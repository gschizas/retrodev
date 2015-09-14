#! /usr/bin/env python
# -*- coding: utf-8 -*-

# video2cpc
# (c) MML, 2009

# Notas e Ideas:
# Mejorar la cuantización (24 bits to cpc).
# Implementar doble buffer (Pares e impares).

# Busca los *** MODIFICAME ***

# Parches para que funcione en python 2.5


import sys
import os		# path.exists(), listdir()
import glob		# glob() expande los patrones de los ficheros
from math import sqrt, pow		# sqrt()
import Image
from optparse import make_option, OptionParser
import hashlib	# para calcular el sha1 de los patrones

# Marcadores de compresión
CMP_COPY = 0x00
CMP_SKIP = 0x50
CMP_REPEAT = 0xA0
CMP_END_SCANLINE = 0xFD
CMP_END_SCREEN = 0xFE
CMP_END_VIDEO = 0xFF

# Número máximo de colores del CPC según la resolución
colores_por_modo = (16, 4, 2)

# Ancho en pixels de un byte según la resolución del CPC
pixels_por_byte = (2, 4, 8)

# Paleta del CPC
# Cadena RGB : Tinta + Color Hardware (lista para el Gate Array)
paleta_cpc = {
	'\x00\x00\x00' : 64 + 20, 		# Negro
	'\x00\x00\x7F' : 64 + 4, 		# Azul
	'\x00\x00\xFF' : 64 + 21, 		# Azul Brillante
	'\x7F\x00\x00' : 64 + 28, 		# Rojo
	'\x7F\x00\x7F' : 64 + 24, 		# Magenta
	'\x7F\x00\xFF' : 64 + 29, 		# Malva
	'\xFF\x00\x00' : 64 + 12, 		# Rojo Brillante
	'\xFF\x00\x7F' : 64 + 5, 		# Purpura
	'\xFF\x00\xFF' : 64 + 13, 		# Magenta Brillante
	'\x00\x7F\x00' : 64 + 22, 		# Verde
	'\x00\x7F\x7F' : 64 + 6, 		# Cian
	'\x00\x7F\xFF' : 64 + 23, 		# Azul Cielo
	'\x7F\x7F\x00' : 64 + 30, 		# Amarillo
	'\x7F\x7F\x7F' : 64 + 0, 		# Blanco
	'\x7F\x7F\xFF' : 64 + 31, 		# Azul Pastel
	'\xFF\x7F\x00' : 64 + 14, 		# Naranja
	'\xFF\x7F\x7F' : 64 + 7, 		# Rosa
	'\xFF\x7F\xFF' : 64 + 15, 		# Magenta Pastel
	'\x00\xFF\x00' : 64 + 18, 		# Verde Brillante
	'\x00\xFF\x7F' : 64 + 2, 		# Verde Mar
	'\x00\xFF\xFF' : 64 + 19, 		# Cian Brillante
	'\x7F\xFF\x00' : 64 + 26, 		# Lima
	'\x7F\xFF\x7F' : 64 + 25, 		# Verde Pastel
	'\x7F\xFF\xFF' : 64 + 27, 		# Cian Pastel
	'\xFF\xFF\x00' : 64 + 10, 		# Amarillo Brillante
	'\xFF\xFF\x7F' : 64 + 3, 		# Amarillo Pastel
	'\xFF\xFF\xFF' : 64 + 11 		# Blanco Brillante
}

# Funciones de conversión de las imagenes
def extrae_paleta(imagen):
	"""
	Extrae la paleta de la imagen
	"""
	paleta_final = {}
	contador = 0
	for i in range(len(imagen)):
		if not(imagen[i] in paleta_final):
			paleta_final[imagen[i]] = (contador, paleta_cpc[imagen[i]])
			contador += 1
	if (len(paleta_final) > 16):	# *** MODIFICAME ***
		# print len(paleta_final)
		pass
	return paleta_final

