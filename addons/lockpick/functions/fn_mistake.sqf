#include "..\script_component.hpp"
/*
 * Author: TLB
 * Something slipped: an overset pin, raking against too much tension, or
 * forcing the plug past the sweet spot.
 *
 * Progress is lost either way - set pins drop, the plug springs back. A lock
 * pick kit is never used up. A paperclip bends; past the allowed bends it
 * snaps, is removed from the inventory and the attempt ends.
 *
 * Arguments:
 * 0: Reason message <STRING>
 *
 * Return Value:
 * None
 */

params ["_reason"];

private _state = uiNamespace getVariable ["tlbi_lockpick_state", createHashMap];

if (count _state == 0 || {_state getOrDefault ["done", false]}) exitWith {};

private _unit = _state get "unit";

// Reset progress for whichever technique is running.
switch (_state get "tech") do {
    case TECH_DIAL: {
        _state set ["turn", 0];
        _state set ["strain", 0];
    };
    default {
        private _n = _state get "n";
        private _zero = [];
        private _false = [];
        for "_i" from 1 to _n do { _zero pushBack 0; _false pushBack false };
        _state set ["h", _zero];
        _state set ["set", +_false];
        _state set ["tension", 0];
    };
};

playSound "ACE_Sound_Click_10db";

if ((_state get "tool") == TOOL_KIT) exitWith {
    [format ["%1 %2", _reason, localize "STR_tlbi_lockpick_msg_kit_slip"]] call tlbi_lockpick_fnc_setStatus;
};

private _bends = (_unit getVariable ["tlbi_lockpick_bends", 0]) + 1;
private _limit = round tlbi_lockpick_clipBends;

if (_bends > _limit) exitWith {
    _unit setVariable ["tlbi_lockpick_bends", 0];
    _unit removeItem (_state get "item");
    _state set ["done", true];

    [format ["%1 %2", _reason, localize "STR_tlbi_lockpick_msg_clip_snap"]] call ace_common_fnc_displayTextStructured;
    (uiNamespace getVariable ["tlbi_lockpick_display", displayNull]) closeDisplay 2;
};

_unit setVariable ["tlbi_lockpick_bends", _bends];

[format ["%1 %2", _reason, format [localize "STR_tlbi_lockpick_msg_clip_bend", _bends, _limit + 1]]] call tlbi_lockpick_fnc_setStatus;
