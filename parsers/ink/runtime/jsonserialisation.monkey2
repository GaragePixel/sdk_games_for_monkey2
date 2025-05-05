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

' Static class for JSON serialization
Class JsonSerialisation
	' Control command name lookup for serialization
	Field _controlCommandNames:String[]
	
	' Constructor initializes control command names
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
		_controlCommandNames[ControlCommand.CommandType.End] = "end"
		_controlCommandNames[ControlCommand.CommandType.ListFromInt] = "listInt"
		_controlCommandNames[ControlCommand.CommandType.ListRange] = "range"
		_controlCommandNames[ControlCommand.CommandType.ListRandom] = "lrnd"
		_controlCommandNames[ControlCommand.CommandType.BeginTag] = "#"
		_controlCommandNames[ControlCommand.CommandType.EndTag] = "/#"
		
		' Verify all commands have names
		For Local i:Int = 0 Until ControlCommand.CommandType.TOTAL_VALUES
			If _controlCommandNames[i] = Null
				Error("Control command not accounted for in serialization: " + i)
			End
		Next
	End
	
	' Convert a JSON array to a list of runtime objects
	Method JArrayToRuntimeObjList:List<RuntimeObject>(jArray:JsonArray, skipLast:Bool = False)
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
	
	' Write a list of runtime objects to JSON
	Method WriteListRuntimeObjs:Void(writer:SimpleJsonWriter, list:List<RuntimeObject>)
		writer.WriteArrayStart()
		
		For Local obj:RuntimeObject = Eachin list
			WriteRuntimeObject(writer, obj)
		Next
		
		writer.WriteArrayEnd()
	End
	
	' Write a dictionary of runtime objects to JSON
	Method WriteDictionaryRuntimeObjs:Void(writer:SimpleJsonWriter, dictionary:StringMap<RuntimeObject>)
		writer.WriteObjectStart()
		
		For Local keyVal:= Eachin dictionary
			writer.WritePropertyName(keyVal.Key)
			WriteRuntimeObject(writer, keyVal.Value)
		Next
		
		writer.WriteObjectEnd()
	End
	
	' Write an int dictionary to JSON
	Method WriteIntDictionary:Void(writer:SimpleJsonWriter, dictionary:StringMap<Int>)
		writer.WriteObjectStart()
		
		For Local keyVal:= Eachin dictionary
			writer.WritePropertyName(keyVal.Key)
			writer.WriteIntValue(keyVal.Value)
		Next
		
		writer.WriteObjectEnd()
	End
	
	' Convert a JSON token to a runtime object
	Method JTokenToRuntimeObject:RuntimeObject(token:JsonValue, storyContext:Story = Null)
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
			
			' Divert target value
			If obj.Contains("^->")
				Return New DivertTargetValue(New Path(obj.GetItem("^->").AsString()))
			End
			
			' Variable pointer value
			If obj.Contains("^var")
				Local varPtr:VariablePointerValue = New VariablePointerValue(obj.GetItem("^var").AsString())
				If obj.Contains("ci")
					varPtr.contextIndex = obj.GetItem("ci").AsInt()
				End
				Return varPtr
			End
			
			' Divert
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
					Local externalArgs:Int = obj.GetItem("f").AsInt()
					divert.externalArgs = externalArgs
				End
				
				Return divert
			End
			
			' Choice point
			If obj.Contains("*")
				Local choice:ChoicePoint = New ChoicePoint()
				choice.pathStringOnChoice = obj.GetItem("*").AsString()
				
				If obj.Contains("flg")
					choice.flags = obj.GetItem("flg").AsInt()
				End
				
				Return choice
			End
			
			' Variable reference
			If obj.Contains("VAR?")
				Return New VariableReference(obj.GetItem("VAR?").AsString())
			End
			
			' Variable assignment
			If obj.Contains("VAR=")
				Local varName:String = obj.GetItem("VAR=").AsString()
				Local isNewDecl:Bool = False
				If obj.Contains("re")
					isNewDecl = obj.GetItem("re").AsBool()
				End
				Return New VariableAssignment(varName, isNewDecl)
			End
			
			' Tag
			If obj.Contains("#")
				Return New Tag(obj.GetItem("#").AsString())
			End
			
			' List value
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
			
			' Glue
			If obj.Contains("G<") Return New Glue(Glue.GlueType.Left)
			If obj.Contains("G>") Return New Glue(Glue.GlueType.Right)
			If obj.Contains("G=") Return New Glue(Glue.GlueType.Bidirectional)
			
			' Void
			If obj.Contains("void")
				Return New Void()
			End
			
			' Native function
			If obj.Contains("^")
				Local name:String = obj.GetItem("^").AsString()
				Return NativeFunctionCall.CallWithName(name)
			End
			
			' Control commands - check for each possible command
			For Local i:Int = 0 Until ControlCommand.CommandType.TOTAL_VALUES
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
			
			' Convert content array
			Local container:Container = New Container()
			
			For Local i:Int = 0 Until array.Length - 1
				Local obj:RuntimeObject = JTokenToRuntimeObject(array.GetItem(i), storyContext)
				If obj <> Null
					container.AddContent(obj)
				End
			Next
			
			' Final object is either null terminator or a dictionary of named content
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
	
	' Write a runtime object to JSON
	Method WriteRuntimeObject:Void(writer:SimpleJsonWriter, obj:Object)
		If obj = Null
			writer.WriteNull()
		Else If StringValue(obj) <> Null
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
	
	' Write a runtime container to JSON
	Method WriteRuntimeContainer:Void(writer:SimpleJsonWriter, container:Container, withoutName:Bool = False)
		writer.WriteArrayStart()
		
		For Local content:RuntimeObject = Eachin container.content
			WriteRuntimeObject(writer, content)
		Next
		
		Local hasTerminator:Bool = container.namedOnlyContent <> Null Or 
			container.countFlags > 0 Or 
			(container.name <> Null And Not withoutName)
		
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
	
	' Write a divert object to JSON
	Method WriteDivert:Void(writer:SimpleJsonWriter, divert:Divert)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("->")
		writer.WriteString(divert.targetPathString)
		
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
	
	' Write a control command to JSON
	Method WriteControlCommand:Void(writer:SimpleJsonWriter, command:ControlCommand)
		Local commandName:String = _controlCommandNames[command.commandType]
		
		writer.WriteObjectStart()
		writer.WritePropertyName(commandName)
		writer.WriteInt(0)
		writer.WriteObjectEnd()
	End
	
	' Write a glue object to JSON
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
		
		writer.WriteInt(0)
		writer.WriteObjectEnd()
	End
	
	' Write a choice object to JSON
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
	
	' Write a choice point to JSON
	Method WriteChoicePoint:Void(writer:SimpleJsonWriter, choicePoint:ChoicePoint)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("*")
		writer.WriteString(choicePoint.pathStringOnChoice)
		
		writer.WritePropertyName("flg")
		writer.WriteInt(choicePoint.flags)
		
		writer.WriteObjectEnd()
	End
	
	' Write a variable reference to JSON
	Method WriteVariableReference:Void(writer:SimpleJsonWriter, variableRef:VariableReference)
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
	
	' Write a variable assignment to JSON
	Method WriteVariableAssignment:Void(writer:SimpleJsonWriter, variableAssignment:VariableAssignment)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("VAR=")
		writer.WriteString(variableAssignment.variableName)
		
		If variableAssignment.isNewDeclaration
			writer.WritePropertyName("re")
			writer.WriteBool(True)
		End
		
		writer.WriteObjectEnd()
	End
	
	' Write a native function call to JSON
	Method WriteNativeFunctionCall:Void(writer:SimpleJsonWriter, nativeFunc:NativeFunctionCall)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("^")
		writer.WriteString(nativeFunc.name)
		
		writer.WriteObjectEnd()
	End
	
	' Write a tag to JSON
	Method WriteTag:Void(writer:SimpleJsonWriter, tag:Tag)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("#")
		writer.WriteString(tag.text)
		
		writer.WriteObjectEnd()
	End
	
	' Write an Ink list to JSON
	Method WriteInkList:Void(writer:SimpleJsonWriter, list:InkList)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("list")
		
		writer.WriteObjectStart()
		
		For Local itemAndValue:= Eachin list
			Local item:InkListItem = itemAndValue.Key
			Local value:Int = itemAndValue.Value
			
			Local itemName:String = item.originName
			If itemName = Null
				itemName = "?"
			End
			
			Local fullItemName:String = itemName + "." + item.itemName
			
			writer.WritePropertyName(fullItemName)
			writer.WriteInt(value)
		Next
		
		writer.WriteObjectEnd()
		
		writer.WriteObjectEnd()
	End
