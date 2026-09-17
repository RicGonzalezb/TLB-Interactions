#include "..\script_component.hpp"
/*
 * Author: TLB
 * Brings the tripwire board in line with its stored state: parted grass, device
 * selection and pins, the three actions, the LCD and the status line.
 *
 * Return Value:
 * None
 */

private _display = uiNamespace getVariable ["tlbi_defusal_display", displayNull];

if (isNull _display) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

if (count _trip <= TR_SLIPS) exitWith {};

_trip params ["", "", "", "_fuzes", "", "_tufts", "_stage", "_tension", "_slips"];

private _busy = uiNamespace getVariable ["tlbi_defusal_busy", false];
private _pinning = uiNamespace getVariable ["tlbi_defusal_pinning", false];
private _selected = uiNamespace getVariable ["tlbi_defusal_selectedFuze", -1];
private _working = _stage == TSTAGE_WORK;

{
    _x params ["_pic", "_hot"];

    private _gone = (_tufts select _forEachIndex) select TF_CLEARED;

    _pic ctrlShow (!_gone);
    _hot ctrlShow (!_gone);

    // Grass stays partable after the wire is traced. A decorative tuft can land
    // on a device, and a disabled hotspot over it would still block the click
    // that selects the device - so the tuft has to remain clearable.
    _hot ctrlEnable (!_busy);
} forEach (uiNamespace getVariable ["tlbi_defusal_tripTufts", []]);

{
    _x params ["_pic", "_hot", "_pin"];

    private _pinned = (_fuzes select _forEachIndex) select 2;

    _pic ctrlSetTextColor ([[1, 1, 1, 1], [1, 0.86, 0.52, 1]] select (_forEachIndex == _selected));

    if !(_pinning && {_forEachIndex == _selected}) then {
        _pin ctrlShow _pinned;
    };

    _hot ctrlEnable (!_busy && {_working} && {!_pinned});
} forEach (uiNamespace getVariable ["tlbi_defusal_tripFuzes", []]);

private _selectedPinned = _selected >= 0 && {_selected < count _fuzes} && {(_fuzes select _selected) select 2};

(_display displayCtrl IDC_BTN_A1) ctrlSetText localize "STR_tlbi_defusal_btn_tension";
(_display displayCtrl IDC_BTN_A2) ctrlSetText localize "STR_tlbi_defusal_btn_pin";
(_display displayCtrl IDC_BTN_A3) ctrlSetText localize "STR_tlbi_defusal_btn_cutwire";

(_display displayCtrl IDC_BTN_A1) ctrlEnable (!_busy && {_working} && {_tension == -1});
(_display displayCtrl IDC_BTN_A2) ctrlEnable (_pinning || {!_busy && {_working} && {_selected >= 0} && {!_selectedPinned}});
(_display displayCtrl IDC_BTN_A3) ctrlEnable (!_busy && {_working});
(_display displayCtrl IDC_BTN_CLOSE) ctrlEnable (!_busy);

private _tensionText = localize ([
    "STR_tlbi_defusal_tension_unknown",
    "STR_tlbi_defusal_tension_slack",
    "STR_tlbi_defusal_tension_taut"
] select (_tension + 1));

(_display displayCtrl IDC_READOUT) ctrlSetText ([
    localize "STR_tlbi_defusal_lcd_trace",
    format [localize "STR_tlbi_defusal_lcd_trip", _tensionText, {_x select 2} count _fuzes, count _fuzes]
] select _working);

if (_pinning) then {
    (_display displayCtrl IDC_READOUT) ctrlSetText format [localize "STR_tlbi_defusal_lcd_pin", _slips, PIN_SLIPS, toUpper (["tlbi_defusal_seatPin"] call tlbi_defusal_fnc_keyName)];
};

(_display displayCtrl IDC_STAGE) ctrlSetText localize (["STR_tlbi_defusal_trip_stage_trace", "STR_tlbi_defusal_trip_stage_work"] select _working);

if (!_busy || _pinning) then {
    [format [localize (call {
        if (!_working) exitWith { "STR_tlbi_defusal_trip_msg_trace" };
        if (_pinning) exitWith { "STR_tlbi_defusal_pin_msg_hold" };
        "STR_tlbi_defusal_trip_msg_work"
    }), ["tlbi_defusal_seatPin"] call tlbi_defusal_fnc_keyName]] call tlbi_defusal_fnc_setStatus;
};
