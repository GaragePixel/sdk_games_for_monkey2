Namespace sdk_games.parsers.ink

'===============================================================================
' Path Class - Represents a Path in the Ink Runtime
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
'
' The `Path` class encapsulates the concept of paths within the Ink runtime.
' Paths represent navigation or location references in the story structure,
' such as container hierarchies and parent or absolute positions.
'
' Functionality:
'
' - Properties:
'   - `isParent`: Indicates whether the path is parent.
'   - `head`: Retrieves the first component of the path.
'   - `tail`: Retrieves the remaining components of the path after the head.
'   - `length`: Retrieves the number of components in the path.
'   - `lastComponent`: Retrieves the last component of the path.
'   - `containsNamedComponent`: Indicates whether the path contains named components.
'
' - Methods:
'   - `PathByAppendingPath`: Appends another path to this one, resolving parent paths.
'   - `PathByAppendingComponent`: Appends a single component to this path.
'   - `ToString`: Returns a string representation of the path.
'   - `Equals`: Compares two paths for equality.
'   - `GetComponent`: Retrieves a component at a specified index.
'
' - Nested Class:
'   - `Path.Component`: Represents an individual component of the path.
'
' Notes:
'
' - The `Path` class is designed to support both parent and absolute paths.
' - Components can be indices or named identifiers, enabling flexible referencing.
'
' Technical advantages:
'
' - Efficiency:
'   - Uses optimized structures for path manipulation and comparison.
' - Flexibility:
'   - Supports dynamic path construction and navigation.
' - Robustness:
'   - Ensures consistency by validating components and resolving parent paths.
'
'===============================================================================

Using stdlib.stringio

Class Path Extends RuntimeObject

	Const ParentId:="^"

	' Path.Component Class - Represents an Individual Component of a Path
	Class Component Extends RuntimeObject
	
		Field index:Int
		Field name:String
	
		Property isIndex:Bool()
			Return index >= 0
		End
	
		Property isParent:Bool()
			Return name = Path.ParentID
		End
	
		Method New(index:Int)
			Debug.Assert(index >= 0)
			Self.index = index
			name = Null
		End
	
		Method New(name:String)
			Debug.Assert(name <> Null And name.Length > 0)
			Self.name = name
			index = -1
		End
		
		Function ToParent:Component()
			Return New Component(Path.ParentId)
		End 
	
		Method ToString:String()
			If isIndex
				Return String(index)
			Else
				Return name
			End
		End
		
		Operator To.String()
			Return ToString()
		End 

		Method Equals:Bool(other:Path.Component)
			If other <> Null 
				If other.isIndex <> isIndex Return False
				If isIndex
					Return index = other.index
				Else
					Return name = other.name
				End
			End 
			Return False
		End
		
		Method GetHashCode:String()
			If isIndex Return index 
			Local hash := SHA256()
			hash.Update(name)
			Return hash.Digest()
		End 
	End

Public

	Method GetComponent:Path.Component(index:Int)
		Return _components[index]
	End
	
	Field isRelative:Bool

	Property head:Path.Component()
		If _components.Length > 0
			Return _components.First
		Else
			Return Null
		End
	End

	Property tail:Path()
		If _components.Length >= 2
			Local tailComponents := New List<PathComponent>()
			For Local i:Int = 1 Until _components.Length
				tailComponents.Add(_components[i])
			End
			Return New Path(tailComponents)
		Else
			Return selfpath 'TESTME
		End
	End

	Property length:Int()
		'Compared to c#, Aida is poetry: 
		'	public int length { get { return _components.Count; } }
		Return _components.Length
	End

	Property lastComponent:Path.Component()
		Local lastIndex := _components.Length - 1
		If lastIndex >= 0
			Return _components[lastIndex]
		Else
			Return Null
		End
	End

	Property containsNamedComponent:Bool()
		For Local component:Path.Component = EachIn _components
			If Not component.isIndex
				Return True
			End
		End
		Return False
	End

	Method New()
		_components = New List<Path.Component>()
	End

	Method New(head:Path.Component, tail:Path)
		_components = New List<Path.Component>()
		_components.Add(head)
		_components.AddRange(tail._components)
	End

	Method New(components:List<Path.Component>, relative:Bool = False)
		_components = New List<Path.Component>()
		_components.AddRange(components)
		isRelative = relative
	End

	Method New(componentsString:String)
		_components = New List<Path.Component>()
		Self.componentsString = componentsString
	End
	
	Property selfpath() 
		'iDkP: I'm not sure if it's really the "Self" internal id system from inherence
		'or something else, but if every non-tail paths are relative so maybe I can optimize
		'it by using Self, making a better gc managing.
		Local path:=New Path()
		path.isRelative = True 
		Return path
	End 

	Method PathByAppendingPath:Path(pathToAppend:Path)
		Local result := New Path()
		Local upwardMoves:Int = 0

		For Local component:Path.Component = EachIn pathToAppend._components
			If component.isParent
				upwardMoves += 1
			Else
				Exit
			End
		End

		For Local i:Int = 0 Until _components.Length - upwardMoves
			result._components.Add(_components[i])
		End

		For Local i:Int = upwardMoves Until pathToAppend._components.Length
			result._components.Add(pathToAppend._components[i])
		End

		Return result
	End

	Method PathByAppendingComponent:Path(component:Path.Component)
		Local result := New Path()
		result._components.AddRange(_components)
		result._components.Add(component)
		Return result
	End

	Property componentsString:String()
		If _componentsString = Null
			_componentsString = StringJoin(".", _components) 'From stdlib.stringio
			If isRelative _componentsString = "." + _componentsString
		End
		Return _componentsString
	Setter(value:String)
		_components.Clear()
		_componentsString = value

		' Empty path, empty components
		' (path is to root, like "/" in file system)
		If _componentsString = "" Exit

		' When components start with ".", it indicates a relative path, e.g.
		'   .^.^.hello.5
		' is equivalent to file system style path:
		'  ../../hello/5
		If _componentsString[0] = "."
			isRelative = True
			'_componentsString = _componentsString[1..] 'REWROTE WITH THE FOLLOWING CODE
			Local componentsString := New List<PathComponent>()
			For Local i:Int = 1 Until _componentsString.Length
				componentsString.Add(_components[i])
			End
			_componentsString=componentsString
		Else
			isRelative = False
		End

		For Local str:String = EachIn _componentsString.Split(".")
			Local idx:Int
			If Int.TryParse(str, idx)
				_components.Add(New Path.Component(idx))
			Else
				_components.Add(New Path.Component(str))
			End
		End	
	End
	
	Field _componentsString:String

	Method ToString:String()
		Return componentsString
	End
	
	Operator To:String() 'For future better Aida code translation
		Return componentsString
	End

	Method Equals:Bool(other:Path)
		If other = Null Return False
		If other._components.Length <> _components.Length Return False
		If other.isRelative  <> isRelative  Return False
		Return other._components = _components
	End
	
	Method GetHashCode:String()
		' Generate a hash code using SHA-256 from stdlib
		' Better way to make a hash code; DONE!
		Local hash := SHA256()
		hash.Update(componentsString)
		Return hash.Digest()
	End

Private

	Field _components:List<Path.Component> = Null
End
