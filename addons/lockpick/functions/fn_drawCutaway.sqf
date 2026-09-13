#include "..\script_component.hpp"
/*
 * Author: TLB
 * Builds the cutaway view used by the pin tumbler and rake techniques: a
 * section through the cylinder with one bore per pin, each holding a spring,
 * a driver pin and a key pin, plus the tension wrench and the pick or rake.
 *
 * Only creation happens here. Every moving part is positioned each frame by
 * fn_tick, and all movement is vertical or horizontal, which Arma's dialog UI
 * draws reliably.
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

private _tool = _state get "tool";
private _tech = _state get "tech";
private _n = _state get "n";
private _step = (CUT_PIN_X1 - CUT_PIN_X0) / _n;
private _pw = (_step * 0.46) min 0.05;

private _ctrls = createHashMap;

_ctrls set ["housing", ["lp_housing_co", 0, 0, 1, 1] call _fnc_pic];

private _springs = [];
private _drivers = [];
private _keypins = [];

for "_i" from 0 to _n - 1 do {
    private _cx = CUT_PIN_X0 + (_i + 0.5) * _step;
    ["lp_bore_ca", _cx - _pw * 0.65, CUT_TOP, _pw * 1.3, CUT_KEYWAY - CUT_TOP] call _fnc_pic;
};

for "_i" from 0 to _n - 1 do {
    _springs pushBack (["lp_spring_ca", 0, 0, 0.01, 0.01] call _fnc_pic);
    _drivers pushBack (["lp_driverpin_ca", 0, 0, 0.01, 0.01] call _fnc_pic);
    _keypins pushBack (["lp_keypin_ca", 0, 0, 0.01, 0.01] call _fnc_pic);
};

_ctrls set ["springs", _springs];
_ctrls set ["drivers", _drivers];
_ctrls set ["keypins", _keypins];
_ctrls set ["step", _step];
_ctrls set ["pw", _pw];

_ctrls set ["wrench", [["lp_wrench_kit_ca", "lp_wrench_clip_ca"] select _tool, 0.03, CUT_KEYWAY - 0.12, 0.14, 0.26] call _fnc_pic];

private _pick = call {
    if (_tech == TECH_RAKE) exitWith {
        ["lp_rake_ca", 0, 0, 0.70, 0.16, [[1, 1, 1, 1], [0.92, 0.94, 0.97, 1]] select _tool] call _fnc_pic
    };
    [["lp_pick_kit_ca", "lp_pick_clip_ca"] select _tool, 0, 0, 0.70, 0.16] call _fnc_pic
};
_ctrls set ["pick", _pick];

// Tension gauge, raking only: keep the needle inside the drifting green band.
// Top left, over bare housing, clear of the pin bores.
if (_tech == TECH_RAKE) then {
    [0.02, 0.06, 0.26, 0.15, [0.02, 0.02, 0.015, 0.82]] call _fnc_fill;
    [0.035, 0.155, 0.23, 0.012, [0.30, 0.30, 0.27, 1]] call _fnc_fill;

    private _label = _display ctrlCreate ["tlbi_RscText", -1, _group];
    _label ctrlSetPosition [0.035 * _bw, 0.065 * _bh, 0.23 * _bw, 0.06 * _bh];
    _label ctrlSetFont "PuristaMedium";
    _label ctrlSetFontHeight (0.019 * safezoneH);
    _label ctrlSetText localize "STR_tlbi_lockpick_gauge_tension";
    _label ctrlCommit 0;

    _ctrls set ["band", [0.035, 0.135, 0.1, 0.05, [0.30, 0.55, 0.25, 0.55]] call _fnc_fill];
    _ctrls set ["needle", [0.035, 0.125, 0.004, 0.07, [0.95, 0.92, 0.80, 1]] call _fnc_fill];
};

_state set ["ctrls", _ctrls];
