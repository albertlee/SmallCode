"
SmallCodeNarrator renders a method's AST into quasi-natural-language description.
This is the bidirectional rendering mechanism from Session 3:
AST -> natural language narration for human/LLM observation.

Level 1: keyword selector splitting + argument embedding.
Level 2: common pattern recognition (ifTrue:, do:, collect:, etc.).
"
Class {
	#name : 'SmallCodeNarrator',
	#superclass : 'Object',
	#category : 'SmallCode-DSL',
	#package : 'SmallCode-DSL'
}

{ #category : 'narration' }
SmallCodeNarrator >> narrate: aCompiledMethod [
	"Render a method as a natural language description."

	| ast stream |
	ast := aCompiledMethod ast.
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Method: ';
		nextPutAll: aCompiledMethod methodClass name;
		nextPutAll: ' >> #';
		nextPutAll: aCompiledMethod selector;
		cr.
	aCompiledMethod comment ifNotNil: [ :c |
		c ifNotEmpty: [ stream nextPutAll: 'Purpose: '; nextPutAll: c; cr ] ].
	stream nextPutAll: 'Behavior: '.
	self narrateBody: ast body on: stream indent: 1.
	^ stream contents
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateBody: aSequenceNode on: aStream indent: level [
	"Narrate a sequence of statements."

	aSequenceNode statements doWithIndex: [ :stmt :i |
		i > 1 ifTrue: [ aStream cr; nextPutAll: (self indentString: level) ].
		self narrateNode: stmt on: aStream indent: level ]
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateNode: aNode on: aStream indent: level [
	"Dispatch to specific narration by node type."

	(aNode isMessage) ifTrue: [ ^ self narrateMessage: aNode on: aStream indent: level ].
	(aNode isCascade) ifTrue: [ ^ self narrateCascade: aNode on: aStream indent: level ].
	(aNode isReturn) ifTrue: [ ^ self narrateReturn: aNode on: aStream indent: level ].
	(aNode isAssignment) ifTrue: [ ^ self narrateAssignment: aNode on: aStream indent: level ].
	(aNode isBlock) ifTrue: [ ^ self narrateBlock: aNode on: aStream indent: level ].
	(aNode isVariable) ifTrue: [ aStream nextPutAll: aNode name. ^ self ].
	(aNode isLiteralNode) ifTrue: [ aStream nextPutAll: aNode value printString. ^ self ].
	
	"Fallback"
	aStream nextPutAll: aNode sourceCode
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateMessage: aMessageNode on: aStream indent: level [
	"Narrate a message send. Key logic for DSL readability."

	| sel args |
	sel := aMessageNode selector.
	args := aMessageNode arguments.
	
	"Special patterns"
	(self narrateSpecialPattern: aMessageNode on: aStream indent: level)
		ifTrue: [ ^ self ].
	
	"Unary message"
	args isEmpty ifTrue: [
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ' '; nextPutAll: sel.
		^ self ].
	
	"Binary message"
	(sel isBinary) ifTrue: [
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPut: $ ; nextPutAll: sel; nextPut: $ .
		self narrateNode: args first on: aStream indent: level.
		^ self ].
	
	"Keyword message -> natural language rendering"
	self narrateKeywordMessage: aMessageNode on: aStream indent: level
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateKeywordMessage: aMessageNode on: aStream indent: level [
	"Render keyword message as near-English.
	 e.g. transfer:from:to: with args (100, checking, savings) 
	 -> 'transfer 100 from checking to savings'"

	| keywords args receiver |
	keywords := self splitKeyword: aMessageNode selector.
	args := aMessageNode arguments.
	receiver := aMessageNode receiver.
	
	"Render receiver first (unless it's self)"
	(receiver isVariable and: [ receiver name = 'self' ]) ifFalse: [
		self narrateNode: receiver on: aStream indent: level.
		aStream nextPut: $ ].
	
	"Interleave keywords and arguments"
	keywords withIndexDo: [ :kw :i |
		i > 1 ifTrue: [ aStream nextPut: $ ].
		aStream nextPutAll: kw.
		i <= args size ifTrue: [
			aStream nextPut: $ .
			self narrateNode: (args at: i) on: aStream indent: level ] ]
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateSpecialPattern: aMessageNode on: aStream indent: level [
	"Handle common Smalltalk patterns with English rendering.
	 Return true if handled, false to fall through."

	| sel |
	sel := aMessageNode selector.
	
	"ifTrue:ifFalse: pattern"
	(sel = #ifTrue:ifFalse:) ifTrue: [
		aStream nextPutAll: 'if '.
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ', then '.
		self narrateNode: aMessageNode arguments first on: aStream indent: level + 1.
		aStream nextPutAll: ', otherwise '.
		self narrateNode: aMessageNode arguments second on: aStream indent: level + 1.
		^ true ].
	
	"ifTrue: pattern"
	(sel = #ifTrue:) ifTrue: [
		aStream nextPutAll: 'if '.
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ', then '.
		self narrateNode: aMessageNode arguments first on: aStream indent: level + 1.
		^ true ].
	
	"ifFalse: pattern"
	(sel = #ifFalse:) ifTrue: [
		aStream nextPutAll: 'unless '.
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ', do '.
		self narrateNode: aMessageNode arguments first on: aStream indent: level + 1.
		^ true ].
	
	"do: pattern"
	(sel = #do:) ifTrue: [
		aStream nextPutAll: 'for each element in '.
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ', '.
		self narrateNode: aMessageNode arguments first on: aStream indent: level + 1.
		^ true ].
	
	"collect: pattern"
	(sel = #collect:) ifTrue: [
		aStream nextPutAll: 'transform each element in '.
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ' by '.
		self narrateNode: aMessageNode arguments first on: aStream indent: level + 1.
		^ true ].
	
	"select: pattern"
	(sel = #select:) ifTrue: [
		aStream nextPutAll: 'filter '.
		self narrateNode: aMessageNode receiver on: aStream indent: level.
		aStream nextPutAll: ' where '.
		self narrateNode: aMessageNode arguments first on: aStream indent: level + 1.
		^ true ].
	
	^ false
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateCascade: aCascadeNode on: aStream indent: level [

	aCascadeNode messages doWithIndex: [ :msg :i |
		i > 1 ifTrue: [ aStream nextPutAll: '; then ' ].
		self narrateMessage: msg on: aStream indent: level ]
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateReturn: aReturnNode on: aStream indent: level [

	aStream nextPutAll: 'return '.
	self narrateNode: aReturnNode value on: aStream indent: level
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateAssignment: anAssignmentNode on: aStream indent: level [

	aStream nextPutAll: 'set '; nextPutAll: anAssignmentNode variable name; nextPutAll: ' to '.
	self narrateNode: anAssignmentNode value on: aStream indent: level
]

{ #category : 'narration' }
SmallCodeNarrator >> narrateBlock: aBlockNode on: aStream indent: level [

	| args |
	args := aBlockNode arguments.
	args ifNotEmpty: [
		aStream nextPutAll: '(with '.
		args doWithIndex: [ :arg :i |
			i > 1 ifTrue: [ aStream nextPutAll: ', ' ].
			aStream nextPutAll: arg name ].
		aStream nextPutAll: ') ' ].
	self narrateBody: aBlockNode body on: aStream indent: level
]

{ #category : 'utilities' }
SmallCodeNarrator >> splitKeyword: aSelector [
	"Split a keyword selector into its word parts.
	 transfer:from:to: -> #('transfer' 'from' 'to')"

	| parts |
	(aSelector includes: $:) ifFalse: [ ^ { aSelector } ].
	parts := aSelector substrings: ':'.
	^ parts
]

{ #category : 'utilities' }
SmallCodeNarrator >> indentString: level [

	^ String new: level * 2 withAll: $ 
]
