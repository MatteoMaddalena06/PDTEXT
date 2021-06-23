;non finito

;--------------------------------------------------------
; Modulo principale.
;
; Effettua le chiamte alle funzioni principali che a loro 
; volta chiameranno le secondarie.
;
; Il compito principale del modulo è l'inizilizazione del
; registro BX con l'offset della prima cella su cui 
; effettuare modifiche, e l'uscita in caso di pressione 
; carattere 27(ESC) dall'editor.
;--------------------------------------------------------

INCLUDE I_O.asm
INCLUDE EDITOR.asm
INCLUDE shifter.asm
INCLUDE ANIM~XPI.asm

stack SEGMENT PARA STACK

	db	?

stack ENDS

code SEGMENT PARA PUBLIC

_start:  
        mov     ax, 0B800h
	mov	es, ax

	call    init_editor

	;initial VRAM offset to editing (column 2, line 5)
	mov	bx, MIN_OFFSET_FIRTS_LINE

	edit_run: push    bx
	          call    read_print_char
		  add	  sp, 2h

		  cmp      bx, ESCAPE_OFFSET
	          jne      edit_run
	
	call    exit_work
	
	;return control at MS-DOS
        mov	 ah, 4ch
	mov	 al, 1
	int	 21h

code ENDS
	END _start
