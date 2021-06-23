;-----------------------------------------------------
; Modulo per la gestione dello scorrimento verticale
; e orriziontale dei caratteri e dello schermo
;-----------------------------------------------------

;-----------------------------------------------------
; Scroll Macro

    HORIZONTAL_CHAR_LEFT  EQU 0h
    HORIZONTAL_CHAR_RIGHT EQU 1h
    UP_SCREEN_SHIFT       EQU 0h
    DOWN_SCREEN_SHIFT     EQU 1h
    CHAR_UP               EQU 0h 
    CHAR_DOWN             EQU 1h

;-----------------------------------------------------

;-----------------------------------------------------
; Offse Macro

    MAX_OFFSET_FIRTS_LINE  EQU 3BAh
    MIN_OFFSET_FIRTS_LINE  EQU 324h
    MIN_OFFSET_LAST_LINE   EQU 0F04h   

;-----------------------------------------------------

    OFFSET_BUFFER_DIM EQU  0Dh
    MAX_DATA_OUT      EQU  3DCh

saved_data_out SEGMENT PARA PRIVATE 
 
    buffer_offset_firts_line    dw     OFFSET_BUFFER_DIM DUP(?)
    buffer_offset_last_line     dw     OFFSET_BUFFER_DIM DUP(?)
    firts_line_out              dw     MAX_DATA_OUT DUP(0F00h)
    last_line_out               dw     MAX_DATA_OUT DUP(0F00h)
    number_of_line              dw     0h
   
saved_data_out ENDS

