#include "..\script_component.hpp"
/*
 * Author: TLB
 * Reads one option from the settings module covering a position.
 *
 * Modules work by area: every module of the class whose Eden area contains the
 * position is a candidate, and the smallest area wins, so a module over one
 * building can refine a larger one over the whole town. Options set to their
 * "use settings" value (-1) fall through to the default.
 *
 * Module attributes are stored on the module under the attribute class name;
 * the "<module class>_<name>" property name is checked as well.
 *
 * Arguments:
 * 0: Module class <STRING>
 * 1: Position <ARRAY>
 * 2: Attribute name <STRING>
 * 3: Default <ANY> (default: -1)
 *
 * Return Value:
 * The module's value, or the default <NUMBER or ANY>
 */

params ["_class", "_position", "_name", ["_default", -1]];

private _best = objNull;
private _bestSize = 1e12;

{
    (_x getVariable ["objectArea", [5, 5, 0, false, -1]]) params [["_a", 5], ["_b", 5], ["_angle", 0], ["_rectangle", false]];

    if (_position inArea [getPos _x, _a, _b, _angle, _rectangle] && {_a * _b < _bestSize}) then {
        _best = _x;
        _bestSize = _a * _b;
    };
} forEach (allMissionObjects _class);

if (isNull _best) exitWith { _default };

private _value = _best getVariable [_name, _best getVariable [format ["%1_%2", _class, _name], -1]];

if (_value isEqualType "") then { _value = parseNumber _value };
if (_value isEqualType true) then { _value = [0, 1] select _value };
if (!(_value isEqualType 0) || {_value < 0}) exitWith { _default };

_value
