"
SmallCodeVocabulary maintains the domain vocabulary — the set of named concepts
(selectors + descriptions) that the agent should prefer when writing code.

It extracts vocabulary from live packages/classes in the image and tracks
session-created words. The vocabulary is injected into the LLM system prompt
to constrain generation to known domain language.

This is the core mechanism from Session 3: DSL as the shared medium between
human, LLM, and AST.
"
Class {
	#name : 'SmallCodeVocabulary',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'sessionEntries'
	],
	#classInstVars : [
		'current'
	],
	#category : 'SmallCode-DSL',
	#package : 'SmallCode-DSL'
}

{ #category : 'accessing' }
SmallCodeVocabulary class >> current [

	^ current ifNil: [ current := self new ]
]

{ #category : 'accessing' }
SmallCodeVocabulary class >> reset [

	<script>
	current := nil
]

{ #category : 'initialization' }
SmallCodeVocabulary >> initialize [

	super initialize.
	entries := Dictionary new.
	sessionEntries := OrderedDictionary new
]

{ #category : 'extraction' }
SmallCodeVocabulary >> extractFromPackageNamed: aPackageName [
	"Extract vocabulary from all classes in the named package."

	| package |
	package := self packageNamed: aPackageName.
	package ifNil: [ ^ self ].
	package definedClasses do: [ :cls |
		self extractFromClass: cls ]
]

{ #category : 'extraction' }
SmallCodeVocabulary >> extractFromPackages: packageNames [
	"Extract vocabulary from multiple packages."

	packageNames do: [ :name | self extractFromPackageNamed: name ]
]

{ #category : 'extraction' }
SmallCodeVocabulary >> extractFromClass: aClass [
	"Extract all selectors + method comments from a class as vocabulary entries."

	self extractFromBehavior: aClass.
	self extractFromBehavior: aClass class
]

{ #category : 'extraction' }
SmallCodeVocabulary >> extractFromBehavior: aBehavior [
	"Extract selectors and comments from a single behavior (instance or class side)."

	| className |
	className := aBehavior isInstanceSide
		             ifTrue: [ aBehavior name ]
		             ifFalse: [ aBehavior instanceSide name , ' class' ].
	aBehavior selectors do: [ :sel |
		| method comment entry |
		method := aBehavior >> sel.
		comment := [ method comment ] on: Error do: [ :e | nil ].
		entry := SmallCodeVocabularyEntry
			         className: className
			         selector: sel asString
			         description: (comment ifNil: [ '' ]).
		entries at: entry key put: entry ]
]

{ #category : 'registration' }
SmallCodeVocabulary >> registerSelector: aSelector on: aClassName description: aDescription rationale: aRationale [
	"Register a newly created domain word during this session."

	| entry |
	entry := SmallCodeVocabularyEntry
		         className: aClassName
		         selector: aSelector.
	entry description: aDescription.
	entry rationale: aRationale.
	entries at: entry key put: entry.
	sessionEntries at: entry key put: entry.
	^ entry
]

{ #category : 'querying' }
SmallCodeVocabulary >> selectorsFor: aClass [
	"Return all vocabulary entries for the given class."

	| prefix |
	prefix := aClass name , '>>'.
	^ entries associations
		  select: [ :assoc | assoc key beginsWith: prefix ]
		  thenCollect: [ :assoc | assoc value ]
]

{ #category : 'querying' }
SmallCodeVocabulary >> unarySelectorsFor: aClass [
	"Return all unary (no-argument) vocabulary selectors for a class.
	 Used by SmallCodeProjector for domain view."

	^ (self selectorsFor: aClass)
		  select: [ :entry | entry isUnary ]
		  thenCollect: [ :entry | entry selector asSymbol ]
]

{ #category : 'querying' }
SmallCodeVocabulary >> findSimilar: aSelector [
	"Find vocabulary entries with similar selector names.
	 Uses simple substring and root-word matching."

	| normalized candidates |
	normalized := self normalizeSelector: aSelector.
	candidates := OrderedCollection new.
	entries valuesDo: [ :entry |
		| entryNorm |
		entryNorm := self normalizeSelector: entry selector.
		"Substring match"
		((entryNorm includesSubstring: normalized) or: [
			 normalized includesSubstring: entryNorm ]) ifTrue: [
			candidates add: entry ] ].
	^ candidates
]

{ #category : 'querying' }
SmallCodeVocabulary >> hasSelector: aSelector on: aClassName [
	"Check if a specific selector is in the vocabulary."

	^ entries includesKey: aClassName , '>>' , aSelector
]

{ #category : 'formatting' }
SmallCodeVocabulary >> formatForPrompt [
	"Generate the full vocabulary section for the system prompt."

	| stream classGroups |
	stream := WriteStream on: String new.
	classGroups := Dictionary new.
	entries valuesDo: [ :entry |
		(classGroups at: entry className ifAbsentPut: [ OrderedCollection new ])
			add: entry ].
	classGroups keys asSortedCollection do: [ :clsName |
		| classEntries |
		stream nextPutAll: '### '; nextPutAll: clsName; cr.
		classEntries := (classGroups at: clsName) asSortedCollection: [ :a :b |
			                a selector < b selector ].
		classEntries do: [ :entry |
			stream nextPutAll: entry formatForPrompt; cr ].
		stream cr ].
	^ stream contents
]

{ #category : 'formatting' }
SmallCodeVocabulary >> formatSessionCreatedForPrompt [
	"Generate the session-created vocabulary section."

	| stream |
	sessionEntries ifEmpty: [ ^ '(none yet)' ].
	stream := WriteStream on: String new.
	sessionEntries valuesDo: [ :entry |
		stream
			nextPutAll: '- ';
			nextPutAll: entry className;
			nextPutAll: ' >> ';
			nextPutAll: entry selector;
			nextPutAll: '    "';
			nextPutAll: entry description;
			nextPut: $".
		entry rationale ifNotEmpty: [
			stream nextPutAll: ' ('; nextPutAll: entry rationale; nextPut: $) ].
		stream cr ].
	^ stream contents
]

{ #category : 'formatting' }
SmallCodeVocabulary >> formatForPromptWithPackages: packageNames [
	"Generate vocabulary section scoped to specific packages."

	| stream |
	"First extract from packages if not already done"
	packageNames do: [ :name | self extractFromPackageNamed: name ].
	stream := WriteStream on: String new.
	stream nextPutAll: '## Domain Vocabulary'; cr; cr.
	stream nextPutAll: self formatForPrompt.
	stream nextPutAll: '## Session-Created Vocabulary'; cr.
	stream nextPutAll: self formatSessionCreatedForPrompt; cr.
	^ stream contents
]

{ #category : 'private' }
SmallCodeVocabulary >> normalizeSelector: aSelector [
	"Normalize a selector for similarity comparison.
	 Remove common prefixes (is, has, get, set) and colons."

	| s |
	s := aSelector copyReplaceAll: ':' with: ''.
	#( 'is' 'has' 'get' 'set' 'do' ) do: [ :prefix |
		(s beginsWith: prefix) ifTrue: [
			| rest |
			rest := s allButFirst: prefix size.
			rest ifNotEmpty: [ rest first isUppercase ifTrue: [ s := rest uncapitalized ] ] ] ].
	^ s asLowercase
]

{ #category : 'private' }
SmallCodeVocabulary >> packageNamed: aPackageName [
	"Find a package by name in the system."

	^ [ (PackageOrganizer default packageNamed: aPackageName) ]
		  on: Error
		  do: [ :e | nil ]
]

{ #category : 'accessing' }
SmallCodeVocabulary >> entries [

	^ entries
]

{ #category : 'accessing' }
SmallCodeVocabulary >> sessionEntries [

	^ sessionEntries
]

{ #category : 'accessing' }
SmallCodeVocabulary >> size [

	^ entries size
]

{ #category : 'initialization' }
SmallCodeVocabulary >> resetSession [
	"Clear session-created entries only."

	sessionEntries removeAll
]
