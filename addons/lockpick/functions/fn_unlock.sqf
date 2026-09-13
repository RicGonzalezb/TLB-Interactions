#include "..\script_component.hpp"
/*
 * Author: TLB
 * Unlocks a picked door.
 *
 * Writes the vanilla lock variables directly rather than going through
 * tsp_fnc_breach_adjust: its unlock passes a position where playSound3D now
 * requires an object, which throws a script error and aborts the rest of the
 * caller. tsp_breach's unlock sound is still played when that mod is loaded.
 *
 * Arguments:
 * 0: House <OBJECT>
 * 1: Door selection name <STRING>
 * 2: Door number <NUMBER or STRING>
 *
 * Return Value:
 * None
 */

params ["_house", "_door", "_id"];

_house setVariable [format ["bis_disabled_%1", _door], 0, true];
_house setVariable [format ["bis_disabled_Door_%1", _id], 0, true];

if (fileExists "\tsp_breach\snd\unlock.ogg") then {
    private _pos = _house modelToWorldWorld (_house selectionPosition _door);
    if (_pos vectorDistance (getPosASL _house) < 0.1) then { _pos = eyePos player };
    playSound3D ["tsp_breach\snd\unlock.ogg", objNull, false, _pos, 4, 1, 50];
};
