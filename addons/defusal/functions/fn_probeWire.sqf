#include "..\script_component.hpp"
/*
 * Author: TLB
 * Puts the meter across the selected conductor in one of its two modes.
 *
 * Voltage finds the conductors carrying supply. Continuity finds the ones that
 * actually reach the initiator. Neither answers the question on its own - the
 * firing line is the conductor that reads on both, and there is always at least
 * one decoy sitting on each single reading to prove it.
 *
 * Readings are unlimited; a meter does not run out. What a reading costs is
 * time, and - for continuity - risk: a continuity test drives its own current
 * through whatever it is clipped to, and on the firing line that current goes
 * straight through the detonator. So the skilled play is to volt-test first
 * and then prove the firing line by elimination, never putting continuity on
 * it at all: with two live conductors left, one reading O.L means the other is
 * the firing line.
 *
 * Arguments:
 * 0: Meter mode <NUMBER> - METER_VOLTS or METER_OHMS
 *
 * Return Value:
 * None
 */

params ["_mode"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _cable = uiNamespace getVariable ["tlbi_defusal_selected", -1];
private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

if (_puzzle isEqualTo []) exitWith {};
if ((_puzzle select PZ_STAGE) != STAGE_TEST) exitWith {};

if (_cable < 0) exitWith {
    [localize "STR_tlbi_defusal_msg_no_selection"] call tlbi_defusal_fnc_setStatus;
};

private _slot = [PZ_VOLTS, PZ_OHMS] select (_mode == METER_OHMS);

if (((_puzzle select _slot) select _cable) != -1) exitWith {
    [localize "STR_tlbi_defusal_msg_already_probed"] call tlbi_defusal_fnc_setStatus;
};

private _label = format [
    localize (["STR_tlbi_defusal_progress_volts", "STR_tlbi_defusal_progress_ohms"] select (_mode == METER_OHMS)),
    _cable + 1
];

// Set before the action starts: the callback reads it when the meter settles.
uiNamespace setVariable ["tlbi_defusal_mode", _mode];

[tlbi_defusal_probeTime, _label, {
    private _unit = uiNamespace getVariable ["tlbi_defusal_unit", objNull];
    private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
    private _cable = uiNamespace getVariable ["tlbi_defusal_selected", -1];
    private _mode = uiNamespace getVariable ["tlbi_defusal_mode", METER_VOLTS];
    private _puzzle = _explosive getVariable ["tlbi_defusal_puzzle", []];

    if (_puzzle isEqualTo [] || {_cable < 0}) exitWith {};

    if (_mode == METER_OHMS && {_cable == (_puzzle select PZ_LIVE)} && {random 1 < tlbi_defusal_ohmsRisk * DIFF(DIFF_RISK)}) exitWith {
        [localize "STR_tlbi_defusal_msg_ohms_fired"] call ace_common_fnc_displayTextStructured;

        // Forced: the detonator has already fired, so no spare cut and no
        // countdown applies.
        [_unit, _explosive, true] call tlbi_defusal_fnc_fail;
    };

    private _slot = [PZ_VOLTS, PZ_OHMS] select (_mode == METER_OHMS);
    private _property = [CB_VOLTS, CB_OHMS] select (_mode == METER_OHMS);

    private _results = +(_puzzle select _slot);
    _results set [_cable, ((_puzzle select PZ_CABLES) select _cable) select _property];
    _puzzle set [_slot, _results];

    _explosive setVariable ["tlbi_defusal_puzzle", _puzzle, true];

    [] call tlbi_defusal_fnc_refreshBoard;
}] call tlbi_defusal_fnc_runAction;
