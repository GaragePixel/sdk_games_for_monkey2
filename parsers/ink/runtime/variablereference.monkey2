Namespace sdk_games.parsers.ink

#Rem
'===============================================================================
' VariableReference - Handles Variable References in Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' Represents a reference to a variable in the Ink runtime. This class manages
' both named variable references and references to visit/read counts via paths.
'
' Functionality:
'
' - Stores and exposes the name of the variable reference.
' - Handles variable references to paths used for visit/read counts.
' - Provides computed properties to resolve paths and containers.
' - Includes a string representation for debugging purposes.
'
' Notes:
'
' - Encapsulates both named variables and path-based references for visit counts.
' - Includes a default constructor to support serialization.
' - Uses computed properties to simplify access to resolved paths and containers.
'
' Technical advantages:
'
' - Flexibility:
'   - Supports both named and path-based variable references in one class.
' - Encapsulation:
'   - Combines metadata and functionality for variable references into a single
'     class for easy management.
' - Serialization support:
'   - Provides a default constructor for seamless integration with serialization
'     frameworks.
' - Debugging:
'   - Implements a `ToString` method for clear debugging output.
'===============================================================================
#End

Class VariableReference Extends InkObject

	' Fields
	Field _name:String=Null
	Field _pathForCount:Path=Null

	' Computed Property: Resolves path to container
	Property containerForCount:Container()
		Return Self.ResolvePath(_pathForCount).container
	End

	' Computed Property: Converts path to string and vice versa
	Property pathStringForCount:String()
		If _pathForCount = Null Return Null
		Return CompactPathString(_pathForCount)
	Setter(value:String)
		If value = Null Then
			_pathForCount = Null
		Else
			_pathForCount = New Path(value)
		End
	End

	' Default Constructor: Required for serialization
	Method New()
	End

	' Constructor: Initializes the variable reference with a name
	Method New(name:String)
		_name = name
	End

	' Overrides ToString to provide a debugging representation
	Method ToString:String()
		If _name <> Null
			Return "var(" + _name + ")"
		Else
			Local pathStr:String = pathStringForCount
			Return "read_count(" + pathStr + ")"
		End
	End
End