"
SmallCodeChatPresenter is the UI for one chat tab. Shows a scrollable message column,
a text input field, and submit/cancel buttons. Receives push updates from the model
when a new assistant message arrives.

Converted from ChatPharoChatPresenter (MIT License, pharo-llm/chatpharo).
Simplified: removed slash commands, file attachments, pop-out, inspect, more menu.
"
Class {
	#name : 'SmallCodeChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messagesLayout',
		'messageTextField',
		'submitButton',
		'cancelButton',
		'model',
		'scrollableMessages',
		'thinkingPresenter',
		'errorPresenter'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'layout' }
SmallCodeChatPresenter >> defaultLayout [

	^ SpBoxLayout newVertical
		  spacing: 10;
		  add: scrollableMessages expand: true;
		  add: (SpBoxLayout newHorizontal
				   spacing: 5;
				   add: messageTextField;
				   add: (SpBoxLayout newHorizontal
						    add: submitButton expand: true;
						    add: cancelButton expand: true;
						    yourself)
				   withConstraints: [ :c |
					   c
						   width: 30;
						   padding: 0 ];
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> connectPresenters [

	model messages do: [ :each |
		messagesLayout add: each presenter withConstraints: [ :constraints |
			constraints height: each height ] ].

	messageTextField whenSubmitDo: [ :text | self sendMessage ].
	messageTextField whenTextChangedDo: [ :text |
		self updateSubmitButtonState ].

	submitButton action: [ self sendMessage ].
	self updateSubmitButtonState.

	cancelButton action: [
		model cancelMessage.
		self hideThinking.
		cancelButton visible: false.
		messageTextField text: ''.
		messageTextField enabled: true.
		self updateSubmitButtonState ].

	model whenAnswerReceivedDo: [ :uiMessage |
		self hideThinking.
		cancelButton visible: false.
		submitButton visible: true.
		messagesLayout add: uiMessage presenter withConstraints: [ :constraints |
			constraints height: uiMessage height ].
		messageTextField text: ''.
		self updateSubmitButtonState.
		messageTextField enabled: true ].

	model whenToolExecutionDo: [ :toolName |
		thinkingPresenter phase: #executing.
		thinkingPresenter addExecutedTool: toolName ].

	model whenErrorReceivedDo: [ :errorMessage |
		self hideThinking.
		cancelButton visible: false.
		self showError: errorMessage.
		self updateSubmitButtonState.
		messageTextField enabled: true ].

	model whenChatResetDo: [ self reloadMessages ]
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> hideError [

	messagesLayout remove: errorPresenter ifAbsent: [  ]
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> hideThinking [

	thinkingPresenter phase: #finished.
	thinkingPresenter stopAnimation.
	[
		(Delay forMilliseconds: 600) wait.
		thinkingPresenter isFinished ifTrue: [
			messagesLayout remove: thinkingPresenter ifAbsent: [  ] ] ]
		fork
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> initializePresenters [

	messageTextField := self newTextInput
		                   placeholder: 'Ask SmallCode to code something...';
		                   yourself.

	submitButton := self newButton
		                label: '';
		                icon: (self iconNamed: #smallDoIt);
		                help: 'Submit prompt';
		                yourself.

	cancelButton := self newButton
		                label: '';
		                icon: (self iconNamed: #smallCancel);
		                help: 'Cancel prompt';
		                visible: false;
		                yourself.

	thinkingPresenter := self instantiate: SmallCodeThinkingPresenter.
	errorPresenter := self instantiate: SmallCodeErrorPresenter.

	messagesLayout := SpBoxLayout newVertical.
	scrollableMessages := SpPresenter new.
	scrollableMessages layout: (SpScrollableLayout with: messagesLayout)
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'SmallCode Chat';
		initialExtent: 800 @ 500
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> reloadMessages [

	self hideThinking.
	self hideError.
	messagesLayout := SpBoxLayout newVertical.
	scrollableMessages layout: (SpScrollableLayout with: messagesLayout).
	model messages do: [ :each |
		messagesLayout add: each presenter ].
	messageTextField text: ''.
	cancelButton visible: false.
	messageTextField enabled: true.
	self updateSubmitButtonState
]

{ #category : 'running' }
SmallCodeChatPresenter >> sendMessage [

	| text |
	text := (messageTextField text ifNil: [ '' ]) asString.
	text trimBoth ifEmpty: [ ^ self ].

	model provider ifNil: [
		^ self inform: 'Please configure an LLM provider first.' ].
	model provider isConfigured ifFalse: [
		^ self inform: 'LLM provider not configured. Use: SmallCodeConfiguration current apiKey: ''your-key''' ].

	submitButton visible: false.
	cancelButton visible: true.
	messageTextField enabled: false.
	messageTextField text: ''.
	self showThinking.
	model sendMessage: text
]

{ #category : 'accessing - model' }
SmallCodeChatPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> showError: aString [

	errorPresenter ifNil: [
		errorPresenter := self instantiate: SmallCodeErrorPresenter ].
	self hideError.
	errorPresenter errorMessage: aString.
	errorPresenter whenDismissedDo: [ self hideError ].
	messagesLayout add: errorPresenter withConstraints: [ :constraints |
		constraints height: 40 ]
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> showThinking [

	messagesLayout remove: thinkingPresenter ifAbsent: [  ].
	thinkingPresenter clearExecutedTools.
	thinkingPresenter phase: #thinking.
	thinkingPresenter startAnimation.
	messagesLayout add: thinkingPresenter withConstraints: [ :constraints |
		constraints height: 40 ]
]

{ #category : 'initialization' }
SmallCodeChatPresenter >> updateSubmitButtonState [

	submitButton enabled: (messageTextField isEnabled and: [
			 (messageTextField text ifNil: [ '' ]) asString trimBoth
				 isNotEmpty ])
]
