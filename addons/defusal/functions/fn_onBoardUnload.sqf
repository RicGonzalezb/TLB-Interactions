#include "..\script_component.hpp"
/*
 * Author: TLB
 * Board closed. Banks the time spent on the device so the anti-tamper clock
 * cannot be reset by backing off and coming back, and drops the UI state.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Exit code <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_display"];

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];

if (!isNull _explosive && {!(uiNamespace getVariable ["tlbi_defusal_resolved", false])}) then {
    private _openedAt = uiNamespace getVariable ["tlbi_defusal_openedAt", diag_tickTime];

    _explosive setVariable [
        "tlbi_defusal_elapsed",
        (_explosive getVariable ["tlbi_defusal_elapsed", 0]) + (diag_tickTime - _openedAt),
        true
    ];
};

uiNamespace setVariable ["tlbi_defusal_display", displayNull];
uiNamespace setVariable ["tlbi_defusal_cables", []];
uiNamespace setVariable ["tlbi_defusal_readouts", []];
uiNamespace setVariable ["tlbi_defusal_tags", []];
uiNamespace setVariable ["tlbi_defusal_dirtCtrls", []];
uiNamespace setVariable ["tlbi_defusal_tapeCtrls", []];
uiNamespace setVariable ["tlbi_defusal_hotspots", []];
uiNamespace setVariable ["tlbi_defusal_mineCells", []];
uiNamespace setVariable ["tlbi_defusal_tripTufts", []];
uiNamespace setVariable ["tlbi_defusal_tripFuzes", []];
uiNamespace setVariable ["tlbi_defusal_gauge", []];
uiNamespace setVariable ["tlbi_defusal_pinning", false];
uiNamespace setVariable ["tlbi_defusal_holding", false];
