Namespace sdk_games.parsers.ink

'===============================================================================
' RuntimeObject Class - Base class for all ink runtime content
' Implementation: iDkP from GaragePixel
' Date: 2025-05-04, Aida 4
'===============================================================================

'
' Purpose:
'
' The `RuntimeObject` class serves as the base for all runtime content in the Ink engine.
' It provides hierarchical structures, path resolution, and debug metadata functionality.
'
' Functionality:
'
' - Hierarchical Structure:
'   - `Parent`: Defines the parent object in the hierarchy.
'   - `rootContentContainer`: Retrieves the root container of the hierarchy.
'
' - Path Management:
'   - `path`: Retrieves the path from the root to the object.
'   - `ResolvePath`: Resolves a given path to a content object.
'   - `ConvertPathToRelative`: Converts a global path to a relative path.
'   - `CompactPathString`: Finds the most compact representation of a path.
'
' - Debug Metadata:
'   - `debugMetadata`: Gets or sets the debug metadata.
'   - `ownDebugMetadata`: Retrieves the object's own debug metadata.
'   - `DebugLineNumberOfPath`: Retrieves the debug line number for a specific path.
'
' - Object Management:
'   - `Copy`: Creates a copy of the object (not implemented in this base class).
'   - `SetChild`: Sets a child object and manages its parent relationship.
'
' - Equality and Comparison:
'   - Implicit and explicit comparisons for `RuntimeObject` instances.
'
' Notes:
'
' - The `RuntimeObject` class is the foundation of the Ink runtime object hierarchy.
' - It includes features for path resolution and debug metadata handling.
'
' Technical advantages:
'
' - Flexibility:
'   - Supports dynamic content navigation and manipulation.
' - Debugging:
'   - Provides detailed metadata for debugging and error tracking.
' - Robustness:
'   - Ensures consistency in hierarchy and path relationships.
'
'===============================================================================

Class RuntimeObject

' Debug Metadata
Private

	Field _debugMetadata:DebugMetadata

Public

	Property Parent:RuntimeObject
		Return _parent
	End 

	Property debugMetadata:DebugMetadata()
		If _debugMetadata = Null And Parent
			Return Parent.debugMetadata
		End
		Return _debugMetadata
	Setter(value:DebugMetadata)
		_debugMetadata = value
	End

	Property ownDebugMetadata:DebugMetadata()
		Return _debugMetadata
	End

	Method DebugLineNumberOfPath:Int(path:Path)
		If path = Null Return Null

		Local root := Self.rootContentContainer
		If root
			Local targetContent := root.ContentAtPath(path).obj
			If targetContent
				Local dm := targetContent.debugMetadata
				If dm <> Null Return dm.startLineNumber
			End
		End

		Return Null
	End

' Hierarchical Structure
Private

	Field _path:Path

Public

	Property path:Path()
		If _path = Null
			If Parent = Null
				_path = New Path()
			Else
				' Maintain a Stack so that the order of the components
				' is reversed when they're added to the Path.
				' We're iterating up the hierarchy from the leaves/children to the root.
				Local comps := New Stack<Path.Component>()
				Local child := Self
				Local container := child.Parent 'as Container

				While container
					Local namedChild := child 'as INamedContent
					If namedChild <> Null And namedChild.hasValidName
						comps.Push(New Path.Component(namedChild.name))
					Else
						comps.Push(New Path.Component(container.content.IndexOf(child)))
					End
					child = container
					container = container.Parent' As Container
				Wend

				_path = New Path(comps)
			End
		End
		Return _path
	End

	Method ResolvePath:SearchResult(path:Path)
		If path.isRelative
			Local nearestContainer := Self' As Container
			If nearestContainer = Null
				Assert(Parent <> Null, "Can't resolve relative path because we don't have a parent")
				nearestContainer = Parent ' As Container
				Assert(nearestContainer <> Null, "Expected parent to be a container")
				Assert(path.GetComponent(0).isParent)
				path = path.tail
			End
			Return nearestContainer.ContentAtPath(path)
		Else
			Return Self.rootContentContainer.ContentAtPath(path)
		End
	End

	Method ConvertPathToRelative:Path(globalPath:Path)
		Local ownPath := _path
		Local minPathLength := Min(globalPath.length, ownPath.length)
		Local lastSharedPathCompIndex:Int = -1

		For Local i:Int = 0 Until minPathLength
			Local ownComp := ownPath.GetComponent(i)
			Local otherComp := globalPath.GetComponent(i)
			If ownComp.Equals(otherComp)
				lastSharedPathCompIndex = i
			Else
				Exit
			End
		End

		If lastSharedPathCompIndex = -1 Return globalPath

		Local numUpwardsMoves := (ownPath.length - 1) - lastSharedPathCompIndex

		Local newPathComps := New List<Path.Component>()
		For Local up:Int = 0 Until numUpwardsMoves
			newPathComps.Add(Path.Component.ToParent())
		End

		For Local down:Int = lastSharedPathCompIndex + 1 Until globalPath.length
			newPathComps.Add(globalPath.GetComponent(down))
		End

		Return New Path(newPathComps, True)
	End

	Method CompactPathString:String(otherPath:Path)
		Local globalPathStr:String = Null
		Local relativePathStr:String = Null

		If otherPath.isRelative
			relativePathStr = otherPath.componentsString
			globalPathStr = Self.path.PathByAppendingPath(otherPath).componentsString
		Else
			Local relativePath := ConvertPathToRelative(otherPath)
			relativePathStr = relativePath.componentsString
			globalPathStr = otherPath.componentsString
		End

		If relativePathStr.Length < globalPathStr.Length
			Return relativePathStr
		Else
			Return globalPathStr
		End
	End
		
	Property rootContentContainer:Container()
		Local ancestor := Self
		While ancestor.Parent
			ancestor = ancestor.Parent
		Wend
		Return ancestor' As Container
	End

	Method Copy:RuntimeObject()
		Throw "RuntimeObject.Copy() not implemented for " + Typeof(Self)
	End

	Method SetChild(obj Var:RuntimeObject, value:RuntimeObject)
	'Method SetChild<T>(obj Var:T, value:T) Where T:RuntimeObject
		If obj <> Null obj.Parent = Null
		obj = value
		If obj <> Null obj.Parent = Self
	End

	Operator To:Bool()
		'Return Not Object.ReferenceEquals(Self, Null)
		Return Self=Null
	End

	Operator =:Bool(other:RuntimeObject)
		'Return Object.ReferenceEquals(Self, other)
		Return Self=other
	End

	Operator <>:Bool(other:RuntimeObject)
		Return Not (Self = other)
	End

	Method Equals:Bool(other:Object)
		'Return Object.ReferenceEquals(Self, other)
		Return Self=other
	End

	Method GetHashCode:Int()
		Return Super.GetHashCode()
	End

End
