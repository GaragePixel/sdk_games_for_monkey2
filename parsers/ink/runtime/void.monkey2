Namespace sdk_games.parsers.ink

'===============================================================================
' RuntimeVoid Class (iDkP from GaragePixel, 2025-05-02, Aida v1)
'===============================================================================
' Purpose:
' 
' 	This class represents a placeholder or "void-like" object within the Ink runtime.
' 	It provides a standard way to indicate "nothingness" or an empty object in the
' 	runtime logic, ensuring consistency and compatibility.
'
' Functionality:
'
' 	- Provides a runtime-safe object to represent "void" or "empty" states:
' 		- Ensures compatibility with the runtime's object system.
' 		- Avoids the use of null or undefined states.
'
' Notes:
'
' 	The `RuntimeVoid` class inherits from `RuntimeObject`. This design choice ensures
' 	that it integrates seamlessly into the object hierarchy of the runtime while
' 	allowing it to function as a placeholder wherever an object is expected.
'
' 	The constructor is intentionally empty, as no initialization is required for
' 	this class. Its sole purpose is to act as a standardized "no-op" object.
'
' Technical advantages:
'
' 	- Standardization:
' 		- Provides a consistent way to handle "void" states across the runtime.
' 		- Avoids the risk of null pointer exceptions by using a defined object.
'
' 	- Compatibility:
' 		- Seamlessly integrates with the object hierarchy of the Ink runtime.
' 		- Simplifies logic by providing a defined fallback object.
'===============================================================================

Class RuntimeVoid Extends RuntimeObject

	' Constructor
	Method New()
		' Empty constructor: No initialization required
	End

	' Singleton Instance Property
	Field _instance:RuntimeVoid

	Property Instance:RuntimeVoid()
		If _instance = Null Then _instance = New RuntimeVoid()
		Return _instance
	End

End