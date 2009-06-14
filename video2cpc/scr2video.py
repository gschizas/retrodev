#! /usr/bin/env python
# -*- coding: utf-8 -*-

# scr2cpc
# (c) MML, 2009

# Parches para que funcione en python 2.5
from __future__ import with_statement
from __future__ import division

import sys
import os        # path.exists(), listdir()
import glob        # glob() expande los patrones de los ficheros
#from math import sqrt, pow        # sqrt()
from math import log10
#import Image
from optparse import make_option, OptionParser
#import hashlib    # para calcular el sha1 de los patrones

# Marcadores de compresión
CMP_COPY = 0x00
CMP_SKIP = 0x50
CMP_REPEAT = 0xA0
CMP_END_SCANLINE = 0xFD
CMP_END_SCREEN = 0xFE
CMP_END_VIDEO = 0xFF

# Dimensiones del video
ANCHO_VIDEO = 128
ALTO_VIDEO = 96
LINEA_COMIENZO = 14

# Ancho en pixels de un byte según la resolución del CPC
pixels_por_byte = (2, 4, 8)

# Paleta del CPC
# Número de tinta del firmware : Tinta + Color Hardware (lista para el Gate Array)
paleta_cpc = [
    64 + 20,         # Negro
    64 + 4,         # Azul
    64 + 21,         # Azul Brillante
    64 + 28,         # Rojo
    64 + 24,         # Magenta
    64 + 29,         # Malva
    64 + 12,         # Rojo Brillante
    64 + 5,         # Purpura
    64 + 13,         # Magenta Brillante
    64 + 22,         # Verde
    64 + 6,         # Cian
    64 + 23,         # Azul Cielo
    64 + 30,         # Amarillo
    64 + 0,         # Blanco
    64 + 31,         # Azul Pastel
    64 + 14,         # Naranja
    64 + 7,         # Rosa
    64 + 15,         # Magenta Pastel
    64 + 18,         # Verde Brillante
    64 + 2,         # Verde Mar
    64 + 19,         # Cian Brillante
    64 + 26,         # Lima
    64 + 25,         # Verde Pastel
    64 + 27,         # Cian Pastel
    64 + 10,         # Amarillo Brillante
    64 + 3,         # Amarillo Pastel
    64 + 11         # Blanco Brillante
]

def convierte_frame(cadena_imagen, ancho_imagen, alto_imagen, lista_scanlines):
    """
    Convierte los frames del video
    """
    # La paleta se encuentra en 0x17D1
    paleta = ""
    for i in range(16):        # Y son 16 colores
        paleta += chr(paleta_cpc[ord(cadena_imagen[0x17d1 + i])])
    
    imagen = ""
    for i in range(alto_imagen):
        dir_tmp = lista_scanlines[i] - 0xC000
        imagen += cadena_imagen[dir_tmp : dir_tmp + ancho_imagen]

    calcula_entropia_orden0(imagen)
    calcula_entropia_orden1(imagen)
    return paleta, imagen

