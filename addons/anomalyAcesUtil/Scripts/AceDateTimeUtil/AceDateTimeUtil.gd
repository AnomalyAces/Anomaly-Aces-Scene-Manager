@tool
## Utility helper node for date and datetime operations.[br]
class_name AceDateTimeUtil extends Node

## Common date format masks available on AceDateTimeUtil.[br]
## ISO 8601: YYYY-MM-DD[br]
const FORMAT_DATE_ISO_8601 = "YYYY-MM-DD"
## US Short Date: MM/DD/YYYY[br]
const FORMAT_DATE_US_SHORT = "MM/DD/YYYY"
## European/International Short Date: DD/MM/YYYY[br]
const FORMAT_DATE_EU_SHORT = "DD/MM/YYYY"
## Long Date: MMMM d, yyyy[br]
const FORMAT_DATE_LONG = "MMM D, YYYY"
## Medium Date: MMM d, yyyy[br]
const FORMAT_DATE_MEDIUM = "MMM D, YYYY"
## Packed/Sortable: YYYYMMDD[br]
const FORMAT_DATE_PACKED = "YYYYMMDD"
## Short Date (2-digit year): M/D/YY[br]
const FORMAT_DATE_SHORT_2DIGIT_YEAR = "M/D/YY"
## Day-Month-Year Dash: DD-MM-YYYY[br]
const FORMAT_DATE_DASH = "DD-MM-YYYY"
## Abbreviated Day-Month-Year: DD.MM.YYYY[br]
const FORMAT_DATE_ABBREV = "DD.MM.YYYY"
## Day/Month Name: DD MMM YYYY[br]
const FORMAT_DATE_DAY_MONTH_NAME = "DD MMM YYYY"

## Common datetime format masks available on AceDateTimeUtil.[br]
## ISO 8601 Combined: YYYY-MM-DDTHH:mm:ssZ[br]
const FORMAT_DATETIME_ISO_8601 = "YYYY-MM-DDTHH:mm:ssZ"
## Sortable DateTime: YYYY-MM-DD HH:mm:ss[br]
const FORMAT_DATETIME_SORTABLE = "YYYY-MM-DD HH:mm:ss"
## US DateTime: MM/DD/YYYY h:mm A[br]
const FORMAT_DATETIME_US = "MM/DD/YYYY h:mm A"
## European DateTime: DD/MM/YYYY HH:mm[br]
const FORMAT_DATETIME_EU = "DD/MM/YYYY HH:mm"
## RFC 1123: ddd, DD MMM YYYY HH:mm:ss GMT[br]
const FORMAT_DATETIME_RFC_1123 = "ddd, DD MMM YYYY HH:mm:ss GMT"
## Full Date Time: dddd, MMM D, YYYY h:mm:ss A[br]
const FORMAT_DATETIME_FULL = "dddd, MMM D, YYYY h:mm:ss A"
## Unix Timestamp: epoch seconds[br]
const FORMAT_DATETIME_UNIX_TIMESTAMP = "UNIX_TIMESTAMP"
## Compact DateTime: YYYYMMDDHHmm[br]
const FORMAT_DATETIME_COMPACT = "YYYYMMDDHHmm"
## Short Time: h:mm A[br]
const FORMAT_DATETIME_SHORT_TIME = "h:mm A"
## Detailed with Timezone: YYYY-MM-DD HH:mm:ss Z[br]
const FORMAT_DATETIME_WITH_TZ = "YYYY-MM-DD HH:mm:ss Z"


