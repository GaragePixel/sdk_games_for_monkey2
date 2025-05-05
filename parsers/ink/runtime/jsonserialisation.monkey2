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

Class JsonSerialisation

	Field _controlCommandNames:String[]

	Method New()
		_controlCommandNames = New String[ControlCommand.CommandType.TOTAL_VALUES]
		_controlCommandNames[ControlCommand.CommandType.EvalStart] = "ev"
		_controlCommandNames[ControlCommand.CommandType.EvalOutput] = "out"
		_controlCommandNames[ControlCommand.CommandType.EvalEnd] = "/ev"
		_controlCommandNames[ControlCommand.CommandType.Duplicate] = "du"
		_controlCommandNames[ControlCommand.CommandType.PopEvaluatedValue] = "pop"
		_controlCommandNames[ControlCommand.CommandType.PopFunction] = "~ret"
		_controlCommandNames[ControlCommand.CommandType.PopTunnel] = "->->"
		_controlCommandNames[ControlCommand.CommandType.BeginString] = "str"
		_controlCommandNames[ControlCommand.CommandType.EndString] = "/str"
		_controlCommandNames[ControlCommand.CommandType.NoOp] = "nop"
		_controlCommandNames[ControlCommand.CommandType.ChoiceCount] = "choiceCnt"
		_controlCommandNames[ControlCommand.CommandType.Turns] = "turn"
		_controlCommandNames[ControlCommand.CommandType.TurnsSince] = "turns"
		_controlCommandNames[ControlCommand.CommandType.ReadCount] = "readc"
		_controlCommandNames[ControlCommand.CommandType.Random] = "rnd"
		_controlCommandNames[ControlCommand.CommandType.SeedRandom] = "srnd"
		_controlCommandNames[ControlCommand.CommandType.VisitIndex] = "visit"
		_controlCommandNames[ControlCommand.CommandType.SequenceShuffleIndex] = "seq"
		_controlCommandNames[ControlCommand.CommandType.StartThread] = "thread"
		_controlCommandNames[ControlCommand.CommandType.Done] = "done"
		_controlCommandNames[ControlCommand.CommandType.Ends] = "end"
		_controlCommandNames[ControlCommand.CommandType.ListFromInt] = "listInt"
		_controlCommandNames[ControlCommand.CommandType.ListRange] = "range"
		_controlCommandNames[ControlCommand.CommandType.ListRandom] = "lrnd"
		_controlCommandNames[ControlCommand.CommandType.BeginTag] = "#"
		_controlCommandNames[ControlCommand.CommandType.EndTag] = "/#"

		For Local i:Int = 0 Until ControlCommand.CommandType.TOTAL_VALUES
			If _controlCommandNames[i] = Null
				Error("Control command not accounted for in serialization: " + i)
			End
		Next
	End

	Function JArrayToRuntimeObjList:List<RuntimeObject>(jArray:JsonArray, skipLast:Bool = False)
		Local count:Int = jArray.Length
		If skipLast
			count -= 1
		End
		Local list:List<RuntimeObject> = New List<RuntimeObject>()
		For Local i:Int = 0 Until count
			Local obj:RuntimeObject = JTokenToRuntimeObject(jArray.GetItem(i))
			list.AddLast(obj)
		Next
		Return list
	End

	Function WriteDictionaryRuntimeObjs:Void(writer:SimpleJsonWriter, dictionary:StringMap<RuntimeObject>)
		writer.WriteObjectStart()
		For Local keyVal:= Eachin dictionary
			writer.WritePropertyName(keyVal.Key)
			WriteRuntimeObject(writer, keyVal.Value)
		Next
		writer.WriteObjectEnd()
	End

	Function WriteListRuntimeObjs:Void(writer:SimpleJsonWriter, list:List<RuntimeObject>)
		writer.WriteArrayStart()
		For Local obj:RuntimeObject = Eachin list
			WriteRuntimeObject(writer, obj)
		Next
		writer.WriteArrayEnd()
	End

	Function WriteIntDictionary:Void(writer:SimpleJsonWriter, dictionary:StringMap<Int>)
		writer.WriteObjectStart()
		For Local keyVal:= Eachin dictionary
			writer.WritePropertyName(keyVal.Key)
			writer.WriteInt(keyVal.Value)
		Next
		writer.WriteObjectEnd()
	End

	Function JTokenToRuntimeObject:RuntimeObject(token:JsonValue, storyContext:Story = Null)
		If token = Null
			Return Null
		End
		If token.IsString()
			Return New StringValue(token.AsString())
		End
		If token.IsNumber()
			Local numStr:String = token.ToString()
			If numStr.Contains(".")
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

		If token.IsObject()
			Local obj:JsonObject = token.AsObject()
			If obj.Contains("^->")
				Return New DivertTargetValue(New Path(obj.GetItem("^->").AsString()))
			End
			If obj.Contains("^var")
				Local varPtr:VariablePointerValue = New VariablePointerValue(obj.GetItem("^var").AsString())
				If obj.Contains("ci")
					varPtr.contextIndex = obj.GetItem("ci").AsInt()
				End
				Return varPtr
			End
			If obj.Contains("->")
				Local divert:Divert = New Divert()
				divert.targetPathString = obj.GetItem("->").AsString()
				If obj.Contains("var")
					divert.variableDivertName = obj.GetItem("var").AsString()
				End
				If obj.Contains("c")
					divert.isConditional = obj.GetItem("c").AsBool()
				End
				If obj.Contains("f")
					divert.externalArgs = obj.GetItem("f").AsInt()
				End
				Return divert
			End
			If obj.Contains("*")
				Local choicePoint:ChoicePoint = New ChoicePoint()
				choicePoint.pathStringOnChoice = obj.GetItem("*").AsString()
				If obj.Contains("flg")
					choicePoint.flags = obj.GetItem("flg").AsInt()
				End
				Return choicePoint
			End
			If obj.Contains("VAR?")
				Return New VariableReference(obj.GetItem("VAR?").AsString())
			End
			If obj.Contains("VAR=")
				Local varName:String = obj.GetItem("VAR=").AsString()
				Local isNewDecl:Bool = False
				If obj.Contains("re")
					isNewDecl = obj.GetItem("re").AsBool()
				End
				Return New VariableAssignment(varName, isNewDecl)
			End
			If obj.Contains("#")
				Return New Tag(obj.GetItem("#").AsString())
			End
			If obj.Contains("list")
				Local listContent:JsonObject = obj.GetItem("list").AsObject()
				Local rawList:InkList = New InkList()
				For Local nameToVal:= Eachin listContent
					Local item:InkListItem
					Local nameParts:String[] = nameToVal.Key.Split(".")
					If nameParts.Length >= 2
						item = New InkListItem(nameParts[0], nameParts[1])
					Else
						item = New InkListItem(nameParts[0])
					End
					Local val:Int = nameToVal.Value.AsInt()
					rawList.Add(item, val)
				Next
				Return New ListValue(rawList)
			End
			If obj.Contains("G<")
				Return New Glue(Glue.GlueType.Left)
			End
			If obj.Contains("G>")
				Return New Glue(Glue.GlueType.Right)
			End
			If obj.Contains("G=")
				Return New Glue(Glue.GlueType.Bidirectional)
			End
			If obj.Contains("void")
				Return New Void()
			End
			If obj.Contains("^")
				Local name:String = obj.GetItem("^").AsString()
				Return NativeFunctionCall.CallWithName(name)
			End
			For Local i:Int = 0 Until _controlCommandNames.Length
				Local cmdName:String = _controlCommandNames[i]
				If cmdName <> Null And obj.Contains(cmdName)
					Return New ControlCommand(i)
				End
			Next
			Error("Failed to parse token: " + token.ToString())
		End

		If token.IsArray()
			Local array:JsonArray = token.AsArray()
			If array.Length = 0
				Return New Container()
			End
			Local container:Container = New Container()
			For Local i:Int = 0 Until array.Length - 1
				Local obj:RuntimeObject = JTokenToRuntimeObject(array.GetItem(i), storyContext)
				If obj <> Null
					container.AddContent(obj)
				End
			Next
			Local terminatorObj:JsonValue = array.GetItem(array.Length - 1)
			If Not terminatorObj.IsNull()
				Local namedContentObj:JsonObject = terminatorObj.AsObject()
				For Local key:String = Eachin namedContentObj.Keys
					If key = "#f"
						container.countFlags = namedContentObj.GetItem(key).AsInt()
					Else If key = "#n"
						container.name = namedContentObj.GetItem(key).AsString()
					Else
						Local namedContainer:Container = Container(JTokenToRuntimeObject(namedContentObj.GetItem(key)))
						container.AddToNamedContent(key, namedContainer)
					End
				Next
			End
			Return container
		End
		Error("Unknown token type: " + token.ToString())
		Return Null
	End

	Function WriteRuntimeObject:Void(writer:SimpleJsonWriter, obj:Object)
		If obj = Null
			writer.WriteNull()
			Return
		End
		If StringValue(obj) <> Null
			writer.WriteString(StringValue(obj).value)
		Else If IntValue(obj) <> Null
			writer.WriteInt(IntValue(obj).value)
		Else If FloatValue(obj) <> Null
			writer.WriteFloat(FloatValue(obj).value)
		Else If BoolValue(obj) <> Null
			writer.WriteBool(BoolValue(obj).value)
		Else If ListValue(obj) <> Null
			WriteInkList(writer, ListValue(obj).value)
		Else If DivertTargetValue(obj) <> Null
			Local divTarget:DivertTargetValue = DivertTargetValue(obj)
			writer.WriteObjectStart()
			writer.WritePropertyName("^->")
			writer.WriteString(divTarget.value.ToString())
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
		Else If Void(obj) <> Null
			writer.WriteObjectStart()
			writer.WritePropertyName("void")
			writer.WriteInt(0)
			writer.WriteObjectEnd()
		Else If Divert(obj) <> Null
			WriteDivert(writer, Divert(obj))
		Else If ControlCommand(obj) <> Null
			WriteControlCommand(writer, ControlCommand(obj))
		Else If VariableReference(obj) <> Null
			WriteVariableReference(writer, VariableReference(obj))
		Else If VariableAssignment(obj) <> Null
			WriteVariableAssignment(writer, VariableAssignment(obj))
		Else If ChoicePoint(obj) <> Null
			WriteChoicePoint(writer, ChoicePoint(obj))
		Else If Container(obj) <> Null
			WriteRuntimeContainer(writer, Container(obj))
		Else If Glue(obj) <> Null
			WriteGlue(writer, Glue(obj))
		Else If Choice(obj) <> Null
			WriteChoice(writer, Choice(obj))
		Else If Tag(obj) <> Null
			WriteTag(writer, Tag(obj))
		Else If NativeFunctionCall(obj) <> Null
			WriteNativeFunctionCall(writer, NativeFunctionCall(obj))
		Else If String(obj) <> Null
			writer.WriteString(String(obj))
		Else If Int(obj) <> Null
			writer.WriteInt(Int(obj))
		Else If Float(obj) <> Null
			writer.WriteFloat(Float(obj))
		Else If Bool(obj) <> Null
			writer.WriteBool(Bool(obj))
		Else If InkList(obj) <> Null
			WriteInkList(writer, InkList(obj))
		Else
			Error("Failed to write object of type: " + obj.ToString())
		End
	End

	Function WriteRuntimeContainer:Void(writer:SimpleJsonWriter, container:Container, withoutName:Bool = False)
		writer.WriteArrayStart()
		For Local content:RuntimeObject = Eachin container.content
			WriteRuntimeObject(writer, content)
		Next
		Local hasTerminator:Bool = container.namedOnlyContent <> Null Or container.countFlags > 0 Or (container.name <> Null And Not withoutName)
		If hasTerminator
			writer.WriteObjectStart()
			If container.namedOnlyContent <> Null
				For Local namedContent:= Eachin container.namedOnlyContent
					writer.WritePropertyName(namedContent.Key)
					WriteRuntimeContainer(writer, namedContent.Value, True)
				Next
			End
			If container.countFlags > 0
				writer.WritePropertyName("#f")
				writer.WriteInt(container.countFlags)
			End
			If container.name <> Null And Not withoutName
				writer.WritePropertyName("#n")
				writer.WriteString(container.name)
			End
			writer.WriteObjectEnd()
		Else
			writer.WriteNull()
		End
		writer.WriteArrayEnd()
	End

	Function WriteDivert:Void(writer:SimpleJsonWriter, divert:Divert)
		writer.WriteObjectStart()
		writer.WritePropertyName("->")
		If divert.targetPathString <> Null
			writer.WriteString(divert.targetPathString)
		Else
			writer.WriteString("")
		End
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

	Function WriteControlCommand:Void(writer:SimpleJsonWriter, command:ControlCommand)
		writer.WriteObjectStart()
		writer.WritePropertyName(_controlCommandNames[command.commandType])
		writer.WriteInt(0)
		writer.WriteObjectEnd()
	End

	Function WriteGlue:Void(writer:SimpleJsonWriter, glue:Glue)
		writer.WriteObjectStart()
		Select glue.glueType
			Case Glue.GlueType.Left
				writer.WritePropertyName("G<")
			Case Glue.GlueType.Right
				writer.WritePropertyName("G>")
			Case Glue.GlueType.Bidirectional
				writer.WritePropertyName("G=")
		End
		writer.WriteInt(0)
		writer.WriteObjectEnd()
	End

	Function WriteChoice:Void(writer:SimpleJsonWriter, choice:Choice)
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

	Function WriteChoicePoint:Void(writer:SimpleJsonWriter, choicePoint:ChoicePoint)
		writer.WriteObjectStart()
		writer.WritePropertyName("*")
		writer.WriteString(choicePoint.pathStringOnChoice)
		writer.WritePropertyName("flg")
		writer.WriteInt(choicePoint.flags)
		writer.WriteObjectEnd()
	End

	Function WriteVariableReference:Void(writer:SimpleJsonWriter, variableRef:VariableReference)
		writer.WriteObjectStart()
		If variableRef.pathStringForCount <> Null
			writer.WritePropertyName("CNT?")
			writer.WriteString(variableRef.pathStringForCount)
		Else
			writer.WritePropertyName("VAR?")
			writer.WriteString(variableRef.name)
		End
		writer.WriteObjectEnd()
	End

	Function WriteVariableAssignment:Void(writer:SimpleJsonWriter, variableAssignment:VariableAssignment)
		writer.WriteObjectStart()
		writer.WritePropertyName("VAR=")
		writer.WriteString(variableAssignment.variableName)
		If variableAssignment.isNewDeclaration
			writer.WritePropertyName("re")
			writer.WriteBool(True)
		End
		writer.WriteObjectEnd()
	End

	Function WriteNativeFunctionCall:Void(writer:SimpleJsonWriter, nativeFunc:NativeFunctionCall)
		writer.WriteObjectStart()
		writer.WritePropertyName("^")
		writer.WriteString(nativeFunc.name)
		writer.WriteObjectEnd()
	End

	Function WriteTag:Void(writer:SimpleJsonWriter, tag:Tag)
		writer.WriteObjectStart()
		writer.WritePropertyName("#")
		writer.WriteString(tag.text)
		writer.WriteObjectEnd()
	End

	Function WriteInkList:Void(writer:SimpleJsonWriter, list:InkList)
		writer.WriteObjectStart()
		writer.WritePropertyName("list")
		writer.WriteObjectStart()
		For Local itemAndValue:= Eachin list
			Local item:InkListItem = itemAndValue.Key
			Local value:Int = itemAndValue.Value
			Local itemOriginName:String = item.originName
			If itemOriginName = Null
				itemOriginName = "?"
			End
			Local fullName:String = itemOriginName + "." + item.itemName
			writer.WritePropertyName(fullName)
			writer.WriteInt(value)
		Next
		writer.WriteObjectEnd()
		writer.WriteObjectEnd()
	End

