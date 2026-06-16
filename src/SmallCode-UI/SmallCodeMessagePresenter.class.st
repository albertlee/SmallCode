"
SmallCodeMessagePresenter renders one SmallCodeUIMessage using Microdown for rich text.
Shows the user's content, an optional 'thinking' block, and the assistant's answer.
Includes a Copy button with mouse-hover overlay.

Converted from ChatPharoMessagePresenter (MIT License, pharo-llm/chatpharo).
Simplified: removed feedback buttons (Good/Bad) for minimal core.
"
Class {
	#name : 'SmallCodeMessagePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'contentPresenter',
		'thinkingPresenter',
		'answerPresenter',
		'copyButton'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'initialization' }
SmallCodeMessagePresenter >> connectPresenters [

	contentPresenter document: (Microdown parse: model content).
	thinkingPresenter document: (Microdown parse: model thinking).
	answerPresenter document: (Microdown parse: model answer)
]

{ #category : 'layout' }
SmallCodeMessagePresenter >> defaultLayout [

	| layout answerContainer |
	answerContainer := SpOverlayLayout new.
	answerContainer
		child: answerPresenter;
		addOverlay: copyButton withConstraints: [ :c |
			c
				vAlignStart;
				hAlignEnd ].
	answerPresenter eventHandler
		whenMouseEnterDo: [ :evt | copyButton visible: true ];
		whenMouseLeaveDo: [ :evt | copyButton visible: false ].
	layout := SpBoxLayout newVertical
		          add: 'User' expand: false;
		          add: contentPresenter withConstraints: [ :c |
			          c height: (self estimatedHeightFor: model content) ];
		          add: model assistantLabel expand: false;
		          add: answerContainer withConstraints: [ :c |
			          c height: (self estimatedHeightFor: model answer) ];
		          yourself.
	^ layout yourself
]

{ #category : 'accessing' }
SmallCodeMessagePresenter >> estimatedHeightFor: aString [

	| text lineCount lineHeight minHeight maxHeight |
	text := aString ifNil: [ '' ].
	lineHeight := 20.
	minHeight := 30.
	maxHeight := 500.
	lineCount := self estimatedLineCountFor: text.
	^ (minHeight max: lineCount * lineHeight) min: maxHeight
]

{ #category : 'accessing' }
SmallCodeMessagePresenter >> estimatedLineCountFor: aString [

	| text wrapWidth |
	text := aString ifNil: [ '' ].
	wrapWidth := 80.
	^ (text lines ifEmpty: [ #( '' ) ]) inject: 0 into: [ :sum :line |
		  sum + (((line size / wrapWidth) ceiling) max: 1) ]
]

{ #category : 'accessing' }
SmallCodeMessagePresenter >> height [

	| baseHeight lineHeight contentLines answerLines |
	baseHeight := 48.
	lineHeight := 24.
	contentLines := self estimatedLineCountFor: model content.
	answerLines := self estimatedLineCountFor: model answer.
	^ baseHeight + ((contentLines + answerLines) * lineHeight)
]

{ #category : 'initialization' }
SmallCodeMessagePresenter >> initializePresenters [

	contentPresenter := MicrodownPresenter new.
	thinkingPresenter := MicrodownPresenter new.
	answerPresenter := MicrodownPresenter new.

	copyButton := self newButton
		              icon: (self iconNamed: #smallCopy);
		              label: '';
		              help: 'Copy answer to clipboard';
		              action: [
			              Clipboard clipboardText:
				              (model answer ifNil: [ '' ]).
			              UIManager default inform: 'Copied to clipboard' ];
		              yourself.
	copyButton visible: true
]

{ #category : 'initialization' }
SmallCodeMessagePresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Message';
		initialExtent: 400 @ 200
]

{ #category : 'accessing - model' }
SmallCodeMessagePresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]
