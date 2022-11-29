IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"
include "mouse.inc"
include "array.inc"
include "menus.inc"
include "draw.inc"
include "logic.inc"
include "print.inc"
include "interact.inc"
include "keys.inc"

CODESEG
;actual game engine
	proc game
		USES eax,ebx,ecx,edx

			call displayMouse

		@@mainMenu:
			call menuDisplay,0,5,3,15,10,0
			call drawer,15,15

		@@mainMenuChoise:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
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
			jmp @@staticMenuLoop
	
		@@rules:
			call menuDisplay,1,0,0,17,1,0
		
		@@staticMenuLoop:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
			cmp ebx,0
			je @@mainMenu
			jmp @@staticMenuLoop ;if no keystroke is detected remain in this loop
		
		@@difficulty:
			call menuDisplay,5,2,6,8,6,0		
	
		@@difficltyLoop:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
			cmp ebx,0
			je @@mainMenu
			cmp ebx,5
			je @@adaptField
			jmp @@difficltyLoop;if no keystroke is detected remain in this loop

		@@adaptField:
			movzx eax,[fieldType]
			call adaptField,eax

		@@choisePlayer:
			call menuDisplay,3,5,1,10,10,0
	
		@@choiseLoop:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
			cmp ebx,4
			je @@mainMenu
			cmp ebx,6
			je @@setup
			jmp @@choiseLoop;if no keystroke is detected remain in this loop
		
		@@setup:
			movzx ecx,[playerColor]
			movzx edx,[colors+2*ecx]; the color of the player you want to start
	
		@@screenGame:
			call menuDisplay,6,0,2,14,12,edx
			;used for debbiging to get the correct x and y values for the buttons
			;call drawRectangle,6,127,90,11,14,0 ;undo button posiotn
			;95 van links naar rechts x
			;79 van boven naar onder  y 
			;130 breedte
			;11 hooghte
			;14 gele kleur
			;0 niet filled

		@@game:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
			cmp ebx,7
			je @@paused
			cmp ebx,1
			je @@exit
			cmp ebx,8
			je @@move
			cmp ebx,9
			je @@turnChange
			cmp ebx,10
			je @@undo
			;cmp al,[validateInput]
			;jl @@moveWhere
			;cmp al,'d' ;look if you pressed the 'd' key
			;je short @@undo
			jmp @@game;if no keystroke is detected remain in this loop

		@@paused:
			call menuDisplay,4,10,0,17,15,0
			
		@@pauseLoop:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
			cmp ebx,6
			je @@restore
			jmp @@pauseLoop
		
		@@restore:
			call menuDisplay,6,0,2,14,12,edx
			call restoreField
			jmp @@game

		@@restart:
			mov[statusGrid],0
			call clearGrid
			cmp ebx,0
			je @@mainMenu
			cmp ebx,3
			je @@stats
			jmp @@choisePlayer
	
		@@moveWhere:
			cmp al,'0'
			jge @@move
	    	jmp @@game
			
		@@undo:;statusGrid is where you hold the state if the previous move has been undone or not
			cmp[statusGrid+1],1;1 is to reprensent that you did make an undo
			je @@game
			movzx ebx,[movingSpace]
			call makeMove,ebx,0,1
			mov[statusGrid+1],1
			jmp @@turnChange
		
		@@move:
			mov ecx,[firstTop]
			mov [statusGrid+1],0;0 is to reprensent that you did not make an undo 
			movzx ebx,[movingSpace]
			add ecx,ebx
			cmp [field+ecx],0
			jne @@game
			call makeMove,ebx,edx,0
					
		@@turnChange:
			call gameStatus
			cmp [statusGrid],0
			jne @@gameEnded
			call changeTurn,edx
			cmp dx,[colors+3*2]
			je @@p1
			movzx edx,[colors+3*2]
			jmp @@game
	
		@@p1:
			movzx edx,[colors+4*2]
			jmp @@game
	
		@@noWinner:
			movzx edx,[colors]
			jmp @@anounce

		@@gameEnded:
			cmp [statusGrid],3
			je @@noWinner

		@@anounce:
			call menuDisplay,7,0,3,0,16,edx
			call drawRectangle,6,175,90,11,14,0
	
		@@endGame:
			call keysMenuNavigation
			movzx ebx,[currentMenu]
			cmp ebx,0
			je @@restart
			cmp ebx,3
			je @@restart
			cmp ebx,5
			je @@restart
			cmp ebx,1
			je @@exit
			jmp @@endGame
	
		@@exit:
			movzx edx,[colors+2*2]
			call __keyb_uninstallKeyboardHandler
			call mouse_uninstall
			call terminateProcess,edx,72
			ret 
	endp game

DATASEG
		;indicate the last valid input in chose difficulty level
		difficultyInput db '8'

END