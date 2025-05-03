Namespace sdk_games.parsers.ink

#Rem
'===============================================================================
' StringJoinExtension - Utility for Joining List Elements
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' Provides a utility function to concatenate elements of a list into a single
' string, separated by a specified delimiter. This functionality is designed
' for efficiency and compatibility with generic list types.
'
' Functionality:
'
' - Joins elements of a generic list into a single string with a specified
'   separator:
'   - Ensures compatibility with various data types.
'   - Uses efficient string concatenation to optimize performance.
'
' Notes:
'
' - The `Join` function is implemented as a static method and does not require
'   class instantiation.
' - Designed to mimic the behavior of C#'s `string.Join` for familiarity and
'   ease of use.
' - Utilizes a loop to concatenate elements and separators, avoiding repeated
'   string allocations.
'
' Technical advantages:
'
' - Performance:
'   - Avoids inefficiencies of repeated string concatenation by utilizing
'     a StringBuilder equivalent.
'   - Processes all elements within a single loop.
'
' - Simplicity:
'   - Straightforward interface for combining list elements.
'   - Easily integrates into existing projects, reducing development overhead.
'===============================================================================
#End

Class StringJoinExtension

	' Static Function: Join
	Function Join:String<T>(separator:String, objects:List<T>)
		Local sb := New StringBuilder() ' Efficient string builder usage.

		Local isFirst:Bool = True
		For Local o:T = EachIn objects

			If Not isFirst
				sb.Append(separator)

			sb.Append(o.ToString())

			isFirst = False
		End

		Return sb.ToString()
	End
End