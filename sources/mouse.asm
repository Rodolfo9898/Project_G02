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

;check if a button was clicked
    proc possibleButtonClick
        ARG @@yValue:byte,@@xValue:byte,@@button:byte
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

        @@ignore:
            ret 
    endp possibleButtonClick
    
;mouse routine for the menus
    proc buttonInteraction
        uses eax,ebx,ecx,edx,edi
            movzx edi,[currentMenu]
            cmp edi,0
            je short @@main
            cmp edi,2
            je @@static
            cmp edi,3
            je @@static
            cmp edi,4
            je @@difficulty
            cmp edi,5
            je @@choise
            ;;;add interpretation on the main game screen
            ;cmp edi,6
            ;je @@inGame
            cmp edi,7
            je @@paused
            jmp  @@ignore

        @@static:
            call possibleButtonClick,184,183,0
            jmp short @@ignore

        @@paused:
            call possibleButtonClick,119,95,6
            jmp  @@ignore

        @@inGame:
            ;call possibleButtonClick
            jmp @@ignore
        @@difficulty:
            ;;add interpretation for the numbers choises for adapt field
            call possibleButtonClick,184,183,0
            jmp  @@ignore

        @@choise:
            ;;add interpretation for the numbers choises for who starts
            call possibleButtonClick,184,183,4
            jmp  @@ignore

        @@main:
            call possibleButtonClick,79,95,4
            call possibleButtonClick,95,95,2
            call possibleButtonClick,111,95,3
            call possibleButtonClick,127,95,1

        @@ignore:
            ret 
    endp buttonInteraction

DATASEG
    ;mouse handler
        custom_mouse_handler    dd ?

END