; pasmo --amsdos vdrive.s vdrive.bin

; **********
; * VDRIVE *
; **********

; TODO: Pincharlo al amsdos, carga de snapshots, convertir fecha y hora.
; controlar que los nombres de ficheros no añadan espacios, porque concatena comandos
; OUTI hace cosas raras

; Parchear el firmware correctamente.

; Desactivar las roms superior e inferior para grabar la ram.

; Añadir todas las modificaciones necesarias para que funcione desde rom (reservar ram
; y recuperar ese puntero a la ram reservada en IY; tener en cuenta que no podemos saltar
; entre las roms así por las bravas, por lo que habrá que eliminar la llamada a KL_ROM_SELECT).

;VDRIVE_ROM		EQU 0		; Genera la VDRIVE.ROM

	include "constantes.i"
	include "macros_vdip.i"
	
;IF VDRIVE_ROM
;	ORG #C000			; Inicio de la ROM
;
;	DEFB	1			; Background ROM 
;	DEFB	0			; Mark 0 
;	DEFB	0			; Version 0
;	DEFB	0			; Modification 0 
;ELSE
	ORG #8000
	
inicio
	LD HL,work_space
	LD BC,jump_list
	JP KL_LOG_EXT		; Instalamos los RSXs

work_space	DEFS 4		; Espacio de trabajo para el Kernel
;ENDIF

; Definición de los RSXs
jump_list
	DEFW name_list		; Puntero a la lista de los nombres de los RSXs

;IF VDRIVE_ROM
;inicio
;	JP vdrive_init		; Rutina de inicialización de la ROM
;ENDIF
	JP vdrive
	JP vdrive_in
	JP vdrive_out
	JP cassette
	JP cassette_in
	JP cassette_out
	JP vdrive_reset		; Reinicia el avr y el vdip
	JP vdrive_dir		; Directory (DIR [file])
	JP vdrive_cd		; Change Directory (CD [file]/..)
	JP vdrive_rd		; Read File (RD file)
	JP vdrive_dld		; Delete Directory (DLD file)
	JP vdrive_mkd		; Make Directory (MKD file [datetime])
	JP vdrive_dlf		; Delete File (DLF file)
	JP vdrive_wrf		; Write To File (WRF dword data)
	JP vdrive_opw		; Open File For Write (OPW file [datetime])
	JP vdrive_clf		; Close File (CLF file)
	JP vdrive_rdf		; Read From File (RDF dword)
	JP vdrive_ren		; Rename File (REN file file)
	JP vdrive_opr		; Open File For Read (OPR file [date])
	JP vdrive_sek		; Seek (SEK dword)
	JP vdrive_fs		; Free Space (FS)
	JP vdrive_fse		; Free Space (FSE)
	JP vdrive_idd		; Identify Disk Drive (IDD)
	JP vdrive_idde		; Identify Disk Drive (IDDE)
	JP vdrive_dsn		; Disk Serial Number (DSN)
	JP vdrive_dvl		; Disk Volume Label (DVL)
	JP vdrive_dirt		; Directory File Time Command (DIRT)
	JP vdrive_help		; Imprime la ayuda
	JP vdrive_fwv		; Imprime la versión del firmware
;	JP load_snap		; Carga un snapshot
; ... Añadir nuevos comandos


name_list
;IF VDRIVE_ROM
;	DEFB "VDRIVE INI","T" | #80		; Rutina de inicialización de la ROM
;ENDIF
	DEFB "VDRIV","E" | #80
	DEFB "VDRIVE.I","N" | #80
	DEFB "VDRIVE.OU","T" | #80
	DEFB "TAP","E" | #80
	DEFB "TAPE.I","N" | #80
	DEFB "TAPE.OU","T" | #80
	DEFB "VRESE","T" | #80
	DEFB "VDI","R" | #80
	DEFB "VC","D" | #80
	DEFB "VR","D" | #80
	DEFB "VDL","D" | #80
	DEFB "VMK","D" | #80
	DEFB "VDL","F" | #80
	DEFB "VWR","F" | #80
	DEFB "VOP","W" | #80
	DEFB "VCL","F" | #80
	DEFB "VRD","F" | #80
	DEFB "VRE","N" | #80
	DEFB "VOP","R" | #80
	DEFB "VSE","K" | #80
	DEFB "VF","S" | #80
	DEFB "VFS","E" | #80
	DEFB "VID","D" | #80
	DEFB "VIDD","E" | #80
	DEFB "VDS","N" | #80
	DEFB "VDV","L" | #80
	DEFB "VDIR","T" | #80
	DEFB "VHEL","P" | #80
	DEFB "VFW","V" | #80
