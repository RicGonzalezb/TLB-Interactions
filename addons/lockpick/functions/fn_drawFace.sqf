#include "..\script_component.hpp"
/*
 * Author: TLB
 * Builds the front view used by the sweet-spot technique: a lock set in a
 * wooden door, the plug with its keyhole, the pick, and a strain gauge.
 *
 * The plug turning and the pick changing angle are pre-rendered frames that
 * fn_tick swaps with ctrlSetText - Arma's dialog UI will not rotate a control.
 * The face is kept round by sizing it in screen pixels.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 */

params ["_display"];

private _state = uiNamespace getVariable ["tlbi_lockpick_state", createHashMap];

if (count _state == 0) exitWith {};

// Parts live inside the board's controls group, positioned relative to it.
private _group = _display displayCtrl IDC_LP_BOARD;
(ctrlPosition _group) params ["", "", "_bw", "_bh"];

private _aspect = (_bw / pixelW) / (_bh / pixelH);

private _fnc_pic = {
    params ["_texture", "_rx", "_ry", "_rw", "_rh", ["_tint", [1, 1, 1, 1]]];

    private _ctrl = _display ctrlCreate ["tlbi_RscPicture", -1, _group];
    _ctrl ctrlSetPosition [_rx * _bw, _ry * _bh, _rw * _bw, _rh * _bh];
    _ctrl ctrlSetText format [QPATHTOF(data\%1.paa), _texture];
    _ctrl ctrlSetTextColor _tint;
    _ctrl ctrlCommit 0;
    _ctrl
};

private _fnc_fill = {
    params ["_rx", "_ry", "_rw", "_rh", "_colour"];

    private _ctrl = _display ctrlCreate ["tlbi_RscFill", -1, _group];
    _ctrl ctrlSetPosition [_rx * _bw, _ry * _bh, _rw * _bw, _rh * _bh];
    _ctrl ctrlSetBackgroundColor _colour;
    _ctrl ctrlCommit 0;
    _ctrl
};

private _ctrls = createHashMap;

["lp_door_co", 0, 0, 1, 1] call _fnc_pic;

private _fh = 0.92;
private _fw = _fh / _aspect;
["lp_face_ca", 0.5 - _fw / 2, 0.04, _fw, _fh] call _fnc_pic;

private _ph = 0.50;
private _pw = _ph / _aspect;
_ctrls set ["plug", ["lp_plug_00_ca", 0.5 - _pw / 2, 0.5 - _ph / 2, _pw, _ph] call _fnc_pic];

private _kh = 0.84;
private _kw = _kh / _aspect;
_ctrls set ["pick", ["lp_dpick_15_ca", 0.5 - _kw / 2, 0.5 - _kh / 2, _kw, _kh,
    [[0.82, 0.84, 0.88, 1], [0.97, 0.97, 1, 1]] select (_state get "tool")] call _fnc_pic];
_ctrls set ["pickRect", [0.5 - _kw / 2, 0.5 - _kh / 2, _kw, _kh]];

[0.72, 0.76, 0.26, 0.18, [0.02, 0.02, 0.015, 0.82]] call _fnc_fill;
[0.74, 0.87, 0.22, 0.03, [0.20, 0.20, 0.18, 1]] call _fnc_fill;
_ctrls set ["strain", [0.74, 0.87, 0, 0.03, [0.72, 0.58, 0.22, 1]] call _fnc_fill];

private _label = _display ctrlCreate ["tlbi_RscText", -1, _group];
_label ctrlSetPosition [0.74 * _bw, 0.775 * _bh, 0.22 * _bw, 0.07 * _bh];
_label ctrlSetFont "PuristaMedium";
_label ctrlSetFontHeight (0.019 * safezoneH);
_label ctrlSetText localize "STR_tlbi_lockpick_gauge_strain";
_label ctrlCommit 0;

// Load every frame once now, so the first turn does not stutter while the
// textures stream in.
private _preload = _display ctrlCreate ["tlbi_RscPicture", -1, _group];
_preload ctrlSetPosition [0, 0, 0, 0];
_preload ctrlCommit 0;
for "_i" from 0 to 18 do { _preload ctrlSetText format [QPATHTOF(data\lp_plug_%1_ca.paa), [_i, 2] call CBA_fnc_formatNumber] };
for "_i" from 0 to 30 do { _preload ctrlSetText format [QPATHTOF(data\lp_dpick_%1_ca.paa), [_i, 2] call CBA_fnc_formatNumber] };
_preload ctrlShow false;

_state set ["ctrls", _ctrls];
