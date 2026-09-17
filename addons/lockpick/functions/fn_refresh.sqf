#include "..\script_component.hpp"
/*
 * Author: TLB
 * Sets the board's static text for the running technique: title, a subtitle
 * naming the door, the tool and the technique, the button labels and the
 * how-to line.
 *
 * Return Value:
 * None
 */

private _display = uiNamespace getVariable ["tlbi_lockpick_display", displayNull];
private _state = uiNamespace getVariable ["tlbi_lockpick_state", createHashMap];

if (isNull _display || {count _state == 0}) exitWith {};

private _tech = _state get "tech";
private _tool = _state get "tool";

(_display displayCtrl IDC_LP_TITLE) ctrlSetText localize "STR_tlbi_lockpick_title";

(_display displayCtrl IDC_LP_SUBTITLE) ctrlSetText format [
    localize "STR_tlbi_lockpick_subtitle",
    localize (["STR_tlbi_lockpick_door_civil", "STR_tlbi_lockpick_door_military", "STR_tlbi_lockpick_door_reinforced"] select (_state get "class")),
    localize (["STR_tlbi_lockpick_tool_kit", "STR_tlbi_lockpick_tool_clip"] select _tool),
    _state get "n"
];

(_display displayCtrl IDC_LP_STAGE) ctrlSetText localize (["STR_tlbi_lockpick_tech_pins", "STR_tlbi_lockpick_tech_rake", "STR_tlbi_lockpick_tech_dial"] select _tech);

private _labels = [
    ["STR_tlbi_lockpick_btn_prevpin", "STR_tlbi_lockpick_btn_lift", "STR_tlbi_lockpick_btn_nextpin"],
    ["STR_tlbi_lockpick_btn_rake", "STR_tlbi_lockpick_btn_tension", ""],
    ["STR_tlbi_lockpick_btn_pickleft", "STR_tlbi_lockpick_btn_turn", "STR_tlbi_lockpick_btn_pickright"]
] select _tech;

{
    private _button = _display displayCtrl _x;
    private _key = _labels select _forEachIndex;

    _button ctrlSetText ([localize _key, ""] select (_key == ""));
    _button ctrlEnable (_key != "");
} forEach [IDC_LP_BTN_A1, IDC_LP_BTN_A2, IDC_LP_BTN_A3];

[format [
    localize (["STR_tlbi_lockpick_help_pins", "STR_tlbi_lockpick_help_rake", "STR_tlbi_lockpick_help_dial"] select _tech),
    ["tlbi_lockpick_left"] call tlbi_defusal_fnc_keyName,
    ["tlbi_lockpick_right"] call tlbi_defusal_fnc_keyName,
    ["tlbi_lockpick_hold"] call tlbi_defusal_fnc_keyName,
    ["tlbi_lockpick_rake"] call tlbi_defusal_fnc_keyName
]] call tlbi_lockpick_fnc_setStatus;