def aproxima_color(rojo, verde, azul):
	"""
	Devuelve el color más cercano
	"""
	color_aproximado = 	'\x00\x00\x00'
	minimo = 255 * 3
	for i in list(paleta_cpc.keys()):
		# Algoritmos de cuantización del color:
		
		# Distancia Euclidiana
		var_tmp = sqrt(pow(rojo - ord(i[0]), 2) + pow(azul - ord(i[1]), 2) + pow(verde - ord(i[2]), 2))
		
		# Algoritmo cutre
		#var_tmp = abs(rojo - ord(i[0]) + azul - ord(i[1]) + verde - ord(i[2]))
		
		# Realizar un histograma y escoger los colores más utilizados
		 
		if (var_tmp < minimo):
			minimo = var_tmp
			color_aproximado = i 
	return color_aproximado

def extrae_imagen(fichero_imagen, modo_imagen, ancho_imagen, alto_imagen): #, paleta):
	"""
	Extrae la imagen cruda de la imagen
	"""
	imagen_final = list(fichero_imagen.getdata())
	if (modo_imagen=="RGB") or (modo_imagen=="RGBA"):
		for i in range(alto_imagen * ancho_imagen):
			imagen_final[i] = aproxima_color(imagen_final[i][0], imagen_final[i][1], imagen_final[i][2])
	elif (modo_imagen == "P"):
		pass	# Controlar el modo de paleta
	else:
		imagen_final = []
		print("Modo no soportado.")
	return imagen_final

def convierte_paleta(paleta):
	"""
	Optimiza la paleta
	"""
	paleta_final = []
	for i in range(len(paleta)):
		paleta_final.append("")
	for i in list(paleta.keys()):
		paleta_final[paleta[i][0]] = chr(paleta[i][1])
	return paleta_final

