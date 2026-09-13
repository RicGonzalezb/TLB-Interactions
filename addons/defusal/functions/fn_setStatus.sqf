#include "..\script_component.hpp"
/*
 * Author: TLB
 * Writes the one-line hint under the board.
 *
 * Arguments:
 * 0: Message <STRING>
 *
 * Return Value:
 * None
 */

params ["_text"];

private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];

if (isNull _display) exitWith {};

(_display displayCtrl IDC_STATUS) ctrlSetText _text;
