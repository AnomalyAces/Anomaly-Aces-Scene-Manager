@tool
extends Node

func _ready():
    AceLog.printLog(["Test runner starting..."])
    _run_tests()

func _assert_eq(name: String, got, expected):
    var ok = false
    # Loose comparison for Dictionaries
    if typeof(got) == TYPE_DICTIONARY and typeof(expected) == TYPE_DICTIONARY:
        ok = got == expected
    else:
        ok = str(got) == str(expected)

    if ok:
        AceLog.printLog(["PASS: " + name])
    else:
        AceLog.printLog(["FAIL: " + name + " => got:" + str(got) + " expected:" + str(expected)])

func _run_tests():
    var util_script = load("res://addons/anomalyAcesUtil/Scripts/AceDateTimeUtil/AceDateTimeUtil.gd")
    var Date = util_script.Date
    var DateTime = util_script.DateTime

    # Date parsing tests
    var d1 = Date.parse_date_string("2024-03-15")
    _assert_eq("Date ISO parse", d1, {"year":2024, "month":3, "day":15})

    var d2 = Date.parse_date_string("Mar 15 2024")
    _assert_eq("Date textual parse", d2, {"year":2024, "month":3, "day":15})

    var d3 = Date.parse_date_string("03/15/2024")
    _assert_eq("Date US numeric parse", d3, {"year":2024, "month":3, "day":15})

    var f1 = Date.format_date_string("Mar 15 2024", "YYYY-MM-DD")
    _assert_eq("Date format YYYY-MM-DD", f1, "2024-03-15")

    var f2 = Date.format_date_string("20240315", "MMM D, YYYY")
    _assert_eq("Date format MMM D, YYYY", f2, "Mar 15, 2024")

    # DateTime parsing tests
    var dt1 = DateTime.parse_datetime_string("15 Mar 2024 3:45pm")
    _assert_eq("DateTime textual AM/PM parse (hour)", dt1.get("hour", -1), 15)
    _assert_eq("DateTime textual AM/PM parse (minute)", dt1.get("minute", -1), 45)

    var fd1 = DateTime.format_datetime_string("2024-03-15 13:45", "YYYY-MM-DD HH:mm:ss TZ")
    AceLog.printLog(["Example formatted datetime:", str(fd1)])

    # Unix conversions (printed for manual inspection; may vary by system timezone)
    var uni = DateTime.to_unix_time({"year":2024, "month":3, "day":15, "hour":12, "minute":0, "second":0})
    AceLog.printLog(["Unix time for 2024-03-15 12:00:00 (system-dependent):" ,str(uni)])
    var dt_from_unix = DateTime.from_unix_time(uni)
    AceLog.printLog(["Datetime from unix:" , str(dt_from_unix)])

    AceLog.printLog(["Tests complete."])
