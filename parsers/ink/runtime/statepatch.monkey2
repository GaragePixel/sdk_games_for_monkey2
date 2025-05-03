'=============================================================================== 
' StatePatch Class - Represents a Patch for State Modifications ~n 
' Implementation: iDkP from GaragePixel 
' Date: 2025-05-03, Aida 4 
'=============================================================================== 
' 
' Purpose: 
' 
' This class encapsulates a "patch" for the Ink runtime state. It is used to 
' track modifications to variables, visit counts, and turn indices without 
' directly modifying the original state. This allows for efficient state 
' management and provides a mechanism for temporary or incremental updates. 
' 
' Functionality: 
' 
' - Fields: 
' - _globals: Stores global variables and their values. 
' - _changedVariables: Tracks variables that have been modified. 
' - _visitCounts: Tracks the visit counts for containers. 
' - _turnIndices: Tracks the turn indices for containers. 
' 
' - Methods: 
' - TryGetGlobal: Attempts to retrieve a global variable by name. 
' - SetGlobal: Sets the value of a global variable. 
' - AddChangedVariable: Adds a variable to the changed variables set. 
' - TryGetVisitCount: Attempts to retrieve the visit count for a container. 
' - SetVisitCount: Sets the visit count for a container. 
' - SetTurnIndex: Sets the turn index for a container. 
' - TryGetTurnIndex: Attempts to retrieve the turn index for a container. 
' 
' - Constructor: 
' - Creates a new StatePatch instance, optionally copying data from an 
' existing StatePatch. 
' 
' Notes: 
' 
' - This class is designed to work seamlessly with the Ink runtime, enabling 
' efficient state management and patching capabilities. 
' - The use of dictionaries and hash sets ensures fast lookups and updates. 
' 
' Technical advantages: 
' 
' - Efficiency: 
' - Provides a lightweight mechanism for tracking state changes without 
' modifying the original state. 
' - Flexibility: 
' - Can be used for temporary or incremental updates to the state. 
' - Robustness: 
' - Ensures consistency by maintaining separate data structures for globals, 
' changed variables, visit counts, and turn indices. 
' 
'===============================================================================

Class StatePatch

Private

	Field _globals:Map<String,RuntimeObject>
	Field _changedVariables:Set<String>
	Field _visitCounts:Map<Container,Int>
	Field _turnIndices:Map<Container,Int>

Public

	Method New(toCopy:StatePatch = Null)
		If toCopy <> Null
			_globals = toCopy._globals.Copy()
			_changedVariables = toCopy._changedVariables.Copy()
			_visitCounts = toCopy._visitCounts.Copy()
			_turnIndices = toCopy._turnIndices.Copy()
		Else
			_globals = New Map<String,RuntimeObject>()
			_changedVariables = New Set<String>()
			_visitCounts = New Map<Container,Int>()
			_turnIndices = New Map<Container,Int>()
		End
	End

Public

	Property globals:Map<String,RuntimeObject>()
		Return _globals
	End

	Property changedVariables:Set<String>()
		Return _changedVariables
	End

	Property visitCounts:Map<Container,Int>()
		Return _visitCounts
	End

	Property turnIndices:Map<Container,Int>()
		Return _turnIndices
	End

	Method TryGetGlobal:Bool(name:String, value:RuntimeObject)
		Return _globals.TryGetValue(name, value)
	End

	Method SetGlobal(name:String, value:RuntimeObject)
		_globals[name] = value
	End

	Method AddChangedVariable(name:String)
		_changedVariables.Add(name)
	End

	Method TryGetVisitCount:Bool(container:Container, count:Int)
		Return _visitCounts.TryGetValue(container, count)
	End

	Method SetVisitCount(container:Container, count:Int)
		_visitCounts[container] = count
	End

	Method SetTurnIndex(container:Container, index:Int)
		_turnIndices[container] = index
	End

	Method TryGetTurnIndex:Bool(container:Container, index:Int)
		Return _turnIndices.TryGetValue(container, index)
	End
End
