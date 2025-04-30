'-------------------------------------------------
' InkPlayer - Simple Ink Story Player for Testing
'-------------------------------------------------
' iDkP from GaragePixel
' 2025-04-30, Aida 4
'
' Purpose:
' 
' A simple player to test Ink stories. Loads a story,
' displays text, provides choices, and handles basic
' input (mouse and keyboard) for navigation.
'
' List of Functionality:
'
' - Display story text and choices.
' - Handle keyboard and mouse input to select choices.
'
' Notes:
'
' This implementation is intentionally simple, designed
' only for testing purposes. It does not include advanced
' features like per example the editor capabilities of Inky.
'
' Technical Advantages:
'
' - Lightweight and focused on story functionality.
' - Utilizes sdk_mojo for rendering and input handling.
'
Namespace sdk_games.parsers.ink.player

#Import "<stdlib>"
#Import "<sdk_mojo>"

Using stdlib.io.json..
Using stdlib.graphics..
Using stdlib.collections..
Using sdk_mojo.m2..

'-------------------------------------------------
' InkPlayer Class Definition
'-------------------------------------------------

Class InkPlayer Extends sdk_mojo.m2.app.Window

	Private
	
	Field runtime:InkRuntime
	Field storyText:String
	Field choices:List<Choice>
	Field selectedChoice:Int = 0

	Public
	
	Method New()
		Super.New("Ink Story Player", 800, 600)
		runtime = New InkRuntime()
		storyText = ""
		choices = New List<Choice>()
	End

	Method LoadStory(json:JsonValue)
		' Load a story into the player
		runtime.LoadStory(json)
		AdvanceStory()
	End

	Method AdvanceStory()
		' Progress the story and update display
		storyText = runtime.AdvanceStory()
		choices = runtime.GetChoices()
		selectedChoice = 0
	End

	Method OnRender(canvas:Canvas) Override
		App.RequestRender()
		
		' Run Update()
		OnUpdate()

		' Clear the screen
		canvas.Color = New Color(0, 0, 0)
		canvas.DrawRect(0, 0, Width, Height)

		' Draw the story text
		canvas.Color = New Color(1, 1, 1)
		canvas.DrawText(storyText, 20, 20)

		' Draw choices
		Local choicesCount:=choices.Count()
		Local i:Int=0
		For Local c:=Eachin choices
				
			If i = selectedChoice
				canvas.Color = New Color(0.5, 1, 0.5) ' Highlighted choice
			Else
				canvas.Color = New Color(1, 1, 1)
			End
			canvas.DrawText((i + 1) + ". " + c, 40, 60 + i * 30)
			i+=1
		End
	End

	Method OnUpdate()
		' Handle keyboard input for navigation
		Local choicesCount:=choices.Count()
		If Keyboard.KeyHit(Key.Up)
			selectedChoice = Max(selectedChoice - 1, 0)
		End

		If Keyboard.KeyHit(Key.Down)
			selectedChoice = Min(selectedChoice + 1, choicesCount - 1)
		End

		If Keyboard.KeyHit(Key.Enter) And choicesCount > 0
			runtime.Choose(selectedChoice)
			AdvanceStory()
		End
	End

	Method OnMouseDown(button:Int, x:Float, y:Float)
		Local choicesCount:=choices.Count()
		' Handle mouse input for choice selection
		For Local i:Int = 0 Until choicesCount
			Local choiceY:Float = 60 + i * 30
			If y >= choiceY And y < choiceY + 20
				runtime.Choose(i)
				AdvanceStory()
				Exit
			End
		End
	End
End

'-------------------------------------------------
' Program Entry Point
'-------------------------------------------------

' Temporaly string containing the story, normally using the io's read functionnalities of stdlib
Global InkStoryStr:String 

Function Main()
	Local json:=JsonObject.Parse(InkStoryStr) 'Parse to loaded ink file to Ink JSON file
	InkStoryStr=Null 'Freed the memory
	New AppInstance
	Local player:InkPlayer = New InkPlayer()
	player.LoadStory(json)
	App.Run()
End
