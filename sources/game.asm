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
			cmp ebx,2
			je @@rules
			cmp ebx,3
			je @@stats
			cmp ebx,4
			je @@difficulty
			cmp ebx,5
			je @@choise
			jmp @@noKey

		@@mainMenu:
			mov al, [__keyb_keyboardState + 01h] ;escape
			cmp al, 1	; if 1 = key pressed
			je @@exit
			mov al, [__keyb_keyboardState + 1fh] ;letter s
			cmp al, 1	; if 1 = key pressed
			je @@stats
			mov al, [__keyb_keyboardState + 13h] ;letter r
			cmp al, 1	; if 1 = key pressed
			je @@rules
			mov al, [__keyb_keyboardState + 39h] ;spacebar
			cmp al, 1	; if 1 = key pressed
			je @@difficulty
			jmp @@noKey

		@@stats:
			mov [currentMenu],3
			jmp @@staticMenu

		@@rules:
			mov [currentMenu],2

		@@staticMenu:
			mov al, [__keyb_keyboardState + 30h] ;letter b
			cmp al, 1	; if 1 = key pressed
			je @@goToMain
			jmp @@noKey
		
		@@goToMain:
			cmp ebx,5 ;coming back from player choise to change the board size
			je @@difficulty
			mov [currentMenu],0
			jmp @@noKey

		@@difficulty:
			mov [currentMenu],4

		@@difficultyMenu:
		;TODO NUMBER INTERPRETATION
			jmp @@staticMenu

		@@choise:
		;TODO NUMBER INTERPRETATION
			jmp @@staticMenu
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
			cmp ebx,2
			je @@rules
			cmp ebx,3
			je @@stats
			cmp ebx,4
			je @@difficulty
			jmp @@mainMenuChoise	;if no keystroke is detected remain in this loop
		
		@@stats:
			call menuDisplay,2,5,2,15,10,0
			jmp @@staticLoop

		@@rules:
			call menuDisplay,1,0,0,17,1,0
		
		@@staticLoop:
			call gameInteractions
			movzx ebx, [currentMenu]
			cmp ebx,0
			je @@mainMenu
			jmp @@staticLoop
		
		@@difficulty:
			call menuDisplay,5,2,6,8,6,0
		
		@@difficultyLoop:
			call gameInteractions
			movzx ebx, [currentMenu]
			cmp ebx,0
			je @@mainMenu
			cmp ebx,5
			je @@choise
			jmp @@difficultyLoop
		
		@@choise:
			call menuDisplay,3,5,1,10,10,0

		@@choiseLoop:	
			call gameInteractions
			movzx ebx, [currentMenu]
			cmp ebx,4
			je @@difficulty
			jmp @@choiseLoop

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