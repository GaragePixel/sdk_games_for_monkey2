Namespace sdk_games.parsers.ink

'===============================================================================
' SearchResult Struct - Represents Search Results in Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This struct defines the result of content lookups within the Ink story. It
' 	is designed to handle scenarios where content paths may have changed due to
' 	story modifications or loading old save states.
'
' Functionality:
'
' 	- Field `obj:RuntimeObject`:
' 		- Stores the runtime object found during the search.
' 	- Field `approximate:Bool`:
' 		- Indicates whether the result is an approximation.
' 	- Method `CorrectObj:RuntimeObject()`:
' 		- Returns the object if it's valid, or `Null` if the result is approximate.
' 	- Method `GetContainer:Container()`:
' 		- Attempts to cast the result object to a `Container` type.
'
' Notes:
'
' 	- If a saved story path becomes invalid due to story modifications,
' 	  this struct attempts to find the closest valid container instead
' 	  of crashing.
' 	- This approach ensures robustness in dynamic story updates while
' 	  maintaining the ability to recover gracefully.
'
' Technical advantages:
'
' 	- Prevents crashes when loading old save states with outdated paths.
' 	- Provides clear methods to access and validate search results.
' 	- Enhances runtime stability by working up the story hierarchy to
' 	  find the closest valid container when needed.
'===============================================================================

Struct SearchResult

	Field obj:RuntimeObject
	Field approximate:Bool

	Method CorrectObj:RuntimeObject()
		Return approximate ? Null Else obj
	End

	Method GetContainer:Container()
		Return obj As Container
	End
End