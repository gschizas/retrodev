# Amstrad CPC #

  1. - _How to Wait for the Vertical Blank:_
    * Using the **firmware**:
```
call &bd19
```
    * Using the **hardware**:
      1. Normal method:
```
    LD B,HIGH PPI_B
loop_wait_vbl
    IN A,(C)
    RRA                    ; Carry = VSync
    JP NC,loop_wait_vbl    ; 3 (nc) / 3 (c)
```
      1. Using only the accumulator:
```
loop_wait_vbl
    LD A,HIGH PPI_B
    IN A,(#00)
    RRA
    JR NC,loop_wait_vbl    ; 2 (nc) / 3 (c)
```
  1. - _Macro to Write in a register of the CRTC:_
```
WRITE_CRTC MACRO crtc_register,value
    LD BC,#BC00 + crtc_register
    OUT (C),C
    LD BC,#BD00 + value
    OUT (C),C
    ENDM
```
  1. - _Macro to Send a PSG's register through PPI's port A:_
```
SEND_PSG_REG MACRO REGISTRO
    LD BC,#F400 + REGISTRO
    OUT (C),C
    ENDM   
```
  1. - _Macro to Select a PSG's register:_
```
SELECT_PSG MACRO
    LD BC,#F600 + %11000000
    OUT (C),C
    ENDM
```
  1. - _Macro to Inactive PSG (need it in cpc+ to use between change of modes of PSG):_
```
INACTIVE_PSG MACRO
    LD BC,#F600 + %00000000         
    OUT (C),C                           
    ENDM 
```
  1. - _Macro to Set the mode of PPI ports:_
```
SET_PPI_CONTROL MACRO VALOR
    LD BC,#F700 + VALOR
    OUT (C),C
    ENDM
```
  1. - _Macro to initialize the PSG for scan the keyboard:_
```
INIT_PSG_FOR_SCANKEYS MACRO
    SEND_PSG_REG 14            
    SELECT_PSG                 
    INACTIVE_PSG               ; Fix for CPC+
    SET_PPI_CONTROL %10010010  ; PPI Port A for input
    ENDM 
```
  1. - _Macro to restore the psg after scan the keyboard:_
```
RESTORE_PSG_FROM_SCANKEYS MACRO
    SET_PPI_CONTROL %10000010  ; PPI Port A for output
    INACTIVE_PSG
    ENDM 
```
  1. - _Macro to read a PSG register in A:_
```
READ_PSG_RA MACRO
    LD B,#F4
    IN A,(C)
    ENDM  
```
  1. - _How to read the joystick:_
```
; A --> Estado del joystick (%0 0 Fire_1 Fire_2 Right Left Down Up)
read_joystick_0
    INIT_PSG_FOR_SCANKEYS
    LD   BC,#F500 + %01001001   ; For joystick 0 use the line 9
;   LD   BC,#F500 + %01000110   ; For joystick 1 use the line 6
    OUT  (C),C                  
    READ_PSG_RA                 
    CPL                         
    AND  %00111111              ; A = %0 0 Fire_1 Fire_2 Right Left Down Up)
    RESTORE_PSG_OF_SCANKEYS     
    RET
```
  1. - _Macro to write a value in a PSG's register:_
```
WRITE_PSG MACRO
    LD BC,PPI_C|%10000000
    OUT (C),C                     
    ENDM
```
  1. - _Macro to initialize the PSG:_
```
INIT_PSG MACRO
    SEND_PSG_REG 7
    SELECT_PSG    
    INACTIVE_PSG  
    SEND_PSG_DATA %00111111
    WRITE_PSG              
    INACTIVE_PSG           
    ENDM   
```
  1. - _How to copy 12 bytes blocks using the stack:_
