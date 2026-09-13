#include "..\script_component.hpp"
/*
 * Author: TLB
 * Renders the device, bottom to top:
 *
 *   ground -> shell -> trigger pack -> junction -> cables -> leads -> tags
 *   -> readings -> tape -> soil
 *
 * Every visible part is a pre-rendered texture (see tools/gen_assets.py); flat
 * fills and runtime-drawn geometry are what made earlier versions look like a
 * UI rather than a device. Anything the player acts on - a soil clump, a tape
 * strip, a cable tag - gets an invisible hotspot laid over its texture, and
 * because controls created later sit on top, whatever is physically covering
 * something also takes its clicks until it is removed.
 *
 * Layout is expressed as fractions of the board rectangle. The same fractions
 * live in tools/preview_board.py, which composites this layout offline.
 *
 * Cables are single sprites tinted to their insulation colour. Sprite height is
 * proportional to how far a cable travels, and _padFactor matches the headroom
 * baked into each sprite, which keeps every cable the same thickness.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 */

params ["_display"];

// Mines and tripwires have their own boards; this file draws the IED.
private _kind = uiNamespace getVariable ["tlbi_defusal_kind", KIND_IED];
if (_kind == KIND_MINE) exitWith { [_display] call tlbi_defusal_fnc_mineDraw };
if (_kind == KIND_TRIP) exitWith { [_display] call tlbi_defusal_fnc_tripDraw };

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (count _puzzle <= PZ_TAPE) exitWith {};

_puzzle params ["_count", "_cables", "", "", "", "", "", "", "_dirt", "_tape"];

(ctrlPosition (_display displayCtrl IDC_BOARD)) params ["_bx", "_by", "_bw", "_bh"];

private _hotspots = [];

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

private _fnc_fill = {
    params ["_rx", "_ry", "_rw", "_rh", "_colour"];

    private _ctrl = _display ctrlCreate ["tlbi_RscFill", -1];
    _ctrl ctrlSetPosition ([_rx, _ry, _rw, _rh] call _fnc_rect);
    _ctrl ctrlSetBackgroundColor _colour;
    _ctrl ctrlCommit 0;
    _ctrl
};

// An invisible click target. The handler and its argument ride on the control,
// so one generic event handler serves soil, tape and tags alike.
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

// --- The device -------------------------------------------------------------
["ground_co", 0, 0, 1, 1] call _fnc_picture;
["shell_ca", 0.100, 0.200, 0.890, 0.700] call _fnc_picture;
["pack_ca", 0.012, 0.060, 0.135, 0.880] call _fnc_picture;

// --- Cables -----------------------------------------------------------------
private _top = 0.150;
private _rowH = (0.880 - _top) / ((_count - 1) max 1);
private _leftX = 0.215;
private _rightX = 0.875;   // inside the junction block, not at its edge
private _span = _rightX - _leftX;

// Jitter derived from stored values, so redrawing never reshuffles the loom.
private _rows = [];
{
    _rows pushBack (_top + _forEachIndex * _rowH + (_x select CB_SAG1) * 0.09 * _rowH);
} forEach _cables;

// Headroom baked into each sprite, as a multiple of the row spacing. Must match
// CPAD in tools/gen_assets.py: {0: 64, 1: 64, 2: 128} against ROW = 128.
private _padFactor = [0.5, 0.5, 1.0];

private _cableCtrls = [];
private _cableEnds = [];

{
    _x params ["_colourIdx", "", "", "_endRow", "", "_sag2"];

    private _cable = _forEachIndex;

    // Cables run to a nearby row: it is what a real loom does, and sprites only
    // exist for travel up to two rows.
    private _end = _cable + (((_endRow - _cable) max -CABLE_MAX_TRAVEL) min CABLE_MAX_TRAVEL);
    _end = (_end max 0) min (_count - 1);

    private _travel = _end - _cable;
    private _pad = (_padFactor select (abs _travel)) * _rowH;
    private _y0 = _rows select _cable;
    private _y1 = _rows select _end;
    private _colour = (tlbi_defusal_palette select _colourIdx) select 0;

    private _sprite = format ["cable_d%1%2_%3",
        ["p", "m"] select (_travel < 0),
        abs _travel,
        ["a", "b"] select (_sag2 >= 0)
    ];

    private _ctrl = [_sprite, _leftX, (_y0 min _y1) - _pad, _span, abs (_y1 - _y0) + 2 * _pad, _colour] call _fnc_picture;

    _cableCtrls pushBack [_ctrl, _colour];
    _cableEnds pushBack _y1;
} forEach _cables;

