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

            MOVE.L      #$D391D399,$4000
            MOVE.L      #$D3A1D291,$4004

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
            TRAP        #15         ;   read number from keyboard into $600
            
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
            BCS         ADD             ; ADD
          
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
            
            MOVE.B      #$4E,(A4)+      ; N
            MOVE.B      #$4F,(A4)+      ; O
            MOVE.B      #$50,(A4)+      ; P

            BRA         FINISHED

*--------------------------------------------------------------
*           MOVE
*--------------------------------------------------------------
MOVE        MOVE.B #'M',(A4)+
            MOVE.B #'O',(A4)+
            MOVE.B #'V',(A4)+
            MOVE.B #'E',(A4)+     
            CLR.L       D1              ; clear D1
            MOVE.W      D5,D1           ; move address to D1
            LSR.L       #6,D1           ; bring 12th and 13th bit to front for size
            LSR.L       #6,D1
            AND.B       #$03,D1          ; mask bits
            
            CMP.B       #$1,D1          ; 01 = byte
            BNE         MOVE_WORD
            JSR         BYTE_SIZE
            BRA         MOVE_SIZED    
            
MOVE_WORD   CMP.B       #$3,D1         ; 11 = word
            BNE         MOVE_LONG
            JSR         WORD_SIZE
            BRA         MOVE_SIZED       
            
MOVE_LONG   CMP.B       #$2,D1         ; 10 = long
            BNE         DATA
            JSR         LONG_SIZE
            
MOVE_SIZED  MOVE.B      #' ',(A4)+      ; SPACES
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            
            CLR.L       D1              ; clear D1
            MOVE.W      D5,D1           ; move address to D1
            MOVE.W      D5,D1           ; copy to D1 for ea printing
            JSR         EA_MFIRST
            MOVE.B      #',',(A4)+      ; print comma
            
            MOVE.W      D5,D1           ; copy to D1 again
            MOVE.W      D5,D2           ; copy to D2 as well
            
            ANDI.W      #%0000000111000000,D1 ; keep destination mode
            LSR.L       #3,D1           ; bring the destination mode forward
            ANDI.W      #%000011100000000,D2 ; keep destination register
            LSR.L       #3,D2           ; bring the destination register to front
            LSR.L       #6,D2            
            
            ; at this point we have D1 -> 0000000000111000 1s being mode
            ;                       D2 -> 0000000000000111 1s being register
            
            CMPI.B      #%001000,D1     ; check if dest. is An
            BEQ         DATA
            
            CMPI.B      #%111000,D1     ; check if dest. is immediate data
            BNE         MOVE_NOTI
            CMPI.B      #%000100,D2
            BEQ         DATA
            
MOVE_NOTI   ADD.L       D2,D1
            JSR         EA_MFIRST       ; D1 is ready for destination ea print
            
            BRA         FINISHED

*--------------------------------------------------------------
*           MOVEM
*--------------------------------------------------------------
MOVEM       BRA         FINISHED


*--------------------------------------------------------------
*           ADD
*--------------------------------------------------------------
ADD         MOVE.W      D5,D1       ; copy opcode

            ROR.W       #8,D1
            LSR.B       #4,D1
            CMPI.B      #$0D,D1     ; verify first 4 bits are 1101
            BNE         DATA
            
            MOVE.B      #'A',(A4)+  ; A
            MOVE.B      #'D',(A4)+  ; D
            MOVE.B      #'D',(A4)+  ; D
            
ADD_SUB     JSR         OP_SIZE     ; print size of operation
            
            MOVE.B      #' ',(A4)+  ; SPACES
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            
            MOVE.W      D5,D1       ; reset d1 to right opcode

            LSL.W       #7,D1
            LSR.W       #7,D1
            LSR.W       #7,D1       
            LSR.W       #1,D1       ; isolate 8th bit
            
            CMPI.W      #$0000,D1
            BNE         ADDSUB_EA   ; if 8th bit is 1, ea is destination
                                    ; if 8th bit is 0, dn is destination
            
            MOVE.W      D5,D1       ; reset d1 to right opcode
            
            LSL.W       #3,D1
            LSR.W       #3,D1       ; clear opmode from bottom word
            
            JSR         EA_MFIRST   ; decode effective address

            MOVE.B      #',',(A4)+   ; ,
            
            MOVE.W      D5,D1       ; reset d1 to right opcode
            ROR.W       #8,D1
            LSL.B       #4,D1
            LSR.B       #5,D1       ; isolate register (last word is 0000 0RRR)
            
            JSR         EA_MFIRST   ; decode data register

            BRA         FINISHED

