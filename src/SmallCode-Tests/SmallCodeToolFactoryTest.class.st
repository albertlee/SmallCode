"
Tests for SmallCodeToolFactory, focused on mode-aware tool selection
(plan mode = read-only) and the executeTool: guard.
"
Class {
	#name : 'SmallCodeToolFactoryTest',
	#superclass : 'TestCase',
	#instVars : [
		'factory'
	],
	#category : 'SmallCode-Tests',
	#package : 'SmallCode-Tests'
}

{ #category : 'running' }
SmallCodeToolFactoryTest >> setUp [

	super setUp.
	factory := SmallCodeToolFactory
		           projector: SmallCodeProjector new
		           vocabulary: SmallCodeVocabulary new
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testDefaultModeIsBuild [

	self assert: factory mode equals: #build
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testExecuteMutatingToolBlockedInPlanMode [

	| result |
	factory mode: #plan.
	result := factory executeTool: 'create_class' arguments: Dictionary new.
	self assert: (result includesKey: 'error').
	self assert: ((result at: 'error') includesSubstring: 'plan mode')
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testExecuteUnknownToolStillErrors [

	| result |
	factory mode: #plan.
	result := factory executeTool: 'no_such_tool' arguments: Dictionary new.
	self assert: (result includesKey: 'error').
	self assert: ((result at: 'error') includesSubstring: 'Unknown tool')
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testFinishAvailableInPlanMode [

	| names |
	names := (factory toolsForMode: #plan) collect: [ :t | t name ].
	self assert: (names includes: 'finish')
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testReadOnlyToolsExcludeAllMutatingTools [

	| names |
	names := factory readOnlyTools collect: [ :t | t name ].
	factory mutatingToolNames do: [ :each |
		self deny: (names includes: each) ]
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testToolsForBuildModeAreAllTools [

	self
		assert: (factory toolsForMode: #build) size
		equals: factory allTools size
]

{ #category : 'tests' }
SmallCodeToolFactoryTest >> testToolsForPlanModeAreReadOnly [

	| names mutating |
	names := (factory toolsForMode: #plan) collect: [ :t | t name ].
	mutating := factory mutatingToolNames.
	self assert: (names noneSatisfy: [ :n | mutating includes: n ]).
	self
		assert: (factory toolsForMode: #plan) size
		equals: factory allTools size - factory mutatingToolNames size
]
