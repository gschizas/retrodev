; **********
; * Macros *
; **********

;-----------------------------------------------------------------------------
; Macros generales
;-----------------------------------------------------------------------------
; Obtiene el puntero correcto a la cadena
OBTEN_PUNTERO_REG MACRO reg
	LD reg,(HL)
	INC HL
	LD H,(HL)
	LD L,reg
	ENDM

; Envia un comando al puerto del VDIP
SEND_CMD MACRO comando
	LD BC,VDIP_PORT
	LD D,comando
	OUT (C),D
	ENDM

; Envia un byte a un puerto ya establecido
SEND_BYTE MACRO byte
	LD D,byte
	OUT (C),D
	ENDM

; Envia un byte a un puerto ya establecido (usando el acumulador)
SEND_ABYTE MACRO byte
	LD A,byte
	OUT (C),A
	ENDM

; Envia una dword (4 bytes) a un puerto ya establecido
SEND_DWORD MACRO val_1,val_2,val_3,val_4
	OUT (C),val_1
	OUT (C),val_2
	OUT (C),val_3
	OUT (C),val_4
	ENDM

; Envia una cadena de bytes (nombre del fichero) a un puerto ya establecido
SEND_FILENAME MACRO
	LOCAL bucle_send_filename
bucle_send_filename
	SEND_BYTE (HL) 		;	LD D,(HL) ;	OUT (C),D
	INC HL
	DEC A
	JR NZ,bucle_send_filename
	ENDM	

; Comprueba si concuerdan el número de parámetros enviados con el acumulador
TEST_PARAM MACRO num_param
	CP num_param	; comprobamos el número de parámetros
	JP NZ,error_en_parametros
	ENDM	

; Rellenamos la variable de cadena
FILL_STRING_CONT MACRO desplazamiento,num_bytes,registro
	LD L,(IX+desplazamiento)
	LD H,(IX+desplazamiento+1)
;	LD A,num_bytes
;	LD (HL),A
    LD (HL),num_bytes
	INC HL		; Puntero a la variable de cadena
	OBTEN_PUNTERO_REG registro
	ENDM

FILL_STRING_MINI MACRO registro
    LD A,(HL)   ; Longitud del nombre del fichero
    INC HL      ; Puntero al nombre del fichero
    OBTEN_PUNTERO_REG registro
    ENDM

FILL_STRING MACRO desplazamiento,registro
	LD L,(IX+desplazamiento)
	LD H,(IX+desplazamiento+1)
    FILL_STRING_MINI registro
;	LD A,(HL)	; Longitud del nombre del fichero
;	INC HL		; Puntero al nombre del fichero
;	OBTEN_PUNTERO_REG registro
	ENDM

; Escribimos #xxxx bytes en un puerto ya establecido
; DE => Contador
; HL => Origen
WRITE_BYTES16 MACRO
	LOCAL bucle_write_bytes
bucle_write_bytes
;   INC B
;   OUTI
	LD A,(HL)
	OUT (C),A
	INC HL
	DEC DE
	LD A,D
	OR E
	JR NZ,bucle_write_bytes
	ENDM

; Leemos #xxxx bytes de un puerto ya establecido
; DE => Contador
; HL => Destino
READ_BYTES16 MACRO
	LOCAL bucle_read_bytes
bucle_read_bytes
	INI
	INC B
	DEC DE
	LD A,D
	OR E
	JR NZ,bucle_read_bytes
	ENDM

; Leemos #xx bytes de un puerto ya establecido
; A => Contador
; HL => Destino
READ_BYTES8 MACRO
	LOCAL bucle_read_bytes
bucle_read_bytes
	INI
	INC B
	DEC A
	JR NZ,bucle_read_bytes
	ENDM

; Salta #xx bytes leidos de un puerto ya establecido
; A => Contador
SKIP_BYTES8 MACRO
	LOCAL bucle_skip_bytes
bucle_skip_bytes
	DEFB #ED,#70		; IN F,(C)	Salta  el nombre del fichero
	DEC A
	JR NZ,bucle_skip_bytes
	ENDM

