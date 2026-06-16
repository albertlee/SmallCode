"
Metadata wrapper for a single tool/function available to the agent.
Stores name, description, JSON parameters schema, and the executable Smalltalk block.
Can be serialized to OpenAI function-calling tool format.

Converted from ChatPharoClient (MIT License, pharo-llm/chatpharo).
"
Class {
	#name : 'SmallCodeTool',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'parameters',
		'block'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeTool class >> name: aName description: aDescription parameters: aParametersSchema block: aBlock [

	^ self basicNew
		  initializeWithName: aName
		  description: aDescription
		  parameters: aParametersSchema
		  block: aBlock;
		  yourself
]

{ #category : 'initialization' }
SmallCodeTool >> initializeWithName: aName description: aDescription parameters: aParametersSchema block: aBlock [

	super initialize.
	name := aName.
	description := aDescription.
	parameters := aParametersSchema.
	block := aBlock
]

{ #category : 'execution' }
SmallCodeTool >> applyTo: argumentsDictionary [
	"Execute this tool with the given arguments."

	^ block value: argumentsDictionary
]

{ #category : 'converting' }
SmallCodeTool >> openAISchema [
	"Export as OpenAI function-calling tool schema."

	^ Dictionary
		  with: 'type' -> 'function'
		  with: 'function' -> (Dictionary
				   with: 'name' -> name
				   with: 'description' -> description
				   with: 'parameters' -> parameters)
]

{ #category : 'accessing' }
SmallCodeTool >> name [

	^ name
]

{ #category : 'accessing' }
SmallCodeTool >> name: aString [

	name := aString
]

{ #category : 'accessing' }
SmallCodeTool >> description [

	^ description
]

{ #category : 'accessing' }
SmallCodeTool >> description: aString [

	description := aString
]

{ #category : 'accessing' }
SmallCodeTool >> parameters [

	^ parameters
]

{ #category : 'accessing' }
SmallCodeTool >> parameters: aDictionary [

	parameters := aDictionary
]

{ #category : 'accessing' }
SmallCodeTool >> block [

	^ block
]

{ #category : 'accessing' }
SmallCodeTool >> block: aBlock [

	block := aBlock
]

{ #category : 'printing' }
SmallCodeTool >> printOn: aStream [

	aStream
		nextPutAll: 'Tool(';
		nextPutAll: name;
		nextPut: $)
]
