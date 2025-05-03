Namespace sdk_games.parsers.ink

'===============================================================================
' ChoicePoint Class - Represents a Decision Point in the Story
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
'
' The `ChoicePoint` class encapsulates the logic and metadata associated with
' decision points within the Ink story. It provides mechanisms for resolving
' paths, storing conditions, and managing flags that define the behavior of
' choices.
'
' Functionality:
'
' - Properties:
'   - `pathOnChoice`: Retrieves or sets the path associated with the choice.
'   - `choiceTarget`: Resolves and retrieves the container for the choice path.
'   - `pathStringOnChoice`: Gets or sets the compact string representation of
'     the choice path.
'   - `flags`: Encodes or decodes choice metadata as an integer.
'
' - Methods:
'   - `ToString`: Returns a string representation of the choice point.
'
' - Constructor:
'   - Initializes a `ChoicePoint` instance with default or custom settings for
'     the `onceOnly` property.
'
' Notes:
'
' - The `ChoicePoint` class is designed to work seamlessly with the Ink runtime,
'   enabling dynamic generation and resolution of choices.
' - Flags are used for efficient storage and retrieval of choice metadata.
'
' Technical advantages:
'
' - Efficiency:
'   - Uses flags to store multiple choice properties compactly.
' - Flexibility:
'   - Supports relative and absolute paths for choice resolution.
' - Robustness:
'   - Ensures consistency by resolving relative paths to global ones.
'
'===============================================================================

Class ChoicePoint Extends RuntimeObject

Private

	Field _pathOnChoice:Path

Public

	' Constructor
	Method New(onceOnly:Bool = True)
		Self.onceOnly = onceOnly
	End

	' Properties
	Property pathOnChoice:Path()
		If _pathOnChoice <> Null And _pathOnChoice.isRelative
			Local choiceTargetObj := choiceTarget
			If choiceTargetObj <> Null
				_pathOnChoice = choiceTargetObj.path
			End
		End
		Return _pathOnChoice
	Setter(value:Path)
		_pathOnChoice = value
	End

	Property choiceTarget:Container()
		Return Self.ResolvePath(_pathOnChoice).container
	End

	Property pathStringOnChoice:String()
		Return CompactPathString(pathOnChoice)
	Setter(value:String)
		pathOnChoice = New Path(value)
	End

	Field hasCondition:Bool
	Field hasStartContent:Bool
	Field hasChoiceOnlyContent:Bool
	Field onceOnly:Bool
	Field isInvisibleDefault:Bool

	Property flags:Int()
		Local flags := 0
		If hasCondition flags = flags | 1
		If hasStartContent flags = flags | 2
		If hasChoiceOnlyContent flags = flags | 4
		If isInvisibleDefault flags = flags | 8
		If onceOnly flags = flags | 16
		Return flags
	Setter(value:Int)
		hasCondition = (value & 1) > 0
		hasStartContent = (value & 2) > 0
		hasChoiceOnlyContent = (value & 4) > 0
		isInvisibleDefault = (value & 8) > 0
		onceOnly = (value & 16) > 0
	End

	Method ToString:String()
		Local targetLineNum := DebugLineNumberOfPath(pathOnChoice)
		Local targetString := pathOnChoice.ToString()

		If targetLineNum <> Null
			targetString = " line " + targetLineNum + "("+targetString+")"
		End

		Return "Choice: -> " + targetString
	End
End
