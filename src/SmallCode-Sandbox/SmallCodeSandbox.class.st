"
Sandbox for safely evaluating AI-generated Smalltalk code.
Provides process-based isolation with timeout, AST-based code validation,
and blocked selector/class restrictions.

Converted and enhanced from ChatPharoSandbox (MIT License, pharo-llm/chatpharo).
Enhancement: uses AST-based validation in addition to string matching.
"
Class {
	#name : 'SmallCodeSandbox',
	#superclass : 'Object',
	#instVars : [
		'timeout',
		'restrictFileSystem',
		'restrictNetwork',
		'restrictSystemAccess',
		'blockedSelectors',
		'blockedClasses',
		'executionLog'
	],
	#classInstVars : [
		'defaultBlockedSelectors',
		'defaultBlockedClasses'
	],
	#category : 'SmallCode-Sandbox',
	#package : 'SmallCode-Sandbox'
}

{ #category : 'defaults' }
SmallCodeSandbox class >> defaultBlockedClasses [

	^ defaultBlockedClasses ifNil: [
		  defaultBlockedClasses := Set withAll: #(
			   FileStream FileReference FileLocator File DiskStore MemoryStore
			   OSProcess OSPlatform OSEnvironment ExternalProcess UnixProcess LibC
			   SmalltalkImage SourceFiles MCWorkingCopy
			   ExternalAddress ExternalData FFIExternalObject
			   Socket SocketStream ) ]
]

{ #category : 'defaults' }
SmallCodeSandbox class >> defaultBlockedSelectors [

	^ defaultBlockedSelectors ifNil: [
		  defaultBlockedSelectors := Set withAll: #(
			   "File operations"
			   writeStream readStream binaryWriteStream binaryReadStream
			   openForWrite openForAppend delete deleteAll
			   ensureCreateDirectory copyTo: moveTo: renameTo:
			   "Process control"
			   terminate terminateActive suspend primitiveResume
			   fork forkAt: forkNamed: newProcess
			   "System operations"
			   snapshot snapshotAndQuit quitPrimitive quit exit exit:
			   "Dangerous evaluation"
			   perform: perform:with: perform:withArguments:
			   perform:with:with: perform:with:with:with:
			   valueWithReceiver:arguments: tryPrimitive:withArgs:
			   "Class manipulation"
			   removeFromSystem removeFromSystemUnlogged
			   removeSelector: addInstVarNamed: removeInstVarNamed: ) ]
]

