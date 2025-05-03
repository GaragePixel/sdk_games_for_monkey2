Namespace sdk_games.parsers.ink

'===============================================================================
' Choice Class - Represents a Generated Choice in Ink Story
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
' 
' This class encapsulates the concept of a generated choice in the Ink story.
' A single choice point in the story can dynamically generate multiple
' choices based on the story's state, and this class represents each
' individual choice.
'
' Functionality:
'
' - Fields:
'   - `_text`: The main text presented to the player for this choice.
'   - `_pathStringOnChoice`: The target path for the story to divert to when
'     the choice is selected.
'   - `_sourcePath`: The path to the original choice point in the story.
'   - `_index`: The index of this choice in the story's `currentChoices` list.
'   - `_targetPath`: The internal representation of the target path.
'   - `_threadAtGeneration`: The thread state when this choice was generated.
'   - `_originalThreadIndex`: The original thread index at the time of generation.
'   - `_isInvisibleDefault`: Indicates whether this is an invisible default choice.
'   - `_tags`: A list of tags associated with the choice.
'
' - Methods:
'   - `Clone`: Creates a copy of the current choice instance.
'
' Notes:
'
' - This implementation ensures compatibility with the Ink runtime while
'   allowing dynamic story generation.
' - The `Clone` method provides a mechanism for creating independent copies
'   of a choice, preserving its state.
'
' Technical advantages:
'
' - Flexibility:
'   - Supports dynamic choice generation based on story state.
'
' - Robustness:
'   - Encapsulates all relevant data for a choice, ensuring consistency
'     throughout the runtime.
'
'===============================================================================

Class Choice Extends RuntimeObject

    ' Fields
    Field _text:String
    Field _sourcePath:String
    Field _index:Int
    Field _targetPath:Path
    Field _threadAtGeneration:CallStack.Thread
    Field _originalThreadIndex:Int
    Field _isInvisibleDefault:Bool
    Field _tags:List<String>

    ' Property: Gets or sets the main text for the choice
    Property text:String()
        Return _text
    End
    Setter(value:String)
        _text = value
    End

    ' Property: Gets or sets the target path as a string
    Property pathStringOnChoice:String()
        Return _targetPath.ToString()
    End
    Setter(value:String)
        _targetPath = New Path(value)
    End

    ' Constructor
    Method New()
        ' Empty constructor
    End

    ' Method: Creates a copy of the current choice
    Method Clone:Choice()
        Local copy := New Choice()
        copy.text = _text
        copy.sourcePath = _sourcePath
        copy.index = _index
        copy.targetPath = _targetPath
        copy.originalThreadIndex = _originalThreadIndex
        copy.isInvisibleDefault = _isInvisibleDefault
        If _threadAtGeneration <> Null copy.threadAtGeneration = _threadAtGeneration.Copy()
        Return copy
    End

End
