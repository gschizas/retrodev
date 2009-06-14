; Texto de ayuda
	DEFB "VDRIVE v0.25",LF,CR
	DEFB "------------",LF,CR
;	DEFB "VDRIVE",LF,CR
;	DEFB "VDRIVE.IN",LF,CR
;	DEFB "VDRIVE.OUT",LF,CR
;	DEFB "TAPE",LF,CR
;	DEFB "TAPE.IN",LF,CR
;	DEFB "TAPE.OUT",LF,CR
	DEFB "VRESET --> Reinicia el VDIP y el Atmel AVR",LF,CR
	DEFB "VDIR [fichero] --> Muestra el contenido del directorio",LF,CR
	DEFB "VCD directorio --> Cambia el directorio activo",LF,CR
	DEFB "VRD fichero --> Carga en memoria el fichero",LF,CR
	DEFB "VDLD directorio --> Borra el directorio",LF,CR
	DEFB "VMKD directorio [datetime] --> Crea el directorio",LF,CR
	DEFB "VDLF fichero --> Borra el fichero",LF,CR
	DEFB "VWRF num_bytes dir_mem --> Escribe en el fichero abierto",LF,CR
	DEFB "VOPW fichero [datetime] --> Abre fichero para escritura",LF,CR
	DEFB "VCLF fichero --> Cierra un fichero",LF,CR
	DEFB "VRDF num_bytes dir_mem --> Lee del fichero abierto",LF,CR
	DEFB "VREN fichero1 fichero2 --> Renombra un fichero",LF,CR
	DEFB "VOPR fichero [date] --> Abre fichero para lectura",LF,CR
	DEFB "VSEK num_bytes --> Se posiciona dentro del fichero",LF,CR
	DEFB "VFS a$ --> a$ = Espacio libre en el disco",LF,CR
	DEFB "VFSE a$ --> a$ = Espacio libre en el disco",LF,CR
	DEFB "VIDD --> Muestra el IDD del disco",LF,CR
	DEFB "VIDDE --> Muestra el IDD del disco",LF,CR
	DEFB "VDSN a$ --> a$ = Numero serie del disco",LF,CR
	DEFB "VDVL a$ --> a$ = Etiqueta del disco",LF,CR
	DEFB "VDIRT fichero a$ --> a$ = datetime del fichero",LF,CR
	DEFB "VHELP --> Muestra la ayuda sobre los comandos",LF,CR
	DEFB "VFWV --> Muestra la version del firmware",LF,CR
;	DEFB "RAW.READ @a% --> Lee un byte del vdip",LF,CR
;	DEFB "RAW.WRITE a% --> Escribe un byte en el vdip",LF,CR
;	DEFB "VSNAP --> Carga un snapshot",LF,CR
	DEFB 255

	