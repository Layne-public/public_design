// =====================================================
// Chip-level wrapper with IO pads for simulation
//   - Exposes package-level pins: *_pad
//   - Instantiates digital_top and IUMAFS IO cells
//   - All pad control signals come from digital_top
// =====================================================
`include "defines.vh"
module pad_wrapper
(
    // ---------- Package pins (external view) ----------
    // Clocks / resets
    input  wire        clk_pad,
    input  wire        rst_n_pad,

    // JTAG pins
    input  wire        jtag_TCK_pad,
    input  wire        jtag_TMS_pad,
    input  wire        jtag_TDI_pad,
    output wire        jtag_TDO_pad,

    // Analog-front-end configuration pins (digital side)
    input  wire        AN_VAL_PAD_pin,
    input  wire        AN_SD_PAD_pin,
    input  wire        AN_DATA0_PAD_pin,
    input  wire        AN_DATA1_PAD_pin,

    // Core control hooks
    input  wire        TEST_MODE_PAD_pin,
    input  wire        COR_START_PAD_pin,
    output wire        RUST_VAL_PAD_pin,
    output wire [2:0]  RUST_DAT_PAD_pin,

    // ---------- Analog-front-end side (core-facing) ----------
    input  wire        AN_CLK,
    input  wire        AN_DAT0,
    input  wire        AN_DAT1,
    input  wire        AN_RSTN,
    output wire        BUF_FUL,
    output wire [31:0] ANA_THR,
    output wire [15:0] DUMY_TRIM
);

    // =================================================
    // Simple supply model for pad cells
    // =================================================
    supply1 VDD;
    supply1 VDDIO;
    supply0 VSS;
    supply0 VSSIO;

    // Global PORE for IO cells: 0 = normal operation
    wire PORE = 1'b0;

    // =================================================
    // Core-side nets (between pads and digital_top)
    // =================================================

    // Clocks / resets
    wire clk_core;
    wire rst_n_core;

    // JTAG
    wire jtag_TCK_core;
    wire jtag_TMS_core;
    wire jtag_TDI_core;
    wire jtag_TDO_core;

    // Analog-front-end config (digital)
    wire AN_VAL_core;
    wire AN_SD_core;
    wire AN_DATA0_core;
    wire AN_DATA1_core;

    // Core control hooks
    wire TEST_MODE_core;
    wire COR_START_core;
    wire RUST_VAL_core;
    wire [2:0] RUST_DAT_core;

    // =================================================
    // Pad control signals from digital_top
    // =================================================

    // clk PAD controls
    wire clk_DO, clk_IDDQ, clk_IE, clk_SMT, clk_PU, clk_PD, clk_OE, clk_PIN1, clk_PIN2;

    // rst_n PAD controls
    wire rst_n_DO, rst_n_IDDQ, rst_n_IE, rst_n_SMT, rst_n_PU, rst_n_PD, rst_n_OE, rst_n_PIN1, rst_n_PIN2;

    // JTAG TCK PAD controls
    wire jtag_TCK_DO, jtag_TCK_IDDQ, jtag_TCK_IE, jtag_TCK_SMT, jtag_TCK_PU, jtag_TCK_PD, jtag_TCK_OE, jtag_TCK_PIN1, jtag_TCK_PIN2;

    // JTAG TMS PAD controls
    wire jtag_TMS_DO, jtag_TMS_IDDQ, jtag_TMS_IE, jtag_TMS_SMT, jtag_TMS_PU, jtag_TMS_PD, jtag_TMS_OE, jtag_TMS_PIN1, jtag_TMS_PIN2;

    // JTAG TDI PAD controls
    wire jtag_TDI_DO, jtag_TDI_IDDQ, jtag_TDI_IE, jtag_TDI_SMT, jtag_TDI_PU, jtag_TDI_PD, jtag_TDI_OE, jtag_TDI_PIN1, jtag_TDI_PIN2;

    // JTAG TDO PAD controls
    wire jtag_TDO_DO, jtag_TDO_IDDQ, jtag_TDO_IE, jtag_TDO_SMT, jtag_TDO_PU, jtag_TDO_PD, jtag_TDO_OE, jtag_TDO_PIN1, jtag_TDO_PIN2;

    // AN_* PAD controls
    wire AN_VAL_PAD_DO,   AN_VAL_PAD_IDDQ,   AN_VAL_PAD_IE,   AN_VAL_PAD_SMT,   AN_VAL_PAD_PU,   AN_VAL_PAD_PD,   AN_VAL_PAD_OE,   AN_VAL_PAD_PIN1,   AN_VAL_PAD_PIN2;
    wire AN_SD_PAD_DO,    AN_SD_PAD_IDDQ,    AN_SD_PAD_IE,    AN_SD_PAD_SMT,    AN_SD_PAD_PU,    AN_SD_PAD_PD,    AN_SD_PAD_OE,    AN_SD_PAD_PIN1,    AN_SD_PAD_PIN2;
    wire AN_DATA0_PAD_DO, AN_DATA0_PAD_IDDQ, AN_DATA0_PAD_IE, AN_DATA0_PAD_SMT, AN_DATA0_PAD_PU, AN_DATA0_PAD_PD, AN_DATA0_PAD_OE, AN_DATA0_PAD_PIN1, AN_DATA0_PAD_PIN2;
    wire AN_DATA1_PAD_DO, AN_DATA1_PAD_IDDQ, AN_DATA1_PAD_IE, AN_DATA1_PAD_SMT, AN_DATA1_PAD_PU, AN_DATA1_PAD_PD, AN_DATA1_PAD_OE, AN_DATA1_PAD_PIN1, AN_DATA1_PAD_PIN2;

    // TEST_MODE / COR_START PAD controls
    wire TEST_MODE_PAD_DO, TEST_MODE_PAD_IDDQ, TEST_MODE_PAD_IE, TEST_MODE_PAD_SMT, TEST_MODE_PAD_PU, TEST_MODE_PAD_PD, TEST_MODE_PAD_OE, TEST_MODE_PAD_PIN1, TEST_MODE_PAD_PIN2;
    wire COR_START_PAD_DO, COR_START_PAD_IDDQ, COR_START_PAD_IE, COR_START_PAD_SMT, COR_START_PAD_PU, COR_START_PAD_PD, COR_START_PAD_OE, COR_START_PAD_PIN1, COR_START_PAD_PIN2;

    // RUST_VAL / RUST_DAT PAD controls
    wire RUST_VAL_PAD_DO,  RUST_VAL_PAD_IDDQ,  RUST_VAL_PAD_IE,  RUST_VAL_PAD_SMT,  RUST_VAL_PAD_PU,  RUST_VAL_PAD_PD,  RUST_VAL_PAD_OE,  RUST_VAL_PAD_PIN1,  RUST_VAL_PAD_PIN2;
    wire RUST_DAT_PAD_DO,  RUST_DAT_PAD_IDDQ,  RUST_DAT_PAD_IE,  RUST_DAT_PAD_SMT,  RUST_DAT_PAD_PU,  RUST_DAT_PAD_PD,  RUST_DAT_PAD_OE,  RUST_DAT_PAD_PIN1,  RUST_DAT_PAD_PIN2;

    // =================================================
    // Instantiate digital_top (pure digital core)
    // =================================================
    digital_top u_digital_top (
        // Clocks / resets
        .clk              (clk_core),
        .rst_n            (rst_n_core),

        // JTAG pins (core side)
        .jtag_pin_TCK     (jtag_TCK_core),
        .jtag_pin_TMS     (jtag_TMS_core),
        .jtag_pin_TDI     (jtag_TDI_core),
        .jtag_pin_TDO     (jtag_TDO_core),

        // AN_* config pins (core side)
        .AN_VAL_PAD       (AN_VAL_core),
        .AN_SD_PAD        (AN_SD_core),
        .AN_DATA0_PAD     (AN_DATA0_core),
        .AN_DATA1_PAD     (AN_DATA1_core),

        // Core control hooks
        .TEST_MODE_PAD    (TEST_MODE_core),
        .COR_START_PAD    (COR_START_core),
        .RUST_VAL_PAD     (RUST_VAL_core),
        .RUST_DAT_PAD     (RUST_DAT_core),

        // Analog-front-end side (direct ports of wrapper)
        .AN_CLK           (AN_CLK),
        .AN_DAT0          (AN_DAT0),
        .AN_DAT1          (AN_DAT1),
        .AN_RSTN          (AN_RSTN),
        .BUF_FUL          (BUF_FUL),
        .ANA_THR          (ANA_THR),
        .DUMY_TRIM        (DUMY_TRIM),

        // -------- PAD control signals coming out --------
        // clk
        .clk_DO           (clk_DO),
        .clk_IDDQ         (clk_IDDQ),
        .clk_IE           (clk_IE),
        .clk_SMT          (clk_SMT),
        .clk_PU           (clk_PU),
        .clk_PD           (clk_PD),
        .clk_OE           (clk_OE),
        .clk_PIN1         (clk_PIN1),
        .clk_PIN2         (clk_PIN2),

        // rst_n
        .rst_n_DO         (rst_n_DO),
        .rst_n_IDDQ       (rst_n_IDDQ),
        .rst_n_IE         (rst_n_IE),
        .rst_n_SMT        (rst_n_SMT),
        .rst_n_PU         (rst_n_PU),
        .rst_n_PD         (rst_n_PD),
        .rst_n_OE         (rst_n_OE),
        .rst_n_PIN1       (rst_n_PIN1),
        .rst_n_PIN2       (rst_n_PIN2),

        // JTAG TCK
        .jtag_TCK_DO      (jtag_TCK_DO),
        .jtag_TCK_IDDQ    (jtag_TCK_IDDQ),
        .jtag_TCK_IE      (jtag_TCK_IE),
        .jtag_TCK_SMT     (jtag_TCK_SMT),
        .jtag_TCK_PU      (jtag_TCK_PU),
        .jtag_TCK_PD      (jtag_TCK_PD),
        .jtag_TCK_OE      (jtag_TCK_OE),
        .jtag_TCK_PIN1    (jtag_TCK_PIN1),
        .jtag_TCK_PIN2    (jtag_TCK_PIN2),

        // JTAG TMS
        .jtag_TMS_DO      (jtag_TMS_DO),
        .jtag_TMS_IDDQ    (jtag_TMS_IDDQ),
        .jtag_TMS_IE      (jtag_TMS_IE),
        .jtag_TMS_SMT     (jtag_TMS_SMT),
        .jtag_TMS_PU      (jtag_TMS_PU),
        .jtag_TMS_PD      (jtag_TMS_PD),
        .jtag_TMS_OE      (jtag_TMS_OE),
        .jtag_TMS_PIN1    (jtag_TMS_PIN1),
        .jtag_TMS_PIN2    (jtag_TMS_PIN2),

        // JTAG TDI
        .jtag_TDI_DO      (jtag_TDI_DO),
        .jtag_TDI_IDDQ    (jtag_TDI_IDDQ),
        .jtag_TDI_IE      (jtag_TDI_IE),
        .jtag_TDI_SMT     (jtag_TDI_SMT),
        .jtag_TDI_PU      (jtag_TDI_PU),
        .jtag_TDI_PD      (jtag_TDI_PD),
        .jtag_TDI_OE      (jtag_TDI_OE),
        .jtag_TDI_PIN1    (jtag_TDI_PIN1),
        .jtag_TDI_PIN2    (jtag_TDI_PIN2),

        // JTAG TDO
        .jtag_TDO_IDDQ    (jtag_TDO_IDDQ),
        .jtag_TDO_IE      (jtag_TDO_IE),
        .jtag_TDO_SMT     (jtag_TDO_SMT),
        .jtag_TDO_PU      (jtag_TDO_PU),
        .jtag_TDO_PD      (jtag_TDO_PD),
        .jtag_TDO_OE      (jtag_TDO_OE),
        .jtag_TDO_PIN1    (jtag_TDO_PIN1),
        .jtag_TDO_PIN2    (jtag_TDO_PIN2),

        // AN_* pad controls
        .AN_VAL_PAD_DO    (AN_VAL_PAD_DO),
        .AN_VAL_PAD_IDDQ  (AN_VAL_PAD_IDDQ),
        .AN_VAL_PAD_IE    (AN_VAL_PAD_IE),
        .AN_VAL_PAD_SMT   (AN_VAL_PAD_SMT),
        .AN_VAL_PAD_PU    (AN_VAL_PAD_PU),
        .AN_VAL_PAD_PD    (AN_VAL_PAD_PD),
        .AN_VAL_PAD_OE    (AN_VAL_PAD_OE),
        .AN_VAL_PAD_PIN1  (AN_VAL_PAD_PIN1),
        .AN_VAL_PAD_PIN2  (AN_VAL_PAD_PIN2),

        .AN_SD_PAD_DO     (AN_SD_PAD_DO),
        .AN_SD_PAD_IDDQ   (AN_SD_PAD_IDDQ),
        .AN_SD_PAD_IE     (AN_SD_PAD_IE),
        .AN_SD_PAD_SMT    (AN_SD_PAD_SMT),
        .AN_SD_PAD_PU     (AN_SD_PAD_PU),
        .AN_SD_PAD_PD     (AN_SD_PAD_PD),
        .AN_SD_PAD_OE     (AN_SD_PAD_OE),
        .AN_SD_PAD_PIN1   (AN_SD_PAD_PIN1),
        .AN_SD_PAD_PIN2   (AN_SD_PAD_PIN2),

        .AN_DATA0_PAD_DO   (AN_DATA0_PAD_DO),
        .AN_DATA0_PAD_IDDQ (AN_DATA0_PAD_IDDQ),
        .AN_DATA0_PAD_IE   (AN_DATA0_PAD_IE),
        .AN_DATA0_PAD_SMT  (AN_DATA0_PAD_SMT),
        .AN_DATA0_PAD_PU   (AN_DATA0_PAD_PU),
        .AN_DATA0_PAD_PD   (AN_DATA0_PAD_PD),
        .AN_DATA0_PAD_OE   (AN_DATA0_PAD_OE),
        .AN_DATA0_PAD_PIN1 (AN_DATA0_PAD_PIN1),
        .AN_DATA0_PAD_PIN2 (AN_DATA0_PAD_PIN2),

        .AN_DATA1_PAD_DO   (AN_DATA1_PAD_DO),
        .AN_DATA1_PAD_IDDQ (AN_DATA1_PAD_IDDQ),
        .AN_DATA1_PAD_IE   (AN_DATA1_PAD_IE),
        .AN_DATA1_PAD_SMT  (AN_DATA1_PAD_SMT),
        .AN_DATA1_PAD_PU   (AN_DATA1_PAD_PU),
        .AN_DATA1_PAD_PD   (AN_DATA1_PAD_PD),
        .AN_DATA1_PAD_OE   (AN_DATA1_PAD_OE),
        .AN_DATA1_PAD_PIN1 (AN_DATA1_PAD_PIN1),
        .AN_DATA1_PAD_PIN2 (AN_DATA1_PAD_PIN2),

        // TEST_MODE / COR_START
        .TEST_MODE_PAD_DO   (TEST_MODE_PAD_DO),
        .TEST_MODE_PAD_IDDQ (TEST_MODE_PAD_IDDQ),
        .TEST_MODE_PAD_IE   (TEST_MODE_PAD_IE),
        .TEST_MODE_PAD_SMT  (TEST_MODE_PAD_SMT),
        .TEST_MODE_PAD_PU   (TEST_MODE_PAD_PU),
        .TEST_MODE_PAD_PD   (TEST_MODE_PAD_PD),
        .TEST_MODE_PAD_OE   (TEST_MODE_PAD_OE),
        .TEST_MODE_PAD_PIN1 (TEST_MODE_PAD_PIN1),
        .TEST_MODE_PAD_PIN2 (TEST_MODE_PAD_PIN2),

        .COR_START_PAD_DO   (COR_START_PAD_DO),
        .COR_START_PAD_IDDQ (COR_START_PAD_IDDQ),
        .COR_START_PAD_IE   (COR_START_PAD_IE),
        .COR_START_PAD_SMT  (COR_START_PAD_SMT),
        .COR_START_PAD_PU   (COR_START_PAD_PU),
        .COR_START_PAD_PD   (COR_START_PAD_PD),
        .COR_START_PAD_OE   (COR_START_PAD_OE),
        .COR_START_PAD_PIN1 (COR_START_PAD_PIN1),
        .COR_START_PAD_PIN2 (COR_START_PAD_PIN2),

        // RUST_VAL / RUST_DAT
        .RUST_VAL_PAD_IDDQ  (RUST_VAL_PAD_IDDQ),
        .RUST_VAL_PAD_IE    (RUST_VAL_PAD_IE),
        .RUST_VAL_PAD_SMT   (RUST_VAL_PAD_SMT),
        .RUST_VAL_PAD_PU    (RUST_VAL_PAD_PU),
        .RUST_VAL_PAD_PD    (RUST_VAL_PAD_PD),
        .RUST_VAL_PAD_OE    (RUST_VAL_PAD_OE),
        .RUST_VAL_PAD_PIN1  (RUST_VAL_PAD_PIN1),
        .RUST_VAL_PAD_PIN2  (RUST_VAL_PAD_PIN2),

        .RUST_DAT_PAD_IDDQ  (RUST_DAT_PAD_IDDQ),
        .RUST_DAT_PAD_IE    (RUST_DAT_PAD_IE),
        .RUST_DAT_PAD_SMT   (RUST_DAT_PAD_SMT),
        .RUST_DAT_PAD_PU    (RUST_DAT_PAD_PU),
        .RUST_DAT_PAD_PD    (RUST_DAT_PAD_PD),
        .RUST_DAT_PAD_OE    (RUST_DAT_PAD_OE),
        .RUST_DAT_PAD_PIN1  (RUST_DAT_PAD_PIN1),
        .RUST_DAT_PAD_PIN2  (RUST_DAT_PAD_PIN2)
    );

    // =================================================
    // IO pad instances (IUMAFS)
    // =================================================

    // ----- clk -----
    IUMAFS u_pad_clk (
        .IE   (clk_IE),
        .PORE (PORE),
        .OE   (clk_OE),
        .IDDQ (clk_IDDQ),
        .DO   (clk_DO),
        .PIN2 (clk_PIN2),
        .PIN1 (clk_PIN1),
        .SMT  (clk_SMT),
        .PD   (clk_PD),
        .PU   (clk_PU),
        .DI   (clk_core),
        .PAD  (clk_pad),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- rst_n -----
    IUMAFS u_pad_rst_n (
        .IE   (rst_n_IE),
        .PORE (PORE),
        .OE   (rst_n_OE),
        .IDDQ (rst_n_IDDQ),
        .DO   (rst_n_DO),
        .PIN2 (rst_n_PIN2),
        .PIN1 (rst_n_PIN1),
        .SMT  (rst_n_SMT),
        .PD   (rst_n_PD),
        .PU   (rst_n_PU),
        .DI   (rst_n_core),
        .PAD  (rst_n_pad),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- JTAG TCK -----
    IUMAFS u_pad_jtag_TCK (
        .IE   (jtag_TCK_IE),
        .PORE (PORE),
        .OE   (jtag_TCK_OE),
        .IDDQ (jtag_TCK_IDDQ),
        .DO   (jtag_TCK_DO),
        .PIN2 (jtag_TCK_PIN2),
        .PIN1 (jtag_TCK_PIN1),
        .SMT  (jtag_TCK_SMT),
        .PD   (jtag_TCK_PD),
        .PU   (jtag_TCK_PU),
        .DI   (jtag_TCK_core),
        .PAD  (jtag_TCK_pad),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- JTAG TMS -----
    IUMAFS u_pad_jtag_TMS (
        .IE   (jtag_TMS_IE),
        .PORE (PORE),
        .OE   (jtag_TMS_OE),
        .IDDQ (jtag_TMS_IDDQ),
        .DO   (jtag_TMS_DO),
        .PIN2 (jtag_TMS_PIN2),
        .PIN1 (jtag_TMS_PIN1),
        .SMT  (jtag_TMS_SMT),
        .PD   (jtag_TMS_PD),
        .PU   (jtag_TMS_PU),
        .DI   (jtag_TMS_core),
        .PAD  (jtag_TMS_pad),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- JTAG TDI -----
    IUMAFS u_pad_jtag_TDI (
        .IE   (jtag_TDI_IE),
        .PORE (PORE),
        .OE   (jtag_TDI_OE),
        .IDDQ (jtag_TDI_IDDQ),
        .DO   (jtag_TDI_DO),
        .PIN2 (jtag_TDI_PIN2),
        .PIN1 (jtag_TDI_PIN1),
        .SMT  (jtag_TDI_SMT),
        .PD   (jtag_TDI_PD),
        .PU   (jtag_TDI_PU),
        .DI   (jtag_TDI_core),
        .PAD  (jtag_TDI_pad),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- JTAG TDO (output) -----
    IUMAFS u_pad_jtag_TDO (
        .IE   (jtag_TDO_IE),
        .PORE (PORE),
        .OE   (jtag_TDO_OE),
        .IDDQ (jtag_TDO_IDDQ),
        .DO   (jtag_TDO_core),       // FIX: Was jtag_TDO_DO. Connect to core data.
        .PIN2 (jtag_TDO_PIN2),
        .PIN1 (jtag_TDO_PIN1),
        .SMT  (jtag_TDO_SMT),
        .PD   (jtag_TDO_PD),
        .PU   (jtag_TDO_PU),
        .DI   (/* unused */),
        .PAD  (jtag_TDO_pad),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- AN_VAL_PAD -----
    IUMAFS u_pad_AN_VAL (
        .IE   (AN_VAL_PAD_IE),
        .PORE (PORE),
        .OE   (AN_VAL_PAD_OE),
        .IDDQ (AN_VAL_PAD_IDDQ),
        .DO   (AN_VAL_PAD_DO),
        .PIN2 (AN_VAL_PAD_PIN2),
        .PIN1 (AN_VAL_PAD_PIN1),
        .SMT  (AN_VAL_PAD_SMT),
        .PD   (AN_VAL_PAD_PD),
        .PU   (AN_VAL_PAD_PU),
        .DI   (AN_VAL_core),
        .PAD  (AN_VAL_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- AN_SD_PAD -----
    IUMAFS u_pad_AN_SD (
        .IE   (AN_SD_PAD_IE),
        .PORE (PORE),
        .OE   (AN_SD_PAD_OE),
        .IDDQ (AN_SD_PAD_IDDQ),
        .DO   (AN_SD_PAD_DO),
        .PIN2 (AN_SD_PAD_PIN2),
        .PIN1 (AN_SD_PAD_PIN1),
        .SMT  (AN_SD_PAD_SMT),
        .PD   (AN_SD_PAD_PD),
        .PU   (AN_SD_PAD_PU),
        .DI   (AN_SD_core),
        .PAD  (AN_SD_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- AN_DATA0_PAD -----
    IUMAFS u_pad_AN_DATA0 (
        .IE   (AN_DATA0_PAD_IE),
        .PORE (PORE),
        .OE   (AN_DATA0_PAD_OE),
        .IDDQ (AN_DATA0_PAD_IDDQ),
        .DO   (AN_DATA0_PAD_DO),
        .PIN2 (AN_DATA0_PAD_PIN2),
        .PIN1 (AN_DATA0_PAD_PIN1),
        .SMT  (AN_DATA0_PAD_SMT),
        .PD   (AN_DATA0_PAD_PD),
        .PU   (AN_DATA0_PAD_PU),
        .DI   (AN_DATA0_core),
        .PAD  (AN_DATA0_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- AN_DATA1_PAD -----
    IUMAFS u_pad_AN_DATA1 (
        .IE   (AN_DATA1_PAD_IE),
        .PORE (PORE),
        .OE   (AN_DATA1_PAD_OE),
        .IDDQ (AN_DATA1_PAD_IDDQ),
        .DO   (AN_DATA1_PAD_DO),
        .PIN2 (AN_DATA1_PAD_PIN2),
        .PIN1 (AN_DATA1_PAD_PIN1),
        .SMT  (AN_DATA1_PAD_SMT),
        .PD   (AN_DATA1_PAD_PD),
        .PU   (AN_DATA1_PAD_PU),
        .DI   (AN_DATA1_core),
        .PAD  (AN_DATA1_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- TEST_MODE_PAD -----
    IUMAFS u_pad_TEST_MODE (
        .IE   (TEST_MODE_PAD_IE),
        .PORE (PORE),
        .OE   (TEST_MODE_PAD_OE),
        .IDDQ (TEST_MODE_PAD_IDDQ),
        .DO   (TEST_MODE_PAD_DO),
        .PIN2 (TEST_MODE_PAD_PIN2),
        .PIN1 (TEST_MODE_PAD_PIN1),
        .SMT  (TEST_MODE_PAD_SMT),
        .PD   (TEST_MODE_PAD_PD),
        .PU   (TEST_MODE_PAD_PU),
        .DI   (TEST_MODE_core),
        .PAD  (TEST_MODE_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- COR_START_PAD -----
    IUMAFS u_pad_COR_START (
        .IE   (COR_START_PAD_IE),
        .PORE (PORE),
        .OE   (COR_START_PAD_OE),
        .IDDQ (COR_START_PAD_IDDQ),
        .DO   (COR_START_PAD_DO),
        .PIN2 (COR_START_PAD_PIN2),
        .PIN1 (COR_START_PAD_PIN1),
        .SMT  (COR_START_PAD_SMT),
        .PD   (COR_START_PAD_PD),
        .PU   (COR_START_PAD_PU),
        .DI   (COR_START_core),
        .PAD  (COR_START_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- RUST_VAL_PAD (output) -----
    IUMAFS u_pad_RUST_VAL (
        .IE   (RUST_VAL_PAD_IE),
        .PORE (PORE),
        .OE   (RUST_VAL_PAD_OE),
        .IDDQ (RUST_VAL_PAD_IDDQ),
        .DO   (RUST_VAL_core),      // FIX: Was RUST_VAL_PAD_DO. Connect to core data.
        .PIN2 (RUST_VAL_PAD_PIN2),
        .PIN1 (RUST_VAL_PAD_PIN1),
        .SMT  (RUST_VAL_PAD_SMT),
        .PD   (RUST_VAL_PAD_PD),
        .PU   (RUST_VAL_PAD_PU),
        .DI   (/* unused */),
        .PAD  (RUST_VAL_PAD_pin),
        .VDD  (VDD),
        .VDDIO(VDDIO),
        .VSS  (VSS),
        .VSSIO(VSSIO)
    );

    // ----- RUST_DAT_PAD[2:0] (3-bit output bus) -----
    // FIX: Replaced single instance with a generate block for 3 pads.
    //      Assumes all 3 pads share the same control signals.
    //      Data is now correctly wired from RUST_DAT_core[2:0].
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : gen_rust_dat_pads
            IUMAFS u_pad_RUST_DAT (
                .IE   (RUST_DAT_PAD_IE),
                .PORE (PORE),
                .OE   (RUST_DAT_PAD_OE),
                .IDDQ (RUST_DAT_PAD_IDDQ),
                .DO   (RUST_DAT_core[i]),      // FIX: Connect to indexed core data
                .PIN2 (RUST_DAT_PAD_PIN2),
                .PIN1 (RUST_DAT_PAD_PIN1),
                .SMT  (RUST_DAT_PAD_SMT),
                .PD   (RUST_DAT_PAD_PD),
                .PU   (RUST_DAT_PAD_PU),
                .DI   (/* unused */),
                .PAD  (RUST_DAT_PAD_pin[i]),  // FIX: Connect to indexed pad pin
                .VDD  (VDD),
                .VDDIO(VDDIO),
                .VSS  (VSS),
                .VSSIO(VSSIO)
            );
        end
    endgenerate

endmodule