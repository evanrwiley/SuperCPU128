; ==============================================================================
; NEURAL MONITOR - C64 CLIENT
; The "Thin Client" that runs on the C64 and talks to the AI Bridge.
; ==============================================================================

.cpu "65816"

; Shared Memory Bridge Addresses
BRIDGE_CMD      = $DE00 ; Command Register (0=Idle, 1=Analyze, 2=Optimize)
BRIDGE_ADDR_LO  = $DE01 ; Target Address Low
BRIDGE_ADDR_HI  = $DE02 ; Target Address High
BRIDGE_LEN      = $DE03 ; Length (Pages)
BRIDGE_STATUS   = $DE04 ; 0=Ready, 1=Busy, 2=Done
BRIDGE_RESULT   = $DE10 ; Start of Result Text Buffer (Null Terminated)

; ------------------------------------------------------------------------------
; Main Loop
; ------------------------------------------------------------------------------
Main:
    JSR DrawUI          ; Draw the Monitor Interface
    
InputLoop:
    JSR GetKey          ; Wait for keypress
    CMP #$85            ; F1 Key?
    BEQ DoExplain
    CMP #$86            ; F3 Key?
    BEQ DoOptimize
    JMP InputLoop

; ------------------------------------------------------------------------------
; Action: Explain Code at Current Cursor
; ------------------------------------------------------------------------------
DoExplain:
    LDA #<CurrentAddr   ; Get address under cursor
    STA BRIDGE_ADDR_LO
    LDA #>CurrentAddr
    STA BRIDGE_ADDR_HI
    LDA #$01            ; Length: 1 Page (256 bytes)
    STA BRIDGE_LEN
    
    LDA #$01            ; Command: 1 = ANALYZE/EXPLAIN
    STA BRIDGE_CMD
    
    JSR WaitForAI       ; Wait for ARM to process
    JSR ShowPopup       ; Display text from BRIDGE_RESULT
    JMP InputLoop

; ------------------------------------------------------------------------------
; Wait for AI (Blocking)
; ------------------------------------------------------------------------------
WaitForAI:
    LDA #$01
    STA BorderColor     ; Set Border White (Thinking)
Wait:
    LDA BRIDGE_STATUS
    CMP #$02            ; Done?
    BEQ Done
    JMP Wait
Done:
    LDA #$00
    STA BorderColor     ; Set Border Black (Ready)
    RTS

; ------------------------------------------------------------------------------
; Show Popup Window
; ------------------------------------------------------------------------------
ShowPopup:
    ; (Routine to draw a box on screen and print the text at $DE10)
    ; ...
    RTS
