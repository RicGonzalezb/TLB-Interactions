#include "..\script_component.hpp"
/*
 * Author: TLB
 * The building variable that holds Zeus Lock settings for one door, keyed by the
 * door's number so the same door is found whether it was picked through
 * tsp_breach or our own Door menu.
 *
 * Arguments:
 * 0: Door selection name <STRING>
 *
 * Return Value:
 * Variable name <STRING>
 */

params ["_door"];

private _digits = ((_door splitString "") select {_x in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]}) joinString "";

format ["tlbi_lockpick_zeus_%1", _digits]
