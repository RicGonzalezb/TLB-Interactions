#include "..\script_component.hpp"
/*
 * Author: TLB
 * Per-frame logic for the lockpicking board. One per-frame handler per board;
 * it removes itself when the board closes.
 *
 * PINS  Pins bind one at a time in a hidden order. Lifting a pin that is not
 *       binding is quick and springy and cannot set; the binding pin lifts
 *       slowly - that stiffness is how you find it. Release it inside the
 *       shear-line window and it clicks and stays set; lift it past the window
 *       and it oversets, dropping every set pin. A kit also shows a faint glint
 *       while the binding pin is in the window; a paperclip wobbles instead.
 *
 * RAKE  Hold tension to keep the needle inside a slowly drifting band, and rake
 *       while it is there: each stroke may set a pin. Raking with too much
 *       tension binds everything and can slip; too little drops a set pin.
 *
 * DIAL  Move the pick to find the sweet spot, then turn. The plug only turns
 *       as far as the pick is close to it; forcing it past that builds strain,
 *       and too much strain slips. Turned all the way, it opens.
 *
 * Arguments:
 * 0: PFH arguments <ARRAY> (unused)
 * 1: PFH id <NUMBER>
 *
 * Return Value:
 * None
 */

params ["", "_pfhID"];

#define DRIVER_LEN 0.16

private _display = uiNamespace getVariable ["tlbi_lockpick_display", displayNull];
private _state = uiNamespace getVariable ["tlbi_lockpick_state", createHashMap];

if (isNull _display || {count _state == 0}) exitWith { _pfhID call CBA_fnc_removePerFrameHandler };

private _now = diag_tickTime;
private _dt = ((_now - (_state get "last")) min 0.1) max 0;
_state set ["last", _now];

private _unit = _state get "unit";

if (!alive _unit || {(getPosASL _unit) vectorDistance (_state get "pos") > 4} || {!isNull objectParent _unit}) exitWith {
    _pfhID call CBA_fnc_removePerFrameHandler;
    _display closeDisplay 2;
};

if (_state get "done") exitWith {};

private _hold = (_state getOrDefault ["hold_key", false]) || {_state getOrDefault ["hold_mouse", false]};
private _left = (_state getOrDefault ["left_key", false]) || {_state getOrDefault ["left_mouse", false]};
private _right = (_state getOrDefault ["right_key", false]) || {_state getOrDefault ["right_mouse", false]};
private _tool = _state get "tool";
private _ctrls = _state getOrDefault ["ctrls", createHashMap];

if (count _ctrls == 0) exitWith {};

// Parts sit in the board's controls group: positions are relative to it.
(ctrlPosition (_display displayCtrl IDC_LP_BOARD)) params ["", "", "_bw", "_bh"];

private _fnc_place = {
    params ["_ctrl", "_rx", "_ry", "_rw", "_rh"];
    _ctrl ctrlSetPosition [_rx * _bw, _ry * _bh, _rw * _bw, _rh * _bh];
    _ctrl ctrlCommit 0;
};

// Positions every pin stack from a per-pin lift (0 rest, 1 at the shear line).
private _fnc_renderPins = {
    params ["_lift", ["_glint", -1]];

    private _keyLen = _state get "keyLen";
    private _set = _state get "set";
    private _step = _ctrls get "step";
    private _pw = _ctrls get "pw";

    {
        private _cx = CUT_PIN_X0 + (_forEachIndex + 0.5) * _step;
        private _len = _keyLen select _forEachIndex;
        private _travel = CUT_KEYWAY - _len - CUT_SHEAR;

        private _keyBottom = CUT_KEYWAY;
        private _driverBottom = CUT_SHEAR - 0.004;

        if !(_set select _forEachIndex) then {
            _keyBottom = CUT_KEYWAY - _x * _travel;
            _driverBottom = _keyBottom - _len;
        };

        private _driverTop = _driverBottom - DRIVER_LEN;

        [(_ctrls get "keypins") select _forEachIndex, _cx - _pw / 2, _keyBottom - _len, _pw, _len] call _fnc_place;
        [(_ctrls get "drivers") select _forEachIndex, _cx - _pw / 2, _driverTop, _pw, DRIVER_LEN] call _fnc_place;
        [(_ctrls get "springs") select _forEachIndex, _cx - _pw / 2, CUT_TOP, _pw, (_driverTop - CUT_TOP) max 0.02] call _fnc_place;

        ((_ctrls get "keypins") select _forEachIndex) ctrlSetTextColor ([[1, 1, 1, 1], [1, 0.93, 0.62, 1]] select (_forEachIndex == _glint));
    } forEach _lift;
};

private _setCount = {({_x} count (_state get "set"))};