;	DEFB "VSNA","P" | #80
	DEFB #00			; Fin de la lista de nombres

; Rutinas de los RSXs
;IF VDRIVE_ROM
; Rutina de inicialización de la ROM
; ENTRADAS: DE contiene la dirección del byte más bajo de memoria usable.
;           HL contiene la dirección del byte más alto de memoria usable.
; SALIDAS: *Si todo fue bien:
;           Bandera de Acarreo activada.
;           DE contiene la nueva dirección del byte más bajo de memoria usable.
;           HL contiene la nueva dirección del byte más alto de memoria usable.
;          *Si todo fue mal:
;           Bandera de Acarreo desactivada.
;           DE y HL deben ser preservados.
; CORROMPE: A, BC y el resto de Banderas de estado.
;
; NOTAS:
; La ROM superior está habilitada y seleccionada, la ROM inferior está deshabilitada.
; La rutina no debe utilizar los registros alternativos.
; La ROM puede asignarse memoría ó de la cima ó de la base ó de ambas, devolviendo en HL y DE los nuevos limites.
; El Acarreo desactivado solo es reconozido a partir de la versión 1.1 del firmware.
; Cuando esta rutina de inicialización regrese, el Kernel almacenará la dirección del byte más alto de memoria; 
; así cada vez que se llame a una entrada de la ROM, se le pasará esta dirección en IY (para acceder a variables en
; la parte baja se deben usar punteros almacenados en la zona superior).
;vdrive_init
;	RET
;ENDIF

; Activamos las redirecciones del firmware	
vdrive
	CALL vdrive_in
	CALL vdrive_out
	RET
	
; Activamos las redirecciones de operaciones de entrada
vdrive_in
	XOR A
	LD (fichero_abierto_in),A

	; Almacena los saltos del firmware
	LD HL,CAS_IN_OPEN
	LD DE,buffer_llamadas_firmware
	LD BC,7*3
	LDIR
	LD HL,CAS_CATALOG
	LD BC,3
	LDIR

	; Parchea los saltos	
	LD HL,tabla_saltos_lectura
	LD DE,CAS_IN_OPEN
	LD BC,7*3
	LDIR
	LD DE,CAS_CATALOG
	LD BC,3
	LDIR

	XOR A
	LD (fichero_abierto_in),A
	RET

; Activamos las redirecciones de las operaciones de salida
vdrive_out
	XOR A
	LD (fichero_abierto_out),A

	; Almacena los saltos del firmware
	LD HL,CAS_OUT_OPEN
	LD DE,buffer_llamadas_firmware+24
	LD BC,5*3
	LDIR

	; Parchea los saltos
	LD HL,tabla_saltos_escritura
	LD DE,CAS_OUT_OPEN
	LD BC,5*3
	LDIR
	
	XOR A
	LD (fichero_abierto_in),A
	RET

; Restaura las entradas de cassette del firmware para CPCs sin disquetera
cassette
	CALL cassette_in
	CALL cassette_out
	RET

cassette_in
	; Restaura los saltos del firmware
	LD HL,buffer_llamadas_firmware
	LD DE,CAS_IN_OPEN
	LD BC,7*3
	LDIR
	LD DE,CAS_CATALOG
	LD BC,3
	LDIR
	RET
	
cassette_out
	; Restaura los saltos del firmware
	LD HL,buffer_llamadas_firmware+24
	LD DE,CAS_OUT_OPEN
	LD BC,5*3
	LDIR
	RET

buffer_llamadas_firmware
	DEFS 13*3	

tabla_saltos_lectura
	JP VD_IN_OPEN
	JP VD_IN_CLOSE
	JP VD_IN_ABANDON
	JP VD_IN_CHAR
	JP VD_IN_DIRECT
	JP VD_RETURN
	JP VD_TEST_EOF
	JP VD_CATALOG
	
tabla_saltos_escritura
	JP VD_OUT_OPEN
	JP VD_OUT_CLOSE
	JP VD_OUT_ABANDON
	JP VD_OUT_CHAR
	JP VD_OUT_DIRECT

