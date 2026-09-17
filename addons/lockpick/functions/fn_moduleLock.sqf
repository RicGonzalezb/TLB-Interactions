#include "..\script_component.hpp"
/*
 * Author: TLB
 * Init function of the Lock settings module, on the server.
 *
 * Locks or unlocks every door whose handle is inside the module's area. It
 * waits a few seconds first, so random door locking (ours or tsp_breach's) has
 * already run and the module has the last word. The other options (technique,
 * door class, difficulty, pickable) are read when a lock is picked, by fn_start.
 *
 * Arguments:
 * 0: Module <OBJECT>
 *
 * Return Value:
 * True <BOOL>
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith { true };

// This module's own value, not the smallest overlapping module's.
private _state = _logic getVariable ["LockState", _logic getVariable ["tlbi_moduleLock_LockState", -1]];
if (_state isEqualType "") then { _state = parseNumber _state };

if (!(_state isEqualType 0) || {_state < 0}) exitWith { true };

[{
    params ["_logic", "_state"];

    (_logic getVariable ["objectArea", [5, 5, 0, false, -1]]) params [["_a", 5], ["_b", 5], ["_angle", 0], ["_rectangle", false]];
    private _center = getPos _logic;
    private _count = 0;

    {
        private _house = _x;

        {
            _x params ["_id", "_door", "_point"];

            private _relative = [0, 0, 0];
            if (_point != "") then { _relative = _house selectionPosition [_point, "Memory"] };
            if (_relative isEqualTo [0, 0, 0]) then { _relative = _house selectionPosition [_door, "Geometry", "AveragePoint"] };

            if (!(_relative isEqualTo [0, 0, 0]) && {(_house modelToWorld _relative) inArea [_center, _a, _b, _angle, _rectangle]}) then {
                _house setVariable [format ["bis_disabled_Door_%1", _id], _state, true];
                _house setVariable [format ["bis_disabled_%1", _door], _state, true];
                _count = _count + 1;
            };
        } forEach ([_house] call tlbi_lockpick_fnc_doors);
    } forEach nearestObjects [_center, ["House"], (_a max _b) * 1.5 + 25];

    diag_log text format ["[TLB Interactions] Lock settings module %1 %2 door(s) at %3",
        ["unlocked", "locked"] select (_state == 1), _count, _center];
}, [_logic, _state], 5] call CBA_fnc_waitAndExecute;

true
