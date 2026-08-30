@tool
class_name AceSerialize extends Node

const CLASS_RESOURCE: String = "CLASS_RESOURCE"



static var json: JSON = JSON.new()


static func serialize_array(array: Array[Variant]) -> String:
	var string_arr: Array[String] = []
	if _is_typed_object_array(array):
		var obj_array: Array[Object] = _convert_custom_obj_arr_to_base_obj_arr(array)
		for obj in obj_array:
			string_arr.append(serialize(obj))
	elif _is_typed_dictionary_array(array):
		for dict in array:
			string_arr.append(JSON.stringify(dict, "\t",false))
		
	return "["+",".join(string_arr)+"]"

static func serialize(obj: Object) -> String:
	var dict: Dictionary = {}

	if obj.get_script() != null:
		var cls_properties: Array[Dictionary] = obj.get_script().get_script_property_list()
		var properties: Array[String] = _prop_list_to_string_list(cls_properties)
		
		#Add Class Resource to object - contains script of classes (built-in and custom)
		var base_script: Dictionary = cls_properties[0]
		if base_script.hint_string != null && base_script.hint_string != "":
			dict[CLASS_RESOURCE] = "Resource(\"%s\")" % base_script.hint_string
		
		for prop in properties:
			var pval = obj.get(prop)
			#Don't serialize empty properties
			if(pval == null || (typeof(pval) == TYPE_STRING && pval == "" )):
				continue
			if typeof(pval) == TYPE_ARRAY:
				dict[prop] = []
				if pval.size() == 0:
					continue
				else:
					var obj_arr: Array[Object] = _convert_custom_obj_arr_to_base_obj_arr(pval)
					for val in obj_arr:
						dict[prop].append(JSON.parse_string(serialize(val)))
						# dict[prop].append(val)
			else:
				var value = (
					JSON.parse_string(serialize(pval)) if (typeof(pval) == TYPE_OBJECT && !pval is Texture2D)
					else var_to_str(pval) if ![TYPE_STRING,TYPE_INT,TYPE_FLOAT].has(typeof(pval))
					else pval
				)
				dict[prop] = value
		return JSON.stringify(dict, "\t",false)
	else:
		return var_to_str(obj) if ![TYPE_STRING,TYPE_INT,TYPE_FLOAT].has(typeof(obj)) else str(obj)
	
static func deserialize(jsonInput:String, cls:Resource) -> AceDeserializeResult:
	AceLog.printLog(["Deserializing...", jsonInput], AceLog.LOG_LEVEL.DEBUG)
	var json_res: Error = json.parse(jsonInput)
	if json_res == Error.OK:
		var payload = json.get_data()
		if typeof(payload) == TYPE_DICTIONARY:
			# print("JSON object is Dictionary") 
			var res: AceDeserializeResult = _deserialize_obj(payload, cls)
			return res
		elif typeof(payload) == TYPE_ARRAY:
			# print("JSON object is Array") 
			var res: AceDeserializeResult = _deserialize_array(payload, cls)
			return res
		else:
			# print("JSON object is %s" % payload.get_class()) 
			var res:AceDeserializeResult = AceDeserializeResult.new()
			res.data = str_to_var(payload)
			res.error = Error.OK
			return res
	else:
		AceLog.printLog(["Error processing json string %s. \nError Code %s" % [jsonInput, json_res]], AceLog.LOG_LEVEL.ERROR)
		var res:AceDeserializeResult = AceDeserializeResult.new()
		res.error = json_res
		return res

	
static func _prop_list_to_string_list(cls_properties: Array[Dictionary]):
	var properties: Array[String] 
	properties.assign(cls_properties.map(
		func(prop) -> String: return prop.name 
	))
	return properties

static func _deserialize_array(jsonInput:Array, cls:Resource) -> AceDeserializeResult:
	var arrayDeserRes: AceDeserializeResult = AceDeserializeResult.new()
	var array: Array = []
	for jsonObj in jsonInput:
		if typeof(jsonObj) == TYPE_DICTIONARY:
			# print("JSON object in array is Dictionary") 
			var deserializeRes: AceDeserializeResult = _deserialize_obj(jsonObj, cls)
			if deserializeRes.error == Error.OK:
				array.append(deserializeRes.data)
			else:
				AceLog.printLog(["Error processing object %s. Error Code %s" % [JSON.stringify(jsonObj), deserializeRes.error]], AceLog.LOG_LEVEL.ERROR)
				arrayDeserRes.error = deserializeRes.error
				return arrayDeserRes
		else:
			# print("JSON object in array is %s" % jsonObj.get_class())  
			array.append(str_to_var(jsonObj))
	
	arrayDeserRes.data = array
	arrayDeserRes.error = Error.OK
	return arrayDeserRes

