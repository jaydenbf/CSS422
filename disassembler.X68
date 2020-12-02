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
*                       starting address    - $7000
*                       ending address      - $7010
*--------------------------------------------------------------


            MOVE.L      #$6000,A1
            MOVE.L      #$5000,A2
            MOVE.B      #0,D7       ;   used many times as a counter for loops

            LEA         WLC,A1
            MOVE.B      #14,D0
            TRAP        #15         ;   print welcome message


RESTART     LEA         SADDR,A1
            MOVE.B      #14,D0
            TRAP        #15         ;   ask for starting address
            
            MOVE.B      #2,D0
            TRAP        #15         ;   read number from keyboard into $6000
            
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

FSADDR      CMPI.B      #$FF,$5017
            BNE         FEADDR

            LEA         EADDR,A1
            MOVE.B      #14,D0
            TRAP        #15         ;   ask for ending address
            
            MOVEA.L     #$6000,A1
            MOVEA.L     #$5010,A2
            MOVE.B      #0,D7
            
            MOVE.B      #2,D0
            TRAP        #15         ;   read number from keyboard into $6000
            
            BRA         DECODE

FEADDR      MOVE.B      #0,D7
            MOVE.L      #$00000000,D1   ; clear d1
            MOVEA.L     #$5000,A1
            
COMB        MOVE.B      (A1)+,D2
            ASL.L       #4,D1
            ADD.L       D2,D1
           
            ADDI.B      #1,D7
            CMPI.B      #8,D7           ; check counter
            BEQ         FSCOMB
            BNE         COMB
            
FSCOMB      CMPI.B      #$FF,$7000
            BNE         FECOMB
            MOVEA.L     #$5010,A1
            MOVEA.L     #$7000,A2
            MOVE.L      D1,(A2)         ; load the start address hex number into $7000
            MOVEA.L     #$5010,A1
            MOVE.L      #$00000000,D1   ; clear d1
            MOVE.L      #$00000000,D2   ; clear d2
            MOVE.B      #0,D7           ; reset counter
            BRA         COMB            ; repeat for ending address
            
FECOMB      MOVEA.L     #$7010,A2
            MOVE.L      D1,(A2)         ; move ending address into 6000
            
*--------------------------------------------------------------
*           FIND OPCODE
*--------------------------------------------------------------

            MOVEA.L     $7000,A6        ; will use a6 as the current address
            *JSR         ATEND
            
            MOVE.L      #$00000000,D1
            MOVE.W      (A6),D1
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
NOP         LEA         NOPMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED

*--------------------------------------------------------------
*           MOVE
*--------------------------------------------------------------
MOVE        LEA         MOVEMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           MOVEM
*--------------------------------------------------------------
MOVEM       LEA         MOVEMMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           ADD
*--------------------------------------------------------------
ADD         LEA         ADDMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           SUB
*--------------------------------------------------------------
SUB         LEA         SUBMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           MULS
*--------------------------------------------------------------
MULS        LEA         MULSMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           LEA
*--------------------------------------------------------------
LEA         LEA         LEAMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           AND
*--------------------------------------------------------------
AND         LEA         ANDMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           NOT
*--------------------------------------------------------------
NOT         LEA         NOTMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           LSL
*--------------------------------------------------------------
LSL         LEA         LSLMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           ASR
*--------------------------------------------------------------
ASR         LEA         ASRMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           Bcc
*--------------------------------------------------------------
Bcc         LEA         BGEMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           JSR
*--------------------------------------------------------------
JSR         LEA         JSRMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           RTS
*--------------------------------------------------------------
RTS         LEA         RTSMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           BRA
*--------------------------------------------------------------
BRA         LEA         NOPMSG,A1
            MOVE.B      #14,D0
            TRAP        #15
            BRA         FINISHED


*--------------------------------------------------------------
*           FINISHED
*--------------------------------------------------------------
FINISHED

*--------------------------------------------------------------
*           DECODE EFFECTIVE ADDRESS
*               6 bits in the form MMMRRR where M are the mode
*               bits and R are the register bits stored in D1
*--------------------------------------------------------------
EA          LSL.W       #7,D1
            LSL.W       #3,D1   ; shift unnecessary bits out
            
            LSL.W       #1,D1
            BCC         EA_0
            BCS         EA_1
            BRA         INVALID_EA

EA_0        LSL.W       #1,D1
            BCC         EA_00
            BCS         EA_01
            BRA         INVALID_EA
            
EA_00       LSL.W       #1,D1
            BCC         DN              ; Dn
            BCS         AN              ; An
            BRA         INVALID_EA

EA_01       LSL.W       #1,D1
            BCC         AN_ID           ; (An)
            BCS         AN_POST         ; (An)+
            BRA         INVALID_EA

