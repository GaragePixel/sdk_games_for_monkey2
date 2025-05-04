Namespace sdk_games.parsers.ink

'===============================================================================
' Value Class - Represents a runtime value in the Ink Engine
' Implementation: iDkP from GaragePixel
' Date: 2025-05-04, Aida 4
'===============================================================================

'
' Purpose:
'
' The `Value` class and its derived classes encapsulate various runtime values
' used in the Ink engine, such as booleans, integers, floats, strings, and others.
'
' Functionality:
'
' - Base Class `Value`:
'   - Provides an abstract interface for all value types.
'   - Defines common properties such as `valueType`, `isTruthy`, and `valueObject`.
'   - Implements methods for casting between value types.
'
' - Derived Classes (`ValueBool`, `ValueInt`, etc.):
'   - Represent specific value types with specialized functionality.
'   - Support type casting and truthiness evaluation.
'
' Notes:
'
' - Enums avoid using reserved words by prefixing type names (e.g., `TBool`).
' - The `Value` class is designed as a base class, with derived classes for each
'   specific type, ensuring type safety and extensibility.
'
' Technical advantages:
'
' - Flexibility:
'   - Supports dynamic type conversion and value creation.
' - Maintainability:
'   - Follows a consistent structure for extending new value types.
' - Compatibility:
'   - Adheres to Monkey2/Wonkey language constraints and coding standards.
'
'===============================================================================

' Enum for Value Types
Enum ValueType
	TBool = -1
	TInt = 0
	TFloat = 1
	TList = 2
	TString = 3
	TDivertTarget = 4
	TVariablePointer = 5
End

' Base Class for all Value Types
Class Value Extends RuntimeObject

Public

	' Abstract Properties
	Property valueType:ValueType()
		Throw "Abstract Property: Must be implemented in derived class."
	End
	
	Property isTruthy:Bool()
		Throw "Abstract Property: Must be implemented in derived class."
	End
	
	Property valueObject:Object()
		Throw "Abstract Property: Must be implemented in derived class."
	End

	' Abstract Method for Casting
	Method CastT:Value(newType:ValueType)
		Throw "Abstract Method: Must be implemented in derived class."
	End

	' Static Factory Method for Creating Values
	Function Create:Value(val:T)
		Local type=Typeof(val)
		If type=Bool Return New ValueBool(Bool(val))
		If type=Int Return New ValueInt(Int(val))
		If type=Float Return New ValueFloat(Float(val))
		If type=String Return New ValueString(String(val))
		If type=Path Return New ValueDivertTarget(Path(val))
		If type=InkList Return New ValueList(InkList(val))
		' Add other cases as needed
		Return Null
	End

	' Method to Copy the Value
	Method Copy:Value()
		Return Create(valueObject)
	End
	
	Operator To:String()
		Return Cast<String>(value)
	End 

End

'===============================================================================
' Derived Classes for Specific Value Types
'===============================================================================

' Boolean Value
Class ValueBool Extends Value

Private
	Field _value:Bool

Public
	Property valueType:ValueType()
		Return ValueType.TBool
	End

	Property isTruthy:Bool()
		Return _value
	End

	Property valueObject:RuntimeObject()
		Return _value
	End

	Method New(val:Bool)
		_value = val
	End

	Method CastT:Value(newType:ValueType)
		Select newType
			Case ValueType.TInt Return New ValueInt(_value ? 1 Else 0)
			Case ValueType.TFloat Return New ValueFloat(_value ? 1.0 Else 0.0)
			Case ValueType.TString Return New ValueString(_value ? "true" Else "false")
			Default Throw "Invalid cast from Bool to " + newType
		End
	End

End

' Integer Value
Class ValueInt Extends Value

Private
	Field _value:Int

Public
	Property valueType:ValueType()
		Return ValueType.TInt
	End

	Property isTruthy:Bool()
		Return _value <> 0
	End

	Property valueObject:Object()
		Return _value
	End

	Method New(val:Int)
		_value = val
	End

	Method Cast:Value(newType:ValueType)
		Select newType
			Case ValueType.TBool Return New ValueBool(_value <> 0)
			Case ValueType.TFloat Return New ValueFloat(Float(_value))
			Case ValueType.TString Return New ValueString(String(_value))
			Default Throw "Invalid cast from Int to " + newType
		End
	End

End

' Float Value
Class ValueFloat Extends Value

Private
	Field _value:Float

Public
	Property valueType:ValueType()
		Return ValueType.TFloat
	End

	Property isTruthy:Bool()
		Return _value <> 0.0
	End

	Property valueObject:Object()
		Return _value
	End

	Method New(val:Float)
		_value = val
	End

	Method CastT:Value(newType:ValueType)
		Select newType
			Case ValueType.TBool Return New ValueBool(_value <> 0.0)
			Case ValueType.TInt Return New ValueInt(Int(_value))
			Case ValueType.TString Return New ValueString(String(_value))
			Default Throw "Invalid cast from Float to " + newType
		End
	End

End

' String Value
Class ValueString Extends Value

Private
	Field _value:String

Public
	Property valueType:ValueType()
		Return ValueType.TString
	End

	Property isTruthy:Bool()
		Return _value.Length > 0
	End

	Property valueObject:Object()
		Return _value
	End

	Method New(val:String)
		_value = val
	End

	Method CastT:Value(newType:ValueType)
		Select newType
			Case ValueType.TInt Return New ValueInt(Int(_value))
			Case ValueType.TFloat Return New ValueFloat(Float(_value))
			Case ValueType.TBool Return New ValueBool(_value <> "")
			Default Throw "Invalid cast from String to " + newType
		End
	End

End

' Divert Target Value
Class ValueDivertTarget Extends Value

Private
	Field _targetPath:Path

Public
	Property valueType:ValueType()
		Return ValueType.TDivertTarget
	End

	Property isTruthy:Bool()
		Throw "Shouldn't check truthiness of a divert target"
	End

	Property valueObject:Object()
		Return _targetPath
	End

	Method New(path:Path)
		_targetPath = path
	End

	Method CastT:Value(newType:ValueType)
		If newType = ValueType.TDivertTarget Return Self
		Throw "Invalid cast from DivertTarget to " + newType
	End

End

' Variable Pointer Value
Class ValueVariablePointer Extends Value

Private
	Field _variableName:String
	Field _contextIndex:Int

Public
	Property valueType:ValueType()
		Return ValueType.TVariablePointer
	End

	Property isTruthy:Bool()
		Throw "Shouldn't check truthiness of a variable pointer"
	End

	Property valueObject:Object()
		Return _variableName
	End

	Method New(name:String, contextIndex:Int=-1)
		_variableName = name
		_contextIndex = contextIndex
	End

	Method CastT:Value(newType:ValueType)
		If newType = ValueType.TVariablePointer Return Self
		Throw "Invalid cast from VariablePointer to " + newType
	End

End

' List Value
Class ValueList Extends Value

Private
	Field _value:InkList

Public
	Property valueType:ValueType()
		Return ValueType.TList
	End

	Property isTruthy:Bool()
		Return _value.Count > 0
	End

	Property valueObject:Object()
		Return _value
	End

	Method New(list:InkList)
		_value = list
	End

	Method CastT:Value(newType:ValueType)
		If newType = ValueType.TList Return Self
		Throw "Invalid cast from List to " + newType
	End

End
