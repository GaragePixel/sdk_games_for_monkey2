'-------------------------------------------------
' InkRuntime Extensions - Global State & JSON Enhancements
'-------------------------------------------------
' iDkP from GaragePixel
' 2025-04-30, Aida 4
'
' Purpose:
' 
' Define extensions to the Ink runtime for:
' 1. Maintaining state across different story files/segments
' 2. Enhancing JSON object iteration capabilities
'
' List of Functionality:
'
' - Extract global variables from story segments
' - Persist variables between story transitions
' - Create memory-only JSON data for transfer
' - Enhance JSON object iteration with extension methods
'
' Notes:
'
' Rather than implementing full streaming, this approach
' focuses on variable persistence between discrete story loads.
' This maintains compatibility with the existing inkplayer
' while adding multi-segment capabilities.
'
' Technical Advantages:
'
' - Simpler than full streaming with comparable user experience
' - Memory-efficient by only persisting necessary state
' - Avoids file I/O overhead during story transitions
' - Enhances JSON library without breaking existing functionality
'
Namespace sdk_games.parsers.ink

#Import "<stdlib>"

Using stdlib.io.json
Using stdlib.collections

'-------------------------------------------------
' InkRuntime - Implements the Ink virtual machine (runtime)
'-------------------------------------------------
' iDkP from GaragePixel
' 2025-04-30, Aida 4
'
' Purpose:
' 
' Implements the runtime for Ink, handling story progression,
' state management, and variable tracking.
'
' List of Functionality:
'
' - Parse input commands.
' - Execute story logic.
' - Manage variables and flow control.
'
' Notes:
'
' This is the core of the Ink system and will be referenced
' by the Ink player for story execution.
'
' Technical Advantages:
'
' - Modular design for easy integration with other components.
' - Uses stdlib for JSON parsing and data management.
'
'-------------------------------------------------
' InkRuntime Class Definition
'-------------------------------------------------
Class InkRuntime

	Private
	
	Field _storyState:StoryState
	Field _variables:StringMap<JsonValue>
	Field _contentContainer:JsonArray
	Field _outputText:String
	Field _choices:Stack<JsonObject>
	Field _contentIndex:Int
		
	' Content type constants
	Const CONTENT_TEXT:Int = 0
	Const CONTENT_CHOICE:Int = 1
	Const CONTENT_DIVERT:Int = 2
	Const CONTENT_VARIABLE:Int = 3
	Const CONTENT_CONDITIONAL:Int = 4

	Public

	Method New()
		' Initialize the runtime state
		_storyState = New StoryState()
		_variables = New StringMap<JsonValue>()
		_contentContainer = New JsonArray()
		_outputText = ""
		_choices = New Stack<JsonObject>()
		_contentIndex = 0
	End

	Method LoadStory(json:JsonObject)
		' Load the story's JSON data into the runtime
		If json = Null
			RuntimeError("Story JSON data cannot be Null")
		End

		_storyState.Load(json["state"])
			
		' Load main content container
		If json.Contains("mainContentContainer")
			If json["mainContentContainer"].IsArray
				_contentContainer = Cast<JsonArray>(json["mainContentContainer"])
			End
		End
			
		' Load variables
		_variables.Clear()
		If json.Contains("variables")
			If json["variables"].IsObject
				Local vars:JsonObject = Cast<JsonObject>(json["variables"])
				' Since we can't directly iterate JSON objects, we'll check known keys
				' This is a workaround since the JSON library doesn't provide direct iteration
				ExtractKeysFromObject(vars, _variables)
			End
		End
			
		_contentIndex = 0
	End

	Method AdvanceStory:String()
		' Progress the story and return the next output text
		If _contentContainer = Null
			RuntimeError("Content container is not initialized")
		End

		_outputText = ""
		_choices.Clear()

		While Not _storyState.IsComplete() And _contentIndex < _contentContainer.Length
			Local nextContent:JsonValue = _contentContainer[_contentIndex]
			_contentIndex += 1
				
			If nextContent = Null Then Exit
				
			Local contentType:Int = ProcessContent(nextContent)
				
			If contentType = CONTENT_CHOICE
				' Stop advancing when we encounter choices
				Exit
			End
		Wend

		Return _outputText
	End

	Method GetChoices:Stack<JsonObject>()
		' Return the available choices for the current point in the story
		Return _choices
	End

	Method Choose(index:Int)
		' Select a choice and progress the story
		If index < 0 Or index >= _choices.Length
			RuntimeError("Invalid choice index: " + String(index))
		End

		' Get the target position from the choice
		Local choice:JsonObject = _choices[index]
		Local targetPos:Int = 0
			
		If choice.Contains("targetPosition")
			targetPos = Int(choice["targetPosition"].ToNumber())
		End
			
		' Update the story state
		_storyState.SetCurrentPosition(targetPos)
		_contentIndex = targetPos
			
		' Clear choices after selection
		_choices.Clear()
	End
		
	Method GetVariable:JsonValue(name:String, defaultValue:JsonValue = Null)
		' Get a variable value by name
		If _variables.Contains(name)
			Return _variables[name]
		End
		Return defaultValue
	End
		
	Method SetVariable(name:String, value:JsonValue)
		' Set a variable value
		_variables[name] = value
	End

	Method GetAllVariables:StringMap<JsonValue>()
		Return _variables
	End

	Private
	
	' Helper method to extract keys from JSON object into a StringMap
	Method ExtractKeysFromObject(obj:JsonObject, map:StringMap<JsonValue>)
		' Get its string representation (hack but works)
		Local objStr:String = obj.ToString()
		' Remove outer braces
		objStr = objStr.Slice(1, objStr.Length-1)
			
		' If empty object, return
		If objStr.Length = 0 Then Return
			
		' Split by commas (this is a simple approach that works for basic JSON)
		Local pairs:String[] = objStr.Split(",")
		For Local pair:String = Eachin pairs
			Local keyValue:String[] = pair.Split(":")
			If keyValue.Length >= 2
				' Extract key (remove quotes)
				Local key:String = keyValue[0].Trim()
				key = key.Slice(1, key.Length-1)  ' Remove quotes
					
				' If the JSON object has this key, add it to the map
				If obj.Contains(key)
					map[key] = obj[key]
				End
			End
		Next
	End
		
	Method ProcessContent:Int(content:JsonValue)
		' Process a content item and determine its type
		If content = Null Then Return -1
			
		' If it's not an object, treat as plain text
		If Not content.IsObject
			_outputText += content.ToString()
			Return CONTENT_TEXT
		End
			
		' Process as content object
		Local contentObj:JsonObject = Cast<JsonObject>(content)
			
		' Check content type
		If contentObj.Contains("type")
			Local typeStr:String = contentObj["type"].ToString()
			Local typeInt:Int = Int(typeStr)
				
			Select typeInt
				Case CONTENT_TEXT
					If contentObj.Contains("text")
						_outputText += contentObj["text"].ToString()
					End
					Return CONTENT_TEXT
						
				Case CONTENT_CHOICE
					' Add to available choices
					_choices.Push(contentObj)
					Return CONTENT_CHOICE
						
				Case CONTENT_DIVERT
					' Handle divert
					If contentObj.Contains("target")
						Local targetStr:String = contentObj["target"].ToString()
						Local targetPos:Int = Int(targetStr)
						_contentIndex = targetPos
					End
					Return CONTENT_DIVERT
						
				Case CONTENT_VARIABLE
					' Process variable reference
					If contentObj.Contains("name")
						Local varName:String = contentObj["name"].ToString()
						If _variables.Contains(varName)
							_outputText += _variables[varName].ToString()
						End
					End
					Return CONTENT_VARIABLE
						
				Case CONTENT_CONDITIONAL
					' Handle conditional logic
					If contentObj.Contains("condition") And contentObj.Contains("content")
						If EvaluateCondition(contentObj["condition"])
							' Process conditional content
							ProcessContent(contentObj["content"])
						Elseif contentObj.Contains("else")
							' Process else content
							ProcessContent(contentObj["else"])
						End
					End
					Return CONTENT_CONDITIONAL
						
				Default
					RuntimeError("Unsupported content type: " + String(typeInt))
			End
		End
			
		Return -1
	End
		
	Method EvaluateCondition:Bool(condition:JsonValue)
		' Evaluate a condition expression
		If condition = Null Then Return False
			
		If condition.IsObject
			Local conditionObj:JsonObject = Cast<JsonObject>(condition)
				
			If conditionObj.Contains("variable") And conditionObj.Contains("value")
				Local variableName:String = conditionObj["variable"].ToString()
				Local expectedValue:JsonValue = conditionObj["value"]
				
				If _variables.Contains(variableName)
					Local actualValue:JsonValue = _variables[variableName]
					Return CompareJsonValues(actualValue, expectedValue)
				End
			Elseif conditionObj.Contains("op")
				' Handle logical operations
				Local operation:String = conditionObj["op"].ToString()
				
				Select operation
					Case "and"
						If conditionObj.Contains("left") And conditionObj.Contains("right")
							Return EvaluateCondition(conditionObj["left"]) And EvaluateCondition(conditionObj["right"])
						End
					Case "or"
						If conditionObj.Contains("left") And conditionObj.Contains("right")
							Return EvaluateCondition(conditionObj["left"]) Or EvaluateCondition(conditionObj["right"])
						End
					Case "not"
						If conditionObj.Contains("value")
							Return Not EvaluateCondition(conditionObj["value"])
						End
				End
			End
		Elseif condition.IsBool
			Return condition.ToBool()
		End
			
		Return False
	End
		
	Method CompareJsonValues:Bool(value1:JsonValue, value2:JsonValue)
		' Compare two JSON values for equality
		If value1 = Null Or value2 = Null Then Return False
			
		If value1.IsString And value2.IsString
			Return value1.ToString() = value2.ToString()
		Elseif value1.IsNumber And value2.IsNumber
			Return value1.ToNumber() = value2.ToNumber()
		Elseif value1.IsBool And value2.IsBool
			Return value1.ToBool() = value2.ToBool()
		End
			
		Return False
	End
