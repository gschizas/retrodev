; ****************
; * Constantes.i *
; ****************

; Llamadas al firmware
KL_LOG_EXT		EQU #BCD1
TXT_OUTPUT		EQU #BB5A
KL_ROM_SELECT	EQU #B90F

; Operaciones de entrada con Cinta
CAS_IN_OPEN		EQU #BC77
CAS_IN_CLOSE	EQU #BC7A
CAS_IN_ABANDON	EQU #BC7D
CAS_IN_CHAR 	EQU #BC80
CAS_IN_DIRECT 	EQU #BC83
CAS_RETURN 		EQU #BC86
CAS_TEST_EOF 	EQU #BC89
CAS_CATALOG 	EQU #BC9B

; Operaciones de salida con Cinta
CAS_OUT_OPEN	EQU #BC8C
CAS_OUT_CLOSE	EQU #BC8F
CAS_OUT_ABANDON	EQU #BC92
CAS_OUT_CHAR	EQU #BC95
CAS_OUT_DIRECT	EQU #BC98

; Constantes
VDIP_PORT	equ #FC00		; Puerto usado por el proyecto
RESET_PORT	equ #FC01		; Puerto para reiniciar el AVR y el VDIP

; Comandos del VDIP
CMD_VDIP_DIR	equ #01		; Directory (DIR [file])                   
CMD_VDIP_CD		equ #02		; Change Directory (CD [file]/..)          
CMD_VDIP_RD		equ #04   	; Read File (RD file)                      
CMD_VDIP_DLD	equ #05		; Delete Directory (DLD file)              
CMD_VDIP_MKD	equ #06   	; Make Directory (MKD file [datetime])     
CMD_VDIP_DLF	equ #07   	; Delete File (DLF file)                   
CMD_VDIP_WRF	equ #08  	; Write To File (WRF dword data)           
CMD_VDIP_OPW	equ #09   	; Open File For Write (OPW file [datetime])
CMD_VDIP_CLF	equ #0a   	; Close File (CLF file)                    
CMD_VDIP_RDF	equ #0b   	; Read From File (RDF dword)               
CMD_VDIP_REN	equ #0c  	; Rename File (REN file file)              
CMD_VDIP_OPR	equ #0e   	; Open File For Read (OPR file [date])     
CMD_VDIP_SEK	equ #28   	; Seek (SEK dword)                         
CMD_VDIP_FS		equ #12   	; Free Space (FS)                          
CMD_VDIP_FSE	equ #93   	; Free Space (FSE)                         
CMD_VDIP_IDD	equ #0f  	; Identify Disk Drive (IDD)                
CMD_VDIP_IDDE	equ #94   	; Identify Disk Drive (IDDE)               
CMD_VDIP_DSN	equ #2d   	; Disk Serial Number (DSN)                 
CMD_VDIP_DVL	equ #2e		; Disk Volume Label (DVL)                  
CMD_VDIP_DIRT	equ #2f   	; Directory File Time Command (DIRT)       
CMD_VDIP_FWV	equ #13		; Disk Volume Label (DVL)                  
; ... Añadir nuevos comandos

; Constantes útiles para la comunicación con el VDIP
ESPACIO			equ #20
INTRO			equ #0D
PROMPT			equ #3E
; Salto de línea
LF				equ #0A
CR				equ #0D