; LD HLE,#xxxxxx
LOAD_ELH MACRO val_e,val_l,val_h
	LD E,val_e
	LD L,val_l
	LD H,val_h
	ENDM

;-----------------------------------------------------------------------------
; Macros que envían los comandos al VDIP
;-----------------------------------------------------------------------------
; Envia un comando sin parámetros al VDIP
SEND_CMD_0_PARAM MACRO comando
	TEST_PARAM #00
	SEND_CMD comando
	SEND_BYTE INTRO
	ENDM

; Envia un comando sin parámetros, pero que usa una variable al VDIP
SEND_CMD_VAR MACRO comando,num_bytes
	TEST_PARAM #01
	SEND_CMD comando
	SEND_BYTE INTRO
	FILL_STRING_CONT 0,num_bytes,E
	READ_BYTES8
	ENDM

SEND_CMD_VAR_HEX MACRO comando,num_bytes
	TEST_PARAM #01
	SEND_CMD comando
	SEND_BYTE INTRO
	FILL_STRING_CONT 0,num_bytes,E
	LD A,num_bytes/2
	READ_BYTES8
	ENDM

; Envia un comando de dos parámetros (nombre fichero) y obligatorios al VDIP
SEND_CMD_2_FILE MACRO comando
	TEST_PARAM #02
	SEND_CMD comando
	SEND_BYTE ESPACIO
	FILL_STRING 2,E
	SEND_FILENAME
	SEND_BYTE ESPACIO
	FILL_STRING 0,E
	SEND_FILENAME
	SEND_BYTE INTRO
	ENDM

; Envia un comando de un solo parámetro (nombre fichero) y obligatorio al VDIP
SEND_CMD_1_FILE MACRO comando
	TEST_PARAM #01
	FILL_STRING 0,E
	SEND_CMD comando
	SEND_BYTE ESPACIO
	SEND_FILENAME
	SEND_BYTE INTRO
	ENDM

; Envia un comando de un solo parámetro (dword) y obligatorio al VDIP
SEND_CMD_1_DWORD MACRO comando
	TEST_PARAM #01
	SEND_CMD comando
	SEND_BYTE ESPACIO
	
	XOR A
	LD L,(IX+0)	; Byte Bajo 
	LD H,(IX+1)	; Byte Alto
	SEND_DWORD A,A,H,L		; solo 16 bits
	SEND_BYTE INTRO
	ENDM

; Envia un comando de dos parámetros (dword) y obligatorios al VDIP
SEND_CMD_2_DWORD MACRO comando
	TEST_PARAM #02
	SEND_CMD comando
	SEND_BYTE ESPACIO
	
	; Dirección en RAM de los bytes
	LD L,(IX+0)
	LD H,(IX+1)

	; Número de bytes
	LD E,(IX+2)
	LD D,(IX+3)

	XOR A
	SEND_DWORD A,A,D,E		; solo 16 bits
	SEND_ABYTE INTRO
	ENDM

; Envia un comando de un parámetro "nombre fichero" (opcional) al VDIP
SEND_CMD_FILE_OPTIONAL MACRO comando
	LOCAL _hay_fichero,_no_hay_fichero,_sigue,_envia_intro
	CP #01	; comprobamos el número de parámetros
	JR Z,_hay_fichero
	CP #00
	JR Z,_no_hay_fichero
	JP error_en_parametros
_hay_fichero
	FILL_STRING 0,E
	JR _sigue
_no_hay_fichero
	XOR A
_sigue
	SEND_CMD comando
	OR A
	JR Z,_envia_intro
	SEND_BYTE ESPACIO
	SEND_FILENAME
_envia_intro
	SEND_BYTE INTRO
	ENDM

; Envia un comando de dos parámetro "nombre fichero" (obligatorio) y "date" (opcional) al VDIP
SEND_CMD_FILE_DATE MACRO comando
LOCAL _hay_fecha,_solo_nombre,_sigue,_sigue_ejecutando
	CP #02
	JR Z,_hay_fecha
	CP #01
	JR Z,_solo_nombre
	JP error_en_parametros
_hay_fecha
	LOAD_ELH 'D',(IX+2),(IX+3)
	JR _sigue
