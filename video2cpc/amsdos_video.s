; Visualiza un video de 128x96 pixels en un CPC con vdrive

; CONSTANTES

; Firmware de lectura de ficheros
CAS_IN_OPEN	EQU #BC77
CAS_IN_CLOSE	EQU #BC7A
CAS_IN_CHAR	EQU #BC80

; Constantes de la pantalla
BASE_PANTALLA		EQU #C000
ALTO_LINEA		EQU #0800
ALTO_PANTALLA		EQU 96
FACTOR			EQU #C000 + 64

; Dimensiones del video
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
;	DI
;	IM 1
;	LD HL,#C9FB	; EI (#FB) + RET (#C9)
;	LD (#0038),HL	; Habrá un retardo de 4 NOPs al responder a las interrupciones
;	LD SP,#C000	; Inicializamos la pila
;	EI

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

      ; open file for reading
      LD B,end_nombre_video - nombre_video
      LD HL,nombre_video
      LD DE,buffer_2kb
      CALL CAS_IN_OPEN

decrunch_frame
	; Esperamos al refresco
	LD B,#F5
wait_vbl02
	IN A,(C)
	RRA
	JR NC,wait_vbl02

	LD IX,tabla_scanlines - 2

	; Leemos un byte
	PUSH IX
	CALL CAS_IN_CHAR
	POP IX
test_end_video
	CP CMP_END_VIDEO
	JP Z,end_of_file
	OR A			; No hay cambios en la paleta
	JR Z,decrunch_scanline
establece_paleta
;	LD A,(HL)		; A = Número de colores

bucle_establece_paleta	
	PUSH AF
	PUSH IX
	CALL CAS_IN_CHAR
	POP IX
	LD D,A		; D = Pluma
	PUSH IX
	CALL CAS_IN_CHAR
	POP IX
	LD E,A		; E = Color

	LD B,#7F
	OUT (C),D
	OUT (C),E

	POP AF
	DEC A
	JR NZ,bucle_establece_paleta

	; Descomprime frame
decrunch_scanline
	INC IX
	INC IX
	LD D,(IX + 0)
	LD E,(IX + 1)	; DE = Dir. Scanline
;	CALL CAS_IN_CHAR
;	LD E,A
;	CALL CAS_IN_CHAR
;	LD D,A		; DE = Dir. Scanline
decrunch_bytes
	PUSH IX
	CALL CAS_IN_CHAR
	POP IX
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
	LD B,A
	EX DE,HL
bucle_copy
;	PUSH AF
	PUSH IX
	CALL CAS_IN_CHAR
	POP IX
	LD (HL),A
	INC HL
;	POP AF
;	DEC A
;	JR NZ,bucle_copy
	DJNZ bucle_copy
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
	LD B,A
	PUSH IX
	CALL CAS_IN_CHAR
	POP IX
bucle_repeat
	LD (HL),A
	INC HL
;	DEC A
;	JR NZ,bucle_repeat
	DJNZ bucle_repeat
	EX DE,HL
	JR decrunch_bytes

end_of_file
	CALL CAS_IN_CLOSE
	JP reinicia_video

; El video a cargar desde el vdrive
nombre_video
	DEFB "peli.vid"
end_nombre_video
tabla_scanlines
	DEFS ALTO_PANTALLA * 2
buffer_2kb
	DEFS 2048

	END inicio