static func _deserialize_obj(jsonInput:Dictionary, cls:Resource) -> AceDeserializeResult:
	var res:AceDeserializeResult = AceDeserializeResult.new()
	
	var obj:Object = cls.new()
	var cls_properties: Array[Dictionary] = obj.get_script().get_script_property_list()
	var properties: Array[String] = _prop_list_to_string_list(cls_properties)

	var typed_obj_dict: Dictionary[String, TypedInfo] = {}
	_determine_obj_typed_members(obj,typed_obj_dict)

	# print("Typed Objects:")
	# print(JSON.stringify(typed_obj_dict, "\t"))


	# print("Properties to deserialize: %s" % JSON.stringify(properties, "\t"))

	# print("Json Input...")
	# print(JSON.stringify(jsonInput, "\t"))
	
	for key in jsonInput.keys():
		if key in properties:
			var value = jsonInput.get(key)
			if typeof(value) == TYPE_STRING:
				# Type TYPE_NIL is returned for strings from str_to_var
				if typeof(str_to_var(value)) == TYPE_INT || typeof(str_to_var(value)) == TYPE_FLOAT || typeof(str_to_var(value)) == TYPE_NIL:
					obj.set(key, value)
				else:
					obj.set(key, str_to_var(value))
			elif typeof(value) == TYPE_DICTIONARY:
				# print("Key %s is of type Dictionary" % key)
				var internal_res: AceDeserializeResult
				if value.has(CLASS_RESOURCE):
					internal_res = _deserialize_obj(value, str_to_var(value.get(CLASS_RESOURCE)))
				else:
					if typed_obj_dict.has(key):
						var tInfo: TypedInfo = typed_obj_dict[key]
						
						if tInfo.dict_obj_script != null:
							internal_res = _deserialize_obj(value, tInfo.dict_obj_script)
						elif tInfo.is_built_in:
							obj.set(key, value)
							continue
					else:
						AceLog.printLog(["Key %s has no type information. Assigning to object value directly. Value: %s" % [key, value]], AceLog.LOG_LEVEL.WARN)
						obj.set(key, value)
						continue

				if internal_res != null:
					obj.set(key, internal_res.data)
			elif typeof(value) == TYPE_ARRAY:
				# print("Key %s is of type Array istyped: %s with values %s" % [key,value.is_typed(),str(value)])

				if typed_obj_dict.has(key):
					var tInfo: TypedInfo = typed_obj_dict[key]
					# print("Key: %s, is an array with type info: %s" % [key, str(tInfo)])
					
					var internal_res: AceDeserializeResult
					if tInfo.is_built_in:
						internal_res = _deserialize_array(value, null)
					else:
						internal_res = _deserialize_array(value, tInfo.array_script)
					
					# print("Key: %s" % key)
					# print("Value: %s" % value)
					# print("Deseralize Result: %s" % internal_res)
					obj.get(key).assign(internal_res.data)
					# obj.set(key, internal_res.data)
					# print("Object After Assigning Deserialized Val: %s" % obj)
				else:
					var internal_res: AceDeserializeResult = _deserialize_array(value, null)
					obj.get(key).assign(internal_res.data)
					# obj.set(key, internal_res.data)
			else:
				obj.set(key, value)
		elif key == CLASS_RESOURCE:
			#found added property CLASS_RESOURCE from serialize. Continue
			continue
		else:
			AceLog.printLog(["Key %s is not included in %s" % [key, cls.resource_path]], AceLog.LOG_LEVEL.ERROR)
			res.data = null
			res.error = FAILED
			return res
	
	res.data = obj
	res.error = OK
	return res


static func _determine_obj_typed_members(obj: Object, typed_members_dict: Dictionary[String, TypedInfo]):
	var current_path = ""
	_recursively_find(typed_members_dict, obj, current_path)

