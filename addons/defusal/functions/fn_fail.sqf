#include "..\script_component.hpp"
/*
 * Author: TLB
 * Wrong wire, or the anti-tamper clock ran out.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Explosive <OBJECT>
 * 2: Caused by the timer rather than a cut <BOOL> (default: false)
 *
 * Return Value:
 * None
 */

params ["_unit", "_explosive", ["_timedOut", false]];

private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];
private _wire = uiNamespace getVariable ["tlbi_defusal_selected", -1];

// A surviveable mistake: the wire was a dead end, not the collapsing circuit.
if (!_timedOut && {!(_puzzle isEqualTo [])} && {(_puzzle select PZ_STRIKES) > 0} && {_wire >= 0}) exitWith {
    private _deadends = +(_puzzle select PZ_DEADENDS);
    _deadends pushBackUnique _wire;

    // The conductor is simply gone. Its meter readings are left untouched -
    // surviving the cut proves it was not the firing line, not what it read.
    _puzzle set [PZ_DEADENDS, _deadends];
    _puzzle set [PZ_STRIKES, (_puzzle select PZ_STRIKES) - 1];
    _explosive setVariable ["tlbi_defusal_puzzle", _puzzle, true];

    uiNamespace setVariable ["tlbi_defusal_selected", -1];

    playSound3D [SND_TONE, objNull, false, getPosASL _explosive, 0.6, 2, 12];

    [] call tlbi_defusal_fnc_refreshBoard;
    [localize "STR_tlbi_defusal_msg_strike"] call tlbi_defusal_fnc_setStatus;
};

uiNamespace setVariable ["tlbi_defusal_resolved", true];

{
    _explosive setVariable [_x, nil, true];
} forEach ["tlbi_defusal_puzzle", "tlbi_defusal_mine", "tlbi_defusal_trip", "tlbi_defusal_elapsed"];

(uiNamespace getVariable ["tlbi_defusal_display", displayNull]) closeDisplay 2;

private _fuse = 0;

if (tlbi_defusal_failureMode == FAILURE_COUNTDOWN && {!_timedOut}) then {
    _fuse = 0.5 max tlbi_defusal_countdownTime;

    playSound3D [SND_ARMED, objNull, false, getPosASL _explosive, 4, 1, 60];

    [localize "STR_tlbi_defusal_msg_armed"] call ace_common_fnc_displayTextStructured;
};

[_unit, -1, [_explosive, _fuse], "#tlbi_defusal_wrongWire"] call ace_explosives_fnc_detonateExplosive;
