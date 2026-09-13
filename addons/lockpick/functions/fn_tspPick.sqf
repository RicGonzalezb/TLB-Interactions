#include "..\script_component.hpp"
/*
 * Author: TLB
 * Replacement for tsp_fnc_breach_pick, installed by fn_postInit. tsp_breach's
 * "Use Lockpick" / "Use Paperclip" door actions call this with their own door
 * data; instead of a progress bar and a dice roll it opens the board, and on
 * success unlocks through fn_unlock, which plays tsp_breach's unlock sound.
 *
 * tsp_breach's own paperclip loss (it deletes the clip 75% of the time before
 * picking starts) is not applied - bending and snapping on mistakes replaces it.
 *
 * Arguments (tsp_breach's):
 * 0: Unit <OBJECT>
 * 1: Door data <ARRAY> - [id, house, door, pos, animName, animPhase, locked, ...]
 * 2: Delete chance <NUMBER>
 * 3: Item class <STRING>
 * 4: Chance table <ARRAY>
 *
 * Return Value:
 * None
 */

params ["_unit", "_data", "_deleteChance", "_item", "_damage"];

if (!(missionNamespace getVariable ["tlbi_lockpick_enabled", true]) || {!tlbi_lockpick_takeOverTsp}) exitWith {
    _this call tlbi_lockpick_tspOriginal;
};

_data params ["_id", "_house", "_door"];

private _tool = [TOOL_CLIP, TOOL_KIT] select (_item == "tsp_lockpick");

if (([_house, _door] call tlbi_lockpick_fnc_doorClass) == DOOR_GLASS) exitWith {
    [localize "STR_tlbi_lockpick_msg_glass"] call ace_common_fnc_displayTextStructured;
};

[
    _unit, _house, _door, _tool, _item,
    tlbi_lockpick_fnc_unlock,
    [_house, _door, _id]
] call tlbi_lockpick_fnc_start;