switch (_state get "tech") do {

    // ------------------------------------------------------------------------
    case TECH_PINS: {
        call {
            private _n = _state get "n";
            private _heights = _state get "h";
            private _set = _state get "set";
            private _order = _state get "order";
            private _sel = _state get "sel";
            private _window = _state get "window";

            private _steps = (_state get "rightEdge") - (_state get "leftEdge");
            _state set ["leftEdge", 0];
            _state set ["rightEdge", 0];
            if (_steps != 0 && {!_hold}) then {
                _sel = ((_sel + _steps) max 0) min (_n - 1);
                _state set ["sel", _sel];
            };

            private _next = _order findIf {!(_set select _x)};
            private _binding = [-1, _order select (_next max 0)] select (_next != -1);

            {
                if !(_set select _forEachIndex) then {
                    private _v = _x;

                    if (_forEachIndex == _sel && {_hold}) then {
                        _v = _v + ([1.8, _state get "lift"] select (_forEachIndex == _binding)) * _dt;
                        _v = _v + (random 2 - 1) * (_state get "shake") * _dt;
                        if (_forEachIndex != _binding) then { _v = _v min 1.7 };
                    } else {
                        _v = _v - 3 * _dt;
                    };

                    _heights set [_forEachIndex, _v max 0];
                };
            } forEach _heights;

            private _h = _heights select _sel;
            private _inWindow = abs (_h - 1) <= _window / 2;

            if (_hold && {_sel == _binding} && {_h > 1 + _window / 2}) exitWith {
                [localize "STR_tlbi_lockpick_msg_overset"] call tlbi_lockpick_fnc_mistake;
            };

            if ((_state get "wasHolding") && {!_hold} && {_sel == _binding} && {_inWindow}) then {
                _set set [_sel, true];
                _heights set [_sel, 0];
                playSound "ACE_Sound_Click";
            };

            _state set ["wasHolding", _hold];

            if (call _setCount == _n) exitWith { call tlbi_lockpick_fnc_finish };

            private _glint = [-1, _sel] select ((_state get "glint") && {_sel == _binding} && {_inWindow});
            [_heights, _glint] call _fnc_renderPins;

            // Pick glides to the selected pin, its tip under that key pin.
            private _target = CUT_PIN_X0 + (_sel + 0.5) * (_ctrls get "step");
            private _pickX = _state get "pickX";
            _pickX = _pickX + (_target - _pickX) * ((_dt * 12) min 1);
            _state set ["pickX", _pickX];

            private _selLen = (_state get "keyLen") select _sel;
            private _tipY = [CUT_KEYWAY - (_heights select _sel) * (CUT_KEYWAY - _selLen - CUT_SHEAR), CUT_KEYWAY] select (_set select _sel);
            [_ctrls get "pick", _pickX - 0.02 * 0.70, _tipY - 0.42 * 0.16, 0.70, 0.16] call _fnc_place;

            (_display displayCtrl IDC_LP_READOUT) ctrlSetText format [localize "STR_tlbi_lockpick_lcd_pins", _sel + 1, _n, call _setCount, _n];
        };
    };

    // ------------------------------------------------------------------------
    case TECH_RAKE: {
        call {
            private _n = _state get "n";
            private _set = _state get "set";
            private _band = _state get "band";

            private _centre = (((_state get "centre") + (random 2 - 1) * (_state get "drift") * sqrt _dt) max 0.2) min 0.8;
            private _tension = (((_state get "tension") + ([-(_state get "fall"), _state get "rise"] select _hold) * _dt) max 0) min 1;
            _state set ["centre", _centre];
            _state set ["tension", _tension];

            private _stroke = ((_state get "stroke") - _dt) max 0;

            if ((_state get "rakeEdge") > 0) then {
                _state set ["rakeEdge", 0];

                if (_now >= (_state get "nextStroke")) then {
                    _state set ["nextStroke", _now + 0.35];
                    _stroke = 0.35;

                    call {
                        if (abs (_tension - _centre) <= _band / 2) exitWith {
                            private _unset = [];
                            { if !(_x) then { _unset pushBack _forEachIndex } } forEach _set;
                            if (count _unset > 0 && {random 1 < (_state get "chance")}) then {
                                _set set [selectRandom _unset, true];
                                playSound "ACE_Sound_Click";
                            };
                        };

                        if (_tension > _centre + _band / 2) exitWith {
                            if (random 1 < (_state get "slipChance")) then { _state set ["slip", true] };
                        };

                        private _setIdx = [];
                        { if (_x) then { _setIdx pushBack _forEachIndex } } forEach _set;
                        if (count _setIdx > 0 && {random 1 < (_state get "dropChance")}) then { _set set [selectRandom _setIdx, false] };
                    };
                };
            };

            _state set ["stroke", _stroke];

            if (_state getOrDefault ["slip", false]) exitWith {
                _state set ["slip", false];
                [localize "STR_tlbi_lockpick_msg_bound"] call tlbi_lockpick_fnc_mistake;
            };

            if (call _setCount == _n) exitWith { call tlbi_lockpick_fnc_finish };

            // Unset pins bounce while the rake runs through them.
            private _lift = [];
            { _lift pushBack ([0, random 1.15] select (_stroke > 0 && {!_x})) } forEach _set;
            [_lift] call _fnc_renderPins;

            // The rake rests deep under the back pins and each stroke draws it out
            // under the front ones and back, teeth tips pressing the key pins.
            private _swing = sin (((0.35 - _stroke) / 0.35) * 180) * ([0, 0.33] select (_stroke > 0));
            [_ctrls get "pick", 0.63 - _swing, CUT_KEYWAY - 0.52 * 0.16, 0.70, 0.16] call _fnc_place;

            [_ctrls get "band", 0.035 + (_centre - _band / 2) * 0.23, 0.135, _band * 0.23, 0.05] call _fnc_place;
            [_ctrls get "needle", 0.035 + _tension * 0.23 - 0.002, 0.125, 0.004, 0.07] call _fnc_place;
            (_ctrls get "needle") ctrlSetBackgroundColor ([[0.95, 0.30, 0.22, 1], [0.95, 0.92, 0.80, 1]] select (abs (_tension - _centre) <= _band / 2));

            (_display displayCtrl IDC_LP_READOUT) ctrlSetText format [localize "STR_tlbi_lockpick_lcd_rake", call _setCount, _n, round (_tension * 100)];
        };
    };

    // ------------------------------------------------------------------------
    case TECH_DIAL: {
        call {
            private _angle = _state get "angle";
            private _turn = _state get "turn";
            private _strain = _state get "strain";
            private _limit = _state get "strainLimit";

            if (_left) then { _angle = _angle - 70 * _dt };
            if (_right) then { _angle = _angle + 70 * _dt };
            _angle = _angle + (random 2 - 1) * (_state get "shake") * _dt;
            _angle = (_angle max -90) min 90;

            if (_hold) then {
                private _off = ((abs (_angle - (_state get "sweet"))) - (_state get "width") / 2) max 0;
                private _max = 90 * (((1 - _off / (_state get "falloff")) max 0) min 1);

                _turn = (_turn + 110 * _dt) min _max;

                if (_turn >= _max - 0.5 && {_max < 89.5}) then {
                    _strain = _strain + _dt;
                } else {
                    _strain = (_strain - _dt) max 0;
                };
            } else {
                _turn = (_turn - 160 * _dt) max 0;
                _strain = (_strain - 1.5 * _dt) max 0;
            };

            _state set ["angle", _angle];
            _state set ["turn", _turn];
            _state set ["strain", _strain];

            if (_strain > _limit) exitWith {
                [localize "STR_tlbi_lockpick_msg_strain"] call tlbi_lockpick_fnc_mistake;
            };

            if (_turn >= 89.5) exitWith { call tlbi_lockpick_fnc_finish };

            private _plugFrame = (round (_turn / PLUG_STEP) max 0) min 18;
            if (_plugFrame != (_state get "plugFrame")) then {
                _state set ["plugFrame", _plugFrame];
                (_ctrls get "plug") ctrlSetText format [QPATHTOF(data\lp_plug_%1_ca.paa), [_plugFrame, 2] call CBA_fnc_formatNumber];
            };

            private _pickFrame = (round ((_angle + 90) / PICK_STEP) max 0) min 30;
            if (_pickFrame != (_state get "pickFrame")) then {
                _state set ["pickFrame", _pickFrame];
                (_ctrls get "pick") ctrlSetText format [QPATHTOF(data\lp_dpick_%1_ca.paa), [_pickFrame, 2] call CBA_fnc_formatNumber];
            };

            // The pick shakes in the hand while the plug is being forced.
            (_ctrls get "pickRect") params ["_px", "_py", "_pw", "_ph"];
            private _shake = [0, 0.006 * (_strain / _limit)] select (_strain > 0);
            [_ctrls get "pick", _px + (random 2 - 1) * _shake, _py + (random 2 - 1) * _shake, _pw, _ph] call _fnc_place;

            private _k = (_strain / _limit) min 1;
            [_ctrls get "strain", 0.74, 0.87, 0.22 * _k, 0.03] call _fnc_place;
            (_ctrls get "strain") ctrlSetBackgroundColor [0.72 + 0.23 * _k, 0.58 - 0.34 * _k, 0.22, 1];

            (_display displayCtrl IDC_LP_READOUT) ctrlSetText format [localize "STR_tlbi_lockpick_lcd_dial", round _turn, round (_k * 100)];
        };
    };
};
