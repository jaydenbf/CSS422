*-----------------------------------------------------------
* Title      : Disassembler for CSS 422 Project - Team Terminal
*-----------------------------------------------------------

LF          EQU         $0A
CR          EQU         $0D


*--------------------------------------------------------------
*           BEGINNING OF PROGRAM
*--------------------------------------------------------------

            ORG         $1000
START:       

*--------------------------------------------------------------
*           RECEIVE AND PARSE INPUT
*   postcondition:  correct hexadecimal addresses inputted 
*                   will be entered into
*                       starting address    - $700
*                       ending address      - $710
*--------------------------------------------------------------


RESTART     MOVE.L      #$500,A2
            MOVE.L      #$000,A4
            MOVE.B      #0,D7       ;   used many times as a counter for loops
            MOVE.B      #0,D6       ;   used as a counter for how many lines we've printed

            LEA         WLC,A1
            MOVE.B      #14,D0
            TRAP        #15         ;   print welcome message


            LEA         SADDR,A1
            MOVE.B      #14,D0
            TRAP        #15         ;   ask for starting address
            
            MOVE.L      #$600,A1
            MOVE.B      #2,D0
            TRAP        #15         ;   read number from keyboard into $600
            
DECODE      MOVE.B      (A1)+,D1
            CMPI.B      #$30,D1     ;   is D1 < 30
            BLT.B       INV         ;   then invalid
            CMP.B       #$39,D1     ;   is D1 <= 39
            BLE.B       NOLTR       ;   if so, it's not a letter (so branch)
        
            CMPI.B      #$41,D1     ;   is D1 < 41
            BLT.B       INV         ;   then invalid
            CMPI.B      #$46,D1     ;   is D1 > 46
            BGT.B       INV         ;   then invalid
            SUBI.B      #$37,D1     ;   subtract 37 from D1
            BRA         LTR         ;   finished with this letter

NOLTR       SUBI.B      #$30,D1     ;   if it's a number subtract 30

LTR         MOVE.B      D1,(A2)+    ;   throw byte into $5000s
            ADDI.B      #1,D7
            CMPI.B      #8,D7
            BEQ         FSADDR      ;   finished decoding
            BRA         DECODE      ;   repeat for all 8 times

INV         LEA         INVALID,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         RESTART

FSADDR      CMPI.B      #$FF,$517
            BNE         FEADDR

            LEA         EADDR,A1
            MOVE.B      #14,D0
            TRAP        #15         ;   ask for ending address
            
            MOVEA.L     #$600,A1
            MOVEA.L     #$510,A2
            MOVE.B      #0,D7
            
            MOVE.B      #2,D0
            TRAP        #15         ;   read number from keyboard into $6000
            
            BRA         DECODE

FEADDR      MOVE.B      #0,D7
            MOVE.L      #$00000000,D1   ; clear d1
            MOVEA.L     #$500,A1
            
COMB        MOVE.B      (A1)+,D2
            ASL.L       #4,D1
            ADD.L       D2,D1
           
            ADDI.B      #1,D7
            CMPI.B      #8,D7           ; check counter
            BEQ         FSCOMB
            BNE         COMB
            
FSCOMB      CMPI.B      #$FF,$700
            BNE         FECOMB
            MOVEA.L     #$510,A1
            MOVEA.L     #$700,A2
            MOVE.L      D1,(A2)         ; load the start address hex number into $700
            MOVEA.L     #$510,A1
            MOVE.L      #$00000000,D1   ; clear d1
            MOVE.L      #$00000000,D2   ; clear d2
            MOVE.B      #0,D7           ; reset counter
            BRA         COMB            ; repeat for ending address
            
FECOMB      MOVEA.L     #$710,A2
            MOVE.L      D1,(A2)         ; move ending address into $710
            
*--------------------------------------------------------------
*           FIND OPCODE
*--------------------------------------------------------------
            MOVEA.L     $700,A6        ; will use a6 as the current address
            
