#include "script_component.hpp"
#include "..\main\script_version.hpp"

#define VERSION_STR MAJOR.MINOR.PATCHLVL.BUILD
#define VERSION_AR MAJOR,MINOR,PATCHLVL,BUILD

class CfgPatches {
    class tlbi_defusal {
        name = "TLB Interactions - Interactive Defusal";
        author = "TLB";
        url = "";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.02;
        requiredAddons[] = {"tlbi_main", "cba_main", "ace_explosives", "ace_interact_menu"};
        version = VERSION_STR;
        versionStr = QUOTE(VERSION_STR);
        versionAr[] = {VERSION_AR};
        skipWhenMissingDependencies = 1;
    };
};

class CfgFunctions {
    class tlbi_defusal {
        tag = "tlbi_defusal";

        class defusal {
            file = "tlbi\addons\defusal\functions";

            // Init runs through CfgFunctions rather than CBA's
            // Extended_*_EventHandlers: it is engine-native, needs no
            // hand-written pbo path, and cannot fail silently the way a
            // preprocessFileLineNumbers on a mistyped path does.
            class preInit { preInit = 1; };
            class postInit { postInit = 1; };

            class action {};
            class autoClear {};
            class brushDirt {};
            class classify {};
            class cutTape {};
            class cutWire {};
            class drawBoard {};
            class mineCell {};
            class mineDraw {};
            class mineGenerate {};
            class mineRefresh {};
            class mineTool {};
            class seatPin {};
            class steadyPin {};
            class tripCut {};
            class tripDraw {};
            class tripGenerate {};
            class tripRefresh {};
            class tripSelect {};
            class tripTension {};
            class tripTuft {};
            class fail {};
            class generatePuzzle {};
            class onBoardUnload {};
            class openBoard {};
            class probeWire {};
            class refreshBoard {};
            class runAction {};
            class selectWire {};
            class setStatus {};
            class startDefuse {};
            class succeed {};
        };
    };
};

// NOTE: do not patch ACE's ACE_DefuseObject / ACE_DefuseObject_Large in
// CfgVehicles to redirect the defuse statement. Re-opening those classes from a
// separate addon drops members they inherit (scope, side, ...) and the engine
// then throws "No entry ... .side" on any mission load. The runtime replacement
// of ace_explosives_fnc_startDefuse in fn_postInit is the supported way to do
// this, and it covers every explosive because ACE compiles that statement
// string at click time.

#include "gui\defines.hpp"
#include "gui\dialog.hpp"
