"
!! Purpose
I am a class that can convert PlantUML syntax to the url of a diagram which can be loaded of the plantuml site (https://www.plantuml.com)


I have two service methods on the class side of me.
- ==urlFromSource:== which returns a url to a diagram corresponding to the source.
- ==loadUML:== which returns the image of the diagram.


I use a re-factoring of the plantuml encoding scheme developed as part of: https://github.com/fuhrmanator/PlantUMLPharoGizmo.

"
Class {
	#name : #PlantUMLBridge,
	#superclass : #Object,
	#category : #'PlantUML Bridge'
}

{ #category : #examples }
PlantUMLBridge class >> example [
	<example>
	(self imageFromUML:
'@startuml
title Thursday night
start
:Eat Hot Wings;
:Drink Homebrew;
stop
@enduml') inspect
]

{ #category : #examples }
PlantUMLBridge class >> exampleOpenInBrowser [
	<example>
	(self webbrowseUML:
'@startuml
title Thursday night
start
:Eat Hot Wings;
:Drink Homebrew;
stop
@enduml')
]

{ #category : #public }
PlantUMLBridge class >> imageFromUML: source [
	| url |
	url := self pngFromSource: source.
	^ZnEasy getPng: url
]

{ #category : #public }
PlantUMLBridge class >> pngFromSource: source [
	^'https://www.plantuml.com/plantuml/img/' , (self new urlFromSource: source) 
]

{ #category : #public }
PlantUMLBridge class >> svgFromSource: source [
	^'https://www.plantuml.com/plantuml/svg/' , (self new urlFromSource: source) 
]

{ #category : #public }
PlantUMLBridge class >> webbrowseUML: source [
	| url |
	url := self svgFromSource: source.
	^WebBrowser openOn: url.
]

{ #category : #plantUMLencoding }
PlantUMLBridge >> encode6bit: bCopy [
	"Ported from https://github.com/dougn/python-plantuml/blob/master/plantuml.py"
	| b |
	b := bCopy.
	b < 10
		ifTrue: [ ^ (Character value: (48 + b)) asString ].
	b := b - 10.
	b < 26
		ifTrue: [ ^ (Character value: (65 + b)) asString ].
	b := b - 26.
	b < 26
		ifTrue: [ ^ (Character value: (97 + b)) asString ].
	b := b - 26.
	b = 0
		ifTrue: [ ^ '-' ].
	b = 1
		ifTrue: [ ^ '_' ].
	^ $? asString
]

{ #category : #plantUMLencoding }
PlantUMLBridge >> encode: aString [
	"Ported from https://github.com/dougn/python-plantuml/blob/master/plantuml.py"

	| res i |
	res := WriteStream on: (String new).
	i := 0.
	[ i < aString size ]
		whileTrue: [ i + 2 = aString size
				ifTrue: [ res nextPutAll:
							(self on: aString
								encode3bytes: (aString at: i + 1) asInteger
								arg2: (aString at: i + 2) asInteger
								arg3: 0) ]
				ifFalse: [ i + 1 = aString size
						ifTrue: [ res nextPutAll:
									(self on: aString encode3bytes: (aString at: i + 1) asInteger arg2: 0 arg3: 0) ]
						ifFalse: [ res nextPutAll:
									(self on: aString
										encode3bytes: (aString at: i + 1) asInteger
										arg2: (aString at: i + 2) asInteger
										arg3: (aString at: i + 3) asInteger) ] ].
			i := i + 3 ].
		res close.
	^ res contents
]

{ #category : #plantUMLencoding }
PlantUMLBridge >> on: aString encode3bytes: b1 arg2: b2 arg3: b3 [
	"Ported from https://github.com/dougn/python-plantuml/blob/master/plantuml.py"

	| res c1 c2 c3 c4 |
	c1 := b1 >> 2.	"c1 = b1 >> 2;"
	c2 := (b1 bitAnd: 16r3) << 4 bitOr: b2 >> 4.	"c2 = ((b1 & 0x3) << 4) | (b2 >> 4);"
	c3 := (b2 bitAnd: 16rF) << 2 bitOr: b3 >> 6.	"c3 = ((b2 & 0xF) << 2) | (b3 >> 6);"
	c4 := b3 bitAnd: 16r3F.	"c4 = b3 & 0x3F;"
	res := WriteStream on: (String new).	"res = '';"
	res nextPutAll: (self encode6bit: (c1 bitAnd: 16r3F)).	"res += _encode6bit(c1 & 0x3F);"
	res nextPutAll: (self encode6bit: (c2 bitAnd: 16r3F)).	"res += _encode6bit(c2 & 0x3F);"
	res nextPutAll: (self encode6bit: (c3 bitAnd: 16r3F)).	"res += _encode6bit(c3 & 0x3F);"
	res nextPutAll: (self encode6bit: (c4 bitAnd: 16r3F)).	"res += _encode6bit(c4 & 0x3F);"
	^ res contents	"return res;"
]

{ #category : #plantUMLencoding }
PlantUMLBridge >> pkzipped: aString [
	"Use the ZLibWriteStream to get a DEFLATE function from PKTools"

	| zstream |
	^ String
		streamContents: [ :stream | 
			zstream := ZLibWriteStream on: stream.
			"zstream := GZipWriteStream on: stream."
			zstream nextPutAll: aString.
			zstream close.
			zstream encodedStream contents ]
]

{ #category : #plantUMLencoding }
PlantUMLBridge >> urlFromSource: aSource [
	"Ported from https://github.com/dougn/python-plantuml/blob/master/plantuml.py"

	| zlibbedStr compressedString |
	zlibbedStr := self pkzipped: aSource.
	compressedString := zlibbedStr copyFrom: 3 to: zlibbedStr size - 4.
	^ self encode: compressedString
]
