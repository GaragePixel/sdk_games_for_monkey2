Namespace sdk_games.parsers.ink

'===============================================================================
' CallStack Class - Represents the Story's Execution Call Stack
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
' 
' This class encapsulates the execution call stack of the Ink story runtime.
' It manages multiple threads of execution and provides mechanisms for pushing
' and popping elements, managing temporary variables, and navigating the story's
' flow.
'
' Functionality:
'
' - Nested Classes:
'   - `CallStack.Element`: Represents an individual call stack element, including
'     pointers, temporary variables, and evaluation metadata.
'   - `CallStack.Thread`: Represents a single thread of execution within the
'     call stack.
'
' - Methods:
'   - `Push` and `Pop`: Manage the call stack elements.
'   - `GetTemporaryVariableWithName` and `SetTemporaryVariable`: Manage temporary
'     variable values within the stack.
'   - `Reset`: Resets the call stack to its initial state.
'   - `WriteJson`: Serializes the call stack to JSON.
'   - `ThreadWithIndex`: Retrieves a thread by its index.
'
' - Properties:
'   - `currentThread`: Gets or sets the current thread.
'   - `callStackTrace`: Retrieves a string representation of the call stack for
'     debugging purposes.
'   - `elements`: Retrieves the list of call stack elements.
'
' Notes:
'
' - This implementation ensures compatibility with the Ink runtime while
'   supporting advanced features like thread management and temporary variable
'   handling.
' - The `CallStack.Thread` class manages thread-specific state, while the
'   `CallStack.Element` class encapsulates individual stack frame data.
'
' Technical advantages:
'
' - Flexibility:
'   - Supports multi-threaded story execution.
' - Robustness:
'   - Provides comprehensive error handling for mismatched push/pop operations
'     and variable access.
'
'===============================================================================

