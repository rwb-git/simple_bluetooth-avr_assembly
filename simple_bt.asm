; 8-10-2019
;
;   simple_bt derived from rgb2019.asm which was not responding to app rgb12 

.include "m328def.inc"

.cseg

.org $0000
	jmp RESET      ;Reset handle
	
;---------------------

init_wdr:  ;init_watchdog:

   cli

   wdr

   lds r16,wdtcsr

   ori r16, (1<<wdce | 1<<wde)

   sts wdtcsr, r16

   ldi r16, (1<<wde | 1<<wdp2 | 1<<wdp0 | 1<<wdp1)

                                       ;  wdp3     wdp2     wdp1     wdp0     timeout
                                       ;  0        1        0        1        0.5 seconds
                                       ;  0        0        0        0        0.016 seconds = default
                                       ;  0        1        1        1        2 sec
   sts wdtcsr, r16

   sei

   ret

;------------------------------

get_uart_byte:                         ; uses r21. either timesout and resets avr or returns byte in r21

   lds r21,ucsr0a    
   sbrs r21,rxc0
   rjmp get_uart_byte                  ; THIS WILL watchdog reset if nothing is received

   lds r21,UDR0

   ret

;-------------------------------------

uart_send1:                            ; send byte in r21; uses r16  
   
   lds r16,ucsr0a 
   sbrs r16,udre0
   rjmp uart_send1

   sts udr0,r21

   ret

;----------------------
 
btcode42:

   ldi r21,0x57                        ; dummy ack code for app msg 0x26; handled in BluetoothChatService handle_0x57
   rcall uart_send1

   clr r17


   ; ---------------- this block causes a failure every other time 0x42 is received, to see how well the app recovers 
   cpi r18,1
   
   brne line72
   
   ldi r18,0

   rjmp line73

line72:

   ldi r17,7                           ; send 7 fewer bytes than app expects

   ldi r18,1

line73:

   ; ----------- end of forced error block ---------------------------



l4oop1258:

   mov r21,r17                         ; sends 00 01 02 .. FF

   rcall uart_send1                    ; uses r16 r21

   inc r17
   brne l4oop1258

   ret

;-------------------------
   
check_for_byte:

   lds r16,ucsr0a
   sbrs r16,rxc0
   ret

   lds r21,UDR0

   cpi r21,0x42

   breq btcode42

   ret

;-------------------

init_uart1: 

   ldi r16,25                          ; 103 for 16mhz and 9600; 16 57k;  25 38400;  

   sts ubrr0l,r16                      ; 2560 pdf pg 222 and 226

   ldi r16,0b00000110                  ; 8 bits    no parity      1 STOP Bit
   sts ucsr0c,r16                      ; 2560 pdf pg 221

   ldi r16,0b00011000                  ; rxwn = txen = 1
   sts ucsr0b,r16                      ; 2560 pdf pg 220

   ret

;-------------------------

RESET:
	ldi	r16,high(RAMEND) 
	out	SPH,r16	         
	ldi	r16,low(RAMEND)	 
	out	SPL,r16

   rcall init_wdr

   rcall init_uart1

main_loop:  ;--------------------------------------------------------------------------------------------------------

   wdr

   rcall check_for_byte
  
   rjmp	main_loop

