;PORT MAPPING
;LCD ada di port a (RS, RW, EN) dan port B sisanya
;LED ada di port C
;buttons ada di port D

.include "m8515def.inc"

.def tmp=r16
.def arg_1=r24
.def arg_2=r25

.org $00
rjmp main

main:
	;init stack
	ldi tmp, low(RAMEND)
	out SPL, tmp
	ldi tmp, high(RAMEND)
	out SPH, tmp
	
	;init lcd
	rcall lcd_init
	;clar lcd
	rcall lcd_clear
	
	
	ldi arg_1, low(msg_welcome_row1*2)
	ldi arg_2, high(msg_welcome_row1*2)
	rcall lcd_show_string

	ldi arg_1, $40
	rcall lcd_set_position

	ldi arg_1, low(msg_welcome_row2*2)
	ldi arg_2, high(msg_welcome_row2*2)
	rcall lcd_show_string

forever:
	rjmp forever

lcd_init:	
	;init 8bit, 2line, 5x7	
	ldi arg_1, $38	
	rcall lcd_set_option
	
	;set display on, cursor off, blink off	
	ldi arg_1, $0C
	rcall lcd_set_option

	;increase cursor, display sroll OFF
	ldi arg_1, $06
	rcall lcd_set_option		

	ret

lcd_show_string:	
	mov ZL, arg_1
	mov ZH, arg_2
	
	lcd_show_string_loop:
		lpm
		tst r0
		breq return		
		mov arg_1, r0
		rcall lcd_show_char		
		adiw Z, 1
		rjmp lcd_show_string_loop


lcd_show_char:
	sbi PORTA, 1
	rcall lcd_set_option
	ret

lcd_set_position:
	ori arg_1, $80
	rcall lcd_set_option
	ret

lcd_clear:
	ldi arg_1, $01	
	rcall lcd_set_option
	ret


lcd_set_option:		
	out PORTB, arg_1
	sbi PORTA, 0
	cbi PORTA, 0
	cbi PORTA, 1
	rcall DELAY_01
	ret

return:
	ret

DELAY_00:
; Delay 4 000 cycles
; 500us at 8.0 MHz
	    ldi  r18, 6
	    ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
	ret

DELAY_01:	
; DELAY_CONTROL 40 000 cycles
; 5ms at 8.0 MHz
	    ldi  r18, 52
	    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret

DELAY_02:
; Delay 160 000 cycles
; 20ms at 8.0 MHz
	    ldi  r18, 208
	    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
		ret

msg_welcome_row1:
.db "selamat datang di", 0
msg_welcome_row2:
.db "program absensi", 0
