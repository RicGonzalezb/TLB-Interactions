// TLB Interactions - Lockpicking
// Shared constants for config and SQF. Macro-light for the same reason as the
// defusal addon: built without a P: drive.

#define PATHTOF(var1) \tlbi\addons\lockpick\var1
#define QPATHTOF(var1) QUOTE(PATHTOF(var1))
#define QUOTE(var1) #var1

// The chrome textures (panel, LCD, plates) are shared with the defusal addon.
#define CHROME(var1) QUOTE(\tlbi\addons\defusal\data\var1)

// --- Dialog -----------------------------------------------------------------
#define IDD_TLBI_LOCKPICK   715000
#define IDC_LP_TITLE        715001
#define IDC_LP_SUBTITLE     715002
#define IDC_LP_BOARD        715003
#define IDC_LP_READOUT      715004
#define IDC_LP_STAGE        715005
#define IDC_LP_STATUS       715006
#define IDC_LP_BTN_A1       715010
#define IDC_LP_BTN_A2       715011
#define IDC_LP_BTN_A3       715012
#define IDC_LP_BTN_CLOSE    715013

// --- Tools, techniques, doors -----------------------------------------------
#define TOOL_KIT            0
#define TOOL_CLIP           1

#define TECH_PINS           0   // single-pin picking in a cutaway
#define TECH_RAKE           1   // raking while holding tension in a band
#define TECH_DIAL           2   // find the sweet spot, then turn the plug

#define DOOR_CIVIL          0
#define DOOR_MILITARY       1
#define DOOR_REINFORCED     2
#define DOOR_GLASS          3

// --- Cutaway layout (board fractions) ---------------------------------------
// Must match make_housing in tools/gen_lockpick_assets.py.
#define CUT_TOP             0.06
#define CUT_SHEAR           0.50
#define CUT_KEYWAY          0.86
#define CUT_PIN_X0          0.30
#define CUT_PIN_X1          0.80

// --- Face-view frames -------------------------------------------------------
#define PLUG_STEP           5   // degrees per plug frame, 0..90
#define PICK_STEP           6   // degrees per pick frame, -90..90

// --- Keys (DIK codes) -------------------------------------------------------
#define KEY_ESC             1
#define KEY_W               17
#define KEY_R               19
#define KEY_A               30
#define KEY_D               32
#define KEY_SPACE           57
#define KEY_LEFT            203
#define KEY_RIGHT           205
