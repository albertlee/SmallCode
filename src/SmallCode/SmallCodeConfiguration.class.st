"
SmallCodeConfiguration holds API keys, model settings, and system defaults.
Singleton accessed via `SmallCodeConfiguration current`.
"
Class {
	#name : 'SmallCodeConfiguration',
	#superclass : 'Object',
	#instVars : [
		'apiKey',
		'model',
		'baseURL',
		'temperature',
		'maxTokens',
		'maxAgentSteps',
		'sandboxEnabled',
		'sandboxTimeout',
		'domainPackages'
	],
	#classInstVars : [
		'current'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'accessing' }
SmallCodeConfiguration class >> current [

	^ current ifNil: [ current := self new ]
]

{ #category : 'accessing' }
SmallCodeConfiguration class >> reset [

	<script>
	current := nil
]

{ #category : 'initialization' }
SmallCodeConfiguration >> initialize [

	super initialize.
	baseURL := 'https://openrouter.ai/api/v1'.
	model := 'google/gemini-2.5-flash'.
	temperature := 0.2.
	maxTokens := 8192.
	maxAgentSteps := 20.
	sandboxEnabled := true.
	sandboxTimeout := 5000.
	domainPackages := OrderedCollection new
]

{ #category : 'accessing' }
SmallCodeConfiguration >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
SmallCodeConfiguration >> apiKey: aString [

	apiKey := aString
]

{ #category : 'accessing' }
SmallCodeConfiguration >> model [

	^ model
]

{ #category : 'accessing' }
SmallCodeConfiguration >> model: aString [

	model := aString
]

{ #category : 'accessing' }
SmallCodeConfiguration >> baseURL [

	^ baseURL
]

{ #category : 'accessing' }
SmallCodeConfiguration >> baseURL: aString [

	baseURL := aString
]

{ #category : 'accessing' }
SmallCodeConfiguration >> temperature [

	^ temperature
]

{ #category : 'accessing' }
SmallCodeConfiguration >> temperature: aNumber [

	temperature := aNumber
]

{ #category : 'accessing' }
SmallCodeConfiguration >> maxTokens [

	^ maxTokens
]

{ #category : 'accessing' }
SmallCodeConfiguration >> maxTokens: anInteger [

	maxTokens := anInteger
]

{ #category : 'accessing' }
SmallCodeConfiguration >> maxAgentSteps [

	^ maxAgentSteps
]

{ #category : 'accessing' }
SmallCodeConfiguration >> maxAgentSteps: anInteger [

	maxAgentSteps := anInteger
]

{ #category : 'accessing' }
SmallCodeConfiguration >> sandboxEnabled [

	^ sandboxEnabled
]

{ #category : 'accessing' }
SmallCodeConfiguration >> sandboxEnabled: aBoolean [

	sandboxEnabled := aBoolean
]

{ #category : 'accessing' }
SmallCodeConfiguration >> sandboxTimeout [

	^ sandboxTimeout
]

{ #category : 'accessing' }
SmallCodeConfiguration >> sandboxTimeout: anInteger [

	sandboxTimeout := anInteger
]

{ #category : 'accessing' }
SmallCodeConfiguration >> domainPackages [

	^ domainPackages
]

{ #category : 'accessing' }
SmallCodeConfiguration >> domainPackages: aCollection [

	domainPackages := aCollection asOrderedCollection
]

{ #category : 'testing' }
SmallCodeConfiguration >> isConfigured [

	^ apiKey isNotNil and: [ apiKey isNotEmpty ]
]

{ #category : 'validation' }
SmallCodeConfiguration >> validateConfiguration [

	self isConfigured ifFalse: [
		Error signal: 'SmallCode API key not configured. Use: SmallCodeConfiguration current apiKey: ''your-key''' ]
]
