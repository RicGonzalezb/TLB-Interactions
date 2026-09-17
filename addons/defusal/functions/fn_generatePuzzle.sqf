#include "..\script_component.hpp"
/*
 * Author: TLB
 * Builds one device and stores it on the object, so every player sees the same
 * device and progress at every stage survives backing off.
 *
 * Nothing on the device marks the firing line. Each conductor has two hidden
 * electrical properties, and all four combinations are present:
 *
 *     supply + continuity  -> the firing line. Exactly one. Cut this.
 *     supply, no continuity -> a live bus tap that goes nowhere
 *     continuity, no supply -> a return path that reaches the initiator body
 *     neither               -> dead filler
 *
 * Before any of that can be tested the device has to be physically reached:
 * soil packed over it (optional, per setting) and tape binding the wiring.
 *
 * Arguments:
 * 0: Explosive <OBJECT>
 * 1: Unit doing the defusing <OBJECT>
 *
 * Return Value:
 * Puzzle <ARRAY> - see PZ_* in script_component.hpp
 */

params ["_explosive", "_unit"];

private _fnc_shuffle = {
    private _array = +_this;
    for "_i" from (count _array) - 1 to 1 step -1 do {
        private _j = floor random (_i + 1);
        private _tmp = _array select _i;
        _array set [_i, _array select _j];
        _array set [_j, _tmp];
    };
    _array
};

private _min = (3 max round (tlbi_defusal_minWires + DIFF(DIFF_WIRES))) min 8;
private _max = _min max round (tlbi_defusal_maxWires + DIFF(DIFF_WIRES));
private _count = (_min + floor random (_max - _min + 1)) min 8;

private _indices = [];
for "_i" from 0 to _count - 1 do { _indices pushBack _i };

// --- Wiring -----------------------------------------------------------------
// One of each meaningful decoy is guaranteed, so a single meter mode can never
// settle it on its own - and so there are always at least two live conductors,
// which is what makes proving the firing line by elimination possible.
private _types = [[1, 1], [1, 0], [0, 1]];

for "_i" from 3 to _count - 1 do {
    _types pushBack (selectRandom [[1, 0], [0, 1], [0, 0]]);
};

_types = _types call _fnc_shuffle;

private _live = _types findIf {_x isEqualTo [1, 1]};
private _ends = _indices call _fnc_shuffle;

// Colours repeat in pairs, as they do on a real harness.
private _pairs = [];
{ _pairs pushBack floor (_forEachIndex / 2) } forEach _indices;
_pairs = _pairs call _fnc_shuffle;

private _paletteOrder = [];
for "_i" from 0 to (count tlbi_defusal_palette) - 1 do { _paletteOrder pushBack _i };
_paletteOrder = _paletteOrder call _fnc_shuffle;

private _cables = [];

{
    private _i = _x;
    (_types select _i) params ["_volts", "_ohms"];

    _cables pushBack [
        _paletteOrder select (_pairs select _i),
        _volts,
        _ohms,
        _ends select _i,
        random [-1.2, 0, 1.2],
        random [-1.2, 0, 1.2]
    ];
} forEach _indices;

// --- Soil -------------------------------------------------------------------
// A jittered 6 x 2 grid of overlapping clumps: the whole device is covered, but
// no two devices are buried the same way.
private _dirt = [];

private _buried = ["tlbi_moduleExplosive", getPos _explosive, "Buried", -1] call tlbi_defusal_fnc_moduleValue;

if ([tlbi_defusal_excavation, _buried == 1] select (_buried >= 0)) then {
    for "_row" from 0 to 1 do {
        for "_col" from 0 to 5 do {
            _dirt pushBack [
                (_col + 0.5) / 6 + random [-0.035, 0, 0.035],
                (_row + 0.5) / 2 + random [-0.08, 0, 0.08],
                0.19 + random 0.045,
                floor random 4,
                2
            ];
        };
    };
};

// --- Tape -------------------------------------------------------------------
// One strip binding the cable tags - so no conductor can be reached until it is
// gone - and two across the loom where it runs over the shell.
private _tape = [
    [0.135, 0.090, floor random 2, true],
    [0.370 + random 0.06, 0.055, floor random 2, true],
    [0.580 + random 0.06, 0.055, floor random 2, true]
];

private _unknown = [];
{ _unknown pushBack -1 } forEach _indices;

private _strikes = [0, 1] select (tlbi_defusal_failureMode == FAILURE_ONESTRIKE);
private _stage = [STAGE_TAPE, STAGE_EXCAVATE] select (count _dirt > 0);

private _puzzle = [_count, _cables, _live, _stage, +_unknown, +_unknown, _strikes, [], _dirt, _tape];

_explosive setVariable ["tlbi_defusal_puzzle", _puzzle, true];
_explosive setVariable ["tlbi_defusal_elapsed", 0, true];

_puzzle
