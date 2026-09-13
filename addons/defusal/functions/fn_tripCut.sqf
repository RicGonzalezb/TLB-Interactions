#include "..\script_component.hpp"
/*
 * Author: TLB
 * Cuts the tripwire. On a taut wire with any device still unpinned, that
 * releases the striker. Otherwise the device is safe.
 *
 * Return Value:
 * None
 */

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

if (count _trip <= TR_SLIPS) exitWith {};
if ((_trip select TR_STAGE) != TSTAGE_WORK) exitWith {};

[tlbi_defusal_cutTime, localize "STR_tlbi_defusal_progress_cutwire", {
    private _unit = uiNamespace getVariable ["tlbi_defusal_unit", objNull];
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

    if (count _trip <= TR_SLIPS || {isNull _explosive}) exitWith {};
    if (uiNamespace getVariable ["tlbi_defusal_resolved", false]) exitWith {};

    private _unpinned = ((_trip select TR_FUZES) findIf {!(_x select 2)}) != -1;

    if ((_trip select TR_TAUT) && {_unpinned}) exitWith {
        [localize "STR_tlbi_defusal_trip_msg_cut_fired"] call ace_common_fnc_displayTextStructured;
        [_unit, _explosive, true] call tlbi_defusal_fnc_fail;
    };

    [_unit, _explosive] call tlbi_defusal_fnc_succeed;
}] call tlbi_defusal_fnc_runAction;
