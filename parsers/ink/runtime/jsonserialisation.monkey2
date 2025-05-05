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

' Simple JSON writer for Ink runtime
Class SimpleJson
	' Write a runtime object to JSON format
	Method WriteRuntimeObject:String(obj:InkObject)
		Local writer:SimpleJsonWriter = New SimpleJsonWriter()
		writer.WriteObject(obj)
		Return writer.ToString()
	End
	
	' Convert a JSON string back to a runtime object
	Method JTokenToRuntimeObject:InkObject(token:JsonValue, storyContext:Story = Null)
		If token.IsString() Then
			Return New StringValue(token.AsString())
		End
		
		If token.IsNumber() Then
			' Different handling for int vs float
			Local str:String = token.ToString()
			If str.Contains(".") Then
				Return New FloatValue(token.AsFloat())
			Else
				Return New IntValue(token.AsInt())
			End
		End
		
		If token.IsBool() Then
			Return New BoolValue(token.AsBool())
		End
		
		If token.IsNull() Then
			Return Null
		End
		
		If token.IsObject() Then
			Local obj:JsonObject = token.AsObject()
			
			' Divert target value
			If obj.Contains("^->") Then
				Return New DivertTargetValue(New Path(obj.GetItem("^->").AsString()))
			End
			
			' Variable pointer value
			If obj.Contains("^var") Then
				Local varPtr:VariablePointerValue = New VariablePointerValue(obj.GetItem("^var").AsString())
				If obj.Contains("ci") Then
					varPtr.contextIndex = obj.GetItem("ci").AsInt()
				End
				Return varPtr
			End
			
			' List value
			If obj.Contains("list") Then
				Local listContent:JsonObject = obj.GetItem("list").AsObject()
				Local rawList:InkList = New InkList()
				
				For Local nameToVal := Eachin listContent
					Local item:InkListItem = InkListItem.Null
					
					Local nameParts:String[] = nameToVal.Key.Split(".")
					If nameParts.Length > 0 Then
						item = New InkListItem(nameParts[0])
						If nameParts.Length > 1 Then
							item.itemName = nameParts[1]
						End
					End
					
					Local val:Int = nameToVal.Value.AsInt()
					rawList.Add(item, val)
				Next
				
				Return New ListValue(rawList)
			End
			
			' Divert
			If obj.Contains("->") Then
				Local divert:Divert = New Divert()
				divert.targetPathString = obj.GetItem("->").AsString()
				
				If obj.Contains("var") Then
					divert.variableDivertName = obj.GetItem("var").AsString()
				End
				
				If obj.Contains("c") Then
					divert.isConditional = obj.GetItem("c").AsBool()
				End
				
				If obj.Contains("f") Then
					Local externalArgs:Int = obj.GetItem("f").AsInt()
					divert.externalArgs = externalArgs
				End
				
				Return divert
			End
			
			' Choice
			If obj.Contains("*") Then
				Local choice:ChoicePoint = New ChoicePoint()
				choice.pathStringOnChoice = obj.GetItem("*").AsString()
				
				If obj.Contains("flg") Then
					choice.flags = obj.GetItem("flg").AsInt()
				End
				
				Return choice
			End
			
			' Tag
			If obj.Contains("#") Then
				Local tag:Tag = New Tag(obj.GetItem("#").AsString())
				Return tag
			End
			
			' Variable reference
			If obj.Contains("VAR?") Then
				Return New VariableReference(obj.GetItem("VAR?").AsString())
			End
			
			' Variable assignment
			If obj.Contains("VAR=") Then
				Local varName:String = obj.GetItem("VAR=").AsString()
				Local isNewDecl:Bool = False
				If obj.Contains("re") Then
					isNewDecl = obj.GetItem("re").AsBool()
				End
				Return New VariableAssignment(varName, isNewDecl)
			End
			
			' Void
			If obj.Contains("void") Then
				Return New Void()
			End
			
			' Control commands
			If obj.Contains("^->") Then
				Return New ControlCommand(ControlCommand.CommandType.PushTunnel)
			End
			
			If obj.Contains("->t->") Then
				Return New ControlCommand(ControlCommand.CommandType.TunnelOnwards)
			End
			
			If obj.Contains("str") Then
				Return New ControlCommand(ControlCommand.CommandType.BeginString)
			End
			
			If obj.Contains("/str") Then
				Return New ControlCommand(ControlCommand.CommandType.EndString)
			End
			
			If obj.Contains("ev") Then
				Return New ControlCommand(ControlCommand.CommandType.EvalStart)
			End
			
			If obj.Contains("/ev") Then
				Return New ControlCommand(ControlCommand.CommandType.EvalEnd)
			End
			
			If obj.Contains("out") Then
				Return New ControlCommand(ControlCommand.CommandType.EvalOutput)
			End
			
			If obj.Contains("du") Then
				Return New ControlCommand(ControlCommand.CommandType.Duplicate)
			End
			
			If obj.Contains("pop") Then
				Return New ControlCommand(ControlCommand.CommandType.PopEvaluatedValue)
			End
			
			If obj.Contains("/pop") Then
				Return New ControlCommand(ControlCommand.CommandType.PopFunction)
			End
			
			If obj.Contains("~ret") Then
				Return New ControlCommand(ControlCommand.CommandType.PopTunnel)
			End
			
			If obj.Contains("/->") Then
				Return New ControlCommand(ControlCommand.CommandType.PopTunnel)
			End
			
			If obj.Contains("nop") Then
				Return New ControlCommand(ControlCommand.CommandType.NoOp)
			End
			
			If obj.Contains("choiceCnt") Then
				Return New ControlCommand(ControlCommand.CommandType.ChoiceCount)
			End
			
			If obj.Contains("turns") Then
				Return New ControlCommand(ControlCommand.CommandType.TurnsSince)
			End
			
			If obj.Contains("readc") Then
				Return New ControlCommand(ControlCommand.CommandType.ReadCount)
			End
			
			If obj.Contains("rnd") Then
				Return New ControlCommand(ControlCommand.CommandType.Random)
			End
			
			If obj.Contains("srnd") Then
				Return New ControlCommand(ControlCommand.CommandType.SeedRandom)
			End
			
			If obj.Contains("visit") Then
				Return New ControlCommand(ControlCommand.CommandType.VisitIndex)
			End
			
			If obj.Contains("seq") Then
				Return New ControlCommand(ControlCommand.CommandType.SequenceShuffleIndex)
			End
			
			If obj.Contains("thread") Then
				Return New ControlCommand(ControlCommand.CommandType.StartThread)
			End
			
			If obj.Contains("done") Then
				Return New ControlCommand(ControlCommand.CommandType.Done)
			End
			
			If obj.Contains("end") Then
				Return New ControlCommand(ControlCommand.CommandType.End)
			End
			
			If obj.Contains("listInt") Then
				Return New ControlCommand(ControlCommand.CommandType.ListFromInt)
			End
			
			If obj.Contains("range") Then
				Return New ControlCommand(ControlCommand.CommandType.ListRange)
			End
			
			If obj.Contains("lrnd") Then
				Return New ControlCommand(ControlCommand.CommandType.ListRandom)
			End
			
			Error("Failed to parse token: " + token.ToString())
		End
		
		If token.IsArray() Then
			Local array:JsonArray = token.AsArray()
			
			If array.Length == 0 Then
				Return New Container()
			End
			
			' Get content array
			Local contentList:List<InkObject> = New List<InkObject>()
			
			For Local i:Int = 0 Until array.Length - 1
				Local obj:InkObject = JTokenToRuntimeObject(array.GetItem(i), storyContext)
				If obj <> Null Then contentList.AddLast(obj)
			Next
			
			Local container:Container = New Container()
			container.AddContents(contentList)
			
			' Final object is either a null terminator or a dictionary of named content
			Local terminatorObj:JsonValue = array.GetItem(array.Length - 1)
			If Not terminatorObj.IsNull() Then
				Local namedContentObj:JsonObject = terminatorObj.AsObject()
				
				For Local key:String = Eachin namedContentObj.Keys
					If key = "#f" Then
						container.countFlags = namedContentObj.GetItem(key).AsInt()
					ElseIf key = "#n" Then
						container.name = namedContentObj.GetItem(key).AsString()
					Else
						Local namedContainer:Container = JArrayToContainer(namedContentObj.GetItem(key).AsArray())
						container.AddToNamedContent(key, namedContainer)
					End
				Next
			End
			
			Return container
		End
		
		Error("Unknown token type: " + token)
		Return Null
	End
	
	' Convert a JSON array to a Container
	Method JArrayToContainer:Container(jArray:JsonArray, skipLast:Bool = False)
		Local container:Container = New Container()
		If jArray.Length == 0 Return container
		
		Local count:Int = jArray.Length
		If skipLast Then count -= 1
		
		' Add content
		For Local i:Int = 0 Until count
			Local obj:InkObject = JTokenToRuntimeObject(jArray.GetItem(i))
			container.AddContent(obj)
		Next
		
		' Process named content if present
		If Not skipLast Then
			Local terminatorObj:JsonValue = jArray.GetItem(jArray.Length - 1)
			If Not terminatorObj.IsNull() Then
				Local namedContentObj:JsonObject = terminatorObj.AsObject()
				
				For Local key:String = Eachin namedContentObj.Keys
					If key = "#f" Then
						container.countFlags = namedContentObj.GetItem(key).AsInt()
					ElseIf key = "#n" Then
						container.name = namedContentObj.GetItem(key).AsString()
					Else
						Local namedContainer:Container = JArrayToContainer(namedContentObj.GetItem(key).AsArray())
						container.AddToNamedContent(key, namedContainer)
					End
				Next
			End
		End
		
		Return container
	End
