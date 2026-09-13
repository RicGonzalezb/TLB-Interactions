#include "..\script_component.hpp"
/*
 * Author: TLB
 * Commits to the selected clamp. Once this starts there is no backing out - the
 * board refuses Escape while busy and the resolution runs even if the display
 * is torn down some other way.
 *
 * Return Value:
 * None
 */

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _wire = uiNamespace getVariable ["tlbi_defusal_selected", -1];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (_puzzle isEqualTo []) exitWith {};
if ((_puzzle select PZ_STAGE) != STAGE_TEST) exitWith {};

if (_wire < 0) exitWith {
    [localize "STR_tlbi_defusal_msg_no_selection"] call tlbi_defusal_fnc_setStatus;
};

if (_wire in (_puzzle select PZ_DEADENDS)) exitWith {
    [localize "STR_tlbi_defusal_msg_already_cut"] call tlbi_defusal_fnc_setStatus;
};

[tlbi_defusal_cutTime, format [localize "STR_tlbi_defusal_progress_cut", _wire + 1], {
    private _unit = uiNamespace getVariable ["tlbi_defusal_unit", objNull];
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _wire = uiNamespace getVariable ["tlbi_defusal_selected", -1];
    private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

    if (_puzzle isEqualTo [] || {_wire < 0} || {isNull _explosive}) exitWith {};
    if (uiNamespace getVariable ["tlbi_defusal_resolved", false]) exitWith {};

    if (_wire == (_puzzle select PZ_LIVE)) exitWith {
        [_unit, _explosive] call tlbi_defusal_fnc_succeed;
    };

    [_unit, _explosive, false] call tlbi_defusal_fnc_fail;
}] call tlbi_defusal_fnc_runAction;
