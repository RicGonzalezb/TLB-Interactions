#include "..\script_component.hpp"
/*
 * Author: TLB
 * Runs a building's own UserActions condition or statement, the way the engine
 * would: with "this" set to the building. Compiled code is cached per string, so
 * conditions evaluated every frame while the menu is open cost no compiles.
 *
 * Arguments:
 * 0: House <OBJECT>
 * 1: Condition or statement text <STRING>
 *
 * Return Value:
 * The code's result; true for an empty string or a non-boolean result <ANY>
 */

params ["_house", "_text"];

if (_text == "") exitWith { true };

if (isNil "tlbi_lockpick_codeCache") then { tlbi_lockpick_codeCache = createHashMap };

private _code = tlbi_lockpick_codeCache get _text;
if (isNil "_code") then {
    _code = compile _text;
    tlbi_lockpick_codeCache set [_text, _code];
};

this = _house;
private _result = call _code;

if (isNil "_result") exitWith { true };
if !(_result isEqualType true) exitWith { true };

_result
