#include "..\script_component.hpp"
/*
 * Author: TLB
 * Renders a buried mine, bottom to top:
 *
 *   ground -> stones -> mine -> safety pin (hidden) -> soil cells
 *   -> prod flags (hidden) -> cell hotspots
 *
 * The mine and stones are drawn under the soil, so digging a cell out reveals
 * whatever is really there. Cells are laid out as fractions of the board; stones
 * and the mine are kept square in screen pixels.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 */

params ["_display"];

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _mine = _explosive getVariable ["tlbi_defusal_mine", []];

if (count _mine <= MN_AT) exitWith {};

_mine params ["_cols", "_rows", "_cx", "_cy", "", "", "_stones", "", "", "_at"];

(ctrlPosition (_display displayCtrl IDC_BOARD)) params ["_bx", "_by", "_bw", "_bh"];

private _hotspots = [];
private _aspect = (_bw / pixelW) / (_bh / pixelH);

private _fnc_tex = { format [QPATHTOF(data\%1.paa), _this] };

private _fnc_rect = {
    params ["_rx", "_ry", "_rw", "_rh"];
    [_bx + _rx * _bw, _by + _ry * _bh, _rw * _bw, _rh * _bh]
};

private _fnc_picture = {
    params ["_texture", "_rx", "_ry", "_rw", "_rh", ["_tint", [1, 1, 1, 1]]];

    private _ctrl = _display ctrlCreate ["tlbi_RscPicture", -1];
    _ctrl ctrlSetPosition ([_rx, _ry, _rw, _rh] call _fnc_rect);
    _ctrl ctrlSetText (_texture call _fnc_tex);
    _ctrl ctrlSetTextColor _tint;
    _ctrl ctrlCommit 0;
    _ctrl
};

private _fnc_hotspot = {
    params ["_rx", "_ry", "_rw", "_rh", "_handler", "_index"];

    private _ctrl = _display ctrlCreate ["tlbi_RscHotspot", -1];
    _ctrl ctrlSetPosition ([_rx, _ry, _rw, _rh] call _fnc_rect);
    _ctrl setVariable ["tlbi_handler", _handler];
    _ctrl setVariable ["tlbi_index", _index];
    _ctrl ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        [_ctrl getVariable ["tlbi_index", -1]] call (_ctrl getVariable ["tlbi_handler", {}]);
    }];
    _ctrl ctrlCommit 0;

    _hotspots pushBack _ctrl;
    _ctrl
};

private _gx = 0.02;
private _gy = 0.05;
private _cw = 0.96 / _cols;
private _ch = 0.90 / _rows;

private _fnc_cell = {
    params ["_cell"];
    [_gx + (_cell % _cols) * _cw, _gy + (floor (_cell / _cols)) * _ch, _cw, _ch]
};

["ground_co", 0, 0, 1, 1] call _fnc_picture;

// --- Stones -----------------------------------------------------------------
{
    ([_x] call _fnc_cell) params ["_rx", "_ry", "_rw", "_rh"];

    private _s = (_rw min (_rh / _aspect)) * 0.7;
    [["stone_a_ca", "stone_b_ca"] select (_forEachIndex % 2), _rx + (_rw - _s) / 2, _ry + (_rh - _s * _aspect) / 2, _s, _s * _aspect] call _fnc_picture;
} forEach _stones;

// --- Mine and its pin -------------------------------------------------------
private _mx = _gx + (_cx + 0.5) * _cw;
private _my = _gy + (_cy + 0.5) * _ch;
private _ms = ((3 * _cw) min (3 * _ch / _aspect)) * 0.92;

[["mine_ap_ca", "mine_at_ca"] select _at, _mx - _ms / 2, _my - _ms * _aspect / 2, _ms, _ms * _aspect] call _fnc_picture;

// Pin hole offset within the sprite, as a fraction of its width - must match
// make_mine in tools/gen_assets.py.
private _hole = _mx + _ms * ([0.058, 0.079] select _at);
private _ps = _ms * 0.20;
private _pin = ["pin_ca", _hole - _ps * 0.30, _my - _ps * _aspect / 2, _ps, _ps * _aspect, [0.88, 0.88, 0.84, 1]] call _fnc_picture;
_pin ctrlShow false;

// --- Soil, flags, hotspots --------------------------------------------------
// Soil tiles overhang their cell so neighbours overlap into a continuous
// surface rather than a visible grid.
private _cells = [];

for "_cell" from 0 to (_cols * _rows) - 1 do {
    ([_cell] call _fnc_cell) params ["_rx", "_ry", "_rw", "_rh"];

    // Deterministic per-cell jitter in size and position, so the soil reads as
    // one lumpy surface instead of a wall of identical tiles.
    private _k = 1.35 + (((_cell * 53) % 17) / 17) * 0.35;
    private _ox = ((((_cell * 31) % 13) / 13) - 0.5) * 0.30 * _rw;
    private _oy = ((((_cell * 71) % 11) / 11) - 0.5) * 0.30 * _rh;

    private _soil = [
        format ["dirt_%1_ca", ["a", "b", "c", "d"] select ((_cell * 7) % 4)],
        _rx + _rw * (1 - _k) / 2 + _ox, _ry + _rh * (1 - _k * 1.05) / 2 + _oy, _rw * _k, _rh * _k * 1.05
    ] call _fnc_picture;

    _cells pushBack [_soil];
};

{
    ([_forEachIndex] call _fnc_cell) params ["_rx", "_ry", "_rw", "_rh"];

    private _fw = _rw * 0.26;
    private _fh = _fw * _aspect * 2;
    private _flag = ["flag_ca", _rx + _rw * 0.55, _ry + _rh * 0.5 - _fh * 0.85, _fw, _fh] call _fnc_picture;
    _flag ctrlShow false;

    _x pushBack _flag;
} forEach _cells;

{
    ([_forEachIndex] call _fnc_cell) params ["_rx", "_ry", "_rw", "_rh"];

    _x pushBack ([_rx, _ry, _rw, _rh, tlbi_defusal_fnc_mineCell, _forEachIndex] call _fnc_hotspot);
} forEach _cells;

uiNamespace setVariable ["tlbi_defusal_mineCells", _cells];
uiNamespace setVariable ["tlbi_defusal_minePin", _pin];
uiNamespace setVariable ["tlbi_defusal_hotspots", _hotspots];
