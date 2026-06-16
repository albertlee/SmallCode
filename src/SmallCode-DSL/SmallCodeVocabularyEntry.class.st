"
A single entry in the domain vocabulary registry.
Tracks a selector as a named domain concept with metadata.
"
Class {
	#name : 'SmallCodeVocabularyEntry',
	#superclass : 'Object',
	#instVars : [
		'className',
		'selector',
		'description',
		'rationale',
		'createdAt',
		'usageCount',
		'isUnary'
	],
	#category : 'SmallCode-DSL',
	#package : 'SmallCode-DSL'
}

{ #category : 'instance creation' }
SmallCodeVocabularyEntry class >> className: aClassName selector: aSelector description: aDescription [

	^ self new
		  className: aClassName;
		  selector: aSelector;
		  description: aDescription;
		  yourself
]

{ #category : 'initialization' }
SmallCodeVocabularyEntry >> initialize [

	super initialize.
	createdAt := DateAndTime now.
	usageCount := 0.
	rationale := ''
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> className [

	^ className
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> className: aString [

	className := aString
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> selector [

	^ selector
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> selector: aString [

	selector := aString.
	isUnary := (aString includes: $:) not
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> description [

	^ description
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> description: aString [

	description := aString
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> rationale [

	^ rationale
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> rationale: aString [

	rationale := aString
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> createdAt [

	^ createdAt
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> usageCount [

	^ usageCount
]

{ #category : 'accessing' }
SmallCodeVocabularyEntry >> incrementUsage [

	usageCount := usageCount + 1
]

{ #category : 'testing' }
SmallCodeVocabularyEntry >> isUnary [

	^ isUnary ifNil: [ (selector includes: $:) not ]
]

{ #category : 'converting' }
SmallCodeVocabularyEntry >> key [
	"Unique key for this entry."

	^ className , '>>' , selector
]

{ #category : 'converting' }
SmallCodeVocabularyEntry >> formatForPrompt [
	"Format as a line for the system prompt vocabulary section."

	^ '- ' , selector , String tab , String tab , '"' , (description ifNil: [ '(no doc)' ]) , '"'
]

{ #category : 'printing' }
SmallCodeVocabularyEntry >> printOn: aStream [

	aStream
		nextPutAll: className;
		nextPutAll: ' >> ';
		nextPutAll: selector
]
