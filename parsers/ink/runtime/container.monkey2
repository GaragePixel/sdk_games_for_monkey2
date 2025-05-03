Namespace sdk_games.parsers.ink

'===============================================================================
' Container Class - Represents a Collection of Runtime Objects
' Implementation: iDkP from GaragePixel
' Date: 2025-05-02, Aida 4
'===============================================================================
'
' Purpose:
'
' 	This class acts as a container for runtime objects in the Ink engine. It
' 	manages objects, named content, and facilitates path-based content lookups.
'
' Functionality:
'
' 	- Manage runtime objects (`AddContent`, `InsertContent`, `AddContentsOfContainer`).
' 	- Handle named content (`TryAddNamedContent`, `AddToNamedContentOnly`).
' 	- Perform path-based lookups (`ContentAtPath`, `ContentWithPathComponent`).
' 	- Generate hierarchical string representations (`BuildStringOfHierarchy`).
' 	- Manage counting flags for visits and turns.
'
' Notes:
'
' 	- This class extends `RuntimeObject` and implements the `INamedContent` interface.
' 	- The class uses a combination of lists and dictionaries to manage content
' 	  and named content, ensuring efficient lookups and updates.
' 	- Path-based lookups are optimized to handle partial paths and recover from
' 	  invalid paths gracefully.
'
' Technical advantages:
'
' 	- Provides a robust and flexible way to manage runtime objects and named
' 	  content in the Ink engine.
' 	- Ensures efficient content lookups and updates with proper error handling.
' 	- Facilitates debugging and visualization through hierarchical string
' 	  representations.
'===============================================================================

Class Container Extends RuntimeObject Implements INamedContent

	Field _name:String
	Field _content:=New List<RuntimeObject>()
	Field _namedContent:=New Map<String,INamedContent>()
	Field _visitsShouldBeCounted:Bool
	Field _turnIndexShouldBeCounted:Bool
	Field _countingAtStartOnly:Bool

	Method New()
		_content = New List<RuntimeObject>()
		_namedContent = New Map<String,INamedContent>()
	End

	Method AddContent(contentObj:RuntimeObject)
		_content.Add(contentObj)

		If contentObj.parent
			Throw New RuntimeException("Content is already in " + contentObj.parent.ToString())
		End

		contentObj.parent = Self
		TryAddNamedContent(contentObj)
	End

	Method InsertContent(contentObj:RuntimeObject, index:Int)
		_content.Insert(index, contentObj)

		If contentObj.parent
			Throw New RuntimeException("Content is already in " + contentObj.parent.ToString())
		End

		contentObj.parent = Self
		TryAddNamedContent(contentObj)
	End

	Method TryAddNamedContent(contentObj:RuntimeObject)
		Local namedContentObj:=contentObj
		If namedContentObj And namedContentObj.HasValidName()
			AddToNamedContentOnly(namedContentObj)
		End
	End

	Method AddToNamedContentOnly(namedContentObj:INamedContent)
		Local runtimeObj:=namedContentObj
		DebugAssert(runtimeObj <> Null, "Can only add Runtime.Objects to a Runtime.Container")
		runtimeObj.parent = Self
		_namedContent[namedContentObj.name] = namedContentObj
	End

	Method ContentAtPath:SearchResult(path:Path, partialPathStart:Int=0, partialPathLength:Int=-1)
		If partialPathLength = -1
			partialPathLength = path.Length
		End

		Local result:=New SearchResult()
		result.approximate = False

		Local currentContainer:=Self
		Local currentObj:=Self

		For Local i:=partialPathStart Until partialPathLength
			Local comp:=path.GetComponent(i)

			If Not currentContainer
				result.approximate = True
				Break
			End

			Local foundObj:=currentContainer.ContentWithPathComponent(comp)

			If Not foundObj
				result.approximate = True
				Break
			End

			Local nextContainer:=foundObj
			If i < partialPathLength - 1 And Not nextContainer
				result.approximate = True
				Break
			End

			currentObj = foundObj
			currentContainer = nextContainer
		Next

		result.obj = currentObj
		Return result
	End

	Method BuildStringOfHierarchy(sb:StringBuilder, indentation:Int, pointedObj:RuntimeObject)
		Local appendIndentation:=Lambda()
			Local spacesPerIndent:=4
			For Local i:=0 Until spacesPerIndent * indentation
				sb.Append(" ")
			Next
		End

		appendIndentation()
		sb.Append("[")

		If Self.HasValidName()
			sb.AppendFormat(" ({0})", _name)
		End

		If Self = pointedObj
			sb.Append("  <---")
		End

		sb.AppendLine()
		indentation += 1

		For Local i:=0 Until _content.Length
			Local obj:=_content[i]

			If Typeof(obj)=Container
				Local container:=obj
				container.BuildStringOfHierarchy(sb, indentation, pointedObj)
			Else
				appendIndentation()
				If Typeof(obj)=StringValue
					sb.Append("\")
					sb.Append(obj.ToString().Replace("\n", "\\n"))
					sb.Append("\")
				Else
					sb.Append(obj.ToString())
				End
			End

			If i <> _content.Length - 1
				sb.Append(",")
			End

			If Not (Typeof(obj)=Container) And obj = pointedObj
				sb.Append("  <---")
			End

			sb.AppendLine()
		Next

		indentation -= 1
		appendIndentation()
		sb.Append("]")
	End

	Method BuildStringOfHierarchy:String()
		Local sb:=New StringBuilder()
		BuildStringOfHierarchy(sb, 0, Null)
		Return sb.ToString()
	End

End