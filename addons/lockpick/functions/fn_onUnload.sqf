#include "..\script_component.hpp"
/*
 * Author: TLB
 * Board closed. The tick handler notices the display is gone and removes
 * itself; this only drops the UI state. Picking progress is not kept - once the
 * tension wrench comes out, set pins fall back.
 *
 * Return Value:
 * None
 */

uiNamespace setVariable ["tlbi_lockpick_display", displayNull];
uiNamespace setVariable ["tlbi_lockpick_state", createHashMap];
