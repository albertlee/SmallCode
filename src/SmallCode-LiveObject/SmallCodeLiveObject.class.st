"
SmallCodeLiveObject intercepts doesNotUnderstand: to synthesize missing methods via LLM.

Enhanced from the PoC LiveObject with:
1. Recursion guard (prevents DNU -> LLM -> DNU infinite loops)
2. AST validation (parse generated code before compile)
3. Retry loop (up to 3 attempts with error feedback)
4. Vocabulary check (find similar existing selectors before creating new ones)
5. Vocabulary registration (new methods auto-registered as domain words)
6. Class context injection (instVarNames, existing selectors fed to LLM)

Subclass SmallCodeLiveObject for domain objects that should auto-synthesize methods.
Or use SmallCodeLiveObject class >> enableFor: aClass to add DNU interception dynamically.

Usage:
  obj := SmallCodeLiveObject new.
  obj doSomethingNew.  'triggers DNU -> LLM synthesis -> compile -> resend'
"
Class {
	#name : 'SmallCodeLiveObject',
	#superclass : 'Object',
	#instVars : [
		'synthesizing'
	],
	#classVars : [
		'Provider',
		'Vocabulary',
		'MaxRetries'
	],
	#category : 'SmallCode-LiveObject',
	#package : 'SmallCode-LiveObject'
}

