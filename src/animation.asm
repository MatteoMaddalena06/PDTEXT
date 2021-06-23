;------------------------------------------------------
; 
; Modulo per la gestione delle animazioni della 
; scrollbar
;
;------------------------------------------------------

;------------------------------------------------------
;Characters' Macro

    SCROLLBAR_CHAR_AND_ATTRIBUTE        EQU  07B1h
    SCROLLBAR_CHAR_AND_ATTRIBUTE_NO_SEE EQU  07DBh

;------------------------------------------------------

;------------------------------------------------------
; Direction Macro

    DOWN_ANIMATION EQU 0h 
    UP_ANIMATION   EQU 1h

;------------------------------------------------------

procedure_animation SEGMENT PARA PRIVATE

    scrollbar_animation PROC FAR

     push   bp

     mov    bp, sp

     push   si

     cmp    WORD PTR [bp+6], DOWN_ANIMATION
     je     animation_down_

     mov    si, 0EFEh

     ;up animation
     search_down: 
         cmp   BYTE PTR es:[si], 0B1h
         je     _animation_up
         sub   si, 0A0h
         jmp    search_down

     ;lower the shaft
     _animation_up:
         push   si
         sub    si, 1E0h
         push   si
         cmp    si, 045Eh
         je     _dealloc   
         pop    si
         mov    WORD PTR es:[si], SCROLLBAR_CHAR_AND_ATTRIBUTE 
         pop    si
         mov    WORD PTR es:[si], SCROLLBAR_CHAR_AND_ATTRIBUTE_NO_SEE
         jmp    _end_a

     animation_down_: mov    si, 4FEh

     search_up: 
         cmp   BYTE PTR es:[si], 0B1h
         je     _animation_down
         add    si, 0A0h
         jmp    search_up

     ;lower the shaft
     _animation_down:
         push   si
         add    si, 1E0h
         push   si
         cmp    si, 0EFEh
         je     _dealloc   
         pop    si
         mov    WORD PTR es:[si], SCROLLBAR_CHAR_AND_ATTRIBUTE
         pop    si
         mov    WORD PTR es:[si], SCROLLBAR_CHAR_AND_ATTRIBUTE_NO_SEE
         jmp    _end_a
        
     _dealloc: add    sp, 4h

     _end_a: pop    si
             pop    bp
             ret

    scrollbar_animation ENDP

procedure_animation ENDS