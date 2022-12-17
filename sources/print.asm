IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "incFiles/setup.inc"
include "incFiles/print.inc"

CODESEG
;move the cursor to a specific place
	proc moveCursor
		ARG @@row:byte,@@column:byte
		USES eax,edx,ecx
	
			mov ah,02h 
			mov dl,[@@row]
			mov dh,[@@column]
			int 10h 
			ret 
	endp moveCursor
;Print a character on the screen
	proc printChar
		ARG @@color:word,@@char:byte
		USES eax,ebx,ecx

			mov ah,09h
			mov bx,[@@color]  ;colour
			mov cx,1
			mov al,[@@char]     ;print
			int 10h 
			ret
	endp printChar

;Print a string onto a specific position on screen with a specific color
	proc printString
		ARG @@string:dword,@@color:word,@@row:byte,@@column:byte
		;row is the hoizontal position
		;column is the vetical position
		USES eax,edx,ebx,ecx,edi

			mov ecx, [@@string]
			movzx edi,[@@color]
			movzx eax,[@@row]
			movzx ebx,[@@column]
	
		@@loop:
			call moveCursor,ebx,eax ;adjust the cursor correctly
			mov edx,[ecx] ;get the current character you want
			cmp dl,'~' ;this is to symbolize a newline
			je @@nextLine
			cmp dl,'$'; this is to indicate the end of the string 
			je @@end
			call printChar,edi,edx ;print the char
			inc ebx
			jmp @@nextChar
	
		@@nextLine:
			inc eax
			movzx ebx,[@@column]

		@@nextChar:
			inc ecx
			jmp @@loop
	
		@@end:
			ret
	endp printString

;print the scores
	proc printScore
		ARG @@number:byte
		USES eax,ebx,ecx,edx,edi
			
			movzx ebx,[@@number]
			movzx eax,[winnerCount+ebx] ;the current score for draws,player1 and player2 depending on @@number
			mov	ebx, 10		; divider
			xor ecx, ecx	; counter for digits to be printed

		; Store digits on stack
		@@getNextDigit:
			inc	ecx         ; increase digit counter
			xor edx, edx
			div	ebx   		; divide by 10
			push dx			; store remainder on stack
			test eax, eax	; check whether zero?
			jnz	@@getNextDigit
			movzx ebx,[@@number]
			movzx edx,[cursorPosVert+ebx] ;the correct possiton for the cursor
			movzx edi,[cursorPosHor]
			movzx ebx, [colors+2*2]
		@@printDigits:		
			pop ax
			add	al,'0'      	; Add 30h => code for a digit in the ASCII table, ...
			call printChar,ebx,eax	; Print the digit to the screen, ...
			call moveCursor,edi,edx
			add edi,1  
			loop @@printDigits	; Until digit counter = 0.
			ret
	endp printScore

DATASEG
;;;;Constants
    ;to hold the information of who has won howmany times
	;they are orded as follows: draws,wins by player1,wins by player 2	
		winnerCount db 0,0,0
    ;cursor positons in statistics verticaly
		cursorPosVert db 10,14,18
    ;cursor position in statistics horizontaly
		cursorPosHor db 25

;;;;Titles
	;connect 4
		connect4 db "Connect 4",'$'
	;rules
		titleRules db "Rules",'$'
    ;statistics
		statistics db "Statistics",'$'
	;beginner
		beginner db "Chose who will begin:",'$'
	;paused
		paused db "Pauzed",'$'
    ;difficulty
		difficulty db "Chose size of playfield:",'$'
    ;ennumeration for the cols
		enumeration db " 1  2   3   4   5  6   7",'$'

;;;;Interactions
	;start
		start db "Start = spacebar",'$'
	;rules
		rule db "    Rules = r",'$'
    ;statistics
		stats db "   Stats = s",'$'
	;exit
		exit db "   Exit = esc",'$'
	;player1
		player1 db "  Player1 = 1",'$'
	;player2
		player2 db "  Player2 = 2",'$'
	;move
		movement db " Move = 1-7",'$'
    ;pauze
		pauze db "Pause = p",'$'
	;undo
		undo db "Undo = d",'$'
	;restart
		restart db "Restart = e",'$'
	;menu
		menu db "Menu = l",'$'
	;exit after an endgame
		exitAfterPlay db "Exit = esc",'$'
	;statistics after an endgame
		statsAfterPlay db "Stats = s",'$'
   
;;;;Game announcements   
    ;winner
		winner db "Winner:",'$'
	;draw
		draw db "Draw!",'$'
	;turn
		turn db "Turn :",'$'

;;;;Extra text
	;player1
		p1 db "Player 1 has won:  ",'$'
	;player2
		p2 db "Player 2 has won:  ",'$'
	;draws
		draws db  "No winner found :  ",'$'
	;credits
		credits db "Made by Rodolfo Alberto Perez Tobar",'$'

;;;;Difficulties
		;very easy
			veasy db "Easiest: 5*4 = 1",'$'
		;easy
			easy db "Easy   : 6*5 = 2",'$'
		;standard
			standard db "Normal : 7*6 = 3",'$'
		;tricky
			tricky db "Tricky : 8*7 = 4",'$'
		;hard
			hard db "Hard   : 9*7 = 5",'$'
		;extreme
			extreme db "Extreme:10*7 = 6",'$'
		;square
			square db "Square : 8*8 = 7",'$'

END