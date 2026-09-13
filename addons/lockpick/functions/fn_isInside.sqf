#include "..\script_component.hpp"
/*
 * Author: TLB
 * Whether a unit is inside a building: its own roof is somewhere above the
 * unit's head. Locking and unlocking a door by hand only works from that side.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: House <OBJECT>
 *
 * Return Value:
 * Inside <BOOL>
 */

params ["_unit", "_house"];

private _from = eyePos _unit;
private _hits = lineIntersectsSurfaces [_from, _from vectorAdd [0, 0, 30], _unit, objNull, true, 3, "GEOM", "NONE"];

(_hits findIf {(_x select 2) == _house || {(_x select 3) == _house}}) != -1