```
    DI
    LD (sm_old_sp12 + 1),SP
    LD HL,DIRECCION_ORIGEN
    EXX
    LD HL,DIRECCION_DESTINO
    EXX
   
    ; Begin COPY_12
    LD SP,HL        ; HL ==> ORIGEN

    LD BC,12
    ADD HL,BC       ; NEXT_CHUNCK

    POP AF
    POP DE
    POP BC
    EX AF,AF'
    POP AF
    EXX
    POP DE
    POP BC

    LD SP,HL        ; HL ==> DESTINO
    PUSH BC
    PUSH DE
    PUSH AF

    OR A            ; Limpia Carry
    LD BC,12
    SBC HL,BC       ; NEXT_CHUNCK

    EXX     
    PUSH BC
    PUSH DE
    EX AF,AF'
    PUSH AF
    ; End COPY_12
sm_old_sp12
    LD SP,#0000
    EI
```
  1. - _How to copy 16 bytes blocks using the stack:_
```
    DI
    LD (sm_old_sp16 + 1),SP
    LD HL,DIRECCION_ORIGEN
    EXX
    LD HL,DIRECCION_DESTINO
    EXX
   
    ; Begin COPY_16
    LD SP,HL        ; HL ==> ORIGEN

    LD BC,16
    ADD HL,BC       ; NEXT_CHUNCK

    POP AF
    POP DE
    POP BC
    EX AF,AF'
    EXX
    POP AF
    POP DE
    POP BC
    POP IX
    POP IY

    LD SP,HL        ; HL ==> DESTINO
    PUSH IY
    PUSH IX
    PUSH BC
    PUSH DE
    PUSH AF

    OR A            ; Limpia Carry
    LD BC,16
    SBC HL,BC       ; NEXT_CHUNCK

    EXX     
    EX AF,AF'
    PUSH BC
    PUSH DE
    PUSH AF
    ; End COPY_16
sm_old_sp16
    LD SP,#0000
    EI
```
  1. - _How to wait X scanlines:_
```
; wait_scanlines_bc
; Example to use:
;   LD BC,(scanlines_to_wait * 8)-2 ; (3)
;   CALL  wait_scanlines_bc         ; (5)
wait_scanlines_bc
    DEFB #00,00                     ; (2)
    DEFB #00,00                     ; (2)
    DEFB #00,00                     ; (2)

loop_wait_scanlines_bc              ; Total Loop --> 8 * (CNT - 1) + 7
    OR A                            ; (1)
    DEC BC                          ; (2)
    LD A,B                          ; (1)
    OR C                            ; (1)
    JR NZ,loop_wait_scanlines_bc    ; (2/3)

    RET                             ; (3)
                                    ; Total Rutine --> 16 + 8 * CNT
```
  1. - _How to wait X frames:_
```
wait_x_frames
loop_wait_x_frames
    WAIT_VBL
    HALT
    DEC E
    JR NZ,loop_wait_x_frames
    RET
```
  1. - _How to put all the inks in black:_
```
eclipse
    LD BC,#7F00 + #54 ; GATE_ARRAY + BLACK
    LD A,17     ; 16 Pens + Border
loop_eclipse
    DEC A
    OUT (C),A   ; Pen
    OUT (C),C   ; Ink
    JR NZ,loop_eclipse
    RET
```
  1. - _How to put a palette:_
```
    WAIT_VBL
    LD HL,end_palette - 1
    LD A,end_palette - palette - 1
    CALL set_palette
.
.
.
palette
    DEFB RED,GREEN,BLUE,...
end_palette
.
.
.
set_palette
    LD B,#7F
loop_set_palette
    OUT (C),A
    LD C,(HL)
    OUT (C),C
    DEC HL
    DEC A
    CP #FF
    JR NZ,loop_set_palette
    RET
```
  1. - _How to set the screen dimensions:_