shifter_procedure SEGMENT PARA PRIVATE

    ;------------------------------------------------------
    ; Initialize the offsets array
    ;
    ; Parameters: NULL
    ; Value return: NULL

    init_offset_buffer PROC NEAR

     push   ax
     push   bx
     push   cx

     mov    ax, saved_data_out
     mov    ds, ax

     mov    cx, OFFSET_BUFFER_DIM
     mov    bx, OFFSET buffer_offset_firts_line
     mov    ax, OFFSET firts_line_out

     init_firts_offset: mov    WORD PTR [bx], ax
                        add    ax, 98h 
                        add    bx, 2h
                        loop   init_firts_offset

     mov    cx, OFFSET_BUFFER_DIM
     mov    bx, OFFSET buffer_offset_last_line
     mov    ax, OFFSET last_line_out

     init_last_offset: mov    WORD PTR [bx], ax
                       add    ax, 98h 
                       add    bx, 2h
                       loop   init_last_offset
     pop    cx
     pop    bx
     pop    ax
     ret     

    init_offset_buffer ENDP

    ;------------------------------------------------------

    ;------------------------------------------------------
    ; Vertical displacement screen
    ;     Scroll the screen vertically in both directions
    ;
    ; Parameters: The direction of the scroll
    ; Value return: NULL

    vertical_screen_shifter PROC FAR

     push   bp

     mov    bp, sp

     push   ax
     push   bx
     push   dx
     push   si
     push   di
     push   ds

     call   init_offset_buffer

     mov    bx, OFFSET number_of_line
 
     cmp    WORD PTR [bp+6], UP_SCREEN_SHIFT
     je     up_shift 

     cmp    WORD PTR [bx], 1Ah 
     je     _end_sh

     push   ds
     mov    ax, 0B800h 
     mov    ds, ax
     pop    es

     ;store firts line 
     mov    si, MIN_OFFSET_FIRTS_LINE
     mov    di, OFFSET buffer_offset_firts_line
     push   bx
     mov    bx, WORD PTR es:[bx]
     mov    di, WORD PTR es:[di+bx]
     pop    bx
     mov    cx, 4Ch 
     rep    movsw

     push   ds
     pop    es   

     ;down shift
     mov    di, MIN_OFFSET_FIRTS_LINE
     mov    si, MIN_OFFSET_FIRTS_LINE+0A0h

     down_shift: mov    cx, 4Ch 
                 push   di
                 push   si
                
                 rep    movsw

                 pop    si 
                 pop    di

                 add    si, 0A0h
                 add    di, 0A0h

                 cmp    si, MIN_OFFSET_LAST_LINE
                 jbe    down_shift

                 ;animation
                 mov    ax, DOWN_ANIMATION
                 push   ax
                 call   scrollbar_animation
                 add    sp, 2h 

                 mov    ax, saved_data_out
                 mov    ds, ax

                 ;restore the last line (possibile errore)
                 mov    di, MIN_OFFSET_LAST_LINE
                 mov    si, OFFSET buffer_offset_last_line
                 push   bx
                 mov    bx, WORD PTR [bx]
                 mov    si, WORD PTR [si+bx]
                 pop    bx  
                 mov    cx, 4Ch 
                 rep    movsw

                 add    WORD PTR [bx], 2h

                 jmp    _end_sh 

     up_shift: cmp    WORD PTR [bx], 0h
               je     _end_sh

               push  ds
               mov   ax, 0B800h 
               mov   ds, ax
               pop   es

               ;store the last line
               mov   si, MIN_OFFSET_LAST_LINE
               mov   di, OFFSET buffer_offset_last_line
               push  bx
               mov   bx, WORD PTR es:[bx]
               sub   bx, 2h
               mov   di, WORD PTR es:[di+bx]
               pop   bx
               mov   cx, 4Ch 
               rep   movsw
                
               push  ds
               pop   es

               mov   si, MIN_OFFSET_LAST_LINE-0A0h
               mov   di, MIN_OFFSET_LAST_LINE

               up_shift_rep: mov    cx, 4Ch
                             push   si
                             push   di

                             rep    movsw

                             pop    di
                             pop    si

                             sub    si, 0A0h
                             sub    di, 0A0h

                             cmp    si, MIN_OFFSET_FIRTS_LINE
                             jae    up_shift_rep

                             ;animation
                             mov    ax, UP_ANIMATION
                             push   ax
                             call   scrollbar_animation
                             add    sp, 2h

                             mov    ax, saved_data_out
                             mov    ds, ax

                             ;restore firts line
                             mov    di, MIN_OFFSET_FIRTS_LINE
                             mov    si, OFFSET buffer_offset_firts_line
                             push   bx
                             mov    bx, WORD PTR [bx]
                             sub    bx, 2h
                             mov    si, WORD PTR [bx+si]
                             pop    bx
                             mov    cx, 4Ch 
                             rep    movsw

                             sub   WORD PTR [bx], 2h

     _end_sh: pop    ds
              pop    di
              pop    si
              pop    dx
              pop    bx
              pop    ax
              pop    bp
              ret
        
    vertical_screen_shifter ENDP

    ;------------------------------------------------------

    ;------------------------------------------------------
    ; Vertical displacement character
    ;     Scroll character vertically only down
    ;
    ; Parameters:
    ;    The current cursor position
    ;    The current offset
    ;    The firts next line cell offest
    ;
    ; Value return: NULL
    
    vertical_char_shifter PROC FAR

     push    bp

     mov     bp, sp

     push    ax
     push    cx
     push    si
     push    di
     push    ds

     mov     ax, 0B800h 
     mov     ds, ax
     mov     es, ax

     mov     BYTE PTR [bp+11], 0h

     ;char down
     mov     cx, MAX_EDITOR_COLUMN+1h
     sub     cx, WORD PTR [bp+10]

     push    cx
    
     mov     si, MIN_OFFSET_LAST_LINE-0A0h 
     mov     di, MIN_OFFSET_LAST_LINE

     rep_down: mov     cx, 4Ch 
               push    si 
               push    di

               rep     movsw

               pop     di
               pop     si

               sub     di, 0A0h 
               sub     si, 0A0h

               cmp     si, WORD PTR [bp+6]
               jae     rep_down

               ;clear line
               mov     di, WORD PTR [bp+6]
               mov     ax, 0F00h 
               mov     cx, 4Ch 
               rep     stosw

               ;down current line
               mov     si, WORD PTR [bp+8]
               mov     di, WORD PTR [bp+6]
               pop     cx
               push    cx
               rep     movsw

               ;clear current line
               mov     di, WORD PTR [bp+8]
               mov     ax, 0F00h 
               pop     cx
               rep     stosw
               jmp     _end_sh

     _end_sh: pop     ds
              pop     di
              pop     si
              pop     cx
              pop     ax
              pop     bp
              ret 

    vertical_char_shifter ENDP

    ;------------------------------------------------------

    ;------------------------------------------------------
    ; Horizontal displacement character
    ;   scrolls characters horizontally in both directions
    ;
    ; Parameters:
    ;   Offset from which to start scrolling
    ;   The character causing the scroll
    ;   Value of scroll
    ;
    ; Value return: NULL

        horizontal_char_shifter PROC FAR

            push   bp

            mov    bp, sp

            push   ax 
            push   bx 
            push   cx
            push   dx
            push   di
            push   si
            push   ds

            ;Store in DS the Base adress of VRAM
            mov    ax, 0B800h 
            mov    ds, ax

            ;get cursor position (BIOS service)
            mov    ah, 03h 
            xor    bh, bh 
            int    10h

            ;left or right
            cmp    WORD PTR [bp+6], HORIZONTAL_CHAR_RIGHT
            je     _horizontal_shift_char_right
            cmp    BYTE PTR [bp+8], BACKSPACE_KEY
            je     _delete_shift

            inc    dl
            mov    dh, dl
            mov    dl, MAX_EDITOR_COLUMN+1h
            sub    dl, dh
            xor    dh, dh
            mov    cx, dx ;number of times
            ;canc horizontal shift char left
            mov    si, WORD PTR [bp+10]
            add    si, 2h
            mov    di, WORD PTR [bp+10]
            jmp    _left_shift

            ;delete horizontal shift char left
            _delete_shift:  mov    dh, dl
                            mov    dl, MAX_EDITOR_COLUMN+1h
                            sub    dl, dh
                            xor    dh, dh
                            mov    cx, dx ;number of times
                            mov    si, WORD PTR [bp+10]
                            mov    di, WORD PTR [bp+10]
                            sub    di, 2h
            
            _left_shift: rep    movsw
                         sub    si, 2h
                         mov    WORD PTR es:[si], 0F00h
                         jmp    _end_sh

            _horizontal_shift_char_right:
                        mov    dh, dl
                        mov    dl, MAX_EDITOR_COLUMN
                        sub    dl, dh
                        xor    dh, dh
                        mov    cx, dx ;number of times
                        shl    dl, 1h 
                        mov    di, WORD PTR [bp+8]
                        add    di, dx
                        sub    di, 2h
                        mov    si, di
                        sub    si, 2h

                        shift_: mov    ax, WORD PTR es:[si] ;store in ax the cell's value
                                mov    WORD PTR es:[di], ax ;store the cell's value in next cell
                                sub    si, 2h 
                                sub    di, 2h
                                dec    cx
                                jcxz   _end_sh
                                jmp    shift_
            
             _end_sh: pop   ds 
                      pop   si
                      pop   di
                      pop   dx
                      pop   cx
                      pop   bx
                      pop   ax 
                      pop   bp
                      ret

        horizontal_char_shifter ENDP

    ;------------------------------------------------------

shifter_procedure ENDS