ADDSUB_EA   MOVE.W      D5,D1       ; reset d1 to right opcode

            LSR.W       #4,D1
            LSR.W       #5,D1       ; isolate register (last byte is 0000 0RRR)
            AND.B       #$07,D1
            
            JSR         EA_MFIRST   ; decode data register

            MOVE.B      #',',(A4)+   ; ,
            
            MOVE.W      D5,D1       ; reset d1 to right opcode
            
            LSL.W       #3,D1
            LSR.W       #3,D1       ; clear opmode from bottom byte
            
            MOVE.B      D1,D2       ; check for invalid modes
            CMPI.B      #%111100,D2
            BEQ         DATA        ; dest can't be immediate data
            LSR.B       #3,D2
            CMPI.B      #%000,D2    ; dest can't be Dn
            BEQ         DATA
            CMPI.B      #%001,D2    ; dest can't be An
            BEQ         DATA

            JSR         EA_MFIRST   ; decode effective address
            
            BRA         FINISHED

*--------------------------------------------------------------
*           SUB
*--------------------------------------------------------------
SUB         MOVE.W      D5,D1       ; copy opcode

            ROR.W       #8,D1
            LSR.B       #4,D1
            CMPI.B      #$09,D1     ; verify first 4 bits are 1001
            BNE         DATA

            MOVE.B      #'S',(A4)+
            MOVE.B      #'U',(A4)+
            MOVE.B      #'B',(A4)+
            
            BRA         ADD_SUB     ; reuse decoding for add because they are the same


*--------------------------------------------------------------
*           MULS (MULS.L NOT SUPPORTED)
*--------------------------------------------------------------
MULS        MOVE.W      D5,D1       ; copy opcode

            ROR.W       #8,D1
            LSR.B       #4,D1
            CMPI.B      #$0C,D1     ; verify first 4 bits are 1100
            BNE         DATA        ; not MULS
            
            MOVE.B      #'M',(A4)+  ; MULS.W   
            MOVE.B      #'U',(A4)+  
            MOVE.B      #'L',(A4)+   
            MOVE.B      #'S',(A4)+  
            MOVE.B      #'.',(A4)+
            MOVE.B      #'W',(A4)+
            MOVE.B      #' ',(A4)+  ; SPACES
            MOVE.B      #' ',(A4)+
            
            MOVE.W      D5,D1       ; reset D1 opcode
            ANDI.W      #%0000000000111111,D1 ; keep ea only
            JSR         EA_MFIRST   ; print/decode ea
            MOVE.B      #',',(A4)+      ; print comma
            
            MOVE.W      D5,D1       ; reset D1 opcode
            ANDI.W      #%0000111000000000,D1 ; keep destination dr related bits
            ROR.W       #8,D1       ; bring 9th,10th,11th bits to front
            LSR.B       #1,D1
            
            MOVE.B      D1,D2       ; check for invalid modes
            LSR.B       #3,D2
            CMPI.B      #%001,D2    ; dest can't be An
            BEQ         DATA
            
            JSR         EA_MFIRST   ; decode data register
            
            BRA         FINISHED


*--------------------------------------------------------------
*           LEA
*--------------------------------------------------------------
LEA         MOVE.B      #'L',(A4)+
            MOVE.B      #'E',(A4)+
            MOVE.B      #'A',(A4)+ 
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
  
            CLR.L       D1              ; clear D1
            MOVE.W      D5,D1           ; move address to D1
            ANDI.W      #%0000000000111111,D1 ; iso effective address
            
            MOVE.B      D1,D2       ; check for valid modes
            CMPI.B      #%111000,D2
            BEQ         LEA_VALID   ; dest can be direct (word)
            CMPI.B      #%111001,D2
            BEQ         LEA_VALID   ; dest can be direct (long)
            LSR.B       #3,D2
            CMPI.B      #%010,D2    ; dest can be (An)
            BEQ         LEA_VALID
            BRA         DATA        ; any other mode is invalid
            
LEA_VALID   JSR         EA_MFIRST       ; print ea
            
            MOVE.B      #',',(A4)+
            
            CLR.L       D1              ; clear D1
            MOVE.W      D5,D1           ; copy opcode
            ANDI.W      #%0000111000000000,D1 ; iso data register
            LSR.L       #6,D1           ; move register to front
            LSR.L       #3,D1
            
            ADD.L       #%1000,D1       ; sets ea mode to 001 (An)
            JSR         EA_MFIRST       ; print/decode address register
            
            BRA         FINISHED