```
    LD HL,crtc_values
    LD A,(end_crtc_values - crtc_values) / 2
    CALL set_screen_dimensions
.
.
.

crtc_values
    defb REG_01,WIDTH_SCREEN_FOR_CRTC
    defb REG_06,HEIGHT_SCREEN_FOR_CRTC
    defb REG_02,HORIZONTAL_OFFSET
    defb REG_07,VERTICAL_OFFSET
    defb REG_0C,VRAM_P3             ; Screen in #C000
    defb REG_0D,0
end_crtc_values
.
.
.
set_screen_dimensions
    LD B,#BC + 1
loop_set_screen_dimensions
    OUTI ; CRTC register
    INC B
    INC B
    OUTI ; Value
    DEC A
    JR NZ,loop_set_screen_dimensions
    RET
```
  1. - _Macro to load a file using the firmware:_
```
; Example of use:
; LOAD_FILE filename,12,#C000
;filename
;    DEFB "PANTALLA.SCR"
LOAD_FILE MACRO filename_string,len_filename_string,load_address
    LD HL,filename_string
    LD B,len_filename_string
    CALL #BC77  ; CAS_IN_OPEN 
    LD HL,load_address
    CALL #BC83  ; CAS_IN_DIRECT
    CALL #BC7A  ; CAS_IN_CLOSE 
    ENDM
```
  1. - _Macro to Set an extend ram page in #4000:_
```
SET_RAM_PAGE MACRO valor
    LD BC,#7F00 + valor
    OUT (C),C
    ENDM
```
  1. - _How to know how many ram have the CPC:_
```
; Detectamos cuantas páginas de 16KBs de RAM extendida tenemos disponibles
ram_test
    LD   HL,#4000           ; HL --> Dirección donde se pagina la RAM extendida
    LD   BC,#7F00
    LD   A,#C0              ; Establecemos en #4000 la página 1 de RAM principal
    OUT  (C),A
    LD   A,(HL)
    LD   (buffer_ram + 1),A ; Y almacenamos el byte que hay en #4000 para restaurarlo luego
    LD   A,#FF
    LD   (HL),A             ; Marcamos la página 1 de RAM principal

    LD   A,#C4              ; Primera página de RAM extendida (Hay un máximo de 32, 512KBs + 64KBs internos = 576 KBs)
    LD   D,#01              ; Contador para las páginas
    LD   E,8

; Solo funciona con 6128 y ampliaciones compatibles con las DKTronics de 64KBs, 128KBs, 256KBs y 512KBs
; (también los primeros 512KBs de la ampliación de 4 Megas que emula el WinApe).
bucle_marca_ram
    OUT  (C),A              ; Activamos una página de RAM extendida
    LD   (HL),D             ; Escribimos el contador en su primer byte
   
    INC  D                  ; Realizamos lo mismo con la segunda página del bloque...
    INC  A                 
    OUT  (C),A             
    LD   (HL),D             
   
    INC  D                  ; con la tercera...
    INC  A
    OUT  (C),A
    LD   (HL),D

    INC  D                  ; y con la cuarta.
    INC  A
    OUT  (C),A
    LD  (HL),D

    INC  D
    INC  A         
    AND  %11111011         
    OR   %00000100          ; Nos aseguramos que el bit 2 esté activo

    DEC  E
    JR   NZ,bucle_marca_ram

    ; Comprobamos los espejos de la paginación   
    LD   A,#C7              ; Limite de 64KBs
    OUT  (C),A
    LD   D,(HL)
    LD   A,#CF              ; Limite de 128KBs
    OUT  (C),A
    LD   E,(HL)
    LD   A,#DF              ; Limite de 256KBs
    EX   DE,HL
    OUT  (C),A
    LD   A,(DE)
    LD   IXH,A
    LD   A,#FF              ; Limite de 512KBs
    OUT  (C),A
    LD   A,(DE)
    LD   IXL,A

    LD   A,#C0
    OUT  (C),A              ; Volvemos a situar en #4000 la primera página de RAM principal
    LD   A,(#4000)
    CP   #FF
    JR   NZ,no_ram_expansion
    LD   A,32
    CP   H
    JR   Z,ram_64kbs
    CP   L
    JR   Z,ram_128kbs
    CP   IXH
    JR   Z,ram_256kbs
    CP   IXL
    JR   Z,ram_512kbs
unknown_ram_expansion
no_ram_expansion
    XOR  A
    JR   exit_ram_test
ram_64kbs
    LD   A,4
    JR   exit_ram_test
ram_128kbs
    LD   A,8
    JR   exit_ram_test
ram_256kbs
    LD   A,16
    JR   exit_ram_test
ram_512kbs
    LD   A,32
exit_ram_test
    LD   (PRAM_EXT),A           ; Número de páginas de 16KBs de RAM extendida que tiene este cpc
buffer_ram
    LD   A,#00
    LD   (RAM_P1),A             ; Y restauramos el valor que pudiese haber en #4000
    RET

PRAM_EXT DEFB #00               ;  Número de páginas de 16KBs de RAM extendida detectadas
```
  1. - _How to generate an array with pointers to scanlines:_