FINDOP      LEA         CRLF,A1
            MOVE.B      #14,D0
            TRAP        #15             ; next line

            CMPA.L      $710,A6         ; if we are at the final address
            BEQ         DONE_OPCODE     ; done
            
            MOVEA.L     #$00000000,A4   ; setup output
            
            MOVEA.L     #0,A1
            MOVE.L      A6,D1
            
            SWAP        D1
            JSR         HEX_ASCII       ; first word of address in ascii at $0
            
            SWAP        D1
            ADDA.L      #4,A1
            JSR         HEX_ASCII       ; second word of address in ascii at $0
            
            
            ADDA.L      #8,A4           ; skip to space after address
            
            
            MOVE.B      #32,(A4)+
            MOVE.B      #32,(A4)+       ; ' ' doesn't work for some reason, these are spaces
            MOVE.B      #32,(A4)+
            MOVE.B      #32,(A4)+
            
            MOVE.L      #$00000000,D1   ; clear d1
            MOVE.W      (A6),D1         ; load 4 hex-digit opcode into d1 for decoding
            MOVE.W      (A6),D5         ; load 4 hex-digit opcode into d5 for storage (needed for some opcodes)
            ADDA.W      #2,A6           ; move past current opcode
            
                        
            *BRA         DATA            ; test purposes, should delete
            
            
            ; begin decoding
            ASL.W       #1,D1
            
            BCC         BITS_0
            BCS         BITS_1

BITS_0      ASL.W       #1,D1
            BCC         MOVE            ; MOVE
            BCS         BITS_01
            
BITS_01     ASL.W       #1,D1
            BCC         BITS_010
            BCS         BITS_011
           
BITS_010    ASL.W       #2,D1
            BCC         BITS_010X0
            BCS         BITS_010X1

BITS_011    ASL.W       #1,D1           ; Bcc if any of next 4 bits are 1
            BCS         Bcc
            ASL.W       #1,D1
            BCS         Bcc
            ASL.W       #1,D1
            BCS         Bcc
            ASL.W       #1,D1
            BCS         Bcc
            BRA         BRA             ; BRA otherwise

BITS_010X0  ASL.W       #4,D1
            BCC         NOT             ; NOT
            BCS         LEA             ; LEA
            
BITS_010X1  ASL.W       #2,D1
            BCC         BITS_010X1X0
            BCS         BITS_010X1X1
            
BITS_010X1X0
            ASL.W       #1,D1
            BCC         MOVEM           ; MOVEM
            BCS         LEA             ; LEA
            
BITS_010X1X1
            ASL.W       #1,D1
            BCC         BITS_010X1X10
            BCS         LEA             ; LEA
            
BITS_010X1X10
            ASL.W       #1,D1
            BCS         JSR             ; JSR
            ASL.W       #5,D1
            BCC         NOP             ; NOP
            BCS         RTS             ; RTS

BITS_1      ASL.W       #1,D1
            BCC         SUB             ; SUB
            BCS         BITS_11
            
BITS_11     ASL.W       #1,D1
            BCC         BITS_110
            BCS         BITS_111

BITS_110    ASL.W       #1,D1
            BCC         BITS_1100
            BCS         AND             ; AND
          
BITS_111    ASL.W       #4,D1
            BCC         ASR             ; ASR
            BCS         LSL             ; LSL

BITS_1100   ASL.W       #4,D1           ; AND if any bits 8-6 are 0
            BCC         AND
            ASL.W       #1,D1
            BCC         AND            
            ASL.W       #1,D1
            BCC         AND
            BRA         MULS            ; MULS otherwise
            
*--------------------------------------------------------------
*           NOP
*--------------------------------------------------------------
NOP         CMPI.W      #$4E71,D5
            BNE         DATA
            
            MOVE.B      'N',(A4)+
            MOVE.B      'O',(A4)+
            MOVE.B      'P',(A4)+

            BRA         FINISHED

