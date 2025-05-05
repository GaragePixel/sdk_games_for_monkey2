Namespace sdk_games.parsers.ink

#Rem
'===============================================================================
' JsonSerialisation - JSON Serialization and Deserialization Utilities
' Implementation: iDkP from GaragePixel
' Date: 2025-05-05, Aida 4
'===============================================================================
'
' Purpose:
'
' Provides methods for serializing and deserializing runtime objects to and from
' JSON format. This module enables seamless data manipulation and storage for
' the Ink runtime system in Monkey2/Wonkey.
'
' Functionality:
'
' - Convert JSON arrays to runtime object lists and containers.
' - Serialize runtime objects to JSON strings.
' - Deserialize JSON strings into runtime objects.
' - Write runtime containers, dictionaries, and lists to JSON.
' - Handle Ink-specific serialization schemes for containers, values, and commands.
'
' Notes:
'
' - Relies on Monkey2/Wonkey's `stdlib.io.json` and `stdlib.stringio` for JSON
'   handling and file operations.
' - Implements Ink-specific serialization schemes for runtime objects such as
'   containers, divert targets, and values.
' - The `_controlCommandNames` array maps control command types to their string
'   representations for serialization and deserialization.
'
' Technical advantages:
'
' - Compatibility:
'   - Fully compatible with Monkey2/Wonkey runtime and syntax.
'   - Adheres to Ink's serialization format for runtime objects.
'
' - Simplicity:
'   - Abstracts JSON operations with concise, reusable methods.
'   - Reduces development overhead for JSON handling in Ink projects.
'
' - Performance:
'   - Optimized for efficient serialization and deserialization.
'===============================================================================
#End

#Import "../../io/stringio.monkey2"
#Import "../../io/json/json.monkey2"

Using stdlib.stringio
Using stdlib.io.json

