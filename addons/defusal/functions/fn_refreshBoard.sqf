#include "..\script_component.hpp"
/*
 * Author: TLB
 * Brings every stateful part of the board in line with the stored puzzle: which
 * soil and tape is still on the device, what can be clicked at this stage, tag
 * and cable highlighting, the per-conductor readings and the LCD.
 *
 * Interactivity is decided here and nowhere else, so a stage can never be
 * skipped by clicking something that happens to still be enabled.
 *
 * Return Value:
 * None
 */

// Auto-clear (setting): queue the next clump, rim cell or tuft for the frame
// after this refresh, once any action callback has stored its result. Only one
// call is ever queued; fn_autoClear does nothing while an action is running.
if ((missionNamespace getVariable ["tlbi_defusal_autoClear", false]) && {!(uiNamespace getVariable ["tlbi_defusal_autoQueued", false])}) then {
    uiNamespace setVariable ["tlbi_defusal_autoQueued", true];
    [{
        uiNamespace setVariable ["tlbi_defusal_autoQueued", false];
        call tlbi_defusal_fnc_autoClear;
    }] call CBA_fnc_execNextFrame;
};

// Mines and tripwires have their own refresh; this file refreshes the IED.
private _kind = uiNamespace getVariable ["tlbi_defusal_kind", KIND_IED];
if (_kind == KIND_MINE) exitWith { call tlbi_defusal_fnc_mineRefresh };
if (_kind == KIND_TRIP) exitWith { call tlbi_defusal_fnc_tripRefresh };

private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];

if (isNull _display) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (_puzzle isEqualTo []) exitWith {};

_puzzle params ["_count", "_cables", "", "_stage", "_volts", "_ohms", "", "_deadends", "_dirt", "_tape"];

private _busy = uiNamespace getVariable ["tlbi_defusal_busy", false];
private _selected = uiNamespace getVariable ["tlbi_defusal_selected", -1];
private _testing = _stage == STAGE_TEST;

// --- Soil -------------------------------------------------------------------
// A clump takes two brushes: the first knocks it down to a thinner residue, the
// second clears it.
{
    _x params ["_pic", "_hot", "_rect"];
    private _hp = (_dirt select _forEachIndex) select DT_HP;

    if (_hp <= 0) then {
        _pic ctrlShow false;
        _hot ctrlShow false;
    } else {
        _rect params ["_rx", "_ry", "_rw", "_rh"];
        private _k = [0.64, 1] select (_hp >= 2);

        _pic ctrlSetPosition [_rx + _rw * (1 - _k) / 2, _ry + _rh * (1 - _k) / 2, _rw * _k, _rh * _k];
        _pic ctrlSetTextColor [1, 1, 1, [0.72, 1] select (_hp >= 2)];
        _pic ctrlCommit 0;

        _hot ctrlEnable (!_busy && {_stage == STAGE_EXCAVATE});
    };
} forEach (uiNamespace getVariable ["tlbi_defusal_dirtCtrls", []]);

// --- Tape -------------------------------------------------------------------
{
    _x params ["_pic", "_hot"];

    if !((_tape select _forEachIndex) select TP_INTACT) then {
        _pic ctrlShow false;
        _hot ctrlShow false;
    } else {
        _hot ctrlEnable (!_busy && {_stage == STAGE_TAPE});
    };
} forEach (uiNamespace getVariable ["tlbi_defusal_tapeCtrls", []]);

// --- Tags -------------------------------------------------------------------
{
    _x params ["_pic", "_hot", "_label"];

    private _cable = _forEachIndex;
    private _cut = _cable in _deadends;

    _pic ctrlSetTextColor ([
        [[0.96, 0.93, 0.82, 1], [1, 0.82, 0.38, 1]] select (_cable == _selected),
        [0.42, 0.40, 0.36, 1]
    ] select _cut);

    _label ctrlSetText ([str (_cable + 1), format ["[%1]", _cable + 1]] select (_cable == _selected));
    _hot ctrlEnable (!_busy && {_testing} && {!_cut});
} forEach (uiNamespace getVariable ["tlbi_defusal_tags", []]);

// --- Cables -----------------------------------------------------------------
// Selection brightens the whole cable. With nothing to trace this gives away
// nothing, and it is the only way to see which tag owns which conductor.
{
    _x params ["_ctrl", "_colour"];

    _ctrl ctrlSetTextColor ([
        _colour,
        [
            1 - (1 - (_colour select 0)) * 0.45,
            1 - (1 - (_colour select 1)) * 0.45,
            1 - (1 - (_colour select 2)) * 0.45,
            1
        ]
    ] select (_forEachIndex == _selected));
} forEach (uiNamespace getVariable ["tlbi_defusal_cables", []]);

// --- Readings ---------------------------------------------------------------
private _fnc_volts = {
    [localize "STR_tlbi_defusal_meter_unknown", "0.00 V", "9.14 V"] select (_this + 1)
};
private _fnc_ohms = {
    [localize "STR_tlbi_defusal_meter_unknown", "O.L", "2.1 " + localize "STR_tlbi_defusal_meter_ohm"] select (_this + 1)
};

{
    private _cable = _forEachIndex;
    private _v = _volts select _cable;
    private _o = _ohms select _cable;

    private _text = "";
    if (_testing && {_v != -1 || {_o != -1}}) then {
        _text = format ["%1  %2", _v call _fnc_volts, _o call _fnc_ohms];
    };

    _x ctrlSetText _text;
    _x ctrlSetTextColor ([[0.82, 0.80, 0.70, 1], [0.98, 0.42, 0.32, 1]] select (_v == 1 && {_o == 1}));
} forEach (uiNamespace getVariable ["tlbi_defusal_readouts", []]);

private _lcd = localize "STR_tlbi_defusal_meter_off";

if (_testing) then {
    _lcd = localize "STR_tlbi_defusal_readout_none";

    if (_selected >= 0) then {
        _lcd = format [
            localize "STR_tlbi_defusal_readout",
            _selected + 1,
            localize ((tlbi_defusal_palette select ((_cables select _selected) select CB_COLOUR)) select 1),
            (_volts select _selected) call _fnc_volts,
            (_ohms select _selected) call _fnc_ohms
        ];
    };
};

(_display displayCtrl IDC_READOUT) ctrlSetText _lcd;

(_display displayCtrl IDC_STAGE) ctrlSetText localize ([
    "STR_tlbi_defusal_stage_excavate",
    "STR_tlbi_defusal_stage_tape",
    "STR_tlbi_defusal_stage_test"
] select _stage);

{
    (_display displayCtrl _x) ctrlEnable (!_busy && {_testing} && {_selected >= 0});
} forEach [IDC_BTN_VOLTS, IDC_BTN_OHMS, IDC_BTN_CUT];

(_display displayCtrl IDC_BTN_CLOSE) ctrlEnable (!_busy);

if (!_busy) then {
    [localize ([
        "STR_tlbi_defusal_msg_excavate",
        "STR_tlbi_defusal_msg_tape",
        "STR_tlbi_defusal_msg_instructions"
    ] select _stage)] call tlbi_defusal_fnc_setStatus;
};
