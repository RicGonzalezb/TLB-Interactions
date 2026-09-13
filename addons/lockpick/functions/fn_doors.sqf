#include "..\script_component.hpp"
/*
 * Author: TLB
 * The doors of a building, read from its UserActions config and cached per
 * class.
 *
 * Every building whose doors open from the action menu declares them there: an
 * open and a close action per door, the memory point the action sits at, a
 * condition saying whether it applies and a statement that works the door.
 * Driving doors through those means a building from any terrain or mod opens
 * the way its author made it. Actions are grouped by the number in their class
 * name (OpenDoor_1 / CloseDoor_1); a door with a single toggle action gets it as
 * both open and close.
 *
 * Arguments:
 * 0: House <OBJECT>
 *
 * Return Value:
 * [[id, doorName, memoryPoint, openCondition, openStatement, closeCondition, closeStatement], ...] <ARRAY>
 */

params ["_house"];

private _type = typeOf _house;

if (isNil "tlbi_lockpick_doorCache") then { tlbi_lockpick_doorCache = createHashMap };

private _cached = tlbi_lockpick_doorCache get _type;
if (!isNil "_cached") exitWith { _cached };

private _byId = createHashMap;

{
    private _class = configName _x;
    private _lower = toLower _class;

    if ((_lower find "door") != -1) then {
        private _digits = ((_class splitString "") select {_x in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]}) joinString "";

        if (_digits != "") then {
            private _id = parseNumber _digits;
            private _entry = _byId getOrDefault [_id, [_id, format ["Door_%1", _id], "", "", "", "", ""]];

            private _named = getText (_x >> "actionNamedSel");
            if (_named != "") then { _entry set [1, _named] };
            if ((_entry select 2) == "") then { _entry set [2, getText (_x >> "position")] };

            private _condition = getText (_x >> "condition");
            private _statement = getText (_x >> "statement");

            if ((_lower find "close") != -1) then {
                _entry set [5, _condition];
                _entry set [6, _statement];
            } else {
                _entry set [3, _condition];
                _entry set [4, _statement];
            };

            _byId set [_id, _entry];
        };
    };
} forEach configProperties [configOf _house >> "UserActions", "isClass _x", true];

private _doors = values _byId;
_doors sort true;

tlbi_lockpick_doorCache set [_type, _doors];

_doors
