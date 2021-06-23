;----------------------------------------------------------
; Modulo dedicato alle procedure di I/O del text editor.
; 
; Il modulo definisce tre gruppi di macro che rappresentano:
; 	1. La dimensione dello schermo in modalità testo n3 
; 	2. I carattere la cui gestione deve essere dedicata
;       3. I caratteri il cui completamento deve essere automatico.
;
; Le procedure qui definite sono dedicate all'I/O dell'
; editor e alla gestione dei caratteri speciali.
; La funzione principale del modulo è la seguente:
; "read_print_char" il suo compito è quello di attivare
; la subroutine di servizio numero 16h(22), sotto 
; soubroutine 0h(0), del BIOS per l'acquisizione di caratteri
; da tastiera, effetuare controlli su gli scan-code e i 
; caratteri stessi e chiamare determinate funzioni in base
; ai risultati dei confronti
;
; Ogni operazione di output avviene attraverso l'opportuna
; modifica della VRAM sul chip video mentre il cursore è gestito
; tramite i servizi video del BIOS 
;----------------------------------------------------------

;------------------------------------------------------
; Size's Screen Macro

	LENGTH_SCREEN EQU 80
	WIDTH_SCREEN  EQU 25

;------------------------------------------------------

;------------------------------------------------------
; Special ASCII/Scan code Macro

    	ESCAPE_OFFSET 	  EQU  0h    ;(Ascii decimal:0)
	BACKSPACE_KEY 	  EQU  8h    ;(Ascii decimal: 8)
	ENTER_KEY     	  EQU  0Dh   ;(Ascii decimal: 13)
	ESC_KEY	      	  EQU  1Bh   ;(Ascii decimal: 27)
	TAB_KEY		  EQU  9h    ;(Ascii decimal: 9)
	DOWN_KEY	  EQU  50h   ;(Scan code decimal: 80)
	LEFT_KEY      	  EQU  4Bh   ;(Scan code decimal: 75)
	UP_KEY       	  EQU  48h   ;(Scan code decimal: 72)
	RIGHT_KEY     	  EQU  4Dh   ;(Scan code decimal: 77)
	GO_START 	  EQU  49h   ;(Scan code decimal: 73)
	GO_end_I_O        EQU  51h   ;(Scan code decimal: 81)
	GO_START_LINE 	  EQU  47h   ;(Scan code decimal: 71)
	GO_end_I_O_LINE   EQU  4Fh   ;(Scan code decimal: 79)
	CANC_KEY          EQU  53h   ;(Scan code decimal: 83)

;------------------------------------------------------

;------------------------------------------------------
; Auto complete char 

	OPEN_CURLY_BRACKETS   EQU  7Bh  ;(Ascii deciaml: 123)
	OPEN_ROUND_BRACKETS   EQU  28h  ;(Ascii decimal: 40)
	OPEN_SQUARE_BRACKETS  EQU  5Bh  ;(Ascii deciamal: 91)
	OPEN_ANGULAR_BRACKETS EQU  3Ch  ;(Ascii decimal: 60)
	QUOTES		      EQU  27h  ;(Ascii decimal: 39)
	DUOBLE_QUOTES         EQU  22h  ;(Ascii decimal: 34)

;------------------------------------------------------


