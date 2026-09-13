// Base control styles for the defusal board.
// Only vanilla base classes are inherited from, so no P: drive / external
// includes are needed at build time.

#define TLBI_COL_TEXT       {0.86, 0.84, 0.76, 1.00}
#define TLBI_COL_DIM        {0.62, 0.60, 0.53, 1.00}
#define TLBI_COL_ACCENT     {0.80, 0.66, 0.30, 1.00}
#define TLBI_COL_DANGER     {0.82, 0.24, 0.18, 1.00}

#define TLBI_FONT           "RobotoCondensed"
#define TLBI_FONTHEAD       "PuristaBold"
#define TLBI_FONTTOOL       "PuristaMedium"
#define TLBI_FONTLCD        "LCD14"

#define TLBI_TEXTSIZE       "(0.032 * safezoneH)"
#define TLBI_TEXTSIZE_S     "(0.026 * safezoneH)"
#define TLBI_TEXTSIZE_L     "(0.042 * safezoneH)"

class tlbi_RscBase {
    idc = -1;
    type = 0;
    style = 0;
    x = 0; y = 0; w = 0; h = 0;
    font = TLBI_FONT;
    sizeEx = TLBI_TEXTSIZE;
    colorText[] = TLBI_COL_TEXT;
    colorBackground[] = {0,0,0,0};
    text = "";
    shadow = 0;
};

class tlbi_RscText: tlbi_RscBase {
    type = 0;        // CT_STATIC
    style = 0;       // ST_LEFT
};

class tlbi_RscTextCenter: tlbi_RscText {
    style = 2;       // ST_CENTER
};

class tlbi_RscTextRight: tlbi_RscText {
    style = 1;       // ST_RIGHT
};

// A CT_STATIC with an opaque colorBackground and no text: a plain rectangle.
class tlbi_RscFill: tlbi_RscBase {
    type = 0;
    style = 0;
    colorBackground[] = {0, 0, 0, 1};
    text = "";
};

// Every texture on the board. Tintable through colorText; greyscale sprites
// (cables, tags, plates) take their colour from the script.
class tlbi_RscPicture: tlbi_RscBase {
    type = 0;        // CT_STATIC
    style = 48;      // ST_PICTURE, without ST_KEEP_ASPECT_RATIO
    colorText[] = {1, 1, 1, 1};
};

class tlbi_RscCable: tlbi_RscPicture {};

class tlbi_RscButton {
    idc = -1;
    type = 1;        // CT_BUTTON
    style = 2;       // ST_CENTER
    x = 0; y = 0; w = 0; h = 0;
    font = TLBI_FONTTOOL;
    sizeEx = TLBI_TEXTSIZE;
    text = "";
    action = "";
    borderSize = 0;
    offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0;
    colorText[] = TLBI_COL_TEXT;
    colorDisabled[] = {0.45, 0.44, 0.40, 0.55};
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0.35};
    colorBackgroundActive[] = {1, 1, 1, 0.10};
    colorFocused[] = {1, 1, 1, 0.05};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 0};
    shadow = 1;
    soundEnter[] = {"", 0, 1};
    soundPush[] = {"", 0, 1};
    soundClick[] = {"", 0, 1};
    soundEscape[] = {"", 0, 1};
};

// Tool buttons sit on a worn steel plate texture drawn behind them, so the
// button itself is only a label and a hover wash.
class tlbi_RscToolButton: tlbi_RscButton {};

class tlbi_RscToolButtonDanger: tlbi_RscButton {
    colorText[] = {0.96, 0.66, 0.58, 1};
    colorBackgroundActive[] = {1, 0.3, 0.2, 0.16};
};

// Invisible click target laid over a texture - a soil clump, a tape strip, a
// cable tag. Hover gives the faintest wash so it still reads as interactive.
class tlbi_RscHotspot: tlbi_RscButton {
    sizeEx = TLBI_TEXTSIZE_S;
    colorText[] = {0, 0, 0, 0};
    colorDisabled[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
    colorBackgroundActive[] = {1, 0.95, 0.8, 0.07};
    colorFocused[] = {0, 0, 0, 0};
    shadow = 0;
};
