"
SmallCodeErrorPresenter displays an inline error banner with a Dismiss button.

Converted from ChatPharoErrorPresenter (MIT License, pharo-llm/chatpharo).
"
Class {
	#name : 'SmallCodeErrorPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'iconLabel',
		'errorLabel',
		'dismissButton',
		'errorMessage'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'layout' }
SmallCodeErrorPresenter >> defaultLayout [

	^ SpBoxLayout newHorizontal
		  spacing: 8;
		  vAlignCenter;
		  add: iconLabel expand: false;
		  add: errorLabel;
		  add: dismissButton expand: false;
		  yourself
]

{ #category : 'accessing' }
SmallCodeErrorPresenter >> errorMessage [

	^ errorMessage
]

{ #category : 'accessing' }
SmallCodeErrorPresenter >> errorMessage: aString [

	errorMessage := aString.
	self updateErrorLabel
]

{ #category : 'initialization' }
SmallCodeErrorPresenter >> initialize [

	super initialize.
	errorMessage := 'An error occurred'
]

{ #category : 'initialization' }
SmallCodeErrorPresenter >> initializePresenters [

	iconLabel := self newLabel
		             label: '[Error]';
		             yourself.
	errorLabel := self newLabel
		              label: 'An error occurred';
		              yourself.
	dismissButton := self newButton
		                 label: 'Dismiss';
		                 yourself
]

{ #category : 'updating' }
SmallCodeErrorPresenter >> updateErrorLabel [

	errorLabel label: errorMessage
]

{ #category : 'callbacks' }
SmallCodeErrorPresenter >> whenDismissedDo: aBlock [

	dismissButton action: aBlock
]
