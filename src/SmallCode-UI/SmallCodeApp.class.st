"
SmallCodeApp is the application root object. Owns the configuration and an ordered collection of open chats.
Spawns new chat sessions through newChat. Presenters bind to it to build windows and toolbars.

Usage:
  SmallCodeApp open
"
Class {
	#name : 'SmallCodeApp',
	#superclass : 'Object',
	#instVars : [
		'configuration',
		'chats'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'instance creation' }
SmallCodeApp class >> open [

	^ self new open
]

{ #category : 'adding' }
SmallCodeApp >> addNewChat [

	| chat |
	chat := SmallCodeChat new
		        provider: (SmallCodeOpenRouterProvider fromConfiguration);
		        vocabulary: SmallCodeVocabulary current;
		        yourself.
	chats add: chat.
	^ chat
]

{ #category : 'accessing' }
SmallCodeApp >> chats [

	^ chats
]

{ #category : 'accessing' }
SmallCodeApp >> configuration [

	^ configuration
]

{ #category : 'initialization' }
SmallCodeApp >> initialize [

	super initialize.
	configuration := SmallCodeConfiguration current.
	chats := OrderedCollection new
]

{ #category : 'opening' }
SmallCodeApp >> open [

	self presenter open
]

{ #category : 'accessing' }
SmallCodeApp >> presenter [

	^ SmallCodePresenter on: self
]

{ #category : 'removing' }
SmallCodeApp >> removeAllChats [

	chats removeAll
]

{ #category : 'removing' }
SmallCodeApp >> removeChatAt: anIndex [

	anIndex > 0 ifTrue: [ chats removeAt: anIndex ]
]
