;PORT MAPPING
;LCD ada di port D (RS (5), RW (6), EN (4))
;LCD data ada di port B
;LED ada di port A
;Keypad di port C
;buttons ada di port D (port 2 dan 3)

.include "m8515def.inc"

.def time_info=r14
.def day_info=r15

;temporary variables
.def tmp=r16
.def tmp2=r17
.def tmp3=r18

;keypad's variables
.def keyvalKey = r19
.def tempKey   = r20
.def flagsKey  = r21

;holds current matkul index
.def cur_matkul=r22

;holds window state
.def winstate=r23

;auxiliary veriables
.def arg_1=r24
.def arg_2=r25

;Keypad Definitions
.equ col1 = PINC0
.equ col2 = PINC1
.equ col3 = PINC2
.equ col4 = PINC3
.equ keyport  = PORTC
.equ pressed  = 0

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
	rcall lcd_show_string_rom
	
	rcall lcd_set_row2

	ldi arg_1, low(msg_welcome_row2*2)
	ldi arg_2, high(msg_welcome_row2*2)
	rcall lcd_show_string_rom
	
	;load data
	rcall load_to_ram;
	rcall input_clear
	rcall delay_02
	rcall delay_02
	
	rcall list_init
	rcall list_write
	
	;init interrupts
	ldi tmp, (1<<INT1)|(1<<INT0)
	out GIMSK, tmp
	ldi tmp, (1<<ISC01)|(1<<ISC11)
	out MCUCR, tmp
	sei
	
	rcall init_keypad
forever:
	rcall READ_KEYPAD
	tst keyvalKey
	breq forever	

	;handle button 1-12
	cpi keyvalKey, 1
	brlt forever_4
	cpi keyvalKey, 10
	brge forever_4
	cpi winstate, 2
	brne forever_4
	mov arg_1, keyvalKey
	subi arg_1, -'0'
	rcall lcd_show_char
	rcall delay_02	
	subi arg_1, '0'
	rcall input_save	
	rcall list_init
	rcall list_write
	forever_4:

	;handle prev matkul	
	cpi keyvalKey, 13
	brne forever_1
	cpi winstate, 1
	brne forever_1
	rcall list_prev
	rcall list_write
	forever_1:	

	;handle next matkul
	cpi keyvalKey, 14
	brne forever_2
	cpi winstate, 1
	brne forever_2
	rcall list_next
	rcall list_write
	forever_2:
	
	;handle absen button
	cpi keyvalKey, 15
	brne forever_3
	cpi winstate, 1
	brne forever_3
	rcall input_init	
	forever_3:
			
	;handle info button	
	cpi keyvalKey, 16
	brne forever_5
	cpi winstate, 1
	brne forever_5
	rcall log_init
	rcall log_show
	forever_5:

	;handle back log
	cpi keyvalKey, 12
	brne forever_6
	cpi winstate, 3
	brne forever_6	
	rcall list_init
	rcall list_write
	rcall led_update
	forever_6:	
	
	;handle prev log
	cpi keyvalKey, 13
	brne forever_7
	cpi winstate, 3
	brne forever_7
	rcall log_prev
	rcall log_show
	forever_7:
	
	;handle prev log
	cpi keyvalKey, 14
	brne forever_8
	cpi winstate, 3
	brne forever_8
	rcall log_next
	rcall log_show
	forever_8:

	rjmp forever

;window input absen
input_init:
	ldi winstate, 2
	rcall lcd_clear
	rcall lcd_set_row1	
	ldi arg_1, low(msg_input*2)
	ldi arg_2, high(msg_input*2)
	rcall lcd_show_string_rom
	rcall lcd_set_row2	
	ldi arg_1, low(msg_prompt*2)
	ldi arg_2, high(msg_prompt*2)
	rcall lcd_show_string_rom
	ret

;Y pointer will store head of log
;save in $100 
input_clear:	
	ldi YL, $00
	ldi YH, $01
	ldi tmp, 0	
	st Y, tmp ;null terminated.		
	ret

;save di ofset $100
;each data costs 4 Bytes
input_save:	
	st Y+, arg_1
	st Y+, cur_matkul
	st Y+, day_info
	st Y+, time_info	
	ldi tmp, 0
	st Y+, tmp ;null terminated	
	st -Y, tmp ;bring back head
	rcall lcd_clear
	ldi arg_1, low(msg_saved*2)
	ldi arg_2, high(msg_saved*2)	
	rcall lcd_show_string_rom
	rcall delay_02
	ret

;window show log
log_init:
	ldi winstate, 3
	ldi XL, $00
	ldi XH, $01
	ret

