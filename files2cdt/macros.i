;******************************************************************************
; Macros
;******************************************************************************

; WAIT_VBL: Espera al comienzo del refresco de pantalla
; Corrompe: A
WAIT_VBL MACRO
    LOCAL bucle_wait_vbl
    LD B,HIGH PPI_B         ; Puerto B del PPI
bucle_wait_vbl
;    LD A,HIGH PPI_B
;    IN A,(#00)
    IN A,(C)
    RRA                     ; Bit 0 al Carry flag / Carry = VSync
;   JR NC,bucle_wait_vbl    ; 2 (nc) / 3 (c)
    JP NC,bucle_wait_vbl    ; 3 (nc) / 3 (c)
endm