*--------------------------------------------------------------
*           MOVE
*--------------------------------------------------------------
MOVE        MOVE.B 'M',(A4)+
            MOVE.B 'O',(A4)+
            MOVE.B 'V',(A4)+
            MOVE.B 'E',(A4)+     
            CLR.L       D5              ; clear D5
            MOVE.W      (A6),D5         ; move address to D5
            LSR.L       #6,D5           ; bring 12th and 13th bit to front for size
            LSR.L       #6,D5           
            AND.B       #$03,D5          ; mask bits
            CMP.B       #$0,D5          ; 00 = byte
            BEQ         BYTE_SIZE
            CMP.B       #$01,D5         ; 01 = word
            BEQ         WORD_SIZE       
            CMP.B       #$02,D5         ; 10 = long
            BEQ         LONG_SIZE       
            JMP         DATA            ; else size is invalid 
             
            MOVE.B      #$20,(A4)+  ; SPACES
            MOVE.B      #$20,(A4)+
            MOVE.B      #$20,(A4)+
            
            CLR.L       D5              ; clear D5
            MOVE.W      (A6),D5         ; move address to D5
            MOVE.W      D5,D1           ; copy to D1 for ea printing
            JSR         EA_MFIRST
            MOVE.B      #$2C,(A4)+      ; print comma
            
            MOVE.W      D5,D1           ; copy to D1 again
            ANDI.W      #%0000000111000000,D1 ; keep destination mode
            LSR.L       #3,D1           ; bring the destination mode forward
            ANDI.W      #%000011100000000,D5 ; keep destination register
            LSR.L       #3,D5           ; bring the destination register to front
            LSR.L       #6,D5            
            
            ; at this point we have D1 -> 0000000000111000 1s being mode
            ;                       D5 -> 0000000000000111 1s being register
            ADD.L       D5,D1
            CLR.L       D5              ; clear D5
            MOVE.W      (A6),D5         ; reset address on D5
            JSR         EA_MFIRST       ; D1 is ready for destination ea print
            
            BRA         FINISHED

*--------------------------------------------------------------
*           MOVEM
*--------------------------------------------------------------
MOVEM       BRA         FINISHED


*--------------------------------------------------------------
*           ADD
*--------------------------------------------------------------
ADD         BRA         FINISHED


*--------------------------------------------------------------
*           SUB
*--------------------------------------------------------------
SUB         BRA         FINISHED


*--------------------------------------------------------------
*           MULS (MULS.L NOT SUPPORTED)
*--------------------------------------------------------------
MULS        BRA         FINISHED


*--------------------------------------------------------------
*           LEA
*--------------------------------------------------------------
LEA         BRA         FINISHED


*--------------------------------------------------------------
*           AND
*--------------------------------------------------------------
AND         CLR.L       D1              ; clear D1
            MOVE.W      (A6),D1         ; move address to D1
            LSR.L       #6,D1           ; bring 6th and 7th bit to front
            AND.B       #$03,D1         ; mask other bits
            CMP.B       #$03,D1         ; 11 = invalid: could be MULS
            BEQ         DATA
            MOVE.W      (A6),D1         ; move address to D1
            BTST        #8,D1           ; test 8th bit
            BNE         AND_CHECK       ; if 0 further check
            
AND_CONFIRM MOVE.B      'A',(A4)+       ; store opcode message in string address
            MOVE.B      'N',(A4)+       
            MOVE.B      'D',(A4)+       
            JMP         OP_SIZE         ; get size of opcode
            JSR         EA_MFIRST       ; get effective addressing modes
            

AND_CHECK   CLR.L       D1              ; clear D1
            MOVE.W      (A6),D1         ; move address to D1
            LSR.L       #4,D1           ; bring 4th and 5th bit to front
            AND.B       #$03,D1         ; mask other bits
            CMP.B       #$0,D1          ; 00 = invalid
            BEQ         DATA
            JMP         AND_CONFIRM     ; confirmed to be AND


