"
Tests for SmallCodeAgent mode handling (build vs plan), including mode validation,
plan/run entry points wiring the tool factory, and mode-specific system prompts.
These tests do not call the LLM.
"
Class {
	#name : 'SmallCodeAgentTest',
	#superclass : 'TestCase',
	#instVars : [
		'agent'
	],
	#category : 'SmallCode-Tests',
	#package : 'SmallCode-Tests'
}

{ #category : 'running' }
SmallCodeAgentTest >> setUp [

	super setUp.
	agent := SmallCodeAgent new
]

{ #category : 'tests' }
SmallCodeAgentTest >> testBuildSystemPromptDiffersByMode [

	| buildPrompt planPrompt |
	agent mode: #build.
	buildPrompt := agent buildSystemPrompt.
	agent mode: #plan.
	planPrompt := agent buildSystemPrompt.
	self deny: buildPrompt equals: planPrompt.
	self assert: (planPrompt includesSubstring: 'PLAN MODE')
]

{ #category : 'tests' }
SmallCodeAgentTest >> testDefaultModeIsBuild [

	self assert: agent mode equals: #build
]

{ #category : 'tests' }
SmallCodeAgentTest >> testInvalidModeRejected [

	self should: [ agent mode: #destroy ] raise: Error.
	self assert: agent mode equals: #build
]

{ #category : 'tests' }
SmallCodeAgentTest >> testModeSetterPropagatesToToolFactory [

	agent mode: #plan.
	self assert: agent toolFactory mode equals: #plan
]

{ #category : 'tests' }
SmallCodeAgentTest >> testPlanModeSchemasAreReadOnly [

	| schemas names |
	agent mode: #plan.
	schemas := agent toolFactory toolSchemasForMode: agent mode.
	names := schemas collect: [ :s | (s at: 'function') at: 'name' ].
	agent toolFactory mutatingToolNames do: [ :each |
		self deny: (names includes: each) ]
]
