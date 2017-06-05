;PORT MAPPING
;LCD ada di port a (RS, RW, EN) dan port B sisanya
;LED ada di port C
;buttons ada di port D

.include "m8515def.inc"

.def time_info=r14
.def day_info=r15

.def tmp=r16
.def tmp2=r17

.def arg_1=r24
.def arg_2=r25

.org $00
rjmp main
.org $01
rjmp int_next_shift
.org $02
rjmp int_prev_shift

int_prev_shift:
	rcall led_prev_shift
	rcall led_update
	reti

int_next_shift:
	rcall led_next_shift
	rcall led_update
	reti

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
	
	;init time
	rcall led_init
	ldi tmp, 1
	mov time_info, tmp
	mov day_info, tmp
	rcall led_update

	;show welcome screen
	ldi arg_1, low(msg_welcome_row1*2)
	ldi arg_2, high(msg_welcome_row1*2)
	rcall lcd_show_string

	ldi arg_1, $40
	rcall lcd_set_position

	ldi arg_1, low(msg_welcome_row2*2)
	ldi arg_2, high(msg_welcome_row2*2)
	rcall lcd_show_string
	
	;init interrupts
	ldi tmp, (1<<INT1)|(1<<INT0)
	out GIMSK, tmp
	ldi tmp, (1<<ISC01)|(1<<ISC11)
	out MCUCR, tmp
	sei

forever:
	rjmp forever

;led functions
led_prev_shift:
	mov tmp, time_info
	lsr tmp
	tst tmp
	brne led_prev_shift_no_mod	
	ldi tmp, 4
	led_prev_shift_no_mod:
		mov time_info, tmp

	cpi tmp, 4
	brne led_prev_shift_no_change

	mov tmp, day_info
	lsr tmp
	tst tmp
	brne led_prev_shift_day_no_mod
	ldi tmp, 16
	led_prev_shift_day_no_mod:
		mov day_info, tmp

	led_prev_shift_no_change:
		ret

led_next_shift:
	mov tmp, time_info
	lsl tmp
	cpi tmp, 8
	brne led_next_shift_no_mod	
	ldi tmp, 1
	led_next_shift_no_mod:
		mov time_info, tmp

	cpi tmp, 1
	brne led_next_shift_no_change

	mov tmp, day_info
	lsl tmp
	cpi tmp, 32
	brne led_next_shift_day_no_mod
	ldi tmp, 1
	led_next_shift_day_no_mod:
		mov day_info, tmp

	led_next_shift_no_change:
		ret

led_init:
	ser tmp
	out DDRC, tmp
	ldi tmp, 0 
	out PORTC, tmp
	ret

led_update:
	mov tmp, time_info
	lsl tmp
	lsl tmp
	lsl tmp
	lsl tmp	
	lsl tmp
	or tmp, day_info
	out PORTC, tmp
	ret

;lcd functions
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