Class JsonSerialisation
	' Maps control command types to their string names in JSON
	Field _controlCommandNames:String[]

	' Constructor: Initializes the control command name map
	Method New()
		_controlCommandNames = New String[ControlCommand.CommandType.TOTAL_VALUES]

		_controlCommandNames[ControlCommand.CommandType.EvalStart]         = "ev"
		_controlCommandNames[ControlCommand.CommandType.EvalOutput]        = "out"
		_controlCommandNames[ControlCommand.CommandType.EvalEnd]           = "/ev"
		_controlCommandNames[ControlCommand.CommandType.Duplicate]         = "du"
		_controlCommandNames[ControlCommand.CommandType.PopEvaluatedValue] = "pop"
		_controlCommandNames[ControlCommand.CommandType.PopFunction]       = "~ret"
		_controlCommandNames[ControlCommand.CommandType.PopTunnel]         = "->->"
		_controlCommandNames[ControlCommand.CommandType.BeginString]       = "str"
		_controlCommandNames[ControlCommand.CommandType.EndString]         = "/str"
		_controlCommandNames[ControlCommand.CommandType.NoOp]              = "nop"
		_controlCommandNames[ControlCommand.CommandType.ChoiceCount]       = "choiceCnt"
		_controlCommandNames[ControlCommand.CommandType.Turns]             = "turn"
		_controlCommandNames[ControlCommand.CommandType.TurnsSince]        = "turns"
		_controlCommandNames[ControlCommand.CommandType.ReadCount]         = "readc"
		_controlCommandNames[ControlCommand.CommandType.Random]            = "rnd"
		_controlCommandNames[ControlCommand.CommandType.SeedRandom]        = "srnd"
		_controlCommandNames[ControlCommand.CommandType.VisitIndex]        = "visit"
		_controlCommandNames[ControlCommand.CommandType.SequenceShuffleIndex] = "seq"
		_controlCommandNames[ControlCommand.CommandType.StartThread]       = "thread"
		_controlCommandNames[ControlCommand.CommandType.Done]              = "done"
		_controlCommandNames[ControlCommand.CommandType.End]               = "end"
		_controlCommandNames[ControlCommand.CommandType.ListFromInt]       = "listInt"
		_controlCommandNames[ControlCommand.CommandType.ListRange]         = "range"
		_controlCommandNames[ControlCommand.CommandType.ListRandom]        = "lrnd"
		_controlCommandNames[ControlCommand.CommandType.BeginTag]          = "#"
		_controlCommandNames[ControlCommand.CommandType.EndTag]            = "/#"

		' Verify all commands are mapped
		For Local i:Int = 0 Until ControlCommand.CommandType.TOTAL_VALUES
			If _controlCommandNames[i] = Null
				Error("Internal Error: Control command not accounted for in serialization: " + i)
			End
		Next
	End

	' Converts a JSON array to a List of RuntimeObjects.
	' Optionally skips the last element (used for container terminators).
	Method JArrayToRuntimeObjList:List<RuntimeObject>(jArray:JsonArray, skipLast:Bool=False)
		Local count:Int = jArray.Length
		If skipLast
			count -= 1
		End

		Local resultList:List<RuntimeObject> = New List<RuntimeObject>(count)
		For Local i:Int = 0 Until count
			Local jToken:JsonValue = jArray[i]
			Local runtimeObj:RuntimeObject = JTokenToRuntimeObject(jToken)
			resultList.AddLast(runtimeObj)
		Next
		Return resultList
	End

	' Writes a dictionary mapping strings to RuntimeObjects into JSON format.
	Method WriteDictionaryRuntimeObjs:Void(writer:SimpleJsonWriter, dictionary:StringMap<RuntimeObject>)
		writer.WriteObjectStart()
		For Local keyValue:= Eachin dictionary
			writer.WritePropertyName(keyValue.Key)
			WriteRuntimeObject(writer, keyValue.Value)
		Next
		writer.WriteObjectEnd()
	End

	' Writes a List of RuntimeObjects into JSON format (as a JSON array).
	Method WriteListRuntimeObjs:Void(writer:SimpleJsonWriter, list:List<RuntimeObject>)
		writer.WriteArrayStart()
		For Local obj:RuntimeObject = Eachin list
			WriteRuntimeObject(writer, obj)
		Next
		writer.WriteArrayEnd()
	End

	' Writes a dictionary mapping strings to integers into JSON format.
	Method WriteIntDictionary:Void(writer:SimpleJsonWriter, dictionary:StringMap<Int>)
		writer.WriteObjectStart()
		For Local keyValue:= Eachin dictionary
			writer.WritePropertyName(keyValue.Key)
			writer.WriteInt(keyValue.Value)
		Next
		writer.WriteObjectEnd()
	End

	' Writes a generic RuntimeObject to JSON, dispatching to specific writers based on type.
	Method WriteRuntimeObject:Void(writer:SimpleJsonWriter, obj:RuntimeObject)
		' Handle null separately
		If obj = Null
			writer.WriteNull()
			Return
		End

		' RuntimeObject hierarchy checks
		If Container(obj) <> Null
			WriteRuntimeContainer(writer, Container(obj))
		Else If Divert(obj) <> Null
			WriteDivert(writer, Divert(obj))
		Else If ChoicePoint(obj) <> Null
			WriteChoicePoint(writer, ChoicePoint(obj))
		Else If BoolValue(obj) <> Null
			writer.WriteBool(BoolValue(obj).value)
		Else If IntValue(obj) <> Null
			writer.WriteInt(IntValue(obj).value)
		Else If FloatValue(obj) <> Null
			writer.WriteFloat(FloatValue(obj).value)
		Else If StringValue(obj) <> Null
			writer.WriteString(StringValue(obj).value)
		Else If ListValue(obj) <> Null
			WriteInkList(writer, ListValue(obj).value)
		Else If DivertTargetValue(obj) <> Null
			writer.WriteObjectStart()
			writer.WritePropertyName("^->")
			writer.WriteString(DivertTargetValue(obj).value.ToString())
			writer.WriteObjectEnd()
		Else If VariablePointerValue(obj) <> Null
			Local varPtr:VariablePointerValue = VariablePointerValue(obj)
			writer.WriteObjectStart()
			writer.WritePropertyName("^var")
			writer.WriteString(varPtr.value)
			If varPtr.contextIndex <> -1
				writer.WritePropertyName("ci")
				writer.WriteInt(varPtr.contextIndex)
			End
			writer.WriteObjectEnd()
		Else If Glue(obj) <> Null
			WriteGlue(writer, Glue(obj))
		Else If ControlCommand(obj) <> Null
			WriteControlCommand(writer, ControlCommand(obj))
		Else If NativeFunctionCall(obj) <> Null
			WriteNativeFunctionCall(writer, NativeFunctionCall(obj))
		Else If VariableReference(obj) <> Null
			WriteVariableReference(writer, VariableReference(obj))
		Else If VariableAssignment(obj) <> Null
			WriteVariableAssignment(writer, VariableAssignment(obj))
		Else If Void(obj) <> Null
			WriteVoid(writer)
		Else If Tag(obj) <> Null
			WriteTag(writer, Tag(obj))
		Else If Choice(obj) <> Null
			WriteChoice(writer, Choice(obj)) ' Note: Only used for save state, not compilation
		Else
			Error("Failed to write runtime object: Usually means there's something missing from the list above: " + obj)
		End
	End

	' Converts a JSON token (JsonValue) into the appropriate RuntimeObject type.
	Method JTokenToRuntimeObject:RuntimeObject(token:JsonValue, storyContext:Story=Null) ' storyContext unused for now
		' Basic JSON types
		If token.IsString()
			Return New StringValue(token.AsString())
		End
		If token.IsNumber()
			Local numStr:String = token.ToString()
			If numStr.Contains(".") Or numStr.Contains("e") Or numStr.Contains("E")
				Return New FloatValue(token.AsFloat())
			Else
				Return New IntValue(token.AsInt())
			End
		End
		If token.IsBool()
			Return New BoolValue(token.AsBool())
		End
		If token.IsNull()
			Return Null
		End

		' JSON object (dictionary)
		If token.IsObject()
			Local obj:JsonObject = token.AsObject()
			Local propValue:JsonValue

			' Divert target value: { "^->": "path.target" }
			If obj.TryGetItem("^->", propValue)
				Return New DivertTargetValue(New Path(propValue.AsString()))
			End

			' Variable pointer value: { "^var": "varname", "ci": 0 }
			If obj.TryGetItem("^var", propValue)
				Local varPtr:VariablePointerValue = New VariablePointerValue(propValue.AsString())
				If obj.TryGetItem("ci", propValue)
					varPtr.contextIndex = propValue.AsInt()
				End
				Return varPtr
			End

			' Divert: { "->": "path.target", "c": true }
			If obj.TryGetItem("->", propValue)
				Local divert:Divert = New Divert()
				divert.targetPathString = propValue.AsString()
				If obj.TryGetItem("var", propValue)
					divert.variableDivertName = propValue.AsString()
				End
				If obj.TryGetItem("c", propValue)
					divert.isConditional = propValue.AsBool()
				End
				If obj.TryGetItem("f", propValue) ' External function call arguments flag
					divert.externalArgs = propValue.AsInt()
				End
				Return divert
			End

			' Choice Point: { "*": "path.target", "flg": # }
			If obj.TryGetItem("*", propValue)
				Local choicePoint:ChoicePoint = New ChoicePoint()
				choicePoint.pathStringOnChoice = propValue.AsString()
				If obj.TryGetItem("flg", propValue)
					choicePoint.flags = propValue.AsInt()
				End
				Return choicePoint
			End

			' Variable Reference: { "VAR?": "varname" } or { "CNT?": "path.target" }
			If obj.TryGetItem("VAR?", propValue)
				Return New VariableReference(propValue.AsString())
			End
			If obj.TryGetItem("CNT?", propValue)
				Local readCountVarRef:VariableReference = New VariableReference()
				readCountVarRef.pathStringForCount = propValue.AsString()
				Return readCountVarRef
			End

			' Variable Assignment: { "VAR=": "varname", "re": true }
			If obj.TryGetItem("VAR=", propValue)
				Local varName:String = propValue.AsString()
				Local isNewDecl:Bool = False
				If obj.TryGetItem("re", propValue)
					isNewDecl = propValue.AsBool()
				End
				Return New VariableAssignment(varName, isNewDecl)
			End

			' Tag: { "#": "tag text" }
			If obj.TryGetItem("#", propValue)
				Return New Tag(propValue.AsString())
			End

			' List value: { "list": { "item.name": 1... } }
			If obj.TryGetItem("list", propValue)
				Local listContent:JsonObject = propValue.AsObject()
				Local rawList:InkList = New InkList()
				For Local nameToVal:= Eachin listContent
					Local item:InkListItem
					Local nameParts:String[] = nameToVal.Key.Split(".")
					If nameParts.Length >= 2
						item = New InkListItem(nameParts[0], nameParts[1])
					Else ' Origin name only
						item = New InkListItem(nameParts[0])
					End
					Local val:Int = nameToVal.Value.AsInt()
					rawList.Add(item, val)
				Next
				Return New ListValue(rawList)
			End

			' Glue: { "G<": 0 }, { "G>": 0 }, { "G=": 0 }
			If obj.ContainsKey("G<") Return New Glue(Glue.GlueType.Left)
			If obj.ContainsKey("G>") Return New Glue(Glue.GlueType.Right)
			If obj.ContainsKey("G=") Return New Glue(Glue.GlueType.Bidirectional)

			' Void: { "void": 0 }
			If obj.ContainsKey("void") Return New Void()

			' Native function call: { "^": "+" }
			If obj.TryGetItem("^", propValue)
				Return NativeFunctionCall.CallWithName(propValue.AsString())
			End

			' Control commands (check based on predefined names)
			For Local i:Int = 0 Until _controlCommandNames.Length
				Local cmdName:String = _controlCommandNames[i]
				If cmdName <> Null And obj.ContainsKey(cmdName)
					Return New ControlCommand(i)
				End
			Next

			' If no specific key matches, it's an unknown object type
			Error("Failed to parse json object: " + token.ToJson())
		End

		' JSON array
		If token.IsArray()
			Local jArray:JsonArray = token.AsArray()

			' Empty array = empty container
			If jArray.Length = 0
				Return New Container()
			End

			' The array is a container construct
			Local container:Container = New Container()
			For Local i:Int = 0 Until jArray.Length - 1 ' Iterate through content
				Local element:RuntimeObject = JTokenToRuntimeObject(jArray[i], storyContext)
				If element <> Null
					container.AddContent(element)
				End
			Next

			' Last element is the terminator (null or dictionary)
			Local terminator:JsonValue = jArray[jArray.Length - 1]
			If Not terminator.IsNull()
				Local terminatorObj:JsonObject = terminator.AsObject()
				For Local key:String = Eachin terminatorObj.Keys
					If key = "#f" ' Container flags
						container.countFlags = terminatorObj.GetItem(key).AsInt()
					Else If key = "#n" ' Container name
						container.name = terminatorObj.GetItem(key).AsString()
					Else ' Named content (nested container)
						Local namedContainer:Container = Container(JTokenToRuntimeObject(terminatorObj.GetItem(key)))
						' Check if it's actually a container
						If namedContainer = Null
							Error("Missing value for named content: " + key)
						Else
							container.AddToNamedContent(key, namedContainer)
						End
					End
				Next
			End
			Return container
		End

		Error("Failed to convert token to runtime object: " + token.ToJson())
		Return Null ' Should not reach here
	End

	' Writes a Container to JSON format.
	Method WriteRuntimeContainer:Void(writer:SimpleJsonWriter, container:Container, withoutName:Bool=False)
		writer.WriteArrayStart()
		' Write main content
		For Local c:RuntimeObject = Eachin container.content
			WriteRuntimeObject(writer, c)
		Next

		' Write terminator object if needed (contains named content, flags, name)
		Local hasTerminator:Bool = container.namedOnlyContent <> Null Or
								   container.countFlags > 0 Or
								   (container.name <> Null And Not withoutName)

		If hasTerminator
			writer.WriteObjectStart()
			' Write named content (nested containers)
			If container.namedOnlyContent <> Null
				For Local keyValue:= Eachin container.namedOnlyContent
					writer.WritePropertyName(keyValue.Key)
					WriteRuntimeContainer(writer, keyValue.Value, True) ' Name is already known
				Next
			End
			' Write count flags
			If container.countFlags > 0
				writer.WritePropertyName("#f")
				writer.WriteInt(container.countFlags)
			End
			' Write container name
			If container.name <> Null And Not withoutName
				writer.WritePropertyName("#n")
				writer.WriteString(container.name)
			End
			writer.WriteObjectEnd()
		Else
			' If no terminator needed, write null as the last element
			writer.WriteNull()
		End
		writer.WriteArrayEnd()
	End

	' Writes a Divert object to JSON.
	Method WriteDivert:Void(writer:SimpleJsonWriter, divert:Divert)
		writer.WriteObjectStart()
		writer.WritePropertyName("->")
		writer.WriteString(If divert.targetPathString <> Null Then divert.targetPathString Else "") ' Target path or empty string

		If divert.isConditional
			writer.WritePropertyName("c")
			writer.WriteBool(True)
		End
		If divert.externalArgs > 0
			writer.WritePropertyName("externalArgs")
			writer.WriteInt(divert.externalArgs)
		End
		If divert.variableDivertName <> Null
			writer.WritePropertyName("var")
			writer.WriteString(divert.variableDivertName)
		End
		writer.WriteObjectEnd()
	End

	' Writes a ControlCommand object to JSON using its mapped name.
	Method WriteControlCommand:Void(writer:SimpleJsonWriter, command:ControlCommand)
		writer.WriteObjectStart()
		writer.WritePropertyName(_controlCommandNames[command.commandType])
		writer.WriteInt(0) ' Value is always 0 for control commands
		writer.WriteObjectEnd()
	End

	' Writes a Glue object to JSON.
	Method WriteGlue:Void(writer:SimpleJsonWriter, glue:Glue)
		writer.WriteObjectStart()
		Select glue.glueType
			Case Glue.GlueType.Left
				writer.WritePropertyName("G<")
			Case Glue.GlueType.Right
				writer.WritePropertyName("G>")
			Case Glue.GlueType.Bidirectional
				writer.WritePropertyName("G=")
		End
		writer.WriteInt(0) ' Value is always 0 for glue
		writer.WriteObjectEnd()
	End

	' Writes a Choice object to JSON (used in save state).
	Method WriteChoice:Void(writer:SimpleJsonWriter, choice:Choice)
		writer.WriteObjectStart()
		writer.WritePropertyName("text")
		writer.WriteString(choice.text)
		writer.WritePropertyName("index")
		writer.WriteInt(choice.index)
		If choice.sourcePath <> Null
			writer.WritePropertyName("originalThread")
			writer.WriteString(choice.sourcePath.ToString())
		End
		If choice.targetPath <> Null
			writer.WritePropertyName("->")
			writer.WriteString(choice.targetPath.ToString())
		End
		writer.WriteObjectEnd()
	End

	' Writes a ChoicePoint object to JSON.
	Method WriteChoicePoint:Void(writer:SimpleJsonWriter, choicePoint:ChoicePoint)
		writer.WriteObjectStart()
		writer.WritePropertyName("*")
		writer.WriteString(choicePoint.pathStringOnChoice)
		writer.WritePropertyName("flg")
		writer.WriteInt(choicePoint.flags)
		writer.WriteObjectEnd()
	End

	' Writes a VariableReference object to JSON.
	Method WriteVariableReference:Void(writer:SimpleJsonWriter, varRef:VariableReference)
		writer.WriteObjectStart()
		If varRef.pathStringForCount <> Null
			writer.WritePropertyName("CNT?")
			writer.WriteString(varRef.pathStringForCount)
		Else
			writer.WritePropertyName("VAR?")
			writer.WriteString(varRef.name)
		End
		writer.WriteObjectEnd()
	End

	' Writes a VariableAssignment object to JSON.
	Method WriteVariableAssignment:Void(writer:SimpleJsonWriter, varAssign:VariableAssignment)
		writer.WriteObjectStart()
		writer.WritePropertyName("VAR=")
		writer.WriteString(varAssign.variableName)
		' Only write 're' if it's true (new declaration)
		If varAssign.isNewDeclaration
			writer.WritePropertyName("re")
			writer.WriteBool(True)
		End
		writer.WriteObjectEnd()
	End

	' Writes a NativeFunctionCall object to JSON.
	Method WriteNativeFunctionCall:Void(writer:SimpleJsonWriter, func:NativeFunctionCall)
		writer.WriteObjectStart()
		writer.WritePropertyName("^")
		writer.WriteString(func.name)
		writer.WriteObjectEnd()
	End

	' Writes a Tag object to JSON.
	Method WriteTag:Void(writer:SimpleJsonWriter, tag:Tag)
		writer.WriteObjectStart()
		writer.WritePropertyName("#")
		writer.WriteString(tag.text)
		writer.WriteObjectEnd()
	End

	' Writes an InkList (ListValue's content) to JSON.
	Method WriteInkList:Void(writer:SimpleJsonWriter, list:InkList)
		writer.WriteObjectStart()
		writer.WritePropertyName("list")
		writer.WriteObjectStart()
		For Local itemAndValue:= Eachin list
			Local item:InkListItem = itemAndValue.Key
			Local value:Int = itemAndValue.Value

			Local itemOriginName:String = item.originName
			If itemOriginName = Null
				itemOriginName = "?" ' Use "?" for unknown origin
			End
			Local fullItemName:String = itemOriginName + "." + item.itemName

			writer.WritePropertyName(fullItemName)
			writer.WriteInt(value)
		Next
		writer.WriteObjectEnd()
		writer.WriteObjectEnd()
	End

	' Writes a Void object to JSON.
	Method WriteVoid:Void(writer:SimpleJsonWriter)
		writer.WriteObjectStart()
		writer.WritePropertyName("void")
		writer.WriteInt(0)
		writer.WriteObjectEnd()
	End
