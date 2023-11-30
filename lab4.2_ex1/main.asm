;
; lab4.2_ex1.asm
;
; Created: 11/27/2023 3:44:24 PM
; Author : yenth
;


; Replace with your application code

		.org 0x00
		rjmp main
		.org 0x28
		rjmp UART0_RX
		.org 0x40
	`	.equ LED7SEGPORT = PORTB        
		.equ LED7SEGDIR =  DDRB
		.equ LED7SEGLatchPORT = PORTD
		.equ LED7SEGLatchDIR =  DDRD 
		.equ nLE0Pin   = 4 
		.equ nLE1Pin   = 5 
		.def LCDData = r16
		.def COUNT = r21
		.def DISPLAY = r18
		.equ LCDPORT = PORTA ; Set signal port reg to PORTA
		.equ LCDPORTDIR = DDRA ; Set signal port dir reg to PORTA
		.equ LCDPORTPIN = PINA ; Set clear signal port pin reg to PORTA
		.equ LCD_RS = PINA0
		.equ LCD_RW = PINA1
		.equ LCD_EN = PINA2
		.equ LCD_D7 = PINA7
		.equ LCD_D6 = PINA6
		.equ LCD_D5 = PINA5
		.equ LCD_D4 = PINA4
table_7seg_data: 
		.DB 0XC0, 0XF9,0XA4,0XB0,0X99,0X92,0X82,0XF8,0X80,0X90,0X88,0X8 
		.DB 0XC6,0XA1,0X86,0X8E 
;Lookup table for LED control 
table_7seg_control:   
		.DB 0b00001110,0b00001101, 0b00001011, 0b00000111 
main:
		;UART initial
		ldi r16, 51
		sts UBRR0L, r16						;set baudrate to 9600bps 
		ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
		sts UCSR0C, r16						;8-bit data
		ldi r16, (1<<RXEN0)|(1<<RXCIE0)		;enable transmit and receive interrupt
		sts UCSR0B, r16
		sei

		call LCD_Init
		call led7seg_portinit

begin:

		ldi r16, 0
		ldi r17, 0
		call LCD_Move_Cursor

		mov LCDData, DISPLAY
		call LCD_Send_Data

		call display_num

		rjmp begin

		;UART interrupt 
UART0_RX:
		push r17
		in r17, SREG
		push r17
		inc COUNT
		lds DISPLAY, UDR0
		;mov LCDData, DISPLAY

		lds r17, UCSR0B
		ori r17, (1 << UDRIE0)
		sts UCSR0B, r17
		pop r17
		out SREG, r17

		pop r17
		reti

		;subroutine to display counter
display_num:
		push r23
		push r24
		push r25
		push r26
		push r27
		clr r23				;initialize the tens counter
		clr r24				;initialize the hundreds counter
start:
		mov r25, r21		;save to temporary register
		cpi r25, 10		
		brcc display1		
		mov r27, r21		;display led0 if the number is less than 10
		ldi r26, 0				
		call display_7seg
		call DELAY
		ldi r27, 0
		ldi r26, 1
		call display_7seg
		call DELAY
		ldi r27, 0
		ldi r26, 2
		call display_7seg
		call DELAY
		ldi r27, 0
		ldi r26, 3
		call display_7seg
		call DELAY
		rjmp start
;display if the number has 2 digits	
display1:
		inc r23
		subi r25, 10
		cpi r25, 10
		brcc display1		;subtract until r25 is less than 10 to get the ones digit
		mov r27, r25		;display led0 if the number is greater than 10
		ldi r26, 0
		call display_7seg
		call DELAY
		cpi r23, 10
		brcc display2		;the number has 3 digits
		mov r27, r23		;display led1 if the number is less than 100
		ldi r26, 1
		call display_7seg
		call DELAY
		ldi r27, 0
		ldi r26, 2
		call display_7seg
		call DELAY
		ldi r27, 0
		ldi r26, 3
		call display_7seg
		call DELAY
		rjmp start
;display if the number has 3 digits
display2:
		inc r24
		mov r17, r23		;save to temporary register
		subi r17, 10
		cpi r17, 10
		brcc display2		;subtract until r17 is less than 10 to get the tens digit
		mov r27, r17		;display led1 if the number is greater than 100
		ldi r26, 1
		call display_7seg
		call DELAY
		mov r27, r24		;display led2 if the number is greater than 100
		ldi r26, 2
		call display_7seg
		call DELAY
		ldi r27, 0
		ldi r26, 3
		call display_7seg
		call DELAY
		rjmp start
		pop r27
		pop r26
		pop r25
		pop r24
		pop r23
		ret

;subroutine to initialize the LCD
LCD_Init:
	; Set up data direction register for Port A
	ldi r16, 0b11110111 ; set PA7-PA4 as outputs, PA2-PA0 as output
	out LCDPORTDIR, r16
	; Wait for LCD to power up
	call DELAY_10MS
	call DELAY_10MS

	 ; Send initialization sequence
	ldi r16, 0x02 ; Function Set: 4-bit interface
	call LCD_Send_Command
	ldi r16, 0x28 ; Function Set: enable 5x7 mode for chars
	call LCD_Send_Command
	ldi r16, 0x0E ; Display Control: Display OFF, Cursor ON
	call LCD_Send_Command
	ldi r16, 0x01 ; Clear Display
	call LCD_Send_Command
	ldi r16, 0x80 ; Clear Display
	call LCD_Send_Command
	ret

;subroutine to wait
LCD_wait_busy:
	push r16
	ldi r16, 0b00000111 ; set PA7-PA4 as input, PA2-PA0 as output
	out LCDPORTDIR, r16
	ldi r16,0b11110010 ; set RS=0, RW=1 for read the busy flag
	out LCDPORT, r16
	nop
LCD_wait_busy_loop:
	sbi LCDPORT, LCD_EN
	nop
	nop
	in r16, LCDPORTPIN
	cbi LCDPORT, LCD_EN
	nop
	sbi LCDPORT, LCD_EN
	nop
	nop
	cbi LCDPORT, LCD_EN
	nop
	andi r16,0x80
	cpi r16,0x80
	breq LCD_wait_busy_loop
	ldi r16, 0b11110111 ; set PA7-PA4 as output, PA2-PA0 as output
	out LCDPORTDIR, r16
	ldi r16,0b00000000 ; set RS=0, RW=1 for read the busy flag
	out LCDPORT, r16
	pop r16
	ret

;subroutine to send data
LCD_Send_Data:
	push r17
	call LCD_wait_busy ;check if LCD is busy
	mov r17,r16 ;save the command
	; Set RS high to select data register
	; Set RW low to write to LCD
	andi r17,0xF0
	ori r17,0x01
	; Send data to LCD
	out LCDPORT, r17
	nop
	; Pulse enable pin
	sbi LCDPORT, LCD_EN
	nop
	cbi LCDPORT, LCD_EN
	; Delay for command execution
	;send the lower nibble
	nop
	swap r16
	andi r16,0xF0
	; Set RS high to select data register
	; Set RW low to write to LCD
	andi r16,0xF0
	ori r16,0x01
	; Send command to LCD
	out LCDPORT, r16
	nop
	; Pulse enable pin
	sbi LCDPORT, LCD_EN
	nop
	cbi LCDPORT, LCD_EN
	pop r17
	ret

;subroutine to send command to LCD
LCD_Send_Command:
	push r17
	call LCD_wait_busy ; check if LCD is busy
	mov r17,r16 ;save the command
	; Set RS low to select command register
	; Set RW low to write to LCD
	andi r17,0xF0
	; Send command to LCD
	out LCDPORT, r17
	nop
	nop
	; Pulse enable pin
	sbi LCDPORT, LCD_EN
	nop
	nop
	cbi LCDPORT, LCD_EN
	swap r16
	andi r16,0xF0
	; Send command to LCD
	out LCDPORT, r16
	; Pulse enable pin
	sbi LCDPORT, LCD_EN
	nop
	nop
	cbi LCDPORT, LCD_EN
	pop r17
	ret

	;subroutine to move cursor in LCD
LCD_Move_Cursor:
	cpi r16,0 ;check if first row
	brne LCD_Move_Cursor_Second
	andi r17, 0x0F
	ori r17,0x80
	mov r16,r17
	; Send command to LCD
	call LCD_Send_Command
	ret
LCD_Move_Cursor_Second:
	cpi r16,1 ;check if second row
	brne LCD_Move_Cursor_Exit ;else exit
	andi r17, 0x0F
	ori r17,0xC0
	mov r16,r17
	; Send command to LCD
	call LCD_Send_Command
LCD_Move_Cursor_Exit:
; Return from function
	ret


;-----------------------------------------------------------------
;subroutine to delay 10ms
DELAY_10MS:
	push r21
	push r20
	LDI R21,80 ;1MC
	L1: LDI R20,250 ;1MC
	L2: DEC R20 ;1MC
	NOP ;1MC
	BRNE L2 ;2/1MC
	DEC R21 ;1MC
	BRNE L1 ;2/1MC
	pop r20
	pop r21
	RET ;4MC

DELAY:
	push r21
	push r20
	LDI R21,10 ;1MC
	L3: LDI R20,150 ;1MC
	L4: DEC R20 ;1MC
	NOP ;1MC
	BRNE L4 ;2/1MC
	DEC R21 ;1MC
	BRNE L3 ;2/1MC
	pop r20
	pop r21
	RET ;4MC

led7seg_portinit:
		push r20
		ldi r20, 0b11111111 ; SET led7seg PORT as output
		out LED7SEGDIR, r20
		in r20, LED7SEGLatchDIR ; read the Latch Port direction register
		ori r20, (1<<nLE0Pin) | (1 << nLE1Pin)
		out LED7SEGLatchDIR,r20
		pop r20
		ret

; Display a value on a 7-segment LED using a lookup table
; Input: R27 contains the value to display
; R26 contain the LED index (3..0)
; J34 connect to PORTD
; nLE0 connect to PB4
; nLE1 connect to PB5
; Output: None
display_7seg:
		push r16 ; Save the temporary register
; Look up the 7-segment code for the value in R18
; Note that this assumes a common anode display, where a HIGH output turns OFF the segment
; If using a common cathode display, invert the values in the table above
		ldi zh,high(table_7seg_data<<1) ;
		ldi zl,low(table_7seg_data<<1) ;
		clr r16
		add r30, r27
		adc r31,r16
		lpm r16, z
		out LED7SEGPORT,r16
		sbi LED7SEGLatchPORT,nLE0Pin
		nop
		cbi LED7SEGLatchPORT,nLE0Pin
		ldi zh,high(table_7seg_control<<1) ;
		ldi zl,low(table_7seg_control<<1) ;
		clr r16
		add r30, r26
		adc r31,r16
		lpm r16, z
		out LED7SEGPORT,r16
		sbi LED7SEGLatchPORT,nLE1Pin
		nop
		cbi LED7SEGLatchPORT,nLE1Pin
		pop r16 ; Restore the temporary register
		ret ; Return from the function


