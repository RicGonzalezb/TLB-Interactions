#include "..\script_component.hpp"
/*
 * Author: TLB
 * The item a unit would pick with, for one kind of tool.
 *
 * tsp_breach's "Lock Pick Kit" and "Paperclip" are the standard tools. Our own
 * stand-ins from tlbi_lockpick_items count too - they are what players get
 * when tsp_breach is not loaded. ACE's vehicle "Lockpick" counts as a kit when
 * the setting allows it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: TOOL_KIT or TOOL_CLIP <NUMBER>
 *
 * Return Value:
 * Item class name, or "" when the unit has none <STRING>
 */

params ["_unit", "_tool"];

private _items = _unit call ace_common_fnc_uniqueItems;

private _candidates = [
    ["tsp_lockpick", "tlbi_lockpickKit"] + ([[], ["ACE_key_lockpick"]] select tlbi_lockpick_aceLockpick),
    ["tsp_paperclip", "tlbi_paperclip"]
] select _tool;

private _index = _candidates findIf {_x in _items};

// Not ["", _candidates select _index] select ...: both elements are evaluated,
// and select -1 is an error when the unit has no tool.
if (_index == -1) exitWith { "" };

_candidates select _index
