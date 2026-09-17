#include "..\script_component.hpp"
/*
 * Author: TLB
 * Uses the tool in hand on one soil cell.
 *
 * PROD reports what is under the cell: clear, stone or metal. The rim of the
 * mine reads as metal, and so does its pressure plate - if the prod survives
 * coming down on it.
 *
 * DIG removes the soil. Digging around the mine is the whole point; digging
 * straight down onto an anti-personnel mine's pressure plate fires it. When all
 * eight rim cells are out, the loose soil over the fuze comes away with them
 * and the mine is ready to be pinned.
 *
 * Arguments:
 * 0: Cell index <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_index"];

if (uiNamespace getVariable ["tlbi_defusal_busy", false]) exitWith {};

private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
private _mine = _explosive getVariable ["tlbi_defusal_mine", []];

if (count _mine <= MN_AT) exitWith {};
if ((_mine select MN_STAGE) != MSTAGE_LOCATE) exitWith {};
if (((_mine select MN_DUG) select _index) == 1) exitWith {};

private _tool = uiNamespace getVariable ["tlbi_defusal_tool", TOOL_PROD];

if (_tool == TOOL_PROD && {((_mine select MN_PROBED) select _index) != -1}) exitWith {};

uiNamespace setVariable ["tlbi_defusal_target", _index];
uiNamespace setVariable ["tlbi_defusal_targetTool", _tool];

private _digging = _tool == TOOL_DIG;

[
    ([tlbi_defusal_prodTime, tlbi_defusal_digTime] select _digging) / (tlbi_defusal_clearSpeed max 0.05),
    localize (["STR_tlbi_defusal_progress_prod", "STR_tlbi_defusal_progress_dig"] select _digging),
    {
        private _unit = uiNamespace getVariable ["tlbi_defusal_unit", objNull];
        private _explosive = uiNamespace getVariable ["tlbi_defusal_explosive", objNull];
        private _index = uiNamespace getVariable ["tlbi_defusal_target", -1];
        private _tool = uiNamespace getVariable ["tlbi_defusal_targetTool", TOOL_PROD];
        private _mine = _explosive getVariable ["tlbi_defusal_mine", []];

        if (count _mine <= MN_AT || {_index < 0}) exitWith {};

        _mine params ["_cols", "", "_cx", "_cy", "_dug", "_probed", "_stones", "", "", "_at"];

        private _col = _index % _cols;
        private _row = floor (_index / _cols);
        private _plate = _col == _cx && {_row == _cy};
        private _rim = !_plate && {abs (_col - _cx) <= 1} && {abs (_row - _cy) <= 1};

        if (_tool == TOOL_PROD) exitWith {
            if (_plate && {random 1 < tlbi_defusal_plateProdRisk * DIFF(DIFF_PLATE) * ([1, 0.15] select _at)}) exitWith {
                [localize "STR_tlbi_defusal_mine_msg_plate_prod"] call ace_common_fnc_displayTextStructured;
                [_unit, _explosive, true] call tlbi_defusal_fnc_fail;
            };

            private _result = [[PROD_CLEAR, PROD_STONE] select (_index in _stones), PROD_METAL] select (_plate || _rim);
            private _results = +_probed;
            _results set [_index, _result];
            _mine set [MN_PROBED, _results];

            _explosive setVariable ["tlbi_defusal_mine", _mine, true];
            [] call tlbi_defusal_fnc_refreshBoard;
        };

        if (_plate && {!_at}) exitWith {
            [localize "STR_tlbi_defusal_mine_msg_plate_dig"] call ace_common_fnc_displayTextStructured;
            [_unit, _explosive, true] call tlbi_defusal_fnc_fail;
        };

        private _cellsDug = +_dug;
        _cellsDug set [_index, 1];

        private _exposed = true;
        for "_dc" from -1 to 1 do {
            for "_dr" from -1 to 1 do {
                if !(_dc == 0 && {_dr == 0}) then {
                    if ((_cellsDug select ((_cy + _dr) * _cols + _cx + _dc)) == 0) then { _exposed = false };
                };
            };
        };

        if (_exposed) then {
            _cellsDug set [_cy * _cols + _cx, 1];
            _mine set [MN_STAGE, MSTAGE_PIN];
        };

        _mine set [MN_DUG, _cellsDug];
        _explosive setVariable ["tlbi_defusal_mine", _mine, true];
        [] call tlbi_defusal_fnc_refreshBoard;

        if (_plate) then { [localize "STR_tlbi_defusal_mine_msg_plate_at"] call tlbi_defusal_fnc_setStatus };
        if (_exposed) then { [format [localize "STR_tlbi_defusal_mine_msg_exposed", ["tlbi_defusal_seatPin"] call tlbi_defusal_fnc_keyName]] call tlbi_defusal_fnc_setStatus };
    }
] call tlbi_defusal_fnc_runAction;
