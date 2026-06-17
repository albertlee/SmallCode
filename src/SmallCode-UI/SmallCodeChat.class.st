"
SmallCodeChat is one conversation transcript. Keeps a UI-facing list of SmallCodeUIMessage objects and
an API-facing list of SmallCodeMessage objects. Drives asynchronous prompting: forks a process that
asks the LLM provider and posts the assistant reply back into both collections.

Supports tool-calling: if the LLM response contains tool_calls, they are executed and results are
sent back to the LLM in a follow-up request (up to maxToolRounds).
"
Class {
	#name : 'SmallCodeChat',
	#superclass : 'Object',
	#instVars : [
		'messages',
		'history',
		'provider',
		'projector',
		'vocabulary',
		'toolFactory',
		'promptProcess',
		'maxToolRounds',
		'onAnswerReceived',
		'onErrorReceived',
		'onToolExecution',
		'onChatReset'
	],
	#category : 'SmallCode-UI',
	#package : 'SmallCode-UI'
}

{ #category : 'running' }
SmallCodeChat >> cancelMessage [

	promptProcess ifNotNil: [ :p | p terminate ]
]

{ #category : 'running' }
SmallCodeChat >> clearChat [

	messages removeAll.
	history removeAll.
	projector reset.
	onChatReset ifNotNil: [ :blk | blk value ]
]

{ #category : 'private' }
SmallCodeChat >> executeToolCalls: toolCalls [
	"Execute each tool call and add results to history"

	toolCalls do: [ :tc |
		| result resultJson |
		UIManager default defer: [
			onToolExecution ifNotNil: [ :blk | blk value: tc functionName ] ].

		result := toolFactory
			          ifNil: [ Dictionary with: 'error' -> 'No tool factory' ]
			          ifNotNil: [
			          toolFactory executeTool: tc functionName arguments: tc arguments ].
		resultJson := STONJSON toString: result.
		history add: (SmallCodeMessage toolResult: resultJson callId: tc id) ]
]

{ #category : 'initialization' }
SmallCodeChat >> initialize [

	super initialize.
	messages := OrderedCollection new.
	history := OrderedCollection new.
	projector := SmallCodeProjector new.
	maxToolRounds := 5
]

{ #category : 'accessing' }
SmallCodeChat >> messages [

	^ messages
]

{ #category : 'accessing' }
SmallCodeChat >> presenter [

	^ SmallCodeChatPresenter on: self
]

{ #category : 'accessing' }
SmallCodeChat >> projector [

	^ projector
]

{ #category : 'accessing' }
SmallCodeChat >> provider [

	^ provider
]

{ #category : 'accessing' }
SmallCodeChat >> provider: aProvider [

	provider := aProvider
]

{ #category : 'private' }
SmallCodeChat >> runConversation: uiMessage [
	"Run the LLM conversation loop. Handles tool calls up to maxToolRounds."

	| toolSchemas rounds response |
	toolSchemas := toolFactory
		               ifNil: [ nil ]
		               ifNotNil: [ toolFactory allToolSchemas ].
	rounds := 0.

	[
	rounds >= maxToolRounds ifTrue: [
		uiMessage answer: 'Max tool rounds reached.'.
		UIManager default defer: [
			onAnswerReceived ifNotNil: [ :blk | blk value: uiMessage ] ].
		^ self ].

	response := provider complete: history tools: toolSchemas.
	history add: response.

	response hasToolCalls
		ifTrue: [
			rounds := rounds + 1.
			self executeToolCalls: response toolCalls ]
		ifFalse: [
			uiMessage
				answer: (response content ifNil: [ '' ]);
				thinking: ''.
			UIManager default defer: [
				onAnswerReceived ifNotNil: [ :blk | blk value: uiMessage ] ].
			^ self ] ] repeat
]

{ #category : 'running' }
SmallCodeChat >> sendMessage: text [

	| uiMessage |
	text trimBoth ifEmpty: [ ^ self ].

	uiMessage := SmallCodeUIMessage new
		             content: text;
		             yourself.
	messages add: uiMessage.
	history add: (SmallCodeMessage user: text).

	promptProcess := [
	                  self runConversation: uiMessage
	                 ] forkAt: Processor userBackgroundPriority
]

{ #category : 'accessing' }
SmallCodeChat >> toolFactory [

	^ toolFactory
]

{ #category : 'accessing' }
SmallCodeChat >> toolFactory: aFactory [

	toolFactory := aFactory
]

{ #category : 'accessing' }
SmallCodeChat >> vocabulary [

	^ vocabulary
]

{ #category : 'accessing' }
SmallCodeChat >> vocabulary: aVocabulary [

	vocabulary := aVocabulary.
	projector vocabulary: aVocabulary
]

{ #category : 'callbacks' }
SmallCodeChat >> whenAnswerReceivedDo: aBlock [

	onAnswerReceived := aBlock
]

{ #category : 'callbacks' }
SmallCodeChat >> whenChatResetDo: aBlock [

	onChatReset := aBlock
]

{ #category : 'callbacks' }
SmallCodeChat >> whenErrorReceivedDo: aBlock [

	onErrorReceived := aBlock
]

{ #category : 'callbacks' }
SmallCodeChat >> whenToolExecutionDo: aBlock [

	onToolExecution := aBlock
]