_solo_nombre
	LOAD_ELH #00,(IX+0),(IX+1)
_sigue
	FILL_STRING_MINI D
	SEND_CMD comando
	SEND_BYTE ESPACIO
	SEND_FILENAME

	LD A,E
	CP 'D'
	JR NZ,_sigue_ejecutando
	SEND_BYTE ESPACIO
	SEND_BYTE (IX+1)
	SEND_BYTE (IX+0)
_sigue_ejecutando
	SEND_BYTE INTRO
	ENDM


; Envia un comando de dos parámetro "nombre fichero" (obligatorio) y "datetime" (opcional) al VDIP
SEND_CMD_FILE_DATETIME MACRO comando
	LOCAL _hay_hora,_hay_fecha,_solo_nombre,_sigue,_sigue_ejecutando,_sigue_solo_fecha	
	CP #03
	JR Z,_hay_hora
	CP #02
	JR Z,_hay_fecha
	CP #01
	JR Z,_solo_nombre
	JP error_en_parametros
_hay_hora
	LOAD_ELH 'H',(IX+4),(IX+5)
	JR _sigue
_hay_fecha
	LOAD_ELH 'D',(IX+2),(IX+3)
	JR _sigue
_solo_nombre
	LOAD_ELH #00,(IX+0),(IX+1)
_sigue
	FILL_STRING_MINI D
	SEND_CMD comando
	SEND_BYTE ESPACIO
	SEND_FILENAME

	LD A,E
	CP 'H'
	JR NZ,_sigue_solo_fecha
	SEND_BYTE ESPACIO
	SEND_BYTE (IX+3)
	SEND_BYTE (IX+2)
	SEND_BYTE (IX+1)
	SEND_BYTE (IX+0)
	JR _sigue_ejecutando
_sigue_solo_fecha	
	CP 'D'
	JR NZ,_sigue_ejecutando
	; SEND_BYTE ESPACIO
	SEND_BYTE ESPACIO
	SEND_BYTE #00
	SEND_BYTE #00
	SEND_BYTE (IX+1)
	SEND_BYTE (IX+0)
	
_sigue_ejecutando	
	SEND_BYTE INTRO
	ENDM


; Exclusivamente para el comando DIRT :P (hasta el prompt)
SEND_CMD_VAR_DIRT MACRO comando,num_bytes
	TEST_PARAM #02
	SEND_CMD comando
	SEND_BYTE ESPACIO

	LD L,(IX+2)
	LD H,(IX+3)
	FILL_STRING_MINI E
	SEND_FILENAME
	SEND_BYTE INTRO

	; Rellenamos la variable de cadena
	LD L,(IX+0)
	LD H,(IX+1)
	LD A,num_bytes
	FILL_STRING_MINI E

	DIR_VS_ERROR

	LD E,(IX+2)
	LD D,(IX+3)
	LD A,(DE)
	DEC A
	SKIP_BYTES8
	
	LD A,num_bytes
	READ_BYTES8

	IN A,(C)
	CP INTRO
	JP NZ,trata_error
	IN A,(C)			
	CP PROMPT
	JP NZ,trata_error
	IN A,(C)
	CP INTRO
	JP NZ,trata_error
	ENDM

;-----------------------------------------------------------------------------
; Manejadores simples de errores
;-----------------------------------------------------------------------------
;SALIDAS:
; A: primer byte de código de error
;-----------------------------------------------------------------------------
PROMPT_VS_ERROR MACRO
	IN A,(C)			
	CP PROMPT			; ¿Se ejecutó el comando sin problemas?
	JP NZ,trata_error	; A = primer byte de código de error
	IN A,(C)
	CP INTRO			; No debería de pasar nada, pero y si pasa xDDD
	JP NZ,trata_error	; A = primer byte de código de error
	ENDM


; Se lee un byte, si no es INTRO entonces ERROR
DIR_VS_ERROR MACRO
	LOCAL _siguente_linea_01,_siguente_linea_02
	DEFB #ED,#70		; IN F,(C)	Pasamos del INTRO que sale
	IN H,(C)			
	IN L,(C)			
	IN A,(C)			
	CP INTRO
	JP Z,trata_error_dir ; HL código de error
	LD D,A
	LD A,H
	CP INTRO
	JR NZ,_siguente_linea_01
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
_siguente_linea_01
	CALL TXT_OUTPUT
	LD A,L
	CP INTRO
	JR NZ,_siguente_linea_02
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
_siguente_linea_02
	CALL TXT_OUTPUT
	LD A,D
