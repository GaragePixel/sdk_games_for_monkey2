Namespace sdk_games.parsers.ink

'===============================================================================
' Glue Class - Placeholder Marker for Seamless Content Stitching
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This class represents a "Glue" object within the Ink runtime. It serves
' 	as a marker within the story content, connecting parts of the narrative
' 	seamlessly. Glue ensures logical continuity without requiring additional
' 	control structures or branching logic.
'
' Functionality:
'
' 	- Acts as a content-stitching marker in Ink stories:
' 		- Provides a placeholder for seamless narrative transitions.
' 		- Overrides the ToString method to return "Glue" for debugging or serialization.
'
' Notes:
'
' 	- Glue inherits from RuntimeObject to integrate seamlessly into the Ink
' 	  runtime's object hierarchy, ensuring compatibility with runtime logic.
' 	- The ToString method provides a clear string representation to assist
' 	  in debugging and runtime visualization.
'
' Technical advantages:
'
' 	- Simplifies narrative design by providing a standard marker for content
' 	  continuity.
' 	- Ensures consistent behavior across the runtime object model.
'===============================================================================


Class Glue Extends RuntimeObject

	' Constructor
	Method New()
		' Empty constructor: No initialization required
	End

	' Override ToString Method
	Method ToString:String()
		Return "Glue"
	End

End