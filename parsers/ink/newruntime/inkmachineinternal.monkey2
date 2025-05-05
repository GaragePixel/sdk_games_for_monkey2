#Import "<stdlib>"

'Using stdlib..'io.json
'Using stdlib.io.filesystem
Using stdlib.collections..

Enum TypeElement 
	Narrative 
	MediaTrigger 
	Choice 
	Condition 
	Branch 
	Scene 
End 

Class Story 
	
	Method New(inkVersion:Int)
		Version = inkVersion
	End
	
	Method AddElement(element:StoryElement)
		_root.AddLast(element)
	End
	
	Property Version:Int()
		Return _inkVersion 
	Setter(version:int)
		_inkVersion=version
	End
	
	Property Root:List<StoryElement>() 'Read only!
		Return _root
	End 

	' Metadata about the story
	Field _inkVersion:Int
	Field _root:List<StoryElement> = New List<StoryElement>()

End

' Abstract base class for all story elements
Class StoryElement
	
	Property Type:TypeElement()
		Return _type
	End

	Operator To:String()
		
		select _type
			Case TypeElement.Narrative
				Return "Narrative"
			Case TypeElement.MediaTrigger 
				Return "MediaTrigger"
			Case TypeElement.Choice 
				Return "Choice"
			Case TypeElement.Condition 
				Return "Condition"
			Case TypeElement.Branch
				Return "Branch"
		End 
		
		Return "Scene"
	End
	
	Protected
	
	Field _type:TypeElement
End

' Narrative element (e.g., text prefixed with "^")
Class Narrative Extends StoryElement
	
	Property Content:String()
		Return _content 
	End
	
	Method New(content:String)
		Super._type=TypeElement.Narrative
		_content = content
	End

	Field _content:String
	
End

' Media trigger (e.g., images, music, or sound effects)
Class MediaTrigger Extends StoryElement

	Field mediaType:String
	Field identifier:String
	
	Method New(mediaType:String, identifier:String)
		Super._type=TypeElement.MediaTrigger
		Self.mediaType = mediaType
		Self.identifier = identifier
	End

End

' Choice element representing a player's decision
Class Choice Extends StoryElement

	Field text:String
	Field outcomeKey:String
	
	Method New(text:String, outcomeKey:String)
		Super._type=TypeElement.Choice
		Self.text = text
		Self.outcomeKey = outcomeKey
	End

End

' Conditional logic used to control branching
Class Condition Extends StoryElement

	Field variable:String
	Field comparator:String
	Field value:Variant
	
	Method New(variable:String, comparator:String, value:Variant)
		Super._type=TypeElement.Condition
		Self.variable = variable
		Self.comparator = comparator
		Self.value = value
	End

End

' A branch that connects parts of the story
Class Branch Extends StoryElement

	Field targetKey:String
	
	Method New(targetKey:String)
		Super._type=TypeElement.Branch
		Self.targetKey = targetKey
	End

End

' A container for a scene or a segment of the story
Class Scene Extends StoryElement

	Field key:String
	Field elements:List<StoryElement> = New List<StoryElement>()
	
	Method New(key:String)
		Super._type=TypeElement.Scene
		Self.key = key
	End
	
	Method AddElement(element:StoryElement)
		elements.AddLast(element)
	End

End

' Main logic for representing the JSON structure
Class Book

	Field story:Story
	
	Method New(inkVersion:Int=21)
		story = New Story(inkVersion)
	End
	
	Method AddScene:Scene(key:String)
		Local scene:Scene = New Scene(key)
		story.AddElement(scene)
		Return scene
	End
	
	Method AddNarrative(content:String)
		story.AddElement(New Narrative(content))
	End
	
	Method AddMediaTrigger(mediaType:String, identifier:String)
		story.AddElement(New MediaTrigger(mediaType, identifier))
	End
	
	Method AddChoice(text:String, outcomeKey:String)
		story.AddElement(New Choice(text, outcomeKey))
	End
	
	Method AddCondition(variable:String, comparator:String, value:Variant)
		story.AddElement(New Condition(variable, comparator, value))
	End
	
	Method AddBranch(targetKey:String)
		story.AddElement(New Branch(targetKey))
	End

End

' Example usage
Function Main()
	Local story:Book = New Book()
	
	' Example: Adding a narrative element
	story.AddNarrative("The summer heat shimmered over the pavement as I walked through the shopping district.")
	
	' Example: Adding a media trigger
	story.AddMediaTrigger("image", "city_summer_afternoon")
	story.AddMediaTrigger("music", "summer_ambient")
	
	' Example: Adding a choice
	story.AddChoice("Pretend not to notice", "notice_nothing")
	story.AddChoice("Look more carefully", "notice_something")
	
	' Example: Adding a condition
	story.AddCondition("trust_level", "==", 1)
	
	' Example: Adding a scene
	Local scene:Scene = story.AddScene("notice_nothing")
	scene.AddElement(New Narrative("I blinked and kept my expression neutral."))
	scene.AddElement(New Branch("continue_conversation"))
	
	Print("Story structure created successfully.")

	' List all elements
	ListStoryElements(story)
End

' Routine to recursively list all elements in a story
Function ListStoryElements(book:Book)
	Print("Listing Story Elements:")
	Print("------------------------")
	
	' Get the root story object
	Local story:Story = book.story
	
	' Iterate over all root elements in the story
	For Local element:StoryElement = Eachin story.Root
		PrintElement(element, 0)
	End
End

Function CreateIntendationToken:String(indentLevel:Int)
	Local indent:String
	For Local i:Int = 0 Until indentLevel
		indent += "\t"
	End	
	Return indent
End


' Recursive function to print details of a StoryElement and its children
Function PrintElement(element:StoryElement, indentLevel:Int)
	Local indent:String = CreateIntendationToken(indentLevel) ' Create appropriate indentation
	
	Local type:=element.Type
	Print element
	'Print type 
	
	Select type
		Case TypeElement.Narrative
			Local narrative:= element
			Print(indent + "Narrative: " + narrative.content)
		Case TypeElement.MediaTrigger
			Local media:MediaTrigger = element
			Print(indent + "MediaTrigger: " + media.mediaType + " (" + media.identifier + ")")
		Case TypeElement.Choice
			Local choice:Choice = element
			Print(indent + "Choice: " + choice.text + " (Outcome: " + choice.outcomeKey + ")")
		Case TypeElement.Condition
			Local condition:Condition = element
			Print(indent + "Condition: " + condition.variable + " " + condition.comparator + " " + condition.value.ToString())
		Case TypeElement.Branch
			Local branch:Branch = element
			Print(indent + "Branch: -> " + branch.targetKey)
		Case TypeElement.Scene
			Local scene:Scene = element
			Print(indent + "Scene: " + scene.key)
			' Recursively print all elements in the scene
			For Local child:StoryElement = Eachin scene.elements
				PrintElement(child, indentLevel + 1)
			End
		Default
			Print(indent + "Unknown Element")
	End
	
End

' Example usage
Function PrintProject()
	' Create a sample story
	Local story:Book = New Book(21)
	
	' Add some elements
	story.AddNarrative("The summer heat shimmered over the pavement.")
	story.AddMediaTrigger("image", "city_summer_afternoon")
	story.AddChoice("Pretend not to notice", "notice_nothing")
	story.AddCondition("trust_level", "==", 1)
	
	' Add a scene and nested elements
	Local scene:Scene = story.AddScene("notice_nothing")
	scene.AddElement(New Narrative("I blinked and kept my expression neutral."))
	scene.AddElement(New Branch("continue_conversation"))
	
	' List all elements
	ListStoryElements(story)
End
