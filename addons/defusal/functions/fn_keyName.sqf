#include "..\script_component.hpp"
/*
 * Author: TLB
 * The name of the key bound to one of our CBA keybinds, for on-screen hints.
 *
 * Arguments:
 * 0: Action id <STRING>
 *
 * Return Value:
 * Key name, e.g. "Space" or "Shift+R" <STRING>
 */

params ["_action"];

private _entry = ["TLB Interactions", _action] call CBA_fnc_getKeybind;

if (isNil "_entry") exitWith { localize "STR_tlbi_defusal_key_unbound" };

(_entry param [5, [-1, [false, false, false]]]) params [["_dik", -1], ["_modifiers", [false, false, false]]];

if (_dik < 0) exitWith { localize "STR_tlbi_defusal_key_unbound" };

private _name = keyName _dik;
if ((_name select [0, 1]) == """") then { _name = _name select [1, count _name - 2] };

_modifiers params [["_shift", false], ["_ctrl", false], ["_alt", false]];
if (_alt) then { _name = "Alt+" + _name };
if (_ctrl) then { _name = "Ctrl+" + _name };
if (_shift) then { _name = "Shift+" + _name };

_name
