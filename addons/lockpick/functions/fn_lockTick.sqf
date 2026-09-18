#include "..\script_component.hpp"
/*
 * Author: TLB
 * Locks doors around the player, when tsp_breach is not loaded to do it. Runs
 * every three seconds from fn_postInit.
 *
 * There is no map-wide pass at mission start. The server picks one seed per
 * mission; each client rolls the buildings near it from that seed, the
 * building's class and position, and the door number - so every client arrives
 * at the same locked doors without a single public variable. Only a change a
 * player makes (unlocking, picking, locking) is broadcast, and a door that
 * already has a lock value - from a player, the mission or anything else - is
 * never rolled over.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

if !(missionNamespace getVariable ["tlbi_lockpick_doorActions", true]) exitWith {};

private _seed = missionNamespace getVariable "tlbi_lockpick_lockSeed";
if (isNil "_seed") exitWith {};

private _houseChance = missionNamespace getVariable ["tlbi_lockpick_lockHouses", 0.25];
private _doorChance = missionNamespace getVariable ["tlbi_lockpick_lockDoors", 0.5];

if (_houseChance <= 0 || {_doorChance <= 0} || {isNull player}) exitWith {};

// Avoid repeating the 100 m spatial query while the player stays in the same
// area, but keep a time fallback so dynamically spawned buildings are picked up.
// The 40 m movement threshold still leaves 60 m of overlap between scan radii.
private _scanPos = getPosATL player;
private _lastScanPos = missionNamespace getVariable ["tlbi_lockpick_lastScanPos", []];
private _now = diag_tickTime;
private _lastScanTime = missionNamespace getVariable ["tlbi_lockpick_lastScanTime", -1];

private _moved = _lastScanPos isEqualTo [] || {_scanPos distance2D _lastScanPos >= 40};
private _timedOut = _lastScanTime < 0 || {_now - _lastScanTime >= 30};

if !(_moved || _timedOut) exitWith {};

missionNamespace setVariable ["tlbi_lockpick_lastScanPos", _scanPos];
missionNamespace setVariable ["tlbi_lockpick_lastScanTime", _now];

// Blacklist changes are rare compared to lock ticks. Cache the normalized list
// and rebuild it only when the underlying CBA setting changes.
private _blacklistRaw = missionNamespace getVariable ["tlbi_lockpick_lockBlacklist", ""];

if (
    isNil "tlbi_lockpick_lockBlacklistCacheSource"
    || {tlbi_lockpick_lockBlacklistCacheSource != _blacklistRaw}
) then {
    tlbi_lockpick_lockBlacklistCacheSource = _blacklistRaw;
    tlbi_lockpick_lockBlacklistCache = (_blacklistRaw splitString (", ;" + toString [9, 10, 13])) apply {toLower _x};
};

private _blacklist = missionNamespace getVariable ["tlbi_lockpick_lockBlacklistCache", []];

{
    private _house = _x;

    if (isNil {_house getVariable "tlbi_lockpick_rolled"}) then {
        _house setVariable ["tlbi_lockpick_rolled", true];

        private _type = toLower typeOf _house;
        private _listed = (_blacklist findIf {
            if ((_x select [count _x - 1]) == "*") then {
                (_type find (_x select [0, count _x - 1])) == 0
            } else {
                _x == _type
            }
        }) != -1;

        if (!_listed) then {
            private _doors = [_house] call tlbi_lockpick_fnc_doors;
            private _where = (getPosWorld _house) apply {round _x};

            if (count _doors > 0 && {([_seed, _type, _where] call tlbi_lockpick_fnc_roll) < _houseChance}) then {
                {
                    _x params ["_id", "_door"];
                    private _variable = format ["bis_disabled_Door_%1", _id];

                    if (isNil {_house getVariable _variable}
                        && {(toLower _door find "glass") == -1}
                        && {([_seed, _type, _where, _id] call tlbi_lockpick_fnc_roll) < _doorChance}
                    ) then {
                        _house setVariable [_variable, 1];
                    };
                } forEach _doors;
            };
        };
    };
} forEach nearestObjects [player, ["House"], 100];
