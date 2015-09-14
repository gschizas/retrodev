#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
png2plus
(c) MML, 2009
"""

# TODO: Integrar la compresión.

# Parches para que funcione en python 2.5


import sys
import os           # path.exists()
import glob         # glob() expande los patrones de los ficheros en windows
import Image
from optparse import make_option, OptionParser

# Ancho en pixels de un byte según la resolución del CPC
pixels_por_byte = (2, 4, 8)

# Funciones de conversión de las imagenes
def extrae_imagen(fichero_imagen, modo_imagen, ancho_imagen, alto_imagen):
    """
    Extrae las capas RGB de la imagen
    """
    capa_rojo = capa_verde = capa_azul = ""
    imagen_tmp = list(fichero_imagen.getdata())

    if (modo_imagen=="RGB") or (modo_imagen=="RGBA"):
        for i in range(alto_imagen * ancho_imagen):
            capa_rojo += chr(imagen_tmp[i][0] >> 4)
            capa_verde += chr(imagen_tmp[i][1] >> 4)
            capa_azul += chr(imagen_tmp[i][2] >> 4)
    else:
        print("Modo no soportado.")

    return capa_rojo, capa_verde, capa_azul

def convierte_graficos(cadena, ppb):
    """
    Convierte una cadena de bytes a un modo del CPC
    """
    cadena_final = ""
    for i in range(len(cadena) // ppb):
        if ppb == 2:
            byte_tmp0 = ord(cadena[i * ppb])
            byte_tmp1 = ord(cadena[i * ppb + 1])
            # p1b3->b0 p1b2->b4
            # p1b1->b2 p1b0->b6
            # p0b3->b1 p0b2->b5
            # p0b1->b3 p0b0->b7
            byte_tmp = chr(((byte_tmp1 & 0x08) >> 3) | ((byte_tmp1 & 0x04) << 2) | \
                        ((byte_tmp1 & 0x02) << 1) | ((byte_tmp1 & 0x01) << 6) | \
                        ((byte_tmp0 & 0x08) >> 2) | ((byte_tmp0 & 0x04) << 3) | \
                        ((byte_tmp0 & 0x02) << 2) | ((byte_tmp0 & 0x01) << 7))
        elif ppb == 4:
            byte_tmp0 = ord(cadena[i * ppb])
            byte_tmp1 = ord(cadena[i * ppb + 1])
            byte_tmp2 = ord(cadena[i * ppb + 2])
            byte_tmp3 = ord(cadena[i * ppb + 3])
            # p3b1->b0 p3b0->b4
            # p2b1->b1 p2b0->b5
            # p1b1->b2 p1b0->b6
            # p0b1->b3 p0b0->b7
            byte_tmp = chr(((byte_tmp3 & 0x02) >> 1) | ((byte_tmp3 & 0x01) << 4) | \
                        ((byte_tmp2 & 0x02)) | ((byte_tmp2 & 0x01) << 5) | \
                        ((byte_tmp1 & 0x02) << 1) | ((byte_tmp1 & 0x01) << 6) | \
                        ((byte_tmp0 & 0x02) << 2) | ((byte_tmp0 & 0x01) << 7))
        elif ppb == 8:
            byte_tmp0 = ord(cadena[i * ppb])
            byte_tmp1 = ord(cadena[i * ppb + 1])
            byte_tmp2 = ord(cadena[i * ppb + 2])
            byte_tmp3 = ord(cadena[i * ppb + 3])
            byte_tmp4 = ord(cadena[i * ppb + 4])
            byte_tmp5 = ord(cadena[i * ppb + 5])
            byte_tmp6 = ord(cadena[i * ppb + 6])
            byte_tmp7 = ord(cadena[i * ppb + 7])
            # p7b0->b0 p6b0->b1
            # p5b0->b2 p4b0->b3
            # p3b0->b4 p2b0->b5
            # p1b0->b6 p0b0->b7
            byte_tmp = chr(((byte_tmp7 & 0x01)) | ((byte_tmp6 & 0x01) << 1) | \
                        ((byte_tmp5 & 0x01) << 2) | ((byte_tmp4 & 0x01) << 3) | \
                        ((byte_tmp3 & 0x01) << 4) | ((byte_tmp2 & 0x01) << 5) | \
                        ((byte_tmp1 & 0x01) << 6) | ((byte_tmp0 & 0x01) << 7))
        cadena_final = cadena_final + byte_tmp
    return cadena_final

def genera_volcado_de_pantalla(capa, alto, ancho_en_bytes):
    """
    Convierte la capa de color a un volcado de pantalla de cpc
    """
    capa_tmp = [""] * 8     # Inicializamos una lista a elementos nulos
    contador = 0
    # Reordenamos los scanlines de los bloques de 2 Kb
    for i in range(0, alto, 8):
        for j in range(8):
            capa_tmp[j] += capa[contador : contador + ancho_en_bytes]
            contador += ancho_en_bytes

    # Añadimos los bytes adicionales a cada bloque de 2 Kb
    for i in range(8):
        capa_tmp[i] += chr(0) * (2048 - len(capa_tmp[i]))

    return "".join(capa_tmp)

# Funciones para guardar en disco los datos convertidos
def guarda_archivo(nombre, contenido):
    """
    Guarda un archivo en en disco
    """
    with open(nombre,"wb") as fichero:
        fichero.write(contenido)

# Procesa la línea de comandos    
def procesar_linea_comandos(linea_de_comandos):
    """
    Devuelve una tupla de dos elementos: (opciones, lista_de_ficheros).
    `linea_de_comandos` es una lista de argumentos, o `None` para ``sys.argv[1:]``.
    """
    if linea_de_comandos is None:
        linea_de_comandos = sys.argv[1:]

    version_programa = "%prog v0.5"
    uso_programa = "usage: %prog [options] img1.png img2.png ... imgX.png"
    descripcion_programa = "%prog convert images in png format to binary data for Amstrad CPC."

    # definimos las opciones que soportaremos desde la línea de comandos
    lista_de_opciones = [
        make_option("-m", "--mode", action="store", type="int", dest="mode", default=0, help="Select screen mode (0, 1, 2)"),
        make_option("-s", "--screen", action="store_true", dest="screen", default=False, help="Generate a CPC screen dump")
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
            lista_ficheros = lista_ficheros + glob.glob(i)

    if (opciones.mode < 0) or (opciones.mode > 2):
        parser.error("Screen mode is out of range.")

    return opciones, lista_ficheros

# Función principal
def main(linea_de_comandos=None):
    """
    Función principal
    """
    # obtenemos las opciones y argumentos suministrados al programa
    opciones, lista_ficheros = procesar_linea_comandos(linea_de_comandos)

    # Procesamos los ficheros
    for nombre_imagen in lista_ficheros:
        if not(os.path.exists(nombre_imagen)):
            print("El fichero %s no existe." % nombre_imagen)
            continue
            
        print("Abriendo el fichero de imagen: " + nombre_imagen)
        fichero_imagen = Image.open(nombre_imagen)

        # Obtenemos el nombre del fichero
        nombre_fichero, extension_fichero = os.path.splitext(nombre_imagen)

        # Dimensiones de la imagen
        ancho_imagen, alto_imagen = fichero_imagen.size
        # print u"Tamaño en pixels de la imagen: %d x %d" % (ancho_imagen, alto_imagen)

        # Características de la imagen
        modo_imagen = fichero_imagen.mode
        # print u"Modo de la imagen:", modo_imagen

        fichero_imagen.load()    # Cargamos el fichero en memoria
        capa_rojo, capa_verde, capa_azul = extrae_imagen(fichero_imagen, modo_imagen, ancho_imagen, alto_imagen)

        # Guardamos las capas
        extensiones = iter("rgb")
        for capa in (capa_rojo, capa_verde, capa_azul):
            if (capa != ""):
                capa = convierte_graficos(capa, pixels_por_byte[opciones.mode])
                if opciones.screen:
                    capa = genera_volcado_de_pantalla(capa, alto_imagen, ancho_imagen // pixels_por_byte[opciones.mode])
                guarda_archivo(nombre_fichero + "." + next(extensiones), capa) 

    return 0    # EXIT_SUCCESS

if __name__ == "__main__":
    estado = main()
    sys.exit(estado)
