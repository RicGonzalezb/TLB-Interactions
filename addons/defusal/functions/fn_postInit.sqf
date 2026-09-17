#include "..\script_component.hpp"
// TLB Interactions - Defusal: take over ACE's defusal. Runs via CfgFunctions
// postInit.
//
// ACE compiles its functions with compileFinal in release builds, so
// ace_explosives_fnc_startDefuse CANNOT be reassigned - trying it only produces
// "Attempt to override final function" in the RPT and leaves ACE's original in
// place. The takeover therefore happens at the interaction instead: ACE's
// defuse action is removed from its two helper classes and replaced with an
// identical-looking one whose statement calls us.
//
// That still covers every mine and explosive in the game, because ACE routes
// all of them through those same two helper classes (see
// ace_explosives_fnc_interactEH, which attaches one to each nearby mine).

diag_log text "[TLB Interactions] postInit: installing defusal override";

if (isNil "tlbi_defusal_fnc_startDefuse") exitWith {
    diag_log text "[TLB Interactions] ERROR: own functions did not compile - check CfgFunctions paths.";
};

if (isNil "ace_explosives_fnc_startDefuse") exitWith {
    diag_log text "[TLB Interactions] ace_explosives not found - interactive defusal disabled.";
};

// Reading the final function is fine; only assigning to it is blocked. Keep it
// so the disabled path, AI and remote units can still reach stock behaviour.
tlbi_defusal_aceStartDefuse = ace_explosives_fnc_startDefuse;

// Our own hand-off event, so a defusal started for a non-local unit does not
// land back in ACE's implementation on the owning machine.
["tlbi_defusal_startDefuse", {
    _this call tlbi_defusal_fnc_startDefuse;
}] call CBA_fnc_addEventHandler;

// A defused or detonated device should not keep its board around.
["ace_explosives_defuse", {
    params ["_explosive"];
    {
        _explosive setVariable [_x, nil, true];
    } forEach ["tlbi_defusal_puzzle", "tlbi_defusal_mine", "tlbi_defusal_trip", "tlbi_defusal_elapsed"];
}] call CBA_fnc_addEventHandler;

if (!hasInterface) exitWith {
    diag_log text "[TLB Interactions] postInit: headless - no interaction hook needed";
};

// Rebindable under Configure Addons. The board checks this binding itself
// (fn_keyMatches), because a dialog does not pass key presses to CBA.
[
    "TLB Interactions", "tlbi_defusal_seatPin",
    [localize "STR_tlbi_defusal_key_seatPin", localize "STR_tlbi_defusal_key_seatPin_desc"],
    {false}, {false}, [57, [false, false, false]]
] call CBA_fnc_addKeybind;

// Zeus Explosive settings module, when Zeus Enhanced is loaded.
if (isClass (configFile >> "CfgPatches" >> "zen_custom_modules")) then {
    ["TLB Interactions", "STR_tlbi_defusal_module_name", {_this call tlbi_defusal_fnc_zeusExplosive}, "\tlbi\addons\main\data\logo_small_ca.paa"] call zen_custom_modules_fnc_register;
};

private _fnc_replaceDefuseAction = {
    params ["_class", "_distance"];

    private _action = [
        "TLBI_Defuse",
        localize "STR_ace_explosives_Defuse",
        "\z\ace\addons\explosives\UI\Defuse_ca.paa",
        {[_player, _target] call tlbi_defusal_fnc_startDefuse},
        {[_player, _target] call ace_explosives_fnc_canDefuse},
        {},
        [],
        {[0, 0, 0]},
        _distance
    ] call ace_interact_menu_fnc_createAction;

    if (_action isEqualTo []) exitWith {
        diag_log text format ["[TLB Interactions] ERROR: could not create defuse action for %1", _class];
    };

    // Order matters: addActionToClass compiles the class's config menu, which
    // has to exist before ACE's own entry can be found and removed.
    [_class, 0, [], _action] call ace_interact_menu_fnc_addActionToClass;
    [_class, 0, ["ACE_Defuse"]] call ace_interact_menu_fnc_removeActionFromClass;

    diag_log text format ["[TLB Interactions] hooked defuse action on %1", _class];
};

// Distances match ACE's own: 1 for the standard helper, 2 for the large one.
["ACE_DefuseObject", 1] call _fnc_replaceDefuseAction;
["ACE_DefuseObject_Large", 2] call _fnc_replaceDefuseAction;

diag_log text "[TLB Interactions] postInit: defusal override installed";
