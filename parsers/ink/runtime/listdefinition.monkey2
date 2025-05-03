Namespace sdk_games.parsers.ink

'===============================================================================
' ListDefinition Class - Represents a List of Items in the Story
' Implementation: iDkP from GaragePixel
' Date: 2025-05-03, Aida 4
'===============================================================================
'
' Purpose:
'
' The `ListDefinition` class defines a named collection of items for use within
' the Ink runtime. It provides methods to retrieve item values, check for
' item existence, and access items by name or value.
'
' Functionality:
'
' - Properties:
'   - `name`: Retrieves the name of the list.
'   - `items`: Lazily initializes and retrieves the item dictionary.
'
' - Methods:
'   - `ValueForItem`: Gets the value associated with a specific item.
'   - `ContainsItem`: Checks if a specific item exists in the list.
'   - `ContainsItemWithName`: Checks if an item exists by its name.
'   - `TryGetItemWithValue`: Attempts to retrieve an item by its value.
'   - `TryGetValueForItem`: Attempts to retrieve the value for a specific item.
'
' - Constructor:
'   - Initializes a `ListDefinition` instance with a name and a dictionary of
'     item names and values.
'
' Notes:
'
' - The `items` property uses lazy initialization to optimize memory usage.
' - Item values are accessed via their names for simplicity and efficiency.
'
' Technical advantages:
'
' - Efficiency:
'   - Uses dictionaries for fast lookups.
' - Flexibility:
'   - Supports retrieval by both name and value.
' - Robustness:
'   - Ensures consistency by maintaining separate internal representations for
'     item names and values.
'
'===============================================================================

Class ListDefinition

Public

	' Constructor
	Method New(name:String, items:Map<String,Int>)
		_name = name
		_itemNameToValues = items
	End

	Property name:String()
		Return _name
	End

	Property items:Map<InkListItem,Int>()
		If _items = Null
			_items = New Map<InkListItem,Int>()
			For Local itemNameAndValue:=EachIn _itemNameToValues
				Local item := New InkListItem(_name, itemNameAndValue.Key)
				_items[item] = itemNameAndValue.Value
			End
		End
		Return _items
	End

	Method ValueForItem:Int(item:InkListItem)
		Local intVal:Int
		If _itemNameToValues.TryGetValue(item.itemName, intVal)
			Return intVal
		Else
			Return 0
		End
	End

	Method ContainsItem:Bool(item:InkListItem)
		If item.originName <> _name Return False
		Return _itemNameToValues.ContainsKey(item.itemName)
	End

	Method ContainsItemWithName:Bool(itemName:String)
		Return _itemNameToValues.ContainsKey(itemName)
	End

	Method TryGetItemWithValue:Bool(val:Int, item:InkListItem Var)
		For Local namedItem:=EachIn _itemNameToValues
			If namedItem.Value = val
				item = New InkListItem(_name, namedItem.Key)
				Return True
			End
		End
		item = InkListItem.Null
		Return False
	End

	Method TryGetValueForItem:Bool(item:InkListItem, intVal:Int Var)
		Return _itemNameToValues.TryGetValue(item.itemName, intVal)
	End


Private

	Field _name:String
	Field _items:Map<InkListItem,Int>
	
	' The main representation should be simple item names rather than a RawListItem,
	' since we mainly want to access items based on their simple name, since that's
	' how they'll be most commonly requested from ink.
	Field _itemNameToValues:Map<String,Int>

End
