#include "..\script_component.hpp"
/*
 * Author: TLB
 * Zeus Lock settings (Zeus Enhanced): configures the door whose handle is nearest
 * the position. Used by the Zeus module and by the Zeus context menu entry.
 *
 * The lock state is applied straight away. The other options are stored on the
 * building for that door and override any Eden module covering it; they are read
 * the next time the lock is picked.
 *
 * Arguments:
 * 0: Module position ASL <ARRAY>
 * 1: Attached object <OBJECT>
 *
 * Return Value:
 * None
 */

params ["_position", ["_object", objNull]];

private _found = [_position] call tlbi_lockpick_fnc_nearestDoor;

if (_found isEqualTo []) exitWith {
    [localize "STR_tlbi_zeus_noDoor"] call zen_common_fnc_showMessage;
};

_found params ["_house", "_door"];

// Stored order: Pickable, Technique, DoorClass, KitLevel, ClipLevel.
private _stored = _house getVariable [[_door] call tlbi_lockpick_fnc_doorKey, []];

private _fnc_row = {
    params ["_index", "_label", "_tip", "_values", "_labels"];
    private _current = _stored param [_index, -1];
    ["COMBO", [localize _label, localize _tip], [_values, _labels apply {localize _x}, (_values find _current) max 0]]
};

private _useSettings = "STR_tlbi_module_useSettings";
private _levels = [_useSettings, "STR_tlbi_lockpick_level_0", "STR_tlbi_lockpick_level_1", "STR_tlbi_lockpick_level_2", "STR_tlbi_lockpick_level_3", "STR_tlbi_lockpick_level_4"];

[
    localize "STR_tlbi_lockpick_module_name",
    [
        ["COMBO", [localize "STR_tlbi_lockpick_module_lockState", localize "STR_tlbi_zeus_lockState_tip"],
            [[-1, 1, 0], ["STR_tlbi_lockpick_module_lockState_leave", "STR_tlbi_lockpick_module_lockState_locked", "STR_tlbi_lockpick_module_lockState_unlocked"] apply {localize _x}, 0]],
        [0, "STR_tlbi_lockpick_module_pickable", "STR_tlbi_lockpick_module_pickable_tip", [-1, 1, 0],
            [_useSettings, "STR_tlbi_module_yes", "STR_tlbi_module_no"]] call _fnc_row,
        [1, "STR_tlbi_lockpick_module_technique", "STR_tlbi_lockpick_module_technique_tip", [-1, 0, 1, 2],
            ["STR_tlbi_lockpick_module_technique_random", "STR_tlbi_lockpick_module_technique_pins", "STR_tlbi_lockpick_module_technique_rake", "STR_tlbi_lockpick_module_technique_dial"]] call _fnc_row,
        [2, "STR_tlbi_lockpick_module_doorClass", "STR_tlbi_lockpick_module_doorClass_tip", [-1, 0, 1, 2],
            ["STR_tlbi_lockpick_module_doorClass_building", "STR_tlbi_lockpick_door_civil", "STR_tlbi_lockpick_door_military", "STR_tlbi_lockpick_door_reinforced"]] call _fnc_row,
        [3, "STR_tlbi_lockpick_set_levelKit", "STR_tlbi_lockpick_module_level_tip", [-1, 0, 1, 2, 3, 4], _levels] call _fnc_row,
        [4, "STR_tlbi_lockpick_set_levelClip", "STR_tlbi_lockpick_module_level_tip", [-1, 0, 1, 2, 3, 4], _levels] call _fnc_row
    ],
    {
        params ["_values", "_args"];
        _args params ["_house", "_door", "_id"];

        if (isNull _house) exitWith {};

        _values params ["_lockState", "_pickable", "_technique", "_doorClass", "_kitLevel", "_clipLevel"];

        if (_lockState >= 0) then {
            _house setVariable [format ["bis_disabled_Door_%1", _id], _lockState, true];
            _house setVariable [format ["bis_disabled_%1", _door], _lockState, true];
        };

        _house setVariable [[_door] call tlbi_lockpick_fnc_doorKey, [_pickable, _technique, _doorClass, _kitLevel, _clipLevel], true];

        [localize "STR_tlbi_zeus_lockApplied"] call zen_common_fnc_showMessage;
    },
    {},
    _found
] call zen_dialog_fnc_create;