*--------------------------------------------------------------
*           AND
*--------------------------------------------------------------
AND         MOVE.W      D5,D1       ; copy opcode

            ROR.W       #8,D1
            LSR.B       #4,D1
            CMPI.B      #$0C,D1     ; verify first 4 bits are 1100
            BNE         DATA
            
            MOVE.B      #'A',(A4)+  ; A
            MOVE.B      #'N',(A4)+  ; N
            MOVE.B      #'D',(A4)+  ; D
            
            BRA         ADD_SUB     ; reuse decoding for add because they are the same
            

*--------------------------------------------------------------
*           NOT
*--------------------------------------------------------------
NOT         MOVE.B      #$4E,(A4)+      ; N
            MOVE.B      #$4F,(A4)+      ; O
            MOVE.B      #$54,(A4)+      ; T
            CLR.L       D1              ; clear D1
            MOVE.W      D5,D1           ; move address to D1
            LSR.L       #6,D1           ; bring 6th and 7th bit to front
            AND.B       #$03,D1         ; mask bits
            
            CMP.B       #$0,D1          ; 00 = byte
            BEQ         BYTE_SIZE
            CMP.B       #$01,D1         ; 01 = word
            BEQ         WORD_SIZE       
            CMP.B       #$02,D1         ; 10 = long
            BEQ         LONG_SIZE 
            CMP.B       #$03,D1         ; 11 = invalid      
            BEQ         DATA
            
            MOVE.B      #$20,(A4)+      ; SPACES
            MOVE.B      #$20,(A4)+
            MOVE.B      #$20,(A4)+
            
            JSR         EA_MFIRST       ; decode effective address
            
            BRA         FINISHED


*--------------------------------------------------------------
*           LSL
*--------------------------------------------------------------
LSL         MOVE.W      D5,D1
            ANDI.W      #%1111000000011000,D1
            CMPI.W      #%1110000000001000,D1
            BNE         DATA

            MOVE.B      #$4C,(A4)+      ; L
            MOVE.B      #$53,(A4)+      ; S
            MOVE.B      #$4C,(A4)+      ; L
            CLR.L       D1              ; clear D1
            MOVE.W      D5,D1         ; move address to D1
            BTST        #8,D1           ; test 8th bit
            BEQ         DATA            ; if 0, this is LSR, unsupported
            
            MOVE.B      #$20,(A4)+      ; SPACES
            MOVE.B      #$20,(A4)+
            MOVE.B      #$20,(A4)+
            
            JSR         EA_MFIRST       ; decode effective address
            
            BRA         FINISHED


*--------------------------------------------------------------
*           ASR
*--------------------------------------------------------------
ASR         MOVE.W      D5,D1
            ANDI.W      #%1111000000011000,D1
            CMPI.W      #%1111000000000000,D1
            BNE         DATA

            MOVE.B      #$41,(A4)+      ; A
            MOVE.B      #$53,(A4)+      ; S
            MOVE.B      #$52,(A4)+      ; R
            CLR.L       D1              ; clear D1
            MOVE.W      (A6),D1         ; move address to D1
            BTST        #8,D1           ; test 8th bit
            BNE         DATA            ; if 1, this is ASL, unsupported
            
            MOVE.B      #$20,(A4)+      ; SPACES
            MOVE.B      #$20,(A4)+
            MOVE.B      #$20,(A4)+
            
            JSR         EA_MFIRST       ; decode effective address
            
            BRA         FINISHED


*--------------------------------------------------------------
*           Bcc (only BLT BGE BEQ)
*--------------------------------------------------------------
Bcc         MOVE.W      D5,D1
            ROL.W       #4,D1
            AND.B       #$0F,D1         ; isolate first 4 bits
            CMPI.B      #$06,D1         ; confirm first four bits are 0110 for Bcc
            BNE         DATA

            ROL.W       #4,D1
            AND.B       #$0F,D1         ; isolate condition bits

            CMPI.B      #%0111,D1            
            BEQ         BEQ             ; BEQ
            
            CMPI.B      #%1101,D1
            BEQ         BLT             ; BLT
            
            CMPI.B      #%1100,D1
            BEQ         BGE             ; BGE
            
            BRA         DATA            ; not a supported condition
            
