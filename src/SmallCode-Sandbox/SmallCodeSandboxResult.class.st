"
Sandbox result for code evaluation.
Converted from ChatPharoSandboxResult (MIT License, pharo-llm/chatpharo).
"
Class {
	#name : 'SmallCodeSandboxResult',
	#superclass : 'Object',
	#instVars : [
		'success',
		'value',
		'errorMessage',
		'violations'
	],
	#category : 'SmallCode-Sandbox',
	#package : 'SmallCode-Sandbox'
}

{ #category : 'instance creation' }
SmallCodeSandboxResult class >> failure: anErrorMessage violations: aViolationsArray [

	^ self basicNew
		  initializeFailure: anErrorMessage violations: aViolationsArray;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeSandboxResult class >> success: aValue [

	^ self basicNew
		  initializeSuccess: aValue;
		  yourself
]

{ #category : 'converting' }
SmallCodeSandboxResult >> asDictionary [

	success ifTrue: [
		^ Dictionary
			  with: 'success' -> true
			  with: 'value' -> value asString ].
	^ Dictionary
		  with: 'success' -> false
		  with: 'error' -> errorMessage
		  with: 'violations' -> violations
]

{ #category : 'accessing' }
SmallCodeSandboxResult >> errorMessage [

	^ errorMessage
]

{ #category : 'testing' }
SmallCodeSandboxResult >> hasViolations [

	^ violations isNotNil and: [ violations isNotEmpty ]
]

{ #category : 'initialization' }
SmallCodeSandboxResult >> initializeFailure: anErrorMessage violations: aViolationsArray [

	super initialize.
	success := false.
	errorMessage := anErrorMessage.
	violations := aViolationsArray
]

{ #category : 'initialization' }
SmallCodeSandboxResult >> initializeSuccess: aValue [

	super initialize.
	success := true.
	value := aValue.
	violations := #()
]

{ #category : 'testing' }
SmallCodeSandboxResult >> isFailure [

	^ success not
]

{ #category : 'testing' }
SmallCodeSandboxResult >> isSuccess [

	^ success
]

{ #category : 'printing' }
SmallCodeSandboxResult >> printOn: aStream [

	aStream nextPutAll: 'SandboxResult('.
	success
		ifTrue: [ aStream nextPutAll: 'success: '; print: value ]
		ifFalse: [ aStream nextPutAll: 'failure: '; nextPutAll: errorMessage ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
SmallCodeSandboxResult >> value [

	^ value
]

{ #category : 'accessing' }
SmallCodeSandboxResult >> violations [

	^ violations
]
