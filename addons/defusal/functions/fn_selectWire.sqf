#include "..\script_component.hpp"
/*
 * Author: TLB
 * Clips the meter to a conductor by its tag. Only possible once the tape is off
 * and the wiring can actually be reached.
 *
 * Arguments:
 * 0: Wire index <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_wire"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (_puzzle isEqualTo []) exitWith {};
if ((_puzzle select PZ_STAGE) != STAGE_TEST) exitWith {};
if (_wire in (_puzzle select PZ_DEADENDS)) exitWith {};

uiNamespace setVariable ["tlbi_defusal_selected", _wire];

[] call tlbi_defusal_fnc_refreshBoard;
