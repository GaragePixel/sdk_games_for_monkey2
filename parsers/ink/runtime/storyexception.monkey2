Namespace sdk_games.parsers.ink

'===============================================================================
' StoryException Class - Represents Runtime Errors in Ink Stories
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This class represents exceptions that occur while running an Ink story
' 	at runtime. It is primarily used to signal errors in the Ink script,
' 	rather than issues in the Ink engine itself.
'
' Functionality:
'
' 	- Constructor `New()`:
' 		- Initializes a default instance of StoryException without a message.
' 	- Constructor `New(message:String)`:
' 		- Initializes an instance of StoryException with a specified error
' 		  message.
' 	- Field `useEndLineNumber:Bool`:
' 		- Indicates whether the exception is linked to the end line number
' 		  in the Ink story.
'
' Notes:
'
' 	- This class extends the base Exception class provided by Monkey2/Wonkey.
' 	- The `useEndLineNumber` field can be used to provide additional context
' 	  about the origin of the exception in the Ink story.
' 	- The two constructors follow the standard pattern of exception handling
' 	  in Monkey2/Wonkey.
'
' Technical advantages:
'
' 	- Provides a clear and structured way to handle runtime errors in Ink
' 	  stories.
' 	- Enables better debugging of Ink scripts by differentiating between
' 	  script errors and engine issues.
' 	- The optional `useEndLineNumber` field allows for more detailed error
' 	  reporting and recovery.
'===============================================================================

Class StoryException Extends Exception

	Field useEndLineNumber:Bool

	Method New()
		Super.New()
	End

	Method New(message:String)
		Super.New(message)
	End

End