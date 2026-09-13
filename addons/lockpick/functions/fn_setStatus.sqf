#include "..\script_component.hpp"
/*
 * Author: TLB
 * Writes the one-line hint under the lock.
 *
 * Arguments:
 * 0: Message <STRING>
 *
 * Return Value:
 * None
 */

params ["_text"];

private _display = uiNamespace getVariable ["tlbi_lockpick_display", displayNull];

if (isNull _display) exitWith {};

(_display displayCtrl IDC_LP_STATUS) ctrlSetText _text;
