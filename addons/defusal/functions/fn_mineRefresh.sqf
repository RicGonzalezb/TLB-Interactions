#include "..\script_component.hpp"
/*
 * Author: TLB
 * Brings the mine board in line with its stored state: which cells are dug,
 * prod results, the tool buttons, the LCD and the status line.
 *
 * Return Value:
 * None
 */

private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];

if (isNull _display) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _mine = _explosive getVariable ["tlbi_defusal_mine", []];

if (count _mine <= MN_AT) exitWith {};

_mine params ["", "", "", "", "_dug", "_probed", "", "_stage", "_slips"];

private _busy = uiNamespace getVariable ["tlbi_defusal_busy", false];
private _pinning = uiNamespace getVariable ["tlbi_defusal_pinning", false];
private _tool = uiNamespace getVariable ["tlbi_defusal_tool", TOOL_PROD];
private _locating = _stage == MSTAGE_LOCATE;

{
    _x params ["_soil", "_flag", "_hot"];

    private _isDug = (_dug select _forEachIndex) == 1;
    private _result = _probed select _forEachIndex;

    _soil ctrlShow (!_isDug);

    _flag ctrlShow (!_isDug && {_result != -1});
    if (_result != -1) then {
        _flag ctrlSetTextColor ([[0.93, 0.92, 0.86, 1], [0.52, 0.52, 0.50, 1], [0.92, 0.22, 0.16, 1]] select _result);
    };

    _hot ctrlShow (!_isDug);
    _hot ctrlEnable (!_busy && {_locating});
} forEach (uiNamespace getVariable ["tlbi_defusal_mineCells", []]);

private _prod = localize "STR_tlbi_defusal_btn_prod";
private _dig = localize "STR_tlbi_defusal_btn_dig";

(_display displayCtrl IDC_BTN_A1) ctrlSetText ([_prod, format ["[ %1 ]", _prod]] select (_tool == TOOL_PROD));
(_display displayCtrl IDC_BTN_A2) ctrlSetText ([_dig, format ["[ %1 ]", _dig]] select (_tool == TOOL_DIG));
(_display displayCtrl IDC_BTN_A3) ctrlSetText localize "STR_tlbi_defusal_btn_pin";

{
    (_display displayCtrl _x) ctrlEnable (!_busy && {_locating});
} forEach [IDC_BTN_A1, IDC_BTN_A2];

(_display displayCtrl IDC_BTN_A3) ctrlEnable (_pinning || {!_busy && {_stage == MSTAGE_PIN}});
(_display displayCtrl IDC_BTN_CLOSE) ctrlEnable (!_busy);

(_display displayCtrl IDC_READOUT) ctrlSetText ([
    format [localize "STR_tlbi_defusal_lcd_pin", _slips, PIN_SLIPS, toUpper (["tlbi_defusal_seatPin"] call tlbi_defusal_fnc_keyName)],
    format [localize "STR_tlbi_defusal_lcd_tool", [_prod, _dig] select (_tool == TOOL_DIG)]
] select _locating);

(_display displayCtrl IDC_STAGE) ctrlSetText localize (["STR_tlbi_defusal_mine_stage_pin", "STR_tlbi_defusal_mine_stage_locate"] select _locating);

if (!_busy || _pinning) then {
    [format [localize (call {
        if (_locating) exitWith { "STR_tlbi_defusal_mine_msg_locate" };
        if (_pinning) exitWith { "STR_tlbi_defusal_pin_msg_hold" };
        "STR_tlbi_defusal_mine_msg_exposed"
    }), ["tlbi_defusal_seatPin"] call tlbi_defusal_fnc_keyName]] call tlbi_defusal_fnc_setStatus;
};
