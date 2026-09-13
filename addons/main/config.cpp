#include "script_version.hpp"

#define QUOTE(var1) #var1
#define VERSION MAJOR.MINOR
#define VERSION_STR MAJOR.MINOR.PATCHLVL.BUILD
#define VERSION_AR MAJOR,MINOR,PATCHLVL,BUILD

class CfgPatches {
    class tlbi_main {
        name = "TLB Interactions - Main";
        author = "TLB";
        url = "";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.02;
        requiredAddons[] = {"cba_main"};
        version = VERSION_STR;
        versionStr = QUOTE(VERSION_STR);
        versionAr[] = {VERSION_AR};
        skipWhenMissingDependencies = 1;
    };
};

// Shared CBA settings category, so every future TLB Interactions module lands
// in the same place in the options menu.
class CfgSettings {
    class CBA {
        class Versioning {
            class tlbi {
                class dependencies {
                    CBA[] = {"cba_main", {3,15,7}, "true"};
                };
            };
        };
    };
};
