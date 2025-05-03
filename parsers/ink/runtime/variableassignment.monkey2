Namespace sdk_games.parsers.ink

#Rem
'===============================================================================
' VariableAssignment - Handles Variable Assignments in Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' Represents a variable assignment operation in the Ink runtime. This class
' stores metadata about the variable assignment, such as the variable name,
' whether it's a new declaration, and its scope (global or local).
'
' Functionality:
'
' - Stores and exposes the name of the variable being assigned.
' - Tracks whether the assignment represents a new declaration.
' - Tracks whether the variable is global or local in scope.
' - Provides a string representation of the assignment for debugging purposes.
'
' Notes:
'
' - The assigned value is not stored in this class, as it is expected to be
'   popped off the evaluation stack during execution.
' - Includes a default constructor to support serialization.
'
' Technical advantages:
'
' - Encapsulation:
'   - Combines variable metadata into a single class for easy management.
' - Serialization support:
'   - Provides a default constructor for seamless integration with
'     serialization frameworks.
' - Debugging:
'   - Implements a `ToString` method for clear debugging output.
'===============================================================================
#End

Class VariableAssignment Extends InkObject

	' Fields
	Field _variableName:String=Null 
	Field _isNewDeclaration:Bool=Null 
	Field _isGlobal:Bool

	' Default Constructor: Required for serialization
	Method New()
	End

	' Constructor: Initializes the variable assignment metadata
	Method New(variableName:String, isNewDeclaration:Bool)
		_variableName = variableName
		_isNewDeclaration = isNewDeclaration
	End

	' Overrides ToString to provide a debugging representation
	Method ToString:String()
		Return "VarAssign to " + _variableName
	End
End