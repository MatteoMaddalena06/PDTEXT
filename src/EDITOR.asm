;--------------------------------------------------------
; Modulo per l'inizializzazione dell'editor
; 
; Definisce funzioni per l'inizializzazione dell'editor,
; passa nella modalità testo 3, visualizza il menù, e la
; schermata di uscita
;--------------------------------------------------------

;-------------------------------------------
; extern header for grapichs
  
	INCLUDE INIT_EDI.INC
  	INCLUDE EXIT_IM.INC

;-------------------------------------------

;-------------------------------------------

	MIN_EDITOR_COLUMN EQU 2h
	MIN_EDITOR_LINE   EQU 5h 
	MAX_EDITOR_COLUMN EQU 4Dh 
	MAX_EDITOR_LINE   EQU 18h

;-------------------------------------------

procedure SEGMENT PARA PUBLIC

    ;-------------------------------------------
	; Init the editor:
	;   Set the video mode (with BIOS Service)
	;   Print the menu (using MMIO VRAM)
	;   Set cursor position (with BIOS service)
	;
	; Parameters: NULL
	; Value return: NULL
		
		init_editor PROC FAR
			
			push	bp

			mov     bp, sp

			push	ax
			push	bx
			push	cx
			push	dx
			push	ds

			;vide mode 03h (BIOS service)
			mov		ah, 0h
			mov		al, 03h
			int		10h

			;set cursor position (BIOS service)
			mov		ah, 02h
			xor     bh, bh
			mov		dh, MIN_EDITOR_LINE
			mov		dl, MIN_EDITOR_COLUMN
			int 	10h

			;print window (VRAM)
			mov		ax, menu_img
			mov		ds, ax
			mov		cx, 0FFFh
			mov		si, OFFSET data_IMG
			xor		di, di
			rep    	movsw

			;print file name
			pop     ds
			mov     si, 81h
			mov     di, 188h
			mov     cx, 9h

			write: mov     al, BYTE PTR [si]
			       cmp     al, 0Dh 
				   je      _end_e
				   mov     ah, 0Fh 
				   mov     WORD PTR es:[di], ax
				   inc     si
				   add     di, 2h
				   loop    write

			_end_e: pop     bp
					pop 	dx
					pop		cx
					pop		bx
					pop		ax
					ret

		init_editor ENDP

    ;-------------------------------------------

    ;-------------------------------------------
	; Exit to text editor:
	;	Print exit message
	;   Set new cursor position
	;
	; Prameters: NULL
	; Value return: NULL

		exit_work PROC FAR

			push	ax
			push   	bx
			push	ds
			push	di

			;print exit text
			mov		cx, 0FFFh
			mov		ax, exit_msg
			mov		ds, ax
			xor		di, di
			mov		si, OFFSET exit_IMG
			rep     movsw

			;set cursor position (BIOS service)
			mov		ah, 02h
			xor     bh, bh
			mov		dh, 18h
			mov		dl, 4Fh
			int		10h

			pop		di
			pop 	ds
			pop		bx
			pop		ax
			ret

		exit_work ENDP

	;-------------------------------------------

procedure ENDS
