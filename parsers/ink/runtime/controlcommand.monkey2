Namespace sdk_games.parsers.ink

'===============================================================================
' ControlCommand Class - Represents a Command in the Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
'
' The `ControlCommand` class encapsulates commands used within the Ink runtime.
' It provides a mechanism to represent and manage various types of runtime
' operations, such as evaluating expressions, managing tunnels, and controlling
' threads.
'
' Functionality:
'
' - Properties:
'   - `cmdType`: Retrieves the type of the control command.
'
' - Methods:
'   - `Copy`: Creates a copy of the control command.
'   - `ToString`: Returns a string representation of the command type.
'   - Factory Methods: Static methods for creating instances of specific commands.
'
' Notes:
'
' - The `ControlCommandType` enum provides a comprehensive list of supported commands.
' - Factory methods simplify the creation of frequently used command instances.
'
' Technical advantages:
'
' - Efficiency:
'   - Centralized representation of control commands minimizes boilerplate code.
' - Flexibility:
'   - Supports a wide range of runtime operations via the `ControlCommandType` enum.
' - Robustness:
'   - Ensures consistent handling of commands across the runtime.
'
'===============================================================================

Enum ControlCommandType
	NotSet = -1
	EvalStart
	EvalOutput
	EvalEnd
	Duplicate
	PopEvaluatedValue
	PopFunction
	PopTunnel
	BeginString
	EndString
	NoOp
	ChoiceCount
	Turns
	TurnsSince
	ReadCount
	Random
	SeedRandom
	VisitIndex
	SequenceShuffleIndex
	StartThread
	DoneCommand ' Renamed from "End" to "DoneCommand" to comply with the reserved keyword rule
	ListFromInt
	ListRange
	ListRandom
	BeginTag
	EndTag
End

Class ControlCommand Extends RuntimeObject

Public

	' Properties
	Property cmdType:ControlCommandType() 'Changed from CommandType in order to not conflicts with the type enumerator
		Return _cmdType
	End

	' Constructor
	Method New(cmdType:ControlCommandType = ControlCommandType.NotSet)
		_cmdType = cmdType
	End

	' Methods
	Method Copy:ControlCommand()
		Return New ControlCommand(_cmdType)
	End

	Method ToString:String()
		Return _cmdType.ToString()
	End

	' Factory Methods
	Function EvalStart:ControlCommand()
		Return New ControlCommand(ControlCommandType.EvalStart)
	End

	Function EvalOutput:ControlCommand()
		Return New ControlCommand(ControlCommandType.EvalOutput)
	End

	Function EvalEnd:ControlCommand()
		Return New ControlCommand(ControlCommandType.EvalEnd)
	End

	Function Duplicate:ControlCommand()
		Return New ControlCommand(ControlCommandType.Duplicate)
	End

	Function PopEvaluatedValue:ControlCommand()
		Return New ControlCommand(ControlCommandType.PopEvaluatedValue)
	End

	Function PopFunction:ControlCommand()
		Return New ControlCommand(ControlCommandType.PopFunction)
	End

	Function PopTunnel:ControlCommand()
		Return New ControlCommand(ControlCommandType.PopTunnel)
	End

	Function BeginString:ControlCommand()
		Return New ControlCommand(ControlCommandType.BeginString)
	End

	Function EndString:ControlCommand()
		Return New ControlCommand(ControlCommandType.EndString)
	End

	Function NoOp:ControlCommand()
		Return New ControlCommand(ControlCommandType.NoOp)
	End

	Function ChoiceCount:ControlCommand()
		Return New ControlCommand(ControlCommandType.ChoiceCount)
	End

	Function Turns:ControlCommand()
		Return New ControlCommand(ControlCommandType.Turns)
	End

	Function TurnsSince:ControlCommand()
		Return New ControlCommand(ControlCommandType.TurnsSince)
	End

	Function ReadCount:ControlCommand()
		Return New ControlCommand(ControlCommandType.ReadCount)
	End

	Function Random:ControlCommand()
		Return New ControlCommand(ControlCommandType.Random)
	End

	Function SeedRandom:ControlCommand()
		Return New ControlCommand(ControlCommandType.SeedRandom)
	End

	Function VisitIndex:ControlCommand()
		Return New ControlCommand(ControlCommandType.VisitIndex)
	End

	Function SequenceShuffleIndex:ControlCommand()
		Return New ControlCommand(ControlCommandType.SequenceShuffleIndex)
	End

	Function StartThread:ControlCommand()
		Return New ControlCommand(ControlCommandType.StartThread)
	End

	Function Done:ControlCommand()
		Return New ControlCommand(ControlCommandType.DoneCommand) ' Updated reference to renamed enum value
	End

	Function ListFromInt:ControlCommand()
		Return New ControlCommand(ControlCommandType.ListFromInt)
	End

	Function ListRange:ControlCommand()
		Return New ControlCommand(ControlCommandType.ListRange)
	End

	Function ListRandom:ControlCommand()
		Return New ControlCommand(ControlCommandType.ListRandom)
	End

	Function BeginTag:ControlCommand()
		Return New ControlCommand(ControlCommandType.BeginTag)
	End

	Function EndTag:ControlCommand()
		Return New ControlCommand(ControlCommandType.EndTag)
	End

Private

	Field _cmdType:ControlCommandType

End
