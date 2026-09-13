#include "..\script_component.hpp"
/*
 * Author: TLB
 * Cuts one strip of tape away from the wiring. When the last strip is gone the
 * conductors can be reached and the meter comes out.
 *
 * Arguments:
 * 0: Tape strip index <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_index"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (_puzzle isEqualTo []) exitWith {};
if ((_puzzle select PZ_STAGE) != STAGE_TAPE) exitWith {};
if !(((_puzzle select PZ_TAPE) select _index) select TP_INTACT) exitWith {};

uiNamespace setVariable ["tlbi_defusal_target", _index];

[CLEAR_TIME(tlbi_defusal_tapeTime), localize "STR_tlbi_defusal_progress_tape", {
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _index = uiNamespace getVariable ["tlbi_defusal_target", -1];
    private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

    if (_puzzle isEqualTo [] || {_index < 0}) exitWith {};

    private _tape = +(_puzzle select PZ_TAPE);
    private _strip = +(_tape select _index);
    _strip set [TP_INTACT, false];
    _tape set [_index, _strip];
    _puzzle set [PZ_TAPE, _tape];

    private _exposed = (_tape findIf {_x select TP_INTACT}) == -1;

    if (_exposed) then {
        _puzzle set [PZ_STAGE, STAGE_TEST];
    };

    _explosive setVariable ["tlbi_defusal_puzzle", _puzzle, true];

    [] call tlbi_defusal_fnc_refreshBoard;

    if (_exposed) then {
        [localize "STR_tlbi_defusal_msg_exposed"] call tlbi_defusal_fnc_setStatus;
    };
}] call tlbi_defusal_fnc_runAction;