log_show:
	ld tmp, X
	tst tmp
	brne log_show_not_empty
	rcall lcd_clear
	rcall lcd_set_row1
	ldi arg_1, low(msg_log_empty*2)
	ldi arg_2, high(msg_log_empty*2)
	rcall lcd_show_string_rom	
	ret

	log_show_not_empty:	

	;show npm
	rcall lcd_clear
	rcall lcd_set_row1
	ldi arg_1, low(msg_log_row1*2)
	ldi arg_2, high(msg_log_row1*2)
	rcall lcd_show_string_rom
	ld arg_1, X+
	subi arg_1, -'0'
	rcall lcd_show_char

	;show nama matkul
	rcall lcd_set_row2
	ldi arg_1, low(msg_log_row2*2)
	ldi arg_2, high(msg_log_row2*2)
	rcall lcd_show_string_rom
	
	ld tmp, X+
	mov ZL, tmp
	ldi ZH, 0
	
	ld arg_1, Z+
	ld arg_2, Z+
	rcall lcd_show_string_rom
	
	;get day_info and time_info
	push day_info
	push time_info	
	ld day_info, X+
	ld time_info, X+
	rcall led_update
	pop time_info
	pop day_info	
	sbiw X, 4
	ret //assert when leaves this func X always pointing start of current index

log_next:
	//disregard next if current is empty
	ld tmp, X
	tst tmp	
	breq log_next_nope	
	adiw X, 4	
	log_next_nope:
	ret	

log_prev:
	//if current is $100, dont set to prev
	cpi XL, $00
	brne log_prev_update
	cpi XH, $01
	brne log_prev_update
	ret

	log_prev_update:
	sbiw X, 4
	ret

;selector matkul
;cur_matkul holds current matkul name pointer
list_init:
	ldi winstate, 1 ;which means select matkul
	ldi cur_matkul, $60
	rcall lcd_clear
	rcall lcd_set_row1
	ldi arg_1, low(msg_select_matkul*2)
	ldi arg_2, high(msg_select_matkul*2)
	rcall lcd_show_string_rom
	ret	

list_write:	
	rcall lcd_set_row2
	
	ldi arg_1, low(msg_prompt*2)
	ldi arg_2, high(msg_prompt*2)
	rcall lcd_show_string_rom
		
	mov XL, cur_matkul
	ldi XH, 0
	
	ld arg_1, X+
	ld arg_2, X+
	rcall lcd_show_string_rom
	ret

list_next:
	subi cur_matkul, -2
	cpi cur_matkul, $6A
	brne cycle_list_not_overflow_1
	ldi cur_matkul, $60
	cycle_list_not_overflow_1:
	ret

list_prev:
	subi cur_matkul, 2
	cpi cur_matkul, $5E
	brne cycle_list_not_overflow_2
	ldi cur_matkul, $68
	cycle_list_not_overflow_2:
	ret

;load matkul ke ram
load_to_ram:
;memory 60..6A HI:LO simpan pointer ke string (array of string)
;strings starts at 0x6B
	ldi XL, $60 ;holds pointer to pointer to current string
	ldi XH, 0

	ldi YL, low(matkul_name*2) ;pointer to current string (head)
	ldi YH, high(matkul_name*2)

	ldi ZL, low(matkul_name*2) ;pointer to program memory
	ldi ZH, high(matkul_name*2)
	
	ldi tmp, 5 ;loading 5 strings
	loop_load_to_ram:		
		lpm								
		adiw Z, 1
		tst r0								
		brne loop_load_to_ram
		;found end of current string
		st X+, YL
		st X+, YH
		mov YL, ZL
		mov YH, ZH		
		subi tmp, 1
		tst tmp		
		brne loop_load_to_ram
	ret

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
	out DDRA, tmp
	ldi tmp, 0 
	out PORTA, tmp
	ret

led_update:
	mov tmp, time_info
	lsl tmp
	lsl tmp
	lsl tmp
	lsl tmp	
	lsl tmp
	or tmp, day_info
	out PORTA, tmp
	ret

AWAL:
	ldi tempKey, low(RAMEND)
	out SPL, tempKey
	ldi tempKey, high(RAMEND)
	out SPH, tempKey

