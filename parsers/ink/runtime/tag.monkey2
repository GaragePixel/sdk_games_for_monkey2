Namespace sdk_games.parsers.ink

'===============================================================================
' Tag Class - Represents Tags in Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This class defines a Tag in the Ink runtime, which is used to represent
' 	textual tags embedded within the story output stream.
'
' Functionality:
'
' 	- Constructor `New(tagText:String)`:
' 		- Initializes a new tag with the specified text.
' 	- Method `ToString:String()`:
' 		- Returns the tag formatted as a string prefixed by "# ".
'
' Notes:
'
' 	- Tags are dynamically constructed at runtime based on BeginTag
' 	  and EndTag control commands.
' 	- Plain text in the output stream is turned into tags when
' 	  `story.currentTags` is called.
' 	- This class is primarily utilized during dynamic string
' 	  generation if a tag is embedded in it.
' 	- See the implementation of `ControlCommand.EndString` in `Story.monkey2`
' 	  for additional context.
'
' Technical advantages:
'
' 	- Provides a clear and standardized way to handle tags in the runtime.
' 	- Simplifies integration of tags into dynamic string generation and
' 	  narrative output processing.
'===============================================================================

Class Tag Extends RuntimeObject

	Field text:String

	Method New(tagText:String)
		Self.text = tagText
	End

	Method ToString:String()
		Return "# " + text
	End
End