I_O_procedures SEGMENT PARA PRIVATE

	;-------------------------------------------
	; Write char
	;	Print char (MMIO VRAM)
	;   Set new cursor position
	;
	; Parameters (stack):
	;	Char's ASCII code
	; 	Offset where to write character
	;
	; Value return: NULL

		write_char PROC NEAR

			push	bp

			mov	bp, sp

			push	ax
			push	bx
			push	cx
			push	dx

			cmp     WORD PTR [bp+4], 0F9Eh
			jbe     no_scroll

			mov     ax, DOWN_SCREEN_SHIFT
			push	ax
			call    vertical_screen_shifter
			add     sp, 2h

			;new curosor position (BIOS service)
			mov     ah, 02h 
			xor     bh, bh 
			mov     dl, MIN_EDITOR_COLUMN
			mov     dh, MAX_EDITOR_LINE
			int     10h

			;update offset (VRAM)
		        mov   WORD PTR [bp+4], 0F04h

			no_scroll: ;get cursor position (BIOS service)
				   mov	   ah, 03h 
				   xor	   bh, bh
				   int     10h

			cmp     dl, MAX_EDITOR_COLUMN
			je      next_line

	        ;right horizontal scroll
			push	WORD PTR [bp+4]
			mov	ax, HORIZONTAL_CHAR_RIGHT
			push	ax
			call	horizontal_char_shifter
			add	sp, 4

			;write char
			mov	bx, WORD PTR [bp+4]
			mov	al, BYTE PTR [bp+6]
			mov	ah, 07h
			mov	WORD PTR es:[bx], ax
			
			cmp	BYTE PTR [bp+6], OPEN_SQUARE_BRACKETS
			je      complete_square
			cmp     BYTE PTR [bp+6], OPEN_ROUND_BRACKETS
			je	complete_round
			cmp	BYTE PTR [bp+6], OPEN_CURLY_BRACKETS
			je      complete_curly
			cmp     BYTE PTR [bp+6], OPEN_ANGULAR_BRACKETS
			je      complete_angular
			cmp     BYTE PTR [bp+6], DUOBLE_QUOTES
			je      complete_double_quotes
			cmp     BYTE PTR [bp+6], QUOTES
			je      complete_quotes
			;update offset
			add     WORD PTR [bp+4], 2h
			jmp     _new_curs

			complete_angular: ;right horizontal scroll
					  add    WORD PTR [bp+4], 2h
					  push	 WORD PTR [bp+4]
					  mov	 ax, HORIZONTAL_CHAR_RIGHT
					  push   ax
					  call	 horizontal_char_shifter
					  add	 sp, 4h
					  add 	 bx, 2h 
					  mov	 WORD PTR es:[bx], 073Eh
					  jmp     _new_curs

			complete_square: ;right horizontal scroll
					 add    WORD PTR [bp+4], 2h
					 push	WORD PTR [bp+4]
					 mov	ax, HORIZONTAL_CHAR_RIGHT
					 push	ax
					 call	horizontal_char_shifter
					 add	sp, 4h
					 add	bx, 2h
					 mov	WORD PTR es:[bx], 075Dh
					 jmp    _new_curs

			complete_round: ;right horizontal scroll
					add     WORD PTR [bp+4], 2h
					push	WORD PTR [bp+4]
					mov	ax, HORIZONTAL_CHAR_RIGHT
					push	ax
					call	horizontal_char_shifter
					add	sp, 4h
					add     bx, 2h 
					mov     WORD PTR es:[bx], 0729h
					jmp     _new_curs

			complete_curly: ;right horizontal scroll
					add     WORD PTR [bp+4], 2h
					push	WORD PTR [bp+4]
					mov	ax, HORIZONTAL_CHAR_RIGHT
					push	ax
					call	horizontal_char_shifter
					add	sp, 4h
					add	bx, 2h 
					mov	WORD PTR es:[bx], 077Dh
					jmp     _new_curs

			complete_double_quotes: ;right horizontal scroll
						add     WORD PTR [bp+4], 2h
						push	WORD PTR [bp+4]
						mov	ax, HORIZONTAL_CHAR_RIGHT
						push	ax
						call	horizontal_char_shifter
						add	sp, 4h
						add     bx, 2h 
						mov     WORD PTR es:[bx], 0722h
						jmp     _new_curs
			
			complete_quotes: ;right horizontal scroll
					 add     WORD PTR [bp+4], 2h
					 push	 WORD PTR [bp+4]
					 mov	 ax, HORIZONTAL_CHAR_RIGHT
					 push	 ax
					 call	 horizontal_char_shifter
					 add	 sp, 4h
					 add     bx, 2h 
					 mov     WORD PTR es:[bx], 0727h

			_new_curs: ;new cursor position (BIOS service)
				   mov	   ah, 02h
				   xor     bh, bh 
				   inc     dl
				   int	   10h
				   jmp     _end_I_O

			next_line: mov	   bx, WORD PTR [bp+4]
				   mov	   al, BYTE PTR [bp+6]
				   mov	   BYTE PTR es:[bx], al
				   mov	   BYTE PTR es:[bx+1], 07h
			           mov     ah, 02h
				   xor     bh, bh
				   inc     dh
				   mov	   dl, 2h
			 	   int     10h
				   ;update offset
				   add	   WORD PTR [bp+4], 0Ah

	     	_end_I_O: pop    dx
			  pop    cx
			  pop	 bx
			  pop    ax
			  pop    bp
			  ret

		write_char ENDP

	;-------------------------------------------

	;-------------------------------------------
	; Delete char 
	; 	Write a invisble char
	;   Set new cursor position
	;
	; Parameters:
	;	Offset char 
	;    
	; Value return: New VRAM offset

		delete_char PROC NEAR

			push	bp

			mov	bp, sp

			push	ax
			push	cx
			push	bx
			push	dx

			;get cursor position
			mov	ah, 03h
			xor	bh, bh
			int     10h

			cmp   BYTE PTR [bp+7], CANC_KEY
			je    _canc_char
			cmp   dl, MIN_EDITOR_COLUMN
			je    _end_I_O

			;horizontal shift and delte
			push	WORD PTR [bp+4]
			push	WORD PTR [bp+6]
			mov	ax, HORIZONTAL_CHAR_LEFT
			push	ax
			call    horizontal_char_shifter
			add	sp, 6h

			;new cursor position
			mov    ah, 02h
			xor    bh, bh
			dec    dl
			int    10h

			;decrement Offset VRAM
			sub    WORD PTR [bp+4], 2h
			jmp    _end_I_O

			_canc_char: cmp    dl, MAX_EDITOR_COLUMN
				    je    _end_I_O

				    ;horizontal shift
				    push   WORD PTR [bp+4]
				    push   WORD PTR [bp+6]
				    mov	   ax, HORIZONTAL_CHAR_LEFT
				    push   ax
				    call   horizontal_char_shifter
			            add	   sp, 6h

			_end_I_O: pop    dx
				  pop    bx
				  pop    cx
				  pop	 ax
				  pop	 bp
				  ret

		delete_char ENDP
	
	;-------------------------------------------

	;-------------------------------------------
	; Move curosr characters menagment
	;	Edit the current cursor position
	;	Find the offset of new position
	;
	; Parameters: NULL
	; Value returns: 
	;	bx = new offset

		_move_cursor PROC NEAR

	        push	bp 

		mov	bp, sp
		sub     sp, 4h

		push	ax
		push	cx
		push	dx

		mov     WORD PTR [bp-2], bx

		;get cursor position (BIOS service)
		mov	ah, 03h
		xor	bh, bh
		int	10h

		cmp	BYTE PTR [bp+4], TAB_KEY
		je      tab_char
		cmp     BYTE PTR [bp+4], ENTER_KEY
		je      enter_char
		cmp     BYTE PTR [bp+5], UP_KEY
		je      up_char
	        cmp     BYTE PTR [bp+5], DOWN_KEY
		je      down_char
		cmp     BYTE PTR [bp+5], GO_START
		je      go_start_char
		cmp     BYTE PTR [bp+5], GO_end_I_O
		je      go_end_I_O_char
		cmp     BYTE PTR [bp+5], GO_START_LINE
		je      go_start_line_char
		cmp     BYTE PTR [bp+5], GO_end_I_O_LINE
		je      go_end_I_O_line_char
		cmp     BYTE PTR [bp+5], LEFT_KEY
		je      left_char

	        ;right_char
		cmp     dl, MAX_EDITOR_COLUMN
		je      _ignore
		mov	ah, 02h
		inc     dl
		int 	10h
		jmp     _new_offset

	       ;new position (BIOS service)
	       left_char: cmp     dl, MIN_EDITOR_COLUMN
			  je      _ignore
			  mov	  ah, 02h 
		          dec	  dl
			  int     10h
			  jmp    _new_offset

		enter_char: mov     WORD PTR [bp-4], dx
			    ;new position (BIOS service)
			    mov	    ah, 02h
			    inc     dh																																													
			    mov	    dl, 2h
			    int     10h
			    jmp     _new_offset

		tab_char: ;new position (BIOS service)
			  cmp    dl, 45h
			  ja     _ignore
			  mov    ah, 02h
			  add	 dl, 8h
			  int    10h
			  jmp    _new_offset

		up_char: ;new position (BIOS serivce)
			 mov	ah, 02h
			 dec    dh 
			 int 	10h
			 jmp    _new_offset

		down_char: ;new position (BIOS service)				  
			   mov    ah, 02h 
			   inc	  dh
			   int    10h
			   jmp    _new_offset

		go_start_char: ;new position (BIOS service)
			       mov    ah, 02h
			       mov    dh, MIN_EDITOR_LINE
			       mov    dl, MIN_EDITOR_COLUMN
			       int    10h
			       jmp    _new_offset

		go_end_I_O_char: ;new position (BIOS service)
				 mov	ah, 02h
				 mov	dh, MAX_EDITOR_LINE
				 mov	dl, MAX_EDITOR_COLUMN
				 int	10h
				 jmp    _new_offset

		go_start_line_char: ;new position (BIOS service)
				    mov     ah, 02h 
				    mov	    dl, MIN_EDITOR_COLUMN
				    int     10h
				    jmp     _new_offset

		go_end_I_O_line_char: ;new position (BIOS service)
				      mov	ah, 02h 
				      mov	dl, MAX_EDITOR_COLUMN
				      int 	10h

		;new VRAM offset
		;{[(LENGTH_SCREEN*DH)+(DL+1)]*2}-2
		_new_offset: push    dx
			     mov    al, LENGTH_SCREEN
			     mul    dh
			     xor    dh, dh
			     inc    dl
			     add    ax, dx
			     mov    cx, 2h
			     mul    cx

		;store result in bx
		mov	bx, ax
		sub     bx, 2h

		pop     dx

		cmp     BYTE PTR [bp+5], DOWN_KEY
		je      _scroll_down
		cmp     BYTE PTR [bp+4], ENTER_KEY
		je      _scroll_down_enter

		;scroll up
		cmp     bx, 324h
		jae     _end_I_O

		mov     ax, UP_SCREEN_SHIFT
		push	ax
		call    vertical_screen_shifter
		add     sp, 2h 

		;new cursor position (BIOS service)
		mov	ah, 02h 
		push	bx 
		xor     bh, bh 
		inc     dh 
		int     10h 
		pop     bx 

		;new offset
		add     bx, 0A0h 
		jmp     _end_I_O

		_scroll_down_enter: 
		        cmp     bx, 0F9Eh 
			jnbe    do
		        cmp     bx, MIN_OFFSET_LAST_LINE
		        je      _end_I_O

			push    WORD PTR [bp-4]
			push    WORD PTR [bp+6]
			push	bx
			call    vertical_char_shifter
			add     sp, 6h
			jmp     _end_I_O   

		_scroll_down:
			cmp     bx, 0F9Eh 
		    	jbe    _end_I_O

		do:				   
			mov	ax, DOWN_SCREEN_SHIFT
			push	ax
			call    vertical_screen_shifter
			add     sp, 2h

			push    bx

			mov     ah, 02h 
			xor     bh, bh
			dec     dh 
			int     10h

			pop     bx

		    	;new offset
			sub    bx, 0A0h
			jmp    _end_I_O

		_ignore: mov	bx, WORD PTR [bp-2] 

		_end_I_O: pop     dx
			  pop	  cx
			  pop     ax
			  add     sp, 4h
			  pop     bp
			  ret

		_move_cursor ENDP

	;-------------------------------------------

	;-------------------------------------------
	; Main I_O function
	;	Read a character
	;	Menagement it
	;	Call subroutine to do works
	;
	; Parameters:
	;	Offset where to write the read character
	;
	; Value return:
	;	bx =  New offset 

		read_print_char PROC FAR

			mov	bp, sp

			push	ax

			;input char (BIOS service)
			mov	ah, 00h
			int	16h

			cmp	al, BACKSPACE_KEY
			je 	del_char
			cmp 	al, ENTER_KEY
			je      move_cursor
			cmp	al, ESC_KEY
			je      exit_char
			cmp     al, TAB_KEY
			je      move_cursor
			cmp	ah, DOWN_KEY
			je      move_cursor
			cmp	ah, UP_KEY
			je	move_cursor
			cmp	ah, LEFT_KEY
			je	move_cursor
			cmp	ah, RIGHT_KEY
			je      move_cursor
			cmp     ah, GO_START
			je      move_cursor
			cmp	ah, GO_end_I_O
			je      move_cursor
			cmp     ah, GO_end_I_O_LINE
			je      move_cursor
			cmp     ah, GO_START_LINE
			je      move_cursor
			cmp     ah, CANC_KEY
			je      del_char
			jmp     no_special
			
			del_char: push     ax
			          push	   WORD PTR [bp+4]
				  call     delete_char
				  pop      WORD PTR [bp+4]
				  add      sp, 2h
				  jmp     _end_I_O
			
			move_cursor: push    WORD PTR [bp+4]
			             push    ax
				     call    _move_cursor
				     add     sp, 4h
				     ;store in stack the new offset
				     mov     WORD PTR [bp+4], bx
			             jmp     _end_I_O

			exit_char: ;store in stack the escape offset
				   mov    WORD PTR [bp+4], ESCAPE_OFFSET
				   jmp    _end_I_O

			no_special: push     ax
				    push     WORD PTR [bp+4]
				    call     write_char
				    pop      WORD PTR [bp+4]
				    add      sp, 2h
				    jmp      _end_I_O

			_end_I_O: pop    ax
				  ;store new ofset in bx
				  mov    bx, WORD PTR [bp+4]
				  ret

		read_print_char ENDP

		;-------------------------------------------

I_O_procedures ENDS

