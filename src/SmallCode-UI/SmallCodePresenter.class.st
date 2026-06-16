"
SmallCodePresenter is the main window shell. Shows a toolbar and a notebook of chat tabs.
Each notebook page's presenterProvider yields a SmallCodeChatPresenter.

Usage:
  SmallCodeApp open
"
Class {
	#name : 'SmallCodePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'notebook',
		'toolbar',
		'chatCounter'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'adding' }
SmallCodePresenter >> addNewChat [

	| newPage chatName newChat |
	chatCounter := chatCounter + 1.
	chatName := 'Chat ' , chatCounter asString.
	newChat := model addNewChat.

	newChat toolFactory: (SmallCodeToolFactory
			 projector: newChat projector
			 vocabulary: newChat vocabulary).

	newPage := SpNotebookPage
		           title: chatName
		           icon: (self iconNamed: #announcement)
		           provider: [ newChat presenter ].
	notebook addPage: newPage.
	notebook selectPage: newPage.

	notebook pages ifEmpty: [ self addNewChat ]
]

{ #category : 'layout' }
SmallCodePresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: toolbar expand: false;
		  add: notebook expand: true;
		  yourself
]

{ #category : 'deleting' }
SmallCodePresenter >> deleteAllChats [

	(self confirm: 'Are you sure you want to delete all chats?') ifFalse: [
		^ self ].
	notebook pages copy do: [ :page | notebook removePage: page ].
	model removeAllChats
]

{ #category : 'deleting' }
SmallCodePresenter >> deleteSelectedChat [

	| pageTitle pageIndex |
	notebook selectedPage ifNil: [ ^ self inform: 'No chat selected.' ].
	pageTitle := notebook selectedPage title.
	(self confirm: 'Delete this chat?') ifFalse: [ ^ self ].
	pageIndex := notebook pages indexOf: notebook selectedPage ifAbsent: [
		             ^ self ].
	notebook removePage: notebook selectedPage.
	model removeChatAt: pageIndex.
	notebook pages ifEmpty: [ self addNewChat ]
]

{ #category : 'initialization' }
SmallCodePresenter >> initializePresenters [

	chatCounter := 0.
	notebook := self newNotebook.
	toolbar := self newToolbar.

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'New Chat';
			 icon: (self iconNamed: #add);
			 help: 'Create a new chat';
			 action: [ self addNewChat ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Delete Chat';
			 icon: (self iconNamed: #delete);
			 help: 'Delete the selected chat';
			 action: [ self deleteSelectedChat ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Delete All';
			 icon: (self iconNamed: #delete);
			 help: 'Delete all chats';
			 action: [ self deleteAllChats ];
			 yourself).

	notebook pages ifEmpty: [ self addNewChat ]
]

{ #category : 'initialization' }
SmallCodePresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'SmallCode';
		initialExtent: 900 @ 600
]

{ #category : 'accessing - model' }
SmallCodePresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]
