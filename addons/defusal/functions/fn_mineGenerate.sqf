#include "..\script_component.hpp"
/*
 * Author: TLB
 * Buries one pressure mine under a grid of soil and stores it on the object.
 *
 * The mine takes a 3 x 3 block of cells: its pressure plate is the centre cell
 * and its rim the eight around it. A few stones are scattered elsewhere, so a
 * prod that hits something solid is not automatically the mine.
 *
 * Anti-tank mines need far more weight than a hand to fire. They get a larger
 * body, prodding the plate is much less risky, and digging onto the plate is
 * survivable - all of which is true of the real thing.
 *
 * Arguments:
 * 0: Explosive <OBJECT>
 * 1: Unit doing the defusing <OBJECT>
 *
 * Return Value:
 * Mine state <ARRAY> - see MN_* in script_component.hpp
 */

params ["_explosive", "_unit"];

private _cols = MINE_COLS;
private _rows = MINE_ROWS;
private _cells = _cols * _rows;

private _cx = 1 + floor random (_cols - 2);
private _cy = 1 + floor random (_rows - 2);

private _stones = [];
private _attempts = 0;

while {count _stones < 5 && {_attempts < 200}} do {
    _attempts = _attempts + 1;

    private _cell = floor random _cells;
    private _col = _cell % _cols;
    private _row = floor (_cell / _cols);

    if ((abs (_col - _cx) > 1 || {abs (_row - _cy) > 1}) && {!(_cell in _stones)}) then {
        _stones pushBack _cell;
    };
};

private _trigger = toLower getText (configOf _explosive >> "mineTrigger");
private _at = (_trigger find "tank") >= 0 || {((toLower typeOf _explosive) find "atmine") >= 0};

private _dug = [];
private _probed = [];
for "_i" from 1 to _cells do {
    _dug pushBack 0;
    _probed pushBack -1;
};

private _mine = [_cols, _rows, _cx, _cy, _dug, _probed, _stones, MSTAGE_LOCATE, 0, _at];

_explosive setVariable ["tlbi_defusal_mine", _mine, true];
_explosive setVariable ["tlbi_defusal_elapsed", 0, true];

_mine