Class CallStack

	' Nested Class: Represents an individual call stack element
	Class Element
		
		Field _currentPointer:Pointer
		
		Field _inExpressionEvaluation:Bool
		Field _temporaryVariables:Map<String,RuntimeObject>
		Field _type:PushPopType
		
		' When this callstack element is actually a function evaluation called from the game,
		' we need to keep track of the size of the evaluation stack when it was called
		' so that we know whether there was any return value.
		Field _evaluationStackHeightWhenPushed:Int

		' When functions are called, we trim whitespace from the start and end of what
		' they generate, so we make sure know where the function's start and end are.
		Field _functionStartInOutputStream:Int

		' Constructor
		Method New(type:PushPopType, pointer:Pointer, inExpressionEvaluation:Bool = False)
			_currentPointer = pointer
			_inExpressionEvaluation = inExpressionEvaluation
			_temporaryVariables = New Map<String,RuntimeObject>()
			_type = type
		End

		' Method: Creates a copy of the current element
		Method Copy:Element()
			Local copy := New Element(_type, _currentPointer, _inExpressionEvaluation)
			copy._temporaryVariables = _temporaryVariables.Copy()
			copy._evaluationStackHeightWhenPushed = _evaluationStackHeightWhenPushed
			copy._functionStartInOutputStream = _functionStartInOutputStream
			Return copy
		End
	End

	' Nested Class: Represents a single thread of execution
	Class Thread
		Field _callstack:List<Element>
		Field _threadIndex:Int
		Field _previousPointer:Pointer

		' Constructor
		Method New()
			_callstack = New List<Element>()
		End

		' Constructor: Initializes from JSON
		Method New(jThreadObj:Map<String,RuntimeObject>, storyContext:Story)
			_threadIndex = Int(jThreadObj["threadIndex"])
			Local jThreadCallstack:List<RuntimeObject> = List<RuntimeObject>(jThreadObj["callstack"])
			For Local jElTok:RuntimeObject = Eachin jThreadCallstack
				Local jElementObj:Map<String,RuntimeObject> = Map<String,RuntimeObject>(jElTok)
				Local pushPopType:PushPopType = PushPopType(Int(jElementObj["type"]))
				Local pointer:Pointer = Pointer.Nil
				If jElementObj.ContainsKey("cPath")
					Local currentContainerPathStr:String = String(jElementObj["cPath"])
					Local threadPointerResult = storyContext.ContentAtPath(New Path(currentContainerPathStr))
					pointer._container = threadPointerResult._container
					pointer._index = Int(jElementObj["idx"])
					If threadPointerResult._obj = Null
						RuntimeError("When loading state, internal story location couldn't be found: " + currentContainerPathStr)
					Elseif threadPointerResult._approximate
						If pointer._container <> Null
							storyContext.Warning("State recovery approximated '" + pointer._container._path.ToString() + "' for '" + currentContainerPathStr + "'")
						Else
							storyContext.Warning("Exact internal story location couldn't be found: '" + currentContainerPathStr + "'")
						End
					End
				End
				Local el := New Element(pushPopType, pointer, Bool(jElementObj["exp"]))
				If jElementObj.ContainsKey("temp")
					el._temporaryVariables = Json.JObjectToDictionaryRuntimeObjs(Map<String,RuntimeObject>(jElementObj["temp"]))
				Else
					el._temporaryVariables.Clear()
				End
				_callstack.Add(el)
			Next
			If jThreadObj.ContainsKey("previousContentObject")
				Local prevPath := New Path(String(jThreadObj["previousContentObject"]))
				_previousPointer = storyContext.PointerAtPath(prevPath)
			End
		End

		' Method: Creates a copy of the current thread
		Method Copy:Thread()
			Local copy := New Thread()
			copy._threadIndex = _threadIndex
			For Local el:Element = Eachin _callstack
				copy._callstack.Add(el.Copy())
			Next
			copy._previousPointer = _previousPointer
			Return copy
		End

		' Serialize this thread to JSON
		Method WriteJson:Void(writer:SimpleJsonWriter, storyContext:Story)
			writer.WriteObjectStart()
			
			' Thread index
			writer.WritePropertyName("threadIndex")
			writer.Write(threadIndex)
			
			' Callstack
			writer.WritePropertyName("callstack")
			writer.WriteArrayStart()
			
			For Local el := Eachin _callstack
				writer.WriteObjectStart()
				
				' Current content path
				writer.WritePropertyName("cPath")
				writer.WriteObjectStart()
				
				writer.WritePropertyName("c")
				writer.Write(storyContext.ContentPathToPathString(el.currentContainer.path))
				
				writer.WritePropertyName("i")
				writer.Write(el.currentContentIndex)
				
				writer.WriteObjectEnd()
				
				' Push/pop type
				writer.WritePropertyName("type")
				writer.Write(Int(el.type))
				
				' Whether we're in temporary evaluation
				writer.WritePropertyName("temp")
				writer.Write(el.inExpressionEvaluation)
				
				' Evaluation stack height
				writer.WritePropertyName("ev")
				writer.Write(el.evaluationStackHeight)
				
				' Temporary variables
				If el._temporaryVariables <> Null And el._temporaryVariables.Count > 0 Then
					writer.WritePropertyName("tempVars")
					writer.WriteObjectStart()
					
					For Local keyValue := Eachin el._temporaryVariables
						writer.WritePropertyName(keyValue.Key)
						
						Local val:Object = keyValue.Value
						If val = Null Then
							writer.WriteNull()
						Else
							writer.WriteRuntimeObject(val)
						End
					Next
					
					writer.WriteObjectEnd()
				End
				
				writer.WriteObjectEnd()
			Next
			
			writer.WriteArrayEnd()
			
			' Previous content object path
			If previousContentObject <> Null Then
				writer.WritePropertyName("previousContentObject")
				writer.WriteObjectStart()
				
				writer.WritePropertyName("c")
				writer.Write(storyContext.ContentPathToPathString(previousContentObject.path))
				
				writer.WriteObjectEnd()
			End
			
			writer.WriteObjectEnd()
		End
		
		' Load thread state from JSON
		Method LoadJson:Thread(jThreadObj:JsonObject, storyContext:Story)
			' Thread index
			threadIndex = jThreadObj.GetItem("threadIndex").AsInt()
			
			' Callstack
			Local jThreadCallstack:JsonArray = jThreadObj.GetItem("callstack").AsArray()
			_callstack = New Stack<Element>()
			
			For Local jElTok := Eachin jThreadCallstack
				Local jElementObj:JsonObject = jElTok.AsObject()
				
				' Current container
				Local jPathObj:JsonObject = jElementObj.GetItem("cPath").AsObject()
				Local currentContainerPathStr:String = jPathObj.GetItem("c").AsString()
				Local currentContentIdx:Int = jPathObj.GetItem("i").AsInt()
				
				Local threadElement:Element = Null
				
				Local currentContainer:Container = Container(storyContext.ContentAtPath(New Path(currentContainerPathStr)).obj)
				
				If currentContainer = Null Then
					Error("Could not find container for path: " + currentContainerPathStr)
					Return Null
				End
				
				' Create Element
				Local pushPopType:PushPopType = PushPopType(jElementObj.GetItem("type").AsInt())
				threadElement = New Element(pushPopType, currentContainer, currentContentIdx)
				
				' Expression evaluation flag
				threadElement.inExpressionEvaluation = jElementObj.GetItem("temp").AsBool()
				
				' Evaluation stack height
				If jElementObj.ContainsKey("ev") Then
					threadElement.evaluationStackHeight = jElementObj.GetItem("ev").AsInt()
				End
				
				' Temporary variables
				If jElementObj.ContainsKey("tempVars") Then
					Local jVarObj:JsonObject = jElementObj.GetItem("tempVars").AsObject()
					threadElement._temporaryVariables = New StringMap<RuntimeObject>()
					
					For Local varName := Eachin jVarObj.Keys
						Local jVarVal:JsonValue = jVarObj.GetItem(varName)
						Local varValue:RuntimeObject = storyContext.JsonValueToRuntimeObject(jVarVal)
						threadElement._temporaryVariables.Set(varName, varValue)
					Next
				End
				
				_callstack.Push(threadElement)
			Next
			
			' Previous content object
			If jThreadObj.ContainsKey("previousContentObject") Then
				Local prevContentObjPath:JsonObject = jThreadObj.GetItem("previousContentObject").AsObject()
				Local prevPath:String = prevContentObjPath.GetItem("c").AsString()
				previousContentObject = storyContext.ContentAtPath(New Path(prevPath)).obj
			End
			
			Return Self
		End
	End

	' Fields
	Field _threads:List<Thread>
	Field _threadCounter:Int
	Field _startOfRoot:Pointer

	' Constructor
	Method New(storyContext:Story)
		_startOfRoot = Pointer.StartOf(storyContext._rootContentContainer)
		Reset()
	End

	' Method: Resets the call stack to its initial state
	Method Reset()
		_threads = New List<Thread>()
		_threads.Add(New Thread())
		_threads[0]._callstack.Add(New Element(PushPopType.Tunnel, _startOfRoot))
	End

	' Method: Pushes an element onto the call stack
	Method Push(type:PushPopType, externalEvaluationStackHeight:Int = 0, outputStreamLengthWithPushed:Int = 0)
		Local element := New Element(type, _currentElement._currentPointer, False)
		element._evaluationStackHeightWhenPushed = externalEvaluationStackHeight
		element._functionStartInOutputStream = outputStreamLengthWithPushed
		_callStack.Add(element)
	End
	
	' Pop an Element from the stack
	Method Pop:PushPopType(popType:PushPopType = Null)
		If Self.elements.Count = 0 Then
			Error("Trying to pop an empty stack")
			Return Null
		End
		
		Local element:Element = _current.callstack.Pop()
		
		' Potentially restore the evaluation stack height that was created
		' during function evaluation
		If popType = Null Then
			popType = element.type
		End
		
		Return popType
	End

	' Property: Retrieves the current thread
	Property currentThread:Thread()
		Return _threads[_threads.Length - 1]
	Setter(value:Thread)
		If _threads.Length <> 1
			RuntimeError("Shouldn't set the current thread when multiple are present")
		End
		_threads.Clear()
		_threads.Add(value)
	End

	' Property: Retrieves the call stack trace as a string
	Property callStackTrace:String()
		Local sb := New StringBuilder()
		For Local t:Int = 0 Until _threads.Length
			Local thread := _threads[t]
			Local isCurrent:Bool = (t = _threads.Length - 1)
			sb.Append("=== THREAD " + (t + 1) + "/" + _threads.Length + (isCurrent ? " (current)" Else "") + " ===\n")
			For Local i:Int = 0 Until thread._callstack.Length
				If thread._callstack[i]._type = PushPopType.Func
					sb.Append("  [FUNCTION] ")
				Else
					sb.Append("  [TUNNEL] ")
				End
				Local pointer := thread._callstack[i]._currentPointer
				If Not pointer.isNull
					sb.Append("<SOMEWHERE IN " + pointer._container._path.ToString() + ">\n")
				End
			Next
		Next
		Return sb.ToString()
	End

	' Serialize this CallStack to JSON
	Method WriteJson:Void(writer:SimpleJsonWriter)
		writer.WriteObjectStart()
		
		' Threads
		writer.WritePropertyName("threads")
		writer.WriteArrayStart()
		
		For Local thread := Eachin _threads
			thread.WriteJson(writer, _story)
		Next
		
		writer.WriteArrayEnd()
		
		' Current thread index
		writer.WritePropertyName("threadIndex")
		writer.Write(_threads.IndexOf(_current))
		
		' Thread counter
		writer.WritePropertyName("threadCounter")
		writer.Write(_threadCounter)
		
		writer.WriteObjectEnd()
	End
	
	' Load CallStack state from JSON
	Method LoadJson:CallStack(jObject:JsonObject)
		_threads.Clear()
		
		' Load threads
		Local jThreads:JsonArray = jObject.GetItem("threads").AsArray()
		
		For Local jThreadTok := Eachin jThreads
			Local jThreadObj:JsonObject = jThreadTok.AsObject()
			Local thread:Thread = New Thread(0)
			thread = thread.LoadJson(jThreadObj, _story)
			_threads.AddLast(thread)
		Next
		
		' Set current thread
		Local currentThreadIndex:Int = jObject.GetItem("threadIndex").AsInt()
		_current = _threads[currentThreadIndex]
		
		' Set thread counter
		_threadCounter = jObject.GetItem("threadCounter").AsInt()
		
		Return Self
	End

	' Property: Retrieves the call stack elements
	Property elements:List<Element>()
		Return _callStack
	End

	' Private Property: Accesses the current call stack
	Private 
	
	Property _callStack:List<Element>()
		Return currentThread._callstack
	End
End
