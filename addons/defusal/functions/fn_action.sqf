#include "..\script_component.hpp"
/*
 * Author: TLB
 * Routes the three shared action buttons to whatever they mean for the kind of
 * device on the board.
 *
 *            button 1         button 2       button 3
 *   IED      TEST VOLTS       TEST CONT.     CUT
 *   mine     PROD (tool)      DIG (tool)     SEAT PIN
 *   tripwire CHECK TENSION    SEAT PIN       CUT WIRE
 *
 * Arguments:
 * 0: Button slot, 1-3 <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_slot"];

switch (uiNamespace getVariable ["tlbi_defusal_kind", KIND_IED]) do {
    case KIND_MINE: {
        switch (_slot) do {
            case 1: { [TOOL_PROD] call tlbi_defusal_fnc_mineTool };
            case 2: { [TOOL_DIG] call tlbi_defusal_fnc_mineTool };
            case 3: { call tlbi_defusal_fnc_seatPin };
        };
    };
    case KIND_TRIP: {
        switch (_slot) do {
            case 1: { call tlbi_defusal_fnc_tripTension };
            case 2: { call tlbi_defusal_fnc_seatPin };
            case 3: { call tlbi_defusal_fnc_tripCut };
        };
    };
    default {
        switch (_slot) do {
            case 1: { [METER_VOLTS] call tlbi_defusal_fnc_probeWire };
            case 2: { [METER_OHMS] call tlbi_defusal_fnc_probeWire };
            case 3: { call tlbi_defusal_fnc_cutWire };
        };
    };
};
