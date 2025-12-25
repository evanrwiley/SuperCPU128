; ==============================================================================
; SUPERCPU CREATOR STUDIO - MAIN IDE
; The central hub for the C64/C128 Development Suite.
; ==============================================================================

.cpu "65816"

; ------------------------------------------------------------------------------
; Constants & Memory Map
; ------------------------------------------------------------------------------
SCREEN_RAM      = $0400
COLOR_RAM       = $D800
BORDER_COLOR    = $D020
BG_COLOR        = $D021

; Shared Memory / Bridge Interface
BRIDGE_CMD      = $DE00 ; Command Register
BRIDGE_ADDR_LO  = $DE01 ; Param Address Low
BRIDGE_ADDR_HI  = $DE02 ; Param Address High
BRIDGE_PARAM    = $DE03 ; Param / Length
BRIDGE_VALID    = $DE10 ; Valid Bit (Write 1 to trigger)
BRIDGE_DONE     = $DE14 ; Done Bit (Read 1 when complete)

; Command Codes
CMD_BUILD       = $10
CMD_SPRITE      = $20
CMD_SID         = $30
CMD_AI_CFG      = $40

; Buffers
PROMPT_BUFFER   = $CF00 ; 256 Byte Buffer for User Input

; ------------------------------------------------------------------------------
; Main Entry Point
; ------------------------------------------------------------------------------
* = $0801
    .byte $0B, $08, $0A, $00, $9E, "2061", $00, $00, $00 ; SYS 2061

Start:
    SEI
    CLD
    JSR InitScreen
    JSR DrawMenu
    
MainLoop:
    JSR GetKey
    CMP #"1"
    BEQ DoEditor
    CMP #"2"
    BEQ DoSprite
    CMP #"3"
    BEQ DoSound
    CMP #"4"
    BEQ DoBuild
    CMP #"5"
    BEQ DoDebug
    JMP MainLoop

; ------------------------------------------------------------------------------
; Subroutines
; ------------------------------------------------------------------------------
InitScreen:
    LDA #$00
    STA BORDER_COLOR
    STA BG_COLOR
    LDA #$0E ; Light Blue Text
    STA $0286
    JSR $E544 ; CLRHOME
    RTS

DrawMenu:
    LDX #$00
DrawLoop:
    LDA MenuText,X
    BEQ DrawDone
    JSR $FFD2 ; CHROUT
    INX
    JMP DrawLoop
DrawDone:
    RTS

MenuText:
    .text "SUPERCPU CREATOR STUDIO", 13, 13
    .text "1. CODE EDITOR", 13
    .text "2. SPRITE STUDIO (AI)", 13
    .text "3. SID LAB (AI)", 13
    .text "4. BUILD PROJECT", 13
    .text "5. DEBUGGER", 13, 13
    .text "SELECT OPTION > ", 0

DoEditor:
    ; Placeholder for Editor
    JMP MainLoop

DoSprite:
    JSR InputPrompt
    LDA #CMD_SPRITE
    JSR SendCommand
    JMP MainLoop

DoSound:
    JSR InputPrompt
    LDA #CMD_SID
    JSR SendCommand
    JMP MainLoop

DoBuild:
    LDA #CMD_BUILD
    JSR SendCommand
    JMP MainLoop

DoDebug:
    BRK
    JMP MainLoop

; ------------------------------------------------------------------------------
; Input Prompt Routine
; ------------------------------------------------------------------------------
InputPrompt:
    ; Clear Buffer
    LDX #$00
    LDA #$00
ClrBuf:
    STA PROMPT_BUFFER,X
    INX
    BNE ClrBuf
    
    ; Print "DESCRIBE > "
    LDA #$0D
    JSR $FFD2
    LDA #"D"
    JSR $FFD2
    LDA #">"
    JSR $FFD2
    LDA #" "
    JSR $FFD2
    
    ; Get String
    LDX #$00
GetStrLoop:
    JSR $FF9F ; SCANSKEY
    JSR $FFE4 ; GETIN
    BEQ GetStrLoop
    CMP #$0D ; Return
    BEQ GetStrDone
    STA PROMPT_BUFFER,X
    JSR $FFD2 ; Echo
    INX
    CPX #$FF
    BNE GetStrLoop
GetStrDone:
    RTS

; ------------------------------------------------------------------------------
; Send Command to Bridge
; ------------------------------------------------------------------------------
SendCommand:
    STA BRIDGE_CMD      ; Store Command Type
    
    LDA #<PROMPT_BUFFER ; Store Address of Prompt
    STA BRIDGE_ADDR_LO
    LDA #>PROMPT_BUFFER
    STA BRIDGE_ADDR_HI
    
    LDA #$01
    STA BRIDGE_VALID    ; Trigger Daemon
    
    ; Wait for Done
    LDA #$05 ; Purple Border (Busy)
    STA BORDER_COLOR
WaitLoop:
    LDA BRIDGE_DONE
    BEQ WaitLoop
    
    LDA #$00 ; Black Border (Done)
    STA BORDER_COLOR
    
    ; Clear Valid
    LDA #$00
    STA BRIDGE_VALID
    RTS

GetKey:
    JSR $FF9F ; SCANSKEY
    JSR $FFE4 ; GETIN
    BEQ GetKey
    RTS

