include '../apogee-sdk/source/kr580vm80a.inc'
include '../apogee-sdk/source/apogee.inc'

format rka

STROBE_OFF := 0
STROBE_ON  := MIDI_CTRL_STROBE

start:
    MVI A, VG75_CMD_STOP_DISP
    STA VG75_CMD
    MVI A, 80h
    STA VV55_USR_CWR

main_loop:
    MVI B, 4

.loop4:
    PUSH B
    MVI E, 090h
    MVI D, 60
    MVI C, 127
    CALL send_note
    LXI B, 18500
    CALL loop
    NOP
    NOP
    MOV A, A
    MOV A, A
    MOV A, A
    MVI E, 080h
    MVI D, 60
    MVI C, 0
    CALL send_note
    LXI B, 18500
    CALL loop
    MOV A, A
    MOV A, A
    POP B
    DCR B
    JNZ .loop4

    MVI B, 8

.loop8:
    PUSH B
    MVI E, 090h
    MVI D, 60
    MVI C, 127
    CALL send_note
    LXI B, 9241
    CALL loop
    MVI A, 0
    MOV A, A
    MOV A, A
    MVI E, 080h
    MVI D, 60
    MVI C, 0
    CALL send_note
    LXI B, 9240
    CALL loop
    MVI A, 0
    MOV A, A
    MOV A, A
    MOV A, A
    MOV A, A
    POP B
    DCR B
    JNZ .loop8

    MVI B, 16

.loop16:
    PUSH B
    MVI E, 090h
    MVI D, 60
    MVI C, 127
    CALL send_note
    LXI B, 4611
    CALL loop
    MVI A, 0
    MVI A, 0
    MVI A, 0
    MOV A, A
    MVI E, 080h
    MVI D, 60
    MVI C, 0
    CALL send_note
    LXI B, 4611
    CALL loop
    NOP
    NOP
    NOP
    POP B
    DCR B
    JNZ .loop16

    MVI B, 32

.loop32:
    PUSH B
    MVI E, 090h
    MVI D, 60
    MVI C, 127
    CALL send_note
    LXI B, 2296
    CALL loop
    MOV A, A
    MOV A, A
    MOV A, A
    MOV A, A
    MOV A, A
    MOV A, A
    MVI E, 080h
    MVI D, 60
    MVI C, 0
    CALL send_note
    LXI B, 2296
    CALL loop
    MVI A, 0
    MOV A, A
    MOV A, A
    POP B
    DCR B
    JNZ .loop32

    MVI B, 64

.loop64:
    PUSH B
    MVI E, 090h
    MVI D, 60
    MVI C, 127
    CALL send_note
    LXI B, 1139
    CALL loop
    MVI A, 0
    MVI A, 0
    MVI A, 0
    MVI E, 080h
    MVI D, 60
    MVI C, 0
    CALL send_note
    LXI B, 1139
    CALL loop
    MVI A, 0
    POP B
    DCR B
    JNZ .loop64

    JMP main_loop

send_note:
    CALL midi_out
    MOV E, D
    CALL midi_out
    MOV E, C
    CALL midi_out
    RET

midi_out:
    MOV A, E
    STA VV55_USR_PORT_A
    MVI A, STROBE_OFF
    STA VV55_USR_PORT_C
    MVI A, STROBE_ON
    STA VV55_USR_PORT_C
    MVI A, STROBE_OFF
    STA VV55_USR_PORT_C
    RET

loop:
    DCX B
    MOV A, B
    ORA C
    JNZ loop
    RET
