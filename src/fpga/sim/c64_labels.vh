// C64 KERNAL and BASIC Labels for Simulation Tracing
// Derived from C64rom.lib and c64_kernal.lib

`ifndef C64_LABELS_VH
`define C64_LABELS_VH

// KERNAL Vectors
localparam [15:0] K_SCNKEY = 16'hFF9F;
localparam [15:0] K_LOAD   = 16'hFFD5;
localparam [15:0] K_SAVE   = 16'hFFD8;
localparam [15:0] K_SETTIM = 16'hFFDB;
localparam [15:0] K_RDTIM  = 16'hFFDE;
localparam [15:0] K_STOP   = 16'hFFE1;
localparam [15:0] K_GETIN  = 16'hFFE4;
localparam [15:0] K_CLALL  = 16'hFFE7;
localparam [15:0] K_UDTIM  = 16'hFFEA;
localparam [15:0] K_SCREEN = 16'hFFED;
localparam [15:0] K_PLOT   = 16'hFFF0;
localparam [15:0] K_IOBASE = 16'hFFF3;
localparam [15:0] K_LISTEN = 16'hFFB1;
localparam [15:0] K_SECOND = 16'hFF93;
localparam [15:0] K_TKSA   = 16'hFF96;
localparam [15:0] K_TALK   = 16'hFFB4;
localparam [15:0] K_UNTLK  = 16'hFFAB;
localparam [15:0] K_UNLSN  = 16'hFFAE;
localparam [15:0] K_ACPTR  = 16'hFFA5;
localparam [15:0] K_CIOUT  = 16'hFFA8;
localparam [15:0] K_CHKIN  = 16'hFFC6;
localparam [15:0] K_CHKOUT = 16'hFFC9;
localparam [15:0] K_CHRIN  = 16'hFFCF;
localparam [15:0] K_CHROUT = 16'hFFD2;
localparam [15:0] K_CLOSE  = 16'hFFC3;
localparam [15:0] K_OPEN   = 16'hFFC0;
localparam [15:0] K_SETMSG = 16'hFF90;
localparam [15:0] K_SETLFS = 16'hFFBA;
localparam [15:0] K_SETNAM = 16'hFFBD;
localparam [15:0] K_CLRCHN = 16'hFFCC;
localparam [15:0] K_READST = 16'hFFB7;
localparam [15:0] K_SETTMO = 16'hFFA2;
localparam [15:0] K_MEMTOP = 16'hFF99;
localparam [15:0] K_MEMBOT = 16'hFF9C;
localparam [15:0] K_RESTOR = 16'hFF8A;
localparam [15:0] K_IOINIT = 16'hFF84;
localparam [15:0] K_RAMTAS = 16'hFF87;
localparam [15:0] K_CINT   = 16'hFF81;
localparam [15:0] K_VECTOR = 16'hFF8D;

// BASIC Vectors (Selected)
localparam [15:0] B_COLD   = 16'hA000; // Cold Start
localparam [15:0] B_WARM   = 16'hA002; // Warm Start
localparam [15:0] B_READY  = 16'hA474; // Ready Prompt
localparam [15:0] B_MAIN   = 16'hA480; // Main Loop
localparam [15:0] B_LIST   = 16'hA69C;
localparam [15:0] B_RUN    = 16'hA871;

task print_label_trace;
    input [15:0] addr;
    begin
        case (addr)
            K_SCNKEY: $display("[TRACE] KERNAL: SCNKEY (Scan Keyboard)");
            K_LOAD:   $display("[TRACE] KERNAL: LOAD");
            K_SAVE:   $display("[TRACE] KERNAL: SAVE");
            K_SETTIM: $display("[TRACE] KERNAL: SETTIM");
            K_RDTIM:  $display("[TRACE] KERNAL: RDTIM");
            K_STOP:   $display("[TRACE] KERNAL: STOP");
            K_GETIN:  $display("[TRACE] KERNAL: GETIN");
            K_CLALL:  $display("[TRACE] KERNAL: CLALL");
            K_UDTIM:  $display("[TRACE] KERNAL: UDTIM");
            K_SCREEN: $display("[TRACE] KERNAL: SCREEN");
            K_PLOT:   $display("[TRACE] KERNAL: PLOT");
            K_IOBASE: $display("[TRACE] KERNAL: IOBASE");
            K_LISTEN: $display("[TRACE] KERNAL: LISTEN");
            K_SECOND: $display("[TRACE] KERNAL: SECOND");
            K_TKSA:   $display("[TRACE] KERNAL: TKSA");
            K_TALK:   $display("[TRACE] KERNAL: TALK");
            K_UNTLK:  $display("[TRACE] KERNAL: UNTLK");
            K_UNLSN:  $display("[TRACE] KERNAL: UNLSN");
            K_ACPTR:  $display("[TRACE] KERNAL: ACPTR");
            K_CIOUT:  $display("[TRACE] KERNAL: CIOUT");
            K_CHKIN:  $display("[TRACE] KERNAL: CHKIN");
            K_CHKOUT: $display("[TRACE] KERNAL: CHKOUT");
            K_CHRIN:  $display("[TRACE] KERNAL: CHRIN");
            K_CHROUT: $display("[TRACE] KERNAL: CHROUT");
            K_CLOSE:  $display("[TRACE] KERNAL: CLOSE");
            K_OPEN:   $display("[TRACE] KERNAL: OPEN");
            K_SETMSG: $display("[TRACE] KERNAL: SETMSG");
            K_SETLFS: $display("[TRACE] KERNAL: SETLFS");
            K_SETNAM: $display("[TRACE] KERNAL: SETNAM");
            K_CLRCHN: $display("[TRACE] KERNAL: CLRCHN");
            K_READST: $display("[TRACE] KERNAL: READST");
            K_SETTMO: $display("[TRACE] KERNAL: SETTMO");
            K_MEMTOP: $display("[TRACE] KERNAL: MEMTOP");
            K_MEMBOT: $display("[TRACE] KERNAL: MEMBOT");
            K_RESTOR: $display("[TRACE] KERNAL: RESTOR");
            K_IOINIT: $display("[TRACE] KERNAL: IOINIT");
            K_RAMTAS: $display("[TRACE] KERNAL: RAMTAS");
            K_CINT:   $display("[TRACE] KERNAL: CINT");
            K_VECTOR: $display("[TRACE] KERNAL: VECTOR");
            
            B_COLD:   $display("[TRACE] BASIC: Cold Start");
            B_WARM:   $display("[TRACE] BASIC: Warm Start");
            B_READY:  $display("[TRACE] BASIC: Ready");
            B_MAIN:   $display("[TRACE] BASIC: Main Loop");
            B_LIST:   $display("[TRACE] BASIC: LIST");
            B_RUN:    $display("[TRACE] BASIC: RUN");
        endcase
    end
endtask

`endif // C64_LABELS_VH
