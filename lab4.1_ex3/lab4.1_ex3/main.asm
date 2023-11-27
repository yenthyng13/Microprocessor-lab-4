;
; lab4.1_ex3.asm
;
; Created: 11/14/2023 1:11:12 PM
; Author : yenth
;


; Replace with your application code
		;.include "m324pdef.inc"
		.equ SS = 4
		ldi r16, (1<<5) | (1<<7) | (1<<4)
		out DDRB, r16
		sbi PORTB, SS

		;SPI initialize
		;LSB first, Master mode, sampling on rising edge, fclk / 8
		ldi r16, (1<<SPE0)  | (1<<MSTR0) | (1<<SPR00)
		out SPCR0, r16
		ldi r16, (1<<SPI2X0)
		out SPSR0, r16

		;UART initial
		ldi r16, 51
		sts UBRR0L, r16						;set baudrate to 9600bps 
		ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
		sts UCSR0C, r16						;8-bit data
		ldi r16, (1<<RXEN0)|(1<<TXEN0)	;enable transmit and receive interrupt
		sts UCSR0B, r16

		;Set input/output for ports:
		


start:	
		call USART_ReceiveChar
		;call USART_SendChar
		cbi	PORTB,SS
		call SPI_Transmit	
		sbi	PORTB,SS	
		jmp start


USART_SendChar:
		push r17
		;Wait for the transmitter to be ready
USART_SendChar_Wait:
		lds r17, UCSR0A
		sbrs r17, UDRE0 ;check USART Data Register Empty bit
		rjmp USART_SendChar_Wait
		sts UDR0, r16 ;send out
		pop r17
		ret

;receive 1 byte in r16 using UART
USART_ReceiveChar:
		push r17
		;Wait for the transmitter to be ready
USART_ReceiveChar_Wait:
		lds r17, UCSR0A
		sbrs r17, RXC0 ;check USART Receive Complete bit
		rjmp USART_ReceiveChar_Wait
		lds r16, UDR0 ;get data
		pop r17
		ret

;Send 1 byte in r16 using SPI
SPI_Transmit:
		push r17
		out SPDR0, r16

wait:	
		in r17, SPSR0
		sbrs r17, SPIF0
		rjmp wait

		in r16, SPDR0
		pop r17
		ret

