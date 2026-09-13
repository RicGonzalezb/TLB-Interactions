#include "..\script_component.hpp"
/*
 * Author: TLB
 * Selects a firing device on the tripwire as the target for SEAT PIN.
 *
 * Arguments:
 * 0: Device index <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_index"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

if (count _trip <= TR_SLIPS) exitWith {};
if ((_trip select TR_STAGE) != TSTAGE_WORK) exitWith {};
if (((_trip select TR_FUZES) select _index) select 2) exitWith {};

uiNamespace setVariable ["tlbi_defusal_selectedFuze", _index];

[] call tlbi_defusal_fnc_refreshBoard;
