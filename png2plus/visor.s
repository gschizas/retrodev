
    ORG #2000

; MACROS
; Esperamos el refresco de pantalla
WAIT_VBL MACRO
    LOCAL loop_wait_vbl
    LD B,#F5
loop_wait_vbl
    IN A,(C)
    RRA
    JR NC,loop_wait_vbl
    ENDM

; Muestra los registros del Asic en #4000
ASIC_ON MACRO
    LD BC,#7FB8
    OUT (C),C
    ENDM

; Esconde los registros del Asic en #4000
ASIC_OFF MACRO
    LD BC,#7FA0
    OUT (C),C
    ENDM

; Reescribe la paleta del Asic
ASIC_PUT_PALETTE MACRO paleta, longitud
    LD DE,#6400
    LD HL,paleta
    LD BC,longitud
    LDIR
    ENDM

; Inicializamos la base de la pantalla
CRTC_BASE MACRO valor
    LD BC,#BC0C
    OUT (C),C
    LD BC,#BD00+valor
    OUT (C),C
    LD BC,#BC0D
    OUT (C),C
    LD BC,#BD00
    OUT (C),C
    ENDM

; Carga un fichero
LOAD_FILE MACRO filename,len_filename,load_address
    LD HL,filename
    LD B,len_filename
    CALL #BC77  ; CAS_IN_OPEN (Abre un fichero para lectura y lee la cabecera de Amsdos)
;    EX DE,HL    ; Ponemos en HL la dirección de carga leida de la cabecera
    LD HL,load_address
    CALL #BC83  ; CAS_IN_DIRECT (Lee un fichero con cabecera del Amsdos)
    CALL #BC7A  ; CAS_IN_CLOSE (Cierre un fichero abierto para lectura)
    ENDM

inicio
    ; Inicialización

    ; Almacenamos el número de la unidad desde la que se cargó el programa
    LD HL,(#BE7D)
    LD A,(HL)
    LD (unidad_de_disco + 1),A

    
    LD C,#FF                ; Desactivamos todas las roms
    LD HL,comienzo_programa ; Dirección de comienzo del programa en sí
    CALL #BD16              ; MC_START_PROGRAM

comienzo_programa
    CALL #BCCB              ; KL_ROM_WALK (Activamos todas las roms)

; Al inicializarse el Amsdos, se pone como unidad por defecto la 0
; Así que necesitamos restaurar el número de unidad a la desde que se cargó el programa
unidad_de_disco
    LD A,0
    LD HL,(&BE7D)
    LD (HL),A

    ; Cargamos las imagenes en los bancos de memoria secundaria
    LD A,#C0 + 4    ; Página 4
    LD B,#7F
    OUT (C),A
    LOAD_FILE pantalla_roja,fin_pantalla_roja - pantalla_roja,#4000

    LD A,#C0 + 5    ; Página 5
    LD B,#7F
    OUT (C),A
    LOAD_FILE pantalla_verde,fin_pantalla_verde - pantalla_verde,#4000

    LD A,#C0 + 6    ; Página 6
    LD B,#7F
    OUT (C),A
    LOAD_FILE pantalla_azul,fin_pantalla_azul - pantalla_azul,#4000

    LD A,#C0        ; Página 1 (Normal)
    LD B,#7F
    OUT (C),A

    ; Tomamos el control del sistema
    DI

    ; Inicializamos las interrupciones
    IM 1
    LD HL,#C9FB     ; EI (#FB) + RET (#C9)
    LD (#0038),HL   ; Habrá un retardo de 4 NOPs al responder a las interrupciones

    LD SP,#2000     ; Movemos la pila

    ; Desbloqueamos el Asic
    LD HL,unlock_asic_sequence  ; Cadena para desbloquear el Asic
    LD B,#BC                    ; Puerto para desbloquear el Asic  
    LD A,17                     ; Longitud de la cadea para desbloquear el Asic
loop_unlock_asic
    INC B
    OUTI                        ; OUTI = DEC B + OUT (C),(HL) + INC HL
    DEC A
    JR NZ,loop_unlock_asic

    EI

    ; Esperamos el refresco
    WAIT_VBL

    ; Modo 0
    LD BC,#7F8C     ; ROM_OFF + MODE 0
    OUT (C),C

    ; Ponemos la paleta a negro
    ASIC_ON     

    XOR A
    LD HL,#6400
    LD (HL),A
    LD D,H
    LD E,L
    INC DE
    LD BC,#3E   ; ((16+1+15)*2)-1
    LDIR

    ASIC_OFF

    ; Descomprimimos las imagenes en su destino
    LD A,#C0 + 4    ; Página 4
    LD B,#7F
    OUT (C),A

    LD HL,#4000
    LD DE,#C000
    CALL decrunch

    LD A,#C0        ; Página 1
    LD B,#7F
    OUT (C),A

    LD HL,#C000
    LD DE,#4000
    LD BC,#4000
    LDIR

    LD A,#C0 + 5    ; Página 5
    LD B,#7F
    OUT (C),A

    LD HL,#4000
    LD DE,#8000
    CALL decrunch

    LD A,#C0 + 6    ; Página 6
    LD B,#7F
    OUT (C),A

    LD HL,#4000
    LD DE,#C000
    CALL decrunch

    ; Restauramos el estado de la ram a los bancos de memoria primarios
    LD A,#C0
    LD B,#7F
    OUT (C),A

    ASIC_ON

bucle_principal
    ; Color rojo
    WAIT_VBL
    CRTC_BASE #10   ; #4000
    ASIC_PUT_PALETTE paleta_roja,16*2
    HALT
;    DEFS 64,0
    
    ; Color verde
    WAIT_VBL
    CRTC_BASE #20   ; #8000
    ASIC_PUT_PALETTE paleta_verde,16*2
    HALT
;    DEFS 64,0

    ; Color azul
    WAIT_VBL
    CRTC_BASE #30   ; #C000
    ASIC_PUT_PALETTE paleta_azul,16*2
    HALT
;    DEFS 64,0

    JP bucle_principal

; Rutina de descompresión
; DE = Destino de los datos descomprimidos
; HL = Origen de los datos comprimidos
decrunch
    INCLUDE "aplib_cpc.s"
;    INCLUDE "exo_cpc.s"
;    INCLUDE "pu_cpc.s"

unlock_asic_sequence
    DEFB #FF,#00,#FF,#77,#B3,#51,#A8,#D4,#62
    DEFB #39,#9C,#46,#2B,#15,#8A,#CD,#EE

paleta_roja
    DEFW #0000,#0010,#0020,#0030
    DEFW #0040,#0050,#0060,#0070
    DEFW #0080,#0090,#00A0,#00B0
    DEFW #00C0,#00D0,#00E0,#00F0

paleta_verde
    DEFW #0000,#0100,#0200,#0300
    DEFW #0400,#0500,#0600,#0700
    DEFW #0800,#0900,#0A00,#0B00
    DEFW #0C00,#0D00,#0E00,#0F00

paleta_azul
    DEFW #0000,#0001,#0002,#0003
    DEFW #0004,#0005,#0006,#0007
    DEFW #0008,#0009,#000A,#000B
    DEFW #000C,#000D,#000E,#000F

pantalla_roja
;    DEFB "ROJO.BIN"
    DEFB "ROJO.APK"
fin_pantalla_roja

pantalla_verde
;    DEFB "VERDE.BIN"
    DEFB "VERDE.APK"
fin_pantalla_verde

pantalla_azul
;    DEFB "AZUL.BIN"
    DEFB "AZUL.APK"
fin_pantalla_azul

    END inicio
