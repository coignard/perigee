include '../apogee-sdk/source/kr580vm80a.inc'
include '../apogee-sdk/source/apogee.inc'

format rka

STROBE_OFF := 0
STROBE_ON  := MIDI_CTRL_STROBE

T4 := 12
T3 := 16
T8 := 6

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

macro play ss*, sl*, ch*, vel*
    dw ss
    dw ss
    dw 0
    db sl
    db 1
    db ch
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
    MOV E, M
    INX H
    MOV D, M
    DCX H
    MOV A, E
    ANA D
    CPI 0FFh
    JZ  wait

    PUSH H
    LXI D, 7
    DAD D
    MOV A, M
    DCR A
    MOV M, A
    JNZ next

    POP H
    PUSH H
    LXI D, 6
    DAD D
    MOV A, M
    INX H
    MOV M, A

    POP H
    PUSH H
    CALL coff

    POP H
    PUSH H
    CALL gnext

    POP H
    PUSH H
    LXI B, 4
    DAD B
    MOV M, E
    INX H
    MOV M, D

    POP H
    PUSH H
    CALL con

next:
    POP H
    LXI D, 10
    DAD D
    JMP tloop

wait:
    LXI B, 0D00h
.dly:
    DCX B
    MOV A, B
    ORA C
    JNZ .dly
    JMP loop

coff:
    PUSH H
    LXI D, 8
    DAD D
    MOV C, M
    MOV A, C
    ORI 080h
    MOV C, A
    POP H
    PUSH H
    LXI D, 4
    DAD D
    MOV E, M
    INX H
    MOV D, M
    MOV A, E
    ORA D
    JZ  .done
    XCHG
.loop:
    MOV A, M
    CPI 0FFh
    JZ  .done
    PUSH B
    PUSH H
    MOV E, C
    CALL midi_out
    MOV E, M
    CALL midi_out
    MVI E, 0
    CALL midi_out
    POP H
    POP B
    INX H
    JMP .loop
.done:
    POP H
    RET

con:
    PUSH H
    LXI D, 8
    DAD D
    MOV C, M
    MOV A, C
    ORI 090h
    MOV C, A
    INX H
    MOV B, M
    POP H
    PUSH H
    LXI D, 4
    DAD D
    MOV E, M
    INX H
    MOV D, M
    MOV A, E
    ORA D
    JZ  .done
    XCHG
.loop:
    MOV A, M
    CPI 0FFh
    JZ  .done
    PUSH B
    PUSH H
    MOV E, C
    CALL midi_out
    MOV E, M
    CALL midi_out
    MOV E, B
    CALL midi_out
    POP H
    POP B
    INX H
    JMP .loop
.done:
    POP H
    RET

gnext:
    PUSH H
    LXI D, 2
    DAD D
    MOV E, M
    INX H
    MOV D, M
    XCHG
    MOV C, M
    INX H
    MOV B, M
    MOV A, C
    ANA B
    CPI 0FFh
    JNZ .got
    POP H
    PUSH H
    MOV E, M
    INX H
    MOV D, M
    XCHG
    MOV C, M
    INX H
    MOV B, M
.got:
    INX H
    XCHG
    POP H
    PUSH H
    PUSH B
    LXI B, 2
    DAD B
    MOV M, E
    INX H
    MOV M, D
    POP D
    POP H
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

cCm: db (2+1)*12+C_,  (2+1)*12+Ds_, (2+1)*12+G_,  0FFh
cFm: db (2+1)*12+F_,  (2+1)*12+Gs_, (3+1)*12+C_,  0FFh
cGm: db (2+1)*12+G_,  (2+1)*12+As_, (3+1)*12+D_,  0FFh
cD:  db (2+1)*12+D_,  (2+1)*12+Fs_, (2+1)*12+A_,  0FFh
cA:  db (2+1)*12+A_,  (3+1)*12+Cs_, (3+1)*12+E_,  0FFh

seq1:
    dw cCm, cFm, cGm, 0FFFFh

seq2:
    dw cD, cA, 0FFFFh

data:
    play seq1, T4, 4, 100
    play seq2, T3, 0, 110
    dw 0FFFFh
