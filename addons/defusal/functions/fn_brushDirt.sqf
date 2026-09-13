#include "..\script_component.hpp"
/*
 * Author: TLB
 * Brushes one soil clump off the device. Each clump takes two passes; once the
 * last one is gone the procedure moves on to the tape.
 *
 * Arguments:
 * 0: Clump index <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_index"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (_puzzle isEqualTo []) exitWith {};
if ((_puzzle select PZ_STAGE) != STAGE_EXCAVATE) exitWith {};
if ((((_puzzle select PZ_DIRT) select _index) select DT_HP) <= 0) exitWith {};

uiNamespace setVariable ["tlbi_defusal_target", _index];

[CLEAR_TIME(tlbi_defusal_dirtTime), localize "STR_tlbi_defusal_progress_brush", {
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _index = uiNamespace getVariable ["tlbi_defusal_target", -1];
    private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

    if (_puzzle isEqualTo [] || {_index < 0}) exitWith {};

    private _dirt = +(_puzzle select PZ_DIRT);
    private _clump = +(_dirt select _index);
    _clump set [DT_HP, ((_clump select DT_HP) - 1) max 0];
    _dirt set [_index, _clump];
    _puzzle set [PZ_DIRT, _dirt];

    private _cleared = (_dirt findIf {(_x select DT_HP) > 0}) == -1;

    if (_cleared) then {
        _puzzle set [PZ_STAGE, STAGE_TAPE];
    };

    _explosive setVariable ["tlbi_defusal_puzzle", _puzzle, true];

    [] call tlbi_defusal_fnc_refreshBoard;

    if (_cleared) then {
        [localize "STR_tlbi_defusal_msg_uncovered"] call tlbi_defusal_fnc_setStatus;
    };
}] call tlbi_defusal_fnc_runAction;
