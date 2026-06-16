"
SmallCodeThinkingPresenter shows an animated 'Thinking...' indicator while the LLM is processing.
Displays model name, elapsed time, phase (#thinking / #executing / #analyzing / #finished),
and tool execution list.

Converted from ChatPharoThinkingPresenter (MIT License, pharo-llm/chatpharo).
Simplified: removed owner chain navigation for hideThinking (uses callback instead).
"
Class {
	#name : 'SmallCodeThinkingPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'statusLabel',
		'dotsLabel',
		'animationProcess',
		'currentPhase',
		'showDetailsButton',
		'hideButton',
		'thinkingContent',
		'thinkingStartedAt',
		'thinkingElapsedSeconds',
		'modelNameLabel',
		'executedTools',
		'toolsLabel',
		'onHide'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> addExecutedTool: aToolName [

	aToolName ifNil: [ ^ self ].
	executedTools add: aToolName.
	self updateToolsLabel
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> clearExecutedTools [

	executedTools removeAll.
	self updateToolsLabel
]

{ #category : 'layout' }
SmallCodeThinkingPresenter >> defaultLayout [

	| layout |
	layout := SpBoxLayout newHorizontal
		          spacing: 5;
		          vAlignCenter;
		          add: modelNameLabel expand: false;
		          add: statusLabel expand: false;
		          add: dotsLabel expand: false;
		          add: toolsLabel expand: false;
		          yourself.
	layout add: hideButton expand: false.
	^ layout
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> formattedElapsedThinkingTime [

	| minutes secondsLabel totalSeconds |
	totalSeconds := thinkingElapsedSeconds.
	minutes := totalSeconds // 60.
	secondsLabel := totalSeconds \\ 60.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: minutes asString;
			  nextPutAll: ' min ';
			  nextPutAll: secondsLabel asString;
			  nextPutAll: 's' ]
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> initialize [

	super initialize.
	currentPhase := #thinking.
	thinkingStartedAt := nil.
	thinkingElapsedSeconds := 0.
	executedTools := OrderedCollection new
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> initializePresenters [

	statusLabel := self newLabel
		               label: 'Thinking';
		               yourself.
	modelNameLabel := self newLabel
		                  label: '';
		                  yourself.

	dotsLabel := self newLabel
		             label: '';
		             yourself.
	showDetailsButton := self newButton
		                     label: 'Details';
		                     action: [ self openThinkingDetails ];
		                     yourself.

	hideButton := self newButton
		              label: 'Hide';
		              help: 'Hide thinking indicator';
		              action: [
			              self stopAnimation.
			              onHide ifNotNil: [ :blk | blk value ] ];
		              yourself.

	toolsLabel := self newLabel
		              label: '';
		              yourself
]

{ #category : 'testing' }
SmallCodeThinkingPresenter >> isFinished [

	^ currentPhase = #finished
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> openThinkingDetails [

	thinkingContent ifEmpty: [ ^ self ].
	| detailPresenter |
	detailPresenter := SmallCodeThinkingDetailPresenter new.
	detailPresenter thinkingContent: thinkingContent.
	detailPresenter open
]

{ #category : 'accessing' }
SmallCodeThinkingPresenter >> phase: aSymbol [
	"Valid phases: #thinking, #executing, #analyzing, #finished"

	currentPhase := aSymbol.
	aSymbol = #finished ifTrue: [ self updateElapsedThinkingTime ].
	self updateStatusLabel
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> startAnimation [

	animationProcess ifNotNil: [ animationProcess terminate ].
	thinkingStartedAt := DateAndTime now.
	thinkingElapsedSeconds := 0.
	self clearExecutedTools.
	animationProcess := [
		                    | dots |
		                    dots := 0.
		                    [ true ] whileTrue: [
				                    dots := dots + 1 \\ 4.
				                    dotsLabel label: ('.' repeat: dots).
				                    thinkingElapsedSeconds :=
					                    (DateAndTime now - thinkingStartedAt) asSeconds rounded
						                    max: 0.
				                    self updateStatusLabel.
				                    (Delay forMilliseconds: 400) wait ] ] fork
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> stopAnimation [

	animationProcess ifNotNil: [
		animationProcess terminate.
		animationProcess := nil ].
	dotsLabel label: ''
]

{ #category : 'accessing' }
SmallCodeThinkingPresenter >> thinkingContent [

	^ thinkingContent ifNil: [ '' ]
]

{ #category : 'accessing' }
SmallCodeThinkingPresenter >> thinkingContent: aString [

	thinkingContent := aString
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> updateElapsedThinkingTime [

	thinkingStartedAt ifNil: [
		thinkingElapsedSeconds := 0.
		^ self ].
	thinkingElapsedSeconds := ((DateAndTime now - thinkingStartedAt) asSeconds rounded) max: 0
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> updateStatusLabel [

	| phaseText text |
	phaseText := currentPhase
		             caseOf: {
				             ([ #thinking ] -> [ 'Thinking' ]).
				             ([ #executing ] -> [ 'Executing tools' ]).
				             ([ #analyzing ] -> [ 'Analyzing' ]).
				             ([ #finished ] -> [ 'Done' ]) }
		             otherwise: [ 'Thinking' ].

	text := phaseText , ' (' , self formattedElapsedThinkingTime , ')'.
	statusLabel label: text
]

{ #category : 'initialization' }
SmallCodeThinkingPresenter >> updateToolsLabel [

	executedTools ifEmpty: [
		toolsLabel label: ''.
		^ self ].
	toolsLabel label: '| Tools: ' , (', ' join: executedTools)
]

{ #category : 'callbacks' }
SmallCodeThinkingPresenter >> whenHideDo: aBlock [

	onHide := aBlock
]