INIT_KEYPAD:
	ldi keyvalKey, $F0     	; Make Cols as i / p
	out DDRC, keyvalKey    	; and Rows as o / p
	ldi keyvalKey, $0F     	; Enable pullups
	out keyport, keyvalKey	; on columns
	ret

		; cara mau cek apakah tombolnya bisa ditekan, coba pencet salah satu
						; tombol di keypad lalu pause programnya dan bandingkan hasilnya dengan
						; r21

						; secara otomatis, kalau keyvalKey tidak ditekan, nilai keyvalKey tetap 0

	READ_KEYPAD:
	rcall get_key
	ret

	get_key:
		ldi keyvalKey, 1    	; Scanning Row1
		ldi tempKey, $7F 		; Make Row 1 low
		out keyport, tempKey 	; Send to keyport
		rcall read_col 			; Read Columns

		sbrc flagsKey, pressed 	; If key pressed
		rjmp done 				; Exit the routine

		ldi keyvalKey, 2 		; Scanning Row2
		ldi tempKey, $BF 		; Make Row 2 Low
		out keyport, tempKey 	; Send to keyport
		rcall read_col 			; Read Columns

		sbrc flagsKey, pressed 	; If key pressed
		rjmp done 				; Exit from routine

		ldi keyvalKey, 3 		; Scanning Row3
		ldi tempKey, $DF 		; Make Row 3 Low
		out keyport, tempKey 	; Send to keyport
		rcall read_col 			; Read columns

		sbrc flagsKey, pressed 	; If key pressed
		rjmp done 				; Exit the routine

		ldi keyvalKey , 4 		; Scanning Row4
		ldi tempKey , $EF 		; Make Row 4 Low
		out keyport, tempKey 	; send to keyport
		rcall read_col 			; Read columns

	done:
		ret

	read_col :
		cbr flagsKey, (1 << pressed) 	; Clear status flag

		sbic PINC, col1 				; Check COL1
		rjmp nextcol 					; Go to COL2 if not low

	hold :
		sbis PINC , col1 				; Wait for key release
		rjmp hold

		sbr flagsKey, (1 << pressed) 	; Set status flag
		ret 							; key 1 pressed

	nextcol:
		sbic PINC , col2 				; Check COL2
		rjmp nextcol1 					; Goto COL3 if not low

	hold1:
		sbis PINC , col2 				; Wait for key release
		rjmp hold1
		
		ldi tempKey, 4
		add keyvalKey, tempKey			; Key 2 pressed

		sbr flagsKey, (1 << pressed) 	; Set status flag
		ret
	nextcol1 :
		sbic PINC , col3 				; Check COL3
		rjmp nextcol2 					; Goto COL4 if no pressed

	hold2:
		sbis PINC , col3 				; Wait for key release
		rjmp hold2
		
		ldi tempKey, 8
		add keyvalKey, tempKey			; Key 2 pressed

		sbr flagsKey, (1 << pressed) 	; Set status flag
		ret

	nextcol2:
		sbic PINC , col4 				; Check COL4
		rjmp exit						; Exit if not low

	hold3:
		sbis PINC , col4 				; Wait for key release
		rjmp hold3

		ldi tempKey, 12
		add keyvalKey, tempKey			; Key 2 pressed

		sbr flagsKey, (1 << pressed) 	; Set status flag
		ret

	exit:
		clr keyvalKey 					; reset keyvalKey
		cbr flagsKey, (1 << pressed) 	; No Key Pressed
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

lcd_clear_row2:
	rcall lcd_set_row2
	ldi tmp, 30
	lcd_clear_row2_loop:	
	ldi arg_1, ' '
	rcall lcd_show_char
	subi tmp, 1
	tst tmp
	brne lcd_clear_row2_loop	

lcd_set_row1:	
	ldi arg_1, $0
	rcall lcd_set_position	
	ret

lcd_set_row2:
	ldi arg_1, $40
	rcall lcd_set_position
	ret

lcd_show_string_ram:	
	mov XL, arg_1
	mov XH, arg_2
	
	lcd_show_string_ram_loop:
		ld tmp, X+
		tst tmp
		breq return		
		mov arg_1, tmp
		rcall lcd_show_char		
		rjmp lcd_show_string_ram_loop

lcd_show_string_rom:	
	mov ZL, arg_1
	mov ZH, arg_2
	
	lcd_show_string_rom_loop:
		lpm
		tst r0
		breq return		
		mov arg_1, r0
		rcall lcd_show_char		
		adiw Z, 1
		rjmp lcd_show_string_rom_loop

lcd_show_char:
	sbi PORTD, 5
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
	sbi PORTD, 4
	cbi PORTD, 4
	cbi PORTD, 5
	rcall DELAY_01
	ret

return:
	ret

DELAY_00:
; Delay 4 000 cycles
; 500us at 8.0 MHz
	push r18
	push r19
	    ldi  r18, 6
	    ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
	pop r19
	pop r18
	ret

DELAY_01:	
; DELAY_CONTROL 40 000 cycles
; 5ms at 8.0 MHz
	push r18
	push r19
	    ldi  r18, 52
	    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	pop r19
	pop r18
	ret

DELAY_02:
; Delay 160 000 cycles
; 20ms at 8.0 MHz
	push r18
	push r19
	    ldi  r18, 208
	    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
		pop r19
		pop r18
		ret

msg_welcome_row1:
.db "Selamat Datang Di", 0
msg_welcome_row2:
.db "Program Absensi", 0
msg_select_matkul:
.db "Pilih mata kuliah", 0
msg_prompt:
.db "> ", 0
msg_input:
.db "Masukkan NPM: (1-9)", 0
msg_saved:
.db "Data tersimpan!", 0
msg_log_row1:
.db "NPM   : ", 0
msg_log_row2:
.db "Matkul: ", 0
msg_log_empty:
.db "Akhir dari database.", 0

;nama mata kuliah
matkul_name:
.db "POK      ", 0
.db "Matdas 1 ", 0
.db "Matdis 2 ", 0
.db "TKTPL    ", 0
.db "MPKT B   ", 0