; Funciones del firmware que debe soportar el VDrive	
PRINT_DEBUG MACRO txt_msg
	PUSH AF
	PUSH HL
	LD HL,txt_msg
	CALL vvv
	POP HL
	POP AF
	ENDM
	
; Funciones de Entrada
; VD IN OPEN
; Equivalente a CAS IN OPEN
; ENTRADAS: B Longitud del nombre del fichero en caracteres
;           HL Puntero al nombre del fichero
;           DE Dirección del buffer de 2KBs
; SALIDAS: *Si todo fue bien:
;           Bandera de Acarreo activada.
;           Bandera de Cero desactivada.
;           HL dirección del buffer con la cabecera del fichero.
;			DE dirección de carga del fichero
;			BC Longitud el fichero
;			A tipo de fichero
;          *Si había un fichero abierto:
;           Bandera de Acarreo y Cero desactivada.
;           A código de error
;			BC,DE,HL destruidos
;          *Siempre:
;           IX y las otras banderas destruidas.
VD_IN_OPEN
	PRINT_DEBUG txt_CAS_IN_OPEN		
	LD A,(fichero_abierto_in)
	OR A
	JR NZ,hay_fichero_abierto_vio
	CPL
	LD (fichero_abierto_in),A
	LD A,B
	LD (descriptor_cadena_fichero_in),A
	LD A,L
	LD (descriptor_cadena_fichero_in+1),A
	LD A,H
	LD (descriptor_cadena_fichero_in+2),A
	LD A,1
	LD IX,pdescriptor_cadena_fichero_in
;	CALL vdrive_opr
	
	LD A,128
	LD IX,direccion_de_carga_in
	LD HL,buffer_cabecera_amsdos_in
	LD (IX+0),L
	LD (IX+1),H
	LD (IX+2),A
	XOR A
	LD (IX+3),A
	LD A,2
;	CALL vdrive_rdf	

	LD IX,buffer_cabecera_amsdos_in
	LD E,(IX+21)
	LD D,(IX+22)		; Dirección de carga
;	LD (direccion_de_carga_in),DE
	LD C,(IX+24)
	LD B,(IX+25)		; Longitud fichero
	LD (longitud_fichero_in),BC
	LD HL,buffer_cabecera_amsdos_in
	SCF				; Carry true
	SBC A,A			; Zero false
	LD A,(IX+18)	; Tipo fichero
	RET
hay_fichero_abierto_vio
	SCF
	SBC A,A
	CCF
	RET

direccion_de_carga_in
	DEFS 2
longitud_fichero_in
	DEFS 2
descriptor_cadena_fichero_in
	DEFS 3
buffer_cabecera_amsdos_in
	DEFS 128
fichero_abierto_in
	DEFS 1
pdescriptor_cadena_fichero_in
	DEFW descriptor_cadena_fichero_in

; VD IN CLOSE 
; Equivalente a CAS IN CLOSE
; Si el fichero fue cerrado con éxito, entonces Acarreo activado y A destruido.
; Si no había un fichero abierto, entonces Acarreo falso y A código de error
VD_IN_CLOSE
	PRINT_DEBUG txt_CAS_IN_CLOSE	
	LD A,(fichero_abierto_in)
	OR A
	JR Z,nofile_vd_in_close
	PUSH IX
	LD A,1
	LD IX,pdescriptor_cadena_fichero_in
;	CALL vdrive_clf
	POP IX
	XOR A
	LD (fichero_abierto_in),A
	SCF
	RET
nofile_vd_in_close
	CCF
	RET
	
; VD IN ABANDON
; Equivalente a CAS IN ABANDON
; AF,BC,DE,HL destruidos.
VD_IN_ABANDON
	PRINT_DEBUG txt_CAS_IN_ABANDON	
	LD A,(fichero_abierto_in)
	OR A
	RET Z		; JR Z,exit_vd_in_abandon
	PUSH IX
	LD A,1
	LD IX,pdescriptor_cadena_fichero_in
;	CALL vdrive_clf
	POP IX
	XOR A
	LD (fichero_abierto_in),A
;exit_vd_in_abandon
;	SCF
	RET