```
;******************************************************************************
; Crea la tabla con las direcciones de comienzo de cada línea, usada por la
; rutina que nos convertirá de coordenadas a direcciones de memoria.
; Corrompe: HL,DE,BC,A,IX,IY
;******************************************************************************
genera_tabla_scanlines
    LD HL,#C000             ; Dirección de comienzo de la pantalla
    LD DE,#0800             ; Cantidad a sumar para pasar de una línea a la que está debajo
    LD BC,#C050             ; Cantidad a sumar para pasar de una caracter al que está debajo
    LD A,200-1              ; Altura de la pantalla
    LD IY,#4000             ; Byte de menos peso de las direcciones
    LD IX,#4100             ; Byte de más peso de las direcciones
genera_scanlines
    LD (IX),H
    LD (IY),L
loop_genera_scanlines
    ADD HL,DE
    JR NC,next_genera_scanlines
    ADD HL,BC
next_genera_scanlines
    INC IX
    INC IY
    LD (IX),H
    LD (IY),L
    DEC A
    JR NZ,loop_genera_scanlines
    RET
```
  1. - _How to convert from coords to screen address:_
```
;******************************************************************************
; Convertimos de coordenadas a direcciones de memoria, haciendo uso de las
; tablas de punteros a scanlines anteriormente generadas.
; En el snippet anterior #4000 (byte de menos peso) y #4100 (byte de más peso)
; Entradas:
;   BC: Coordenadas del sprite (Y,X)
; Salidas:
;   BC: Dirección correspondiente a las coordenadas suministradas
;******************************************************************************
convierte_coordenadas
    SRL C                       ; C = CX >> 1 (Hay 2 pixels por byte en modo 0)
    LD H,#40                    ; HL = #40xx
    LD L,B                      ; B ==> CY (Scanline a pintar)
    LD A,(HL)
    INC H
    LD B,(HL)           
    ADD A,C
    JR NC,sigue
    INC B
sigue
    LD C,A             ; BC = DIR_MEMORIA
    RET
```
  1. - _How to generate an array with pointers to tiles:_
```
;******************************************************************************
; Crea la tabla con las direcciones de comienzo de cada patrón
; Corrompe: HL,DE,BC,A,IX,IY
;******************************************************************************
genera_tabla_patrones
    LD HL,DIR_PATRONES                          ; Dirección de comienzo de los patrones
    LD DE,ANCHO_PATRON_MENU * ALTO_PATRON_MENU  ; Cantidad a sumar para pasar de un patrón al siguiente
    LD B,#FF                                    ; Número de patrones
    LD IX,#4200                                 ; Byte de más peso de la dirección
    LD IY,#4300                                 ; Byte de menos peso de la dirección
genera_patrones
    LD (IX),H
    LD (IY),L
_loop_genera_patrones
    ADD HL,DE
    INC IX
    INC IY
    LD (IX),H
    LD (IY),L
    DJNZ _loop_genera_patrones
    RET
```
  1. - _How to Print a screen using tiles:_