BEQ         MOVE.B      #'B',(A4)+
            MOVE.B      #'E',(A4)+
            MOVE.B      #'Q',(A4)+
         
            MOVE.W      D5,D1
            JSR         BCC_SIZE
            
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
                        
            MOVE.W      D5,D1
            ROR.W       #8,D1
            
            BRA         OR_BCC          ; uses branch from here on out, identical to decode

BLT         MOVE.B      #'B',(A4)+
            MOVE.B      #'L',(A4)+
            MOVE.B      #'T',(A4)+
            
            MOVE.W      D5,D1
            JSR         BCC_SIZE
            
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
                        
            MOVE.W      D5,D1
            ROR.W       #8,D1
            
            BRA         OR_BCC          ; uses branch from here on out, identical to decode
            
BGE         MOVE.B      #'B',(A4)+
            MOVE.B      #'G',(A4)+
            MOVE.B      #'E',(A4)+
         
            MOVE.W      D5,D1
            JSR         BCC_SIZE
            
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            
            MOVE.W      D5,D1
            ROR.W       #8,D1
            
            BRA         OR_BCC          ; uses branch from here on out, identical to decode
            
            
BCC_SIZE    CMPI.B      #$00,D1
            BEQ         BCC_16
            
            CMPI.B      #$FF,D1
            BEQ         BCC_32
            
            MOVE.B      #'.',(A4)+
            MOVE.B      #'B',(A4)+
            RTS
            
BCC_16      MOVE.B      #'.',(A4)+
            MOVE.B      #'W',(A4)+
            RTS
            
BCC_32      MOVE.B      #'.',(A4)+
            MOVE.B      #'L',(A4)+
            RTS

*--------------------------------------------------------------
*           JSR
*--------------------------------------------------------------
JSR     CLR.L   D3
        MOVE.W  D5,D3
        LSR.L   #6,D3
        CMPI.W  #$13A, D3
        BNE     DATA
        MOVE.B     #'J',(A4)+          *4A -- J
        MOVE.B     #'S',(A4)+          *53  -- S   
        MOVE.B     #'R',(A4)+          *52   --R
        MOVE.B     #' ',(A4)+
        MOVE.B     #' ',(A4)+
        MOVE.B     #' ',(A4)+
        MOVE.B     #' ',(A4)+
        MOVE.B     #' ',(A4)+           
        ANDI.W      #%0000000000111000,D3

        LSR.L       #6,D1           ; move register to front
        LSR.L       #3,D1
        ADD.L       #%0000,D1


        MOVE.B      D1,D2       ; check for valid modes
        CMPI.B      #%111000,D2
        BEQ         DATA        ; dest can be direct (word)
        CMPI.B      #%111001,D2
        BEQ         DATA        ; dest can be direct (long)
        LSR.B       #3,D2
        CMPI.B      #%010,D2    ; dest can be (An)
        BEQ         DATA
       
        JSR         EA_MFIRST                           
        BRA         FINISHED



*--------------------------------------------------------------
*           RTS
*           A6 - the current opcode's address
*           A4 - the current position of the output
*         
*           no operand syntax nor operand size
*--------------------------------------------------------------
RTS     
        CMPI.W      #$4E75,D5
        BNE         DATA
        MOVE.B      #'R',(A4)+
        MOVE.B      #'T',(A4)+ 
        MOVE.B      #'S',(A4)+
        BRA         FINISHED



*--------------------------------------------------------------
*           BRA
*--------------------------------------------------------------
BRA         CLR.L       D1
            MOVE.W      D5,D1       ; reset opcode
            ROR.W       #8,D1       ; get last byte to front
            CMPI.B      #$60,D1     ; make sure its 01100000
            BNE         DATA        ; not bra
            
            MOVE.B      #'B',(A4)+
            MOVE.B      #'R',(A4)+
            MOVE.B      #'A',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            
OR_BCC      MOVE.L      A6,D2       ; address of the next instruction
                                    ; is the address of this instruction plus 2
                                    ; which is the program counter
            
            ROR.W       #8,D1       ; move first byte to front
            CMPI.B      #$00,D1     ; check if it's $00
            BEQ         BRA_16      ; 16-bit displacement
            CMPI.B      #$FF,D1     ; check if it's $FF
            BEQ         BRA_32      ; 32-bit displacement
                                    ; 8-bit displacement otherwise
            
            ; 8-bit displacement: no extention                   
            AND.W       #$00FF,D1   ; isolate last 8 bits (displacement)
            ADD.B       D1,D2       ; add displacement to pc
            MOVE.W      D2,D1       ; now have bra address in d1
            MOVE.B      #'$',(A4)+
            
            MOVEA.L     #$100,A1                        
            JSR         HEX_ASCII
            
            MOVE.B      $100,(A4)+
            MOVE.B      $101,(A4)+
            MOVE.B      $102,(A4)+
            MOVE.B      $103,(A4)+  ; print out the long
            
            BRA         FINISHED
            