EA_1        LSL.W       #1,D1
            BCC         AN_PRE          ; -(An)
            BCS         EA_11

EA_11       LSL.W       #2,D1
            BCC         EA_11X1
            BCS         EA_IMM          ; #(data)
            
EA_11X1     LSL.W       #2,D1
            BCC         EA_WORD         ; direct word
            BCS         EA_LONG         ; direct long
            
DONE_EA     RTS
            
*--------------------------------------------------------------
*           PRINT VARIOUS EA
*--------------------------------------------------------------
DN          MOVE.W      D1,D2
            MOVE.B      #'D',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display D for data register
            
            LSR.W       #7,D2
            LSR.W       #6,D2
            MOVE.L      D2,D1
            MOVE.B      #3,D0
            TRAP        #15             ; display the number for the register
            BRA         DONE_EA

AN          MOVE.W      D1,D2
            MOVE.B      #'A',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display A for address register
            
            LSR.W       #7,D2
            LSR.W       #6,D2
            MOVE.L      D2,D1
            MOVE.B      #3,D0
            TRAP        #15             ; display the number for the register
            BRA         DONE_EA

AN_ID       MOVE.W      D1,D2
            MOVE.B      #'(',D1
            MOVE.B      #6,D0
            TRAP        #15
            
            MOVE.W      D1,D2
            MOVE.B      #'A',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display (A
            
            LSR.W       #7,D2
            LSR.W       #6,D2
            MOVE.L      D2,D1
            MOVE.B      #3,D0
            TRAP        #15             ; display the number for the register
            
            MOVE.W      D1,D2
            MOVE.B      #')',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display )
            BRA         DONE_EA


AN_POST     MOVE.W      D1,D2
            MOVE.B      #'(',D1
            MOVE.B      #6,D0
            TRAP        #15
            
            MOVE.W      D1,D2
            MOVE.B      #'A',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display (A
            
            LSR.W       #7,D2
            LSR.W       #6,D2
            MOVE.L      D2,D1
            MOVE.B      #3,D0
            TRAP        #15             ; display the number for the register
            
            MOVE.W      D1,D2
            MOVE.B      #')',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display )
            
            MOVE.W      D1,D2
            MOVE.B      #'+',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display +
            BRA         DONE_EA


AN_PRE      MOVE.W      D1,D2
            MOVE.B      #'-',D1
            MOVE.B      #6,D0
            TRAP        #15
      
            MOVE.W      D1,D2
            MOVE.B      #'(',D1
            MOVE.B      #6,D0
            TRAP        #15
            
            MOVE.W      D1,D2
            MOVE.B      #'A',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display -(A
            
            LSR.W       #7,D2
            LSR.W       #6,D2
            MOVE.L      D2,D1
            MOVE.B      #3,D0
            TRAP        #15             ; display the number for the register
            
            MOVE.W      D1,D2
            MOVE.B      #')',D1
            MOVE.B      #6,D0
            TRAP        #15             ; display )
            BRA         DONE_EA

EA_IMM      *todo

EA_WORD     *todo

EA_LONG     *todo
            

*--------------------------------------------------------------
*           CHECK IF THIS IS THE LAST INSTRUCTION
*--------------------------------------------------------------
ATEND       MOVE.L      $7010,A5
            CMPA.L      A6,A5
            BGT         FINISHED
            RTS
            

            INCLUDE     'strings.x68'
            SIMHALT                 ;   halt simulator

NOPMSG      DC.B        'NOP     ',0
MOVEMSG     DC.B        'MOVE    ',0
MOVEMMSG    DC.B        'MOVEM   ',0
ADDMSG      DC.B        'ADD     ',0
SUBMSG      DC.B        'SUB     ',0
MULSMSG     DC.B        'MULS    ',0
LEAMSG      DC.B        'LEA     ',0
ANDMSG      DC.B        'AND     ',0
NOTMSG      DC.B        'NOT     ',0
LSLMSG      DC.B        'LSL     ',0
ASRMSG      DC.B        'ASR     ',0
BLTMSG      DC.B        'BLT     ',0
BGEMSG      DC.B        'BGE     ',0
BEQMSG      DC.B        'BEQ     ',0
JSRMSG      DC.B        'JSR     ',0
RTSMSG      DC.B        'RTS     ',0
BRAMSG      DC.B        'BRA     ',0


WLC         DC.B        'Welcome to Team Terminal''s disassembler!',CR,LF,0
SADDR       DC.B        'Please enter your starting address: ',0
EADDR       DC.B        'Please enter your ending address: ',0
INVALID     DC.B        'Please enter a valid address.',CR,LF,0

            END         START





*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