// The junction goes on after the cables so every cable end disappears under it,
// and a crimp ferrule marks where each one enters. Without both, the loom
// visibly stops short of the block it is meant to be wired into.
["junction_ca", 0.835, 0.080, 0.150, 0.840] call _fnc_picture;

{
    [0.846, _x - 0.010, 0.020, 0.020, [0.36, 0.36, 0.33, 1]] call _fnc_fill;
    [0.846, _x + 0.006, 0.020, 0.004, [0.12, 0.12, 0.11, 1]] call _fnc_fill;
} forEach _cableEnds;

// --- Leads, tags and readings -----------------------------------------------
private _tagH = (_rowH * 0.5) min 0.10;

{
    [0.140, _x - 0.007, 0.082, 0.014, [0.10, 0.10, 0.09, 1]] call _fnc_fill;
} forEach _rows;

private _tags = [];
private _readouts = [];

{
    private _cable = _forEachIndex;
    private _y = _x;

    private _pic = ["tag_ca", 0.150, _y - _tagH / 2, 0.068, _tagH] call _fnc_picture;

    private _label = _display ctrlCreate ["tlbi_RscTextCenter", -1];
    _label ctrlSetPosition ([0.160, _y - _tagH / 2, 0.058, _tagH] call _fnc_rect);
    _label ctrlSetFont "PuristaBold";
    _label ctrlSetFontHeight (0.022 * safezoneH);
    _label ctrlSetTextColor [0.20, 0.17, 0.12, 1];
    _label ctrlCommit 0;

    private _hot = [0.150, _y - _tagH / 2, 0.068, _tagH, tlbi_defusal_fnc_selectWire, _cable] call _fnc_hotspot;

    _tags pushBack [_pic, _hot, _label];

    private _read = _display ctrlCreate ["tlbi_RscTextCenter", -1];
    _read ctrlSetPosition ([0.845, _y - 0.045, 0.140, 0.090] call _fnc_rect);
    _read ctrlSetFont "EtelkaMonospacePro";
    _read ctrlSetFontHeight (0.018 * safezoneH);
    _read ctrlSetShadow 2;
    _read ctrlCommit 0;

    _readouts pushBack _read;
} forEach _rows;

// --- Tape -------------------------------------------------------------------
private _tapeCtrls = [];

{
    _x params ["_tx", "_tw", "_variant"];

    // The tag strip binds the tag column; the others wrap the shell only.
    private _span = [[0.16, 0.94], [0.08, 0.95]] select (_forEachIndex == 0);
    _span params ["_ty0", "_ty1"];

    private _pic = [["tape_a_ca", "tape_b_ca"] select _variant, _tx, _ty0, _tw, _ty1 - _ty0] call _fnc_picture;
    private _hot = [_tx, _ty0, _tw, _ty1 - _ty0, tlbi_defusal_fnc_cutTape, _forEachIndex] call _fnc_hotspot;

    _tapeCtrls pushBack [_pic, _hot];
} forEach _tape;

// --- Soil -------------------------------------------------------------------
// Clumps are square in screen pixels, so their height fraction depends on the
// board's aspect. The hotspot is a little smaller than the texture so that
// overlapping clumps can still be picked out one at a time.
private _aspect = (_bw / pixelW) / (_bh / pixelH);
private _dirtCtrls = [];

{
    _x params ["_cx", "_cy", "_size", "_variant"];

    private _h = _size * _aspect;
    private _rx = _cx - _size / 2;
    private _ry = _cy - _h / 2;

    private _pic = [format ["dirt_%1_ca", ["a", "b", "c", "d"] select _variant], _rx, _ry, _size, _h] call _fnc_picture;
    private _hot = [_rx + _size * 0.1, _ry + _h * 0.1, _size * 0.8, _h * 0.8, tlbi_defusal_fnc_brushDirt, _forEachIndex] call _fnc_hotspot;

    _dirtCtrls pushBack [_pic, _hot, [_rx, _ry, _size, _h] call _fnc_rect];
} forEach _dirt;

uiNamespace setVariable ["tlbi_defusal_cables", _cableCtrls];
uiNamespace setVariable ["tlbi_defusal_tags", _tags];
uiNamespace setVariable ["tlbi_defusal_readouts", _readouts];
uiNamespace setVariable ["tlbi_defusal_tapeCtrls", _tapeCtrls];
uiNamespace setVariable ["tlbi_defusal_dirtCtrls", _dirtCtrls];
uiNamespace setVariable ["tlbi_defusal_hotspots", _hotspots];