End

Class SimpleJsonWriter
	Field _writer:StringWriter = New StringWriter()
	Field _stateStack:Stack<Int> = New Stack<Int>()
	Field _currentStateIndex:Int = -1
	Field _state:Int = 0
	Const STATE_NONE:Int = 0
	Const STATE_OBJECT:Int = 1
	Const STATE_ARRAY:Int = 2
	Field _commaRequired:Bool = False
	Field _indentLevel:Int = 0
	Field _prettyPrint:Bool = False

	Method New(prettyPrint:Bool = False)
		_prettyPrint = prettyPrint
		_stateStack.Push(STATE_NONE)
	End

	Method ToString:String() Override
		Return _writer.ToString()
	End

	Method WriteObjectStart:Void()
		WriteCommaIfNeeded()
		_writer.Write("{")
		PushState(STATE_OBJECT)
		_indentLevel += 1
		If _prettyPrint
			_writer.Write("~n")
		End
	End

	Method WriteObjectEnd:Void()
		_indentLevel -= 1
		If _prettyPrint
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("}")
		PopState()
	End

	Method WriteArrayStart:Void()
		WriteCommaIfNeeded()
		_writer.Write("[")
		PushState(STATE_ARRAY)
		_indentLevel += 1
		If _prettyPrint
			_writer.Write("~n")
		End
	End

	Method WriteArrayEnd:Void()
		_indentLevel -= 1
		If _prettyPrint
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("]")
		PopState()
	End

	Method WritePropertyName:Void(name:String)
		WriteCommaIfNeeded()
		If _prettyPrint
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("~q" + EscapeString(name) + "~q:")
		If _prettyPrint
			_writer.Write(" ")
		End
		_commaRequired = False
	End

	Method WriteNull:Void()
		WriteCommaIfNeeded()
		_writer.Write("null")
	End

	Method WriteInt:Void(value:Int)
		WriteCommaIfNeeded()
		_writer.Write(String(value))
	End

	Method WriteFloat:Void(value:Float)
		WriteCommaIfNeeded()
		_writer.Write(String(value))
	End

	Method WriteString:Void(value:String)
		WriteCommaIfNeeded()
		_writer.Write("~q" + EscapeString(value) + "~q")
	End

	Method WriteBool:Void(value:Bool)
		WriteCommaIfNeeded()
		_writer.Write(value ? "true" : "false")
	End

	Method PushState:Void(state:Int)
		_stateStack.Push(state)
		_state = state
		_commaRequired = False
	End

	Method PopState:Void()
		_stateStack.Pop()
		_state = _stateStack.Top()
		_commaRequired = True
	End

	Method WriteCommaIfNeeded:Void()
		If _commaRequired
			_writer.Write(",")
		Else
			_commaRequired = True
		End
	End

	Method WriteIndent:Void()
		For Local i:Int = 0 Until _indentLevel
			_writer.Write("	")
		Next
	End

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
				Default
					result += c
			End
		Next
		Return result
	End
End
