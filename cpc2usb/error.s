; Rutinas de manejo de los errores de vdrive
trata_error
	CP 'B'
	JR Z,_error_bad_command
	CP 'C'
	JR Z,_error_command_failed
	CP 'D'
	JR Z,_error_disk_full
	CP 'R'
	JR Z,_error_read_only
	CP 'F'
	JR Z,_error_con_f
	CP 'N'
	JR Z,_error_con_n
_error_desconocido
_bucle_error_desconocido
	IN A,(C)
	JR NZ,_bucle_error_desconocido
	LD HL,mensaje_error_desconocido
	JP print_error
_error_bad_command
	LD HL,mensaje_error_bad_command
	JR _fin_trata_error_02
_error_command_failed
	LD HL,mensaje_error_command_failed
	JR _fin_trata_error_02
_error_disk_full
	LD HL,mensaje_error_disk_full
	JR _fin_trata_error_02
_error_read_only
	LD HL,mensaje_error_read_only
	JR _fin_trata_error_02
_error_con_f
	CP 'I'
	JR Z,_error_invalid
	CP 'N'
	JR Z,_error_filename_invalid
	CP 'O'
	JR Z,_error_file_open
	JR _error_desconocido
_error_con_n
	CP 'D'
	JR Z,_error_no_disk
	CP 'E'
	JR Z,_error_dir_not_empty
	CP 'U'
	JR Z,_error_no_upgrade
	JR _error_desconocido
_error_invalid
	LD HL,mensaje_error_invalid
	JR _fin_trata_error_01
_error_filename_invalid
	LD HL,mensaje_error_filename_invalid
	JR _fin_trata_error_01
_error_file_open
	LD HL,mensaje_error_file_open
	JR _fin_trata_error_01
_error_no_disk
	LD HL,mensaje_error_no_disk
	JR _fin_trata_error_01
_error_dir_not_empty
	LD HL,mensaje_error_dir_not_empty
	JR _fin_trata_error_01
_error_no_upgrade
	LD HL,mensaje_error_no_upgrade
	JR _fin_trata_error_01
_fin_trata_error_02
	DEFB #ED,#70		; IN F,(C)
_fin_trata_error_01
	DEFB #ED,#70		; IN F,(C)
	JP print_error

error_en_parametros
	LD HL,mensaje_error_en_parametros
	JP print_error

error_no_disk
	LD HL,mensaje_error_no_disk
	JP print_error

print_error
	LD DE,CABECERA_ERROR
	EX DE,HL
	CALL print_texto
	EX DE,HL
	CALL print_texto
	LD A,LF
	CALL TXT_OUTPUT
	LD A,CR
	CALL TXT_OUTPUT
	RET	

trata_error_dir
	LD A,H
	CP 'B'
	JR Z,_error_dir_bad_command
	CP 'C'
	JR Z,_error_dir_command_failed
	CP 'D'
	JR Z,_error_dir_disk_full
	CP 'R'
	JR Z,_error_dir_read_only
	CP 'F'
	JR Z,_error_dir_con_f
	CP 'N'
	JR Z,error_no_disk
_error_dir_desconocido
	LD HL,mensaje_error_desconocido
	JR fin_trata_error_dir
_error_dir_con_f
	LD A,L
	CP 'I'
	JR Z,_error_dir_invalid
	CP 'N'
	JR Z,_error_dir_filename_invalid
	CP 'O'
	JR Z,_error_dir_file_open
	JR _error_dir_desconocido
_error_dir_con_n
	LD A,L
	CP 'D'
	JR Z,_error_dir_no_disk
	CP 'E'
	JR Z,_error_dir_dir_not_empty
	CP 'U'
	JR Z,_error_dir_no_upgrade
	JR _error_dir_desconocido
_error_dir_invalid
	LD HL,mensaje_error_invalid
	JR fin_trata_error_dir
_error_dir_filename_invalid
	LD HL,mensaje_error_filename_invalid
	JR fin_trata_error_dir
_error_dir_file_open
	LD HL,mensaje_error_file_open
	JR fin_trata_error_dir
_error_dir_no_disk
	LD HL,mensaje_error_no_disk
	JR fin_trata_error_dir
_error_dir_dir_not_empty
	LD HL,mensaje_error_dir_not_empty
	JR fin_trata_error_dir
_error_dir_no_upgrade
	LD HL,mensaje_error_no_upgrade
	JR fin_trata_error_dir
_error_dir_bad_command
	LD HL,mensaje_error_bad_command
	JR fin_trata_error_dir
_error_dir_disk_full
	LD HL,mensaje_error_disk_full
	JR fin_trata_error_dir
_error_dir_read_only
	LD HL,mensaje_error_read_only
	JR fin_trata_error_dir
_error_dir_command_failed
	LD HL,mensaje_error_command_failed
fin_trata_error_dir
	JP print_error
	
; Mensajes de error
CABECERA_ERROR
	DEFB "ERROR ",255
mensaje_error_en_parametros
	DEFB "BAD PARAMS",255
mensaje_error_bad_command
   	DEFB "BAD COMMAND",255
mensaje_error_command_failed
  	DEFB "COMMAND FAILED",255
mensaje_error_disk_full
	DEFB "DISK FULL",255
mensaje_error_invalid
   	DEFB "INVALID",255
mensaje_error_filename_invalid
	DEFB "FILENAME INVALID",255
mensaje_error_file_open
	DEFB "FILE OPEN",255
mensaje_error_no_disk
	DEFB "NO DISK",255
mensaje_error_dir_not_empty
   	DEFB "DIR NOT EMPTY",255
mensaje_error_no_upgrade
   	DEFB "NO UPGRADE",255
mensaje_error_read_only
    DEFB "READ ONLY",255
mensaje_error_desconocido      
	DEFB "UNKNOWN",255   