## Utility helper for date-only operations.[br]
class Date:
	## Normalize and clean a raw date string.[br]
	## [b]date_string[/b] - Raw date input. Examples: 2024-03-15, 15 Mar 2024, Mar 15 2024, 03/15/2024[br]
	static func _clean_date_string(date_string: String) -> String:
		return date_string.strip_edges()

	## Normalize date input and remove common timezone markers.[br]
	## [b]date_string[/b] - Raw date input. Examples: 2024-03-15, 15 Mar 2024, Mar 15 2024, 20240315[br]
	static func _normalize_date_string(date_string: String) -> String:
		var cleaned = Date._clean_date_string(date_string)
		cleaned = cleaned.replace("Z", "")
		cleaned = cleaned.replace("UTC", "")
		return cleaned

	## Convert a date string into a numeric-only string for compact parsing.[br]
	static func _digits_only_string(date_string: String) -> String:
		var digits = ""
		for char in date_string:
			if char.is_valid_int():
				digits += char
		return digits

	## Attempt to parse date strings using common separator-based formats and month names.[br]
	static func _month_name_to_number(month_name: String) -> int:
		var key = month_name.strip_edges().to_lower()
		if key.length() > 3:
			key = key.substr(0, 3)
		var map = {
			"jan": 1, "feb": 2, "mar": 3, "apr": 4,
			"may": 5, "jun": 6, "jul": 7, "aug": 8,
			"sep": 9, "oct": 10, "nov": 11, "dec": 12
		}
		return int(map.get(key, 0))

	static func _parse_date_string_from_segments(cleaned: String) -> Dictionary:
		var normalized = cleaned.replace("/", "-").replace(".", "-").replace(",", "").replace(" ", "-")
		var parts = normalized.split("-")
		if parts.size() != 3:
			return {}

		var first_month = Date._month_name_to_number(parts[0])
		var second_month = Date._month_name_to_number(parts[1])
		var third_month = Date._month_name_to_number(parts[2])

		var first_is_num = parts[0].is_valid_int()
		var second_is_num = parts[1].is_valid_int()
		var third_is_num = parts[2].is_valid_int()

		if first_is_num and second_is_num and third_is_num:
			var first = int(parts[0])
			var second = int(parts[1])
			var third = int(parts[2])

			if parts[0].length() == 4:
				return {"year": first, "month": second, "day": third}

			if parts[2].length() == 4:
				# Support both MM/DD/YYYY and DD/MM/YYYY depending on the numeric values.
				if first > 12 and second <= 12:
					return {"year": third, "month": second, "day": first}
				if second > 12 and first <= 12:
					return {"year": third, "month": first, "day": second}
				return {"year": third, "month": first, "day": second}

			if parts[0].length() == 2 and parts[1].length() == 2 and parts[2].length() == 2:
				return {"year": 2000 + first, "month": second, "day": third}
			return {}

		if third_is_num and parts[2].length() == 4:
			var year = int(parts[2])
			if first_month > 0 and second_is_num:
				return {"year": year, "month": first_month, "day": int(parts[1])}
			if second_month > 0 and first_is_num:
				return {"year": year, "month": second_month, "day": int(parts[0])}
			if first_is_num and second_is_num:
				return {"year": year, "month": int(parts[0]), "day": int(parts[1])}
			return {}

		if first_is_num and second_is_num and third_month > 0:
			return {"year": int(parts[0]), "month": third_month, "day": int(parts[1])}

		if first_month > 0 and second_is_num and third_is_num:
			return {"year": int(parts[2]), "month": first_month, "day": int(parts[1])}

		return {}

	## Attempt to parse compact numeric date strings such as YYYYMMDD or YYMMDD.[br]
	static func _parse_compact_date_string(cleaned: String) -> Dictionary:
		var digits = Date._digits_only_string(cleaned)
		if digits.length() == 8:
			return {
				"year": int(digits.substr(0, 4)),
				"month": int(digits.substr(4, 2)),
				"day": int(digits.substr(6, 2))
			}
		if digits.length() == 6:
			return {
				"year": 2000 + int(digits.substr(0, 2)),
				"month": int(digits.substr(2, 2)),
				"day": int(digits.substr(4, 2))
			}
		return {}

	## Parse a date string into a date dictionary containing year, month and day.[br]
	## Supports multiple common date formats by default:[br]
	## - YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD[br]
	## - MM/DD/YYYY, DD/MM/YYYY, DD-MM-YYYY[br]
	## - YYYYMMDD, YYMMDD[br]
	## - D-MMM-YYYY, MMM-D-YYYY, D MMM YYYY, MMM D YYYY[br]
	## Examples: 2024-03-15, 15 Mar 2024, Mar 15 2024, 03/15/2024, 20240315[br]
	## [b]date_string[/b] - Raw date input. Example: 2024-03-15[br]
	static func parse_date_string(date_string: String) -> Dictionary:
		var cleaned = Date._normalize_date_string(date_string)
		if cleaned == "":
			return {}

		var date_dict = Date._parse_date_string_from_segments(cleaned)
		if date_dict.is_empty():
			date_dict = Date._parse_compact_date_string(cleaned)
		if date_dict.is_empty():
			var fallback_dict = Time.get_datetime_dict_from_datetime_string(cleaned, false)
			if fallback_dict.is_empty() or "year" not in fallback_dict:
				return {}
			date_dict = fallback_dict
		
		if date_dict.is_empty() or "year" not in date_dict:
			return {}

		return {
			"year": date_dict["year"],
			"month": date_dict["month"],
			"day": date_dict["day"]
		}

	## Format a date dictionary into a string using the provided format mask.[br]
	## [b]date_dict[/b] - Parsed date dictionary.[br]
	## [b]format[/b] - Output format mask. Uses common masks: `YYYY` = 4-digit year, `YY` = 2-digit year, `MM` = zero-padded month, `M` = month, `MMM` = 3-letter month abbreviation (Jan, Feb...), `DD` = zero-padded day, `D` = day. Example: "YYYY-MM-DD" -> 2024-03-15[br]
	static func _pad_number(value: int, width: int) -> String:
		var s = str(value)
		while s.length() < width:
			s = "0" + s
		return s

	static func format_date_dict(date_dict: Dictionary, format: String = "YYYY-MM-DD") -> String:
		if date_dict.is_empty() or "year" not in date_dict or "month" not in date_dict or "day" not in date_dict:
			return ""

		var year = int(date_dict["year"])
		var month = int(date_dict["month"])
		var day = int(date_dict["day"])

		var month_names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
		var replacements = {
			"YYYY": str(year),
			"YY": str(year).substr(str(year).length() - 2, 2),
			"MM": Date._pad_number(month, 2),
			"MMM": month_names[clamp(month - 1, 0, 11)],
			"M": str(month),
			"DD": Date._pad_number(day, 2),
			"D": str(day)
		}

		var out = format
		# Use placeholder pass to avoid partial replacements (e.g., M inside MMM)
		var token_order = ["YYYY", "YY", "MMM", "MM", "M", "DD", "D"]
		var placeholders = {}
		var ph_keys = []
		var idx = 0
		for key in token_order:
			var ph = "__TK_" + str(idx) + "__"
			placeholders[ph] = replacements.get(key, "")
			ph_keys.append(ph)
			out = out.replace(key, ph)
			idx += 1
		for ph in ph_keys:
			out = out.replace(ph, placeholders[ph])
		return out

	## Parse a raw date string and return a formatted date string.[br]
	## [b]date_string[/b] - Raw date input. Examples: 2024-03-15, Mar 15 2024, 03/15/2024[br]
	## [b]format[/b] - Output format mask. Uses common masks as above. Example: "YYYY-MM-DD" -> 2024-03-15[br]
	static func format_date_string(date_string: String, format: String = "YYYY-MM-DD") -> String:
		var date_dict = Date.parse_date_string(date_string)
		return Date.format_date_dict(date_dict, format)