def calcula_entropia_orden0(imagen):
    """
    Calculo de la entropia de la imagen
    """

    lista_frecuencias = []
    for i in range(256):
        lista_frecuencias.append(0)

    for i in range(len(imagen)):
        lista_frecuencias[ord(imagen[i])] += 1

    entropia = 0.0
    for i in range(256):
        if (lista_frecuencias[i]):
            frecuencia = lista_frecuencias[i] / len(imagen)
            entropia += -(frecuencia * (log10(frecuencia) * 3.3219))
    print "Longitud del fichero %d" % len(imagen)
    print "Bits por byte: %.2f" % entropia
    print "Porcentaje de compresión: %.2f %%" % (100 - ((entropia * 100) / 8))
    print "Longitud teórica del fichero comprimido %d" % ((len(imagen)  * (100 - ((entropia * 100) / 8))) // 100)
    print

def calcula_entropia_orden1(imagen):
    """
    Calculo de la entropia de la imagen
    """

    lista_frecuencias_tmp = []
    for i in range(256):
        lista_frecuencias_tmp.append(0)

    lista_frecuencias = []
    for i in range(256):
        lista_frecuencias.append(lista_frecuencias_tmp)

    for i in range(len(imagen) // 2):
        lista_frecuencias[ord(imagen[i * 2])] [ord(imagen[(i * 2) + 1])] += 1
        print ord(imagen[i*2]),ord(imagen[(i*2)+1]),
    entropia = 0.0
    for i in range(256):
        for j in range(256):
            if (lista_frecuencias[i][j]):
                frecuencia = lista_frecuencias[i][j] / len(imagen)
                entropia += -(frecuencia * (log10(frecuencia) * 3.3219))
    print "Longitud del fichero %d" % len(imagen)
    print "Bits por byte: %.2f" % entropia
    print "Porcentaje de compresión: %.2f %%" % (100 - ((entropia * 100) / 8))
    print "Longitud teórica del fichero comprimido %d" % ((len(imagen)  * (100 - ((entropia * 100) / 8))) // 100)
    print

def diff_paleta(paleta_vieja, paleta_nueva):
    """
    Diferencias entre los frames de las paletas
    """
    paleta_final = ""
    for i in range(len(paleta_nueva)):
        if (i < len(paleta_vieja)):
            if (paleta_nueva[i] <> paleta_vieja[i]):
                paleta_final += chr(i) + paleta_nueva[i]
        else:
            paleta_final += chr(i) + paleta_nueva[i]
    return chr(len(paleta_final) // 2) + paleta_final
    
def comprime_scanline(scanline_vieja, scanline_nueva): #, dir_scanline):
    """
    Comprime un scanline
    """
    #scanline_final = chr(dir_scanline % 256) + chr(dir_scanline // 256)
    scanline_final = ""
    contador_skip = 0
    contador_repeticiones = 0
    cadena_a_copiar = ""
    byte_anterior = ""
    #print "Longitud scanline: %d" % (len(scanline_nueva))
    for i in range(len(scanline_nueva)):
        byte_actual = scanline_nueva[i]
        if (byte_actual == scanline_vieja[i]):
                contador_skip += 1
                # ¿Hay un COPY pendiente?
                if (len(cadena_a_copiar)):
                    cadena_a_copiar += byte_anterior    # Hay que añadir el byte anterior
                    #print "COPY pendiente: %d" % (len(cadena_a_copiar)),
                    scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
                    cadena_a_copiar = ""
                elif (contador_repeticiones):    # ¿Hay un REPEAT pendiente?
                    #print "REPEAT pendiente: %d" % contador_repeticiones,
                    scanline_final += chr(CMP_REPEAT + contador_repeticiones) + byte_anterior
                    contador_repeticiones = 0
                elif (i <> 0) and (byte_anterior <> scanline_vieja[i - 1]):
                    cadena_a_copiar += byte_anterior    # Hay que añadir el byte anterior
                    #print "COPY pendiente: %d" % (len(cadena_a_copiar)),
                    scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
                    cadena_a_copiar = ""
        else:    # byte_actual <> scanline_vieja[i]
            if (contador_skip):
                #print "SKIP: %d" % (contador_skip - 1),
                scanline_final += chr(CMP_SKIP + contador_skip - 1)
                contador_skip = 0
                if (i == (len(scanline_nueva) - 1)):    # Hay que añadir el byte anterior
                    cadena_a_copiar += byte_actual
            else:
                if (byte_actual <> byte_anterior):
                    if (contador_repeticiones):
                        #print "REPEAT: %d" % contador_repeticiones,
                        scanline_final += chr(CMP_REPEAT + contador_repeticiones) + byte_anterior
                        contador_repeticiones = 0
                    else:
                        cadena_a_copiar += byte_anterior
                    if (i == (len(scanline_nueva) - 1)):    # Hay que añadir el byte anterior
                        cadena_a_copiar += byte_actual
                else:    # byte_actual == byte_anterior
                    contador_repeticiones += 1
                    if ((contador_repeticiones == 1) and len(cadena_a_copiar)):
                        #print "COPY: %d" % (len(cadena_a_copiar)),
                        scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
                        cadena_a_copiar = ""
        byte_anterior = byte_actual
    else:    # else del for
        # ¿Hay un SKIP pendiente? (si hay un skip pendiente, ponemos CMP_END_SCANLINE y nos lo ahorramos)
        #if (contador_skip):
        #    #print "SKIP final: %d" % (contador_skip - 1),
        #    scanline_final += chr(CMP_SKIP + contador_skip - 1)
        # ¿Hay un COPY pendiente?
        if (len(cadena_a_copiar)):
            #print "COPY final: %d" % (len(cadena_a_copiar)),
            scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
        # ¿Hay un REPEAT pendiente?
        if (contador_repeticiones):
            #print "REPEAT final: %d" % contador_repeticiones,
            scanline_final += chr(CMP_REPEAT + contador_repeticiones) + byte_anterior
    
    #print "LEN final: %d" % (len(scanline_final) - 2)
    #print ""
    #descomprime_scanline(scanline_nueva, scanline_final[2:])

    scanline_final +=  chr(CMP_END_SCANLINE)
    
    return scanline_final

def optimiza_video(lista_frames, pack_mode, scanlines): #, lista_scanlines):
    """
    Optimiza el video
    """
    ancho_bytes_scanline = 64
    alto_pantalla = (200 if scanlines else 100) # len(lista_scanlines)
    alto_scanlines = (2 if scanlines else 1)
    paleta_vieja = ""
    imagen_vieja_par = chr(0) * len(lista_frames[0][1])    # Pantalla inicializada a 0 (imagen_vieja = "")
    imagen_vieja_impar = chr(0) * len(lista_frames[0][1])    # Pantalla inicializada a 0 (imagen_vieja = "")
    for i in range(len(lista_frames)):
        paleta_nueva = lista_frames[i][0]
        imagen_nueva = lista_frames[i][1]
        contador = 0
        imagen_tmp = ""
        for j in range(0, alto_pantalla, alto_scanlines):
            if (i % 2):
                scanline_vieja = imagen_vieja_impar[contador : contador + ancho_bytes_scanline]
            else:
                scanline_vieja = imagen_vieja_par[contador : contador + ancho_bytes_scanline]
            scanline_nueva = imagen_nueva[contador : contador + ancho_bytes_scanline]
            imagen_tmp += comprime_scanline(scanline_vieja, scanline_nueva) #, lista_scanlines[j])
            contador += ancho_bytes_scanline
        # Si las últimas líneas de pantalla son CMP_END_SCANLINE las recortamos
        longitud_imagen_tmp = len(imagen_tmp) - 1
        cnt = 0
        fin_bucle = False
        k = 0
        while (not (fin_bucle)) and (k <= longitud_imagen_tmp):
            if (imagen_tmp[longitud_imagen_tmp - k] == chr(CMP_END_SCANLINE)):
                cnt += 1
            else:
                fin_bucle = True
            k += 1
        # Si la pantalla es igual a la anterior lo reducimos a cambios de paleta, CMP_END_SCREEN
        if (cnt <> (alto_pantalla//alto_scanlines)):
            cnt -= 2
        else:
            cnt -= 1
        imagen_tmp = imagen_tmp[ : longitud_imagen_tmp - cnt]
        print "Imagen: %d" % len(imagen_tmp)
        lista_frames[i] = diff_paleta(paleta_vieja, paleta_nueva) + imagen_tmp + chr(CMP_END_SCREEN)
        paleta_vieja = paleta_nueva
        if (i % 2):
            imagen_vieja_impar = imagen_nueva
        else:
            imagen_vieja_par = imagen_nueva
    return lista_frames

# Funciones para guardar en disco los datos convertidos
def guarda_archivo(nombre, contenido):
    """
    Guarda un archivo en en disco
    """
    with open(nombre,"wb") as f:
        f.write(contenido)

# Procesa la línea de comandos    
def procesar_linea_comandos(linea_de_comandos):
    """
    Devuelve una tupla de dos elementos: (opciones, lista_de_ficheros).
    `linea_de_comandos` es una lista de argumentos, o `None` para ``sys.argv[1:]``.
    """
    if linea_de_comandos is None:
        linea_de_comandos = sys.argv[1:]

    version_programa = "%prog v0.1"
    uso_programa = "usage: %prog [options] img1.scr img2.scr ... imgX.scr"
    descripcion_programa = "%prog convert images in scr format to video data for Amstrad CPC."

    # definimos las opciones que soportaremos desde la lnea de comandos
    lista_de_opciones = [
        make_option("-o", "--output", action="store", type="string", dest="fichero_salida", default="peli.vid", help="Name for the video file"),
        make_option("-p", "--pack", action="store", type="int", dest="pack_mode", default=0, help="Select pack mode (8 bits, 16 bits...)"),
        make_option("-r", "--mode", action="store", type="int", dest="mode", default=0, help="Select screen mode (0, 1, 2)"),
        make_option("-s", "--scanlines", action="store_true", dest="scanlines", default=False, help="Generate scanlines")
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
        if not (len(lista_ficheros)):
            parser.error("No files to process.")
    if (opciones.mode < 0) or (opciones.mode > 2):
        parser.error("Screen mode is out of range.")

    return opciones, lista_ficheros

# Función principal
def main(linea_de_comandos=None):
    # obtenemos las opciones y argumentos suministrados al programa
    opciones, lista_ficheros = procesar_linea_comandos(linea_de_comandos)

    # opciones.mode contiene el modo de resolución del cpc

    # Obtenemos el número de imagenes de las que consta el video
    print u"El video consta de %d imagenes." % len(lista_ficheros)

    # Obtenemos el ancho y el alto del video
    ancho_imagen, alto_imagen = ANCHO_VIDEO, ALTO_VIDEO
    print u"Las imagenes del video son de %d x %d pixels." % (ancho_imagen, alto_imagen)

    # Inicializamos las constantes de los marcadores del compresor
    ancho_en_bytes_imagen = ancho_imagen // pixels_por_byte[opciones.mode]

    # Si vamos a modificar variables globales, hay que indicarselo a python antes,
    # en caso contrario creará variables locales.    
    global CMP_COPY, CMP_SKIP, CMP_REPEAT 
    if ((ancho_en_bytes_imagen * 3) < 256):
        CMP_COPY = 0x00
        CMP_SKIP = ancho_en_bytes_imagen
        CMP_REPEAT = ancho_en_bytes_imagen * 2
    else:
        print u"ERROR: Las imagenes son muy anchas y necesitas activar el modo de 16 bits para el compresor (TODO)."
        return 1    # Salimos del programa con un error
    # Generamos los comienzos de los scanlines (old)
    lista_scanlines_old = []
    comienzo = 0xC000
    lista_scanlines_old.append(comienzo)
    for i in range(1, (200 if opciones.scanlines else 100)):        # (alto_imagen * 2 if opciones.scanlines else alto_imagen)):
        comienzo += 0x0800
        comienzo += (0x0000 if (i % 8) else (0xC000 + 80))    # ancho_en_bytes_imagen))
        comienzo = comienzo & 0xFFFF
        lista_scanlines_old.append(comienzo)
    # Generamos los comienzos de los scanlines (new)
    #lista_scanlines_new = []
    #comienzo = 0xC000
    #lista_scanlines_new.append(comienzo)
    #for i in range(1, (200 if opciones.scanlines else 100)):        # (alto_imagen * 2 if opciones.scanlines else alto_imagen)):
    #    comienzo += 0x0800
    #    comienzo += (0x0000 if (i % 8) else (0xC000 + ancho_en_bytes_imagen))
    #    comienzo = comienzo & 0xFFFF
    #    lista_scanlines_new.append(comienzo)

    lista_frames = []
    
    for nombre_imagen in lista_ficheros:
        print u"Abriendo el fichero de imagen: " + nombre_imagen

        imagen_scr = ""
        with open(nombre_imagen, "rb") as f:    # Abrimos el fichero    
            f.seek(128, 0)                        # Saltamos la cabecera del AMSDOS
            imagen_scr = f.read()                # Y lo cargamos en memoria

        if len(imagen_scr):
            # Vamos añadiendo las parejas (paleta, imagen) a la lista
            lista_frames.append(convierte_frame(imagen_scr, ancho_imagen // pixels_por_byte[opciones.mode], alto_imagen, lista_scanlines_old))
            
        else:
            print u"ERROR: Se produjo un error con el fichero %s." % nombre_imagen
            return 1    # Salimos del programa con un error
        
    
    # Optimizamos el video
    lista_frames = optimiza_video(lista_frames, opciones.pack_mode, opciones.scanlines) #, lista_scanlines_new)

    # Y lo guardamos en disco
    guarda_archivo(opciones.fichero_salida, "".join(lista_frames) + chr(CMP_END_VIDEO))

    return 0    # EXIT_SUCCESS

if __name__ == "__main__":
    estado = main()
    sys.exit(estado)
