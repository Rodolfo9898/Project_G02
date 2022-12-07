IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"
include "mouse.inc"
include "array.inc"
include "print.inc"
include "draw.inc"

CODESEG
;according to the menu you want you will load the corresponsding header
	proc menuDistribution
		ARG @@menu:word,@@color:word,@@row:byte,@@col:byte
		USES eax,ebx,ecx,edx

			movzx eax,[@@menu]
			movzx ecx,[@@color]
			mov ebx,[textHeader+eax*4] ;title you want
			movzx eax,[colors+ecx*2]; color of the tile
			movzx ecx,[colors] ;black for the background
			movzx edx,[@@col]; col position for the cursor
			call fillBackground,ecx;black
			movzx ecx,[@@row] ;row positon for the cursor
			call printString,ebx,eax,ecx,edx
			ret
	endp menuDistribution

;according to the menu display the info correctly
	proc menuConfiguration
		ARG @@menu:word,@@color:word,@@length:word,@@col:byte
		USES eax,ebx,ecx,edx,edi

			movzx eax,[@@menu]
			movzx ecx,[@@color]
			movzx edx,[colors+ecx*2]; color to use
			movzx ecx,[@@col]
			movzx edi,[@@length]
			cmp eax,0
			je @@start
			cmp eax,1
			je @@rules
			cmp eax,2
			je @@stats
			cmp eax,3
			je @@choice
			cmp eax,4
			je @@resume
			cmp eax,5
			je @@difficuty
			cmp eax,6
			je @@game
			cmp eax,7
			je @@announce
			jmp @@end

		@@start: ;start menu options
			mov ebx,[menuMain+eax*4];the button you want
			call makeButton,ebx,edx,ecx,12,0
		 	cmp eax,edi
		 	je @@credits
			add eax,1
		 	add ecx,2
			jmp @@start

		@@rules: ;rules menu options
			mov ebx,offset rules
			call printString,ebx,edx,ecx,1
			jmp @@back

		@@stats:
			xor eax,eax;reset eax to 0 since you want to acces an array with eax

		@@statsMenu: ;stats menu options
			mov ebx,[menuStats+eax*4];text you want
			call printString,ebx,edx,ecx,5
			call printScore,eax
			cmp eax,edi
			je @@back
			add eax,1
			add ecx,4
			jmp @@statsMenu
	
		@@difficuty:
			xor eax,eax
	
		@@difficultyMenu:
			mov ebx,[menuDifficulty+eax*4];text you want
			call makeButton,ebx,edx,ecx,12,0
			cmp eax,edi
			je @@back
			add eax,1
			add ecx,2
			jmp @@difficultyMenu
		@@choice:
			xor eax,eax

		@@choiceMenu:
			mov ebx,[menuChoice+eax*4];text you want
			call makeButton,ebx,edx,ecx,12,0
			cmp eax,edi
			je @@back
			add eax,1
			add ecx,4
			movzx edx,[colors+4*2]
			jmp @@choiceMenu

		@@game:
			xor eax,eax
			movzx edx,[@@color]
			call playerTurn,edx
			movzx edx,[colors+2*2] 
	
		@@gameMenu:
			mov ebx,[menuGame+eax*4];the button you want
			cmp eax,1
			jle @@moveIndicationKeys
			call makeButton,ebx,edx,ecx,1,1
			cmp eax,edi
		 	je @@grid
			add eax,1
		 	add ecx,2
			jmp @@gameMenu
		
		@@moveIndicationKeys:
			call printString,ebx,edx,ecx,eax
			add eax,1
			add ecx,2
			jmp @@gameMenu

		@@announce:
			call announceInfo
			movzx edx,[colors+2*2]
			xor eax,eax

		@@announceMenu: ;there are 2 aling ments for the buttons hence there proc is split in 2 routines
			mov ebx,[menuAnnounce+eax*4]		
			cmp eax,2
			je @@newButtons
			call makeButton,ebx,edx,ecx,1,1
			add eax,1
			add ecx,2
			jmp @@announceMenu

		@@newButtons:
			mov ebx,[menuAnnounce+eax*4]
			call makeButton,ebx,edx,ecx,1,1
			cmp eax,edi
			je @@playerAnnounce
			add eax,1
			add ecx,2
			jmp @@newButtons

		@@playerAnnounce:;announce the player that won if someone won
			movzx edi,[@@color]; color to use
			mov eax,[turnPiece] ;xpos
			mov ebx,[turnPiece+1*4];ypos
			mov ecx,[turnPiece+2*4];piece dimention
			call drawRectangle,eax,ebx,ecx,ecx,edi,1 ;to indicate the winner
			

		@@grid:
			call drawGrid,100,10;draw the grid
			call restoreField
			jmp @@end

		@@back: ;back button is used by stats menu ,rules menu and choice menu hence it is a separate option
			movzx edx,[colors+2*2]
			mov ebx,offset back ;the back button
			call makeButton,ebx,edx,23,23,0
			jmp @@logo 

		@@resume: ;pause menu options
			mov ebx,offset resume;the resume button
			call makeButton,ebx,edx,ecx,12,0
			jmp @@end

		@@logo:
			movzx eax,[@@menu]
			cmp eax,2
			jne @@end
			call drawStats
			jmp @@end

		@@credits: ;credits have a different format that the buttons hence it is a separate option
			add eax,1
			mov ebx,[menuMain+eax*4];the text for the credits
			call printString,ebx,edx,20,2
			call drawlogo

		@@end:
			ret 
	endp menuConfiguration