*--------------------------------------------------------------
*           NOT
*--------------------------------------------------------------
NOT         MOVE.B      'N',(A4)+       ; store opcode message in string address
            MOVE.B      'O',(A4)+       
            MOVE.B      'T',(A4)+       
            CLR.L       D1              ; clear D1
            MOVE.W      (A6),D1         ; move address to D1
            LSR.L       #6,D1           ; bring 6th and 7th bit to front
            AND.B       #$03,D1         ; mask bits
            CMP.B       #$0,D1          ; 00 = byte
            BEQ         BYTE_SIZE
            CMP.B       #$01,D1         ; 01 = word
            BEQ         WORD_SIZE       
            CMP.B       #$02,D1         ; 10 = long
            BEQ         LONG_SIZE       
            JMP         DATA            ; else size is invalid


*--------------------------------------------------------------
*           LSL
*--------------------------------------------------------------
LSL         CLR.L       D1              ; clear D1
            MOVE.W      (A6),D1         ; move address to D1
            BRA         FINISHED


*--------------------------------------------------------------
*           ASR
*--------------------------------------------------------------
ASR         CLR.L       D1              ; clear D1
            MOVE.W      (A6),D1         ; move address to D1
            BRA         FINISHED


*--------------------------------------------------------------
*           Bcc
*--------------------------------------------------------------
Bcc         BRA         FINISHED


*--------------------------------------------------------------
*           JSR
*--------------------------------------------------------------
JSR         BRA         FINISHED


*--------------------------------------------------------------
*           RTS
*           A6 - the current opcode's address
*           A4 - the current position of the output
*         
*           no operand syntax nor operand size
*--------------------------------------------------------------
RTS     
        
        MOVE.B    'R',(A4)+     *store opcode messge in string address
        MOVE.B    'T',(A4)+     *store opcode messge in string address
        MOVE.B    'S',(A4)+     *store opcode messge in string address
        MOVE.B    #$0A,(A4)+    * add line feed
        MOVE.B    #$0D,(A4)+    * add carriage 
        RTS                     * return

        **************************
        *after all the test code decoded into the address that A4 is pointing to
        *use task 14 to print
        *we need to keep track of where the string started
        *************************
        *MOVE.L    ??????,A1       * load message into A1 for print
        *MOVE.W    #14,D0        *use task 14 to print string in A1
        *TRAP      #15           *run task 14


*--------------------------------------------------------------
*           BRA
*--------------------------------------------------------------
BRA         BRA         FINISHED

*--------------------------------------------------------------
*           DATA (invalid input)
*--------------------------------------------------------------
DATA        MOVE.B      #$44,(A4)+  ; D
            MOVE.B      #$41,(A4)+  ; A
            MOVE.B      #$54,(A4)+  ; T
            MOVE.B      #$41,(A4)+  ; A
            MOVE.B      #$20,(A4)+  ; spaces
            MOVE.B      #$20,(A4)+
            MOVE.B      #$20,(A4)+
            MOVE.B      #$20,(A4)+
            MOVE.B      #$24,(A4)+  ; $
            
            MOVE.W      D5,D1
            MOVEA.W     #$100,A1
            JSR         HEX_ASCII   ; load ascii for data into 100

            MOVE.B      $100,(A4)+
            MOVE.B      $101,(A4)+
            MOVE.B      $102,(A4)+
            MOVE.B      $103,(A4)+  ; print word address
            
            BRA         FINISHED

