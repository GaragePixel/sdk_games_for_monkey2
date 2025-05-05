#Import "<stdlib>"

'Using stdlib..'io.json
'Using stdlib.io.filesystem
Using stdlib.collections..

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
End

' Narrative element (e.g., text prefixed with "^")
Class Narrative Extends StoryElement

	Field content:String
	
	Method New(content:String)
		Self.content = content
	End

End

' Media trigger (e.g., images, music, or sound effects)
Class MediaTrigger Extends StoryElement

	Field mediaType:String
	Field identifier:String
	
	Method New(mediaType:String, identifier:String)
		Self.mediaType = mediaType
		Self.identifier = identifier
	End

End

' Choice element representing a player's decision
Class Choice Extends StoryElement

	Field text:String
	Field outcomeKey:String
	
	Method New(text:String, outcomeKey:String)
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
		Self.variable = variable
		Self.comparator = comparator
		Self.value = value
	End

End

' A branch that connects parts of the story
Class Branch Extends StoryElement

	Field targetKey:String
	
	Method New(targetKey:String)
		Self.targetKey = targetKey
	End

End

' A container for a scene or a segment of the story
Class Scene Extends StoryElement

	Field key:String
	Field elements:List<StoryElement> = New List<StoryElement>()
	
	Method New(key:String)
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
End
