#include "..\script_component.hpp"
/*
 * Author: TLB
 * A repeatable roll between 0 and 1 for any value. Every machine that rolls the
 * same key gets the same number, which is what lets each client work out the
 * same locked doors without the server sending them.
 *
 * Arguments:
 * Key <ANY>
 *
 * Return Value:
 * 0..1 <NUMBER>
 */

private _c = toArray hashValue _this;

(((_c select 0) * 7919) + ((_c select 1) * 104729) + ((_c select 2) * 1301) + ((_c select 3) * 31) + (_c select 4)) % 10007 / 10007
