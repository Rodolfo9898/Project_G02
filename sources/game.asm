IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"
include "mouse.inc"
include "keys.inc"
include "array.inc"
include "menus.inc"
include "draw.inc"
include "logic.inc"
include "print.inc"

CODESEG
;game interactions
proc gameInteractions
	USES eax,ebx,edx
			movzx ebx,[currentMenu]
			cmp ebx,0
			je @@mainMenu
			ret

		@@mainMenu:
			mov al, [__keyb_keyboardState + 01h] ;escape
			cmp al, 1	; if 1 = key pressed
			je @@exit
			jmp @@noKey

		@@exit:
			mov [currentMenu],1
		
		@@noKey:
		ret 
endp gameInteractions


;actual game engine
	proc game
		USES eax,ebx,ecx,edx
			
		@@mainMenu:
			call menuDisplay,0,5,3,15,10,0
			call displayMouse
		
		@@mainMenuChoise:	
		    call gameInteractions
			movzx ebx, [currentMenu]
			cmp ebx,1
			je @@exit
			jmp @@mainMenuChoise	;if no keystroke is detected remain in this loop
		
		@@exit:
			movzx edx,[colors+2*2]
			call mouse_uninstall
			call __keyb_uninstallKeyboardHandler
			call terminateProcess,edx,72
			ret 
	endp game

;main
	proc main
	    	sti
	    	cld
	    	push ds
	    	pop	es
			call setVideoMode,13h
	    	call fillBackground,[colors];black
 			call mouse_install, offset mouseHandler
			call __keyb_installKeyboardHandler
			call game
	endp main

DATASEG
		;indicate the last valid input in chose difficulty level
		difficultyInput db '8'
		;current menu
		currentMenu db 0
		;exp chosen
		exp db 0
		;setup chosen
		setting db 0
Stack 100h
END main