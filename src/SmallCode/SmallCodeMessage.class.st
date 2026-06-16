"
SmallCodeMessage wraps a single message in the OpenAI chat protocol.
Supports roles: system, user, assistant, tool.
Assistant messages may carry tool_calls; tool messages carry tool_call_id.
"
Class {
	#name : 'SmallCodeMessage',
	#superclass : 'Object',
	#instVars : [
		'role',
		'content',
		'toolCalls',
		'toolCallId',
		'name'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeMessage class >> assistant: aString [

	^ self role: 'assistant' content: aString
]

{ #category : 'instance creation' }
SmallCodeMessage class >> assistantWithToolCalls: aToolCallsArray [

	^ self new
		  role: 'assistant';
		  content: nil;
		  toolCalls: aToolCallsArray;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeMessage class >> role: aRole content: aString [

	^ self new
		  role: aRole;
		  content: aString;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeMessage class >> system: aString [

	^ self role: 'system' content: aString
]

{ #category : 'instance creation' }
SmallCodeMessage class >> toolResult: aString callId: anId [

	^ self new
		  role: 'tool';
		  content: aString;
		  toolCallId: anId;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeMessage class >> user: aString [

	^ self role: 'user' content: aString
]

{ #category : 'converting' }
SmallCodeMessage >> asOpenAIDict [
	"Convert to the Dictionary format expected by OpenAI API."

	| dict |
	dict := Dictionary new.
	dict at: 'role' put: role.
	content ifNotNil: [ dict at: 'content' put: content ].
	toolCalls ifNotNil: [
		toolCalls ifNotEmpty: [
			dict at: 'tool_calls' put: (toolCalls collect: [ :tc | tc asOpenAIDict ]) ] ].
	toolCallId ifNotNil: [ dict at: 'tool_call_id' put: toolCallId ].
	name ifNotNil: [ dict at: 'name' put: name ].
	^ dict
]

{ #category : 'accessing' }
SmallCodeMessage >> content [

	^ content
]

{ #category : 'accessing' }
SmallCodeMessage >> content: aString [

	content := aString
]

{ #category : 'testing' }
SmallCodeMessage >> hasToolCalls [

	^ toolCalls isNotNil and: [ toolCalls isNotEmpty ]
]

{ #category : 'testing' }
SmallCodeMessage >> isToolResult [

	^ role = 'tool'
]

{ #category : 'accessing' }
SmallCodeMessage >> name [

	^ name
]

{ #category : 'accessing' }
SmallCodeMessage >> name: aString [

	name := aString
]

{ #category : 'printing' }
SmallCodeMessage >> printOn: aStream [

	aStream
		nextPutAll: 'Msg(';
		nextPutAll: role;
		nextPutAll: ': '.
	content ifNotNil: [
		aStream nextPutAll: (content copyFrom: 1 to: (content size min: 60)) ].
	self hasToolCalls ifTrue: [
		aStream nextPutAll: ' ['; print: toolCalls size; nextPutAll: ' tool_calls]' ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
SmallCodeMessage >> role [

	^ role
]

{ #category : 'accessing' }
SmallCodeMessage >> role: aString [

	role := aString
]

{ #category : 'accessing' }
SmallCodeMessage >> toolCallId [

	^ toolCallId
]

{ #category : 'accessing' }
SmallCodeMessage >> toolCallId: aString [

	toolCallId := aString
]

{ #category : 'accessing' }
SmallCodeMessage >> toolCalls [

	^ toolCalls
]

{ #category : 'accessing' }
SmallCodeMessage >> toolCalls: anArray [

	toolCalls := anArray
]
