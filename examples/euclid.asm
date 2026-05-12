include '../apogee-sdk/source/kr580vm80a.inc'
include '../apogee-sdk/source/apogee.inc'

format rka

STROBE_OFF := 0
STROBE_ON  := MIDI_CTRL_STROBE

L64 := 1
L32 := 2
L16 := 4
L8  := 8
L4  := 16
L2  := 32
L1  := 64

C_  := 0
Cs_ := 1
D_  := 2
Ds_ := 3
E_  := 4
F_  := 5
Fs_ := 6
G_  := 7
Gs_ := 8
A_  := 9
As_ := 10
B_  := 11

macro euclid k*, n*, sl*, nl*, ch*, nt*, oct*, vel:127
    db k
    db n
    db n - k
    db sl
    db 1
    db nl
    db 0
    db 090h + ch
    db (oct + 1) * 12 + nt
    db vel
end macro

start:
    MVI A, VG75_CMD_STOP_DISP
    STA VG75_CMD
    MVI A, 80h
    STA VV55_USR_CWR

loop:
    LXI H, data

tloop:
    MOV A, M
    CPI 0FFh
    JZ  wait

    PUSH H

    LXI D, 6
    DAD D
    MOV A, M
    ORA A
    JZ  .cstep
    DCR A
    MOV M, A
    JNZ .cstep
    CALL noff

.cstep:
    POP H
    PUSH H
    LXI D, 4
    DAD D
    MOV A, M
    DCR A
    MOV M, A
    JNZ .next

    POP H
    PUSH H
    LXI D, 3
    DAD D
    MOV A, M
    INX H
    MOV M, A

    POP H
    PUSH H
    MOV B, M
    INX H
    MOV C, M
    INX H
    MOV A, M
    ADD B
    CMP C
    JC  .nob

    SUB C
    MOV M, A

    POP H
    PUSH H
    LXI D, 6
    DAD D
    MOV A, M
    ORA A
    JZ  .don
    CALL noff

.don:
    POP H
    PUSH H
    LXI D, 5
    DAD D
    MOV A, M
    INX H
    MOV M, A
    CALL non
    JMP .next

.nob:
    MOV M, A

.next:
    POP H
    LXI D, 10
    DAD D
    JMP tloop

wait:
    LXI B, 0900h
.dly:
    DCX B
    MOV A, B
    ORA C
    JNZ .dly
    JMP loop

noff:
    INX H
    MOV E, M
    CALL midi_out
    INX H
    MOV E, M
    CALL midi_out
    MVI E, 0
    CALL midi_out
    DCX H
    DCX H
    RET

non:
    INX H
    MOV E, M
    CALL midi_out
    INX H
    MOV E, M
    CALL midi_out
    INX H
    MOV E, M
    CALL midi_out
    DCX H
    DCX H
    DCX H
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

data:
    euclid 4,  16, L16, L32, 0, C_,  2, 120
    euclid 5,  16, L16, L8,  0, E_,  3, 100
    euclid 7,  12, L16, L64, 1, B_,  4, 90
    euclid 3,  8,  L8,  L2,  2, G_,  3, 80
    euclid 13, 16, L16, L64, 4, Fs_, 3, 85
    db 0FFh