static func _recursively_find(typed_members_dict: Dictionary[String, TypedInfo], obj: Object, current_path: String):
	# Exit the recursion if the object is null or not a valid object.
	if not is_instance_valid(obj):
		return

	# Get all properties of the object.
	var cls_properties: Array[Dictionary] = obj.get_script().get_script_property_list()
	var properties: Array[String] = _prop_list_to_string_list(cls_properties)

	for property in properties:
		var value: Variant

		# Skip built-in properties or internal ones.
		if property.begins_with("_"):
			continue

		# Try to get the property's value.
		value = obj.get(property)

		var full_path = current_path + ":" + property if current_path.length() > 0 else property

		# Check if the value is an Array.
		if typeof(value) == TYPE_ARRAY:
			# print("Proptery: %s is of type Array | Value: %s " % [property, JSON.stringify(value)])
			var typed_array_type: int  = value.get_typed_builtin()
			var typed_array_script: Script = value.get_typed_script()

			var tInfo: TypedInfo

			if typed_members_dict.has(property):
				tInfo = typed_members_dict[property]
			else:
				tInfo = TypedInfo.new()


			# Check if it's a typed built-in array.
			if typed_array_type != TYPE_NIL && typed_array_type != TYPE_OBJECT:
				# print("Property: %s array type is built-in" % property)
				
				tInfo.is_built_in = true
				tInfo.built_in_type = typed_array_type
				typed_members_dict[property] = tInfo
			# Check if its a typed custom array
			elif typed_array_script != null:
				# print("Property: %s array type is custom - %s" % [property, typed_array_script.get_global_name()])
				
				tInfo.is_built_in = false
				tInfo.array_script = typed_array_script
				typed_members_dict[property] = tInfo

				# Recursively check for the object type of the typed array
				if !tInfo.children_processed:
					tInfo.children_processed = true
					_recursively_find(typed_members_dict, typed_array_script.new(),full_path) 


		# Check for dictionaries.
		elif typeof(value) == TYPE_DICTIONARY:
			# print("Proptery: %s is of type Dictionary " % property)

			var typed_dict_val_type: int  = value.get_typed_value_builtin()
			var typed_dict_val_script: Script = value.get_typed_value_script()

			var tInfo: TypedInfo

			if typed_members_dict.has(property):
				tInfo = typed_members_dict[property]
			else:
				tInfo = TypedInfo.new()

			# Check if it's a typed built-in array.
			if typed_dict_val_type != TYPE_NIL && typed_dict_val_type != TYPE_OBJECT:
				# print("Property: %s value type is built-in" % property)
				
				tInfo.is_built_in = true
				tInfo.built_in_type = typed_dict_val_type
				typed_members_dict[property] = tInfo
			
			elif typed_dict_val_script != null:
				# print("Property: %s array type is custom - %s" % [property, typed_dict_val_script.get_global_name()])
				
				tInfo.is_built_in = false
				tInfo.dict_obj_script = typed_dict_val_script
				typed_members_dict[property] = tInfo

				# Recursively check for the object type of the typed array
				if !tInfo.children_processed:
					tInfo.children_processed = true
					_recursively_find(typed_members_dict, typed_dict_val_script.new(),full_path) 

		
		# Recurse for nested objects (not dictionaries or arrays).
		elif typeof(value) == TYPE_OBJECT and not value is Array and not value is Dictionary:
			_recursively_find(typed_members_dict, value, full_path)
	pass

static func _is_typed_dictionary_array(array: Array) -> bool:
	if array.get_typed_builtin() == TYPE_DICTIONARY: # TYPE_DICTIONARY is a constant
		return true
	return false

static func _is_typed_object_array(array: Array) -> bool:
	var classname = array.get_typed_class_name()
	# Check if a class name is set and it is not an empty string
	if classname != &"": # &"" is an empty StringName
		# You can also check against a specific class name if needed
		# e.g., if class_name == &"MyCustomObject":
		return true
	return false

static func _convert_custom_obj_arr_to_base_obj_arr(customObjArr: Array[Variant]) -> Array[Object]:
	var obj_array: Array[Object]
	obj_array.assign(customObjArr)
	return obj_array
