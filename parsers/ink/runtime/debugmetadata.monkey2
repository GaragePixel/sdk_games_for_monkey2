Namespace sdk_games.parsers.ink

'===============================================================================
' DebugMetadata Class - Represents Debug Information for Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
'
' This class encapsulates debug metadata for the Ink runtime, providing
' line and character range information, file names, and source names.
' It is primarily used for debugging and merging debug metadata from
' multiple sources.
'
' Functionality:
'
' - Fields:
'   - `_startLineNumber`: The starting line number of the debug range.
'   - `_endLineNumber`: The ending line number of the debug range.
'   - `_startCharacterNumber`: The starting character number of the debug range.
'   - `_endCharacterNumber`: The ending character number of the debug range.
'   - `_fileName`: The name of the file associated with the debug metadata.
'   - `_sourceName`: The name of the source associated with the debug metadata.
'
' - Methods:
'   - `Merge`: Combines two `DebugMetadata` instances into a single range.
'   - `ToString`: Returns a string representation of the debug metadata.
'
' Notes:
'
' - The `Merge` method is used to combine debug ranges, ensuring that the
'   resulting metadata covers the entire range of both inputs.
' - The `ToString` method provides a human-readable representation of the
'   debug metadata.
'
' Technical advantages:
'
' - Flexibility:
'   - Supports merging of debug metadata from multiple sources.
' - Clarity:
'   - Provides detailed debug information, including file and line numbers.
' - Robustness:
'   - Ensures consistency when merging debug ranges.
'
'===============================================================================

Class DebugMetadata

	Private
	
	Field _startLineNumber:Int = 0
	Field _endLineNumber:Int = 0
	Field _startCharacterNumber:Int = 0
	Field _endCharacterNumber:Int = 0
	Field _fileName:String = Null
	Field _sourceName:String = Null

	Public

	Method New()
	End

	Method Merge:DebugMetadata(dm:DebugMetadata)
		Local newDebugMetadata := New DebugMetadata()

		' These fields are expected to be identical.
		newDebugMetadata._fileName = _fileName
		newDebugMetadata._sourceName = _sourceName

		' Merge start line and character numbers
		If _startLineNumber < dm._startLineNumber
			newDebugMetadata._startLineNumber = _startLineNumber
			newDebugMetadata._startCharacterNumber = _startCharacterNumber
		ElseIf _startLineNumber > dm._startLineNumber
			newDebugMetadata._startLineNumber = dm._startLineNumber
			newDebugMetadata._startCharacterNumber = dm._startCharacterNumber
		Else
			newDebugMetadata._startLineNumber = _startLineNumber
			newDebugMetadata._startCharacterNumber = Min(_startCharacterNumber, dm._startCharacterNumber)
		End

		' Merge end line and character numbers
		If _endLineNumber > dm._endLineNumber
			newDebugMetadata._endLineNumber = _endLineNumber
			newDebugMetadata._endCharacterNumber = _endCharacterNumber
		ElseIf _endLineNumber < dm._endLineNumber
			newDebugMetadata._endLineNumber = dm._endLineNumber
			newDebugMetadata._endCharacterNumber = dm._endCharacterNumber
		Else
			newDebugMetadata._endLineNumber = _endLineNumber
			newDebugMetadata._endCharacterNumber = Max(_endCharacterNumber, dm._endCharacterNumber)
		End

		Return newDebugMetadata
	End

	Method ToString:String()
		If _fileName <> Null
			Return "line " + _startLineNumber + " of " + _fileName
		Else
			Return "line " + _startLineNumber
		End
	End
	
	Property startLineNumber:Int()
		Return _startLineNumber
	Setter(value:Int)
		_startLineNumber = value
	End

	Property endLineNumber:Int()
		Return _endLineNumber
	Setter(value:Int)
		_endLineNumber = value
	End

	Property startCharacterNumber:Int()
		Return _startCharacterNumber
	Setter(value:Int)
		_startCharacterNumber = value
	End

	Property endCharacterNumber:Int()
		Return _endCharacterNumber
	Setter(value:Int)
		_endCharacterNumber = value
	End

	Property fileName:String()
		Return _fileName
	Setter(value:String)
		_fileName = value
	End

	Property sourceName:String()
		Return _sourceName
	Setter(value:String)
		_sourceName = value
	End
End
