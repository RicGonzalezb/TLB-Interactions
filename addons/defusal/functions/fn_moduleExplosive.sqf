#include "..\script_component.hpp"
/*
 * Author: TLB
 * Init function of the Explosive settings module.
 *
 * There is nothing to apply at mission start: the module is read when a
 * device's board is first opened (fn_moduleValue), which also covers explosives
 * placed during the mission.
 *
 * Arguments:
 * 0: Module <OBJECT>
 *
 * Return Value:
 * True <BOOL>
 */

params [["_logic", objNull, [objNull]]];

diag_log text format ["[TLB Interactions] Explosive settings module at %1", getPos _logic];

true
