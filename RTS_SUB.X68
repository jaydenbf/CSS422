*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:   subroutine for decoding RTS
*-----------------------------------------------------------

RTS_SUB

*-----------------------------------------
* do some operations first(for loop memeroy region)        
* read the test opcode into D1 
* backup of D1 stores in D2
* RTS opcode stores in D3  ($4e75)
* the test opcode address stores into A3
* need a variable to keep track of our current address: Curr_Addrs
* need a variable to keep track of our current output address: Curr_Output_Addrs
* need a variable to store the output and be prepared to show on the display window: RTS_RESULT
*-------------------------------------------   
        * check RTS
        MOVE.W    D1,D2        ; move the value into D2 for temp storage
        MOVE.W    #$4e75,D3    ; RTS code in HEX   store in D3
       
        
        CMP.W     D3,D2         ;compare test opcode to RTS
        BNE       NOTMATCH     ;return if not match
        
        MOVE.B    #0,D6      ; clear D6
        JSR       DECODE_RTS
        CMP.B     #1,D6         ; D6 =1 if opcode is valid    
        BEQ       DONEDECODE  ;return to main. otherwise, compare to next opcode subroutine 
        
        
        
NOTMATCH  
*need more operations to keep the previous data in stack  
        RTS        

DONEDECODE
        RTS        
        
        
        
DECODE_RTS
       
        MOVEA.L   #0,A1             ; clear A1
        MOVEA.L   Curr_Addrs,A1      ; keep track of current opcode address to a1
   

        MOVEA.L   #0,A2         ;clear A2 
        MOVEA.L   Curr_Output_Addrs,A2 ; current output address to a2
        LEA       RTS_RESULT,A3     ; move the to-be-printed string to A3

 
RTS_COPY
        CMPI.B    #00,(A3)      ; compare 0 to RTS_RESULT
        BEQ       OUTPUT_FORMATTING  ; branch to formatting if we have copied all of the data
        MOVE.B    (A3)+,(A2)+   ; add output string to current output address, then increase by 1
        BRA       RTS_COPY      ; loop until everything is copied
        
OUTPUT_FORMATTING
*-------------------------
*1.adding space and 'RTS' to the output address
*then we can use trap to display the ouput
*an example: RTS   (space)  XXXX,XXXXX
*2.update the current address
*3. everything is finished, use RTS to return
*-------------------------

        RTS       




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
