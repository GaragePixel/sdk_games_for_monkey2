Namespace sdk_games.parsers.ink

'===============================================================================
' INamedContent Interface - Represents Named Content in Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This interface defines the structure for named content in the Ink runtime.
' 	It ensures that any implementing class provides a name and a validity check.
'
' Functionality:
'
' 	- `name`: A read-only property to retrieve the name of the content.
' 	- `hasValidName`: A read-only property to check if the name is valid.
'
' Notes:
'
' 	- Interfaces are used in Monkey2/Wonkey to define contracts for implementing classes.
' 	- The naming conventions and property structure closely follow the original Ink runtime.
'
' Technical advantages:
'
' 	- Provides a standard for handling named content across the runtime.
' 	- Simplifies the implementation of new classes by enforcing a consistent interface.
'===============================================================================

Interface INamedContent
	Method GetName:String()
	Method HasValidName:Bool()
End