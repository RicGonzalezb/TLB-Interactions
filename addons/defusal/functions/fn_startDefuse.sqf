#include "..\script_component.hpp"
/*
 * Author: TLB
 * Drop-in replacement for ace_explosives_fnc_startDefuse. Installed over ACE's
 * own function at post-init, which is enough to take over defusal for every
 * mine and explosive in the game: ACE's interaction defines its statement as
 * the string "[_player, _target] call ace_explosives_fnc_startDefuse", so it
 * resolves the global at the moment the player clicks.
 *
 * AI defusal, remote-controlled units and the disabled case all fall through to
 * the original ACE implementation, which is kept in
 * tlbi_defusal_aceStartDefuse.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Interaction helper or the explosive itself <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_unit", objNull, [objNull]], ["_target", objNull, [objNull]]];

diag_log text format ["[TLB Interactions] startDefuse: unit=%1 target=%2", _unit, typeOf _target];

private _fnc_ace = {
    // Only ever the function we saved at post-init: falling back to whatever
    // ace_explosives_fnc_startDefuse currently holds could be us, and recurse.
    if (isNil "tlbi_defusal_aceStartDefuse") exitWith {
        diag_log text "[TLB Interactions] no saved ACE startDefuse to fall back to";
    };

    _this call tlbi_defusal_aceStartDefuse;
};

if !(missionNamespace getVariable ["tlbi_defusal_enabled", true]) exitWith {
    [_unit, _target] call _fnc_ace;
};

if (!alive _unit) exitWith {};

if (_target isKindOf "ACE_DefuseObject") then {
    _target = attachedTo _target;
};

if (isNull _target) exitWith {};

// Hand off to the machine the unit is local to, using our own event so the
// hand-off does not land back in ACE's implementation.
if (!local _unit) exitWith {
    ["tlbi_defusal_startDefuse", [_unit, _target], _unit] call CBA_fnc_targetEvent;
};

// Only the interacting player gets the board; AI keep ACE's timed behaviour.
if (!hasInterface || {ACE_player != _unit}) exitWith { [_unit, _target] call _fnc_ace };

// Mirrors the gate ACE's own player branch applies.
if ((missionNamespace getVariable ["ace_explosives_requireSpecialist", false]) && {!(_unit call ace_common_fnc_isEOD)}) exitWith {};

if !([_unit, _target] call tlbi_defusal_fnc_openBoard) then {
    diag_log text "[TLB Interactions] openBoard refused to open";
};
