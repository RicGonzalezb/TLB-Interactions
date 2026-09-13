#include "script_component.hpp"
#include "..\main\script_version.hpp"

#define VERSION_STR MAJOR.MINOR.PATCHLVL.BUILD
#define VERSION_AR MAJOR,MINOR,PATCHLVL,BUILD

class CfgPatches {
    class tlbi_lockpick {
        name = "TLB Interactions - Lockpicking";
        author = "TLB";
        url = "";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.02;
        // tlbi_defusal provides the shared control styles and chrome textures;
        // A3_Ui_F the controls group the board is built in.
        requiredAddons[] = {"A3_Ui_F", "tlbi_main", "tlbi_defusal", "cba_main","ace_common", "ace_interact_menu", "ace_interaction"};
        version = VERSION_STR;
        versionStr = QUOTE(VERSION_STR);
        versionAr[] = {VERSION_AR};
        skipWhenMissingDependencies = 1;
    };
};

class CfgFunctions {
    class tlbi_lockpick {
        tag = "tlbi_lockpick";

        class lockpick {
            file = "tlbi\addons\lockpick\functions";

            class preInit { preInit = 1; };
            class postInit { postInit = 1; };

            class doorAction {};
            class doorClass {};
            class doorHelpers {};
            class doorRun {};
            class doors {};
            class drawCutaway {};
            class drawFace {};
            class finish {};
            class hasTool {};
            class isInside {};
            class lockTick {};
            class roll {};
            class mistake {};
            class onUnload {};
            class press {};
            class refresh {};
            class setStatus {};
            class start {};
            class tick {};
            class tspPick {};
            class unlock {};
        };
    };
};

#include "gui\dialog.hpp"
