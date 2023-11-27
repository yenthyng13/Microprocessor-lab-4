;
; lab4.1_ex5.asm
;
; Created: 11/27/2023 3:18:57 PM
; Author : yenth
;


; Replace with your application code
		.def COUNT = r19
		
		;port initialize
		ldi r16, 0xff
		out DDRA, r16		;set port A as output


		;UART initial
		ldi r16, 51
		sts UBRR0L, r16						;set baudrate to 9600bps 
		ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
		sts UCSR0C, r16						;8-bit data
		ldi r16, (1<<RXEN0)|(1<<TXEN0)	;enable transmit and receive interrupt
		sts UCSR0B, r16

		ldi r19, 0
		call RD_data
main:	
		out PORTA, COUNT
		call USART_ReceiveChar
		;out PORTA, COUNT
		call WR_data
		rjmp main

		;receive 1 byte in r16 using UART
USART_ReceiveChar:
		push r17
		;Wait for the transmitter to be ready
USART_ReceiveChar_Wait:
		lds r17, UCSR0A
		sbrs r17, RXC0		;check USART Receive Complete bit
		rjmp USART_ReceiveChar_Wait
		inc COUNT			;increase the counter
		lds r16, UDR0		;get data
		pop r17
		ret


		;write data to EEPROM
WR_data:
		;write the address 
		sbic EECR, EEPE
		rjmp WR_data
		;set up address
		ldi r18, 0
		out EEARH, r18
		ldi r17, 0
		out EEARL, r17
		;write data 
		out EEDR, COUNT
		sbi EECR, EEMPE
		sbi EECR, EEPE
		ret

RD_data:
		sbic EECR, EEPE
		rjmp RD_data
		ldi r18, 0
		out EEARH, r18
		ldi r17, 0
		out EEARL, r17
		sbi EECR, EERE
		in COUNT, EEDR
		ret
