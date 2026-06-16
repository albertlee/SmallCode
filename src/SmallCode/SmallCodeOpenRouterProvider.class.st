"
OpenRouter LLM provider. Uses the OpenAI-compatible API at openrouter.ai.
Supports function-calling (tools) for models that support it.

Usage:
  provider := SmallCodeOpenRouterProvider withApiKey: 'sk-or-...'.
  provider model: 'google/gemini-2.5-flash'.
  response := provider complete: messages tools: toolSchemas.
"
Class {
	#name : 'SmallCodeOpenRouterProvider',
	#superclass : 'SmallCodeProvider',
	#instVars : [
		'appName',
		'appURL'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeOpenRouterProvider class >> withApiKey: aString [

	^ self new
		  apiKey: aString;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeOpenRouterProvider class >> fromConfiguration [
	"Create from global SmallCodeConfiguration."

	| config |
	config := SmallCodeConfiguration current.
	config validateConfiguration.
	^ self new
		  apiKey: config apiKey;
		  model: config model;
		  baseURL: config baseURL;
		  temperature: config temperature;
		  maxTokens: config maxTokens;
		  yourself
]

{ #category : 'initialization' }
SmallCodeOpenRouterProvider >> initialize [

	super initialize.
	baseURL := 'https://openrouter.ai/api/v1'.
	model := 'google/gemini-2.5-flash'.
	temperature := 0.2.
	maxTokens := 8192.
	appName := 'SmallCode'.
	appURL := 'https://github.com/hanzhupeng/SmallCode'
]

{ #category : 'api' }
SmallCodeOpenRouterProvider >> complete: messages tools: toolSchemas [
	"Send chat completion to OpenRouter with optional function-calling tools.
	 Returns a SmallCodeMessage."

	| payload response messageDict |
	payload := self buildRequestPayload: messages tools: toolSchemas.
	response := self sendRequest: payload.
	messageDict := self extractMessage: response.
	^ self parseMessageDict: messageDict
]

{ #category : 'private' }
SmallCodeOpenRouterProvider >> buildRequestPayload: messages tools: toolSchemas [
	"Build the JSON request body."

	| data |
	data := Dictionary new.
	data at: 'model' put: model.
	data at: 'messages' put: (self buildMessagesPayload: messages).
	temperature ifNotNil: [ data at: 'temperature' put: temperature ].
	maxTokens ifNotNil: [ data at: 'max_tokens' put: maxTokens ].
	toolSchemas ifNotNil: [
		toolSchemas ifNotEmpty: [
			data at: 'tools' put: toolSchemas asArray.
			data at: 'tool_choice' put: 'auto' ] ].
	^ data
]

{ #category : 'private' }
SmallCodeOpenRouterProvider >> sendRequest: payloadDict [
	"POST to /chat/completions and return parsed JSON response."

	| client response jsonString |
	client := ZnClient new
		          url: baseURL , '/chat/completions';
		          entity: (ZnEntity json: (STONJSON toString: payloadDict));
		          headerAt: 'Authorization' put: 'Bearer ' , apiKey;
		          headerAt: 'HTTP-Referer' put: appURL;
		          headerAt: 'X-Title' put: appName;
		          timeout: 120;
		          yourself.
	[ jsonString := client post ]
		ensure: [ client close ].
	jsonString ifNil: [ Error signal: 'No response from OpenRouter' ].
	^ [ STONJSON fromString: jsonString ]
		  on: Error
		  do: [ :e | Error signal: 'Failed to parse response: ' , e messageText ]
]

{ #category : 'private' }
SmallCodeOpenRouterProvider >> extractMessage: jsonResponse [
	"Extract the assistant message dict from the API response."

	| choices |
	choices := jsonResponse at: 'choices' ifAbsent: [ #() ].
	choices ifEmpty: [
		| errorMsg |
		errorMsg := jsonResponse at: 'error' ifAbsent: [ jsonResponse ].
		Error signal: 'Empty response from LLM: ' , errorMsg asString ].
	^ choices first at: 'message'
]

{ #category : 'private' }
SmallCodeOpenRouterProvider >> parseMessageDict: messageDict [
	"Parse the raw message dictionary into a SmallCodeMessage."

	| content toolCallDicts toolCalls |
	content := messageDict at: 'content' ifAbsent: [ nil ].
	toolCallDicts := messageDict at: 'tool_calls' ifAbsent: [ nil ].
	toolCalls := toolCallDicts ifNotNil: [
		             toolCallDicts collect: [ :tc | SmallCodeToolCall fromOpenAIDict: tc ] ].
	toolCalls ifNotNil: [ toolCalls ifNotEmpty: [
		^ SmallCodeMessage assistantWithToolCalls: toolCalls ] ].
	^ SmallCodeMessage assistant: (content ifNil: [ '' ])
]

{ #category : 'accessing' }
SmallCodeOpenRouterProvider >> appName [

	^ appName
]

{ #category : 'accessing' }
SmallCodeOpenRouterProvider >> appName: aString [

	appName := aString
]

{ #category : 'accessing' }
SmallCodeOpenRouterProvider >> appURL [

	^ appURL
]

{ #category : 'accessing' }
SmallCodeOpenRouterProvider >> appURL: aString [

	appURL := aString
]
