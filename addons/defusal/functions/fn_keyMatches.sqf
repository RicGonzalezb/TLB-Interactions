#include "..\script_component.hpp"
/*
 * Author: TLB
 * Whether a key event matches one of our CBA keybinds.
 *
 * The boards are dialogs, and a dialog does not pass key presses on to CBA's
 * keybind handler, so the keybinds are registered only to be rebindable in
 * Configure Addons and the boards compare key events against them here.
 *
 * A binding without modifiers matches with or without them held, so a hold key
 * keeps working if Shift is pressed at the same time.
 *
 * Arguments:
 * 0: Action id <STRING>
 * 1: DIK code <NUMBER>
 * 2: Shift <BOOL> (default: false)
 * 3: Ctrl <BOOL> (default: false)
 * 4: Alt <BOOL> (default: false)
 * 5: Ignore modifiers, for key releases <BOOL> (default: false)
 *
 * Return Value:
 * Matches <BOOL>
 */

params ["_action", "_key", ["_shift", false], ["_ctrl", false], ["_alt", false], ["_anyModifiers", false]];

private _entry = ["TLB Interactions", _action] call CBA_fnc_getKeybind;

if (isNil "_entry") exitWith { false };

((_entry param [8, []]) findIf {
    _x params [["_dik", -1], ["_modifiers", [false, false, false]]];

    _dik == _key && {
        _anyModifiers
        || {_modifiers isEqualTo [_shift, _ctrl, _alt]}
        || {_modifiers isEqualTo [false, false, false]}
    }
}) != -1