BRA_16      ; 16-bit displacement: word extention
            CLR.L       D1
            MOVE.W      (A6),D1     ; get next word
            ADDA.L      #2,A6       ; increment current address
            
            ADD.W       D2,D1       ; add program counter to displacement
                                    ; now have bra address in d1
            
            MOVE.B      #'$',(A4)+
                        
            MOVEA.L     #$100,A1                        
            JSR         HEX_ASCII
            
            MOVE.B      $100,(A4)+
            MOVE.B      $101,(A4)+
            MOVE.B      $102,(A4)+
            MOVE.B      $103,(A4)+  ; print out the word
            
            BRA         FINISHED
            
BRA_32      ; 32-bit displacement: long extention
            MOVE.L      (A6),D1     ; get next long
            ADDA.L      #4,A6       ; increment current address
            
            ADD.L       D2,D1       ; add program counter to displacement
                                    ; now have bra address in d1
            MOVE.B      #'$',(A4)+                        
            
            MOVEA.L     #$100,A1                        
            SWAP        D1
            JSR         HEX_ASCII
            
            MOVEA.L     #$104,A1
            SWAP        D1
            JSR         HEX_ASCII
            
            MOVE.B      $100,(A4)+
            MOVE.B      $101,(A4)+
            MOVE.B      $102,(A4)+
            MOVE.B      $103,(A4)+
            MOVE.B      $104,(A4)+
            MOVE.B      $105,(A4)+
            MOVE.B      $106,(A4)+
            MOVE.B      $107,(A4)+  ; print out the long
            
            BRA         FINISHED

*--------------------------------------------------------------
*           DATA (invalid input)
*--------------------------------------------------------------
DATA        MOVEA.L     #$00000008,A4
            MOVE.B      #' ',(A4)+  ; spaces
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #'D',(A4)+  ; D
            MOVE.B      #'A',(A4)+  ; A
            MOVE.B      #'T',(A4)+  ; T
            MOVE.B      #'A',(A4)+  ; A
            MOVE.B      #' ',(A4)+  ; spaces
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #' ',(A4)+
            MOVE.B      #'$',(A4)+  ; $
            
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
OP_SIZE     MOVE.W      D5,D1     ; move address to D1
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
            BRA         DATA        ; else size is invalid 

*--------------------------------------------------------------
*           DECODE EFFECTIVE ADDRESS
*               6 bits in the form MMMRRR where M are the mode
*               bits and R are the register bits stored in D1
*--------------------------------------------------------------
EA_MFIRST   MOVE.B      D1,D2   ; save register data

            LSL.B       #2,D1
            LSL.B       #5,D2

            LSR.B       #5,D1   ;left with just 3 mode bits in D1
            LSR.B       #5,D2   ; left with just 3 reg bits in D2
            
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
            
BYTE_SIZE   MOVE.B      #$2E,(A4)+  ; .
            MOVE.B      #$42,(A4)+  ; B
            RTS

WORD_SIZE   MOVE.B      #$2E,(A4)+  ; .
            MOVE.B      #$57,(A4)+  ; W
            RTS

LONG_SIZE   MOVE.B      #$2E,(A4)+  ; .
            MOVE.B      #$4C,(A4)+  ; L
            RTS
            

*--------------------------------------------------------------
*           PRINT VARIOUS EA
*--------------------------------------------------------------
DN          MOVE.B      #$44,(A4)+
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            
            BRA         DONE_EA

AN          MOVE.B      #$41,(A4)+       ; A
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number

            BRA         DONE_EA

AN_ID       MOVE.B      #40,(A4)+       ; ( doesn't work for some reason?
            MOVE.B      #$41,(A4)+       ; A
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            MOVE.B      #$29,(A4)+       ; )

            BRA         DONE_EA


AN_POST     MOVE.B      #40,(A4)+       ; ( doesn't work for some reason?
            MOVE.B      #$41,(A4)+       ; A
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            MOVE.B      #$29,(A4)+       ; )
            MOVE.B      #$2B,(A4)+       ; +

            BRA         DONE_EA


