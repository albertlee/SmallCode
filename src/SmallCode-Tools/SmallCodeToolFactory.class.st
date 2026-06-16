"
SmallCodeToolFactory creates and registers all built-in tools for the agent.
Includes browser environment tools (converted from ChatPharoBrowserEnvironment),
agent-specific tools (inspect, eval with bindings, check_code, senders, etc.),
and DSL tools (vocabulary, register_word, narrate_method).
"
Class {
	#name : 'SmallCodeToolFactory',
	#superclass : 'Object',
	#instVars : [
		'projector',
		'vocabulary',
		'narrator',
		'sandbox',
		'mode'
	],
	#category : 'SmallCode-Tools',
	#package : 'SmallCode-Tools'
}

{ #category : 'instance creation' }
SmallCodeToolFactory class >> projector: aProjector vocabulary: aVocabulary [

	^ self new
		  projector: aProjector;
		  vocabulary: aVocabulary;
		  yourself
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> agentTools [

	^ {
		  self toolInspectObject.
		  self toolEvalCode.
		  self toolCheckCode.
		  self toolReadMethod.
		  self toolSendersOf.
		  self toolImplementorsOf.
		  self toolRunTests.
		  self toolFinish }
]

{ #category : 'building' }
SmallCodeToolFactory >> allToolSchemas [
	"Return OpenAI schemas for all tools."

	^ (self allTools collect: [ :t | t openAISchema ]) asArray
]

{ #category : 'building' }
SmallCodeToolFactory >> allTools [
	"Return all built-in tools."

	^ OrderedCollection new
		  addAll: self agentTools;
		  addAll: self browserTools;
		  addAll: self dslTools;
		  yourself
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> browserTools [

	^ {
		  self toolGetPackages.
		  self toolGetClassesInPackages.
		  self toolDescribePackage.
		  self toolGetClassDefinitions.
		  self toolGetClassMethods.
		  self toolGetClassComments.
		  self toolFindMethods.
		  self toolCreateClass.
		  self toolCreatePackage.
		  self toolAddMethod.
		  self toolRemoveMethod.
		  self toolAddInstanceVariable.
		  self toolSetClassComment }
]

{ #category : 'dsl tools' }
SmallCodeToolFactory >> dslTools [

	^ {
		  self toolVocabulary.
		  self toolRegisterWord.
		  self toolNarrateMethod }
]

{ #category : 'execution' }
SmallCodeToolFactory >> executeTool: aToolName arguments: argumentsDict [
	"Find and execute a tool by name."

	(mode = #plan and: [ self mutatingToolNames includes: aToolName ])
		ifTrue: [
			^ Dictionary with: 'error'
				  -> ('Tool ' , aToolName , ' is disabled in plan mode (read-only). Produce an implementation plan and call finish instead.') ].
	self allTools do: [ :tool |
		tool name = aToolName ifTrue: [
			^ [ tool applyTo: argumentsDict ]
				  on: Error
				  do: [ :e | Dictionary with: 'error' -> e messageText ] ] ].
	^ Dictionary with: 'error' -> ('Unknown tool: ' , aToolName)
]

{ #category : 'initialization' }
SmallCodeToolFactory >> initialize [

	super initialize.
	narrator := SmallCodeNarrator new.
	sandbox := SmallCodeSandbox withDefaults.
	mode := #build
]

{ #category : 'accessing' }
SmallCodeToolFactory >> mode [

	^ mode
]

{ #category : 'accessing' }
SmallCodeToolFactory >> mode: aSymbol [

	mode := aSymbol
]

{ #category : 'building' }
SmallCodeToolFactory >> mutatingToolNames [
	"Names of tools that modify the live image. These are disabled in plan mode."

	^ #( 'create_class' 'create_package' 'add_method' 'remove_method'
	      'add_instance_variable' 'set_class_comment' 'register_word' ) asSet
]

{ #category : 'accessing' }
SmallCodeToolFactory >> narrator [

	^ narrator
]

{ #category : 'accessing' }
SmallCodeToolFactory >> projector [

	^ projector
]

{ #category : 'accessing' }
SmallCodeToolFactory >> projector: aProjector [

	projector := aProjector
]

{ #category : 'building' }
SmallCodeToolFactory >> readOnlyTools [
	"Return all tools except those that mutate the live image."

	| mutating |
	mutating := self mutatingToolNames.
	^ self allTools reject: [ :t | mutating includes: t name ]
]

{ #category : 'accessing' }
SmallCodeToolFactory >> sandbox [

	^ sandbox
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolAddInstanceVariable [

	^ SmallCodeTool
		  name: 'add_instance_variable'
		  description: 'Add an instance variable to an existing class.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class name')
						    with: 'variable_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Variable name'))
				   with: 'required' -> #( 'class_name' 'variable_name' ))
		  block: [ :args |
				  | cls varName |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , (args at: 'class_name')) ].
				  varName := args at: 'variable_name'.
				  (cls instVarNames includes: varName asSymbol) ifTrue: [
					  ^ Dictionary with: 'error' -> ('Variable already exists: ' , varName) ].
				  [
				  cls addInstVarNamed: varName.
				  Dictionary
					  with: 'success' -> true
					  with: 'class' -> (args at: 'class_name')
					  with: 'added' -> varName ]
					  on: Error
					  do: [ :e | Dictionary with: 'error' -> e messageText ] ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolAddMethod [

	^ SmallCodeTool
		  name: 'add_method'
		  description: 'Add or replace a method in a class. The source_code must be complete Smalltalk method source including the method signature. Always include a method comment for domain methods.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class name')
						    with: 'source_code' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Complete Smalltalk method source')
						    with: 'protocol' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Protocol category (default: as yet unclassified)')
						    with: 'side' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'enum' -> #( 'instance' 'class' )
								     with: 'description' -> 'instance or class side (default: instance)'))
				   with: 'required' -> #( 'class_name' 'source_code' ))
		  block: [ :args |
				  | cls targetClass sourceCode protocol side selector |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , (args at: 'class_name')) ].
				  sourceCode := (args at: 'source_code') copyReplaceAll: String lf with: String cr.
				  protocol := args at: 'protocol' ifAbsent: [ 'as yet unclassified' ].
				  side := args at: 'side' ifAbsent: [ 'instance' ].
				  targetClass := side = 'class'
					                 ifTrue: [ cls class ]
					                 ifFalse: [ cls ].
				  [
				  selector := targetClass compile: sourceCode classified: protocol.
				  Dictionary
					  with: 'success' -> true
					  with: 'class' -> (args at: 'class_name')
					  with: 'selector' -> selector asString
					  with: 'side' -> side ]
					  on: Error
					  do: [ :e | Dictionary with: 'error' -> ('Compile error: ' , e messageText) ] ]
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolCheckCode [

	^ SmallCodeTool
		  name: 'check_code'
		  description: 'Parse and validate Smalltalk code without executing it. Checks syntax, finds unimplemented selectors, and reports AST structure.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'code' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'description' -> 'Smalltalk code to check (method source or expression)'))
				   with: 'required' -> #( 'code' ))
		  block: [ :args |
				  | code ast selectors unimplemented |
				  code := args at: 'code'.
				  [
				  ast := RBParser parseExpression: code ]
					  on: Error
					  do: [ :e |
						  ^ Dictionary
							    with: 'valid' -> false
							    with: 'error' -> ('Parse error: ' , e messageText) ].
				  selectors := ast allChildren
					               select: [ :n | n isMessage ]
					               thenCollect: [ :n | n selector ].
				  unimplemented := selectors select: [ :sel |
					                   (Symbol findInternedString: sel asString) isNil or: [
						                   sel implementors isEmpty ] ].
				  Dictionary
					  with: 'valid' -> true
					  with: 'selectors_used' -> (selectors asSet asArray sort)
					  with: 'unimplemented_selectors' -> unimplemented asArray
					  with: 'node_count' -> ast allChildren size ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolCreateClass [

	^ SmallCodeTool
		  name: 'create_class'
		  description: 'Create a new class in the Pharo image.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'New class name (must start with uppercase)')
						    with: 'superclass' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Superclass name (default: Object)')
						    with: 'package' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Package to place the class in')
						    with: 'instance_variables' -> (Dictionary
								     with: 'type' -> 'array'
								     with: 'items' -> (Dictionary with: 'type' -> 'string')
								     with: 'description' -> 'Instance variable names'))
				   with: 'required' -> #( 'class_name' 'package' ))
		  block: [ :args |
				  | className superName pkgName instVars superclass definition |
				  className := args at: 'class_name'.
				  superName := args at: 'superclass' ifAbsent: [ 'Object' ].
				  pkgName := args at: 'package'.
				  instVars := args at: 'instance_variables' ifAbsent: [ #() ].
				  (className isEmpty or: [ className first isUppercase not ]) ifTrue: [
					  ^ Dictionary with: 'error' -> 'Class name must start with uppercase' ].
				  (Smalltalk globals includesKey: className asSymbol) ifTrue: [
					  ^ Dictionary with: 'error' -> 'Class already exists' ].
				  superclass := Smalltalk globals at: superName asSymbol ifAbsent: [
					                ^ Dictionary with: 'error' -> ('Superclass not found: ' , superName) ].
				  [
				  definition := superclass << className asSymbol.
				  instVars ifNotEmpty: [ definition := definition slots: (instVars collect: #asSymbol) ].
				  definition := definition package: pkgName.
				  definition install.
				  Dictionary
					  with: 'success' -> true
					  with: 'class_name' -> className
					  with: 'package' -> pkgName ]
					  on: Error
					  do: [ :e | Dictionary with: 'error' -> e messageText ] ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolCreatePackage [
	^ SmallCodeTool
		  name: 'create_package'
		  description: 'Create a new package in the Pharo image.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'package_name' -> (Dictionary
							     with: 'type' -> 'string'
							     with: 'description' -> 'Package name'))
				   with: 'required' -> #( 'package_name' ))
		  block: [ :args |
				  | pName |
				  pName := args at: 'package_name'.
				  [
				  PackageOrganizer default ensurePackage: pName.
				  Dictionary with: 'success' -> true with: 'package_name' -> pName ]
					  on: Error
					  do: [ :e | Dictionary with: 'error' -> e messageText ] ]


]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolDescribePackage [

	^ SmallCodeTool
		  name: 'describe_package'
		  description: 'Describe a package: list each class with its comment and methods.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'package' -> (Dictionary
							     with: 'type' -> 'string'
							     with: 'description' -> 'Package name'))
				   with: 'required' -> #( 'package' ))
		  block: [ :args |
				  | pName classes |
				  pName := args at: 'package'.
				  [ classes := (PackageOrganizer default packageNamed: pName) definedClasses ]
					  on: Error
					  do: [ :e | ^ Dictionary with: 'error' -> ('Package not found: ' , pName) ].
				  Dictionary with: 'summary_per_class' -> (Dictionary newFrom: (classes collect: [ :c |
							   c name -> (Dictionary
									    with: 'comment' -> c comment
									    with: 'instance_methods' -> c selectors sorted
									    with: 'class_methods' -> c class selectors sorted) ])) ]
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolEvalCode [

	^ SmallCodeTool
		  name: 'eval_code'
		  description: 'Evaluate a Smalltalk expression in the live image. Object handles (obj_1, obj_2...) from previous observations are available as variables via compiler bindings. Returns the projected result with a handle.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'code' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'description' -> 'Smalltalk expression to evaluate. You can reference live objects by their handles (e.g. obj_1).'))
				   with: 'required' -> #( 'code' ))
		  block: [ :args |
				  | code bindings result |
				  code := args at: 'code'.
				  bindings := projector allBindings.
				  [
				  result := OpalCompiler new
					            bindings: bindings;
					            evaluate: code ]
					  on: Error
					  do: [ :e |
						  ^ Dictionary with: 'error' -> ('Evaluation error: ' , e messageText) ].
				  Dictionary
					  with: 'result' -> (projector project: result)
					  with: 'handle' -> (projector handleFor: result) ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolFindMethods [

	^ SmallCodeTool
		  name: 'find_methods'
		  description: 'Find methods whose source includes a given substring. Capped at 30 results.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'substring' -> (Dictionary
							     with: 'type' -> 'string'
							     with: 'description' -> 'Substring to search for in method sources'))
				   with: 'required' -> #( 'substring' ))
		  block: [ :args |
				  | sub methods results |
				  sub := args at: 'substring'.
				  methods := SystemNavigation default allMethodsSelect: [ :m |
					             m sourceCode includesSubstring: sub ].
				  results := (methods copyFrom: 1 to: (methods size min: 30)) collect: [ :m |
					             Dictionary
						             with: 'class' -> m methodClass name
						             with: 'selector' -> m selector ].
				  Dictionary
					  with: 'methods' -> results asArray
					  with: 'total_found' -> methods size ]
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolFinish [

	^ SmallCodeTool
		  name: 'finish'
		  description: 'Stop the agent loop and return the final answer. Include both the task result and any new vocabulary created during this session.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'answer' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'description' -> 'Final answer summarizing what was accomplished')
						    with: 'vocabulary_changelog' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'description' -> 'Summary of new domain words created and why (may be empty)'))
				   with: 'required' -> #( 'answer' ))
		  block: [ :args |
				  Dictionary
					  with: 'finished' -> true
					  with: 'answer' -> (args at: 'answer')
					  with: 'vocabulary_changelog' -> (args at: 'vocabulary_changelog' ifAbsent: [ '' ]) ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolGetClassComments [

	^ SmallCodeTool
		  name: 'get_class_comments'
		  description: 'Get the comment of each class.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'classes' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Class names'))
				   with: 'required' -> #( 'classes' ))
		  block: [ :args |
				  | result |
				  result := Dictionary new.
				  (args at: 'classes') do: [ :cName |
					  | cls |
					  cls := Smalltalk globals at: cName asSymbol ifAbsent: [ nil ].
					  cls ifNotNil: [ result at: cName put: cls comment ] ].
				  Dictionary with: 'comments' -> result ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolGetClassDefinitions [

	^ SmallCodeTool
		  name: 'get_class_definitions'
		  description: 'Get the definition of each class: superclass, instance variables, class variables, package.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'classes' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Class names'))
				   with: 'required' -> #( 'classes' ))
		  block: [ :args |
				  | result notFound |
				  result := Dictionary new.
				  notFound := OrderedCollection new.
				  (args at: 'classes') do: [ :cName |
					  | cls |
					  cls := Smalltalk globals at: cName asSymbol ifAbsent: [ nil ].
					  cls
						  ifNotNil: [
							  result at: cName put: (Dictionary
									   with: 'superclass' -> (cls superclass ifNotNil: [ :s | s name ])
									   with: 'instance_variables' -> cls instVarNames
									   with: 'class_variables' -> cls classVarNames
									   with: 'package' -> cls package name) ]
						  ifNil: [ notFound add: cName ] ].
				  Dictionary
					  with: 'definitions' -> result
					  with: 'not_found' -> notFound asArray ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolGetClassMethods [

	^ SmallCodeTool
		  name: 'get_class_methods'
		  description: 'Get the source code or just selectors of methods for given classes.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'classes' -> (Dictionary
								     with: 'type' -> 'array'
								     with: 'items' -> (Dictionary with: 'type' -> 'string')
								     with: 'description' -> 'Class names')
						    with: 'selectors_only' -> (Dictionary
								     with: 'type' -> 'boolean'
								     with: 'description' -> 'If true, return only selector names; if false, return full source'))
				   with: 'required' -> #( 'classes' 'selectors_only' ))
		  block: [ :args |
				  | result selectorsOnly |
				  result := Dictionary new.
				  selectorsOnly := args at: 'selectors_only'.
				  (args at: 'classes') do: [ :cName |
					  | cls |
					  cls := Smalltalk globals at: cName asSymbol ifAbsent: [ nil ].
					  cls ifNotNil: [
						  result at: cName put: (Dictionary
								   with: 'instance' -> (selectorsOnly
											    ifTrue: [ cls selectors sorted asArray]
											    ifFalse: [ (cls selectors sorted collect: [ :s | cls sourceCodeAt: s ]) asArray ])
								   with: 'class' -> (selectorsOnly
											   ifTrue: [ cls class selectors sorted asArray]
											   ifFalse: [ (cls class selectors sorted collect: [ :s | cls class sourceCodeAt: s ]) asArray ])) ] ].
				  Dictionary with: 'methods_per_class' -> result ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolGetClassesInPackages [

	^ SmallCodeTool
		  name: 'get_classes_in_packages'
		  description: 'List the classes in each given package.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'packages' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Package names'))
				   with: 'required' -> #( 'packages' ))
		  block: [ :args |
				  | result notFound |
				  result := Dictionary new.
				  notFound := OrderedCollection new.
				  (args at: 'packages') do: [ :pName |
					  [ | pkg |
					  pkg := PackageOrganizer default packageNamed: pName.
					  result at: pName put: (pkg definedClasses collect: [ :c | c name ]) sorted asArray]
						  on: Error
						  do: [ :e | notFound add: pName ] ].
				  Dictionary
					  with: 'classes_per_package' -> result
					  with: 'not_found' -> notFound asArray ]
]

{ #category : 'as yet unclassified' }
SmallCodeToolFactory >> toolGetPackages [
^ SmallCodeTool
		  name: 'get_packages'
		  description: 'List all packages in the Pharo image.'
		  parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new with: 'required' -> #())
		  block: [ :args |
				  Dictionary with: 'packages' -> (PackageOrganizer default packages collect: [ :p | p name ]) sorted asArray ]


]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolImplementorsOf [

	^ SmallCodeTool
		  name: 'implementors_of'
		  description: 'Find all classes that implement a given selector.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'selector' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'The selector to search for'))
				   with: 'required' -> #( 'selector' ))
		  block: [ :args |
				  | sel impls |
				  sel := (args at: 'selector') asSymbol.
				  impls := sel implementors.
				  Dictionary
					  with: 'selector' -> sel
					  with: 'count' -> impls size
					  with: 'implementors' -> ((impls copyFrom: 1 to: (impls size min: 30)) collect: [ :m |
								   m methodClass name , '>>' , m selector ]) asArray ]
]

{ #category : 'as yet unclassified' }
SmallCodeToolFactory >> toolInspectObject [
^ SmallCodeTool
		  name: 'inspect_object'
		  description: 'Deep-inspect a live object by its handle (@obj_N). Returns structured view of the object''s state including class, instance variables, and domain properties.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'handle' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'description' -> 'The object handle (e.g. obj_1)')
						    with: 'depth' -> (Dictionary
								     with: 'type' -> 'integer'
								     with: 'description' -> 'Inspection depth: 0=type only, 1=shallow, 2=deep, 3=with collections (default: 2)'))
				   with: 'required' -> #( 'handle' ))
		  block: [ :args |
				  | obj depth result |
				  obj := projector objectAt: (args at: 'handle').
				  obj ifNil: [
					  ^ Dictionary with: 'error' -> ('No object with handle: ' , (args at: 'handle')) ].
				  depth := args at: 'depth' ifAbsent: [ 2 ].
				  result := projector project: obj depth: depth.
				  Dictionary
					  with: 'object' -> result
					  with: 'class' -> obj class name
					  with: 'handle' -> (args at: 'handle')
					  with: 'domain_view' -> (projector domainView: obj) ]
				
				
]

{ #category : 'dsl tools' }
SmallCodeToolFactory >> toolNarrateMethod [

	^ SmallCodeTool
		  name: 'narrate_method'
		  description: 'Render a method as a natural language description by interpreting its AST structure and domain vocabulary. Use this to understand existing code in domain terms.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class name')
						    with: 'selector' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Method selector'))
				   with: 'required' -> #( 'class_name' 'selector' ))
		  block: [ :args |
				  | cls method |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , (args at: 'class_name')) ].
				  (cls includesSelector: (args at: 'selector') asSymbol) ifFalse: [
					  ^ Dictionary with: 'error' -> ('Method not found: ' , (args at: 'selector')) ].
				  method := cls >> (args at: 'selector') asSymbol.
				  Dictionary with: 'narration' -> (narrator narrate: method) ]
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolReadMethod [

	^ SmallCodeTool
		  name: 'read_method'
		  description: 'Read the source code and structure of an existing method.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class name')
						    with: 'selector' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Method selector')
						    with: 'side' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'enum' -> #( 'instance' 'class' )
								     with: 'description' -> 'instance or class side (default: instance)'))
				   with: 'required' -> #( 'class_name' 'selector' ))
		  block: [ :args |
				  | cls targetClass method |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , (args at: 'class_name')) ].
				  targetClass := (args at: 'side' ifAbsent: [ 'instance' ]) = 'class'
					                 ifTrue: [ cls class ]
					                 ifFalse: [ cls ].
				  (targetClass includesSelector: (args at: 'selector') asSymbol) ifFalse: [
					  ^ Dictionary with: 'error' -> ('Method not found: ' , (args at: 'selector')) ].
				  method := targetClass >> (args at: 'selector') asSymbol.
				  Dictionary
					  with: 'source' -> method sourceCode
					  with: 'protocol' -> method protocol asString
					  with: 'comment' -> ([ method comment ] on: Error do: [ :e | '' ])
					  with: 'narration' -> (narrator narrate: method) ]
]

{ #category : 'dsl tools' }
SmallCodeToolFactory >> toolRegisterWord [

	^ SmallCodeTool
		  name: 'register_word'
		  description: 'Register a newly created domain selector in the vocabulary. Call this AFTER compiling a new domain method to make the word visible in future vocabulary queries and in the system prompt.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class the selector belongs to')
						    with: 'selector' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'The new selector')
						    with: 'description' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Natural language description of this domain concept')
						    with: 'rationale' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Why this word was needed (what gap it fills)'))
				   with: 'required' -> #( 'class_name' 'selector' 'description' ))
		  block: [ :args |
				  | entry similar |
				  similar := vocabulary findSimilar: (args at: 'selector').
				  entry := vocabulary
					           registerSelector: (args at: 'selector')
					           on: (args at: 'class_name')
					           description: (args at: 'description')
					           rationale: (args at: 'rationale' ifAbsent: [ '' ]).
				  Dictionary
					  with: 'registered' -> true
					  with: 'word' -> entry key
					  with: 'similar_existing' -> (similar collect: [ :e | e key ]) ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolRemoveMethod [

	^ SmallCodeTool
		  name: 'remove_method'
		  description: 'Remove a method from a class.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class name')
						    with: 'selector' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Method selector')
						    with: 'side' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'enum' -> #( 'instance' 'class' )
								     with: 'description' -> 'instance or class side (default: instance)'))
				   with: 'required' -> #( 'class_name' 'selector' ))
		  block: [ :args |
				  | cls targetClass |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , (args at: 'class_name')) ].
				  targetClass := (args at: 'side' ifAbsent: [ 'instance' ]) = 'class'
					                 ifTrue: [ cls class ]
					                 ifFalse: [ cls ].
				  (targetClass includesSelector: (args at: 'selector') asSymbol) ifFalse: [
					  ^ Dictionary with: 'error' -> ('Method not found: ' , (args at: 'selector')) ].
				  [
				  targetClass removeSelector: (args at: 'selector') asSymbol.
				  Dictionary with: 'success' -> true with: 'removed' -> (args at: 'selector') ]
					  on: Error
					  do: [ :e | Dictionary with: 'error' -> e messageText ] ]
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolRunTests [

	^ SmallCodeTool
		  name: 'run_tests'
		  description: 'Run SUnit tests for a given test class. Returns pass/fail/error counts and details of failures.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary
								     with: 'type' -> 'string'
								     with: 'description' -> 'Name of the TestCase subclass to run'))
				   with: 'required' -> #( 'class_name' ))
		  block: [ :args |
				  | cls suite result |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Test class not found: ' , (args at: 'class_name')) ].
				  (cls isKindOf: TestCase class) ifFalse: [
					  ^ Dictionary with: 'error' -> ((args at: 'class_name') , ' is not a TestCase subclass') ].
				  suite := cls buildSuite.
				  result := suite run.
				  Dictionary
					  with: 'passed' -> result passedCount
					  with: 'failed' -> result failureCount
					  with: 'errors' -> result errorCount
					  with: 'total' -> result runCount
					  with: 'failures' -> (result failures collect: [ :f |
								   f class name , ': ' , f description ])
					  with: 'error_details' -> (result errors collect: [ :e |
								   e class name , ': ' , e description ]) ]
]

{ #category : 'building' }
SmallCodeToolFactory >> toolSchemasForMode: aSymbol [
	"Return OpenAI schemas for the tools available in the given mode."

	^ ((self toolsForMode: aSymbol) collect: [ :t | t openAISchema ]) asArray
]

{ #category : 'agent tools' }
SmallCodeToolFactory >> toolSendersOf [

	^ SmallCodeTool
		  name: 'senders_of'
		  description: 'Find all methods that send a given selector.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'selector' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'The selector to search for'))
				   with: 'required' -> #( 'selector' ))
		  block: [ :args |
				  | sel senders |
				  sel := (args at: 'selector') asSymbol.
				  senders := sel senders.
				  Dictionary
					  with: 'selector' -> sel
					  with: 'count' -> senders size
					  with: 'senders' -> ((senders copyFrom: 1 to: (senders size min: 30)) collect: [ :m |
								   m methodClass name , '>>' , m selector ]) asArray ]
]

{ #category : 'browser tools' }
SmallCodeToolFactory >> toolSetClassComment [

	^ SmallCodeTool
		  name: 'set_class_comment'
		  description: 'Set or update the comment of a class.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'class_name' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class name')
						    with: 'comment' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'Class comment text'))
				   with: 'required' -> #( 'class_name' 'comment' ))
		  block: [ :args |
				  | cls |
				  cls := Smalltalk globals at: (args at: 'class_name') asSymbol ifAbsent: [ nil ].
				  cls ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , (args at: 'class_name')) ].
				  [
				  cls comment: (args at: 'comment').
				  Dictionary with: 'success' -> true ]
					  on: Error
					  do: [ :e | Dictionary with: 'error' -> e messageText ] ]
]