End

'-------------------------------------------------
' StoryState Class Definition
'-------------------------------------------------
Class StoryState

	Private
	
	Field _variables:StringMap<JsonValue>
	Field _currentPosition:Int
	Field _callStack:Stack<Int>
	Field _isComplete:Bool

	Public
	
	Method New()
		_variables = New StringMap<JsonValue>()
		_currentPosition = 0
		_callStack = New Stack<Int>()
		_isComplete = False
	End

	Method Load(stateValue:JsonValue)
		' Load story state from JSON
		If stateValue = Null Or Not stateValue.IsObject Then Return
			
		Local state:JsonObject = Cast<JsonObject>(stateValue)
			
		If state.Contains("currentPosition")
			_currentPosition = Int(state["currentPosition"].ToNumber())
		End
			
		_variables.Clear()
		If state.Contains("variables")
			If state["variables"].IsObject
				Local variables:JsonObject = Cast<JsonObject>(state["variables"])
					
				' Extract variables using a helper method (since JSON doesn't provide direct iteration)
				ExtractKeysFromObject(variables, _variables)
			End
		End
			
		_callStack.Clear()
		If state.Contains("callStack")
			If state["callStack"].IsArray
				Local callstack:JsonArray = Cast<JsonArray>(state["callStack"])
				For Local i:Int = 0 Until callstack.Length
					_callStack.Push(Int(callstack[i].ToNumber()))
				Next
			End
		End
			
		If state.Contains("isComplete")
			_isComplete = state["isComplete"].ToBool()
		Else
			_isComplete = False
		End
	End
		
	' Helper method to extract keys from JSON object into a StringMap
	Method ExtractKeysFromObject(obj:JsonObject, map:StringMap<JsonValue>)
		' Get its string representation (hack but works)
		Local objStr:String = obj.ToString()
		' Remove outer braces
		objStr = objStr.Slice(1, objStr.Length-1)
			
		' If empty object, return
		If objStr.Length = 0 Then Return
			
		' Split by commas (this is a simple approach that works for basic JSON)
		Local pairs:String[] = objStr.Split(",")
		For Local pair:String = Eachin pairs
			Local keyValue:String[] = pair.Split(":")
			If keyValue.Length >= 2
				' Extract key (remove quotes)
				Local key:String = keyValue[0].Trim()
				key = key.Slice(1, key.Length-1)  ' Remove quotes
					
				' If the JSON object has this key, add it to the map
				If obj.Contains(key)
					map[key] = obj[key]
				End
			End
		Next
	End

	Method Save:JsonObject()
		' Save story state to JSON
		Local state:JsonObject = New JsonObject()
		state["currentPosition"] = New JsonNumber(_currentPosition)
			
		Local vars:JsonObject = New JsonObject()
		For Local key:String = Eachin _variables.Keys
			vars[key] = _variables[key]
		Next
		state["variables"] = vars
			
		Local stackArr:JsonArray = New JsonArray()
		For Local pos:Int = Eachin _callStack
			stackArr.Add(New JsonNumber(pos))
		Next
		state["callStack"] = stackArr
			
		state["isComplete"] = New JsonBool(_isComplete)
			
		Return state
	End

	Method IsComplete:Bool()
		' Check if the story has reached its end
		Return _isComplete
	End

	Method SetCurrentPosition(pos:Int)
		' Set the current position in the story
		_currentPosition = pos
	End
		
	Method GetCurrentPosition:Int()
		' Get the current position in the story
		Return _currentPosition
	End
		
	Method PushCallStack(pos:Int)
		' Push a position onto the call stack
		_callStack.Push(pos)
	End
		
	Method PopCallStack:Int()
		' Pop a position from the call stack
		If _callStack.Length > 0
			Return _callStack.Pop()
		End
		Return -1
	End
		
	Method SetVariable(name:String, value:JsonValue)
		' Set a variable in the story state
		_variables[name] = value
	End
		
	Method GetVariable:JsonValue(name:String, defaultValue:JsonValue = Null)
		' Get a variable from the story state
		If _variables.Contains(name)
			Return _variables[name]
		End
		Return defaultValue
	End
	
	Method SetComplete(complete:Bool)
		' Mark the story as complete or incomplete
		_isComplete = complete
	End
