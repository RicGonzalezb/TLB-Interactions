// TLB Interactions - Defusal
// Shared constants for both config and SQF. Deliberately macro-light: this addon
// is built without a P: drive, so it cannot #include ACE/CBA's script_macros.

#define PATHTOF(var1) \tlbi\addons\defusal\var1
#define QPATHTOF(var1) QUOTE(PATHTOF(var1))
#define QUOTE(var1) #var1

// --- Dialog -----------------------------------------------------------------
#define IDD_TLBI_DEFUSAL    714000

#define IDC_TITLE           714001
#define IDC_SUBTITLE        714002
#define IDC_CLOCK           714003
#define IDC_BOARD           714004
#define IDC_STATUS          714005
#define IDC_READOUT         714006
#define IDC_STAGE           714007
#define IDC_BTN_OHMS        714008
#define IDC_BTN_VOLTS       714010
#define IDC_BTN_CUT         714011
#define IDC_BTN_CLOSE       714012
#define IDC_PROGRESS_FRAME  714013
#define IDC_PROGRESS_BAR    714014
#define IDC_PROGRESS_TEXT   714015

// The three action buttons are shared by every kind of device and relabelled
// per kind; these aliases name them by position rather than by the IED meter.
#define IDC_BTN_A1          IDC_BTN_VOLTS
#define IDC_BTN_A2          IDC_BTN_OHMS
#define IDC_BTN_A3          IDC_BTN_CUT

// --- Device kinds -----------------------------------------------------------
// Each kind has its own procedure, board and saved state. See fn_classify for
// how an explosive is assigned one.
#define KIND_IED            0
#define KIND_MINE           1
#define KIND_TRIP           2

// --- Procedure stages -------------------------------------------------------
// Physical work comes before electrical work: the device is dug out, then the
// tape binding its wiring is cut away, and only then can a meter reach it.
#define STAGE_EXCAVATE      0
#define STAGE_TAPE          1
#define STAGE_TEST          2

// --- Puzzle data layout -----------------------------------------------------
// Stored on the explosive object under "tlbi_defusal_puzzle", so progress at
// every stage survives backing off or handing the job to someone else.
//
// The firing line is not marked anywhere. Exactly one conductor is BOTH
// energised and continuous to the initiator; decoys have one property or the
// other, so neither meter mode alone can ever identify it.
#define PZ_COUNT        0   // NUMBER  - conductor count
#define PZ_CABLES       1   // ARRAY   - per-cable data, see CB_* below
#define PZ_LIVE         2   // NUMBER  - index of the firing line
#define PZ_STAGE        3   // NUMBER  - STAGE_*
#define PZ_VOLTS        4   // ARRAY   - per cable: -1 untested, 0 no supply, 1 supply
#define PZ_OHMS         5   // ARRAY   - per cable: -1 untested, 0 open, 1 continuity
#define PZ_STRIKES      6   // NUMBER  - mistakes remaining before detonation
#define PZ_DEADENDS     7   // ARRAY   - conductors already cut
#define PZ_DIRT         8   // ARRAY   - soil clumps, see DT_* below
#define PZ_TAPE         9   // ARRAY   - tape strips, see TP_* below

// Per cable: [colourIndex, hasSupply, hasContinuity, endRow, sag1, sag2]
#define CB_COLOUR       0
#define CB_VOLTS        1
#define CB_OHMS         2
#define CB_ENDROW       3
#define CB_SAG1         4
#define CB_SAG2         5

// Per soil clump: [centreX, centreY, size, variant, brushesLeft]
// Positions are fractions of the board; size is a fraction of board width and
// the clump is drawn square in screen pixels.
#define DT_X            0
#define DT_Y            1
#define DT_SIZE         2
#define DT_VARIANT      3
#define DT_HP           4

// Per tape strip: [x, width, variant, intact]
#define TP_X            0
#define TP_W            1
#define TP_VARIANT      2
#define TP_INTACT       3

