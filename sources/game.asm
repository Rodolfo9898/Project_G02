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
;numbers interactions
proc numberInputs
	ARG @@currentMenu:byte
	USES eax,ebx,ecx
			mov al, [__keyb_keyboardState + 02h] ;number 1
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 03h] ;number 2
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 04h] ;number 3
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 05h] ;number 4
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 06h] ;number 5
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 07h] ;number 6
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 08h] ;number 7
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 09h] ;number 8
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			mov al, [__keyb_keyboardState + 0ah] ;number 9
			cmp al, 1	; if 1 = key pressed
			mov al, [__keyb_keyboardState + 0bh] ;number 0
			cmp al, 1	; if 1 = key pressed
			je @@numberInput
			jmp @@noKey

		@@numberInput:
			mov al,[__keyb_rawScanCode]
			movzx ebx,[@@currentMenu]
			cmp ebx,4
			je @@difficulty
			cmp ebx,5
			je @@setup
			jmp @@noKey
		
		@@difficulty:
			cmp al, 08h ;number 8 on toprow and not on numberpad
			jg @@noKey
			dec eax
			mov [exp],al
			inc eax
			mov [currentMenu],5
			jmp @@noKey
		
		@@setup:
			cmp al, 03h ;number 2 on toprow and not on numberpad
			jg @@noKey
			inc eax ;scancode and choise in array are off by one so add one to compensate
			mov [setting],al
			mov [currentMenu],6

		@@noKey:
			ret 
endp numberInputs 


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
			cmp ebx,6
			je @@gameplay
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
			call numberInputs,ebx
			jmp @@staticMenu

		@@choise:
			mov [currentMenu],5

		@@choiseMenu:
			call numberInputs,ebx
			jmp @@staticMenu
		
		@@gameplay:
			mov [currentMenu],6

		@@gameplayscreen:
			mov al, [__keyb_keyboardState + 27h] ;letter m
			cmp al, 1	; if 1 = key pressed
			je @@goToMain
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
			;movzx edx,[exp]
			;dec edx
			;add edx,'0'
			;call moveCursor,18,18
			;call printChar,1,edx

		@@choiseLoop:	
			call gameInteractions
			movzx ebx, [currentMenu]
			cmp ebx,1
			je @@exit
			cmp ebx,4
			je @@difficulty
			cmp ebx,6
			je @@screenGame
			jmp @@choiseLoop
		
		@@screenGame:
			movzx edx,[setting]
			movzx ecx,[colors+edx*2];color of player you chose to start
			call menuDisplay,6,0,2,14,12,ecx
			add edx,'0'
			call moveCursor,18,18
			call printChar,1,edx

		@@gameplayLoop:
			call gameInteractions
			movzx ebx, [currentMenu]
			cmp ebx,0
			je @@mainMenu
			jmp @@gameplayLoop

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