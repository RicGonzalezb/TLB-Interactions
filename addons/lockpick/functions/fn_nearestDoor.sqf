#include "..\script_component.hpp"
/*
 * Author: TLB
 * The door whose handle is nearest a position, within 4 m.
 *
 * Arguments:
 * 0: Position ASL <ARRAY>
 *
 * Return Value:
 * [house, door selection name, door number], or [] <ARRAY>
 */

params ["_position"];

private _where = ASLToAGL _position;
private _found = [];
private _nearest = 4;

{
    private _house = _x;

    {
        _x params ["_id", "_door", "_point"];

        private _relative = [0, 0, 0];
        if (_point != "") then { _relative = _house selectionPosition [_point, "Memory"] };
        if (_relative isEqualTo [0, 0, 0]) then { _relative = _house selectionPosition [_door, "Geometry", "AveragePoint"] };

        if !(_relative isEqualTo [0, 0, 0]) then {
            private _distance = (_house modelToWorld _relative) distance _where;
            if (_distance < _nearest) then {
                _nearest = _distance;
                _found = [_house, _door, _id];
            };
        };
    } forEach ([_house] call tlbi_lockpick_fnc_doors);
} forEach nearestObjects [_where, ["House"], 30];

_found