End

' SimpleJsonWriter for writing JSON data
Class SimpleJsonWriter
	' The underlying StringWriter for output
	Field _writer:StringWriter = New StringWriter()
	
	' Track state for proper comma placement
	Field _stateStack:Stack<Int> = New Stack<Int>()
	Field _currentState:Int
	
	' Constants for state tracking
	Const _inObject:Int = 1
	Const _inArray:Int = 2
	
	' Indentation management
	Field _currentIndentation:Int = 0
	Field _prettyPrint:Bool = False
	
	' Writer creation with optional pretty printing
	Method New(prettyPrint:Bool = False)
		_prettyPrint = prettyPrint
	End
	
	' Generate the JSON string
	Method ToString:String() Override
		Return _writer.ToString()
	End

	' Objects
	Method WriteObjectStart:Void()
		WriteComma()
		_writer.Write("{")
		
		PushState(_inObject)
		_currentIndentation += 1
		WriteNewlineAndIndent()
	End
	
	Method WriteObjectEnd:Void()
		_currentIndentation -= 1
		WriteNewlineAndIndent()
		_writer.Write("}")
		
		PopState()
	End
	
	' Arrays
	Method WriteArrayStart:Void()
		WriteComma()
		_writer.Write("[")
		
		PushState(_inArray)
		_currentIndentation += 1
		WriteNewlineAndIndent()
	End
	
	Method WriteArrayEnd:Void()
		_currentIndentation -= 1
		WriteNewlineAndIndent()
		_writer.Write("]")
		
		PopState()
	End
	
	' Properties
	Method WritePropertyName:Void(name:String)
		WriteComma()
		WriteNewlineAndIndent()
		
		_writer.Write("~q" + EscapeString(name) + "~q:")
		If _prettyPrint
			_writer.Write(" ")
		End
		
		_inPreviousItemField = True
	End
	
	' Values
	Method WriteNull:Void()
		WriteComma()
		WriteNewlineAndIndent()
		_writer.Write("null")
		_inPreviousItemField = False
	End
	
	Method WriteInt:Void(val:Int)
		WriteComma()
		WriteNewlineAndIndent()
		_writer.Write(String(val))
		_inPreviousItemField = False
	End
	
	Method WriteFloat:Void(val:Float)
		WriteComma()
		WriteNewlineAndIndent()
		_writer.Write(String(val))
		_inPreviousItemField = False
	End
	
	Method WriteString:Void(val:String)
		WriteComma()
		WriteNewlineAndIndent()
		_writer.Write("~q" + EscapeString(val) + "~q")
		_inPreviousItemField = False
	End
	
	Method WriteBool:Void(val:Bool)
		WriteComma()
		WriteNewlineAndIndent()
		_writer.Write(val ? "true" : "false")
		_inPreviousItemField = False
	End
	
	' Internal helper for state tracking
	Method PushState:Void(state:Int)
		_stateStack.Push(_currentState)
		_currentState = state
		_inPreviousItemField = False
	End
	
	Method PopState:Void()
		_currentState = _stateStack.Pop()
	End
	
	' Internal helpers for formatting and commas
	Field _inPreviousItemField:Bool = False
	
	Method WriteComma:Void()
		If _inPreviousItemField
			_writer.Write(",")
		End
	End
	
	Method WriteNewlineAndIndent:Void()
		If _prettyPrint
			_writer.Write("~n")
			For Local i:Int = 0 Until _currentIndentation
				_writer.Write("    ")
			Next
		End
	End
	
	' Escape special characters in strings
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
