;******************************************************************************
; Constantes del Hardware
;******************************************************************************
; Gate Array
; Puertos de acceso
GATE_ARRAY          EQU #7F00

; Modos de operación
PLUMA               EQU %00000000
TINTA               EQU %01000000
MODO_Y_ROM          EQU %10000000
MODO                EQU %10000000
ROM                 EQU %10000000
INTERRUPT           EQU %10000000
RAM                 EQU %11000000

; Selección de Pluma
BORDER              EQU %00010000
PEN                 EQU %00000000
PEN_00              EQU %00000000
PEN_01              EQU %00000001
PEN_02              EQU %00000010
PEN_03              EQU %00000011
PEN_04              EQU %00000100
PEN_05              EQU %00000101
PEN_06              EQU %00000110
PEN_07              EQU %00000111
PEN_08              EQU %00001000
PEN_09              EQU %00001001
PEN_0A              EQU %00001010
PEN_0B              EQU %00001011
PEN_0C              EQU %00001100
PEN_0D              EQU %00001101
PEN_0E              EQU %00001110
PEN_0F              EQU %00001111

; Colores
BLANCO              EQU #00     ; White 
;BLANCO             EQU #01     ; White (no definido oficialmente) 
VERDE_MAR           EQU #02     ; Sea Green 
AMARILLO_PASTEL     EQU #03     ; Pastel Yellow 
AZUL                EQU #04     ; Blue 
PURPURA             EQU #05     ; Purple 
CIAN                EQU #06     ; Cyan 
ROSA                EQU #07     ; Pink 
;PURPURA            EQU #08     ; Purple (no definido oficialmente) 
;AMARILLO_PASTEL    EQU #09     ; Pastel Yellow (no definido oficialmente) 
AMARILLO_BRILLANTE  EQU #0A     ; Bright Yellow 
BLANCO_BRILLANTE    EQU #0B     ; Bright White 
ROJO_BRILLANTE      EQU #0C     ; Bright Red 
MAGENTA_BRILLANTE   EQU #0D     ; Bright Magenta 
NARANJA             EQU #0E     ; Orange 
MAGENTA_PASTEL      EQU #0F     ; Pastel Magenta 
;AZUL               EQU #10     ; Blue (no definido oficialmente) 
;VERDE_MAR          EQU #11     ; Sea Green (no definido oficialmente) 
VERDE_BRILLANTE     EQU #12     ; Bright Green 
CIAN_BRILLANTE      EQU #13     ; Bright Cyan 
NEGRO               EQU #14     ; Black 
AZUL_BRILLANTE      EQU #15     ; Bright Blue 
VERDE               EQU #16     ; Green 
AZUL_CIELO          EQU #17     ; Sky Blue 
MAGENTA             EQU #18     ; Magenta 
VERDE_PASTEL        EQU #19     ; Pastel Green 
LIMA                EQU #1A     ; Lime 
CIAN_PASTEL         EQU #1B     ; Pastel Cyan 
ROJO                EQU #1C     ; Red 
MALVA               EQU #1D     ; Mauve 
AMARILLO            EQU #1E     ; Yellow 
AZUL_PASTEL         EQU #1F     ; Pastel Blue 

; Modos de pantalla
MODE_0              EQU #00
MODE_1              EQU #01
MODE_2              EQU #02
MODE_3              EQU #03     ; Mode 0 con 4 colores (no definido oficialmente)

; ROM
ALL_ROM_OFF         EQU %00001100
ROM_UPPER_OFF       EQU %00001000
ROM_UPPER_ON        EQU %00000000
ROM_LOWER_OFF       EQU %00000100
ROM_LOWER_ON        EQU %00000000

; RASTER 52 DIVIDER
RASTER_DIVIDER      EQU %00010000

;******************************************************************************
; CRTC
; Puertos de acceso
CRTC_REG            EQU #BC00
CRTC_DAT            EQU #BD00

; Registros del CRTC
REG_00              EQU #00     ; Horizontal Total
REG_01              EQU #01     ; Horizontal Displayed
REG_02              EQU #02     ; Horizontal Sync Position
REG_03              EQU #03     ; VSYNC, HSYNC Widths
REG_04              EQU #04     ; Vertical Total
REG_05              EQU #05     ; Vertical Total Adjust
REG_06              EQU #06     ; Vertical Displayed
REG_07              EQU #07     ; Vertical Sync Position
REG_08              EQU #08     ; Mode Control
REG_09              EQU #09     ; Scan Line
REG_0A              EQU #0A     ; Cursor Start
REG_0B              EQU #0B     ; Cursor End
REG_0C              EQU #0C     ; Display Start Addr (H)
REG_0D              EQU #0D     ; Display Start Addr (L)
REG_0E              EQU #0E     ; Cursor Position (H)
REG_0F              EQU #0F     ; Cursor Position (L)
REG_10              EQU #10     ; Light Pen Reg (H)
REG_11              EQU #11     ; Light Pen Reg (L)

;******************************************************************************
; PPI
; Puertos de acceso
PPI_A               EQU #F400    ; Puerto A del 8255
PPI_B               EQU #F500    ; Puerto B del 8255
PPI_C               EQU #F600    ; Puerto C del 8255
PPI_CONTROL         EQU #F700    ; Puerto de Control del 8255

; Constantes
TAPE_MOTOR_ON       EQU %00010000
TAPE_MOTOR_OFF      EQU %00000000
TAPE_WRITE_DATA     EQU %00100000
TAPE_READ_DATA      EQU %10000000
