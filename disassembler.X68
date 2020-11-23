*-----------------------------------------------------------
* Title      : Disassembler for CSS 422 Project - Team Terminal
*-----------------------------------------------------------

LF          EQU         $0A
CR          EQU         $0D
            ORG         $1000
START:       

            MOVE.L      #$6000,A1
            MOVE.L      #$5000,A2
            MOVE.B      #0,D7

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
            MOVE.L      #$5010,A2
            MOVE.B      #0,D7
            
            MOVE.B      #2,D0
            TRAP        #15         ;   read number from keyboard into $6000
            
            BRA         DECODE

FEADDR
            INCLUDE     'strings.x68'
            SIMHALT                 ;   halt simulator


WLC         DC.B        'Welcome to Team Terminal''s disassembler!',CR,LF,0
SADDR       DC.B        'Please enter your starting address: ',0
EADDR       DC.B        'Please enter your ending address: ',0
INVALID     DC.B        'Please enter a valid address.',CR,LF,0

            END         START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
