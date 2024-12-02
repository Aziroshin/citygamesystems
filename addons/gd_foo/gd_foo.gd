## Functions extending the functionality of builtin GDScript types.
##
## Dictionary namespace classes have the following naming schema:
## `<key_type>_keyed_<value_type>_dictionary`.
## Basic Dictionary functions don't have an extra
## `variant_keyed_variant_dictionary` namespace class, but instead go into a
## `dictionary` namespace class.

extends EditorPlugin
class_name GDFoo

class variant_keyed_array_dictionary:
	const INVALID_VALUE_TYPE_ERROR_MSG := "Invalid value type in Dictionary[Variant, Array]."
	
	## Adds `p_item` to the array at `p_key`.
	## Initializes an array at `p_key` if none exists yet.
	##
	## Returns `ERR_ALREADY_EXISTS` if `p_item` already exists in the array.
	## Returns `ERR_INVALID_DATA` and pushes an error if there's a non-Array
	## value at `p_key`.
	##
	static func add_array_item_unique_in_array(
		p_dict: Dictionary,
		p_key: Variant,
		p_item: Variant,
	) -> Error:
		if not p_key in p_dict:
			p_dict[p_key] = []
		elif not p_dict[p_key] is Array:
			push_error(INVALID_VALUE_TYPE_ERROR_MSG)
			return ERR_INVALID_DATA
		
		var array: Array = p_dict[p_key]
		if p_item in array:
			return ERR_ALREADY_EXISTS
		array.append(p_item)
		return OK
	
	## Erases `p_item` from the array at `p_key`.
	##
	## If `p_item` exists multiple times in the array, it'll only be erased
	## once (according to what `.find(p_key)` returns for the array)
	##
	## Returns `ERR_DOES_NOT_EXIST` when `p_item` doesn't exist in the array,
	## otherwise `OK`. Note: This also means that it'll return `OK` if there's
	## no array at `p_key` (in which case it'll do nothing).
	static func erase_array_item_once(
		p_dict: Dictionary,
		p_key: Variant,
		p_item: Variant,
		p_erase_array_if_empty_after_erasing_item := false
	) -> Error:
		if p_key in p_dict:
			var untyped_value: Variant = p_dict[p_key]
			if not untyped_value is Array:
				push_error(INVALID_VALUE_TYPE_ERROR_MSG)
				return ERR_INVALID_DATA
			var array := untyped_value as Array
			var item_idx := array.find(p_key)
			
			if item_idx == -1:
				return ERR_DOES_NOT_EXIST
			
			array.remove_at(item_idx)
			
			if len(array) == 0 and p_erase_array_if_empty_after_erasing_item:
				p_dict.erase(p_key)
			
		return OK
		
