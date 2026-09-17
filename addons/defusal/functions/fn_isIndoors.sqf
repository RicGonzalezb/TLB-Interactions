#include "..\script_component.hpp"
/*
 * Author: TLB
 * Whether an object is inside a building: something that is a building sits
 * straight above it.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value:
 * Indoors <BOOL>
 */

params [["_object", objNull, [objNull]]];

if (isNull _object) exitWith { false };

private _from = (getPosASL _object) vectorAdd [0, 0, 0.3];
private _hits = lineIntersectsSurfaces [_from, _from vectorAdd [0, 0, 25], _object, objNull, true, 1, "GEOM", "NONE"];

(_hits findIf {
    private _hit = _x select 3;
    if (isNull _hit) then { _hit = _x select 2 };
    !isNull _hit && {_hit isKindOf "House"}
}) != -1