End

' Simple JSON writer for story state
Class SimpleJsonWriter
	Field _writer:StringWriter = New StringWriter()
	Field _stateObjects:List<InkObject> = New List<InkObject>()
	Field _indent:Int = 0
	Field _prettyPrint:Bool = True
	
	Method New(prettyPrint:Bool = True)
		_prettyPrint = prettyPrint
	End
	
	Method ToString:String() Override
		Return _writer.ToString()
	End
	
	Method WriteObject:Void(value:InkObject)
		If value Is Container Then
			WriteRuntimeContainer(Container(value))
		ElseIf value Is Divert Then
			WriteDivert(Divert(value))
		ElseIf value Is Value Then
			Write(Value(value))
		ElseIf value Is ControlCommand Then
			WriteControlCommand(ControlCommand(value))
		ElseIf value Is VariableReference Then
			WriteVariableReference(VariableReference(value))
		ElseIf value Is VariableAssignment Then
			WriteVariableAssignment(VariableAssignment(value))
		ElseIf value Is ChoicePoint Then
			WriteChoicePoint(ChoicePoint(value))
		ElseIf value Is Tag Then
			WriteTag(Tag(value))
		ElseIf value Is Void Then
			Write("{\"void\":0}")
		Else
			Error("Failed to write runtime object: " + value)
		End
	End
	
	Method WriteObjectStart:Void()
		StartNewObject(True)
		_indent += 1
	End
	
	Method WriteObjectEnd:Void()
		_indent -= 1
		WriteIndent()
		_writer.Write("}")
	End
	
	Method WriteArrayStart:Void()
		StartNewObject(True)
		_indent += 1
	End
	
	Method WriteArrayEnd:Void()
		_indent -= 1
		WriteIndent()
		_writer.Write("]")
	End
	
	Method WritePropertyName:Void(name:String)
		StartNewObject(True)
		WriteIndent()
		_writer.Write("~q" + name + "~q: ")
	End
	
	Method WritePropertyStart:Void(name:String)
		WritePropertyName(name)
	End
	
	Method WritePropertyEnd:Void()
		' No action needed
	End
	
	Method WritePropertyNameValue:Void(name:String, value:Object)
		WritePropertyName(name)
		WriteRuntimeObject(value)
	End
	
	Method WriteProperty:Void(name:String, value:Int)
		WritePropertyName(name)
		Write(value)
	End
	
	Method WriteProperty:Void(name:String, value:Float)
		WritePropertyName(name)
		Write(value)
	End
	
	Method WriteProperty:Void(name:String, value:String)
		WritePropertyName(name)
		Write(value)
	End
	
	Method WriteProperty:Void(name:String, value:Bool)
		WritePropertyName(name)
		Write(value)
	End
	
	Method WriteProperty:Void(name:String, value:InkObject)
		WritePropertyName(name)
		WriteRuntimeObject(value)
	End
	
	Method WriteRuntimeObject:Void(value:Object)
		If value Is String Then
			Write(String(value))
		ElseIf value Is Int Then
			Write(Int(value))
		ElseIf value Is Float Then
			Write(Float(value))
		ElseIf value Is Bool Then
			Write(Bool(value))
		ElseIf value Is InkList Then
			WriteInkList(InkList(value))
		ElseIf value Is InkObject Then
			WriteObject(InkObject(value))
		ElseIf value = Null Then
			WriteNull()
		Else
			Error("Failed to write object: " + value)
		End
	End
	
	Method WriteRuntimeContainer:Void(container:Container, withoutName:Bool = False)
		WriteArrayStart()
		
		For Local obj:= Eachin container.content
			WriteIndent()
			WriteRuntimeObject(obj)
		Next
		
		' Write terminator object
		Local hasTerminator:Bool = container.namedOnlyContent <> Null Or container.countFlags > 0 Or (container.name <> Null And Not withoutName)
		
		WriteIndent()
		If hasTerminator Then
			WriteObjectStart()
			
			If container.namedOnlyContent <> Null Then
				For Local namedContent := Eachin container.namedOnlyContent
					WritePropertyStart(namedContent.Key)
					WriteRuntimeContainer(namedContent.Value, True)
					WritePropertyEnd()
				Next
			End
			
			If container.countFlags > 0 Then
				WriteProperty("#f", container.countFlags)
			End
			
			If container.name <> Null And Not withoutName Then
				WriteProperty("#n", container.name)
			End
			
			WriteObjectEnd()
		Else
			WriteNull()
		End
		
		WriteArrayEnd()
	End
	
	Method WriteDivert:Void(divert:Divert)
		WriteObjectStart()
		
		If divert.targetPathString <> Null Then
			WriteProperty("->", divert.targetPathString)
		Else
			WriteProperty("->", "")
		End
		
		If divert.isExternal Then
			WriteProperty("externalArgs", divert.externalArgs)
		End
		
		If divert.variableDivertName <> Null Then
			WriteProperty("var", divert.variableDivertName)
		End
		
		If divert.isConditional Then
			WriteProperty("c", divert.isConditional)
		End
		
		WriteObjectEnd()
	End
	
	Method WriteTag:Void(tag:Tag)
		WriteObjectStart()
		WriteProperty("#", tag.text)
		WriteObjectEnd()
	End
	
	Method WriteChoice:Void(choice:Choice)
		WriteObjectStart()
		
		WriteProperty("text", choice.text)
		
		If choice.targetPath <> Null Then
			WriteProperty("->", choice.targetPath.ToString())
		End
		
		WriteProperty("index", choice.index)
		
		If choice.sourcePath <> Null Then
			WriteProperty("originalThread", choice.sourcePath.ToString())
		End
		
		WriteObjectEnd()
	End
	
	Method WriteChoicePoint:Void(choicePoint:ChoicePoint)
		WriteObjectStart()
		
		WriteProperty("*", choicePoint.pathStringOnChoice)
		WriteProperty("flg", choicePoint.flags)
		
		WriteObjectEnd()
	End
	
	Method WriteControlCommand:Void(command:ControlCommand)
		Local controlName:String
		
		Select command.commandType
			Case ControlCommand.CommandType.EvalStart
				controlName = "ev"
			Case ControlCommand.CommandType.EvalOutput
				controlName = "out"
			Case ControlCommand.CommandType.EvalEnd
				controlName = "/ev"
			Case ControlCommand.CommandType.Duplicate
				controlName = "du"
			Case ControlCommand.CommandType.PopEvaluatedValue
				controlName = "pop"
			Case ControlCommand.CommandType.PopFunction
				controlName = "~ret"
			Case ControlCommand.CommandType.PopTunnel
				controlName = "->->"
			Case ControlCommand.CommandType.BeginString
				controlName = "str"
			Case ControlCommand.CommandType.EndString
				controlName = "/str"
			Case ControlCommand.CommandType.NoOp
				controlName = "nop"
			Case ControlCommand.CommandType.ChoiceCount
				controlName = "choiceCnt"
			Case ControlCommand.CommandType.TurnsSince
				controlName = "turns"
			Case ControlCommand.CommandType.ReadCount
				controlName = "readc"
			Case ControlCommand.CommandType.Random
				controlName = "rnd"
			Case ControlCommand.CommandType.SeedRandom
				controlName = "srnd"
			Case ControlCommand.CommandType.VisitIndex
				controlName = "visit"
			Case ControlCommand.CommandType.SequenceShuffleIndex
				controlName = "seq"
			Case ControlCommand.CommandType.StartThread
				controlName = "thread"
			Case ControlCommand.CommandType.Done
				controlName = "done"
			Case ControlCommand.CommandType.End
				controlName = "end"
			Case ControlCommand.CommandType.ListFromInt
				controlName = "listInt"
			Case ControlCommand.CommandType.ListRange
				controlName = "range"
			Case ControlCommand.CommandType.ListRandom
				controlName = "lrnd"
			Default
				Error("Unhandled ControlCommand: " + command.commandType)
		End
		
		Write("{\"" + controlName + "\":0}")
	End
	
	Method WriteVariableReference:Void(variableRef:VariableReference)
		WriteObjectStart()
		
		If variableRef.pathStringForCount <> Null Then
			WriteProperty("CNT?", variableRef.pathStringForCount)
		Else
			WriteProperty("VAR?", variableRef.name)
		End
		
		WriteObjectEnd()
	End
	
	Method WriteVariableAssignment:Void(variableAssignment:VariableAssignment)
		WriteObjectStart()
		
		If variableAssignment.isNewDeclaration Then
			WriteProperty("VAR=", variableAssignment.variableName)
			WriteProperty("re", True)
		Else
			WriteProperty("VAR=", variableAssignment.variableName)
		End
		
		WriteObjectEnd()
	End
	
	Method Write:Void(value:Int)
		StartNewObject(False)
		_writer.Write(value)
	End
	
	Method Write:Void(value:Float)
		StartNewObject(False)
		_writer.Write(value)
	End
	
	Method Write:Void(value:String)
		StartNewObject(False)
		_writer.Write("~q" + EscapeString(value) + "~q")
	End
	
	Method Write:Void(value:Bool)
		StartNewObject(False)
		_writer.Write(value ? "true" : "false")
	End
	
	Method Write:Void(value:Value)
		If value Is IntValue Then
			Write(IntValue(value).value)
		ElseIf value Is FloatValue Then
			Write(FloatValue(value).value)
		ElseIf value Is StringValue Then
			Write(StringValue(value).value)
		ElseIf value Is BoolValue Then
			Write(BoolValue(value).value)
		ElseIf value Is DivertTargetValue Then
			Local divTarget:DivertTargetValue = DivertTargetValue(value)
			WriteObjectStart()
			WriteProperty("^->", divTarget.value)
			WriteObjectEnd()
		ElseIf value Is VariablePointerValue Then
			Local varPtr:VariablePointerValue = VariablePointerValue(value)
			WriteObjectStart()
			WriteProperty("^var", varPtr.value)
			If varPtr.contextIndex <> -1 Then
				WriteProperty("ci", varPtr.contextIndex)
			End
			WriteObjectEnd()
		ElseIf value Is ListValue Then
			WriteInkList(ListValue(value).value)
		Else
			WriteNull()
		End
	End
	
	Method WriteInkList:Void(list:InkList)
		WriteObjectStart()
		
		WritePropertyName("list")
		
		WriteObjectStart()
		
		For Local item := Eachin list
			Local itemName:String = item.Key.originName
			If itemName = Null Then
				itemName = "?"
			End
			
			itemName += "." + item.Key.itemName
			
			WritePropertyName(itemName)
			Write(item.Value)
			
			WriteRawText(",")
		Next
		
		WriteObjectEnd()
		
		WriteObjectEnd()
	End
	
	Method WriteNull:Void()
		StartNewObject(False)
		_writer.Write("null")
	End
	
	Method WriteIndent:Void()
		If _prettyPrint Then
			_writer.Write("~n")
			For Local i:Int = 0 Until _indent
				_writer.Write("    ")
			Next
		End
	End
	
	Method StartNewObject:Void(isContainer:Bool)
		If _stateObjects.Count > 0 Then
			If isContainer Then
				WriteRawText(",")
			Else
				If _stateObjects.Last() Then
					WriteRawText(",")
				End
			End
		End
		
		_stateObjects.AddLast(isContainer)
	End
	
	Method WriteRawText:Void(text:String)
		_writer.Write(text)
	End
	
	Method EscapeString:String(str:String)
		Local sb:StringBuilder = New StringBuilder()
		
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
		
		Return sb.ToString()
	End
End