; VD IN CHAR
; Equivalente a CAS IN CHAR
; Destruye IX y las banderas no utilizadas
; NOTA: Ahora mismo devuelve siempre error.
VD_IN_CHAR
	PRINT_DEBUG txt_CAS_IN_CHAR 	
	LD IXH,A
	LD A,(fichero_abierto_in)
	OR A
	JR NZ,error_vd_in_char
	; Leer un solo byte del fichero abierto
		
error_vd_in_char
	SCF
	SBC A,A
	CCF
	LD A,IXH
	RET

; VD IN DIRECT
; Equivalente a CAS IN DIRECT
; Si el fichero fue leido con éxito, Acarreo activado y A destruido.
; BC,DE,HL y el resto de banderas destruidas.

;Reads an entire file directly into memory.
;Entry
;      HL contains the address where the file is to be placed in RAM.
;Exit
;      If the operation was successful, then:
;            Carry is true.
;            Zero is false.
;            HL contains the entry address.
;            A is corrupt.
;      If it was not open, then:
;            Carry and Zero are both false.
;            HL is corrupt.
;            A holds an error code (664/6128) or is corrupt (464).
;      If ESC was pressed:
;            Carry is false.
;            Zero is true.
;            HL is corrupt.
;            A holds an error code (664/6128 only).
;      In all cases, BC, DE and IX and the other flags are corrupt, and the others are preserved.
VD_IN_DIRECT
	PRINT_DEBUG txt_CAS_IN_DIRECT 	
	LD A,(fichero_abierto_in)
	OR A
	JR Z,error_vd_in_direct
	LD A,2
	LD IX,direccion_de_carga_in
	LD (IX+0),L
	LD (IX+1),H
;	CALL vdrive_rdf	
	LD HL,(buffer_cabecera_amsdos_in+26)
	SCF
	SBC A,A
	RET
error_vd_in_direct
	SCF
	SBC A,A
	CCF
	RET

; VD RETURN
; Equivalente a CAS RETURN
; NOTA: Ahora mismo pasa olimpicamente.
VD_RETURN
	PRINT_DEBUG txt_CAS_RETURN 		
	PUSH AF
	LD A,(fichero_abierto_in)
	OR A
	JR Z,error_vd_return
error_vd_return
	POP AF
	RET

; VD TEST EOF
; Equivalente a TEST EOF
; Si se alcanzó el final del fichero, Acarreo y Cero desactivados, A destruido.
; NOTA: Ahora mismo devuelve siempre fin de fichero.
VD_TEST_EOF
	PRINT_DEBUG txt_CAS_TEST_EOF 	
	LD A,(fichero_abierto_in)
	OR A
	JR Z,error_test_eof
error_test_eof
	SCF
	SBC A,A
	CCF
	RET