*--------------------------------------------------------------
*           FINISHED WITH CURRENT OPCODE
*--------------------------------------------------------------
FINISHED    MOVE.B      #$00,(A4)       ; terminate string
            MOVEA.L     #$00000000,A1   ; load into a1 for printing
            MOVEA.L     #$00000000,A4   ; reset a4 for next instruction
            MOVE.B      #14,D0
            TRAP        #15             ; print instruction
            
            ADDQ.B      #1,D6           ; add to counter of lines on screen
            CMPI.B      #10,D6
            BEQ         PRESS_ENTER     ; 10 lines have been printed, ask user to hit enter to continue
                                        ; 10 lines have not been printed, we can print the next line
            
            BRA         FINDOP


PRESS_ENTER LEA         ENTER_MSG,A1
            TRAP        #15
            
            LEA         ENTER_PH,A1
            MOVE.B      #2,D0
            TRAP        #15
            
            MOVE.B      #0,D6           ; reset line counter
            BRA         FINDOP




DONE_OPCODE SIMHALT                 ;   halt simulator

*--------------------------------------------------------------
*           OP_SIZE
*               determine opmode field for the set format:
*                   BYTE    WORD    LONG    OPERATION
*                   000     001     010     <EA> /\ Dn -> Dn
*                   100     101     110     Dn /\ <EA> -> <EA>
*--------------------------------------------------------------
OP_SIZE     MOVE.W      (A6),D1     ; move address to D1
            LSR.L       #6,D1       ; bring 6th and 7th bit to front
            AND.B       #$07,D1     ; mask other bits
            CMP.B       #$0,D1      ; 000 = byte
            BEQ         BYTE_SIZE
            CMP.B       #$4,D1      ; 100 = byte
            BEQ         BYTE_SIZE
            
            CMP.B       #$1,D1      ; 001 = word
            BEQ         WORD_SIZE 
            CMP.B       #$5,D1      ; 101 = word
            BEQ         WORD_SIZE
            
            CMP.B       #$2,D1      ; 010 = long
            BEQ         LONG_SIZE
            CMP.B       #$6,D1      ; 110 = long
            BEQ         LONG_SIZE
            JMP         DATA        ; else size is invalid 
            

*--------------------------------------------------------------
*           DECODE EFFECTIVE ADDRESS
*               6 bits in the form MMMRRR where M are the mode
*               bits and R are the register bits stored in D1
*--------------------------------------------------------------
EA_MFIRST   MOVE.B      D1,D2   ; save register data

            LSL.W       #7,D1
            LSL.W       #3,D1   ; shift unnecessary bits out
            LSL.W       #7,D2
            LSL.W       #6,D2
            
            LSR.W       #7,D1
            LSR.W       #6,D1   ; left with just 3 mode bits in D1
            LSR.W       #7,D2   ; left with just 3 reg bits in D2
            LSL.W       #6,D2
            
            CMPI.B      #%000,D1
            BEQ         DN
            
            CMPI.B      #%001,D1
            BEQ         AN
            
            CMPI.B      #%010,D1
            BEQ         AN_ID
            
            CMPI.B      #%011,D1
            BEQ         AN_POST
            
            CMPI.B      #%100,D1
            BEQ         AN_PRE
            
            CMPI.B      #%111,D1
            BNE         DATA        ; if the mode is anything else it's not valid
            
            LSR.W       #1,D2       ; need to check register for direct addressing
            BCS         DIR_LONG    ; long addressing if reg = XX1
            LSR.W       #2,D2
            BCC         DIR_WORD    ; word addressing if reg = 0X0
            BCS         IMM         ; immediate if reg = 1X0
            
            
DONE_EA     RTS
            
*--------------------------------------------------------------
*           PRINT VARIOUS SIZES
*--------------------------------------------------------------    
            
BYTE_SIZE   MOVE.B      '.',(A4)+
            MOVE.B      'B',(A4)+
            RTS

WORD_SIZE   MOVE.B      '.',(A4)+
            MOVE.B      'W',(A4)+
            RTS

LONG_SIZE   MOVE.B      '.',(A4)+
            MOVE.B      'L',(A4)+
            RTS
            

