// TLB Interactions - Lockpicking tools for players without tsp_breach.
//
// The board prefers tsp_breach's "Lock Pick Kit" and "Paperclip". These two
// stand in for them when tsp_breach is not loaded. When it is, they still exist
// (so saved loadouts keep working) but are hidden from the Arsenal, Zeus and the
// editor, so nobody sees two paperclips.
//
// That choice is made by the engine when it loads this config, so this file is
// deliberately self-contained and is never binarised: tools\build.ps1 ships any
// config.cpp that uses __has_include as plain text. A binarised config would
// freeze whatever the build machine had installed.

#if __has_include("\tsp_breach\functions.sqf")
    #define TLBI_ITEM_SCOPE 1
#else
    #define TLBI_ITEM_SCOPE 2
#endif

class CfgPatches {
    class tlbi_lockpick_items {
        name = "TLB Interactions - Lockpicking tools";
        author = "TLB";
        url = "";
        units[] = {};
        weapons[] = {"tlbi_lockpickKit", "tlbi_paperclip"};
        requiredVersion = 2.14;
        requiredAddons[] = {"cba_common"};
        skipWhenMissingDependencies = 1;
    };
};

class CfgWeapons {
    class CBA_MiscItem;
    class CBA_MiscItem_ItemInfo;

    class tlbi_paperclip: CBA_MiscItem {
        scope = TLBI_ITEM_SCOPE;
        scopeArsenal = TLBI_ITEM_SCOPE;
        scopeCurator = TLBI_ITEM_SCOPE;
        author = "TLB";
        displayName = "$STR_tlbi_lockpick_items_paperclip";
        descriptionShort = "$STR_tlbi_lockpick_items_paperclip_desc";
        picture = "\tlbi\addons\lockpick_items\data\paperclip_ca.paa";

        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 1;
        };
    };

    class tlbi_lockpickKit: tlbi_paperclip {
        displayName = "$STR_tlbi_lockpick_items_kit";
        descriptionShort = "$STR_tlbi_lockpick_items_kit_desc";
        picture = "\tlbi\addons\lockpick_items\data\lockpick_kit_ca.paa";

        class ItemInfo: ItemInfo {
            mass = 4;
        };
    };
};
