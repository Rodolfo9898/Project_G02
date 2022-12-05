;=============================================================================
; 32-bit Assembler Mouse library.
;
; For use under DMPI 0.9 protected mode.
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Copyright (c) 2015, Tim Bruylants <tim.bruylants@gmail.com>
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;    this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from this
;    software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.
;
;=============================================================================

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "mouse.inc"
include "setup.inc"


;;;;global constants
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Test if mouse is present or not.
;
; ARGUMENTS:
;   none
; RETURNS:
;   EAX     1 if mouse available
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    proc mouse_present
        USES    ebx

        mov     eax, 0
        int     33h

        and     eax, 1

        ret
    endp mouse_present

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Internal mouse handler.
;
; Requires special attention, as this procedure gets called by the mouse
; driver, through the DOS Protected Mode extender.
;
; ARGUMENTS:
;   none
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    proc mouse_internal_handler NOLANGUAGE
        push    ds
        push    es
        push    ax

        mov     ax, [cs:theDS]
        mov     ds, ax
        mov     es, ax

     pop     ax

        call    [custom_mouse_handler]
    
        pop     es
        pop     ds
    
        retf

        ; Internal variable to keep track of DS
        theDS   dw  ?
    endp mouse_internal_handler

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Install mouse handler.
;
; ARGUMENTS:
;   address of the custom mouse handler
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    proc mouse_install
        ARG     @@custom_handler
        USES    eax, ecx, edx, es

            call    mouse_present
            cmp     eax, 1
            jne     @@no_mouse

            mov     eax, [@@custom_handler]
            mov     [custom_mouse_handler], eax

            push    ds
            mov     ax, cs
            mov     ds, ax
            ASSUME  ds:_TEXT
            mov     [theDS], ax
            ASSUME  ds:FLAT
            pop     ds

            mov     eax, 0ch
            mov     ecx, 255
            push    cs
            pop     es
            mov     edx, offset mouse_internal_handler
            int     33h

        @@no_mouse:
            ret
    endp mouse_install

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Uninstall mouse handler.
;
; ARGUMENTS:
;   none
; RETURNS:
;   nothing
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    proc mouse_uninstall
        USES    eax, ecx, edx

        mov     eax, 0ch
        mov     ecx, 0
        mov     edx, 0
        int     33h

        ret
    endp mouse_uninstall

;display the mouse onto the screen
    proc displayMouse
	    USES eax
	    mov ax, 01h
	    int 33h
	    ret
    endp displayMouse

;hide the mouse from the screen
    proc hideMouse
	    USES eax
	    mov ax, 02h
	    int 33h
	    ret
    endp hideMouse

;check if a normal button was clicked
    proc possibleNormalInteraction
        ARG @@yValue:byte,@@xValue:byte,@@button:byte,@@smaller:byte
        USES eax,ebx,ecx,edx,edi
            HEIGHT EQU 11
            WIDE EQU 130
            SWIDE EQU 90
  
            movzx edi,[@@yValue]; waarde van onder naar boven : y
            cmp dx,di
            jl @@ignore
            
            mov eax, HEIGHT; height 
            add ax,di; original value
            cmp dx,ax
            jge @@ignore
            
            sar cx, 1 ; the x coordinate is doubled so we divide by 2
            movzx edi,[@@xValue]; waarde van links naar rechts : x
            cmp cx,di
            jl @@ignore
            
            movzx eax,[@@smaller]
            cmp eax,1
            je @@smallerButton
            mov eax, WIDE; width
            jmp @@compareWide

        @@smallerButton:
            mov eax, SWIDE; smaller width
        
        @@compareWide:
            add ax,di; original value
            cmp cx, ax 
            jge @@ignore
            
            ;;its inside now react accordingly
            test bx,1
            jz @@ignore; we dont use a right click in the menus
            movzx eax,[@@button]
            mov [currentMenu],al

        @@ignore:
            ret 
    endp possibleNormalInteraction

;check if a number button was clicked
    proc possibleNumberInteraction
        ARG @@yValue:byte,@@xValue:byte,@@button:byte,@@menu:byte,@@input:byte
        USES eax,ebx,ecx,edx,edi
            HEIGHT EQU 11
            WIDE EQU 130
  
            movzx edi,[@@yValue]; waarde van onder naar boven : y
            cmp dx,di
            jl @@ignore
            
            mov eax, HEIGHT; height 
            add ax,di; original value
            cmp dx,ax
            jge @@ignore
            
            sar cx, 1 ; the x coordinate is doubled so we divide by 2
            movzx edi,[@@xValue]; waarde van links naar rechts : x
            cmp cx,di
            jl @@ignore
            
            mov eax, WIDE; width
            add ax,di; original value
            cmp cx, ax 
            jge @@ignore
            
            ;;its inside now react accordingly
            test bx,1
            jz @@ignore; we dont use a right click in the menus
            movzx eax,[@@button]
            mov [currentMenu],al
            movzx edi,[@@menu]
            movzx eax,[@@input]
            cmp edi,1
            je @@choise
            mov [fieldType],al
            jmp @@ignore

        @@choise:
            mov [playerColor],al

        @@ignore:
            ret 
    endp possibleNumberInteraction