```
;******************************************************************************
; Rellenamos la pantalla usando patrones
; Entradas:
;   HL: Puntero al mapa de patrones
;******************************************************************************
pinta_pantalla_con_patrones
    XOR A
bucle_pinta_menu_por_patrones
    LD IXH,A
    PUSH HL

    ; Obtenemos la dirección  del scanline a pintar
    LD H,#40                                ; Byte de menos peso de la tabla de punteros a scanlines
    LD L,A                                  ; A => scanline a pintar
    LD E,(HL)
    INC H
    LD D,(HL)                               ; DE => dirección del scanline

    ; Calculamos el scanline del patrón que habrá que pintar
    AND #07                                 ; Scanline del patrón
    RLCA                                    ; A * 2
    RLCA                                    ; A * 2
    LD (sm_suma + 1),A                      ; (A & #07) * Ancho patrón

    LD B,ANCHO_PANTALLA/ANCHO_PATRON
bucle_pinta_scanline
    ; Obtenemos el patrón que toca pintar
    POP HL
    LD A,(HL)                               ; A => patrón a pintar
    INC HL                                  ; mapa++
    PUSH HL

    ; Obtenemos la dirección del scanline del patrón a pintar
    LD H,#42                                ; Byte de menos peso de la tabla de punteros a patrones
    LD L,A
    LD A,(HL)
    INC H
    LD H,(HL)                               ; HL => dirección del patrón a pintar
sm_suma
    ADD A,#00                       
    JR NC,sigue_pmpp01
    INC H
sigue_pmpp01
    LD L,A                                  ; HL => scanline del patrón

    ; Pintamos el scanline del patrón
    LD A,B                                  ; Almacenamos B
    LDI
    LDI
    LDI
    LDI
    LD B,A                                  ; Y lo restauramos
    DJNZ bucle_pinta_scanline

    ; Comprobamos si el próximo scanline es múltiplo de 8, para pasar a la siguiente línea del mapa
    POP HL
    LD A,IXH
    INC A
    LD D,A
    AND #07
    JR Z,sigue_pmpp02
    LD BC,ANCHO_PANTALLA/ANCHO_PATRON
    XOR A       ; Carry = 0
    SBC HL,BC   ; HL -= ANCHO_PANTALLA/ANCHO_PATRON
sigue_pmpp02
    ADD A,D
    JR NZ,bucle_pinta_menu_por_patrones
fin_pinta_scanline
    RET
```
# Amstrad CPC+ #
  1. - _How to Unlock the ASIC:_
```
desbloquea_asic
    DI
    LD HL,secuencia_desbloqueo_asic
    LD B,#BC                    ; Puerto para desbloquear el Asic 
    LD A,17                     ; Longitud de la cadena para desbloquear el Asic
bucle_desbloquea_asic
    INC B
    OUTI                        ; OUTI = DEC B + OUT (C),(HL) + INC HL
    DEC A
    JR NZ,bucle_desbloquea_asic
    EI
    RET

secuencia_desbloqueo_asic
    DEFB #FF,#00,#FF,#77,#B3,#51,#A8,#D4,#62
    DEFB #39,#9C,#46,#2B,#15,#8A,#CD,#EE
```
  1. - _Macro to Put the ASIC Ram in #4000:_
```
ASIC_ON MACRO
    LD BC,#7FB8
    OUT (C),C
    ENDM
```
  1. - _Macro to Quit the ASIC Ram of #4000:_
```
ASIC_OFF MACRO
    LD BC,#7FA0
    OUT (C),C
    ENDM
```
  1. - _How to Emulate a Green Monitor in CPC+:_
```
    CALL desbloquea_asic
    WAIT_VBL
    ASIC_ON
    LD DE,#6400
    LD HL,paleta_fosforo_verde
    LD BC,32 ; 16 * 2
    LDIR
    ASIC_OFF

paleta_fosforo_verde
    DEFW #0000,#0100,#0200,#0300
    DEFW #0400,#0500,#0600,#0700
    DEFW #0800,#0900,#0A00,#0B00
    DEFW #0C00,#0D00,#0E00,#0F00
```
  1. - _Macro to :_
```
```

# Amiga #

See you later...