#include "..\script_component.hpp"
/*
 * Author: TLB
 * Renders a tripwire, bottom to top:
 *
 *   ground -> wire -> branch -> anchor stake -> devices and their pins
 *   -> grass -> hotspots
 *
 * Grass is drawn over everything, so the wire, the stake and the devices are
 * found by parting it. Sprite attachment points below - where the wire meets a
 * stake loop or a pull ring - must match tools/gen_assets.py.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 */

params ["_display"];

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

if (count _trip <= TR_SLIPS) exitWith {};

_trip params ["_left", "_wireY", "", "_fuzes", "_branch", "_tufts"];

(ctrlPosition (_display displayCtrl IDC_BOARD)) params ["_bx", "_by", "_bw", "_bh"];

private _hotspots = [];
private _aspect = (_bw / pixelW) / (_bh / pixelH);
private _steel = [0.78, 0.78, 0.74, 1];

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

["ground_co", 0, 0, 1, 1] call _fnc_picture;

// --- Wire -------------------------------------------------------------------
private _anchorX = [0.90, 0.09] select _left;
(_fuzes select 0) params ["_fx"];

private _wx0 = _anchorX min _fx;
private _wx1 = _anchorX max _fx;
private _wh = 0.10;

// The wire sits 30px down a 64px sprite.
["tripwire_ca", _wx0, _wireY - _wh * (30 / 64), _wx1 - _wx0, _wh, _steel] call _fnc_picture;

if (count _branch > 0 && {count _fuzes > 1}) then {
    private _jx = _branch select 0;
    (_fuzes select 1) params ["_bx2", "_by2"];

    // Branch sprites run from their left edge at half height to the right edge
    // at 20/256 (up) or 236/256 (down) of their height.
    private _up = _by2 < _wireY;
    private _endK = [236 / 256, 20 / 256] select _up;
    private _h = abs (_by2 - _wireY) / abs (_endK - 0.5);

    [format ["tripbranch_%1_ca", ["dn", "up"] select _up], _jx, _wireY - 0.5 * _h, _bx2 - _jx, _h, _steel] call _fnc_picture;
};

// --- Anchor stake -----------------------------------------------------------
// 128x256 sprite; the wire loop is 24% of the way down.
private _sh = 0.36;
private _sw = _sh / (2 * _aspect);
["stake_ca", _anchorX - _sw / 2, _wireY - 0.24 * _sh, _sw, _sh] call _fnc_picture;

// --- Devices ----------------------------------------------------------------
// Square sprite; pull ring at (0.22, 0.19), pin hole at (0.50, 0.18).
private _fuzeCtrls = [];
private _fs = 0.34;
private _fw = _fs / _aspect;

{
    _x params ["_dx", "_dy"];

    private _rx = _dx - 0.22 * _fw;
    private _ry = _dy - 0.19 * _fs;

    private _pic = ["tripfuze_ca", _rx, _ry, _fw, _fs] call _fnc_picture;

    private _pw = _fw * 0.28;
    private _pin = ["pin_ca", _rx + 0.50 * _fw - _pw * 0.3, _ry + 0.18 * _fs - _pw * _aspect / 2, _pw, _pw * _aspect, [0.88, 0.88, 0.84, 1]] call _fnc_picture;
    _pin ctrlShow false;

    _fuzeCtrls pushBack [_pic, controlNull, _pin, [_rx, _ry, _fw, _fs]];
} forEach _fuzes;

// --- Grass ------------------------------------------------------------------
private _tuftCtrls = [];

{
    _x params ["_tx", "_ty", "_size", "_variant"];

    private _h = _size * _aspect;
    private _rx = _tx - _size / 2;
    private _ry = _ty - _h * 0.62;

    _tuftCtrls pushBack [[format ["grass_%1_ca", ["a", "b", "c"] select _variant], _rx, _ry, _size, _h] call _fnc_picture];
} forEach _tufts;

// Hotspots last, device ones first, so grass over a device takes the click
// until it has been parted.
{
    (_x select 3) params ["_rx", "_ry", "_rw", "_rh"];
    _x set [1, [_rx, _ry, _rw, _rh, tlbi_defusal_fnc_tripSelect, _forEachIndex] call _fnc_hotspot];
    _x resize 3;
} forEach _fuzeCtrls;

{
    (_tufts select _forEachIndex) params ["_tx", "_ty", "_size"];

    private _h = _size * _aspect;
    _x pushBack ([_tx - _size * 0.4, _ty - _h * 0.55, _size * 0.8, _h * 0.7, tlbi_defusal_fnc_tripTuft, _forEachIndex] call _fnc_hotspot);
} forEach _tuftCtrls;

uiNamespace setVariable ["tlbi_defusal_tripFuzes", _fuzeCtrls];
uiNamespace setVariable ["tlbi_defusal_tripTufts", _tuftCtrls];
uiNamespace setVariable ["tlbi_defusal_hotspots", _hotspots];
