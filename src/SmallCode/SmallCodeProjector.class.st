"
SmallCodeProjector maps live objects to text representations with handle-based references.
Supports progressive disclosure at multiple depth levels:
  L0: class + handle only
  L1: shallow instance variables (primitives inline, objects as L0 refs)
  L2: recursive expand one level (instVars also at L1)
  L3: collection elements (first N items)
  
Provides domain view: calls unary vocabulary selectors on objects to show
semantic-level properties alongside raw instVar structure.

Handle registry uses identity-based deduplication.
"
Class {
	#name : 'SmallCodeProjector',
	#superclass : 'Object',
	#instVars : [
		'handles',
		'reverseMap',
		'counter',
		'maxCollectionElements',
		'vocabulary'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeProjector class >> new [

	^ super new initialize
]

{ #category : 'handles' }
SmallCodeProjector >> allBindings [
	"Return a Dictionary of handle->object for OpalCompiler bindings: injection."

	^ handles copy
]

{ #category : 'projecting - domain' }
SmallCodeProjector >> domainView: anObject [
	"Call all unary vocabulary selectors on anObject and return domain-level view.
	 Returns a string of key=value pairs, or empty string if no vocabulary."

	| results stream vocabSelectors |
	vocabulary ifNil: [ ^ '' ].
	vocabSelectors := vocabulary unarySelectorsFor: anObject class.
	vocabSelectors ifEmpty: [ ^ '' ].
	results := OrderedCollection new.
	vocabSelectors do: [ :sel |
		| val |
		val := [ anObject perform: sel ]
			       on: Error
			       do: [ :e | nil ].
		val ifNotNil: [ results add: sel -> (self shallowValue: val) ] ].
	results ifEmpty: [ ^ '' ].
	stream := WriteStream on: String new.
	stream nextPutAll: 'Domain: '.
	results doWithIndex: [ :assoc :i |
		i > 1 ifTrue: [ stream nextPutAll: ', ' ].
		stream
			nextPutAll: assoc key;
			nextPut: $=;
			nextPutAll: assoc value ].
	^ stream contents
]

{ #category : 'accessing' }
SmallCodeProjector >> handleCount [

	^ handles size
]

{ #category : 'handles' }
SmallCodeProjector >> handleFor: anObject [
	"Return the handle for anObject, creating one if needed. Identity-based."

	| existing handle |
	anObject ifNil: [ ^ 'nil' ].
	existing := reverseMap at: anObject ifAbsent: [ nil ].
	existing ifNotNil: [ ^ existing ].
	counter := counter + 1.
	handle := 'obj_' , counter printString.
	handles at: handle put: anObject.
	reverseMap at: anObject put: handle.
	^ handle
]

{ #category : 'handles' }
SmallCodeProjector >> handlesDo: aBlock [
	"Iterate all handle->object pairs."

	handles keysAndValuesDo: aBlock
]

{ #category : 'initialization' }
SmallCodeProjector >> initialize [

	super initialize.
	handles := Dictionary new.
	reverseMap := IdentityDictionary new.
	counter := 0.
	maxCollectionElements := 20
]

{ #category : 'private' }
SmallCodeProjector >> isPrimitive: anObject [
	"Return true for objects that should be inlined (no handle needed)."

	^ anObject isNil or: [
		  anObject isNumber or: [
			  anObject isString or: [
				  anObject isSymbol or: [
					  anObject isCharacter or: [
						  anObject isKindOf: Boolean ] ] ] ] ]
]

{ #category : 'accessing' }
SmallCodeProjector >> maxCollectionElements [

	^ maxCollectionElements
]

{ #category : 'accessing' }
SmallCodeProjector >> maxCollectionElements: anInteger [

	maxCollectionElements := anInteger
]

{ #category : 'handles' }
SmallCodeProjector >> objectAt: aHandle [
	"Resolve a handle to the live object, or nil."

	^ handles at: aHandle ifAbsent: [ nil ]
]

{ #category : 'projecting' }
SmallCodeProjector >> project: anObject [
	"Default projection at L1 depth."

	^ self project: anObject depth: 1
]

{ #category : 'projecting' }
SmallCodeProjector >> project: anObject depth: level [
	"Project an object at the given depth level (0-3)."

	anObject ifNil: [ ^ 'nil' ].
	
	"Primitives are always inline"
	(self isPrimitive: anObject) ifTrue: [ ^ anObject printString ].
	
	level = 0 ifTrue: [ ^ self projectL0: anObject ].
	level = 1 ifTrue: [ ^ self projectL1: anObject ].
	level = 2 ifTrue: [ ^ self projectL2: anObject ].
	level >= 3 ifTrue: [ ^ self projectL3: anObject ].
	
	^ self projectL1: anObject
]

{ #category : 'projecting' }
SmallCodeProjector >> projectCollectionDeep: aCollection [
	"Project a collection with elements at L1."

	| stream items |
	stream := WriteStream on: String new.
	stream nextPutAll: '#<'; nextPutAll: aCollection class name.
	stream nextPutAll: ' @'; nextPutAll: (self handleFor: aCollection).
	stream nextPutAll: ' size='; print: aCollection size.
	items := aCollection size <= maxCollectionElements
		         ifTrue: [ aCollection ]
		         ifFalse: [ aCollection asOrderedCollection copyFrom: 1 to: maxCollectionElements ].
	stream nextPutAll: ' ['.
	items doWithIndex: [ :each :i |
		i > 1 ifTrue: [ stream nextPutAll: ', ' ].
		stream nextPutAll: (self project: each depth: 1) ].
	aCollection size > maxCollectionElements ifTrue: [ stream nextPutAll: ', ...' ].
	stream nextPutAll: ']>'.
	^ stream contents
]

{ #category : 'projecting' }
SmallCodeProjector >> projectCollectionShallow: aCollection [
	"Project a collection with element count and first N elements at L0."

	| stream items |
	stream := WriteStream on: String new.
	stream nextPutAll: '#<'; nextPutAll: aCollection class name.
	stream nextPutAll: ' @'; nextPutAll: (self handleFor: aCollection).
	stream nextPutAll: ' size='; print: aCollection size.
	items := aCollection size <= maxCollectionElements
		         ifTrue: [ aCollection ]
		         ifFalse: [ aCollection asOrderedCollection copyFrom: 1 to: maxCollectionElements ].
	stream nextPutAll: ' | '.
	items doWithIndex: [ :each :i |
		i > 1 ifTrue: [ stream nextPutAll: ', ' ].
		stream nextPutAll: (self shallowValue: each) ].
	aCollection size > maxCollectionElements ifTrue: [ stream nextPutAll: ', ...' ].
	stream nextPut: $>.
	^ stream contents
]

{ #category : 'projecting' }
SmallCodeProjector >> projectL0: anObject [
	"Level 0: class name + handle only."

	^ '#<' , anObject class name , ' @' , (self handleFor: anObject) , '>'
]

{ #category : 'projecting' }
SmallCodeProjector >> projectL1: anObject [
	"Level 1: class + handle + shallow instVars."

	| stream |
	(anObject isKindOf: Collection) ifTrue: [ ^ self projectCollectionShallow: anObject ].
	stream := WriteStream on: String new.
	stream nextPutAll: '#<'; nextPutAll: anObject class name.
	stream nextPutAll: ' @'; nextPutAll: (self handleFor: anObject).
	anObject class allInstVarNames ifNotEmpty: [ :names |
		stream nextPutAll: ' | '.
		names doWithIndex: [ :name :i |
			| val |
			i > 1 ifTrue: [ stream nextPutAll: '  ' ].
			val := anObject instVarNamed: name.
			stream
				nextPutAll: name;
				nextPutAll: ': ';
				nextPutAll: (self shallowValue: val) ] ].
	stream nextPut: $>.
	^ stream contents
]

{ #category : 'projecting' }
SmallCodeProjector >> projectL2: anObject [
	"Level 2: like L1, but instVar values expanded to L1."

	| stream |
	(anObject isKindOf: Collection) ifTrue: [ ^ self projectCollectionDeep: anObject ].
	stream := WriteStream on: String new.
	stream nextPutAll: '#<'; nextPutAll: anObject class name.
	stream nextPutAll: ' @'; nextPutAll: (self handleFor: anObject).
	anObject class allInstVarNames ifNotEmpty: [ :names |
		stream nextPutAll: ' | '.
		names doWithIndex: [ :name :i |
			| val |
			i > 1 ifTrue: [ stream nextPutAll: '  ' ].
			val := anObject instVarNamed: name.
			stream
				nextPutAll: name;
				nextPutAll: ': ';
				nextPutAll: (self project: val depth: 1) ] ].
	stream nextPut: $>.
	^ stream contents
]

{ #category : 'projecting' }
SmallCodeProjector >> projectL3: anObject [
	"Level 3: L2 + collection element enumeration."

	(anObject isKindOf: Collection) ifTrue: [ ^ self projectCollectionDeep: anObject ].
	^ self projectL2: anObject
]

{ #category : 'projecting' }
SmallCodeProjector >> projectMethod: aCompiledMethod [
	"Project a CompiledMethod as a structured description."

	| stream |
	stream := WriteStream on: String new.
	stream
		nextPutAll: aCompiledMethod methodClass name;
		nextPutAll: ' >> #';
		nextPutAll: aCompiledMethod selector;
		cr.
	stream nextPutAll: 'Protocol: '; nextPutAll: aCompiledMethod protocol asString; cr.
	aCompiledMethod comment ifNotNil: [ :c |
		c ifNotEmpty: [ stream nextPutAll: 'Comment: '; nextPutAll: c; cr ] ].
	stream nextPutAll: 'Source:'; cr.
	stream nextPutAll: aCompiledMethod sourceCode.
	^ stream contents
]

{ #category : 'projecting - domain' }
SmallCodeProjector >> projectWithDomain: anObject [
	"Project at L1 with domain view appended."

	| base domain |
	base := self projectL1: anObject.
	domain := self domainView: anObject.
	domain ifEmpty: [ ^ base ].
	^ base , String cr , domain
]

{ #category : 'initialization' }
SmallCodeProjector >> reset [
	"Clear all handles."

	handles removeAll.
	reverseMap removeAll.
	counter := 0
]

{ #category : 'private' }
SmallCodeProjector >> shallowValue: aValue [
	"Render a value shallowly: primitives inline, objects as L0 ref."

	aValue ifNil: [ ^ 'nil' ].
	(self isPrimitive: aValue) ifTrue: [ ^ aValue printString ].
	(aValue isKindOf: Boolean) ifTrue: [ ^ aValue printString ].
	^ '#<' , aValue class name , ' @' , (self handleFor: aValue) , '>'
]

{ #category : 'accessing' }
SmallCodeProjector >> vocabulary [

	^ vocabulary
]

{ #category : 'accessing' }
SmallCodeProjector >> vocabulary: aSmallCodeVocabulary [

	vocabulary := aSmallCodeVocabulary
]