;check for a movement inside the board
    proc possibleMoveInteraction
        ARG @@yValue:byte,@@xValue:byte,@@input:byte
        USES eax,ebx,ecx,edx,edi
            
            movzx edi,[@@yValue]; waarde van onder naar boven : y
            cmp dx,di
            jl @@ignore

            push edi
            movzx edi,[fieldType]
            movzx eax,[columnSpaces+edi];height
            pop edi
            add ax,di; original value
            cmp dx,ax
            jge @@ignore

            sar cx, 1 ; the x coordinate is doubled so we divide by 2
            movzx edi,[@@xValue]; waarde van links naar rechts : x
            cmp cx,di
            jl @@ignore

            push edi
            movzx edi,[fieldType]
            movzx eax,[gridSpacing+edi]; width
            pop edi
            add ax,di; original value
            dec eax
            cmp cx, ax 
            jge @@ignore

            ;;its inside now react accordingly
            test bx,1
            jz @@ignore; we dont use a right click in the menus
            movzx eax,[@@input]
            mov [movingSpace],al
            mov [currentMenu],8
            mov [moveDone],1
        @@ignore:
            ret

    endp possibleMoveInteraction

;a game interaction
    proc gameInteraction
        Arg @@input:byte
        USES eax,edi

            movzx edi,[@@input]
            ;mov eax,[horizontal+4*edi]
            call possibleMoveInteraction,10,100,edi

        @@ignore:
            ret
    endp gameInteraction

;mouse routine for the menus
    proc buttonInteraction
        uses eax,ebx,ecx,edx,edi
            movzx edi,[currentMenu]
            cmp edi,0
            je @@main
            cmp edi,2
            je @@static
            cmp edi,3
            je @@static
            cmp edi,4
            je @@difficulty
            cmp edi,5
            je @@choise
            cmp edi,6
            je @@inGame
            cmp edi,7
            je @@paused
            cmp edi,8
            je @@move
            cmp edi,9
            je @@announce
            cmp edi,10
            je @@undo
            ;;;add interpreation for the movements
            jmp  @@ignore

        @@static:
            call possibleNormalInteraction,184,183,0,0
            jmp @@ignore

        @@paused:
            call possibleNormalInteraction,119,95,6,0
            jmp  @@ignore

        @@inGame:
            call possibleNormalInteraction,127,6,7,1
            call possibleNormalInteraction,143,6,10,1
            ;;add interpreation for the movements
            ;call possibleMoveInteraction,10,100,0
            call gameInteraction,0
            jmp @@ignore

        @@difficulty:
            call possibleNumberInteraction,47,95,5,0,0
            call possibleNumberInteraction,63,95,5,0,1
            call possibleNumberInteraction,79,95,5,0,2
            call possibleNumberInteraction,95,95,5,0,3
            call possibleNumberInteraction,111,95,5,0,4
            call possibleNumberInteraction,127,95,5,0,5
            call possibleNumberInteraction,143,95,5,0,6
            call possibleNormalInteraction,184,183,0,0
            jmp  @@ignore

        @@choise:
            call possibleNumberInteraction,79,95,6,1,3
            call possibleNumberInteraction,111,95,6,1,4
            call possibleNormalInteraction,184,183,4,0
            jmp  @@ignore

        @@announce:
            call possibleNormalInteraction,127,6,5,1
            call possibleNormalInteraction,143,6,0,1
            call possibleNormalInteraction,159,6,3,1
            call possibleNormalInteraction,175,6,1,1
            jmp  @@ignore

        @@undo:
            mov [currentMenu],6
            jmp @@ignore
        
        @@move:
            cmp [statusGrid],0
            jg @@announce
            cmp [moveDone],1
            je @@moveMade
            jmp @@ignore

        @@moveMade:
            mov [currentMenu],6
            mov [moveDone],0
            jmp @@ignore

        @@main:
            call possibleNormalInteraction,79,95,4,0
            call possibleNormalInteraction,95,95,2,0
            call possibleNormalInteraction,111,95,3,0
            call possibleNormalInteraction,127,95,1,0

        @@ignore:
            ret 
    endp buttonInteraction

DATASEG
    ;mouse handler
        custom_mouse_handler    dd ?
    ;columns in pixles
        columnSpaces db 168,181,187,190,155,155,177 

END