;	CALL TXT_OUTPUT		; Se imprime en el siguiente paso
	ENDM

RESULT_VS_NO_DISK MACRO
	LOCAL _salio_bien
	LD L,(IX+0)
	LD H,(IX+1)
	INC HL		; Puntero a la variable de cadena
	OBTEN_PUNTERO_REG E
	
	LD A,(HL)
	CP 'N'
	JR NZ,_salio_bien
	INC HL
	LD A,(HL)
	CP 'D'
	JR NZ,_salio_bien
	LD A,(HL)
	CP INTRO
	JR NZ,_salio_bien
	JP error_no_disk
_salio_bien
	DEFB #ED,#70		; IN F,(C)	'INTRO'
	PROMPT_VS_ERROR
	ENDM

	
; Muestra el idde por pantalla (hasta el prompt)
IDDE_VS_NO_DISK MACRO
	LOCAL _no_hay_error_n,_no_hay_error_d,_no_hay_error_nd,_bucle_idde,_siguiente_linea_idde
	IN A,(C)
	CP 'N'
	JR NZ,_no_hay_error_n
	INC HL
	LD A,(HL)
	CP 'D'
	JR NZ,_no_hay_error_d
	LD A,(HL)
	CP INTRO
	JR NZ,_no_hay_error_nd
	JP error_no_disk

_no_hay_error_nd
	LD D,A
	LD A,'N'
	CALL TXT_OUTPUT
	LD A,'D'
	CALL TXT_OUTPUT
	LD A,D
	JR _bucle_idde
_no_hay_error_d
	LD D,A
	LD A,'N'
	CALL TXT_OUTPUT
	LD A,D
_no_hay_error_n
_bucle_idde
	CALL TXT_OUTPUT
	IN A,(C)			
	CP INTRO
	JR NZ,_siguente_linea_idde
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
	JR _bucle_idde
_siguente_linea_idde
	CP PROMPT
	JR NZ,_bucle_idde
;	CALL TXT_OUTPUT
	IN A,(C)
	CP INTRO
	JR NZ,_bucle_idde
	ENDM

; Muestra el directorio por pantalla (hasta el prompt)
PRINT_DIR MACRO
	LOCAL _sigue_leyendo,_siguiente_linea_dir
_sigue_leyendo
	CALL TXT_OUTPUT
	IN A,(C)			
	CP INTRO
	JR NZ,_siguente_linea_dir
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
	JR _sigue_leyendo
_siguente_linea_dir
	CP PROMPT
	JP NZ,_sigue_leyendo
;	CALL TXT_OUTPUT
	IN A,(C)
	CP INTRO
	JP NZ,_sigue_leyendo
	ENDM

; Muestra la versión del firmware
PRINT_VERSION MACRO
	LOCAL _sigue_leyendo_ver,_siguiente_linea_ver
	DEFB #ED,#70		; IN F,(C)	Paso del primer INTRO
	IN A,(C)
_sigue_leyendo_ver
	CALL TXT_OUTPUT
	IN A,(C)			
	CP INTRO
	JR NZ,_siguente_linea_ver
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
	JR _sigue_leyendo_ver
_siguente_linea_ver
	CP PROMPT
	JP NZ,_sigue_leyendo_ver
	IN A,(C)
	CP INTRO
	JP NZ,_sigue_leyendo_ver
	ENDM