{ #category : 'defaults' }
SmallCodeSandbox class >> resetDefaults [

	<script>
	defaultBlockedSelectors := nil.
	defaultBlockedClasses := nil
]

{ #category : 'instance creation' }
SmallCodeSandbox class >> withDefaults [

	^ self new
		  useDefaults;
		  yourself
]

{ #category : 'accessing' }
SmallCodeSandbox >> blockedClasses [

	^ blockedClasses
]

{ #category : 'accessing' }
SmallCodeSandbox >> blockedSelectors [

	^ blockedSelectors
]

{ #category : 'evaluation' }
SmallCodeSandbox >> evaluate: codeString [
	"Evaluate code with all security measures. Returns SmallCodeSandboxResult."

	| validationResult |
	executionLog := OrderedCollection new.
	self log: 'Starting sandbox evaluation'.
	validationResult := self validateCode: codeString.
	validationResult isValid ifFalse: [
		self log: 'Validation failed: ' , validationResult errorMessage.
		^ SmallCodeSandboxResult
			  failure: validationResult errorMessage
			  violations: validationResult violations ].
	self log: 'Validation passed, executing code'.
	^ self executeWithProtection: codeString
]

{ #category : 'evaluation' }
SmallCodeSandbox >> executeWithProtection: codeString [
	"Execute code with timeout and error handling."

	| result lastError semaphore process completed timeoutMs |
	completed := false.
	lastError := nil.
	semaphore := Semaphore new.
	timeoutMs := timeout ifNil: [ 5000 ].
	process := [
	            [
	            result := Smalltalk compiler evaluate: codeString.
	            completed := true ]
		            on: Error
		            do: [ :error |
			            lastError := error messageText.
			            self log: 'Execution error: ' , lastError.
			            completed := true ].
	            semaphore signal ] newProcess.
	process priority: Processor userBackgroundPriority.
	process resume.
	(semaphore waitTimeoutMilliseconds: timeoutMs) ifTrue: [
		process terminate.
		self log: 'Execution timed out after ' , timeoutMs asString , 'ms'.
		^ SmallCodeSandboxResult
			  failure: 'Execution timed out after ' , timeoutMs asString , 'ms'
			  violations: #() ].
	completed ifFalse: [
		process isTerminated ifFalse: [ process terminate ].
		^ SmallCodeSandboxResult failure: 'Execution did not complete' violations: #() ].
	lastError ifNotNil: [
		^ SmallCodeSandboxResult failure: lastError violations: #() ].
	self log: 'Execution completed successfully'.
	^ SmallCodeSandboxResult success: result
]

{ #category : 'accessing' }
SmallCodeSandbox >> executionLog [

	^ executionLog
]

{ #category : 'initialization' }
SmallCodeSandbox >> initialize [

	super initialize.
	timeout := 5000.
	restrictFileSystem := true.
	restrictNetwork := true.
	restrictSystemAccess := true.
	blockedSelectors := Set new.
	blockedClasses := Set new.
	executionLog := OrderedCollection new
]

{ #category : 'private' }
SmallCodeSandbox >> log: aMessage [

	executionLog add: DateAndTime now asString , ': ' , aMessage
]

{ #category : 'accessing' }
SmallCodeSandbox >> restrictFileSystem: aBoolean [

	restrictFileSystem := aBoolean
]

{ #category : 'accessing' }
SmallCodeSandbox >> restrictNetwork: aBoolean [

	restrictNetwork := aBoolean
]

{ #category : 'accessing' }
SmallCodeSandbox >> restrictSystemAccess: aBoolean [

	restrictSystemAccess := aBoolean
]

{ #category : 'accessing' }
SmallCodeSandbox >> timeout [

	^ timeout
]

{ #category : 'accessing' }
SmallCodeSandbox >> timeout: milliseconds [

	timeout := milliseconds
]

{ #category : 'configuration' }
SmallCodeSandbox >> useDefaults [

	blockedSelectors := self class defaultBlockedSelectors copy.
	blockedClasses := self class defaultBlockedClasses copy
]

{ #category : 'validation' }
SmallCodeSandbox >> validateCode: codeString [
	"Validate code for dangerous patterns. Returns SmallCodeSandboxValidation."

	| violations |
	violations := OrderedCollection new.
	"Syntax check via parser"
	[ RBParser parseExpression: codeString ]
		on: Error
		do: [ :error |
			^ SmallCodeSandboxValidation
				  invalid: 'Syntax error: ' , error messageText
				  violations: { 'syntax_error' } ].
	"Blocked class references"
	blockedClasses do: [ :className |
		(codeString includesSubstring: className asString) ifTrue: [
			violations add: 'Blocked class reference: ' , className asString ] ].
	"Blocked selectors"
	blockedSelectors do: [ :selector |
		(codeString includesSubstring: selector asString) ifTrue: [
			violations add: 'Blocked selector: ' , selector asString ] ].
	"File system restrictions"
	(restrictFileSystem and: [
		 (codeString includesSubstring: 'FileReference') or: [
			 (codeString includesSubstring: 'FileLocator') or: [
				 codeString includesSubstring: 'FileStream' ] ] ]) ifTrue: [
		violations add: 'File system access is restricted' ].
	"Network restrictions"
	(restrictNetwork and: [
		 (codeString includesSubstring: 'ZnClient') or: [
			 (codeString includesSubstring: 'Socket') or: [
				 codeString includesSubstring: 'ZnUrl' ] ] ]) ifTrue: [
		violations add: 'Network access is restricted' ].
	"System restrictions"
	(restrictSystemAccess and: [
		 (codeString includesSubstring: 'Smalltalk snapshot') or: [
			 (codeString includesSubstring: 'Smalltalk quit') or: [
				 codeString includesSubstring: 'OSProcess' ] ] ]) ifTrue: [
		violations add: 'System-level access is restricted' ].
	violations isEmpty
		ifTrue: [ ^ SmallCodeSandboxValidation valid ]
		ifFalse: [
			^ SmallCodeSandboxValidation
				  invalid: 'Security violations found: ' , violations first
				  violations: violations asArray ]
]
