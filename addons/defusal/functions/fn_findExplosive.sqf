#include "..\script_component.hpp"
/*
 * Author: TLB
 * The explosive a Zeus is pointing at: the given object if it is one, otherwise
 * the nearest explosive within 3 m of the position.
 *
 * Arguments:
 * 0: Position ASL <ARRAY>
 * 1: Object under the cursor or attached to a module <ANY> (default: objNull)
 *
 * Return Value:
 * Explosive, or objNull <OBJECT>
 */

params ["_position", ["_object", objNull]];

if (_object isEqualType objNull && {!isNull _object} && {_object in allMines}) exitWith { _object };

private _where = ASLToAGL _position;
private _near = allMines select {_x distance _where < 3};

if (_near isEqualTo []) exitWith { objNull };

([_near, [], {_x distance _where}, "ASCEND"] call BIS_fnc_sortBy) select 0