End

'-------------------------------------------------
' StoryLink Class for Managing Story Transitions
'-------------------------------------------------
Class StoryLink
	
	Private
		Field _globalState:JsonObject
		Field _runtime:InkRuntime
		
	Public
		Method New(runtime:InkRuntime)
			_runtime = runtime
			_globalState = New JsonObject()
		End
		
		' Extract global variables from current story
		Method CaptureGlobalState()
			Local variables:StringMap<JsonValue> = _runtime.GetAllVariables()
			_globalState = New JsonObject()
			
			For Local key:String = Eachin variables.Keys
				' Only capture variables marked as global in Ink
				If key.StartsWith("GLOBAL.")
					_globalState[key] = variables[key]
				End
			Next
		End
		
		' Apply captured variables to a newly loaded story
		Method ApplyGlobalState()
			For Local i:Int = 0 Until _globalState.Count()  ' Add parentheses to Count call
				Local key:String = GetSafeJsonKey(_globalState, i)
				
				If key <> ""
					_runtime.SetVariable(key, _globalState[key])
				End
			Next
		End
		
		' Transition to a new story while preserving state
		Method TransitionToStory(storyJson:JsonObject)
			' First capture current globals
			CaptureGlobalState()
			
			' Load the new story
			_runtime.LoadStory(storyJson)
			
			' Apply captured globals to new story
			ApplyGlobalState()
		End
		
		' Helper method for safely getting keys from a JsonObject
		Method GetSafeJsonKey:String(json:JsonObject, index:Int)
			If json = Null Or index < 0 Or index >= json.Count() Then Return ""  ' Add parentheses to Count call
			
			' Extract via string parsing since direct key access isn't available
			Local jsonStr:String = json.ToString()
			' Remove outer braces
			jsonStr = jsonStr.Slice(1, jsonStr.Length-1).Trim()
			
			If jsonStr.Length = 0 Then Return ""
			
			Local pairs:String[] = jsonStr.Split(",")
			If index >= pairs.Length Then Return ""
			
			Local pair:String = pairs[index]
			Local keyValue:String[] = pair.Split(":")
			
			If keyValue.Length < 2 Then Return ""
			
			' Extract and clean key (remove quotes)
			Local key:String = keyValue[0].Trim()
			If key.StartsWith("~q") And key.EndsWith("~q")
				key = key.Slice(2, key.Length-2)
			Elseif key.StartsWith("\") And key.EndsWith("\")
				key = key.Slice(1, key.Length-1)
			End
			
			Return key
		End
End

'-------------------------------------------------
' JsonObjectExt - Extension Methods for JsonObject
'-------------------------------------------------
Class JsonObjectExt

	Public
		' Safer iteration over JsonObject keys and values
		Function ForEach(json:JsonObject, callback:Void(key:String, value:JsonValue))
			If json = Null Then Return
			
			Local jsonStr:String = json.ToString()
			' Remove outer braces
			jsonStr = jsonStr.Slice(1, jsonStr.Length-1).Trim()
			
			If jsonStr.Length = 0 Then Return
			
			' Split by commas (handles simple cases well)
			Local pairs:String[] = jsonStr.Split(",")
			
			For Local pair:String = Eachin pairs
				Local keyValue:String[] = pair.Split(":")
				
				If keyValue.Length >= 2
					' Extract key (remove quotes)
					Local key:String = keyValue[0].Trim()
					
					If key.StartsWith("~q") And key.EndsWith("~q")
						key = key.Slice(2, key.Length-2)
					Elseif key.StartsWith("\") And key.EndsWith("\")
						key = key.Slice(1, key.Length-1)
					End
					
					' Only call if the key exists in the original object (to be safe)
					If json.Contains(key)
						callback(key, json[key])
					End
				End
			Next
		End
		
		' Create a String array of keys
		Function GetKeys:String[](json:JsonObject)
			Local keys:Stack<String> = New Stack<String>()
			
			ForEach(json, Lambda(key:String, value:JsonValue)
				keys.Push(key)
			End)
			
			Return keys.ToArray()
		End
		
		' Safe version of getting a key by index
		Function KeyAt:String(json:JsonObject, index:Int)
			Local keys:String[] = GetKeys(json)
			
			If index >= 0 And index < keys.Length
				Return keys[index]
			End
			
			Return ""
		End
End
