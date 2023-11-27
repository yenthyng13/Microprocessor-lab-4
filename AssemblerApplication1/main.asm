;
; AssemblerApplication1.asm
;
; Created: 11/2/2023 7:32:31 AM
; Author : yenth
;

		;UART initial
		ldi r16, 51
		sts UBRR0L, r16						;set baudrate to 9600bps 
		ldi r16, (1<<UCSZ01)|(1<<UCSZ00)
		sts UCSR0C, r16						;8-bit data
		sei
		ldi r16, (1<<RXCIE0)|(1<<TXCIE0)	;enable transmit and receive interrupt
		sts UCSR0B, r16
start:		
		call USART_ReceiveChar
		call USART_SendChar
		rjmp start
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

;receive 1 byte in r16
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

