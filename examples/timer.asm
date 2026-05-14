include '../source/kr580vm80a.inc'
include '../source/apogee.inc'
include '../source/cycles.inc'

format rka

MASTER_CLOCK := 16000000
CPU_DIVIDER  := 9
BPM          := 120

CYCLES_PER_WHOLE := (MASTER_CLOCK * 60 * 4) / (CPU_DIVIDER * BPM)

macro measure_block out_var
    local current_cycles
    current_cycles = 0

    macro ?! line&
        match =end =measure_block, line
            purge ?
            out_var = current_cycles
        else match =MOV dest =, =M, line
            line
            current_cycles = current_cycles + T_MOV_R_M
        else match =MOV =M =, src, line
            line
            current_cycles = current_cycles + T_MOV_M_R
        else match =MOV dest =, src, line
            line
            current_cycles = current_cycles + T_MOV_R_R
        else match =MVI =M =, imm, line
            line
            current_cycles = current_cycles + T_MVI_M
        else match =MVI dest =, imm, line
            line
            current_cycles = current_cycles + T_MVI_R
        else match =STA addr, line
            line
            current_cycles = current_cycles + T_STA
        else match =RET, line
            line
            current_cycles = current_cycles + T_RET
        else match =CALL addr, line
            line
            current_cycles = current_cycles + T_CALL + CYCLES_#addr
        else match =DCX rp, line
            line
            current_cycles = current_cycles + T_DCX_RP
        else match =ORA r, line
            line
            current_cycles = current_cycles + T_ORA_R
        else match =JNZ addr, line
            line
            current_cycles = current_cycles + T_JCC
        else match =PUSH rp, line
            line
            current_cycles = current_cycles + T_PUSH_RP
        else match =POP rp, line
            line
            current_cycles = current_cycles + T_POP_RP
        else match =DCR r, line
            line
            current_cycles = current_cycles + T_DCR_R
        else match =LXI rp =, imm, line
            line
            current_cycles = current_cycles + T_LXI_RP
        else match =NOP, line
            line
            current_cycles = current_cycles + T_NOP
        else
            line
        end match
    end macro
end macro

macro note_on ch, key, vel
    MVI E, 090h + ch
    MVI D, key
    MVI C, vel
    CALL send_note
end macro

macro note_off ch, key
    MVI E, 080h + ch
    MVI D, key
    MVI C, 0
    CALL send_note
end macro

macro pad_cycles remaining_cycles
    local m, n
    m = remaining_cycles mod 4
    n = (remaining_cycles - T_MOV_R_R * m) / T_NOP

    if n < 0
        err 'remaining cycles cannot be exactly padded with nops and movs :-('
    end if

    repeat n
        NOP
    end repeat

    repeat m
        MOV A, A
    end repeat
end macro

macro delay_cycles target_cycles
    local loops, remainder

    if target_cycles >= CYCLES_LOOP_SETUP + CYCLES_LOOP_ITER
        loops     = (target_cycles - CYCLES_LOOP_SETUP) / CYCLES_LOOP_ITER
        remainder = (target_cycles - CYCLES_LOOP_SETUP) mod CYCLES_LOOP_ITER

        if remainder - T_MOV_R_R * (remainder mod 4) < 0
            loops     = loops - 1
            remainder = remainder + CYCLES_LOOP_ITER
        end if

        if loops > 65535
            err 'delay is too long for a 16-bit register'
        end if

        LXI B, loops
        CALL delay_loop
    else
        remainder = target_cycles
    end if

    pad_cycles remainder
end macro

macro test_note_length note_div, repeats
    local loop_start, phase_cycles, delay_on, delay_off

    phase_cycles = (CYCLES_PER_WHOLE / note_div) / 2
    delay_on  = phase_cycles - (CYCLES_ON_OVERHEAD + CYCLES_NOTE_ON)
    delay_off = phase_cycles - (CYCLES_NOTE_OFF + CYCLES_OFF_OVERHEAD)

    MVI B, repeats
loop_start:
    PUSH B

    note_on 0, 60, 127
    delay_cycles delay_on

    note_off 0, 60
    delay_cycles delay_off

    POP B
    DCR B
    JNZ loop_start
end macro

start:
    MVI A, VG75_CMD_STOP_DISP
    STA VG75_CMD
    MVI A, VV55_CWR_MODE_SET or VV55_CWR_GRP_A_MODE1
    STA VV55_USR_CWR

main_loop:
    test_note_length 4, 4
    test_note_length 8, 8
    test_note_length 16, 16
    test_note_length 32, 32
    test_note_length 64, 64
    JMP main_loop

midi_out:
measure_block CYCLES_midi_out
    MOV A, E
    STA VV55_USR_PORT_A     ; hardware strobe automatically triggered via port C
    RET
end measure_block

send_note:
measure_block CYCLES_send_note
    CALL midi_out
    MOV E, D
    CALL midi_out
    MOV E, C
    CALL midi_out
    RET
end measure_block

delay_loop:
    DCX B
    MOV A, B
    ORA C
    JNZ delay_loop
    RET

CYCLES_delay_loop = T_RET

virtual
    dummy_label:

    measure_block CYCLES_NOTE_ON
        MVI E, 090h
        MVI D, 60
        MVI C, 127
        CALL send_note
    end measure_block

    measure_block CYCLES_ON_OVERHEAD
        PUSH B
    end measure_block

    measure_block CYCLES_NOTE_OFF
        MVI E, 080h
        MVI D, 60
        MVI C, 0
        CALL send_note
    end measure_block

    measure_block CYCLES_OFF_OVERHEAD
        POP B
        DCR B
        JNZ dummy_label
    end measure_block

    measure_block CYCLES_LOOP_SETUP
        LXI B, 0
        CALL delay_loop
    end measure_block

    measure_block CYCLES_LOOP_ITER
        DCX B
        MOV A, B
        ORA C
        JNZ dummy_label
    end measure_block
end virtual
