*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:  JSR SUBROUTINE
*-----------------------------------------------------------


*--------------------------------
*JSR_SUB will be added to RTS_SUB.X68
*under RTS_SUB function
*above NOTMACH ad DONEDECODE

JSR_SUB
        MOVE.W    D1,D2        ; move the value into D2 for temp storage
        MOVE.W    #$4E80,D3    ; move values into registers for CMD_CHECK

 
        CMP.W     D3,D2         ;compare test opcode to JSR
        BNE       NOTMATCH     ;return if not match
        
        MOVE.B    #0,D6      ; clear D6        
        JSR       DECODE_JSR
        CMP.B     #1,D6         ; D6 =1 if opcode is valid    
        BEQ       DONEDECODE  ;return to main. otherwise, compare to next opcode subroutine 
        
DECODE_JSR
       
        MOVEA.L   #0,A1             ; clear A1
        MOVEA.L   Curr_Addrs,A1      ; keep track of current opcode address to a1
   

        MOVEA.L   #0,A2         ;clear A2 
        MOVEA.L   Curr_Output_Addrs,A2 ; current output address to a2
        LEA       JSR_RESULT,A3     ; move the to-be-printed string to A3

JSR_COPY
        CMPI.B    #00,(A3)      ; compare 0 to JSR_RESULT
        BEQ       JSR_DES_OPER_Handler  ; deal with the destination operand
        MOVE.B    (A3)+,(A2)+   ; add output string to current output address, then increase by 1
        BRA       JSR_COPY      ; loop until everything is copied
        
JSR_DES_OPER_Handler
*This function will print the destination operand after the JSR Opcode        

        
JSR_FORMATTING
*-------------------------
*1.adding space and 'JSR' to the output address
*then we can use trap to display the ouput
*an example: JSR   (space)  XXXX,XXXXX
*2.update the current address
*3. everything is finished, use RTS to return
*-------------------------

        RTS        
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