AN_PRE      MOVE.B      #$2D,(A4)+       ; -
            MOVE.B      #$28,(A4)+       ; (
            MOVE.B      #$41,(A4)+       ; A
            ADDI.B      #48,D2
            MOVE.B      D2,(A4)+        ; d2 to ascii number
            MOVE.B      #$29,(A4)+       ; )

            BRA         DONE_EA
            
IMM         ; if it's immediate we need to find the size
            MOVEA.L     #$00000000,A1
CHECK_PD    CMPI.B      #'.',(A1)+  ; find period in the current printed opcode
            BNE         CHECK_PD
            ADDA.L      #1,A1       ; we now have B W or L in (A1)

            CMPI.B      #'L',(A1)   
            BEQ         IMM_LONG    ; if it's L we need to pull the next long
                                    ; if it's B or W we need to pull the next word
                                    
            ; word (or byte but they both use a word)
            CLR.L        D1
            MOVE.W      (A6),D1     ; pull next word
            ADDA.L      #2,A6       ; move past the word
            
            MOVE.B      #'#',(A4)+  ; data is immediate
            MOVE.B      #'$',(A4)+  ; data is in hex
            
            MOVEA.L     #$100,A1
            JSR         HEX_ASCII   ; convert immediate data (d1) into ascii
            
            MOVEA.L     #$100,A1
            MOVE.B      (A1)+,(A4)+ ; print the word data $100-$103
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            
            BRA         DONE_EA
            
IMM_LONG    MOVE.L      (A6),D1     ; pull next long
            ADDA.L      #4,A6       ; move past the long
            
            MOVE.B      #'#',(A4)+  ; data is immediate
            MOVE.B      #'$',(A4)+  ; data is in hex
            
            MOVEA.L     #$100,A1
            SWAP        D1
            JSR         HEX_ASCII   ; convert upper word into ascii at $100-$103
            
            ADDA.L      #2,A1
            SWAP        D1
            JSR         HEX_ASCII   ; conver lower word into ascii at $104-$107
            
            MOVEA.L     #$100,A1
            MOVE.B      (A1)+,(A4)+ ; print the long data $100-$107
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            
            BRA         DONE_EA

DIR_WORD    MOVE.B      #'$',(A4)+  ; address is in hex

            CLR.L       D1
            MOVE.W      (A6),D1     ; pull next word
            ADDA.L      #2,A6       ; move past the word
            
            MOVEA.L     #$100,A1
            JSR         HEX_ASCII   ; convert D1 into ascii at $100-$103
            
            MOVEA.L     #$100,A1
            MOVE.B      (A1)+,(A4)+ ; print the word address $100-$103
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            
            BRA         DONE_EA

DIR_LONG    MOVE.B      #'$',(A4)+  ; address is in hex

            CLR.L       D1
            MOVE.L      (A6),D1     ; pull next long
            ADDA.L      #4,A6       ; move past the long
            
            MOVEA.L     #$100,A1
            SWAP        D1
            JSR         HEX_ASCII   ; convert upper word into ascii at $100-$103
            
            ADDA.L      #4,A1
            SWAP        D1
            JSR         HEX_ASCII   ; convert lower word into ascii at $104-$107
            
            MOVEA.L     #$100,A1
            MOVE.B      (A1)+,(A4)+ ; print the long address $100-$107
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            MOVE.B      (A1)+,(A4)+
            
            BRA         DONE_EA

*--------------------------------------------------------------
*           HEX->ASCII FOR ITEM IN D1, STORE IN (A1)
*           ONE WORD AT A TIME
*--------------------------------------------------------------
HEX_ASCII   MOVE.W      D1,-(SP)
            ADDA.L      #4,A1       ; will go backwards with pre-decrement

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
            MOVE.W      (SP)+,D1    ; ensure d1 gets reset (should with jsr)
            RTS

            

           
            

WLC         DC.B        'Welcome to Team Terminal''s disassembler!',CR,LF,0
SADDR       DC.B        CR,LF,'Please enter your even starting address in hexadecimal below. Don''t include 0x or $,',CR,LF,'and make sure to include all 8 digits.',CR,LF,0
EADDR       DC.B        CR,LF,'Please enter your even ending address in hexadecimal below. Don''t include 0x or $,',CR,LF,'and make sure to include all 8 digits.',CR,LF,0
INVALID     DC.B        'Please enter a valid address.',CR,LF,CR,LF,0
CRLF        DC.B        CR,LF,0
ENTER_MSG   DC.B        CR,LF,'Press enter to print 10 more lines',CR,LF,0

ENTER_PH    DC.B        1   ; placeholder for hitting enter

            END         START





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
