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
' - Uses stdlib for JSON parsing and time management.
'
Namespace sdk_games.parsers.ink

#Import "<stdlib>"

Using stdlib.io.json
Using stdlib.collections
Using stdlib.system.time

'-------------------------------------------------
' InkRuntime Class Definition
'-------------------------------------------------
Class InkRuntime

	Private
	
	Field _storyState:StoryState
	Field _variables:StringMap<InkValue>
	Field _contentContainer:Container
	Field _outputText:String
	Field _choices:List<Choice>

	Public
	
	Method New()
		' Initialize the runtime state
		_storyState = New StoryState()
		_variables = New StringMap<InkValue>()
		_contentContainer = Null
		_outputText = ""
		_choices = New List<Choice>()
	End

	Method LoadStory(json:JsonValue)
		' Load the story's JSON data into the runtime
		If json = Null
			RuntimeError("Story JSON data cannot be Null")
		End

		_storyState.Load(json["state"]) 'FIXME
		_contentContainer = Container.FromJson(json["mainContentContainer"]) 'FIXME
		_variables.Clear()
		Local varsJson:JsonObject = json["variables"]
		For Local key:String = Eachin varsJson.Keys() 'FIXME (not AtEnd property)
			_variables[key] = InkValue.FromJson(varsJson[key])
		End
	End

	Method AdvanceStory:String()
		' Progress the story and return the next output text
		If _contentContainer = Null
			RuntimeError("Content container is not initialized")
		End

		_outputText = ""
		_choices.Clear()

		While Not _storyState.IsComplete()
			Local nextContent:Content = _contentContainer.NextContent(_storyState) 'FIXME
			If nextContent = Null Exit

			Select nextContent.Type 'FIXME
				Case ContentType.Text
					_outputText += nextContent.Text
				Case ContentType.Choice
					_choices.Add(New Choice(nextContent))
				Default
					RuntimeError("Unsupported content type: " + String(nextContent.Type))
			End
		Wend

		Return _outputText
	End

	Method GetChoices:List<Choice>()
		' Return the available choices for the current point in the story
		Return _choices
	End

	Method Choose(index:Int)
		' Select a choice and progress the story
		If index < 0 Or index >= _choices.Length 'FIXME
			RuntimeError("Invalid choice index: " + String(index))
		End

		_storyState.ApplyChoice(_choices[index]) 'FIXME
	End

End

'-------------------------------------------------
' StoryState Class Definition
'-------------------------------------------------
Class StoryState

	Private
	
	Field _variables:StringMap<InkValue>
	Field _currentPosition:Int

	Public
	
	Method New()
		_variables = New StringMap<InkValue>()
		_currentPosition = 0
	End

	Method Load(stateJson:JsonValue)
		' Load story state from JSON
		_currentPosition = stateJson["currentPosition"] 'FIXME
		_variables.Clear()
		Local varsJson:JsonObject = stateJson["variables"] 'FIXME
		For Local key:String = Eachin varsJson.Keys() 'FIXME
			_variables[key] = InkValue.FromJson(varsJson[key])
		End
	End

	Method Save:JsonObject()
		' Save story state to JSON
		Local state:JsonObject = New JsonObject()
		state["currentPosition"] = _currentPosition 'FIXME
		Local vars:JsonObject = New JsonObject()
		For Local key:String = Eachin _variables.Keys() 'FIXME
			vars[key] = _variables[key].ToJson()
		End
		state["variables"] = vars
		Return state
	End

	Method IsComplete:Bool()
		' Check if the story has reached its end
		Return _currentPosition = -1
	End

	Method ApplyChoice(choice:Choice)
		' Apply a choice to progress the story
		_currentPosition = choice.TargetPosition
	End

End

'-------------------------------------------------
' Container Class Definition
'-------------------------------------------------
Class Container

	Private

	Field _content:List<JsonValue>

	Public

	Method New()
		_content = New List<JsonValue>()
	End

	Method FromJson:Container(contentJson:JsonValue)
		' Create a container from JSON data
		Local container:Container = New Container()
		For Local item:JsonValue = Eachin contentJson 'FIXME
			container._content.Add(Content.FromJson(item))
		End
		Return container
	End

	Method NextContent:JsonValue(state:StoryState)
		' Get the next content based on the current state
		If state.IsComplete() Or state._currentPosition >= _content.Length 'FIXME
			Return Null
		End
		Local nextstep:JsonValue = _content[state._currentPosition] 'FIXME
		state._currentPosition += 1
		Return nextstep 'FIXME
	End
End

'-------------------------------------------------
' Choice Class Definition
'-------------------------------------------------
Class Choice

	Private
	
	Field _text:String
	Field _targetPosition:Int

	Public

	Method New(content:JsonValue)
		' Initialize a choice from content
		_text = content.ToString()
		_targetPosition = JsonValue.TargetPosition 'FIXME
	End

	Operator To:String()
		' Return the choice text
		Return _text
	End

	Property TargetPosition:Int()
		Return _targetPosition
	End
End

'-------------------------------------------------
' InkValue Class Definition
'-------------------------------------------------
Class InkValue

	Private
	
	Field _value:Variant

	Public
	
	Method New(value:Variant)
		' Initialize with a generic value
		_value = value
	End

	Method FromJson:InkValue(json:JsonValue)
		' Convert JSON to InkValue
		Return New InkValue(json)
	End

	Method ToJson:JsonValue()
		' Convert InkValue to JSON
		Return Cast<JsonValue>(_value)
	End

	Operator To:String()
		' Return the value as a string
		Return String(_value)
	End

	Property Value:Variant()
		Return _value
	End
End
