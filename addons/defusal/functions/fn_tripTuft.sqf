#include "..\script_component.hpp"
/*
 * Author: TLB
 * Parts one tuft of grass. Once every tuft over a wire has been parted, the
 * wire is traced end to end and the number of devices on it is known.
 *
 * Arguments:
 * 0: Tuft index <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_index"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

if (count _trip <= TR_SLIPS) exitWith {};
if (((_trip select TR_TUFTS) select _index) select TF_CLEARED) exitWith {};

uiNamespace setVariable ["tlbi_defusal_target", _index];

[CLEAR_TIME(tlbi_defusal_grassTime), localize "STR_tlbi_defusal_progress_grass", {
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _index = uiNamespace getVariable ["tlbi_defusal_target", -1];
    private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

    if (count _trip <= TR_SLIPS || {_index < 0}) exitWith {};

    private _tufts = +(_trip select TR_TUFTS);
    private _tuft = +(_tufts select _index);
    _tuft set [TF_CLEARED, true];
    _tufts set [_index, _tuft];
    _trip set [TR_TUFTS, _tufts];

    // Parting grass is allowed at any stage (a stray tuft can sit on a device),
    // but only completes the trace while tracing.
    private _traced = (_trip select TR_STAGE) == TSTAGE_TRACE
        && {(_tufts findIf {(_x select TF_ONPATH) && {!(_x select TF_CLEARED)}}) == -1};

    if (_traced) then {
        _trip set [TR_STAGE, TSTAGE_WORK];
    };

    _explosive setVariable ["tlbi_defusal_trip", _trip, true];
    [] call tlbi_defusal_fnc_refreshBoard;

    if (_traced) then {
        [format [localize "STR_tlbi_defusal_trip_msg_traced", count (_trip select TR_FUZES)]] call tlbi_defusal_fnc_setStatus;
    };
}] call tlbi_defusal_fnc_runAction;
