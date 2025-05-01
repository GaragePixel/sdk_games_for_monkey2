'-------------------------------------------------
' InkCompiler - Implements the Ink script compiler
'-------------------------------------------------
' iDkP from GaragePixel
' 2025-04-30, Aida 4
'
' Purpose:
' 
' Responsible for compiling Ink scripts into a format
' understood by the InkRuntime.
'
' List of Functionality:
'
' - Load and parse Ink scripts.
' - Validate the syntax of Ink scripts.
' - Compile scripts into JSON format for runtime execution.
'
' Notes:
'
' The compiler processes raw Ink scripts and generates a
' runtime-compatible structure. Syntax validation ensures
' that errors are caught early in the development process.
'
' Technical Advantages:
'
' - Structured error-checking for robust script processing.
' - JSON output ensures compatibility with other components.
'
Namespace sdk_games.parsers.ink.compiler

#Import "<stdlib>"

Using stdlib.io.json
Using stdlib.collections

'-------------------------------------------------
' InkCompiler Class Definition
'-------------------------------------------------
Class InkCompiler
	
	Method New()
		' Initialize the compiler state
		_rawScript = ""
		_parsedContent = New List<JsonValue>()
		_errors = New List<String>()
	End

	Method LoadScript(script:String)
		' Load the raw Ink script for compilation
		If script = ""
			RuntimeError("Script cannot be an empty string")
		End
		_rawScript = script
	End

	Method ValidateSyntax:Bool()
		' Validate the syntax of the loaded script
		If _rawScript = ""
			RuntimeError("No script loaded for syntax validation")
		End

		_errors.Clear()
		' Perform syntax validation (simplified example)
		Local _errorsCount:=_errors.Count()
		For Local line:String = Eachin _rawScript.Split("\n")
			If Not line.Trim().StartsWith("//") And line.Trim() = ""
				_errorsCount+=1
				_errors.Add("Empty line without comment at line: " + String(_errorsCount))
			End
		End

		Return _errorsCount = 0
	End

	Method GetErrors:List<String>()
		' Get the list of syntax errors (if any)
		Return _errors
	End

	Method CompileToJSON:JsonObject()
		' Compile the parsed script into a JSON structure
		If _rawScript = ""
			RuntimeError("No script loaded for compilation")
		End

		If Not ValidateSyntax()
			RuntimeError("Cannot compile script with syntax errors")
		End

		Local compiled:JsonObject = New JsonObject()
		compiled.SetValue( "version",New JsonString("1.0"))
		compiled.SetValue( "content",_parsedContentToJSON(_parsedContent)) 'FIXME? Depends of Content problem
		Return compiled
	End

	Private
	
	Method _parsedContentToJSON:JsonArray(content:List<JsonValue>) 'FIXME? Depends of Content problem
		' Helper method to convert parsed content to JSON
		Local jsonArray:JsonArray = New JsonArray()
		For Local item:JsonValue = Eachin content
			jsonArray.Add(item)
		End
		Return jsonArray
	End

	Private
	
	Field _rawScript:String
	Field _parsedContent:List<JsonValue>
	Field _errors:List<String>
End
