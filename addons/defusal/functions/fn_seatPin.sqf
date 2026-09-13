#include "..\script_component.hpp"
/*
 * Author: TLB
 * Starts seating a safety pin: in the fuze of an exposed mine, or in the
 * selected tripwire device. The holding itself is fn_steadyPin.
 *
 * Return Value:
 * None
 */

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _limit = PIN_SLIPS;

private _onFired = {
    [localize "STR_tlbi_defusal_pin_msg_fired"] call ace_common_fnc_displayTextStructured;
    [
        uiNamespace getVariable ["tlbi_defusal_unit", objNull],
        uiNamespace getVariable ["tlbi_defusal_explosive", objNull],
        true
    ] call tlbi_defusal_fnc_fail;
};

switch (uiNamespace getVariable ["tlbi_defusal_kind", KIND_IED]) do {
    case KIND_MINE: {
        private _mine = _explosive getVariable ["tlbi_defusal_mine", []];

        if (count _mine <= MN_AT) exitWith {};
        if ((_mine select MN_STAGE) != MSTAGE_PIN) exitWith {};

        [
            _limit,
            _mine select MN_SLIPS,
            {
                [
                    uiNamespace getVariable ["tlbi_defusal_unit", objNull],
                    uiNamespace getVariable ["tlbi_defusal_explosive", objNull]
                ] call tlbi_defusal_fnc_succeed;
            },
            {
                params ["_slips"];
                private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
                private _mine = _explosive getVariable ["tlbi_defusal_mine", []];

                if (count _mine > MN_AT) then {
                    _mine set [MN_SLIPS, _slips];
                    _explosive setVariable ["tlbi_defusal_mine", _mine, true];
                };

                [format [localize "STR_tlbi_defusal_pin_msg_slip", _slips, PIN_SLIPS]] call tlbi_defusal_fnc_setStatus;
            },
            _onFired,
            uiNamespace getVariable ["tlbi_defusal_minePin", controlNull]
        ] call tlbi_defusal_fnc_steadyPin;
    };

    case KIND_TRIP: {
        private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

        if (count _trip <= TR_SLIPS) exitWith {};
        if ((_trip select TR_STAGE) != TSTAGE_WORK) exitWith {};

        private _index = uiNamespace getVariable ["tlbi_defusal_selectedFuze", -1];
        private _fuzes = _trip select TR_FUZES;

        if (_index < 0 || {_index >= count _fuzes}) exitWith {
            [localize "STR_tlbi_defusal_trip_msg_select"] call tlbi_defusal_fnc_setStatus;
        };
        if ((_fuzes select _index) select 2) exitWith {};

        private _ctrls = uiNamespace getVariable ["tlbi_defusal_tripFuzes", []];
        private _pinCtrl = controlNull;
        if (_index < count _ctrls) then { _pinCtrl = (_ctrls select _index) select 2 };

        [
            _limit,
            _trip select TR_SLIPS,
            {
                private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
                private _trip = _explosive getVariable ["tlbi_defusal_trip", []];
                private _index = uiNamespace getVariable ["tlbi_defusal_selectedFuze", -1];

                if (count _trip <= TR_SLIPS || {_index < 0}) exitWith {};

                private _fuzes = +(_trip select TR_FUZES);
                private _fuze = +(_fuzes select _index);
                _fuze set [2, true];
                _fuzes set [_index, _fuze];
                _trip set [TR_FUZES, _fuzes];
                _explosive setVariable ["tlbi_defusal_trip", _trip, true];

                uiNamespace setVariable ["tlbi_defusal_selectedFuze", -1];
                [] call tlbi_defusal_fnc_refreshBoard;
                [localize "STR_tlbi_defusal_trip_msg_pinned"] call tlbi_defusal_fnc_setStatus;
            },
            {
                params ["_slips"];
                private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
                private _trip = _explosive getVariable ["tlbi_defusal_trip", []];

                if (count _trip > TR_SLIPS) then {
                    _trip set [TR_SLIPS, _slips];
                    _explosive setVariable ["tlbi_defusal_trip", _trip, true];
                };

                [format [localize "STR_tlbi_defusal_pin_msg_slip", _slips, PIN_SLIPS]] call tlbi_defusal_fnc_setStatus;
            },
            _onFired,
            _pinCtrl
        ] call tlbi_defusal_fnc_steadyPin;
    };
};
