; Visualiza un video de 128x96 pixels en un CPC con vdrive

; CONSTANTES
; Vdrive
VDIP_PORT	EQU #FF7E	; Puerto usado por el proyecto
RESET_PORT	EQU #FF7F	; Puerto para reiniciar el AVR y el VDIP
CMD_VDIP_RD	EQU #04   	; Read File (RD file)                      
ESPACIO		EQU #20
INTRO		EQU #0D
PROMPT		EQU #3E

; Dimensiones del video
BASE_PANTALLA		EQU #C000
ALTO_LINEA		EQU #0800
ALTO_PANTALLA		EQU 96
FACTOR			EQU #C000 + 64
ANCHO_EN_BYTES		EQU 64	; 64 bytes (128 pixels en modo 0)
ALTO_EN_CARACTERES	EQU 24	; (96 / 8) * 2 (scanlines)

; Comandos del compresor
CMP_COPY		EQU #00
CMP_SKIP		EQU ANCHO_EN_BYTES
CMP_REPEAT		EQU ANCHO_EN_BYTES * 2
CMP_END_SCANLINE 	EQU #FD
CMP_END_SCREEN		EQU #FE
CMP_END_VIDEO		EQU #FF

; Hardware del CPC
; Paleta del CPC
NEGRO              EQU 64+20 		; Negro
AZUL               EQU 64+4 		; Azul
AZUL_BRILLANTE     EQU 64+21 		; Azul Brillante
ROJO               EQU 64+28 		; Rojo
MAGENTA            EQU 64+24 		; Magenta
MALVA              EQU 64+29 		; Malva
ROJO_BRILLANTE     EQU 64+12 		; Rojo Brillante
PURPURA            EQU 64+5 		; Purpura
MAGENTA_BRILLANTE  EQU 64+13 		; Magenta Brillante
VERDE              EQU 64+22 		; Verde
CIAN               EQU 64+6 		; Cian
AZUL_CIELO         EQU 64+23 		; Azul Cielo
AMARILLO           EQU 64+30 		; Amarillo
BLANCO             EQU 64+0 		; Blanco
AZUL_PASTEL        EQU 64+31 		; Azul Pastel
NARANJA            EQU 64+14 		; Naranja
ROSA               EQU 64+7 		; Rosa
MAGENTA_PASTEL     EQU 64+15 		; Magenta Pastel
VERDE_BRILLANTE    EQU 64+18 		; Verde Brillante
VERDE_MAR          EQU 64+2 		; Verde Mar
CIAN_BRILLANTE     EQU 64+19 		; Cian Brillante
LIMA               EQU 64+26 		; Lima
VERDE_PASTEL       EQU 64+25 		; Verde Pastel
CIAN_PASTEL        EQU 64+27 		; Cian Pastel
AMARILLO_BRILLANTE EQU 64+10 		; Amarillo Brillante
AMARILLO_PASTEL    EQU 64+3 		; Amarillo Pastel
BLANCO_BRILLANTE   EQU 64+11 		; Blanco Brillante

	ORG #4000
