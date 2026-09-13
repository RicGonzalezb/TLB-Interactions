#include "..\script_component.hpp"
// TLB Interactions - Lockpicking: hook into door interaction. Runs via
// CfgFunctions postInit.
//
// Two ways doors work, never both at once:
//
//  - tsp_breach loaded: it owns the doors - its ACE door actions, its random
//    locking. Its "Use Lockpick" and "Use Paperclip" call the global
//    tsp_fnc_breach_pick by name when clicked; that is a plain global (defined at
//    CBA pre-init, not compileFinal), so replacing it here sends both to our
//    board. Nothing else of ours runs.
//
//  - tsp_breach not loaded: our own door system. ACE door actions (open, close,
//    lock, unlock, pick) built at each door when the interaction menu opens, and
//    doors locked around the player from a per-mission seed.

diag_log text "[TLB Interactions] lockpick postInit";

tlbi_lockpick_tspLoaded = isClass (configFile >> "CfgPatches" >> "tsp_breach");

if (tlbi_lockpick_tspLoaded) exitWith {
    if (!isNil "tsp_fnc_breach_pick") then {
        if (isNil "tlbi_lockpick_tspOriginal") then {
            tlbi_lockpick_tspOriginal = tsp_fnc_breach_pick;
        };
        tsp_fnc_breach_pick = tlbi_lockpick_fnc_tspPick;
    };

    diag_log text format ["[TLB Interactions] tsp_breach loaded - using its doors; pick %1",
        ["NOT replaced", "replaced"] select (!isNil "tsp_fnc_breach_pick" && {tsp_fnc_breach_pick isEqualTo tlbi_lockpick_fnc_tspPick})];
};

diag_log text "[TLB Interactions] tsp_breach not loaded - using our own door interactions";

// One seed per mission, chosen by the server and broadcast once (JIP included).
if (isServer && {isNil "tlbi_lockpick_lockSeed"}) then {
    missionNamespace setVariable ["tlbi_lockpick_lockSeed", floor random 1000000, true];
};

if (!hasInterface) exitWith {};

["ace_interactMenuOpened", {
    params ["_menuType"];
    if (_menuType == 0) then { call tlbi_lockpick_fnc_doorHelpers };
}] call CBA_fnc_addEventHandler;

[{ call tlbi_lockpick_fnc_lockTick }, 2] call CBA_fnc_addPerFrameHandler;
