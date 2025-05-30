Namespace sdk_games.parsers.ink

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

#Import "<stdlib>"

Using stdlib.io.json
Using stdlib.collections

'-------------------------------------------------
' InkRuntime Class Definition
'-------------------------------------------------
Class InkRuntime

	Method New()
		' Initialize the runtime state
		_storyState = New StoryState()
		_variables = New StringMap<JsonValue>()
		_contentContainer = New JsonArray()
		_outputText = ""
		_choices = New Stack<JsonObject>()
		_contentIndex = 0
	End
	
	Property CurrentState:StoryState()
		Return _storyState
	End 

	Method LoadStory(json:JsonObject)
	
		' Debug print to verify JSON structure
'		Print "LoadStory JSON:"+json.ToString()
	
		' Initialize the story state
		If json.Contains("state")
			_storyState.Load(json.GetValue("state"))
			Print("StoryState initialized from JSON.")
		Else
			Print("Warning: No 'state' key in JSON. Initializing default state.")
			_storyState = New StoryState() ' Create an empty state
		End
	
		' Check and load main content container
		If json.Contains("root") And json.GetValue("root").IsArray
		    _contentContainer = Cast<JsonArray>(json.GetValue("root"))
		    Print "Root content loaded with "+_contentContainer.Length+" items."
		Else
		    Print "Error: 'root' key missing or not an array."
		    Return
		End
	
		' Reset content index
		_contentIndex = 0
	
	End

	Method AdvanceStory:String()
	    If _contentContainer.Empty Or _contentIndex >= _contentContainer.Length
	        Print "Story is complete or content container is empty."
	        Return "The story has ended."
	    End
	
	    Local nextContent:JsonValue = _contentContainer[_contentIndex]
	    _contentIndex += 1
	
	    ' Process and return the content
	    Return ProcessContent(nextContent)
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
			targetPos = Int(choice.GetValue("targetPosition").ToNumber())
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
	
	Method ProcessContent:String(content:JsonValue)
	    'If content.IsString Return content.ToString()
	    
	    If content.IsArray
	        Local output:String = ""
	        For Local item:=Eachin content.ToArray()
	            output+=ProcessContent(item)
	        End
	        Return output
	    End
	    
		If content.IsObject
			Local obj:JsonObject = Cast<JsonObject>(content)
			Local ev:JsonValue = obj.GetValue("/ev")
			Local str:JsonValue = obj.GetValue("/str")
	
			If ev <> Null Or str <> Null' Or str.IsString
				Local choiceText:String = str.ToString()
				_choices.Push(obj)
				Return "~n[Choice] " + choiceText
			EndIf
	
			Return "Unsupported content type."
		EndIf

		If content.IsString
			Local text:String = content.ToString()

			'If text.Find("#") Return ""
			'If text.Find("/#") Return ""
			text = text.Replace("\n", "~n~n~n")
			text = text.Replace("/#", "~n")
			text = text.Replace("#", "")
			
'			text = text.Replace("#^image:", "Image: ")
'			text = text.Replace("#^music:", "Music: ")
'			text = text.Replace("#^sfx:", "Sound Effect: ")
'			text = text.Replace("/#", "~n").Trim()
'			text = text.Replace("n#", "~n").Trim()
	
			text = text.Replace("^image:", "Image:")
			text = text.Replace("^music:", "Music:")
			text = text.Replace("^sfx:", "Sound Effect:")
			text = text.Replace("^", "")
	
			'Return text+"~n"
			Return text
		End
	
	    Return "Unsupported content type."
	End
		
	Method CompareJsonValues:Bool(value1:JsonValue, value2:JsonValue)
		' Compare two JSON values for equality
		If value1 = Null Or value2 = Null Return False
			
		If value1.IsString And value2.IsString
			Return value1.ToString() = value2.ToString()
		Elseif value1.IsNumber And value2.IsNumber
			Return value1.ToNumber() = value2.ToNumber()
		Elseif value1.IsBool And value2.IsBool
			Return value1.ToBool() = value2.ToBool()
		End
			
		Return False
	End
	
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
End

'-------------------------------------------------
' StoryState Class Definition
'-------------------------------------------------
Class StoryState
	
	Method New()
		_variables = New StringMap<JsonValue>()
		_currentPosition = 0
		_callStack = New Stack<Int>()
		_isComplete = False
	End

	Method Load(stateValue:JsonValue)
		' Load story state from JSON
		If stateValue = Null Or Not stateValue.IsObject Return
			
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
		If objStr.Length = 0 Return
			
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
	
	Private
	
	Field _variables:StringMap<JsonValue>
	Field _currentPosition:Int
	Field _callStack:Stack<Int>
	Field _isComplete:Bool

End
