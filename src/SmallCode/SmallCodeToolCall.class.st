"
SmallCodeToolCall represents a single tool invocation from the LLM response.
Maps to the OpenAI tool_calls[i] structure: id, function name, arguments.
"
Class {
	#name : 'SmallCodeToolCall',
	#superclass : 'Object',
	#instVars : [
		'id',
		'functionName',
		'arguments'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeToolCall class >> fromOpenAIDict: aDict [
	"Parse from OpenAI response format:
	 {id: 'call_xxx', type: 'function', function: {name: '...', arguments: '{...}'}}"

	| fn rawArgs parsedArgs |
	fn := (aDict at: 'function') at: 'name'.
	rawArgs := (aDict at: 'function') at: 'arguments' ifAbsent: [ '{}' ].
	parsedArgs := rawArgs isString
		              ifTrue: [
			              [ STONJSON fromString: rawArgs ]
				              on: Error
				              do: [ :e | Dictionary with: 'error' -> 'Invalid JSON arguments' ] ]
		              ifFalse: [ rawArgs ifNil: [ Dictionary new ] ].
	^ self
		  id: (aDict at: 'id' ifAbsent: [ 'call_' , DateAndTime now asUnixTime printString ])
		  functionName: fn
		  arguments: parsedArgs
]

{ #category : 'instance creation' }
SmallCodeToolCall class >> id: anId functionName: aName arguments: aDict [

	^ self new
		  id: anId;
		  functionName: aName;
		  arguments: aDict;
		  yourself
]

{ #category : 'accessing' }
SmallCodeToolCall >> arguments [

	^ arguments
]

{ #category : 'accessing' }
SmallCodeToolCall >> arguments: aDictionary [

	arguments := aDictionary
]

{ #category : 'converting' }
SmallCodeToolCall >> asOpenAIDict [
	"Convert back to OpenAI format for message history."

	^ Dictionary
		  with: 'id' -> id
		  with: 'type' -> 'function'
		  with: 'function' -> (Dictionary
				   with: 'name' -> functionName
				   with: 'arguments' -> (STONJSON toString: arguments))
]

{ #category : 'accessing' }
SmallCodeToolCall >> functionName [

	^ functionName
]

{ #category : 'accessing' }
SmallCodeToolCall >> functionName: aString [

	functionName := aString
]

{ #category : 'accessing' }
SmallCodeToolCall >> id [

	^ id
]

{ #category : 'accessing' }
SmallCodeToolCall >> id: aString [

	id := aString
]

{ #category : 'printing' }
SmallCodeToolCall >> printOn: aStream [

	aStream
		nextPutAll: 'ToolCall(';
		nextPutAll: functionName;
		nextPutAll: ' #';
		nextPutAll: id asString;
		nextPut: $)
]
