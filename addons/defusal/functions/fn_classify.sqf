#include "..\script_component.hpp"
/*
 * Author: TLB
 * Decides which procedure an explosive gets: IED, mine or tripwire.
 *
 * The CBA class lists are checked first - tripwire, then mine, then IED - and
 * accept either the explosive's own ammo class (what typeOf returns) or any
 * parent class, so listing "MineBase" catches every mine that inherits from it.
 *
 * Anything not listed is classified by how it fires:
 *
 *   class name contains "IED"                      -> IED
 *   mineTrigger names a wire, or class says "trip" -> tripwire
 *   MineBase / BoundingMineBase, or a range,
 *     pressure or tank trigger                     -> mine
 *   everything else (remote, timer, magnetic, IR)  -> IED: a firing circuit
 *
 * Trigger NAMES are matched, not trigger inheritance. In vanilla CfgMineTriggers
 * both TankTriggerMagnetic (the AT mine) and IRTrigger (the SLAM) inherit from
 * WireTrigger, so going by inheritance would put AT mines on the tripwire board.
 *
 * Every decision is written to the RPT with the class name, so mission makers
 * can see exactly what to type into the settings.
 *
 * Arguments:
 * 0: Explosive <OBJECT>
 *
 * Return Value:
 * KIND_* <NUMBER>
 */

params [["_explosive", objNull, [objNull]]];

private _class = typeOf _explosive;
private _lower = toLower _class;
private _ammo = configFile >> "CfgAmmo";

private _fnc_listed = {
    params ["_setting"];

    private _names = ((missionNamespace getVariable [_setting, ""]) splitString (", ;" + toString [9, 10, 13])) apply {toLower _x};

    (_names findIf {_x isEqualTo _lower || {_class isKindOf [_x, _ammo]}}) != -1
};

private _kind = -1;
private _source = "setting";

call {
    if (["tlbi_defusal_classesTrip"] call _fnc_listed) exitWith { _kind = KIND_TRIP };
    if (["tlbi_defusal_classesMine"] call _fnc_listed) exitWith { _kind = KIND_MINE };
    if (["tlbi_defusal_classesIed"] call _fnc_listed) exitWith { _kind = KIND_IED };
};

if (_kind == -1) then {
    _source = "auto";

    private _trigger = toLower getText (_ammo >> _class >> "mineTrigger");

    _kind = call {
        if ((_lower find "ied") >= 0) exitWith { KIND_IED };

        if ((_trigger find "wire") >= 0 || {(_trigger find "trip") >= 0} || {(_lower find "trip") >= 0}) exitWith {
            KIND_TRIP
        };

        if (
            _class isKindOf ["MineBase", _ammo]
            || {_class isKindOf ["BoundingMineBase", _ammo]}
            || {(_trigger find "range") >= 0}
            || {(_trigger find "pressure") >= 0}
            || {(_trigger find "tank") >= 0}
        ) exitWith { KIND_MINE };

        KIND_IED
    };
};

diag_log text format ["[TLB Interactions] %1 classified as %2 (%3)", _class, ["IED", "mine", "tripwire"] select _kind, _source];

_kind
