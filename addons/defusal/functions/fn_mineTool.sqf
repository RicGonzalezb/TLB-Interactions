#include "..\script_component.hpp"
/*
 * Author: TLB
 * Picks up the prod or the trowel. Clicking a soil cell then uses whichever is
 * in hand.
 *
 * Arguments:
 * 0: TOOL_PROD or TOOL_DIG <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_tool"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

uiNamespace setVariable ["tlbi_defusal_tool", _tool];

[] call tlbi_defusal_fnc_refreshBoard;
