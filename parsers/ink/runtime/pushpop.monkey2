Namespace sdk_games.parsers.ink

'===============================================================================
' PushPopType Enum - Represents Types of Stack Operations in Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This enumeration defines the types of stack operations used in the Ink runtime.
' 	These operations dictate how control flows are managed within the narrative,
' 	such as entering/exiting tunnels or invoking functions.
'
' Functionality:
'
' 	- Enumerates the following stack operation types:
' 		- Tunnel: Represents a stack push/pop for narrative tunnels.
' 		- Function: Represents a stack push/pop for function calls.
' 		- FunctionEvaluationFromGame: Represents function evaluations initiated by the game.
'
' Notes:
'
' 	- This enumeration is used throughout the Ink runtime to manage control flow.
' 	- Enum values are explicitly ordered to ensure compatibility with serialized data
' 	  and runtime logic.
'
' Technical advantages:
'
' 	- Provides a clear and standardized way to represent stack operation types.
' 	- Simplifies control flow logic by categorizing operations into distinct types.
'===============================================================================

Enum PushPopType
	Tunnel
	Func
	FuncEvaluationFromGame
End