{ #category : 'configuration' }
SmallCodeLiveObject class >> provider [

	^ Provider ifNil: [ Provider := SmallCodeOpenRouterProvider fromConfiguration ]
]

{ #category : 'configuration' }
SmallCodeLiveObject class >> provider: aProvider [

	Provider := aProvider
]

{ #category : 'configuration' }
SmallCodeLiveObject class >> vocabulary [

	^ Vocabulary ifNil: [ Vocabulary := SmallCodeVocabulary current ]
]

{ #category : 'configuration' }
SmallCodeLiveObject class >> vocabulary: aVocabulary [

	Vocabulary := aVocabulary
]

{ #category : 'configuration' }
SmallCodeLiveObject class >> maxRetries [

	^ MaxRetries ifNil: [ MaxRetries := 3 ]
]

{ #category : 'configuration' }
SmallCodeLiveObject class >> maxRetries: anInteger [

	MaxRetries := anInteger
]

{ #category : 'configuration' }
SmallCodeLiveObject class >> reset [

	<script>
	Provider := nil.
	Vocabulary := nil
]

{ #category : 'initialization' }
SmallCodeLiveObject >> initialize [

	super initialize.
	synthesizing := false
]

{ #category : 'interception' }
SmallCodeLiveObject >> doesNotUnderstand: aMessage [
	"Intercept missing methods: synthesize via LLM with vocabulary awareness."

	| selector |
	selector := aMessage selector.

	"Recursion guard: if already synthesizing, fall through to default DNU"
	synthesizing ifTrue: [ ^ super doesNotUnderstand: aMessage ].

	"Begin synthesis"
	synthesizing := true.
	[
		^ self synthesizeAndResend: aMessage
	] ensure: [
		synthesizing := false ]
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> synthesizeAndResend: aMessage [
	"Core DNU synthesis: vocabulary check -> LLM generate -> AST validate -> compile -> resend."

	| selector source |
	selector := aMessage selector.

	"Step 1: Vocabulary check — is there a similar existing word?"
	self checkVocabularyFor: selector.

	"Step 2: Generate with retry loop"
	source := self generateMethodFor: aMessage.
	source ifNil: [
		Error signal: 'SmallCodeLiveObject: Failed to synthesize method #' , selector , ' after '
			, self class maxRetries printString , ' attempts' ].

	"Step 3: Compile"
	Transcript showln: '[SmallCode DNU] Compiling #' , selector , ':' , String cr , source.
	self class compile: source.

	"Step 4: Register in vocabulary"
	self registerNewWord: selector source: source.

	"Step 5: Resend"
	^ aMessage sendTo: self
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> generateMethodFor: aMessage [
	"Generate method source with retry loop. Returns source string or nil."

	| selector prompt lastError |
	selector := aMessage selector.
	lastError := nil.

	1 to: self class maxRetries do: [ :attempt |
		| reply source |
		prompt := self buildPromptFor: aMessage attempt: attempt lastError: lastError.
		reply := self class provider complete: prompt.
		source := self cleanSource: reply content.

		"AST validation"
		[ RBParser parseMethod: source.
		  "Parse succeeded — return the source"
		  ^ source ]
			on: Error
			do: [ :e |
				lastError := e messageText.
				Transcript showln: '[SmallCode DNU] Attempt ' , attempt printString
					, ' parse error: ' , lastError ] ].

	^ nil "All retries failed"
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> buildPromptFor: aMessage attempt: attempt lastError: errorOrNil [
	"Build the LLM prompt for method synthesis."

	| msgs classContext |
	classContext := self classContextDescription.
	msgs := OrderedCollection new.

	"System prompt with DSL awareness"
	msgs add: (SmallCodeMessage system:
		'You write Pharo Smalltalk methods. Output ONLY the method source (selector + body), no markdown fences, no prose.
Follow keyword message naming conventions. Include a method comment as the first string literal.').

	"User prompt with class context"
	msgs add: (SmallCodeMessage user: (String streamContents: [ :s |
		s nextPutAll: 'Class: '; nextPutAll: self class name; cr.
		s nextPutAll: classContext; cr.
		s nextPutAll: 'Implement method for selector: #'; nextPutAll: aMessage selector; cr.
		s nextPutAll: 'Arguments: '; nextPutAll: aMessage arguments printString; cr.
		
		"Vocabulary context"
		self vocabContextFor: aMessage selector on: s.
		
		"Error feedback for retries"
		(attempt > 1 and: [ errorOrNil isNotNil ]) ifTrue: [
			s cr; nextPutAll: 'PREVIOUS ATTEMPT FAILED with: '; nextPutAll: errorOrNil; cr.
			s nextPutAll: 'Please fix the error and try again.' ] ])).

	^ msgs
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> classContextDescription [
	"Describe the class for the LLM: instVars, existing selectors."

	^ String streamContents: [ :s |
		  s nextPutAll: 'Instance variables: '.
		  s nextPutAll: self class allInstVarNames printString; cr.
		  s nextPutAll: 'Existing methods: '.
		  s nextPutAll: (self class selectors asSortedCollection
				   copyFrom: 1
				   to: (self class selectors size min: 30)) printString ]
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> vocabContextFor: selector on: aStream [
	"Add vocabulary context to the prompt."

	| similar |
	similar := self class vocabulary findSimilar: selector.
	similar ifNotEmpty: [
		aStream cr; nextPutAll: 'Similar existing vocabulary words:'; cr.
		(similar copyFrom: 1 to: (similar size min: 10)) do: [ :entry |
			aStream nextPutAll: '  - '; nextPutAll: entry key.
			entry description ifNotEmpty: [
				aStream nextPutAll: '  "'; nextPutAll: entry description; nextPut: $" ].
			aStream cr ].
		aStream nextPutAll: 'Consider whether an existing word covers this intent.' ]
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> checkVocabularyFor: selector [
	"Log a warning if similar vocabulary words exist."

	| similar |
	similar := self class vocabulary findSimilar: selector.
	similar ifNotEmpty: [
		Transcript showln: '[SmallCode DNU] Warning: similar vocabulary words exist for #' , selector , ': '
			, (similar collect: [ :e | e key ]) printString ]
]

{ #category : 'synthesis' }
SmallCodeLiveObject >> registerNewWord: selector source: sourceCode [
	"Register the newly synthesized method in the vocabulary."

	| method comment |
	method := self class >> selector asSymbol.
	comment := [ method comment ] on: Error do: [ :e | '' ].
	self class vocabulary
		registerSelector: selector asString
		on: self class name
		description: (comment ifNil: [ 'Auto-synthesized via DNU' ])
		rationale: 'Created by doesNotUnderstand: interception'
]

{ #category : 'private' }
SmallCodeLiveObject >> cleanSource: aString [
	"Strip markdown fences from LLM output."

	| s |
	s := aString trimBoth.
	(s beginsWith: '```') ifTrue: [
		s := s copyReplaceAll: '```smalltalk' with: ''.
		s := s copyReplaceAll: '```pharo' with: ''.
		s := s copyReplaceAll: '```' with: '' ].
	^ s trimBoth
]
