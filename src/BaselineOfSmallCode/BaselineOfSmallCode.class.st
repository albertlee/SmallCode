Class {
	#name : 'BaselineOfSmallCode',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfSmallCode',
	#package : 'BaselineOfSmallCode'
}

{ #category : 'baselines' }
BaselineOfSmallCode >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			package: 'SmallCode';
			package: 'SmallCode-DSL' with: [ spec requires: #( 'SmallCode' ) ];
			package: 'SmallCode-Sandbox' with: [ spec requires: #( 'SmallCode' ) ];
			package: 'SmallCode-Tools' with: [ spec requires: #( 'SmallCode' 'SmallCode-DSL' 'SmallCode-Sandbox' ) ];
			package: 'SmallCode-LiveObject' with: [ spec requires: #( 'SmallCode' 'SmallCode-DSL' ) ];
			package: 'SmallCode-UI' with: [ spec requires: #( 'SmallCode' 'SmallCode-Tools' 'SmallCode-DSL' ) ];
			package: 'SmallCode-Tests' with: [ spec requires: #( 'SmallCode' 'SmallCode-Tools' 'SmallCode-DSL' 'SmallCode-Sandbox' 'SmallCode-LiveObject' 'SmallCode-UI' ) ].
		spec
			group: 'Core' with: #( 'SmallCode' 'SmallCode-DSL' 'SmallCode-Sandbox' 'SmallCode-Tools' 'SmallCode-LiveObject' 'SmallCode-UI' );
			group: 'Headless' with: #( 'SmallCode' 'SmallCode-DSL' 'SmallCode-Sandbox' 'SmallCode-Tools' 'SmallCode-LiveObject' );
			group: 'Tests' with: #( 'SmallCode-Tests' );
			group: 'default' with: #( 'Core' 'Tests' ) ]
]
