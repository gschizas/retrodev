#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
files2cdt
(c) MML, 2009
"""

# TODO:
# Añadir distintos tipos de turbo en genera_bloques_turbo()

# NOTAS:
# * El orden en que se le pasan los ficheros, será el orden de los ficheros en la cinta.
# * El fichero "cargador" debe tener una cabecera de amsdos correcta, si se usa el modo de
#   carga del firmware todos los ficheros deberán tener una cabecera de amsdos.

# #BC68 - CAS SET SPEED
# Sets the speed at which the cassette manager saves programs.
# Entry:
#   HL holds the length of 'half a zero' bit.
#   A contains the amount of precompensation.
# Exit:
#   AF and HL are corrupt.
# Notes:
# The value in HL is the length of time that half a zero bit is written as; a “one” bit is 
# twice the length of a “zero” bit; the default values (ie SPEED WRITE 0) are 333 microseconds (HL) 
# and 25 microseconds (A) for SPEED WRITE 1, the values are given as 107 microseconds and 50 microseconds 
# respectively.

   # para usar la instrucción with en python 2.5

         # para tener divisiones de reales en python2.5

import sys
import glob             # glob() expande los patrones de los ficheros en windows
from os import path     # path.basename()
from optparse import make_option, OptionParser

# Constante para evitar números mágicos :P
BYTE_NULO = '\x00'

# Longitud de la cabecera del Amsdos
LONGITUD_CABECERA_AMSDOS = 128

# Longitud de la cabecera de cinta
LONGITUD_CABECERA_CINTA = 64

# Longitud máxima de un bloque de cinta
LONGITUD_BLOQUE_CINTA = 2048

# Longitud en que se dividen los segmentos de un bloque
LONGITUD_SEGMENTO_BLOQUE = 256

# Sincronía para bloque de cabecera en cinta
SINCRONIA_BLOQUE_CABECERA = '\x2C'

# Sincronía para bloque de cabecera en cinta
SINCRONIA_BLOQUE_DATOS = '\x16'

# 32 bits a 1 a añadir al final de todo bloque
COLA_BLOQUE = '\xFF' * 4

# Tipo de bloque especial (primer ó último bloque)
BLOQUE_ESPECIAL = '\xFF'

# Posiciones dentro de la cabecera de cinta
LUGAR_PUNTO = 8
NUMERO_BLOQUE = 16
ULTIMO_BLOQUE = 17
PRIMER_BLOQUE = 23
LONGITUD_BLOQUE_DATOS = 19

# Cabecera CDT (longitud: 10)
# ---------------------------
# Offset    Valor         Tipo          Descripción
# ---------------------------------------------------------
# 0x00      ZXTape!       ASCII[7]      TZX signature
# 0x07         0x1A       BYTE          End of text file marker
# 0x08            1       BYTE          TZX major revision number
# 0x09            0       BYTE          TZX minor revision number
CABECERA_CDT = '\x5A' + '\x58' + '\x54' + '\x61' + '\x70' + '\x65' + '\x21' + '\x1a' + '\x01' + '\x0A'

# Bloque de Pausa (longitud: 3)
# -----------------------------
# 0x20 ID
# Offset  Valor       Tipo        Descripción
# ---------------------------------------------------------
# 0x00    0xXXXX      WORD        Duración de la pausa en milisegundos 
ID_BLOQUE_PAUSA = '\x20'
PAUSA_INICIAL_CDT = '\x88' + '\x13'         # 5.000 milisegundos
PAUSA_CABECERA_FIRMWARE = '\x0E' + '\x00'   # 14 milisegundos
PAUSA_DATOS_FIRMWARE = '\xD0' + '\x07'      # 2000 milisegundos

# Bloque de datos a velocidad turbo (longitud: [0F,10,11] + 0x12)
# ---------------------------------------------------------------
# 0x11 ID
# Offset  Valor       Tipo        Descripción
# ---------------------------------------------------------
# 0x00    0xXXXX      WORD        Length of PILOT pulse
# 0x02    0xXXXX      WORD        Length of SYNC first pulse
# 0x04    0xXXXX      WORD        Length of SYNC second pulse
# 0x06    0xXXXX      WORD        Length of ZERO bit pulse
# 0x08    0xXXXX      WORD        Length of ONE bit pulse
# 0x0A    0xXXXX      WORD        Length of PILOT tone (number of pulses)
# 0x0C      0xXX      BYTE        Used bits in the last byte (other bits should be 0) {8}
# 0x0D    0xXXXX      WORD        Pause after this block (ms.)
# 0x0F         N      BYTE[3]     Length of data that follow
# 0x12      0xXX      BYTE[N]     Data as in .TAP files
ID_BLOQUE_TURBO = '\x11'
# BLOQUE_TURBO = BYTE_NULO * 0x0D

# Información específica para el Amstrad CPC
# ------------------------------------------
# Funcionamiento de la carga del firmware:
# 1.- Un tono guía que consta de una cierta cantidad (4096) de pulsos de bits a 1 (2240).
# 2.- Un pulso de un bit a 0 (1120).
# 3.- Un byte de sincronía (0x2c para cabecera, 0x16 para datos).
# 4.- Una serie de paquetes de 256 bytes con su correspondiente CRC.
# 5.- Una cola de 32 bits a 1.

# Por lo que podemos concluir que para el firmware: 
# Sync1 = Sync2 = Bit0 | Pilot Pulse= Bit1 | Length = 4096 | Bit0 = Bit1 / 2
# Pilot pulse     Length      Sync1       Sync2       Bit 0       Bit 1
# Bit 1           4096        Bit 0       Bit 0       Bit 0       Bit 1

# NOTA: Las rutinas del firmware pueden usar una velocidad variable, para ello leen del tono guía 
# la duración de los bits a 1 y de los pulsos de sincronía la de los bits a 0 (que en el caso del 
# firmware debe ser siempre la mitad que para los bits a 1).

# 2cdt
# ----
# Speed Write 0
# Pausa inicial 10.000ms 
# Pausa entre cabecera y datos 10 ms
# Pausa entre bloques 2.000 ms
# Pilot pulse   Length      Sync1       Sync2       Bit 0       Bit 1
# 2240          4096        1120        1120        1120        2240
#BLOQUE_TURBO_SPEED_WRITE_0 = ID_BLOQUE_TURBO + \
#                               '\xC0' + '\x08' + \
#                               '\x60' + '\x04' + \
#                               '\x60' + '\x04' + \
#                               '\x60' + '\x04' + \
#                               '\xC0' + '\x08' + \
#                               '\x00' + '\x10' + \
#                               '\x08'                   

# Speed Write 1
# Pausa inicial 10.000 ms 
# Pausa entre cabecera y datos 10 ms
# Pausa entre bloques 2.000 ms
# Pilot pulse   Length      Sync1       Sync2       Bit 0       Bit 1
# 896           4096        448         448         448         896
#BLOQUE_TURBO_SPEED_WRITE_1 = ID_BLOQUE_TURBO + \
#                               '\x80' + '\x03' + \
#                               '\xC0' + '\x01' + \
#                               '\xC0' + '\x01' + \
#                               '\xC0' + '\x01' + \
#                               '\x80' + '\x03' + \
#                               '\x00' + '\x10' + \
#                               '\x08'                   

# samp2cdt de bloques reales (cpc desconocido)
# --------------------------------------------
# Speed Write 0
# Pausa inicial 6.568 ms 
# Pausa entre cabecera y datos 16 ms
# Pausa entre bloques 2.016 ms
# Pilot pulse   Length      Sync1       Sync2       Bit 0           Bit 1
# 2423          4096        1234        1234        1250 (1237)     2499 (2473)
#*PANTA.SCR    P-2340,4092 S-1190/1190 0-1186,1-2374 F-2c B8 L-  263 C? P-0.016
#*------------ P-2340,4096 S-1190/1190 0-1187,1-2375 F-16 B8 L- 2069 C? P-4.601
#BLOQUE_TURBO_SPEED_WRITE_0 = ID_BLOQUE_TURBO + \
#                               '\xC0' + '\x08' + \
#                               '\x60' + '\x04' + \
#                               '\x60' + '\x04' + \
#                               '\x60' + '\x04' + \
#                               '\xC0' + '\x08' + \
#                               '\x00' + '\x10' + \
#                               '\x08'                   

# samp2cdt de bloques reales en un 464+
# -------------------------------------
# Speed Write 0
# Pausa inicial 3.533 ms 
# Pausa entre cabecera y datos 16 ms
# Pausa entre bloques 4.601 ms
# Pilot pulse   Length          Sync1       Sync2       Bit 0           Bit 1
# 2340          4092 (4096)     1190        1190        1186 (1187)     2374 (2375)
# *PANTA.SCR    P-2340,4092 S-1190/1190 0-1186,1-2374 F-2c B8 L-  263 C? P-0.016
# *------------ P-2340,4096 S-1190/1190 0-1187,1-2375 F-16 B8 L- 2069 C? P-4.601
# Cabecera
#BLOQUE_TURBO_SPEED_WRITE_0 = ID_BLOQUE_TURBO + \
#                               '\x24' + '\x09' + \
#                               '\xA6' + '\x04' + \
#                               '\xA6' + '\x04' + \
#                               '\xA2' + '\x04' + \
#                               '\x46' + '\x09' + \
#                               '\xFC' + '\x0F' + \
#                               '\x08'                   
# Datos
BLOQUE_TURBO_SPEED_WRITE_0 = ID_BLOQUE_TURBO + \
                               '\x24' + '\x09' + \
                               '\xA6' + '\x04' + \
                               '\xA6' + '\x04' + \
                               '\xA3' + '\x04' + \
                               '\x47' + '\x09' + \
                               '\x00' + '\x10' + \
                               '\x08'                   

# Speed Write 1
# Pausa inicial 3.533 ms 
# Pausa entre cabecera y datos 15 ms
# Pausa entre bloques 4.601 ms 
# Pilot pulse   Length          Sync1       Sync2           Bit 0           Bit 1
# 1164          4087 (4096)     635         635 (556)       606 (607)       1214 (1215)
# *PANTA.SCR    P-1164,4087 S- 635/ 635 0- 606,1-1214 F-2c B8 L-  263 C? P-0.015
# *------------ P-1164,4096 S- 635/ 556 0- 607,1-1215 F-16 B8 L- 2069 C?
# Cabecera
#BLOQUE_TURBO_SPEED_WRITE_1 = ID_BLOQUE_TURBO + \
#                               '\x8C' + '\x04' + \
#                               '\x7B' + '\x02' + \
#                               '\x7B' + '\x02' + \
#                               '\x5E' + '\x02' + \
#                               '\xBE' + '\x04' + \
#                               '\xF7' + '\x0F' + \
#                               '\x08'                   
# Datos
BLOQUE_TURBO_SPEED_WRITE_1 = ID_BLOQUE_TURBO + \
                               '\x8C' + '\x04' + \
                               '\x7B' + '\x02' + \
                               '\x2C' + '\x02' + \
                               '\x5F' + '\x02' + \
                               '\xBF' + '\x04' + \
                               '\x00' + '\x10' + \
                               '\x08'                   

# Funciones adicionales
def calcula_checksum(bloque):
    """
    Calculamos el checksum de un bloque de 256 bytes 
    """
    # Constantes
    SEMILLA_CRC = 0xFFFF    # Semilla del CRC
    MASCARA_CRC = 0x1021    # Máscara de CRC-16-CCITT (ISO 3309 / x^16 + x^12 + x^5 + 1)

    crc_tmp = SEMILLA_CRC   # Inicializamos el CRC
    for i in bloque:
        crc_tmp = crc_tmp ^ (ord(i) << 8)
        for j in range(8):
            if (crc_tmp & 0x8000):
                crc_tmp = (crc_tmp << 1) ^ MASCARA_CRC
            else:
                crc_tmp = crc_tmp << 1
    crc_tmp = (crc_tmp & 0xFFFF) ^ 0xFFFF  # Y hacemos el complemento a 1 del CRC
    
    return chr(crc_tmp // 256) + chr(crc_tmp % 256)

def convierte_3_bytes(numero):
    """
    Convierte 3 bytes a little endian
    """
    cadena_3_bytes = chr(numero % 256)
    tmp = numero // 256
    cadena_3_bytes += chr(tmp % 256)
    cadena_3_bytes += chr(tmp // 256)
    return cadena_3_bytes

def genera_bloques_firmware(cabecera, datos, cdt_bloque_turbo):
    """
    Genera los bloques del firmware en base a la cabecera y los datos
    """
    cinta = ""

    cabecera = convierte_cabecera_cinta(cabecera)
    numero_de_bloques = len(datos) // LONGITUD_BLOQUE_CINTA

    for i in range(numero_de_bloques):
        # Añadimos la cabecera del bloque de datos a la cinta
        cinta += cdt_bloque_turbo + PAUSA_CABECERA_FIRMWARE
        cinta += convierte_3_bytes(len(cabecera) + 1 + 2 + 4)   # 1 (Sincronía) + 2 (CRC) + 4 (Cola)
        cinta += SINCRONIA_BLOQUE_CABECERA
        # Modificamos algunos campos de la cabecera
        lista_cabecera = list(cabecera)
        lista_cabecera[NUMERO_BLOQUE] = chr(i + 1)     # Número de bloques
        if i:
            lista_cabecera[PRIMER_BLOQUE] = BYTE_NULO
        else:
            lista_cabecera[PRIMER_BLOQUE] = BLOQUE_ESPECIAL # Es el primer bloque

        if (not(len(datos) % LONGITUD_BLOQUE_CINTA)) and (i == (numero_de_bloques - 1)):
            lista_cabecera[ULTIMO_BLOQUE] = BLOQUE_ESPECIAL   # Es el último bloque
        else:
            lista_cabecera[ULTIMO_BLOQUE] = BYTE_NULO
        lista_cabecera[LONGITUD_BLOQUE_DATOS] = chr(LONGITUD_BLOQUE_CINTA % 256)
        lista_cabecera[LONGITUD_BLOQUE_DATOS + 1] = chr(LONGITUD_BLOQUE_CINTA // 256)
        cabecera = "".join(lista_cabecera)
        cinta += cabecera
        cinta += calcula_checksum(cabecera)
        cinta += COLA_BLOQUE

        # Añadimos el bloque de datos a la cinta
        cinta += cdt_bloque_turbo + PAUSA_DATOS_FIRMWARE
        cinta += convierte_3_bytes(LONGITUD_BLOQUE_CINTA + 1 + (2 * 8) + 4)   # 1 (Sincronía) + 2 (CRC) * 8 (Segmentos) + 4 (Cola) 
        cinta += SINCRONIA_BLOQUE_DATOS
        datos_bloque = datos[i * LONGITUD_BLOQUE_CINTA: i * LONGITUD_BLOQUE_CINTA + LONGITUD_BLOQUE_CINTA]
        for j in range(8):      # Hay 8 segmentos de 256 bytes por cada bloque de 2048
            datos_segmento = datos_bloque[j * LONGITUD_SEGMENTO_BLOQUE: j * LONGITUD_SEGMENTO_BLOQUE + LONGITUD_SEGMENTO_BLOQUE]
            cinta += datos_segmento + calcula_checksum(datos_segmento)
        cinta += COLA_BLOQUE

    if (len(datos) % LONGITUD_BLOQUE_CINTA):     # Hay un bloque adicional
        datos_bloque = datos[numero_de_bloques * LONGITUD_BLOQUE_CINTA: ]
        # Añadimos la cabecera del último bloque de datos a la cinta
        cinta += cdt_bloque_turbo + PAUSA_CABECERA_FIRMWARE
        cinta += convierte_3_bytes(len(cabecera) + 1 + 2 + 4)   # 1 (Sincronía) + 2 (CRC) + 4 (Cola)
        cinta += SINCRONIA_BLOQUE_CABECERA
        # Modificamos algunos campos de la cabecera
        lista_cabecera = list(cabecera)
        lista_cabecera[NUMERO_BLOQUE] = chr(numero_de_bloques + 1)
        lista_cabecera[PRIMER_BLOQUE] = (BYTE_NULO if numero_de_bloques else BLOQUE_ESPECIAL)
        lista_cabecera[ULTIMO_BLOQUE] = BLOQUE_ESPECIAL         # Es el último bloque
        lista_cabecera[LONGITUD_BLOQUE_DATOS] = chr(len(datos_bloque) % 256)
        lista_cabecera[LONGITUD_BLOQUE_DATOS + 1] = chr(len(datos_bloque) // 256)
        cabecera = "".join(lista_cabecera)
        cinta += cabecera
        cinta += calcula_checksum(cabecera)
        cinta += COLA_BLOQUE
        # Añadimos el último bloque de datos a la cinta
        cinta += cdt_bloque_turbo + PAUSA_DATOS_FIRMWARE
        # Añadimos los bytes necesarios para completar el último segmento
        for i in range(LONGITUD_SEGMENTO_BLOQUE - (len(datos_bloque) % LONGITUD_SEGMENTO_BLOQUE)):
            datos_bloque += BYTE_NULO
        cinta += convierte_3_bytes(len(datos_bloque) + 1 + (2 * (len(datos_bloque) // LONGITUD_SEGMENTO_BLOQUE)) + 4)
        cinta += SINCRONIA_BLOQUE_DATOS
        for j in range(len(datos_bloque) // LONGITUD_SEGMENTO_BLOQUE):
            datos_segmento = datos_bloque[j * LONGITUD_SEGMENTO_BLOQUE: j * LONGITUD_SEGMENTO_BLOQUE + LONGITUD_SEGMENTO_BLOQUE]
            cinta += datos_segmento + calcula_checksum(datos_segmento) 
        cinta += COLA_BLOQUE
    return cinta

def convierte_cabecera_cinta(cabecera_amsdos):
    """
    Convierte la cabecera del amsdos a una cabecera de cinta válida y
    añade el byte de sincronía y el crc
    """
#    cabecera_cinta = ""
    cabecera_amsdos = cabecera_amsdos[:LONGITUD_CABECERA_CINTA]
#    for i in range(15):      # Copiamos el nombre a su posición
#        cabecera_cinta += cabecera_amsdos[i + 1]
#    cabecera_cinta += BYTE_NULO
#    cabecera_cinta +=  cabecera_amsdos[16: LONGITUD_CABECERA_CINTA]
    cabecera_amsdos += BYTE_NULO * (LONGITUD_SEGMENTO_BLOQUE - LONGITUD_CABECERA_CINTA)
    return cabecera_amsdos

def lee_fichero_con_amsdos(nombre_fichero):
    """
    Lee un archivo con cabecera del amsdos
    """
    cabecera = ""
    datos = ""
    with open(nombre_fichero, "r") as fichero:
        print("Opening file: " + path.basename(nombre_fichero))
        cabecera = fichero.read(LONGITUD_CABECERA_AMSDOS)
        datos = fichero.read()

        # Insertamos el nombre del fichero en la cabecera
        nombre_fichero = path.basename(nombre_fichero)
        if (len(nombre_fichero) < 16):
            nombre_fichero += BYTE_NULO * (16 - len(nombre_fichero))
        lista_cabecera = list(cabecera)
        for i in range(16):     # Copiamos el nombre a su posición
            lista_cabecera[i] = nombre_fichero[i]
        cabecera = "".join(lista_cabecera)

    return cabecera, datos

def genera_bloques_turbo(datos, baud_rate): # , tipo_turbo):
    """
    Genera los bloques turbo en base a los datos y la velocidad media en baudios
    """
    cinta = ""

    # MFTL1 => Mi primera carga turbo :P 
    # Sync1 = Sync2 = Bit0 | Pilot Pulse= Bit1 | Length = 2048 | Bit0 = Bit1 / 2
    # Pilot pulse     Length      Sync1       Sync2       Bit 0       Bit 1
    # Bit 1           2048        Bit 0       Bit 0       Bit 0       Bit 1

    # Longitud de los bits a 0 para el cdt en microsegundos = 4 * (10^6 * 35) / (39 * 3 velocidad media en baudios)
    # 3.500.000 T-estados del spectrum / 3.939.600 T-estados del cpc
    pulso_de_bit_cero = int(round(((1e6 * 35) / (39 * 3 * baud_rate)) * 4))
    pulso_de_bit_uno = pulso_de_bit_cero * 2        # bits a 1 = (bits a 0) * 2
    print("Bit a 0: %d t-states %d ms" % (pulso_de_bit_cero, pulso_de_bit_cero // 4))
    print("Bit a 1: %d t-states %d ms" % (pulso_de_bit_uno, pulso_de_bit_uno // 4))

    cadena_cero = chr(pulso_de_bit_cero % 256) + chr(pulso_de_bit_cero // 256)
    cadena_uno = chr(pulso_de_bit_uno % 256) + chr(pulso_de_bit_uno // 256)

    # Añadimos la cabecera del bloque turbo para el cdt
    cinta += ID_BLOQUE_TURBO
    cinta += cadena_uno                     # Pilot pulse (bits a 1)
    cinta += cadena_cero                    # Sync1
    cinta += cadena_cero                    # Sync2
    cinta += cadena_cero                    # Zero bit pulse
    cinta += cadena_uno                     # One bit pulse
    cinta += '\x00' + '\x08'                # Number of pulses of pilot tone 2048
    cinta += '\x08'                         # Used bits in the last byte
    cinta += PAUSA_DATOS_FIRMWARE           # Pause after this block (2000 ms)
    cinta += convierte_3_bytes(len(datos))  # Length of data
    cinta += datos                          # Datas

    return cinta

def lee_fichero_sin_amsdos(nombre_fichero):
    """
    Lee un fichero
    """
    datos = ""
    with open(nombre_fichero, "r") as fichero:
        print("Opening file: " + path.basename(nombre_fichero))
        datos = fichero.read()
    return datos

def escribe_fichero(nombre_fichero, contenido):
    """
    Guarda un fichero
    """
    with open(nombre_fichero, "wb") as fichero:
        fichero.write(contenido)

# Procesa la línea de comandos    
def procesar_linea_comandos(linea_de_comandos):
    """
    Devuelve una tupla de dos elementos: (opciones, lista_de_ficheros).
    `linea_de_comandos` es una lista de argumentos, o `None` para ``sys.argv[1:]``.
    """
    if linea_de_comandos is None:
        linea_de_comandos = sys.argv[1:]

    version_programa = "%prog v0.1"
    uso_programa = "usage: %prog [options] file1 file2 ... fileX"
    descripcion_programa = "%prog generate .cdt archive with the parameter files."

    # definimos las opciones que soportaremos desde la línea de comandos
    lista_de_opciones = [
        make_option("-b", "--baud_rate", action="store", type="int", dest="baud_rate", default=1000, help="Baud rate for turbo data"),
        make_option("-f", "--firmware", action="store_true", dest="firmware", default=False, help="Use firmware loader"),
        make_option("-o", "--output", action="store", type="string", dest="fichero_salida", default="tape.cdt", help="Name for the tape file"),        
        make_option("-s", "--speed_write", action="store", type="int", dest="speed_write", default=0, help="Speed write for formware loader")
    ]
        
    parser = OptionParser(usage=uso_programa, description=descripcion_programa,
        version=version_programa, option_list=lista_de_opciones)
    
    # obtenemos las opciones y la lista de ficheros suministradas al programa
    (opciones, lista_ficheros_tmp) = parser.parse_args(linea_de_comandos)

    # comprobamos el número de argumentos y verificamos los valores
    if (not lista_ficheros_tmp):
        parser.error("No files to process.")
    else:
        lista_ficheros = []
        for i in lista_ficheros_tmp:
            lista_ficheros += glob.glob(i)

    if (opciones.speed_write < 0) or (opciones.speed_write > 1):
        parser.error("Speed write is out of range.")

    if (opciones.baud_rate < 0) or (opciones.baud_rate > 4000):
        parser.error("Baud rate is out of range.")

    return opciones, lista_ficheros

# Función principal
def main(linea_de_comandos=None):
    """
    Función principal
    """

    # Obtenemos las opciones y argumentos suministrados al programa
    opciones, lista_ficheros = procesar_linea_comandos(linea_de_comandos)

    # Inicializamos la estructura del .CDT para el tipo de bloque turbo en base a la velocidad seleccionada
    if (opciones.speed_write):
        cdt_bloque_turbo = BLOQUE_TURBO_SPEED_WRITE_1
    else:
        cdt_bloque_turbo = BLOQUE_TURBO_SPEED_WRITE_0

    # Inicializamos la cinta
    cinta = ""

    # Añadimos la cabecera del formato CDT
    cinta += CABECERA_CDT

    # Añadimos la pausa inicial para que la cinta tome una velocidad constante
    cinta += ID_BLOQUE_PAUSA + PAUSA_INICIAL_CDT

    # Leemos el fichero cargador
    cabecera, datos = lee_fichero_con_amsdos(lista_ficheros[0])
    if ((cabecera == "") or (datos == "")): # ¿Hubo algún problema con el cargador?
        return 1    # EXIT_FAILURE

    # Y lo añadimos a la cinta
    cinta += genera_bloques_firmware(cabecera, datos, cdt_bloque_turbo)

    # Leemos el resto de ficheros y los vamos añadiendo
    lista_ficheros = lista_ficheros[1:]
    for nombre_fichero in lista_ficheros:
        if opciones.firmware:
            # Leemos el fichero usando el Amsdos
            cabecera, datos = lee_fichero_con_amsdos(nombre_fichero)
            if ((cabecera == "") or (datos == "")):
                continue    # Pasamos al siguiente fichero
            else:   # Y lo añadimos a la cinta
                cinta += genera_bloques_firmware(cabecera, datos, cdt_bloque_turbo)
        else:
            datos = lee_fichero_sin_amsdos(nombre_fichero)
            if (datos == ""):
                continue    # Pasamos al siguiente fichero
            else:   # Y lo añadimos a la cinta
                cinta += genera_bloques_turbo(datos, opciones.baud_rate)
           
    escribe_fichero(opciones.fichero_salida, cinta)

    return 0    # EXIT_SUCCESS

if __name__ == "__main__":
    estado = main()
    sys.exit(estado)
