"
Validation result for code checked before sandbox execution.
Converted from ChatPharoSandboxValidation (MIT License, pharo-llm/chatpharo).
"
Class {
	#name : 'SmallCodeSandboxValidation',
	#superclass : 'Object',
	#instVars : [
		'isValid',
		'errorMessage',
		'violations'
	],
	#category : 'SmallCode-Sandbox',
	#package : 'SmallCode-Sandbox'
}

{ #category : 'instance creation' }
SmallCodeSandboxValidation class >> invalid: anErrorMessage violations: aViolationsArray [

	^ self basicNew
		  initializeInvalid: anErrorMessage violations: aViolationsArray;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeSandboxValidation class >> valid [

	^ self basicNew
		  initializeValid;
		  yourself
]

{ #category : 'accessing' }
SmallCodeSandboxValidation >> errorMessage [

	^ errorMessage
]

{ #category : 'initialization' }
SmallCodeSandboxValidation >> initializeInvalid: anErrorMessage violations: aViolationsArray [

	super initialize.
	isValid := false.
	errorMessage := anErrorMessage.
	violations := aViolationsArray
]

{ #category : 'initialization' }
SmallCodeSandboxValidation >> initializeValid [

	super initialize.
	isValid := true.
	errorMessage := nil.
	violations := #()
]

{ #category : 'testing' }
SmallCodeSandboxValidation >> isInvalid [

	^ isValid not
]

{ #category : 'testing' }
SmallCodeSandboxValidation >> isValid [

	^ isValid
]

{ #category : 'printing' }
SmallCodeSandboxValidation >> printOn: aStream [

	aStream nextPutAll: 'Validation('.
	isValid
		ifTrue: [ aStream nextPutAll: 'valid' ]
		ifFalse: [ aStream nextPutAll: 'invalid: '; nextPutAll: errorMessage ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
SmallCodeSandboxValidation >> violations [

	^ violations
]
