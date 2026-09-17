#include "..\script_component.hpp"
/*
 * Author: TLB
 * The steady-hand minigame for seating a safety pin, shared by mines and
 * tripwires.
 *
 * A needle wanders across a gauge. Holding Space - or holding the pin button -
 * pushes the pin in, but a hand under effort shakes, so the needle wanders much
 * harder while held. Letting go stops the push and lets the needle settle back
 * to centre. If the needle leaves the band while the pin is being pushed, the
 * pin slips: progress is lost, and past the slip limit the device fires.
 *
 * The skill is rhythm: push while the needle is steady, ease off before it
 * reaches the edge. The drift is a damped random walk scaled by sqrt(dt), so it
 * behaves the same at any frame rate.
 *
 * Arguments:
 * 0: Slips allowed before the device fires <NUMBER>
 * 1: Slips already used on this device <NUMBER>
 * 2: On seated <CODE>
 * 3: On slip <CODE> - called with [slipsUsed]
 * 4: On fired <CODE>
 * 5: Pin picture to fade in with progress <CONTROL> (default: controlNull)
 *
 * Return Value:
 * None
 */

params ["_limit", "_slips", "_onSeated", "_onSlip", "_onFired", ["_pinCtrl", controlNull]];

private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];

if (isNull _display) exitWith {};

uiNamespace setVariable ["tlbi_defusal_busy", true];
uiNamespace setVariable ["tlbi_defusal_pinning", true];
uiNamespace setVariable ["tlbi_defusal_holding", false];

{ _x ctrlEnable false } forEach (uiNamespace getVariable ["tlbi_defusal_hotspots", []]);

(ctrlPosition (_display displayCtrl IDC_BOARD)) params ["_bx", "_by", "_bw", "_bh"];

private _fnc_fill = {
    params ["_rx", "_ry", "_rw", "_rh", "_colour"];

    private _ctrl = _display ctrlCreate ["tlbi_RscFill", -1];
    _ctrl ctrlSetPosition [_bx + _rx * _bw, _by + _ry * _bh, _rw * _bw, _rh * _bh];
    _ctrl ctrlSetBackgroundColor _colour;
    _ctrl ctrlCommit 0;
    _ctrl
};

// Half-width of the safe band; the Difficulty setting widens or narrows it.
#define GAUGE_BAND (0.34 * DIFF(DIFF_BAND))

private _needleW = (3 * pixelW) / _bw;

private _frame = [0.27, 0.64, 0.46, 0.30, [0.02, 0.02, 0.015, 0.88]] call _fnc_fill;
private _track = [0.30, 0.786, 0.40, 0.012, [0.30, 0.30, 0.27, 1]] call _fnc_fill;
private _band = [0.50 - 0.20 * GAUGE_BAND, 0.755, 0.40 * GAUGE_BAND, 0.075, [0.30, 0.55, 0.25, 0.45]] call _fnc_fill;
private _needle = [0.50 - _needleW / 2, 0.745, _needleW, 0.095, [0.95, 0.92, 0.80, 1]] call _fnc_fill;
private _back = [0.30, 0.88, 0.40, 0.03, [0.20, 0.20, 0.18, 1]] call _fnc_fill;
private _fill = [0.30, 0.88, 0, 0.03, [0.72, 0.58, 0.22, 1]] call _fnc_fill;

private _label = _display ctrlCreate ["tlbi_RscTextCenter", -1];
_label ctrlSetPosition [_bx + 0.27 * _bw, _by + 0.655 * _bh, 0.46 * _bw, 0.07 * _bh];
_label ctrlSetFont "PuristaMedium";
_label ctrlSetFontHeight (0.021 * safezoneH);
_label ctrlSetText format [localize "STR_tlbi_defusal_pin_gauge", toUpper (["tlbi_defusal_seatPin"] call tlbi_defusal_fnc_keyName)];
_label ctrlCommit 0;

private _gauge = [_frame, _track, _band, _needle, _back, _fill, _label];
uiNamespace setVariable ["tlbi_defusal_gauge", _gauge];

