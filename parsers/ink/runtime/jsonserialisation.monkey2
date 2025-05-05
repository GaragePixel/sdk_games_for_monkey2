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

Namespace sdk_games.parsers.ink

' Static class for handling JSON serialization of Ink runtime objects
Class JsonSerialisation
	' Map of control command types to their string representation in JSON
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
		
		' Verify all commands are accounted for
		For Local i:Int = 0 Until ControlCommand.CommandType.TOTAL_VALUES
			If _controlCommandNames[i] = Null
				Error("Control command not accounted for in serialization: " + i)
			End
		Next
	End
	
	' Convert JSON token to runtime object
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
				
				For Local nameToVal := Eachin listContent
					Local item:InkListItem
					
					Local nameParts:String[] = nameToVal.Key.Split(".")
					If nameParts.Length >= 2 
						item = New InkListItem(nameParts[0], nameParts[1])
					Elseif nameParts.Length == 1 
						item = New InkListItem(nameParts[0])
					End
					
					Local val:Int = nameToVal.Value.AsInt()
					rawList.Add(item, val)
				Next
				
				Return New ListValue(rawList)
			End
			
			' Glue
			If obj.Contains("G<")  Return New Glue(Glue.GlueType.Left)
			If obj.Contains("G>")  Return New Glue(Glue.GlueType.Right)
			If obj.Contains("G=")  Return New Glue(Glue.GlueType.Bidirectional)
			
			' Control commands - check for each possible command
			For Local i:Int = 0 Until ControlCommand.CommandType.TOTAL_VALUES
				Local cmdName:String = _controlCommandNames[i]
				If cmdName <> Null And obj.Contains(cmdName) 
					Return New ControlCommand(i)
				End
			Next
			
			' Void
			If obj.Contains("void") 
				Return New Void()
			End
			
			' Native function
			If obj.Contains("^") 
				Local name:String = obj.GetItem("^").AsString()
				Return NativeFunctionCall.CallWithName(name)
			End
			
			Error("Failed to parse token: " + token.ToString())
		End
		
		If token.IsArray() 
			Local arr:JsonArray = token.AsArray()
			
			If arr.Length = 0 
				Return New Container()
			End
			
			' Special case: multiline block
			If arr.Length = 3 
				And arr.GetItem(0).IsInt() 
				And arr.GetItem(0).AsInt() = 0 
				And arr.GetItem(1).IsInt() 
				And arr.GetItem(2).IsString() 
					Return New StringValue(arr.GetItem(2).AsString())
			End
			
			' Get content array
			Local container:Container = New Container()
			Local contentList:List<RuntimeObject> = New List<RuntimeObject>()
			
			For Local i:Int = 0 Until arr.Length - 1
				Local obj:RuntimeObject = JTokenToRuntimeObject(arr.GetItem(i), storyContext)
				If obj <> Null  contentList.AddLast(obj)
			Next
			
			container.AddContent(contentList)
			
			' Final object is either a null terminator or a dictionary of named content
			Local terminatorObj:JsonValue = arr.GetItem(arr.Length - 1)
			If Not terminatorObj.IsNull() 
				Local namedContentObj:JsonObject = terminatorObj.AsObject()
				
				For Local key:String = Eachin namedContentObj.Keys
					If key = "#f" 
						container.countFlags = namedContentObj.GetItem(key).AsInt()
					Elseif key = "#n" 
						container.name = namedContentObj.GetItem(key).AsString()
					Else
						Local namedContainer:Container = 
							Container(JTokenToRuntimeObject(namedContentObj.GetItem(key)))
						container.AddToNamedContent(key, namedContainer)
					End
				Next
			End
			
			Return container
		End
		
		Error("Failed to parse token: " + token.ToString())
		Return Null
	End
	
	' Convert a JSON array to a list of runtime objects
	Method JArrayToRuntimeObjList:List<RuntimeObject>(jArray:JsonArray, skipLast:Bool = False)
		Local count:Int = jArray.Length
		If skipLast  count -= 1
		
		Local list:List<RuntimeObject> = New List<RuntimeObject>()
		
		For Local i:Int = 0 Until count
			Local obj:RuntimeObject = JTokenToRuntimeObject(jArray.GetItem(i))
			list.AddLast(obj)
		Next
		
		Return list
	End
	
	' Convert a JSON array to a Container
	Method JArrayToContainer:Container(jArray:JsonArray)
		Local container:Container = New Container()
		
		Local content:List<RuntimeObject> = JArrayToRuntimeObjList(jArray, True)
		container.AddContent(content)
		
		' Final object is either a null terminator or a dictionary of named content
		Local terminatorObj:JsonValue = jArray.GetItem(jArray.Length - 1)
		If Not terminatorObj.IsNull() 
			Local namedContentObj:JsonObject = terminatorObj.AsObject()
			
			For Local key:String = Eachin namedContentObj.Keys
				If key = "#f" 
					container.countFlags = namedContentObj.GetItem(key).AsInt()
				Elseif key = "#n" 
					container.name = namedContentObj.GetItem(key).AsString()
				Else
					Local namedContentArray:JsonArray = namedContentObj.GetItem(key).AsArray()
					Local namedContainer:Container = JArrayToContainer(namedContentArray)
					container.AddToNamedContent(key, namedContainer)
				End
			Next
		End
		
		Return container
	End
	
	' Write a runtime object to JSON
	Method WriteRuntimeObject:Void(writer:SimpleJsonWriter, obj:RuntimeObject)
		Local objType:TypeInfo = TypeInfo.ForObject(obj)
		
		Select True
			Case objType.ExtendsType(TypeInfo.ForName("String"))
				writer.WriteStringValue(String(obj))
			
			Case objType.ExtendsType(TypeInfo.ForName("Int"))
				writer.WriteIntValue(Int(obj))
			
			Case objType.ExtendsType(TypeInfo.ForName("Float"))
				writer.WriteFloatValue(Float(obj))
			
			Case objType.ExtendsType(TypeInfo.ForName("Bool"))
				writer.WriteBoolValue(Bool(obj))
			
			Case objType.ExtendsType(TypeInfo.ForName("InkList"))
				WriteInkList(writer, InkList(obj))
			
			Case objType.ExtendsType(TypeInfo.ForName("RuntimeObject"))
				WriteRuntimeObject(writer, RuntimeObject(obj))
			
			Case obj = Null
				writer.WriteNullValue()
			
			Default
				Error("Failed to write object of type: " + objType.Name)
		End
	End
	
	' Write a runtime Ink object to JSON
	Method WriteRuntimeObject:Void(writer:SimpleJsonWriter, obj:RuntimeObject)
		Local objType:TypeInfo = TypeInfo.ForObject(obj)
		
		Select True
			Case objType.ExtendsType(TypeInfo.ForName("Container"))
				WriteRuntimeContainer(writer, Container(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("Divert"))
				WriteDivert(writer, Divert(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("Value"))
				WriteValue(writer, Value(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("ControlCommand"))
				WriteControlCommand(writer, ControlCommand(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("VariableReference"))
				WriteVariableReference(writer, VariableReference(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("VariableAssignment"))
				WriteVariableAssignment(writer, VariableAssignment(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("ChoicePoint"))
				WriteChoicePoint(writer, ChoicePoint(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("Choice"))
				WriteChoice(writer, Choice(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("Glue"))
				WriteGlue(writer, Glue(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("Tag"))
				WriteTag(writer, Tag(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("NativeFunctionCall"))
				WriteNativeFunctionCall(writer, NativeFunctionCall(obj))
				
			Case objType.ExtendsType(TypeInfo.ForName("Void"))
				WriteVoid(writer)
				
			Default
				Error("Failed to write object of type: " + objType.Name)
		End
	End
	
	' Write a Value object to JSON
	Method WriteValue:Void(writer:SimpleJsonWriter, val:Value)
		Local objType:TypeInfo = TypeInfo.ForObject(val)
		
		Select True
			Case objType.ExtendsType(TypeInfo.ForName("IntValue"))
				writer.WriteIntValue(IntValue(val).value)
				
			Case objType.ExtendsType(TypeInfo.ForName("FloatValue"))
				writer.WriteFloatValue(FloatValue(val).value)
				
			Case objType.ExtendsType(TypeInfo.ForName("StringValue"))
				writer.WriteStringValue(StringValue(val).value)
				
			Case objType.ExtendsType(TypeInfo.ForName("BoolValue"))
				writer.WriteBoolValue(BoolValue(val).value)
				
			Case objType.ExtendsType(TypeInfo.ForName("ListValue"))
				WriteInkList(writer, ListValue(val).value)
				
			Case objType.ExtendsType(TypeInfo.ForName("DivertTargetValue"))
				writer.WriteObjectStart()
				writer.WritePropertyName("^->")
				writer.WriteStringValue(DivertTargetValue(val).value.ToString())
				writer.WriteObjectEnd()
				
			Case objType.ExtendsType(TypeInfo.ForName("VariablePointerValue"))
				Local varPtr:VariablePointerValue = VariablePointerValue(val)
				writer.WriteObjectStart()
				writer.WritePropertyName("^var")
				writer.WriteStringValue(varPtr.value)
				If varPtr.contextIndex <> -1 
					writer.WritePropertyName("ci")
					writer.WriteIntValue(varPtr.contextIndex)
				End
				writer.WriteObjectEnd()
				
			Default
				Error("Failed to write value of type: " + objType.Name)
		End
	End
	
	' Write a Container to JSON
	Method WriteRuntimeContainer:Void(writer:SimpleJsonWriter, container:Container, withoutName:Bool = False)
		writer.WriteArrayStart()
		
		For Local obj:RuntimeObject = Eachin container.content
			WriteRuntimeObject(writer, obj)
		Next
		
		' Check if we need a terminator object
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
				writer.WriteIntValue(container.countFlags)
			End
			
			If container.name <> Null And Not withoutName 
				writer.WritePropertyName("#n")
				writer.WriteStringValue(container.name)
			End
			
			writer.WriteObjectEnd()
		Else
			writer.WriteNullValue()
		End
		
		writer.WriteArrayEnd()
	End
	
	' Write a Divert to JSON
	Method WriteDivert:Void(writer:SimpleJsonWriter, divert:Divert)
		writer.WriteObjectStart()
		
		If divert.targetPathString <> Null 
			writer.WritePropertyName("->")
			writer.WriteStringValue(divert.targetPathString)
		Else
			writer.WritePropertyName("->")
			writer.WriteStringValue("")
		End
		
		If divert.isExternal 
			writer.WritePropertyName("externalArgs")
			writer.WriteIntValue(divert.externalArgs)
		End
		
		If divert.variableDivertName <> Null 
			writer.WritePropertyName("var")
			writer.WriteStringValue(divert.variableDivertName)
		End
		
		If divert.isConditional 
			writer.WritePropertyName("c")
			writer.WriteBoolValue(divert.isConditional)
		End
		
		writer.WriteObjectEnd()
	End
	
	' Write a ChoicePoint to JSON
	Method WriteChoicePoint:Void(writer:SimpleJsonWriter, choicePoint:ChoicePoint)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("*")
		writer.WriteStringValue(choicePoint.pathStringOnChoice)
		
		writer.WritePropertyName("flg")
		writer.WriteIntValue(choicePoint.flags)
		
		writer.WriteObjectEnd()
	End
	
	' Write a Choice to JSON
	Method WriteChoice:Void(writer:SimpleJsonWriter, choice:Choice)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("text")
		writer.WriteStringValue(choice.text)
		
		If choice.targetPath <> Null 
			writer.WritePropertyName("->")
			writer.WriteStringValue(choice.targetPath.ToString())
		End
		
		writer.WritePropertyName("index")
		writer.WriteIntValue(choice.index)
		
		If choice.sourcePath <> Null 
			writer.WritePropertyName("originalThread")
			writer.WriteStringValue(choice.sourcePath.ToString())
		End
		
		writer.WriteObjectEnd()
	End
	
	' Write a VariableReference to JSON
	Method WriteVariableReference:Void(writer:SimpleJsonWriter, variableRef:VariableReference)
		writer.WriteObjectStart()
		
		If variableRef.pathStringForCount <> Null 
			writer.WritePropertyName("CNT?")
			writer.WriteStringValue(variableRef.pathStringForCount)
		Else
			writer.WritePropertyName("VAR?")
			writer.WriteStringValue(variableRef.name)
		End
		
		writer.WriteObjectEnd()
	End
	
	' Write a VariableAssignment to JSON
	Method WriteVariableAssignment:Void(writer:SimpleJsonWriter, variableAssignment:VariableAssignment)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("VAR=")
		writer.WriteStringValue(variableAssignment.variableName)
		
		If variableAssignment.isNewDeclaration 
			writer.WritePropertyName("re")
			writer.WriteBoolValue(True)
		End
		
		writer.WriteObjectEnd()
	End
	
	' Write a Tag to JSON
	Method WriteTag:Void(writer:SimpleJsonWriter, tag:Tag)
		writer.WriteObjectStart()
		writer.WritePropertyName("#")
		writer.WriteStringValue(tag.text)
		writer.WriteObjectEnd()
	End
	
	' Write a Glue to JSON
	Method WriteGlue:Void(writer:SimpleJsonWriter, glue:Glue)
		writer.WriteObjectStart()
		Select glue.glueType
			Case Glue.GlueType.Left
				writer.WritePropertyName("G<")
				writer.WriteStringValue("")
			Case Glue.GlueType.Right
				writer.WritePropertyName("G>")
				writer.WriteStringValue("")
			Case Glue.GlueType.Bidirectional
				writer.WritePropertyName("G=")
				writer.WriteStringValue("")
		End
		writer.WriteObjectEnd()
	End
	
	' Write a Control Command to JSON
	Method WriteControlCommand:Void(writer:SimpleJsonWriter, command:ControlCommand)
		writer.WriteObjectStart()
		Local commandName:String = _controlCommandNames[command.commandType]
		writer.WritePropertyName(commandName)
		writer.WriteIntValue(0) ' The value doesn't matter, only the key
		writer.WriteObjectEnd()
	End
	
	' Write a NativeFunctionCall to JSON
	Method WriteNativeFunctionCall:Void(writer:SimpleJsonWriter, nativeFunc:NativeFunctionCall)
		writer.WriteObjectStart()
		writer.WritePropertyName("^")
		writer.WriteStringValue(nativeFunc.name)
		writer.WriteObjectEnd()
	End
	
	' Write Void to JSON
	Method WriteVoid:Void(writer:SimpleJsonWriter)
		writer.WriteObjectStart()
		writer.WritePropertyName("void")
		writer.WriteIntValue(0)
		writer.WriteObjectEnd()
	End
	
	' Write an InkList to JSON
	Method WriteInkList:Void(writer:SimpleJsonWriter, list:InkList)
		writer.WriteObjectStart()
		
		writer.WritePropertyName("list")
		
		writer.WriteObjectStart()
		
		For Local item := Eachin list
			Local itemName:String
			If item.Key.originName <> Null 
				itemName = item.Key.originName
			Else
				itemName = "?"
			End
			
			itemName += "." + item.Key.itemName
			
			writer.WritePropertyName(itemName)
			writer.WriteIntValue(item.Value)
		Next
		
		writer.WriteObjectEnd()
		
		writer.WriteObjectEnd()
	End
	
	' Write a dictionary of runtime objects to JSON
	Method WriteDictionaryRuntimeObjs:Void(writer:SimpleJsonWriter, dictionary:StringMap<RuntimeObject>)
		writer.WriteObjectStart()
		
		For Local keyVal := Eachin dictionary
			writer.WritePropertyName(keyVal.Key)
			WriteRuntimeObject(writer, keyVal.Value)
		Next
		
		writer.WriteObjectEnd()
	End
	
	' Write a list of runtime objects to JSON
	Method WriteListRuntimeObjs:Void(writer:SimpleJsonWriter, list:List<RuntimeObject>)
		writer.WriteArrayStart()
		
		For Local obj := Eachin list
			WriteRuntimeObject(writer, obj)
		Next
		
		writer.WriteArrayEnd()
	End
	
	' Write an integer dictionary to JSON
	Method WriteIntDictionary:Void(writer:SimpleJsonWriter, dict:StringMap<Int>)
		writer.WriteObjectStart()
		
		For Local keyVal := Eachin dict
			writer.WritePropertyName(keyVal.Key)
			writer.WriteIntValue(keyVal.Value)
		Next
		
		writer.WriteObjectEnd()
	End
End

' Simple JSON writer for Ink serialization
Class SimpleJsonWriter
	Field _writer:StringWriter = New StringWriter()
	Field _isFirstItem:Stack<Bool> = New Stack<Bool>()
	Field _indent:Int = 0
	Field _prettyPrint:Bool
	
	Method New(prettyPrint:Bool = False)
		_prettyPrint = prettyPrint
	End
	
	Method ToString:String() Override
		Return _writer.ToString()
	End
	
	Method WriteObjectStart:Void()
		WriteCommaIfNeeded()
		_isFirstItem.Push(True)
		_writer.Write("{")
		_indent += 1
		If _prettyPrint  _writer.Write("~n")
	End
	
	Method WriteObjectEnd:Void()
		_indent -= 1
		If _prettyPrint 
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("}")
		_isFirstItem.Pop()
	End
	
	Method WriteArrayStart:Void()
		WriteCommaIfNeeded()
		_isFirstItem.Push(True)
		_writer.Write("[")
		_indent += 1
		If _prettyPrint  _writer.Write("~n")
	End
	
	Method WriteArrayEnd:Void()
		_indent -= 1
		If _prettyPrint 
			_writer.Write("~n")
			WriteIndent()
		End
		_writer.Write("]")
		_isFirstItem.Pop()
	End
	
	Method WritePropertyName:Void(name:String)
		WriteCommaIfNeeded()
		WriteIndent()
		_writer.Write("~q" + EscapeString(name) + "~q:")
		If _prettyPrint  _writer.Write(" ")
		_isFirstItem.Set(_isFirstItem.Length - 1, False)
	End
	
	Method WriteIntValue:Void(value:Int)
		WriteCommaIfNeeded()
		WriteIndent()
		_writer.Write(value)
		_isFirstItem.Set(_isFirstItem.Length - 1, False)
	End
	
	Method WriteFloatValue:Void(value:Float)
		WriteCommaIfNeeded()
		WriteIndent()
		_writer.Write(value)
		_isFirstItem.Set(_isFirstItem.Length - 1, False)
	End
	
	Method WriteStringValue:Void(value:String)
		WriteCommaIfNeeded()
		WriteIndent()
		_writer.Write("~q" + EscapeString(value) + "~q")
		_isFirstItem.Set(_isFirstItem.Length - 1, False)
	End
	
	Method WriteBoolValue:Void(value:Bool)
		WriteCommaIfNeeded()
		WriteIndent()
		_writer.Write(value ? "true" : "false")
		_isFirstItem.Set(_isFirstItem.Length - 1, False)
	End
	
	Method WriteNullValue:Void()
		WriteCommaIfNeeded()
		WriteIndent()
		_writer.Write("null")
		_isFirstItem.Set(_isFirstItem.Length - 1, False)
	End
	
	Method WriteCommaIfNeeded:Void()
		If _isFirstItem.Length > 0 And Not _isFirstItem.Top 
			_writer.Write(",")
			If _prettyPrint  _writer.Write("~n")
		End
	End
	
	Method WriteIndent:Void()
		If _prettyPrint 
			For Local i:Int = 0 Until _indent
				_writer.Write("  ")
			Next
		End
	End
	
	Method EscapeString:String(str:String)
		Local sb:= New StringStack()
		
		For Local i:Int = 0 Until str.Length
			Local c:String = str[i..i+1]
			Select c
				Case "~q"
					sb.Add("\\~q")
				Case "\"
					sb.Add("\\\\")
				Case "~n"
					sb.Add("\\n")
				Case "~r"
					sb.Add("\\r")
				Case "~t"
					sb.Add("\\t")
				Default
					sb.Add(c)
			End
		Next
		
		Return sb.Join("")
	End
End