{ #category : 'instance creation' }
SmallCodeToolFactory >> toolVocabulary [

	^ SmallCodeTool
		  name: 'vocabulary'
		  description:
		  'Returns the current domain vocabulary. Use this to check what domain words already exist BEFORE creating new methods. Always prefer existing vocabulary over inventing new selectors.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'packages' -> (Dictionary
								     with: 'type' -> 'array'
								     with: 'items' -> (Dictionary with: 'type' -> 'string')
								     with:
								     'description'
								     -> 'Package names to extract vocabulary from')
						    with: 'class_name' -> (Dictionary
								     with: 'type' -> 'string'
								     with:
								     'description'
								     -> 'Specific class to get vocabulary for (optional)'))
				   with: 'required' -> #(  ))
		  block: [ :args |
				  | packages |
				  packages := args at: 'packages' ifAbsent: [ #(  ) ].
				  packages do: [ :p | vocabulary extractFromPackageNamed: p ].
				  (args at: 'class_name' ifAbsent: [ nil ]) ifNotNil: [ :cName |
						  | cls |
						  cls := Smalltalk globals at: cName asSymbol ifAbsent: [ nil ].
						  cls ifNotNil: [ vocabulary extractFromClass: cls ] ].
				  Dictionary
					  with: 'vocabulary' -> vocabulary formatForPrompt
					  with:
					  'session_created' -> vocabulary formatSessionCreatedForPrompt
					  with: 'total_entries' -> vocabulary size ]
]

{ #category : 'building' }
SmallCodeToolFactory >> toolsForMode: aSymbol [
	"Return the tools available in the given mode.
	 #plan: read-only tools only. Anything else: all tools."

	^ aSymbol = #plan
		  ifTrue: [ self readOnlyTools ]
		  ifFalse: [ self allTools ]
]

{ #category : 'accessing' }
SmallCodeToolFactory >> vocabulary [

	^ vocabulary
]

{ #category : 'accessing' }
SmallCodeToolFactory >> vocabulary: aVocabulary [

	vocabulary := aVocabulary
]
