lf          equ         $0A
cr          equ         $0D

start       org         $1000

            move.l      #$6000,a1
            move.l      #$5000,a2
            move.b      #0,d7

            lea         wlc,a1
            move.b      #14,d0
            trap        #15         ;   print welcome message


restart     lea         saddr,a1
            move.b      #14,d0
            trap        #15         ;   ask for starting address
            
            move.b      #2,d0
            trap        #15         ;   read number from keyboard into $6000
            
decode      move.b      (a1)+,d1
            cmpi.b      #$30,d1     ;   is d1 < 30
            blt.b       inv         ;   then invalid
            cmp.b       #$39,d1     ;   is d1 <= 39
            ble.b       noltr       ;   if so, it's not a letter (so branch)
        
            cmpi.b      #$41,d1     ;   is d1 < 41
            blt.b       inv         ;   then invalid
            cmpi.b      #$46,d1     ;   is d1 > 46
            bgt.b       inv         ;   then invalid
            subi.b      #$37,d1     ;   subtract 37 from d1
            bra         ltr         ;   finished with this letter

noltr       subi.b      #$30,d1     ;   if it's a number subtract 30

ltr         move.b      d1,(a2)+    ;   throw byte into $5000s
            addi.b      #1,d7
            cmpi.b      #8,d7
            beq         fsaddr      ;   finished decoding
            bra         decode      ;   repeat for all 8 times

inv         lea         invalid,a1
            move.b      #14,d0
            trap        #15
            bra         restart

fsaddr      cmpi.b      #$FF,$5017
            bne         feaddr

            lea         eaddr,a1
            move.b      #14,d0
            trap        #15         ;   ask for ending address
            
            movea.l     #$6000,a1
            move.l      #$5010,a2
            move.b      #0,d7
            
            move.b      #2,d0
            trap        #15         ;   read number from keyboard into $6000
            
            bra         decode

feaddr

            move.b      #9,d0
            trap        #15         ;   halts simulator


wlc         dc.b        'Welcome to Team Terminal''s disassembler!',cr,lf,0
saddr       dc.b        'Please enter your starting address: ',0
eaddr       dc.b        'Please enter your ending address: ',0
invalid     dc.b        'Please enter a valid address.',cr,lf,0

            end         start
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
