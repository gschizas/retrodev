; Lector de carga turbo
; Basado en el artículo de Pedro M. Cuenca para Amstrad Personal

; NOTA: Los bits leidos son los inversos de los que se escribieron.

; Tetris a 2500 baudios (dirección de carga #0170, dirección de ejecución #1A0, tamaño 12453 bytes)
; Bit a 0: 479 t-states 119 ms
; Bit a 1: 958 t-states 239 ms

    include "hardware.i"
    include "macros.i"

; Constantes del programa
COLOR_FRECUENCIA_ALTA   EQU TINTA | VERDE_MAR
COLOR_FRECUENCIA_BAJA   EQU TINTA | AZUL_BRILLANTE

    ORG #A000

inicio
    LD HL,#4000 ; 12453 ;#4000
    LD (longitud),HL
    LD HL,#C000 ; #0170 ;#C000
    LD (dir_carga),HL
    LD HL,#0000 ; #01A0 ;#0000
    LD (dir_ejecucion),HL

    CALL carga_turbo

;    LD HL,(dir_ejecucion)
;    LD A,H
;    OR L
;    RET Z
;    JP (HL)
bucle_infinito
    JR bucle_infinito

; Rutina de carga turbo
carga_turbo
    DI

    ; Guardamos AF' y BC' para restaurar el firmware posteriormente
    EX AF,AF'
    PUSH AF
    EX AF,AF'
    EXX
    PUSH BC

    ; Inicializamos el PPI al estado por defecto del CPC
    LD BC,PPI_CONTROL | %10000010       ; Modo 0 | Puerto A OUT | Puerto B IN | Puerto C OUT

    ; Conectamos el motor del casete
    LD BC,PPI_CONTROL | %00001001       ; TAPE_MOTOR_ON
    OUT (C),C
    LD B,HIGH PPI_B
    EXX             ; B' = PPI_B


    ; Esperamos 1,5 segundos a que la cinta tome una velocidad constante 
    LD B,75
bucle_espera_cinta
    LD C,B          ; PUSH BC
    WAIT_VBL
    LD B,C          ; POP BC
    DJNZ bucle_espera_cinta

reinicia_la_carga
    ; Ponemos el borde azul brillante
    LD BC,GATE_ARRAY | PLUMA | BORDER
    OUT (C),C
    LD C,COLOR_FRECUENCIA_BAJA
    OUT (C),C

    ; Buscamos el tono guía
    CALL busca_tono_guia

    LD HL,(dir_carga)
    LD DE,(longitud)
    CALL carga_datos
    JR C,reinicia_la_carga    ; Se produjo un error, por lo que reiniciamos la carga
    EXX

    ; Desconectamos el motor del casete
    LD BC,PPI_CONTROL | %00001000       ; TAPE_MOTOR_OFF
    OUT (C),C

    ; Recuperamos AF' y BC' para restaurar el firmware
    POP BC
    EXX
    EX AF,AF'
    POP AF
    EX AF,AF'
    EI
    RET

; Busca el tono guía 128 bytes a %11111111 + 1 Bit a 0 (bit de sincronía)
busca_tono_guia
    LD B,#80      ; 1024 bits a 1 (1024 / 8 = 128)
bucle_busca_tono_guia
    CALL carga_byte
    JR C,busca_tono_guia       ; Se produjo un error, así que seguimos leyendo hasta encontrar el tono guía
    CP %11111111
    JR NZ,busca_tono_guia       ; No es el tono guía, así que seguimos leyendo hasta encontrar el tono guía
    DJNZ bucle_busca_tono_guia
    ; Más un último bit a 0
    CALL espera_frecuencia_baja
    JP espera_frecuencia_alta

; Carga un conjunto de bytes, anteriormente se ha leido
; la cabecera
; HL = Dirección de carga
; DE = Longitud en bytes
carga_datos
    CALL carga_byte
    RET C           ; Se produjo un error en la carga
    LD (HL),A
    INC HL
    DEC DE
    LD A,D
    OR E
    JR NZ,carga_datos
    RET

; Carga un byte en el Acumulador
; Carry se activa si se produjo un error en la carga.
carga_byte
    PUSH BC
    LD B,8
bucle_carga_byte
    EX AF,AF'
    CALL espera_frecuencia_baja
    JR C,carga_de_bit_incorrecta
    CALL espera_frecuencia_alta
    JR C,carga_de_bit_incorrecta

    LD A,(periodo_bit_alto)
    CP #08                          ; Valor de temporización
    JR NC,el_bit_cargado_es_1        ; if (periodo_bit_alto > #08): bit_cargado = 1

el_bit_cargado_es_0
    LD A,(periodo_bit_bajo)
    CP #12                          ; Valor de temporización
    JR NC,carga_de_bit_incorrecta    ; if (periodo_bit_bajo <= #12): Error de carga
    EX AF,AF'
    OR A
    JR carga_de_bit_correcta

el_bit_cargado_es_1
    LD A,(periodo_bit_bajo)
    CP #12                          ; Valor de temporización
    JR NC,carga_de_bit_incorrecta   ; if (periodo_bit_bajo <= #12): Error de carga
    EX AF,AF'
    SCF

carga_de_bit_correcta
    RLA
    DJNZ bucle_carga_byte
    OR A
    POP BC
    RET

carga_de_bit_incorrecta
    EX AF,AF'
    SCF
    POP BC
    RET

; Espera hasta que lee del casete un tono bajo.
; Mide el tiempo en periodo_bit_alto y si pasa demasiado, produce un error.
espera_frecuencia_baja
    LD A,B
    LD BC,GATE_ARRAY | PLUMA | BORDER
    OUT (C),C
    LD C,COLOR_FRECUENCIA_BAJA
    OUT (C),C
    LD B,A
    EXX

    LD HL,periodo_bit_alto
    LD (HL),1
bucle_espera_frecuencia_baja              ; BUCALTO
    IN A,(C)
    RLA
    JR C,lectura_correcta
    INC (HL)
    JR Z,lectura_incorrecta
    JR bucle_espera_frecuencia_baja      ; BUCALTO

; Espera hasta que lee del casete un tono alto. 
; Mide el tiempo en periodo_bit_bajo y si pasa demasiado, produce un error.
espera_frecuencia_alta
    LD A,B
    LD BC,GATE_ARRAY | PLUMA | BORDER
    OUT (C),C
    LD C,COLOR_FRECUENCIA_ALTA
    OUT (C),C
    LD B,A
    EXX

    LD HL,periodo_bit_bajo
    LD (HL),1
bucle_espera_frecuencia_alta              ; BUCBAJO
    IN A,(C)
    RLA
    JR NC,lectura_correcta
    INC (HL)
    JR Z,lectura_incorrecta
    JR bucle_espera_frecuencia_alta      ; BUCBAJO

lectura_correcta
    OR A
    EXX
    RET

lectura_incorrecta
    SCF
    EXX
    RET

periodo_bit_alto    DEFS 1
periodo_bit_bajo    DEFS 1

longitud            DEFW #0000
dir_carga           DEFW #0000
dir_ejecucion       DEFW #0000

    END inicio