## Utility helper for datetime operations with timezone-aware transformations.[br]
class DateTime:
	## Normalize and clean a raw datetime string.[br]
	## [b]datetime_string[/b] - Raw datetime input. Examples: 2024-03-15 13:45, 15 Mar 2024 3:45pm, 20240315T143000Z[br]
	static func _clean_datetime_string(datetime_string: String) -> String:
		var cleaned = datetime_string.strip_edges()
		cleaned = cleaned.replace("Z", "")
		cleaned = cleaned.replace("UTC", "")
		cleaned = cleaned.replace("T", " ")
		return cleaned

	## Parse a standard or textual time string into hour/minute/second.[br]
	## Supports:
	## - HH:MM[br]
	## - HH:MM:SS[br]
	## - H:MMam / H:MMpm[br]
	## - H:MM:SSam / H:MM:SSpm[br]
	## - H.MM am/pm (dots are normalized to colons)[br]
	static func _parse_time_string(time_string: String) -> Dictionary:
		var cleaned = time_string.strip_edges().to_lower()
		var ampm = ""
		if cleaned.ends_with("am"):
			ampm = "am"
			cleaned = cleaned.substr(0, cleaned.length() - 2).strip_edges()
		elif cleaned.ends_with("pm"):
			ampm = "pm"
			cleaned = cleaned.substr(0, cleaned.length() - 2).strip_edges()

		cleaned = cleaned.replace(".", ":").replace(" ", "")
		var parts = cleaned.split(":")
		if parts.size() < 2:
			return {}

		for part in parts:
			if not part.is_valid_int():
				return {}

		var hour = int(parts[0])
		var minute = int(parts[1])
		var second = 0
		if parts.size() >= 3:
			second = int(parts[2])

		if hour < 0 or hour > 23 or minute < 0 or minute > 59 or second < 0 or second > 59:
			return {}

		if ampm == "pm" and hour < 12:
			hour += 12
		elif ampm == "am" and hour == 12:
			hour = 0

		return {"hour": hour, "minute": minute, "second": second}

	## Return the system timezone bias in seconds relative to UTC.[br]
	static func _system_timezone_bias_seconds() -> int:
		var tz = Time.get_time_zone_from_system()
		return int(tz.get("bias", 0)) * 60

	## Return the current system timezone name.[br]
	static func _system_timezone_name() -> String:
		return str(Time.get_time_zone_from_system().get("name", "Local"))
	

	## Convert System Timezone Name to 3 letter abbreviation (e.g., "Eastern Standard Time" -> "EST").[br]
	static func _timezone_name_to_abbreviation(tz_name: String) -> String:
		return AceArrayUtil.findFirst(
			AceDateTimeUtilConstants.TIMEZONE_DATA,
			func(item):
				return item["value"].to_lower() == tz_name.to_lower()
		)["abbr"]


	## Parse a datetime string into a datetime dictionary.[br]
	## Supports multiple common datetime formats, including textual months and optional time.[br]
	## Examples: 2024-03-15 13:45, 15 Mar 2024 3:45pm, Mar 15 2024 14:30:00, 20240315T143000Z[br]
	## [b]datetime_string[/b] - Raw datetime input. Examples: 2024-03-15 13:45, 15 Mar 2024 3:45pm, 20240315T143000Z[br]
	## [b]assume_utc[/b] - Interpret input as UTC when true.[br]
	static func parse_datetime_string(datetime_string: String, assume_utc: bool = true) -> Dictionary:
		var cleaned = DateTime._clean_datetime_string(datetime_string)
		if cleaned == "":
			return {}

		var date_part = cleaned
		var time_part = ""
		var time_marker = cleaned.find(":")
		if time_marker != -1:
			var split_idx = cleaned.rfind(" ", time_marker)
			if split_idx != -1:
				date_part = cleaned.substr(0, split_idx).strip_edges()
				time_part = cleaned.substr(split_idx + 1).strip_edges()

		var datetime_dict = {}
		if date_part != "":
			var date_dict = Date.parse_date_string(date_part)
			if not date_dict.is_empty():
				datetime_dict = {
					"year": date_dict["year"],
					"month": date_dict["month"],
					"day": date_dict["day"],
					"hour": 0,
					"minute": 0,
					"second": 0
				}

				if time_part != "":
					var time_dict = DateTime._parse_time_string(time_part)
					if time_dict.is_empty():
						datetime_dict = {}
					else:
						datetime_dict["hour"] = time_dict["hour"]
						datetime_dict["minute"] = time_dict["minute"]
						datetime_dict["second"] = time_dict["second"]

		if datetime_dict.is_empty():
			var fallback_dict = Time.get_datetime_dict_from_datetime_string(cleaned, false)
			if fallback_dict.is_empty() or "year" not in fallback_dict:
				return {}
			datetime_dict = fallback_dict

		if assume_utc:
			datetime_dict["is_utc"] = true

		return datetime_dict

	## Convert a datetime dictionary to a Unix timestamp.[br]
	## [b]datetime_dict[/b] - Parsed datetime dictionary.[br]
	static func to_unix_time(datetime_dict: Dictionary) -> int:
		if datetime_dict.is_empty() or "year" not in datetime_dict:
			return 0
		return Time.get_unix_time_from_datetime_dict(datetime_dict)

	## Convert a Unix timestamp to a standard datetime string.[br]
	## [b]unix_time[/b] - Seconds since epoch.[br]
	static func from_unix_time(unix_time: int) -> String:
		return Time.get_datetime_string_from_unix_time(unix_time)

	## Convert a UTC datetime string into the local system datetime string.[br]
	## [b]utc_datetime_string[/b] - UTC datetime string.[br]
	## [b]assume_utc[/b] - Interpret input as UTC when true.[br]
	static func utc_string_to_local_datetime_string(utc_datetime_string: String, assume_utc: bool = true) -> String:
		var datetime_dict = DateTime.parse_datetime_string(utc_datetime_string, assume_utc)
		AceLog.printLog(["Parsed datetime dict for UTC to local conversion:", str(datetime_dict)], AceLog.LOG_LEVEL.DEBUG)
		if datetime_dict.is_empty():
			return ""

		var unix_time = DateTime.to_unix_time(datetime_dict)
		var local_time = unix_time + DateTime._system_timezone_bias_seconds()
		return DateTime.from_unix_time(local_time)

	## Convert a local datetime string into a UTC datetime string with trailing Z.[br]
	## [b]local_datetime_string[/b] - Local datetime string.[br]
	static func local_datetime_string_to_utc_string(local_datetime_string: String) -> String:
		var datetime_dict = DateTime.parse_datetime_string(local_datetime_string)
		if datetime_dict.is_empty():
			return ""

		var unix_time = DateTime.to_unix_time(datetime_dict)
		var utc_time = unix_time - DateTime._system_timezone_bias_seconds()
		return DateTime.from_unix_time(utc_time) + "Z"

	## Format a datetime string using the provided format mask.[br]
	## [b]datetime_string[/b] - Raw datetime input. Examples: 2024-03-15 13:45, 15 Mar 2024 3:45pm, 20240315T143000Z[br]
	## [b]format[/b] - Output format mask. Uses common masks: `YYYY`, `YY`, `MM`, `MMM`, `M`, `DD`, `D`, `HH` = 24-hour zero-padded, `H` = 24-hour, `mm` = minutes zero-padded, `ss` = seconds zero-padded, `A` = AM/PM, `TZ` = timezone name. Example: FORMAT_DATETIME_WITH_TZ -> 2024-03-15 14:30:00 Local[br]
	## [b]assume_utc[/b] - Interpret input as UTC when true.[br]
	static func format_datetime_string(datetime_string: String, format: String = FORMAT_DATETIME_WITH_TZ, assume_utc: bool = true) -> String:
		var datetime_dict = DateTime.parse_datetime_string(datetime_string, assume_utc)
		if datetime_dict.is_empty():
			return ""

		if format == FORMAT_DATETIME_UNIX_TIMESTAMP:
			return str(DateTime.to_unix_time(datetime_dict))

		var year = int(datetime_dict.get("year", 0))
		var month = int(datetime_dict.get("month", 0))
		var day = int(datetime_dict.get("day", 0))
		var hour = int(datetime_dict.get("hour", 0))
		var minute = int(datetime_dict.get("minute", 0))
		var second = int(datetime_dict.get("second", 0))
		var tz = _timezone_name_to_abbreviation(DateTime._system_timezone_name())

		var hour_24 = hour
		var hour_12 = hour % 12
		if hour_12 == 0:
			hour_12 = 12
		var ampm = "AM"
		if hour >= 12:
			ampm = "PM"

		var month_names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
		var replacements = {
			"YYYY": str(year),
			"YY": str(year).substr(str(year).length() - 2, 2),
			"MM": Date._pad_number(month, 2),
			"MMM": month_names[clamp(month - 1, 0, 11)],
			"M": str(month),
			"DD": Date._pad_number(day, 2),
			"D": str(day),
			"HH": Date._pad_number(hour_24, 2),
			"H": str(hour_24),
			"hh": Date._pad_number(hour_12, 2),
			"h": str(hour_12),
			"mm": Date._pad_number(minute, 2),
			"m": str(minute),
			"ss": Date._pad_number(second, 2),
			"s": str(second),
			"A": ampm,
			"Z": tz
		}

		var out = format
		# Use placeholder pass to avoid partial replacements (e.g., M inside MMM)
		var token_order = ["YYYY", "YY", "MMM", "MM", "M", "DD", "D", "HH", "hh", "H", "h", "mm", "m", "ss", "s", "A", "Z"]
		var placeholders = {}
		var ph_keys = []
		var idx = 0
		for key in token_order:
			var ph = "__TK_" + str(idx) + "__"
			placeholders[ph] = replacements.get(key, "")
			ph_keys.append(ph)
			out = out.replace(key, ph)
			idx += 1
		for ph in ph_keys:
			out = out.replace(ph, placeholders[ph])
		return out

	## Convert a UTC datetime string to a local formatted datetime string.[br]
	## [b]utc_datetime_string[/b] - UTC datetime string.[br]
	## [b]format[/b] - Output format mask. Uses common masks as above. Example: FORMAT_DATETIME_WITH_TZ -> 2024-03-15 12:30:00 UTC[br]
	## [b]assume_utc[/b] - Interpret input as UTC when true.[br]
	static func utc_string_to_local_formatted_string(utc_datetime_string: String, format: String = FORMAT_DATETIME_WITH_TZ, assume_utc: bool = true) -> String:
		var local_string = DateTime.utc_string_to_local_datetime_string(utc_datetime_string, assume_utc)
		if local_string == "":
			return ""

		var datetime_dict = DateTime.parse_datetime_string(local_string, false)
		AceLog.printLog(["Parsed datetime dict for UTC to local conversion (utc_string_to_local_formatted_string):", str(datetime_dict)], AceLog.LOG_LEVEL.DEBUG)
		if datetime_dict.is_empty():
			return ""

		return DateTime.format_datetime_string(local_string, format, false)
