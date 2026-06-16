"
Abstract LLM provider. Subclasses implement the HTTP transport for specific API providers.
All providers use the OpenAI-compatible chat/completions format with function-calling.
"
Class {
	#name : 'SmallCodeProvider',
	#superclass : 'Object',
	#instVars : [
		'apiKey',
		'model',
		'baseURL',
		'temperature',
		'maxTokens'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeProvider class >> fromConfiguration [
	"Create a provider from the global SmallCodeConfiguration."

	self subclassResponsibility
]

{ #category : 'accessing' }
SmallCodeProvider >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
SmallCodeProvider >> apiKey: aString [

	apiKey := aString
]

{ #category : 'accessing' }
SmallCodeProvider >> baseURL [

	^ baseURL
]

{ #category : 'accessing' }
SmallCodeProvider >> baseURL: aString [

	baseURL := aString
]

{ #category : 'private' }
SmallCodeProvider >> buildMessagesPayload: messages [
	"Convert SmallCodeMessage collection to OpenAI JSON array."

	^ (messages collect: [ :msg | msg asOpenAIDict ]) asArray
]

{ #category : 'api' }
SmallCodeProvider >> complete: messages [
	"Send messages without tools. Returns a SmallCodeMessage."

	^ self complete: messages tools: nil
]

{ #category : 'api' }
SmallCodeProvider >> complete: messages tools: toolSchemas [
	"Main entry: send messages + optional tool schemas to LLM.
	 messages: OrderedCollection of SmallCodeMessage.
	 toolSchemas: Array of OpenAI tool schema Dictionaries, or nil.
	 Returns a SmallCodeMessage (assistant role, possibly with tool_calls)."

	self subclassResponsibility
]

{ #category : 'testing' }
SmallCodeProvider >> isConfigured [

	^ apiKey isNotNil and: [ apiKey isNotEmpty ]
]

{ #category : 'accessing' }
SmallCodeProvider >> maxTokens [

	^ maxTokens
]

{ #category : 'accessing' }
SmallCodeProvider >> maxTokens: anInteger [

	maxTokens := anInteger
]

{ #category : 'accessing' }
SmallCodeProvider >> model [

	^ model
]

{ #category : 'accessing' }
SmallCodeProvider >> model: aString [

	model := aString
]

{ #category : 'printing' }
SmallCodeProvider >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		nextPutAll: (model ifNil: [ '?' ]);
		nextPut: $)
]

{ #category : 'accessing' }
SmallCodeProvider >> temperature [

	^ temperature
]

{ #category : 'accessing' }
SmallCodeProvider >> temperature: aNumber [

	temperature := aNumber
]
