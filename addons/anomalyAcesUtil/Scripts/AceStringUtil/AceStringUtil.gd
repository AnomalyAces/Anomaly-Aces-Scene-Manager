@tool
class_name AceStringUtil extends Node

static func isWildcardMatch(wild_card: String, wild_card_str: String, str_to_match) -> bool :

	## Check if str_to_match contains wild_card_str
	if wild_card_str.begins_with(wild_card) && wild_card_str.ends_with(wild_card):
		var str_to_test: String = wild_card_str.replace(wild_card, "")
		return str_to_match.contains(str_to_test)
	## Check if str_to_match ends with wild_card_str
	elif wild_card_str.begins_with(wild_card):
		var str_to_test: String = wild_card_str.replace(wild_card, "")
		return str_to_match.ends_with(str_to_test)
	## Check if str_to_match begins with wild_card_str
	elif wild_card_str.ends_with(wild_card):
		var str_to_test: String = wild_card_str.replace(wild_card, "")
		return str_to_match.begins_with(str_to_test)
	## Check if str_to_match equals wild_card_str if no wild card is present
	else:
		return wild_card_str.casecmp_to(str_to_match) == 0
	return false 
