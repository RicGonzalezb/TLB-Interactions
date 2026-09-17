#include "..\script_component.hpp"
/*
 * Author: TLB
 * Zeus Explosive settings module (Zeus Enhanced): configures one explosive.
 *
 * The values are stored on the explosive and override any Eden module covering
 * it. Difficulty and auto-clear apply the next time its board opens; procedure,
 * burial, grass and branch shape the device when it is built, so "Rebuild the
 * device" starts it again with the new values.
 *
 * Arguments:
 * 0: Module position ASL <ARRAY>
 * 1: Attached object <OBJECT>
 *
 * Return Value:
 * None
 */

params ["_position", ["_object", objNull]];

private _explosive = objNull;

if (!isNull _object && {_object in allMines}) then {
    _explosive = _object;
} else {
    private _where = ASLToAGL _position;
    private _near = allMines select {_x distance _where < 3};
    _near = [_near, [], {_x distance _where}, "ASCEND"] call BIS_fnc_sortBy;
    _explosive = _near param [0, objNull];
};

if (isNull _explosive) exitWith {
    [localize "STR_tlbi_zeus_noExplosive"] call zen_common_fnc_showMessage;
};

private _fnc_row = {
    params ["_name", "_label", "_tip", "_values", "_labels"];
    private _current = _explosive getVariable ["tlbi_defusal_zeus_" + _name, -1];
    ["COMBO", [localize _label, localize _tip], [_values, _labels apply {localize _x}, (_values find _current) max 0]]
};

private _useSettings = "STR_tlbi_module_useSettings";

[
    localize "STR_tlbi_defusal_module_name",
    [
        ["Procedure", "STR_tlbi_defusal_module_procedure", "STR_tlbi_defusal_module_procedure_tip", [-1, 0, 1, 2],
            ["STR_tlbi_defusal_module_procedure_auto", "STR_tlbi_defusal_module_procedure_ied", "STR_tlbi_defusal_module_procedure_mine", "STR_tlbi_defusal_module_procedure_trip"]] call _fnc_row,
        ["Difficulty", "STR_tlbi_defusal_set_difficulty", "STR_tlbi_defusal_module_difficulty_tip", [-1, 0, 1, 2, 3],
            [_useSettings, "STR_tlbi_difficulty_easy", "STR_tlbi_difficulty_normal", "STR_tlbi_difficulty_hard", "STR_tlbi_difficulty_expert"]] call _fnc_row,
        ["Buried", "STR_tlbi_defusal_module_buried", "STR_tlbi_defusal_module_buried_tip", [-1, 1, 0],
            [_useSettings, "STR_tlbi_defusal_module_buried_yes", "STR_tlbi_defusal_module_buried_no"]] call _fnc_row,
        ["Grass", "STR_tlbi_defusal_module_grass", "STR_tlbi_defusal_module_grass_tip", [-1, 1, 0],
            [_useSettings, "STR_tlbi_defusal_module_grass_yes", "STR_tlbi_defusal_module_grass_no"]] call _fnc_row,
        ["Branch", "STR_tlbi_defusal_module_branch", "STR_tlbi_defusal_module_branch_tip", [-1, 1, 0],
            [_useSettings, "STR_tlbi_defusal_module_branch_always", "STR_tlbi_defusal_module_branch_never"]] call _fnc_row,
        ["AutoClear", "STR_tlbi_defusal_set_autoClear", "STR_tlbi_defusal_module_autoClear_tip", [-1, 1, 0],
            [_useSettings, "STR_tlbi_module_on", "STR_tlbi_module_off"]] call _fnc_row,
        ["CHECKBOX", [localize "STR_tlbi_zeus_rebuild", localize "STR_tlbi_zeus_rebuild_tip"], true]
    ],
    {
        params ["_values", "_explosive"];

        if (isNull _explosive) exitWith {};

        {
            _explosive setVariable ["tlbi_defusal_zeus_" + _x, _values select _forEachIndex, true];
        } forEach ["Procedure", "Difficulty", "Buried", "Grass", "Branch", "AutoClear"];

        if (_values select 6) then {
            {
                _explosive setVariable [_x, nil, true];
            } forEach ["tlbi_defusal_puzzle", "tlbi_defusal_mine", "tlbi_defusal_trip", "tlbi_defusal_elapsed"];
        };

        [localize "STR_tlbi_zeus_explosiveApplied"] call zen_common_fnc_showMessage;
    },
    {},
    _explosive
] call zen_dialog_fnc_create;