// --- Mine state -------------------------------------------------------------
// Stored under "tlbi_defusal_mine". The ground is a grid of soil cells; the mine
// sits under a 3 x 3 block of them with its pressure plate in the centre cell.
// Every cell's contents follow from MN_CX/MN_CY and MN_STONES.
#define MN_COLS         0   // NUMBER
#define MN_ROWS         1   // NUMBER
#define MN_CX           2   // NUMBER  - plate column
#define MN_CY           3   // NUMBER  - plate row
#define MN_DUG          4   // ARRAY   - per cell: 0 covered, 1 dug out
#define MN_PROBED       5   // ARRAY   - per cell: -1 not prodded, PROD_*
#define MN_STONES       6   // ARRAY   - cell indices holding a stone
#define MN_STAGE        7   // NUMBER  - MSTAGE_*
#define MN_SLIPS        8   // NUMBER  - pin slips so far
#define MN_AT           9   // BOOL    - anti-tank: needs far more pressure to fire

#define MINE_COLS       11
#define MINE_ROWS       4

#define PROD_CLEAR      0
#define PROD_STONE      1
#define PROD_METAL      2

#define MSTAGE_LOCATE   0   // prod and dig around the mine
#define MSTAGE_PIN      1   // rim exposed: seat the safety pin in the fuze

#define TOOL_PROD       0
#define TOOL_DIG        1

// --- Tripwire state ---------------------------------------------------------
// Stored under "tlbi_defusal_trip". A wire runs from an anchor stake to one
// firing device, sometimes with a branch to a second device hidden in the grass.
#define TR_LEFT         0   // BOOL    - anchor on the left, device on the right
#define TR_WIRE_Y       1   // NUMBER  - board fraction
#define TR_TAUT         2   // BOOL    - tension-release fuze (true) or pull fuze
#define TR_FUZES        3   // ARRAY   - per device: [x, y, pinned]
#define TR_BRANCH       4   // ARRAY   - [] or [junctionX]; branch goes to device 1
#define TR_TUFTS        5   // ARRAY   - per tuft: see TF_*
#define TR_STAGE        6   // NUMBER  - TSTAGE_*
#define TR_TENSION      7   // NUMBER  - -1 not checked, 0 slack, 1 taut
#define TR_SLIPS        8   // NUMBER  - pin slips so far

#define TF_X            0
#define TF_Y            1
#define TF_SIZE         2
#define TF_VARIANT      3
#define TF_CLEARED      4
#define TF_ONPATH       5   // BOOL    - covers part of a wire; must be cleared

#define TSTAGE_TRACE    0   // part the grass along the wire
#define TSTAGE_WORK     1   // read tension, pin devices, cut

// --- Meter modes ------------------------------------------------------------
#define METER_VOLTS     0
#define METER_OHMS      1

// --- Difficulty -------------------------------------------------------------
// The Difficulty setting picks a row of tlbi_defusal_difficultyTable (fn_preInit).
// Each column adjusts a base setting where it is used.
#define DIFF(var1)      ((tlbi_defusal_difficultyTable select ((round tlbi_defusal_difficulty) max 0 min 3)) select var1)
#define DIFF_WIRES      0   // extra conductors on an IED
#define DIFF_RISK       1   // multiplies the continuity-test detonation risk
#define DIFF_PLATE      2   // multiplies the risk of prodding a mine's plate
#define DIFF_BAND       3   // multiplies the steady-hand band when seating a pin
#define DIFF_SLIPS      4   // extra pin slips allowed
#define DIFF_BRANCH     5   // multiplies the tripwire branch chance

// Pin slips allowed after difficulty.
#define PIN_SLIPS       (((round tlbi_defusal_pinSlips) + DIFF(DIFF_SLIPS)) max 0)

// Timed clearing work (brush, prod, dig, grass, tape) runs at the Clearing speed
// setting: a 2x speed halves the time.
#define CLEAR_TIME(var1) ((var1) / (tlbi_defusal_clearSpeed max 0.05))

// --- Failure modes ----------------------------------------------------------
#define FAILURE_INSTANT     0
#define FAILURE_COUNTDOWN   1
#define FAILURE_ONESTRIKE   2

// --- Rendering --------------------------------------------------------------
// Cables are single pre-rendered sprites, tinted at runtime. The per-travel
// headroom in fn_drawBoard MUST match CPAD in tools/gen_assets.py, which is what
// keeps every cable the same thickness regardless of how far it travels.
#define CABLE_MAX_TRAVEL 2      // rows a cable may span; sprites exist for 0..2

// --- Audio ------------------------------------------------------------------
// Referenced from ACE (a hard dependency) rather than shipped.
#define SND_ARMED   "\z\ace\addons\explosives\Data\Audio\IED_Activated.wss"
#define SND_TONE    "\z\ace\addons\explosives\Data\Audio\DialTone.wss"