;display the correct menu that you need
	proc menuDisplay
		ARG @@menu:word, @@length0:word,@@length1:word, @@col0:byte, @@col1:byte,@@player:byte
		USES eax,ebx,ecx,edx

		movzx eax,[@@menu]
		movzx ecx,[@@length0] ;length for the menuDisribution call
		movzx edx,[@@col0];column for the menuDistribution call
		mov ebx,2 ;white
		cmp eax,0
		call hideMouse
		je @@mainScreen
		jg @@screenDisplay

		@@mainScreen:
			add ebx,3 ;5 is green 
			call menuDistribution,eax,ebx,ecx,edx
			sub ebx,3; return back to white
			jmp @@configurationCheck
	
		@@screenDisplay:
			cmp eax,7 ;announce menu does not have headers so you can skip it
			je @@configurationCheck
			call menuDistribution,eax,ebx,ecx,edx

		@@configurationCheck:
			movzx ecx,[@@length1] ;length for the menuConfiguration call
			movzx edx,[@@col1];column for the menuConfiguration call
			cmp eax,6
			jl @@player1
			movzx ebx,[@@player]
	
		@@player1:	
			cmp eax,3;inside the choice menu the player 1 buton needs to be yellow
			jne @@menuConfig
			mov ebx,3 ;change the color to yellow

		@@menuConfig:
			call menuConfiguration,eax,ebx,ecx,edx
			call displayMouse
			ret
	endp menuDisplay

DATASEG
;;;Vetors with offset for the menus
	;vector titles
		textHeader dd offset connect4, offset titleRules, offset statistics, offset beginner, offset paused,offset difficulty,offset enumeration
	;vector start menu
		menuMain dd offset start, offset rule, offset stats, offset exit, offset credits
	;vector stats menu
		menuStats dd offset draws,offset p1,offset p2
	;vector choice menu
		menuChoice dd offset player1, offset player2
	;vector game menu
		menuGame dd offset movement, offset moving, offset pauze, offset undo	
	;vector announce menu
		menuAnnounce dd offset restart, offset menu, offset statsAfterPlay, offset exitAfterPlay
	;vector difficulty menu
		menuDifficulty dd offset veasy, offset easy, offset standard, offset tricky, offset hard, offset extreme, offset square

;;;;Rules
	;rules
		rules	db "The goal of the game is to obtain 4",'~'
				db "tokens of the same color in a straight",'~'
				db "line.",'~'
				db "Do it before the opponent.",'~'
				db "This can be done in 3 ways: a slope,",'~'
				db "horizontaly or verticaly.",'~'
				db '~'
				db "The game can only be played against",'~'
				db "another person.",'~'
				db "Players take turns until the board is",'~'
				db "full or a winner is declared.",'~'
				db "To place a piece press the number of",'~'
				db "the corresponding column or use the",'~'
				db "mouse.",'~'
				db "Navigate the menus by pressing the key",'~'
				db "of the corresponding action you want",'~'
				db "to perform or use the mouse to do it.",'~'
				db '~'
				db "Note: undo can only be used in between",'~'
				db "2 moves and the statistics reset after",'~'
				db "exiting the current execution of the",'~'
				db "app.",'$'

;;;;Special interactions
	;resume
		resume db "   Resume = u",'$'          
	;back
		back db "    Back = b",'$'
	;movement mouse
		moving db "Or mouse",'$'

END