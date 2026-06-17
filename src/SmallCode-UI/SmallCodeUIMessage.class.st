"
SmallCodeUIMessage is a single user+assistant pair as shown in the chat transcript.
Minimal View-Model used by the layout engine; keeps UI state separate from API-layer SmallCodeMessage objects.

Instance Variables:
- content:    the user's message text
- answer:     the assistant's reply text
- thinking:   reasoning model thinking content
- assistantLabel:  label shown before the answer (e.g. 'Assistant', 'SmallCode')
- presenter:  lazily-created SmallCodeMessagePresenter
"
Class {
	#name : 'SmallCodeUIMessage',
	#superclass : 'Object',
	#instVars : [
		'content',
		'answer',
		'thinking',
		'assistantLabel',
		'presenter'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'accessing' }
SmallCodeUIMessage >> answer [

	^ answer
]

{ #category : 'accessing' }
SmallCodeUIMessage >> answer: aString [

	answer := aString.
	self resetPresenter
]

{ #category : 'accessing' }
SmallCodeUIMessage >> assistantLabel [

	^ assistantLabel
]

{ #category : 'accessing' }
SmallCodeUIMessage >> assistantLabel: aString [

	assistantLabel := aString
]

{ #category : 'accessing' }
SmallCodeUIMessage >> content [

	^ content
]

{ #category : 'accessing' }
SmallCodeUIMessage >> content: aString [

	content := aString
]

{ #category : 'accessing' }
SmallCodeUIMessage >> height [

	^ self presenter height
]

{ #category : 'initialization' }
SmallCodeUIMessage >> initialize [

	super initialize.
	content := ''.
	answer := ''.
	thinking := ''.
	assistantLabel := 'SmallCode'
]

{ #category : 'accessing' }
SmallCodeUIMessage >> presenter [

	^ presenter ifNil: [ presenter := SmallCodeMessagePresenter on: self ]
]

{ #category : 'private' }
SmallCodeUIMessage >> resetPresenter [

	presenter := nil
]

{ #category : 'accessing' }
SmallCodeUIMessage >> thinking [

	^ thinking
]

{ #category : 'accessing' }
SmallCodeUIMessage >> thinking: aString [

	thinking := aString
]