*--------------------------------------------------------------
*           PRINT VARIOUS EA
*--------------------------------------------------------------
DN          MOVE.B      'D',(A4)+
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            
            BRA         DONE_EA

AN          MOVE.B      'A',(A4)+
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number

            BRA         DONE_EA

AN_ID       MOVE.B      #40,(A4)+       ; ( doesn't work for some reason?
            MOVE.B      'A',(A4)+
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            MOVE.B      ')',(A4)+

            BRA         DONE_EA


AN_POST     MOVE.B      #40,(A4)+       ; ( doesn't work for some reason?
            MOVE.B      'A',(A4)+
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            MOVE.B      ')',(A4)+
            MOVE.B      '+',(A4)+

            BRA         DONE_EA


AN_PRE      MOVE.B      '-',(A4)+
            MOVE.B      #40,(A4)+       ; ( doesn't work for some reason?
            MOVE.B      'A',(A4)+
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            MOVE.B      ')',(A4)+

            BRA         DONE_EA
            
IMM         *todo

DIR_WORD    *todo

DIR_LONG    *todo

*--------------------------------------------------------------
*           HEX->ASCII FOR ITEM IN D1, STORE IN (A1)
*           ONE WORD AT A TIME
*--------------------------------------------------------------
HEX_ASCII   ADDA.L      #4,A1       ; will go backwards with pre-decrement

            MOVE.B      D1,D2       ; last byte
            LSL.W       #4,D2
            LSR.B       #4,D2       ; move first 4 bits out of vision [xxxx aaaa 0000 bbbb]
            
            CMPI.B      #$A,D2
            BLT         HEXNUM
            ADDQ.B      #7,D2
            
HEXNUM      ADDI.B      #$30,D2     ; last part in ascii in d2
            MOVE.B      D2,-(A1)    ; move to a1+3
            
            LSR.W       #4,D2
            LSR.B       #4,D2       ; move next byte into vision
            
            CMPI.B      #$A,D2
            BLT         HEXNUM2
            ADDQ.B      #7,D2
            
HEXNUM2     ADDI.B      #$30,D2     ; first part in ascii in d2
            MOVE.B      D2,-(A1)    ; move to a1+2
            
            ; repeat for first byte
            LSR.W       #8,D1
            MOVE.B      D1,D2       ; first byte
            LSL.W       #4,D2
            LSR.B       #4,D2       ; move first 4 bits out of vision [xxxx aaaa 0000 bbbb]
            
            CMPI.B      #$A,D2
            BLT         HEXNUM3
            ADDQ.B      #7,D2
            
HEXNUM3     ADDI.B      #$30,D2     ; last part in ascii in d2
            MOVE.B      D2,-(A1)    ; move to a1+1
            
            LSR.W       #4,D2
            LSR.B       #4,D2       ; move next byte into vision
            
            CMPI.B      #$A,D2
            BLT         HEXNUM4
            ADDQ.B      #7,D2
            
HEXNUM4     ADDI.B      #$30,D2     ; first part in ascii in d2
            MOVE.B      D2,-(A1)     ; move to a1
            
            ; result: d1 is now in ascii at (a1)
            
            RTS

            

           
            

WLC         DC.B        'Welcome to Team Terminal''s disassembler!',CR,LF,0
SADDR       DC.B        CR,LF,'Please enter your starting address in hexadecimal below. Don''t include 0x or $,',CR,LF,'and make sure to include all 8 digits.',CR,LF,0
EADDR       DC.B        CR,LF,'Please enter your ending address in hexadecimal below. Don''t include 0x or $,',CR,LF,'and make sure to include all 8 digits.',CR,LF,0
INVALID     DC.B        'Please enter a valid address.',CR,LF,CR,LF,0
CRLF        DC.B        CR,LF,0
ENTER_MSG   DC.B        CR,LF,'Press enter to print 10 more lines',CR,LF,0

ENTER_PH    DC.B        1   ; placeholder for hitting enter

            END         START










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
