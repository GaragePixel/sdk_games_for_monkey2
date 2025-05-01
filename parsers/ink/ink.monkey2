Namespace sdk_games.ink

'-------------------------------------------------
' Ink Virtual Machine
'-------------------------------------------------
' iDkP from GaragePixel
' 2025-05-01, Aida 4
'
' Purpose:
'
' Ink is a narrative scripting language created by Inkle Studios
' for writing interactive fiction. It provides a compact syntax 
' for authoring branching stories with minimal technical overhead. 
'
' List of Functionality:
'
' - Branching narrative paths via choices
' - Variable tracking for story state
' - Conditional logic for dynamic content
' - Content tagging and metadata
' - Knot/stitch structure for organization
' - External function integration
'
' Notes:
'
' Stories written in Ink compile to JSON structure which the runtime interprets. 
' This separation allows content creators to work independently from 
' engine implementation details. 
' The syntax focuses on readability for writers while maintaining
' powerful logical capabilities.
'
' Technical Advantages:
'
' - Writer-friendly syntax requires minimal programming knowledge
' - Compact representation of complex narrative trees
' - Runtime-agnostic through standardized JSON compilation
' - Built-in state tracking simplifies game integration
' - Supports both linear and highly branched interactive fiction'

#Import "inkruntime.monkey2"
#Import "/compiler/inkcompiler"
'#Import "/player/inkplayer"
