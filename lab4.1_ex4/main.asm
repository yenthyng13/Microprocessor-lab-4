;
; lab4.1_ex4.asm
;
; Created: 11/22/2023 4:17:15 PM
; Author : yenth
;


; Replace with your application code
		.equ SS=4 
		.equ MOSI=5 
		.equ MISO=6 
		.equ SCK=7 
		.equ WIP = 0
		.equ WREN = 0x06
		.equ RDSR = 0x05
		.equ WRSR = 0x01
		.equ SPI_RD = 0x03
		.equ SPI_WR = 0x02
		.equ MEM_BYTE3 = 0x00
		.equ MEM_BYTE21 = 0x0100
		.def COUNT = r19

		ldi r16, (1<<MOSI) | (1<<SCK) | (1<<SS)
		out DDRB, r16
		
		;port initialize
		ldi r16, 0xff
		out DDRA, r16		;set port A as output

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

		sbi PORTB, SS

		ldi r19, 0
		call RD_data
main:	
		call USART_ReceiveChar
		out PORTA, COUNT
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

		;Send 1 byte in r16 using SPI
		;r20 contains data from EEPROM 
SPI_Transmit:
		push r17
		out SPDR0, r16
wait:	
		in r17, SPSR0
		sbrs r17, SPIF0
		rjmp wait
		in r20, SPDR0
		pop r17
		ret

		;write data to EEPROM
WR_data:
		;write the address 
		in r17, SPSR0
		ldi r16, WREN
		cbi PORTB, SS			;start SPI transmit
		call SPI_Transmit
		sbi PORTB, SS			;stop SPI transmit
		ldi r16, SPI_WR
		cbi PORTB, SS			
		call SPI_Transmit
		ldi r16, MEM_BYTE3
		call SPI_Transmit
		ldi r16, HIGH(MEM_BYTE21)
		call SPI_Transmit
		ldi r16, LOW(MEM_BYTE21)
		call SPI_Transmit
		;sbi PORTB, SS
		;write data to EEPROM
		mov r16, COUNT
		call SPI_Transmit
		sbi PORTB, SS
		ret

RD_data:
		ldi r16, SPI_RD
		cbi PORTB, SS			
		call SPI_Transmit
		ldi r16, MEM_BYTE3
		call SPI_Transmit
		ldi r16, HIGH(MEM_BYTE21)
		call SPI_Transmit
		ldi r16, LOW(MEM_BYTE21)
		call SPI_Transmit
		ldi r16, 0
		call SPI_Transmit
		sbi PORTB, SS
		mov COUNT, r20
		ret