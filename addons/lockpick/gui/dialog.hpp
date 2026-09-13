// The lockpicking board. Same field-case chrome as the defusal board, reusing
// its control styles (defined by tlbi_defusal) and its chrome textures.
//
// Only the chrome lives here; the lock itself is created at runtime by
// fn_drawCutaway or fn_drawFace, depending on the technique.

class tlbi_RscText;
class tlbi_RscTextRight;
class tlbi_RscFill;
class tlbi_RscPicture;
class tlbi_RscToolButton;
class tlbi_RscToolButtonDanger;
class RscControlsGroupNoScrollbars;

#define LX(V)  QUOTE((V) * safezoneW + safezoneX)
#define LY(V)  QUOTE((V) * safezoneH + safezoneY)
#define LW(V)  QUOTE((V) * safezoneW)
#define LH(V)  QUOTE((V) * safezoneH)

class tlbi_RscLockpickBoard {
    idd = IDD_TLBI_LOCKPICK;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['tlbi_lockpick_display', _this select 0]";
    onUnload = "_this call tlbi_lockpick_fnc_onUnload";

    class controlsBackground {
        class Panel: tlbi_RscPicture {
            text = CHROME(panel_co.paa);
            x = LX(0.170); y = LY(0.178); w = LW(0.660); h = LH(0.644);
        };
        class BoardWell: tlbi_RscFill {
            colorBackground[] = {0.02, 0.02, 0.015, 0.85};
            x = LX(0.191); y = LY(0.281); w = LW(0.618); h = LH(0.363);
        };
        class Lcd: tlbi_RscPicture {
            text = CHROME(lcd_co.paa);
            x = LX(0.195); y = LY(0.651); w = LW(0.420); h = LH(0.044);
        };
        class Plate1: tlbi_RscPicture {
            text = CHROME(plate_co.paa);
            colorText[] = {0.60, 0.62, 0.54, 1};
            x = LX(0.195); y = LY(0.742); w = LW(0.145); h = LH(0.052);
        };
        class Plate2: Plate1 { x = LX(0.348); };
        class Plate3: Plate1 { x = LX(0.501); };
        class PlateClose: Plate1 {
            colorText[] = {0.48, 0.50, 0.44, 1};
            x = LX(0.655); w = LW(0.150);
        };
    };

    class controls {
        class Title: tlbi_RscText {
            idc = IDC_LP_TITLE;
            font = "PuristaBold";
            sizeEx = "(0.042 * safezoneH)";
            colorText[] = {0.80, 0.66, 0.30, 1};
            shadow = 1;
            x = LX(0.195); y = LY(0.192); w = LW(0.610); h = LH(0.045);
        };
        class Subtitle: tlbi_RscText {
            idc = IDC_LP_SUBTITLE;
            sizeEx = "(0.026 * safezoneH)";
            colorText[] = {0.62, 0.60, 0.53, 1};
            shadow = 1;
            x = LX(0.195); y = LY(0.242); w = LW(0.610); h = LH(0.035);
        };
        // A controls group, so the lock parts created inside it are clipped to
        // the board: a pick's handle runs off the right edge instead of over
        // the case.
        class Board: RscControlsGroupNoScrollbars {
            idc = IDC_LP_BOARD;
            x = LX(0.195); y = LY(0.285); w = LW(0.610); h = LH(0.355);
            class Controls {};
        };
        class Readout: tlbi_RscText {
            idc = IDC_LP_READOUT;
            font = "LCD14";
            sizeEx = "(0.030 * safezoneH)";
            colorText[] = {0.10, 0.12, 0.08, 1};
            x = LX(0.206); y = LY(0.652); w = LW(0.400); h = LH(0.042);
        };
        class Stage: tlbi_RscTextRight {
            idc = IDC_LP_STAGE;
            font = "PuristaMedium";
            colorText[] = {0.80, 0.66, 0.30, 1};
            shadow = 1;
            x = LX(0.625); y = LY(0.652); w = LW(0.180); h = LH(0.042);
        };
        class Status: tlbi_RscText {
            idc = IDC_LP_STATUS;
            sizeEx = "(0.026 * safezoneH)";
            colorText[] = {0.62, 0.60, 0.53, 1};
            shadow = 1;
            x = LX(0.195); y = LY(0.700); w = LW(0.610); h = LH(0.034);
        };
        class BtnA1: tlbi_RscToolButton {
            idc = IDC_LP_BTN_A1;
            x = LX(0.195); y = LY(0.742); w = LW(0.145); h = LH(0.052);
        };
        class BtnA2: tlbi_RscToolButton {
            idc = IDC_LP_BTN_A2;
            x = LX(0.348); y = LY(0.742); w = LW(0.145); h = LH(0.052);
        };
        class BtnA3: tlbi_RscToolButton {
            idc = IDC_LP_BTN_A3;
            x = LX(0.501); y = LY(0.742); w = LW(0.145); h = LH(0.052);
        };
        class BtnClose: tlbi_RscToolButton {
            idc = IDC_LP_BTN_CLOSE;
            text = "$STR_tlbi_lockpick_btn_back";
            x = LX(0.655); y = LY(0.742); w = LW(0.150); h = LH(0.052);
        };
    };
};
