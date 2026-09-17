#include "..\script_component.hpp"
/*
 * Author: TLB
 * Reads one option for a single explosive: a value set on it with the Zeus
 * Explosive settings module wins, then the Eden module covering it.
 *
 * Arguments:
 * 0: Explosive <OBJECT>
 * 1: Option name <STRING>
 * 2: Default <ANY> (default: -1)
 *
 * Return Value:
 * The option's value, or the default <NUMBER or ANY>
 */

params ["_explosive", "_name", ["_default", -1]];

private _value = _explosive getVariable ["tlbi_defusal_zeus_" + _name, -1];

if (_value isEqualType 0 && {_value >= 0}) exitWith { _value };

["tlbi_moduleExplosive", getPos _explosive, _name, _default] call tlbi_defusal_fnc_moduleValue
