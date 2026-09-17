#include "..\script_component.hpp"
/*
 * Author: TLB
 * Lays one tripwire through grass and stores it on the object.
 *
 * The wire runs from an anchor stake to a firing device. Sometimes a branch
 * leads off it to a second device, and the only way to know is to trace the
 * whole wire: every tuft over a wire has to be parted before the wire counts as
 * traced, while decorative tufts elsewhere can be left alone.
 *
 * The fuze is either tension-release (taut wire - cutting it fires unless every
 * device is pinned) or pull (slack wire - cutting it is safe). It looks the same
 * either way; only checking the tension tells you.
 *
 * Arguments:
 * 0: Explosive <OBJECT>
 * 1: Unit doing the defusing <OBJECT>
 *
 * Return Value:
 * Tripwire state <ARRAY> - see TR_* in script_component.hpp
 */

params ["_explosive", "_unit"];

private _left = random 1 < 0.5;
private _wireY = 0.36 + random 0.26;
private _taut = random 1 < 0.5;

private _anchorX = [0.90, 0.09] select _left;
private _fuzeX = [0.12, 0.86] select _left;

private _fuzes = [[_fuzeX, _wireY, false]];
private _branch = [];
private _tufts = [];

// Grass: an Explosive settings module decides, otherwise tripwires indoors follow
// the "Grass on tripwires inside buildings" setting. Without grass the wire
// starts traced.
private _where = getPos _explosive;
private _grassModule = ["tlbi_moduleExplosive", _where, "Grass", -1] call tlbi_defusal_fnc_moduleValue;
private _hasGrass = [
    tlbi_defusal_tripIndoorGrass || {!([_explosive] call tlbi_defusal_fnc_isIndoors)},
    _grassModule == 1
] select (_grassModule >= 0);
private _branchModule = ["tlbi_moduleExplosive", _where, "Branch", -1] call tlbi_defusal_fnc_moduleValue;

private _fnc_tuft = {
    params ["_tx", "_ty", "_onPath"];
    if (!_hasGrass) exitWith {};
    _tufts pushBack [_tx, _ty, 0.11 + random 0.035, floor random 3, false, _onPath];
};

// Along the main wire, end to end, both ends included.
private _x0 = _anchorX min _fuzeX;
private _x1 = _anchorX max _fuzeX;

for "_t" from 0 to 9 do {
    [_x0 + (_x1 - _x0) * _t / 9, _wireY + random [-0.04, 0, 0.04], true] call _fnc_tuft;
};

if ([random 1 < tlbi_defusal_branchChance * DIFF(DIFF_BRANCH), _branchModule == 1] select (_branchModule >= 0)) then {
    private _jx = 0.34 + random 0.22;
    private _up = random 1 < 0.5;
    private _bx = _jx + 0.22;
    private _by = ((_wireY + ([0.30, -0.30] select _up)) max 0.14) min 0.86;

    _fuzes pushBack [_bx, _by, false];
    _branch = [_jx];

    for "_t" from 1 to 3 do {
        [_jx + (_bx - _jx) * _t / 3, _wireY + (_by - _wireY) * _t / 3, true] call _fnc_tuft;
    };
};

// Decorative tufts. Without them the grass gives the game away: a tidy line of
// tufts marks the wire, and a diagonal of tufts marks a branch before anything
// has been traced. So a device without a branch gets a decoy diagonal of its
// own, and the rest are scattered anywhere - across the wire included.
if (count _branch == 0) then {
    private _jx = 0.34 + random 0.22;
    private _by = ((_wireY + ([0.30, -0.30] select (random 1 < 0.5))) max 0.14) min 0.86;

    for "_t" from 1 to 3 do {
        [_jx + 0.22 * _t / 3, _wireY + (_by - _wireY) * _t / 3, false] call _fnc_tuft;
    };
};

for "_i" from 1 to 10 do {
    [0.04 + random 0.92, 0.08 + random 0.84, false] call _fnc_tuft;
};

private _trip = [_left, _wireY, _taut, _fuzes, _branch, _tufts, [TSTAGE_TRACE, TSTAGE_WORK] select (count _tufts == 0), -1, 0];

_explosive setVariable ["tlbi_defusal_trip", _trip, true];
_explosive setVariable ["tlbi_defusal_elapsed", 0, true];

_trip
