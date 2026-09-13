#include "..\script_component.hpp"
/*
 * Author: TLB
 * Feels the wire for tension. Taut means a tension-release fuze - cutting it
 * before every device is pinned fires it. Slack means a pull fuze - it must not
 * be pulled, but cutting it is safe.
 *
 * Return Value:
 * None
 */

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

if (count _trip <= TR_SLIPS) exitWith {};
if ((_trip select TR_STAGE) != TSTAGE_WORK) exitWith {};
if ((_trip select TR_TENSION) != -1) exitWith {};

[tlbi_defusal_tensionTime, localize "STR_tlbi_defusal_progress_tension", {
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

    if (count _trip <= TR_SLIPS) exitWith {};

    private _taut = _trip select TR_TAUT;
    _trip set [TR_TENSION, [0, 1] select _taut];

    _explosive setVariable ["tlbi_defusal_trip", _trip, true];
    [] call tlbi_defusal_fnc_refreshBoard;

    [localize (["STR_tlbi_defusal_trip_msg_slack", "STR_tlbi_defusal_trip_msg_taut"] select _taut)] call tlbi_defusal_fnc_setStatus;
}] call tlbi_defusal_fnc_runAction;