End

' Helper class for writing JSON data with proper formatting and state tracking.
Class SimpleJsonWriter
	Field _writer:StringWriter = New StringWriter()
	Field _stateStack:Stack<Int> = New Stack<Int>() ' Tracks whether we are in an object or array
	Field _currentState:Int = State.None ' Current state (Object or Array)
	Field _beforeFirstElementStack:Stack<Bool> = New Stack<Bool>() ' Tracks if the first element in the current context has been written
	Field _beforeFirstElement:Bool = True ' Is the next element the first in the current context?

	' Indentation
	Field _indentLevel:Int = 0
	Field _prettyPrint:Bool = False
	Field _indentString:String = "    " ' Using 4 spaces as indent string

	' State constants
	Const State:{None:Int=0, Object:Int=1, Array:Int=2}

	' Constructor
	Method New(prettyPrint:Bool = False)
		_prettyPrint = prettyPrint
		If _prettyPrint
			_indentString = "	" ' Use tab for pretty printing if requested
		End
		_stateStack.Push(State.None) ' Start in no context
		_beforeFirstElementStack.Push(True)
	End

	' Returns the generated JSON string.
	Method ToString:String() Override
		Return _writer.ToString()
	End

	' Starts writing a JSON object '{'.
	Method WriteObjectStart:Void()
		HandleBeforeWrite()
		_writer.Write("{")
		PushState(State.Object)
		_indentLevel += 1
		If _prettyPrint
			_writer.Write("~n")
		End
	End

	' Ends writing a JSON object '}'.
	Method WriteObjectEnd:Void()
		_indentLevel -= 1
		If _prettyPrint And Not _beforeFirstElement ' Only newline if object wasn't empty
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("}")
		PopState()
	End

	' Starts writing a JSON array '['.
	Method WriteArrayStart:Void()
		HandleBeforeWrite()
		_writer.Write("[")
		PushState(State.Array)
		_indentLevel += 1
		If _prettyPrint
			_writer.Write("~n")
		End
	End

	' Ends writing a JSON array ']'.
	Method WriteArrayEnd:Void()
		_indentLevel -= 1
		If _prettyPrint And Not _beforeFirstElement ' Only newline if array wasn't empty
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("]")
		PopState()
	End

	' Writes a property name (key) in a JSON object.
	Method WritePropertyName:Void(name:String)
		HandleBeforeWrite()
		WriteIndent()
		_writer.Write("~q" + EscapeString(name) + "~q:")
		If _prettyPrint
			_writer.Write(" ") ' Space after colon in pretty print
		Else
			_writer.Write("") ' No space otherwise
		End
		_beforeFirstElement = True ' The value following the property name is the first 'element' in this sub-context
	End

	' Writes a null value.
	Method WriteNull:Void()
		HandleBeforeWrite()
		WriteIndent()
		_writer.Write("null")
	End

	' Writes an integer value.
	Method WriteInt:Void(value:Int)
		HandleBeforeWrite()
		WriteIndent()
		_writer.Write(String(value))
	End

	' Writes a float value.
	Method WriteFloat:Void(value:Float)
		HandleBeforeWrite()
		WriteIndent()
		' Ensure consistent float representation (e.g., always include decimal point)
		Local floatStr:String = String(value)
		If Not floatStr.Contains(".") And Not floatStr.Contains("e") And Not floatStr.Contains("E")
			floatStr += ".0"
		End
		_writer.Write(floatStr)
	End

	' Writes a string value, correctly escaped.
	Method WriteString:Void(value:String)
		HandleBeforeWrite()
		WriteIndent()
		_writer.Write("~q" + EscapeString(value) + "~q")
	End

	' Writes a boolean value.
	Method WriteBool:Void(value:Bool)
		HandleBeforeWrite()
		WriteIndent()
		_writer.Write(If value Then "true" Else "false")
	End

	' Internal: Pushes the current state onto the stack and sets the new state.
	Method PushState:Void(state:Int)
		_stateStack.Push(_currentState)
		_currentState = state
		_beforeFirstElementStack.Push(_beforeFirstElement)
		_beforeFirstElement = True ' Reset for the new context
	End

	' Internal: Pops the state from the stack, restoring the previous state.
	Method PopState:Void()
		_currentState = _stateStack.Pop()
		_beforeFirstElement = _beforeFirstElementStack.Pop()
		' After closing an object/array, the next element will require a comma if it's not the first.
		_beforeFirstElement = False
	End

	' Internal: Handles comma placement and indentation before writing any value or structure.
	Method HandleBeforeWrite:Void()
		If _currentState = State.Array Or _currentState = State.Object
			If Not _beforeFirstElement
				_writer.Write(",")
				If _prettyPrint
					_writer.Write("~n")
				End
			End
			_beforeFirstElement = False
		End
	End

	' Internal: Writes the current indentation string.
	Method WriteIndent:Void()
		If _prettyPrint
			For Local i:Int = 0 Until _indentLevel
				_writer.Write(_indentString)
			Next
		End
	End

	' Internal: Escapes special characters in a string for JSON compatibility.
	Method EscapeString:String(str:String)
		Local result:String = ""
		For Local i:Int = 0 Until str.Length
			Local c:String = str[i..i+1]
			Select c
				Case "~q"
					result += "\\~q"
				Case "\"
					result += "\\\\"
				Case "~n"
					result += "\\n"
				Case "~r"
					result += "\\r"
				Case "~t"
					result += "\\t"
				' Handle other control characters if necessary (e.g., U+0000 to U+001F)
				' For simplicity, we'll assume standard printable characters + common escapes
				Default
					result += c
			End
		Next
		Return result
	End
End
