// The defusal board dialog.
//
// Only the chrome is defined here. The device itself - ground, shell, packs,
// cables, tape, soil and every click target on them - is created at runtime by
// tlbi_defusal_fnc_drawBoard, because all of it is decided per device.
//
// The chrome is textured rather than flat: a scratched field-case panel, a
// multimeter LCD for readings, and worn steel plates under the tool buttons.

// Dialog occupies x 0.17..0.83, y 0.18..0.82 of the safe zone.
#define DX(V)  QUOTE((V) * safezoneW + safezoneX)
#define DY(V)  QUOTE((V) * safezoneH + safezoneY)
#define DW(V)  QUOTE((V) * safezoneW)
#define DH(V)  QUOTE((V) * safezoneH)

class tlbi_RscDefusalBoard {
    idd = IDD_TLBI_DEFUSAL;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "uiNamespace setVariable ['tlbi_defusal_display', _this select 0]";
    onUnload = "_this call tlbi_defusal_fnc_onBoardUnload";

    class controlsBackground {
        class Panel: tlbi_RscPicture {
            text = QPATHTOF(data\panel_co.paa);
            x = DX(0.170); y = DY(0.178); w = DW(0.660); h = DH(0.644);
        };
        class BoardWell: tlbi_RscFill {
            colorBackground[] = {0.02, 0.02, 0.015, 0.85};
            x = DX(0.191); y = DY(0.281); w = DW(0.618); h = DH(0.363);
        };
        class Lcd: tlbi_RscPicture {
            text = QPATHTOF(data\lcd_co.paa);
            x = DX(0.195); y = DY(0.651); w = DW(0.420); h = DH(0.044);
        };
        class PlateVolts: tlbi_RscPicture {
            text = QPATHTOF(data\plate_co.paa);
            colorText[] = {0.60, 0.62, 0.54, 1};
            x = DX(0.195); y = DY(0.742); w = DW(0.145); h = DH(0.052);
        };
        class PlateOhms: PlateVolts {
            x = DX(0.348);
        };
        class PlateCut: PlateVolts {
            colorText[] = {0.58, 0.28, 0.22, 1};
            x = DX(0.501);
        };
        class PlateClose: PlateVolts {
            colorText[] = {0.48, 0.50, 0.44, 1};
            x = DX(0.655); w = DW(0.150);
        };
    };

    class controls {
        class Title: tlbi_RscText {
            idc = IDC_TITLE;
            font = TLBI_FONTHEAD;
            sizeEx = TLBI_TEXTSIZE_L;
            colorText[] = TLBI_COL_ACCENT;
            shadow = 1;
            text = "$STR_tlbi_defusal_board_title";
            x = DX(0.195); y = DY(0.192); w = DW(0.420); h = DH(0.045);
        };
        class Clock: tlbi_RscTextRight {
            idc = IDC_CLOCK;
            font = TLBI_FONTLCD;
            sizeEx = TLBI_TEXTSIZE_L;
            colorText[] = TLBI_COL_DANGER;
            shadow = 1;
            x = DX(0.605); y = DY(0.192); w = DW(0.200); h = DH(0.045);
        };
        class Subtitle: tlbi_RscText {
            idc = IDC_SUBTITLE;
            sizeEx = TLBI_TEXTSIZE_S;
            colorText[] = TLBI_COL_DIM;
            shadow = 1;
            x = DX(0.195); y = DY(0.242); w = DW(0.610); h = DH(0.035);
        };

        // Invisible placeholder that drawBoard reads to find the drawing area.
        class Board: tlbi_RscText {
            idc = IDC_BOARD;
            x = DX(0.195); y = DY(0.285); w = DW(0.610); h = DH(0.355);
        };

        class Readout: tlbi_RscText {
            idc = IDC_READOUT;
            font = TLBI_FONTLCD;
            sizeEx = "(0.030 * safezoneH)";
            colorText[] = {0.10, 0.12, 0.08, 1};
            x = DX(0.206); y = DY(0.652); w = DW(0.400); h = DH(0.042);
        };
        class Stage: tlbi_RscTextRight {
            idc = IDC_STAGE;
            font = TLBI_FONTTOOL;
            colorText[] = TLBI_COL_ACCENT;
            shadow = 1;
            x = DX(0.625); y = DY(0.652); w = DW(0.180); h = DH(0.042);
        };
        class Status: tlbi_RscText {
            idc = IDC_STATUS;
            sizeEx = TLBI_TEXTSIZE_S;
            colorText[] = TLBI_COL_DIM;
            shadow = 1;
            x = DX(0.195); y = DY(0.700); w = DW(0.610); h = DH(0.034);
        };

        class ProgressFrame: tlbi_RscFill {
            idc = IDC_PROGRESS_FRAME;
            colorBackground[] = {0.02, 0.02, 0.015, 0.92};
            x = DX(0.195); y = DY(0.651); w = DW(0.610); h = DH(0.044);
        };
        class ProgressBar: tlbi_RscFill {
            idc = IDC_PROGRESS_BAR;
            colorBackground[] = {0.62, 0.50, 0.20, 1};
            x = DX(0.198); y = DY(0.655); w = DW(0.000); h = DH(0.036);
        };
        class ProgressText: tlbi_RscTextCenter {
            idc = IDC_PROGRESS_TEXT;
            font = TLBI_FONTTOOL;
            sizeEx = TLBI_TEXTSIZE_S;
            colorText[] = {0.94, 0.92, 0.84, 1};
            shadow = 2;
            x = DX(0.195); y = DY(0.653); w = DW(0.610); h = DH(0.040);
        };

        class BtnVolts: tlbi_RscToolButton {
            idc = IDC_BTN_VOLTS;
            text = "$STR_tlbi_defusal_btn_volts";
            x = DX(0.195); y = DY(0.742); w = DW(0.145); h = DH(0.052);
        };
        class BtnOhms: tlbi_RscToolButton {
            idc = IDC_BTN_OHMS;
            text = "$STR_tlbi_defusal_btn_ohms";
            x = DX(0.348); y = DY(0.742); w = DW(0.145); h = DH(0.052);
        };
        class BtnCut: tlbi_RscToolButtonDanger {
            idc = IDC_BTN_CUT;
            text = "$STR_tlbi_defusal_btn_cut";
            x = DX(0.501); y = DY(0.742); w = DW(0.145); h = DH(0.052);
        };
        class BtnClose: tlbi_RscToolButton {
            idc = IDC_BTN_CLOSE;
            text = "$STR_tlbi_defusal_btn_back_away";
            x = DX(0.655); y = DY(0.742); w = DW(0.150); h = DH(0.052);
        };
    };
};
