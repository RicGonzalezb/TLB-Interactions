#include "..\script_component.hpp"
/*
 * Author: TLB
 * How hard a door is to pick.
 *
 * Glass doors cannot be picked. Reinforced and military buildings are matched
 * against our CBA lists (class names, "*" suffix for a prefix match) and, when
 * tsp_breach is loaded, against its own building lists too - so one set of
 * classifications drives both mods.
 *
 * Arguments:
 * 0: House <OBJECT>
 * 1: Door selection name <STRING>
 *
 * Return Value:
 * DOOR_* <NUMBER>
 */

params ["_house", "_door"];

if ((toLower _door find "glass") != -1) exitWith { DOOR_GLASS };

private _type = toLower typeOf _house;

private _fnc_matches = {
    params ["_setting", "_tspVariable"];

    private _entries = ((missionNamespace getVariable [_setting, ""]) splitString (", ;" + toString [9, 10, 13])) apply {toLower _x};
    private _tsp = missionNamespace getVariable [_tspVariable, []];
    if (_tsp isEqualType []) then { _entries append ((_tsp select {_x isEqualType ""}) apply {toLower _x}) };

    (_entries findIf {
        if ((_x select [count _x - 1]) == "*") then {
            (_type find (_x select [0, count _x - 1])) == 0
        } else {
            _x == _type
        }
    }) != -1
};

if (["tlbi_lockpick_classesReinforced", "tsp_cba_breach_reinforced"] call _fnc_matches) exitWith { DOOR_REINFORCED };
if (["tlbi_lockpick_classesMilitary", "tsp_cba_breach_military"] call _fnc_matches) exitWith { DOOR_MILITARY };

DOOR_CIVIL