inicio
	; Tomamos el control del sistema
	DI
	IM 1
	LD HL,#C9FB	; EI (#FB) + RET (#C9)
	LD (#0038),HL	; Habrá un retardo de 4 NOPs al responder a las interrupciones
	LD SP,#C000	; Inicializamos la pila
	EI

genera_tabla_scanlines
; Rellenamos la tabla con los punteros a los scanlines de la zona de juego
	LD HL,BASE_PANTALLA
	LD DE,ALTO_LINEA*2 
	LD A,ALTO_PANTALLA - 1
	LD BC,FACTOR
	LD IX,tabla_scanlines

	LD (IX+0),H
	LD (IX+1),L
loop_gts
	ADD HL,DE
	JR NC,next_gts
	ADD HL,BC
next_gts
	INC IX
	INC IX
	LD (IX + 0),H
	LD (IX + 1),L
	DEC A
	JR NZ,loop_gts

reinicia_video
	; Esperamos al refresco
	LD B,#F5
wait_vbl01
	IN A,(C)
	RRA
	JR NC,wait_vbl01

	; Reiniciamos el Vdip
;	XOR A
;	LD BC,RESET_PORT
;	OUT (C),A

	; Desconectamos las ROMs y establecemos el modo de pantalla
	LD B,#7F
modo_de_pantalla
	LD C,#8C	; ROM_OFF | MODE 0
	OUT (C),C

	; Tintas a negro
	LD C,NEGRO
	XOR A
bucle_apagon
	OUT (C),A
	OUT (C),C
	INC A
	CP #10
	JR NZ,bucle_apagon
	INC A
	LD C,ROJO
	OUT (C),A
	OUT (C),C

	; Ancho de pantalla
	LD BC,#BC01
	OUT (C),C
	INC B
	LD C,ANCHO_EN_BYTES/2
	OUT (C),C

	; Desplazamiento desde la izquierda
	DEC B
	LD C,#02
	OUT (C),C
	INC B
	LD C,26+ANCHO_EN_BYTES/4
	OUT (C),C

	; Alto de pantalla
	DEC B
	LD C,#06
	OUT (C),C
	INC B
	LD C,ALTO_EN_CARACTERES
	OUT (C),C
	
	; Desplazamiento hacía arriba
	DEC B
	LD C,#07
	OUT (C),C
	INC B
	LD C,17 + ((ALTO_EN_CARACTERES * 8) / 14)
	OUT (C),C

	; Inicializamos la pantalla en #C000
	DEC B
	LD C,#0C
	OUT (C),C
	INC B
	LD C,#30
	OUT (C),C
	DEC B
	LD C,#0D
	OUT (C),C
	INC B
	LD C,#00
	OUT (C),C

	; Inicializamos la pantalla a 0
	XOR A
	LD HL,#C000
	LD (HL),A
	LD DE,#C001
	LD BC,#4000-1
	LDIR

;	SEND_CMD CMD_VDIP_RD
	LD BC,VDIP_PORT
	LD A,CMD_VDIP_RD
	OUT (C),A

;	SEND_BYTE ESPACIO
	LD A,ESPACIO
	OUT (C),A

;	SEND_FILENAME
	LD HL,nombre_video
	LD A,(HL)	; Longitud del nombre del fichero
	INC HL		; Puntero al nombre del fichero
bucle_send_filename
	LD D,(HL)
	OUT (C),D
	INC HL
	DEC A
	JR NZ,bucle_send_filename

;	SEND_BYTE INTRO
	LD A,INTRO
	OUT (C),A

decrunch_frame
	; Esperamos al refresco
	LD B,#F5
wait_vbl02
	IN A,(C)
	RRA
	JR NC,wait_vbl02

	LD IX,tabla_scanlines - 2

	; Leemos un byte
	LD B,#FF
	IN A,(C)		; INC HL	LD A,(HL)
test_end_video
	CP CMP_END_VIDEO
	JP Z,bucle_infinito
	OR A			; No hay cambios en la paleta
	JR Z,decrunch_scanline
establece_paleta
;	LD A,(HL)		; A = Número de colores

bucle_establece_paleta	
	LD B,#FF
	IN D,(C)	; D = Pluma
	IN E,(C)	; E = Color

	LD B,#7F
	OUT (C),D
	OUT (C),E

	DEC A
	JR NZ,bucle_establece_paleta

	LD B,#FF
	; Descomprime frame
decrunch_scanline
	INC IX
	INC IX
	LD D,(IX + 0)
	LD E,(IX + 1)	; DE = Dir. Scanline

;	IN A,(C)		; INC HL	LD A,(HL)
;test_end_screen
;	CP CMP_END_SCREEN
;	JP Z,decrunch_frame
;	LD E,A
;	IN D,(C)	; DE = Dir. Scanline
;	INC HL
decrunch_bytes
	IN A,(C)
test_end_screen
	CP CMP_END_SCREEN
	JP Z,decrunch_frame
test_end_scanline
	CP CMP_END_SCANLINE
	JP Z,decrunch_scanline
test_copy
	CP CMP_COPY + ANCHO_EN_BYTES
	JR NC,test_skip
	; Procesamos el copy
	INC A
	EX DE,HL
bucle_copy
	IN D,(C)
	LD (HL),D
	INC HL
	DEC A
	JR NZ,bucle_copy
	EX DE,HL
	JR decrunch_bytes
test_skip
	CP CMP_SKIP + ANCHO_EN_BYTES
	JR NC,test_repeat
	; Procesamos el skip
	SUB CMP_SKIP - 1
	LD L,A
	LD H,#00
	ADD HL,DE
	EX DE,HL	
	JR decrunch_bytes
test_repeat	
	; Procesamos el repeat
	SUB CMP_REPEAT - 1
	EX DE,HL
	IN D,(C)
bucle_repeat
	LD (HL),D
	INC HL
	DEC A
	JR NZ,bucle_repeat
	EX DE,HL
	JR decrunch_bytes

bucle_infinito
;	LD HL,video - 1
;	JP decrunch_frame

;	MACRO PROMPT_VS_ERROR
;	LD BC,VDIP_PORT
	IN A,(C)			
	CP PROMPT		; ¿Se ejecutó el comando sin problemas?
	JP NZ,trata_error	; A = primer byte de código de error
	IN A,(C)
	CP INTRO		; No debería de pasar nada, pero y si pasa xDDD
	JP NZ,trata_error	; A = primer byte de código de error
	JP reinicia_video

trata_error
	CP 'B'
	JR Z,_error_bad_command
	CP 'C'
	JR Z,_error_command_failed
	CP 'D'
	JR Z,_error_disk_full
	CP 'R'
	JR Z,_error_read_only
	CP 'F'
	JR Z,_error_con_f
	CP 'N'
	JR Z,_error_con_n
_error_desconocido
_bucle_error_desconocido
	IN A,(C)
	JR NZ,_bucle_error_desconocido
	JP reinicia_video
_error_bad_command
_error_command_failed
_error_disk_full
_error_read_only
	JR _fin_trata_error_02
_error_con_f
	CP 'I'
	JR Z,_error_invalid
	CP 'N'
	JR Z,_error_filename_invalid
	CP 'O'
	JR Z,_error_file_open
	JR _error_desconocido
_error_con_n
	CP 'D'
	JR Z,_error_no_disk
	CP 'E'
	JR Z,_error_dir_not_empty
	CP 'U'
	JR Z,_error_no_upgrade
	JR _error_desconocido
_error_invalid
_error_filename_invalid
_error_file_open
_error_no_disk
_error_dir_not_empty
_error_no_upgrade
_fin_trata_error_02
	DEFB #ED,#70		; IN F,(C)
_fin_trata_error_01
	DEFB #ED,#70		; IN F,(C)
	JP reinicia_video

; El video a cargar desde el vdrive
nombre_video
      DEFB 8,"peli.vid"

tabla_scanlines
	DEFS ALTO_PANTALLA * 2

	END inicio
