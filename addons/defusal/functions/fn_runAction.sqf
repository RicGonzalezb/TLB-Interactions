#include "..\script_component.hpp"
/*
 * Author: TLB
 * Runs a timed action on the board: locks every control, drives the progress
 * bar over the LCD, and then fires the callback.
 *
 * The callback deliberately does NOT depend on the display still being open. A
 * cut resolves whether or not the player managed to get the board shut - once
 * the pliers close on a wire the outcome is already decided.
 *
 * Arguments:
 * 0: Duration in seconds <NUMBER>
 * 1: Label <STRING>
 * 2: On finish <CODE>
 *
 * Return Value:
 * None
 */

params ["_duration", "_label", "_onFinish"];

uiNamespace setVariable ["tlbi_defusal_busy", true];

private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];
private _px = 0;
private _pw = 0;

if (!isNull _display) then {
    { (_display displayCtrl _x) ctrlEnable false } forEach [IDC_BTN_VOLTS, IDC_BTN_OHMS, IDC_BTN_CUT, IDC_BTN_CLOSE];
    { _x ctrlEnable false } forEach (uiNamespace getVariable ["tlbi_defusal_hotspots", []]);

    { (_display displayCtrl _x) ctrlShow true } forEach [IDC_PROGRESS_FRAME, IDC_PROGRESS_BAR, IDC_PROGRESS_TEXT];
    { (_display displayCtrl _x) ctrlShow false } forEach [IDC_READOUT, IDC_STAGE];

    (_display displayCtrl IDC_PROGRESS_TEXT) ctrlSetText _label;

    private _frame = ctrlPosition (_display displayCtrl IDC_PROGRESS_FRAME);
    _px = _frame select 0;
    _pw = _frame select 2;
};

[{
    params ["_args", "_pfhID"];
    _args params ["_start", "_duration", "_onFinish", "_px", "_pw"];

    private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];
    private _progress = ((diag_tickTime - _start) / _duration) min 1;

    if (!isNull _display) then {
        private _bar = _display displayCtrl IDC_PROGRESS_BAR;
        (ctrlPosition _bar) params ["", "_by", "", "_bh"];
        _bar ctrlSetPosition [_px + 3 * pixelW, _by, (_pw - 6 * pixelW) * _progress, _bh];
        _bar ctrlCommit 0;
    };

    if (_progress < 1) exitWith {};

    _pfhID call CBA_fnc_removePerFrameHandler;

    uiNamespace setVariable ["tlbi_defusal_busy", false];

    if (!isNull _display) then {
        { (_display displayCtrl _x) ctrlShow false } forEach [IDC_PROGRESS_FRAME, IDC_PROGRESS_BAR, IDC_PROGRESS_TEXT];
        { (_display displayCtrl _x) ctrlShow true } forEach [IDC_READOUT, IDC_STAGE];
    };

    // Refresh before the callback, not after: it re-enables whatever the stage
    // allows even when the callback bails out early, and it leaves any status
    // message the callback sets - "device uncovered" and the like - on screen.
    [] call tlbi_defusal_fnc_refreshBoard;

    call _onFinish;
}, 0, [diag_tickTime, _duration max 0.1, _onFinish, _px, _pw]] call CBA_fnc_addPerFrameHandler;