def convierte_pixels(cadena, ppb):
	"""
	Convierte una cadena de bytes a un modo del CPC
	"""
	cadena_final = ""
	for i in range(len(cadena) // ppb):
		if ppb == 2:
			byte_tmp0 = cadena[i * ppb]
			byte_tmp1 = cadena[i * ppb + 1]
			byte_tmp = chr(((ord(byte_tmp1) & 0x08) >> 3) | ((ord(byte_tmp1) & 0x04) << 2) | \
						((ord(byte_tmp1) & 0x02) << 1) | ((ord(byte_tmp1) & 0x01) << 6) | \
						((ord(byte_tmp0) & 0x08) >> 2) | ((ord(byte_tmp0) & 0x04) << 3) | \
						((ord(byte_tmp0) & 0x02) << 2) | ((ord(byte_tmp0) & 0x01) << 7))
		elif ppb == 4:
			byte_tmp0 = cadena[i * ppb]
			byte_tmp1 = cadena[i * ppb + 1]
			byte_tmp2 = cadena[i * ppb + 2]
			byte_tmp3 = cadena[i * ppb + 3]
			byte_tmp = chr(((ord(byte_tmp3) & 0x02) >> 1) | ((ord(byte_tmp3) & 0x01) << 4) | \
						((ord(byte_tmp2) & 0x02)) | ((ord(byte_tmp2) & 0x01) << 5) | \
						((ord(byte_tmp1) & 0x02) << 1) | ((ord(byte_tmp1) & 0x01) << 6) | \
						((ord(byte_tmp0) & 0x02) << 2) | ((ord(byte_tmp0) & 0x01) << 7))
		elif ppb == 8:
			byte_tmp0 = cadena[i * ppb]
			byte_tmp1 = cadena[i * ppb + 1]
			byte_tmp2 = cadena[i * ppb + 2]
			byte_tmp3 = cadena[i * ppb + 3]
			byte_tmp4 = cadena[i * ppb + 4]
			byte_tmp5 = cadena[i * ppb + 5]
			byte_tmp6 = cadena[i * ppb + 6]
			byte_tmp7 = cadena[i * ppb + 7]
			byte_tmp = chr(((ord(byte_tmp7) & 0x01)) | ((ord(byte_tmp6) & 0x01) << 1) | \
						((ord(byte_tmp5) & 0x01) << 2) | ((ord(byte_tmp4) & 0x01) << 3) | \
						((ord(byte_tmp3) & 0x01) << 4) | ((ord(byte_tmp2) & 0x01) << 5) | \
						((ord(byte_tmp1) & 0x01) << 6) | ((ord(byte_tmp0) & 0x01) << 7))
		cadena_final += byte_tmp
	return cadena_final

def convierte_imagen(imagen, paleta):
	"""
	Convierte la imagen a formato cpc
	"""
	for i in range(len(imagen)):
		imagen[i] = chr(paleta[imagen[i]][0])
	return imagen

def convierte_frame(fichero_imagen, modo_imagen, ancho_imagen, alto_imagen, ppb):
	"""
	Convierte los frames del video
	"""
	imagen = extrae_imagen(fichero_imagen, modo_imagen, ancho_imagen, alto_imagen)
	paleta = extrae_paleta(imagen)
	imagen = convierte_imagen(imagen, paleta)
	paleta = convierte_paleta(paleta)
	imagen = convierte_pixels("".join(imagen), ppb)
	return "".join(paleta), imagen

def diff_paleta(paleta_vieja, paleta_nueva):
	"""
	Diferencias entre los frames de las paletas
	"""
	paleta_final = ""
	for i in range(len(paleta_nueva)):
		if (i < len(paleta_vieja)):
			if (paleta_nueva[i] != paleta_vieja[i]):
				paleta_final += chr(i) + paleta_nueva[i]
		else:
			paleta_final += chr(i) + paleta_nueva[i]
	#print "Diff Paleta: %d" % (len(paleta_final) + 1)
	return chr(len(paleta_final) // 2) + paleta_final
	
def comprime_scanline(scanline_vieja, scanline_nueva, dir_scanline):
	"""
	Comprime un scanline
	"""
	scanline_final = chr(dir_scanline % 256) + chr(dir_scanline // 256)
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
					cadena_a_copiar += byte_anterior	# Hay que añadir el byte anterior
					#print "COPY pendiente: %d" % (len(cadena_a_copiar)),
					scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
					cadena_a_copiar = ""
				elif (contador_repeticiones):	# ¿Hay un REPEAT pendiente?
					#print "REPEAT pendiente: %d" % contador_repeticiones,
					scanline_final += chr(CMP_REPEAT + contador_repeticiones) + byte_anterior
					contador_repeticiones = 0
				elif (i != 0) and (byte_anterior != scanline_vieja[i - 1]):
					cadena_a_copiar += byte_anterior	# Hay que añadir el byte anterior
					#print "COPY pendiente: %d" % (len(cadena_a_copiar)),
					scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
					cadena_a_copiar = ""
		else:	# byte_actual <> scanline_vieja[i]
			if (contador_skip):
				#print "SKIP: %d" % (contador_skip - 1),
				scanline_final += chr(CMP_SKIP + contador_skip - 1)
				contador_skip = 0
				if (i == (len(scanline_nueva) - 1)):	# Hay que añadir el byte anterior
					cadena_a_copiar += byte_actual
			else:
				if (byte_actual != byte_anterior):
					if (contador_repeticiones):
						#print "REPEAT: %d" % contador_repeticiones,
						scanline_final += chr(CMP_REPEAT + contador_repeticiones) + byte_anterior
						contador_repeticiones = 0
					else:
						cadena_a_copiar += byte_anterior
					if (i == (len(scanline_nueva) - 1)):	# Hay que añadir el byte anterior
						cadena_a_copiar += byte_actual
				else:	# byte_actual == byte_anterior
					contador_repeticiones += 1
					if ((contador_repeticiones == 1) and len(cadena_a_copiar)):
						#print "COPY: %d" % (len(cadena_a_copiar)),
						scanline_final += chr(CMP_COPY + len(cadena_a_copiar) - 1) + cadena_a_copiar
						cadena_a_copiar = ""
		byte_anterior = byte_actual
	else:	# else del for
		# ¿Hay un SKIP pendiente?
		if (contador_skip):
			#print "SKIP final: %d" % (contador_skip - 1),
			scanline_final += chr(CMP_SKIP + contador_skip - 1)
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
	descomprime_scanline(scanline_nueva, scanline_final[2:])

	scanline_final +=  chr(CMP_END_SCANLINE)		
	
	return scanline_final

def optimiza_video(lista_frames, pack_mode, scanlines, lista_scanlines):
	"""
	Optimiza el video
	"""
	ancho_bytes_scanline = lista_scanlines[0][1] - lista_scanlines[0][0] + 1
	alto_pantalla = len(lista_scanlines)
	alto_scanlines = (2 if scanlines else 1)
	paleta_vieja = ""
	imagen_vieja = chr(0) * len(lista_frames[0][1])	# Pantalla inicializada a 0 (imagen_vieja = "")
	for i in range(len(lista_frames)):
		paleta_nueva = lista_frames[i][0]
		imagen_nueva = lista_frames[i][1]
		contador = 0
		imagen_tmp = ""
		for j in range(0, alto_pantalla, alto_scanlines):
			scanline_vieja = imagen_vieja[contador : contador + ancho_bytes_scanline]
			scanline_nueva = imagen_nueva[contador : contador + ancho_bytes_scanline]
			imagen_tmp += comprime_scanline(scanline_vieja, scanline_nueva, lista_scanlines[j][0])
			contador += ancho_bytes_scanline
		print("Imagen: %d" % len(imagen_tmp))
		lista_frames[i] = diff_paleta(paleta_vieja, paleta_nueva) + imagen_tmp + chr(CMP_END_SCREEN)
		paleta_vieja = paleta_nueva
		imagen_vieja = imagen_nueva
	return lista_frames
	
def descomprime_scanline(scanline_original, scanline_comprimido):
	print("D: %d C: %d" % (len(scanline_original), len(scanline_comprimido)))
	for i in scanline_original:
		print("%x" % ord(i), end=' ')
	print("")
	for i in scanline_comprimido:
		print("%x" % ord(i), end=' ')
	print("")
	scanline_tmp = ""
	estado = CMP_END_VIDEO
	cnt_scanlines = 0
	cnt = 0
	contador_global = 0
	cuenta = 0
	for ni in range(len(scanline_comprimido)):
		cuenta += 1
		i = ord(scanline_comprimido[ni])
		if (estado == CMP_END_VIDEO):
			if (CMP_COPY <= i < CMP_SKIP):
				estado = CMP_COPY
				cnt = i - CMP_COPY + 1
				print("COPY: %d" % cnt, end=' ')
			elif (CMP_SKIP <= i < CMP_REPEAT):
				cnt = 0
				scanline_tmp += scanline_original[contador_global : contador_global + i - CMP_SKIP + 1]
				contador_global += i - CMP_SKIP + 1
				print("SKIP: %d" % (i - CMP_SKIP + 1), end=' ')
				#print "CG: %d" % contador_global,
			elif (CMP_REPEAT <= i < CMP_REPEAT + len(scanline_original)):
				estado = CMP_REPEAT
				cnt = i - CMP_REPEAT + 1
				print("REPEAT: %d" % cnt, end=' ')
			elif (i == CMP_END_SCANLINE):
				estado = CMP_END_VIDEO
		elif (estado == CMP_COPY):
			scanline_tmp += chr(i)
			cnt -= 1
			contador_global += 1
			#print "CG: %d" % contador_global,
		elif (estado == CMP_REPEAT):
			for j in range(cnt):
				scanline_tmp += chr(i)
			contador_global += cnt
			#print "CG: %d" % contador_global,
			cnt = 0
			
		if not(cnt):
			estado = CMP_END_VIDEO
	print("Contador global %d" % contador_global)
	#print ""
	for i in scanline_tmp:
		print("%x" % ord(i), end=' ')
	print("")
	if (scanline_original == scanline_tmp):
		print("CORRECTA")
	else:
		print("ERROR")
	print("")

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

	version_programa = "%prog v0.2"
	uso_programa = "usage: %prog [options] img1.png img2.png ... imgX.png"
	descripcion_programa = "%prog convert images in png format to video data for Amstrad CPC."

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
			lista_ficheros = lista_ficheros + glob.glob(i)
	if (opciones.mode < 0) or (opciones.mode > 2):
		parser.error("Screen mode is out of range.")

	return opciones, lista_ficheros

# Función principal
def main(linea_de_comandos=None):
	# obtenemos las opciones y argumentos suministrados al programa
	opciones, lista_ficheros = procesar_linea_comandos(linea_de_comandos)

	# opciones.mode contiene el modo de resolución del cpc

	# Obtenemos el número de imagenes de las que consta el video
	numero_frames = len(lista_ficheros)
	print("El video consta de %d imagenes." % numero_frames)

	# Obtenemos el ancho y el alto del video
	fichero_frame = Image.open(lista_ficheros[0])
	ancho_frame, alto_frame = fichero_frame.size
	print("Las imagenes del video son de %d x %d pixels." % (ancho_frame, alto_frame))

	# Inicializamos las constantes de los marcadores del compresor
	ancho_en_bytes_frame = ancho_frame // pixels_por_byte[opciones.mode]

	# Si vamos a modificar variables globales, hay que indicarselo a python antes,
	# en caso contrario creará variables locales.	
	global CMP_COPY, CMP_SKIP, CMP_REPEAT 
	if ((ancho_en_bytes_frame * 3) < 256):
		CMP_COPY = 0x00
		CMP_SKIP = ancho_en_bytes_frame
		CMP_REPEAT = ancho_en_bytes_frame * 2
	else:
		print("ERROR: Las imagenes son muy anchas y necesitas activar el modo de 16 bits para el compresor (TODO).")
		return 1	# Salimos del programa con un error
	# Generamos los comienzos y finales de los scanlines
	lista_scanlines = []
	comienzo = 0xC000
	final = 0xC000 + ancho_en_bytes_frame - 1
	lista_scanlines.append((comienzo, final))
	for i in range(1, (alto_frame * 2 if opciones.scanlines else alto_frame)):
		comienzo += 0x0800
		comienzo += (0x0000 if (i % 8) else (0xC000 + ancho_en_bytes_frame))
		comienzo = comienzo & 0xFFFF
		final = comienzo + ancho_en_bytes_frame - 1
		lista_scanlines.append((comienzo, final))
	lista_frames = []
	
	for nombre_imagen in lista_ficheros:
		# Comprobamos la existencia de los ficheros
		if not(os.path.exists(nombre_imagen)):
			print("ERROR: El fichero %s no existe." % nombre_imagen)
			return 1	# Salimos del programa con un error
			
		print("Abriendo el fichero de imagen: " + nombre_imagen)
		fichero_imagen = Image.open(nombre_imagen)
		
		# Comprobamos las dimensiones de los frames
		ancho_imagen, alto_imagen = fichero_imagen.size
		if not((ancho_imagen == ancho_frame) and (alto_imagen == alto_frame)):
			print("ERROR: El fichero %s no posee las dimensiones del resto de imagenes del video." % nombre_imagen)
			return 1	# Salimos del programa con un error

		# Características de la imagen
		modo_imagen = fichero_imagen.mode

		# Cargamos el fichero en memoria
		fichero_imagen.load()

		# Vamos añadiendo las parejas (paleta, imagen) a la lista
		lista_frames.append(convierte_frame(fichero_imagen, modo_imagen, ancho_imagen, alto_imagen, pixels_por_byte[opciones.mode]))
	
	# Optimizamos el video
	lista_frames_optimizados = optimiza_video(lista_frames, opciones.pack_mode, opciones.scanlines, lista_scanlines)
	
	# Y lo guardamos en disco
	guarda_archivo(opciones.fichero_salida, "".join(lista_frames_optimizados) + chr(CMP_END_VIDEO))

	return 0	# EXIT_SUCCESS

if __name__ == "__main__":
	estado = main()
	sys.exit(estado)
