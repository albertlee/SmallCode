"
SmallCodeAgent is the core agent loop. It drives the coding-eval-inspect-debug cycle
inside a live Pharo image, using LLM-powered decision making with structured tool calls.

The agent operates through a domain vocabulary (DSL) that constrains and guides
the LLM's code generation. The system prompt has four sections:
  [IDENTITY]           - who the agent is and where it lives
  [DOMAIN VOCABULARY]  - current domain words (selectors + descriptions)
  [TOOLS]              - auto-generated from tool registry
  [PRINCIPLES]         - DSL-first coding discipline, naming rules, dual output

Usage:
  agent := SmallCodeAgent new.
  agent provider: (SmallCodeOpenRouterProvider withApiKey: 'sk-or-...').
  result := agent run: 'Create a Stack class with push/pop/top and tests'.

  With focus object:
  result := agent run: 'Explain this object' on: someObject.
"
Class {
	#name : 'SmallCodeAgent',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'projector',
		'vocabulary',
		'toolFactory',
		'messages',
		'maxSteps',
		'domainPackages',
		'stepLog'
	],
	#category : 'SmallCode',
	#package : 'SmallCode'
}

{ #category : 'instance creation' }
SmallCodeAgent class >> withProvider: aProvider [

	^ self new
		  provider: aProvider;
		  yourself
]

{ #category : 'instance creation' }
SmallCodeAgent class >> fromConfiguration [
	"Create from global SmallCodeConfiguration."

	| config agent |
	config := SmallCodeConfiguration current.
	agent := self withProvider: SmallCodeOpenRouterProvider fromConfiguration.
	agent maxSteps: config maxAgentSteps.
	agent domainPackages: config domainPackages.
	^ agent
]

{ #category : 'initialization' }
SmallCodeAgent >> initialize [

	super initialize.
	projector := SmallCodeProjector new.
	vocabulary := SmallCodeVocabulary new.
	toolFactory := SmallCodeToolFactory projector: projector vocabulary: vocabulary.
	projector vocabulary: vocabulary.
	messages := OrderedCollection new.
	maxSteps := 20.
	domainPackages := OrderedCollection new.
	stepLog := OrderedCollection new
]

{ #category : 'running' }
SmallCodeAgent >> run: goal [
	"Run the agent on a goal with no initial focus object."

	^ self run: goal on: nil
]

{ #category : 'running' }
SmallCodeAgent >> run: goal on: focusObject [
	"Main entry point. Run the agent loop until finish or maxSteps.
	 goal: a natural language task description.
	 focusObject: optional object to inspect initially."

	self prepareSession: goal focus: focusObject.
	^ self runLoop
]

{ #category : 'running' }
SmallCodeAgent >> prepareSession: goal focus: focusObject [
	"Set up messages for a new agent session."

	messages := OrderedCollection new.
	stepLog := OrderedCollection new.
	vocabulary resetSession.

	"Extract vocabulary from domain packages"
	domainPackages do: [ :pkg | vocabulary extractFromPackageNamed: pkg ].

	"System prompt with 4 sections"
	messages add: (SmallCodeMessage system: self buildSystemPrompt).

	"Focus object observation"
	focusObject ifNotNil: [
		| observation |
		observation := projector projectWithDomain: focusObject.
		messages add: (SmallCodeMessage user:
				 'Initial focus object:' , String cr , observation) ].

	"Goal"
	messages add: (SmallCodeMessage user: 'GOAL: ' , goal)
]

{ #category : 'running' }
SmallCodeAgent >> runLoop [
	"Execute the perceive-decide-execute loop."

	1 to: maxSteps do: [ :stepNum |
		| response |
		self logStep: stepNum event: 'Calling LLM...'.
		response := self callLLM.
		messages add: response.

		response hasToolCalls
			ifTrue: [
				| results finished |
				results := self executeToolCalls: response toolCalls.
				finished := results anySatisfy: [ :r |
					            (r at: 'finished' ifAbsent: [ false ]) = true ].
				finished ifTrue: [
					| finishResult |
					finishResult := results detect: [ :r |
						                (r at: 'finished' ifAbsent: [ false ]) = true ].
					self logStep: stepNum event: 'FINISHED: ' , (finishResult at: 'answer').
					^ finishResult ] ]
			ifFalse: [
				"Text-only response with no tool calls — treat as thinking, continue"
				self logStep: stepNum event: 'Assistant text: ' , (response content copyFrom: 1 to: (response content size min: 100)).
				"If the response seems like a final answer (no tool calls, conversation done), finish"
				stepNum > 1 ifTrue: [
					"Give it one more turn to use finish tool, but don't infinite loop on text-only responses"
					messages add: (SmallCodeMessage user:
						'Please use the finish tool to report your final answer, or continue using tools to complete the task.') ] ] ].

	self logStep: maxSteps event: 'Max steps reached'.
	^ Dictionary
		  with: 'finished' -> true
		  with: 'answer' -> 'Max steps reached without explicit finish.'
		  with: 'steps' -> maxSteps
]

{ #category : 'private' }
SmallCodeAgent >> callLLM [
	"Send current messages to LLM with tool schemas."

	| toolSchemas |
	toolSchemas := toolFactory allToolSchemas.
	^ provider complete: messages tools: toolSchemas
]

{ #category : 'private' }
SmallCodeAgent >> executeToolCalls: toolCalls [
	"Execute all tool calls and add results as tool messages."

	^ toolCalls collect: [ :tc |
		  | result resultJson |
		  self logStep: 0 event: 'Executing tool: ' , tc functionName , ' args: ' , tc arguments printString.
		  result := toolFactory executeTool: tc functionName arguments: tc arguments.
		  resultJson := STONJSON toString: result.
		  messages add: (SmallCodeMessage toolResult: resultJson callId: tc id).
		  self logStep: 0 event: 'Tool result: ' , (resultJson copyFrom: 1 to: (resultJson size min: 200)).
		  result ]
]

{ #category : 'system prompt' }
SmallCodeAgent >> buildSystemPrompt [
	"Build the 4-section system prompt."

	^ String streamContents: [ :s |
		  s nextPutAll: self identitySection; cr; cr.
		  s nextPutAll: self vocabularySection; cr; cr.
		  s nextPutAll: self principlesSection ]
]

{ #category : 'system prompt' }
SmallCodeAgent >> identitySection [

	^ '# Identity
You are SmallCode, a coding agent living inside a Pharo Smalltalk image.
You observe live objects via handles (@obj_N), evaluate code, compile methods,
and run tests. All objects in the image are live — you can inspect, modify,
and extend them through tools.

You operate through a coding-eval-inspect-debug cycle:
1. Understand the goal
2. Browse/inspect existing code and objects
3. Write and compile new code (classes, methods)
4. Evaluate expressions to test behavior
5. Inspect results, debug if needed
6. Run tests to verify correctness
7. Call finish with the result and any new vocabulary created'
]

{ #category : 'system prompt' }
SmallCodeAgent >> vocabularySection [

	| vocabText |
	vocabText := vocabulary formatForPrompt.
	vocabText ifEmpty: [ vocabText := '(no domain vocabulary extracted yet — use the vocabulary tool to discover existing words)' ].
	^ '# Domain Vocabulary

The following selectors are the current domain language.
PREFER using these existing words over inventing new ones.
When you need to express an action or query, FIRST check if a vocabulary word already covers it.

' , vocabText , '
## Session-Created Vocabulary
' , vocabulary formatSessionCreatedForPrompt
]

{ #category : 'system prompt' }
SmallCodeAgent >> principlesSection [

	^ '# Operating Principles

## DSL-First Coding
- ALWAYS check vocabulary (use the vocabulary tool) before creating new methods
- Use Smalltalk keyword message style that reads as near-English domain sentences
  Good: `account transfer: amount from: source to: destination`
  Bad:  `account doTransfer_3args: arr`
- Every new selector is a new word in the domain language — treat naming seriously
- After compiling a new domain method, call register_word to add it to the vocabulary

## Naming Discipline
Before creating any new selector, answer:
1. Does an existing vocabulary word cover this? (call vocabulary tool to check)
2. Is this a stable domain concept or a one-time implementation detail?
3. Is the name specific, descriptive, and free of value judgment?
4. Does it follow keyword message style for multi-argument methods?

## Method Comments
Always include a method comment (first string literal in method body) explaining
what the domain concept means. This comment becomes the vocabulary description.

## Observation Protocol
- After eval/compile, inspect results and report in domain terms
- Use narrate_method to understand existing code in domain language
- Reference objects by their handles (@obj_N) from previous observations

## Eval with Handles
When you use eval_code, all object handles from previous observations (obj_1, obj_2, etc.)
are available as variables. You can write: `obj_1 size` or `obj_1 inject: 0 into: [:a :b | a + b]`.

## Dual Output
Every task produces two things:
1. The requested functionality (code, tests, results)
2. A vocabulary changelog: what new domain words were created and why
Report both when calling finish.'
]

{ #category : 'private' }
SmallCodeAgent >> logStep: stepNum event: aString [

	| entry |
	entry := 'Step ' , stepNum printString , ': ' , aString.
	stepLog add: entry.
	Transcript showln: '[SmallCode] ' , entry
]

{ #category : 'accessing' }
SmallCodeAgent >> provider [

	^ provider
]

{ #category : 'accessing' }
SmallCodeAgent >> provider: aProvider [

	provider := aProvider
]

{ #category : 'accessing' }
SmallCodeAgent >> projector [

	^ projector
]

{ #category : 'accessing' }
SmallCodeAgent >> vocabulary [

	^ vocabulary
]

{ #category : 'accessing' }
SmallCodeAgent >> toolFactory [

	^ toolFactory
]

{ #category : 'accessing' }
SmallCodeAgent >> messages [

	^ messages
]

{ #category : 'accessing' }
SmallCodeAgent >> maxSteps [

	^ maxSteps
]

{ #category : 'accessing' }
SmallCodeAgent >> maxSteps: anInteger [

	maxSteps := anInteger
]

{ #category : 'accessing' }
SmallCodeAgent >> domainPackages [

	^ domainPackages
]

{ #category : 'accessing' }
SmallCodeAgent >> domainPackages: aCollection [

	domainPackages := aCollection asOrderedCollection
]

{ #category : 'accessing' }
SmallCodeAgent >> stepLog [

	^ stepLog
]