[] call tlbi_defusal_fnc_refreshBoard;

[{
    params ["_args", "_pfhID"];
    _args params ["_state", "_limit", "_onSeated", "_onSlip", "_onFired", "_bx", "_bw", "_gauge", "_pinCtrl"];
    _state params ["_last", "_pos", "_vel", "_progress", "_lockUntil", "_slips"];

    private _fnc_end = {
        _pfhID call CBA_fnc_removePerFrameHandler;
        { ctrlDelete _x } forEach _gauge;
        uiNamespace setVariable ["tlbi_defusal_gauge", []];
        uiNamespace setVariable ["tlbi_defusal_busy", false];
        uiNamespace setVariable ["tlbi_defusal_pinning", false];
        uiNamespace setVariable ["tlbi_defusal_holding", false];
    };

    if (isNull (uiNamespace getVariable ["tlbi_defusal_display", displayNull])) exitWith { call _fnc_end };

    private _now = diag_tickTime;
    private _dt = (_now - _last) min 0.1;
    private _holding = (uiNamespace getVariable ["tlbi_defusal_holding", false]) && {_now >= _lockUntil};

    // Damped random walk: shakes and springs back weakly while pushing, barely
    // shakes and settles fast at rest. Tuned by simulation at 60 Hz: holding
    // without ever letting go slips after a median 1.7 s, a player who eases
    // off at around two-thirds of the band seats a 4 s pin in about 8 s without
    // firing it, and never letting go fires it about half the time.
    private _accel = [1.0, 1.8] select _holding;
    private _spring = [6.0, 3.0] select _holding;
    private _damp = [4.0, 4.0] select _holding;

    _vel = _vel + (random 2 - 1) * 1.73 * _accel * sqrt _dt - _pos * _spring * _dt;
    _vel = _vel * (1 - ((_damp * _dt) min 0.9));
    _pos = ((_pos + _vel * _dt) max -1) min 1;

    if (_holding) then {
        if (abs _pos > GAUGE_BAND) then {
            _slips = _slips + 1;
            _progress = (_progress - 0.3) max 0;
            _pos = 0;
            _vel = 0;
            _lockUntil = _now + 0.8;
            [_slips] call _onSlip;
        } else {
            _progress = _progress + _dt / (tlbi_defusal_pinTime max 0.5);
        };
    };

    _state set [0, _now];
    _state set [1, _pos];
    _state set [2, _vel];
    _state set [3, _progress];
    _state set [4, _lockUntil];
    _state set [5, _slips];

    _gauge params ["", "", "", "_needle", "", "_fill"];

    (ctrlPosition _needle) params ["", "_ny", "_nw", "_nh"];
    _needle ctrlSetPosition [_bx + (0.50 + _pos * 0.20) * _bw - _nw / 2, _ny, _nw, _nh];
    _needle ctrlSetBackgroundColor ([[0.95, 0.92, 0.80, 1], [0.95, 0.30, 0.22, 1]] select (abs _pos > GAUGE_BAND * 0.8));
    _needle ctrlCommit 0;

    (ctrlPosition _fill) params ["_fx", "_fy", "", "_fh"];
    _fill ctrlSetPosition [_fx, _fy, 0.40 * _bw * (_progress min 1), _fh];
    _fill ctrlCommit 0;

    if (!isNull _pinCtrl) then {
        _pinCtrl ctrlShow true;
        _pinCtrl ctrlSetTextColor [0.88, 0.88, 0.84, 0.25 + 0.75 * (_progress min 1)];
    };

    if (_slips > _limit) exitWith {
        call _fnc_end;
        call _onFired;
    };

    if (_progress >= 1) exitWith {
        call _fnc_end;
        call _onSeated;
    };
}, 0, [[diag_tickTime, 0, 0, 0, 0, _slips], _limit, _onSeated, _onSlip, _onFired, _bx, _bw, _gauge, _pinCtrl]] call CBA_fnc_addPerFrameHandler;
