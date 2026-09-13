#include "..\script_component.hpp"
/*
 * Author: TLB
 * One input event, from a key or from holding a board button, mapped onto the
 * running technique. Keys and buttons keep separate hold flags so letting go of
 * a button never cancels a key that is still held, and the reverse.
 *
 *            button 1 / A, Left   button 2 / Space, W   button 3 / D, Right   R
 *   pins     previous pin         lift (hold)           next pin              -
 *   rake     -                    tension (hold)        -                     rake
 *   dial     pick left (hold)     turn (hold)           pick right (hold)     -
 *
 * On the rake, button 1 is RAKE rather than a direction.
 *
 * Arguments:
 * 0: Input - "left", "hold", "right" or "rake" <STRING>
 * 1: Pressed (true) or released (false) <BOOL>
 * 2: From a button rather than a key <BOOL> (default: false)
 *
 * Return Value:
 * None
 */

params ["_input", "_down", ["_mouse", false]];

private _state = uiNamespace getVariable ["tlbi_lockpick_state", createHashMap];

if (count _state == 0 || {_state getOrDefault ["done", false]}) exitWith {};

private _source = ["key", "mouse"] select _mouse;

switch (_input) do {
    case "rake": {
        if (_down) then { _state set ["rakeEdge", (_state getOrDefault ["rakeEdge", 0]) + 1] };
    };
    default {
        _state set [format ["%1_%2", _input, _source], _down];

        // Pin selection steps once per press rather than while held.
        if (_down && {_input in ["left", "right"]}) then {
            _state set [format ["%1Edge", _input], (_state getOrDefault [format ["%1Edge", _input], 0]) + 1];
        };
    };
};