;-----------------------------------------------------------------------------
; Macros de manejo de las cabeceras del Amsdos
;-----------------------------------------------------------------------------	
; Cabecera de los ficheros del Amsdos
;------------------------------------
; Longitud 128 bytes
; 0-63 Cabecera de disco
; 64-66 Longitud del fichero en bytes, excluyendo la cabecera (24 bits, little endian)
; 67-68 Suma de los bytes 0-66 (16 bits, checksum)
; 69-127 Sin definir
; 
; Detalles de la cabecera del disco
;----------------------------------
; 0 Número de usuario (#00-#0F)
; 1-8 Nombre del fichero (Rellenado con espacios)
; 9-11 Extensión del fichero (Rellenado con espacios)
; 12-15 Rellenado a #00
; 16 Número de bloque (no se usa a #00)
; 17 Último bloque (no se usa a #00)
; 18 Tipo de fichero
;    Bits:
;		0 Bit de Protección
;		1-3 0 Basic/1 Binario/2 Pantalla/3 Ascii/4-7 sin asignar
; *** NOTA: lo único cierto es el tipo Basic, los demás valen 2 ***
; 19-20 Longitud de datos (en ficheros Ascii también se rellena este campo)
; 21-22 Dirección de carga
; 23 Primer bloque (Ponerlo a #FF)
; 24-25 Longitud del fichero en bytes (solo 16bits, little endian)
; 26-27 Dirección de ejecución
; 28-63 Sin asignar
;
; Datos mínimos que debe tener la cabecera (el resto a 0)
;--------------------------------------------------------
; 21-22 Dirección de carga
; 24-25 Longitud del fichero en bytes (solo 16bits, little endian)
; 26-27 Dirección de ejecución (En un fichero en Basic es #0000)
; 64-66 Longitud del fichero en bytes, excluyendo la cabecera (24 bits, little endian)
; 67-68 Suma de los bytes 0-66 (16 bits, checksum)

;-----------------------------------------------------------------------------
; Decodificamos la cabecera del AMSDOS
READ_AMSDOS_HEADER MACRO
	IN A,(C)			; Número de usuario (#00-#0F)
	CP #10				; Valores válidos entre #00-#0F
	JP P,trata_error	; A = primer byte de código de error

	; Saltamos los siguientes 17 bytes
	LD A,17
	SKIP_BYTES8

	; Leemos el tipo de fichero
	IN A,(C)
	LD I,A
	
	; Saltamos 2 bytes
	DEFB #ED,#70		; IN F,(C)
	DEFB #ED,#70		; IN F,(C)

	; 21-22 Dirección de carga
	IN L,(C)
	IN H,(C)
	
	; Salta un byte
	DEFB #ED,#70		; IN F,(C)
	
	; 24-25 Longitud del fichero en bytes (solo 16bits, little endian)
	IN E,(C)
	IN D,(C)

	; 26-27 Dirección de ejecución
	IN A,(C)
	LD IXL,A
	IN A,(C)
	LD IXH,A

	; Saltamos los siguientes 100 bytes
	LD A,100
	SKIP_BYTES8
	ENDM

;-----------------------------------------------------------------------------
; Conversor de bytes a cadenas ascii de hexadecimales
; Pasar del macro y convertirlo en una función
HEX_02 MACRO
	OR	#F0
	DAA
	ADD	A,#A0
	ADC	A,#40
	LD	(DE),A
	INC DE
	ENDM

HEX_01 MACRO
	RRA
	RRA
	RRA
	RRA
	HEX_02		
	ENDM

;Input: HL = number to convert, DE = location of ASCII string
;Output: ASCII string at (DE) 
CONVIERTE_HEX MACRO num_bytes
	LD L,(IX+0)
	LD H,(IX+1)
	INC HL
	LD E,(HL)
	INC HL
	LD H,(HL)
	LD L,E		; Puntero a la variable de cadena
	LD D,H
	REPT num_bytes/2
		LD C,(HL)
		INC HL
		LD B,(HL)
		INC HL
		PUSH BC
	ENDM
	REPT num_bytes/2
		POP HL
		LD A,H
		HEX_01
		LD A,H
		HEX_02
		LD A,L
		HEX_01
		LD A,L
		HEX_02
	ENDM
	ENDM

;-----------------------------------------------------------------------------
;	DEFB #ED,#70		; IN F,(C)
;	DEFB #ED,#71		; OUT (C),0
;-----------------------------------------------------------------------------
;	OUTI = DEC B + OUT (C),(HL) + INC HL		; Incrementar B previamente
;-----------------------------------------------------------------------------
