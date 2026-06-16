"
SmallCodeThinkingDetailPresenter displays the full thinking content from reasoning models.

Converted from ChatPharoThinkingDetailPresenter (MIT License, pharo-llm/chatpharo).
"
Class {
	#name : 'SmallCodeThinkingDetailPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'thinkingText',
		'closeButton',
		'thinkingContent'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'layout' }
SmallCodeThinkingDetailPresenter >> defaultLayout [

	^ SpBoxLayout newVertical
		  spacing: 10;
		  add: titleLabel expand: false;
		  add: thinkingText;
		  add: closeButton expand: false;
		  yourself
]

{ #category : 'initialization' }
SmallCodeThinkingDetailPresenter >> initialize [

	super initialize.
	thinkingContent := ''
]

{ #category : 'initialization' }
SmallCodeThinkingDetailPresenter >> initializePresenters [

	titleLabel := self newLabel label: 'Thinking Details'.
	thinkingText := self newText
		                text: '';
		                editable: false;
		                yourself.
	closeButton := self newButton
		               label: 'Close';
		               action: [ self window close ];
		               yourself
]

{ #category : 'initialization' }
SmallCodeThinkingDetailPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Thinking Details';
		initialExtent: 800 @ 600
]

{ #category : 'accessing' }
SmallCodeThinkingDetailPresenter >> thinkingContent [

	^ thinkingContent
]

{ #category : 'accessing' }
SmallCodeThinkingDetailPresenter >> thinkingContent: aString [

	thinkingContent := aString.
	thinkingText text:
		(thinkingContent ifNil: [ 'No thinking content available' ])
]