; VD CATALOG
; Equivalente a CAS CATALOG
;Creates a catalogue of all the files on the tape.
;Entry
;     DE contains the address of the 2K buffer to be used to store the information.
;Exit
;      If the operation was successful, then Carry is true, Zero is false, and A is corrupt.
;      If the read stream is already being used, then Carry and Zero are false, and A holds an error code (664/6128 or is corrupt (for the 464).
;      In all cases, BC, DE, HL, IX and the other flags are corrupt and all other registers are preserved.
VD_CATALOG
	PRINT_DEBUG txt_CAS_CATALOG 	
	LD A,0
;	CALL vdrive_dir	
	SCF			; Carry true
	SBC A,A		; Zero false
	RET

; Funciones de Salida
; VD OUT OPEN
; Equivalente a CAS OUT OPEN
; ENTRADAS: B Longitud del nombre del fichero en caracteres
;           HL Puntero al nombre del fichero
;           DE Dirección del buffer de 2KBs
; SALIDAS: *Si todo fue bien:
;           Bandera de Acarreo activada.
;           Bandera de Cero desactivada.
;           HL dirección del buffer con la cabecera del fichero.
;			A,BC,DE y el resto de banderas destruidas
;          *Si hay un fichero abierto:
;           Bandera de Acarreo desactivada.
;           Bandera de Cero desactivada.
;           A código de error
;			HL destruido
; 			BC,DE,IX y el resto de banderas destruidas
VD_OUT_OPEN
	PRINT_DEBUG txt_CAS_OUT_OPEN	
	LD A,(fichero_abierto_out)
	OR A
	JR NZ,hay_fichero_abierto_voo
	CPL
	LD (fichero_abierto_out),A
	LD A,B
	LD (descriptor_cadena_fichero_out),A
	LD A,L
	LD (descriptor_cadena_fichero_out+1),A
	LD A,H
	LD (descriptor_cadena_fichero_out+2),A
	LD A,1
	LD IX,pdescriptor_cadena_fichero_out
;	CALL vdrive_opw
	; HL debe apuntar a la cabecera
	LD HL,buffer_cabecera_amsdos_out
	SCF
	SBC A,A
	RET
hay_fichero_abierto_voo
	SCF
	SBC A,A
	CCF
	RET
	
fichero_abierto_out
	DEFS 0
descriptor_cadena_fichero_out
	DEFS 3
buffer_cabecera_amsdos_out
	DEFS 128
pdescriptor_cadena_fichero_out
	DEFW descriptor_cadena_fichero_out

; VD OUT CLOSE
; Equivalente a CAS OUT CLOSE
; Si el fichero fue cerrado con éxito, entonces Acarreo activado, Cero desactivado y A destruido.
; Si no había un fichero abierto, entonces Acarreo y Cero desactivado y A código de error
; Siempre BC,DE,HL,IX y las otras banderas destruidas
VD_OUT_CLOSE
	PRINT_DEBUG txt_CAS_OUT_CLOSE	
	LD A,(fichero_abierto_out)
	OR A
	JR Z,nofile_vd_out_close
	LD A,1
	LD IX,pdescriptor_cadena_fichero_out
;	CALL vdrive_clf
	XOR A
	LD (fichero_abierto_out),A
	SCF
	SBC A,A
	RET
nofile_vd_out_close
	SCF
	SBC A,A
	CCF
	RET
	
; VD OUT ABANDON
; Equivalente a CAS OUT ABANDON
VD_OUT_ABANDON
	PRINT_DEBUG txt_CAS_OUT_ABANDON	
	LD A,(fichero_abierto_out)
	OR A
	RET Z		;JR Z,exit_vd_out_abandon
	PUSH IX
	LD A,1
	LD IX,pdescriptor_cadena_fichero_out
;	CALL vdrive_clf
	POP IX
	XOR A
	LD (fichero_abierto_out),A
;exit_vd_out_abandon
	RET
	
; VD OUT CHAR
; Equivalente a CAS OUT CHAR
; Entrada: A el byte a escribir
; NOTA: No escribe nada en el fichero. 
VD_OUT_CHAR
	PRINT_DEBUG txt_CAS_OUT_CHAR	
	LD A,(fichero_abierto_out)
	OR A
	JR Z,exit_vd_out_char
	SCF
	SBC A,A
	RET
exit_vd_out_char
	SCF
	SBC A,A
	CCF
	RET

; VD OUT DIRECT
; Equivalente a CAS OUT DIRECT
; Entry
;	HL contains the address of the data which is to be written to tape.
;	DE contains the length of this data.
;	BC contains the execution address.
;	A contains the file type.
; Exit
;	If the operation was successful, then Carry is true, Zero is false, and A is corrupt.
;	If the file was not open, Carry and Zero are false, A holds an error number (664/6128) or is corrupt (464).
;	If ESC was pressed, then Carry is false, Zero is true, and A holds an error code (664/6128 only).
;	In all cases BC, DE, HL, IX and the other flags are corrupt, and the others are preserved.
VD_OUT_DIRECT
	PRINT_DEBUG txt_CAS_OUT_DIRECT	
	LD A,(fichero_abierto_out)
	OR A
	JR Z,exit_vd_out_direct
	; Rellenamos la cabecera
	LD IX,buffer_cabecera_amsdos_out
	LD (IX+21),L
	LD (IX+22),H		; Dirección de carga
	LD (IX+24),E
	LD (IX+25),D		; Longitud fichero
	LD (IX+26),C
	LD (IX+27),B		; Dirección de ejecución
	LD (IX+18),A		; Tipo fichero
	; Guardamos la cabecera
	LD IX,direccion_de_carga_out	
	LD HL,buffer_cabecera_amsdos_out
	LD (IX+0),L
	LD (IX+1),H			; Dirección en RAM de los bytes
	LD HL,128
	LD (IX+2),L
	LD (IX+3),H			; Número de bytes
	LD A,2
;	CALL vdrive_wrf	
	; Guardamos el fichero
	LD IX,buffer_cabecera_amsdos_out
	LD L,(IX+21)
	LD H,(IX+22)		; Dirección de carga
	LD E,(IX+24)
	LD D,(IX+25)		; Longitud fichero
	LD IX,direccion_de_carga_out	
	LD (IX+0),L
	LD (IX+1),H			; Dirección en RAM de los bytes
	LD (IX+2),E
	LD (IX+3),D			; Número de bytes
	LD A,2
;	CALL vdrive_wrf	
	SCF
	SBC A,A
	RET
exit_vd_out_direct
	SCF
	SBC A,A
	CCF
	RET

direccion_de_carga_out
	DEFS 2
longitud_fichero_out
	DEFS 2

; Reinicia el avr y el vdip                
vdrive_reset
	XOR A
	LD BC,RESET_PORT
	OUT (C),A
	RET

; Directory (DIR [file])                   
vdrive_dir	
	SEND_CMD_FILE_OPTIONAL CMD_VDIP_DIR
	DIR_VS_ERROR	; Se lee un byte, si no es INTRO entonces ERROR
	PRINT_DIR
	RET

; Change Directory (CD [file]/..)          
vdrive_cd	
	SEND_CMD_1_FILE CMD_VDIP_CD
	PROMPT_VS_ERROR
	RET

; Read File (RD file)                      
vdrive_rd	
	SEND_CMD_1_FILE CMD_VDIP_RD
	READ_AMSDOS_HEADER			; Decodificamos la cabecera del AMSDOS
	; HL = Dir. Carga / DE = Longitud / IX = Dir. Ejecución / I = Tipo de fichero
	PUSH IX						; Almacenamos la dirección de ejecución
	PUSH DE						; Almacenamos la longitud
	READ_BYTES16				; Cargamos el fichero en RAM
	PROMPT_VS_ERROR
	POP DE						; Recuperamos la longitud
	; Ejecutamos el programa
	POP HL						; Recuperamos la dirección de ejecución
	LD A,H
	OR L
	JR Z,no_binario_autoejecutable
	JP (HL)						; Ejecutamos el programa
no_binario_autoejecutable
	; Detectamos el tipo de fichero
	LD A,I
	OR A						; CP 0
	JR Z,es_basic
	CP 1
	RET NZ						; No es basic protegido (Scr, Ascii ó Bin)
es_basic
	EX DE,HL					; Longitud del programa en HL
	LD BC,#0170
	ADD HL,BC
	; Seleccionamos la rom del Basic (Rom 0)
	LD C,#00
	CALL KL_ROM_SELECT
	LD A,(#C002)	; Obtenemos la versión de la rom 
	OR A						; CP #00
	JP Z,es_cpc464
	; Indicamos la longitud del programa para el CPC664 y el CPC6128
	LD (#AE66),HL
	LD (#AE68),HL
	LD (#AE6A),HL
	LD (#AE6C),HL
	CP #01
	JP NZ,#EA78					; Ejecutamos el basic en un CPC6128
es_cpc664
	JP #EA7D					; Ejecutamos el basic en un CPC664
es_cpc464
	; Indicamos la longitud del programa para el CPC464
	LD (#AE83),HL
	LD (#AE85),HL
	LD (#AE87),HL
	LD (#AE89),HL
	JP #E9BD					; Ejecutamos el basic en un CPC464

; Delete Directory (DLD file)              
vdrive_dld	
	SEND_CMD_1_FILE CMD_VDIP_DLD
	PROMPT_VS_ERROR
	RET

; Make Directory (MKD file [datetime])     
vdrive_mkd	
	SEND_CMD_FILE_DATETIME CMD_VDIP_MKD
	PROMPT_VS_ERROR
	RET

; Delete File (DLF file)                   
vdrive_dlf	
	SEND_CMD_1_FILE CMD_VDIP_DLF
	PROMPT_VS_ERROR
	RET

; Write To File (WRF dword data)           
vdrive_wrf	
	SEND_CMD_2_DWORD CMD_VDIP_WRF
;	WRF_EXEC_VS_ERROR
	WRITE_BYTES16		; Escribimos bytes en el puerto
	PROMPT_VS_ERROR
	RET

; Open File For Write (OPW file [datetime])
vdrive_opw	
	SEND_CMD_FILE_DATETIME CMD_VDIP_OPW
	PROMPT_VS_ERROR
	RET

; Close File (CLF file)                    
vdrive_clf	
	SEND_CMD_1_FILE CMD_VDIP_CLF
	PROMPT_VS_ERROR
	RET

; Read From File (RDF dword)               
vdrive_rdf	
	SEND_CMD_2_DWORD CMD_VDIP_RDF
	READ_BYTES16		; Leemos bytes del puerto
	PROMPT_VS_ERROR
	RET

; Rename File (REN file file)              
vdrive_ren	
	SEND_CMD_2_FILE CMD_VDIP_REN
	PROMPT_VS_ERROR
	RET

; Open File For Read (OPR file [date])     
vdrive_opr	
	SEND_CMD_FILE_DATE CMD_VDIP_OPR
	PROMPT_VS_ERROR
	RET

; Seek (SEK dword)                         
vdrive_sek	
	SEND_CMD_1_DWORD CMD_VDIP_SEK
	PROMPT_VS_ERROR
	RET

; Free Space (FS)                          
vdrive_fs
; Free Space (FSE)                         
vdrive_fse	
	SEND_CMD_VAR_HEX CMD_VDIP_FSE,6*2	; 6 bytes/48 bits
	RESULT_VS_NO_DISK
;	DEFB #ED,#70		; Ignoramos un byte adicional
	CONVIERTE_HEX 6
	RET

; Identify Disk Drive (IDD)                
vdrive_idd	
; Identify Disk Drive (IDDE)               
vdrive_idde	
	SEND_CMD_0_PARAM CMD_VDIP_IDDE
	IDDE_VS_NO_DISK
	RET

; Disk Serial Number (DSN)    
vdrive_dsn	
	SEND_CMD_VAR_HEX CMD_VDIP_DSN,4*2		; 4 bytes/32 bits
	RESULT_VS_NO_DISK
;	DEFB #ED,#70		; Ignoramos un byte adicional
	CONVIERTE_HEX 4
	RET

; Disk Volume Label (DVL)                  
vdrive_dvl	
	SEND_CMD_VAR CMD_VDIP_DVL,11	; 11 bytes/11 caracteres
	RESULT_VS_NO_DISK
	RET

; Directory File Time Command (DIRT)       
vdrive_dirt	
	SEND_CMD_VAR_DIRT CMD_VDIP_DIRT,10	; 10 bytes
	RET

; Imprime la versión del firmware (FWV)
vdrive_fwv
	SEND_CMD_0_PARAM CMD_VDIP_FWV
	PRINT_VERSION
	RET

; Carga un snapshot
;load_snap		
;	RET

; Imprime la ayuda
vdrive_help
	LD HL,texto_ayuda
	CALL print_texto
	RET	

print_texto
	LD A,(HL)
	CP #FF
	RET Z
	CALL TXT_OUTPUT
	INC HL
	JR print_texto
	
	include "error.s"		; Rutinas de manejo de errores

texto_ayuda
	include "ayuda.s"

vvv
	CALL print_texto
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
	CALL TXT_OUTPUT
	RET

; Cadenas de depuración
txt_CAS_IN_OPEN		DEFB "CAS_IN_OPEN",255
txt_CAS_IN_CLOSE	DEFB "CAS_IN_CLOSE",255
txt_CAS_IN_ABANDON	DEFB "CAS_IN_ABANDON",255
txt_CAS_IN_CHAR 	DEFB "CAS_IN_CHAR",255
txt_CAS_IN_DIRECT 	DEFB "CAS_IN_DIRECT",255
txt_CAS_RETURN 		DEFB "CAS_RETURN",255
txt_CAS_TEST_EOF 	DEFB "CAS_TEST_EOF",255
txt_CAS_CATALOG 	DEFB "CAS_CATALOG",255
txt_CAS_OUT_OPEN	DEFB "CAS_OUT_OPEN",255
txt_CAS_OUT_CLOSE	DEFB "CAS_OUT_CLOSE",255
txt_CAS_OUT_ABANDON	DEFB "CAS_OUT_ABANDON",255
txt_CAS_OUT_CHAR	DEFB "CAS_OUT_CHAR",255
txt_CAS_OUT_DIRECT	DEFB "CAS_OUT_DIRECT",255

	END inicio
