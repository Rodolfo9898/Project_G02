IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"

CODESEG
;change the videomode
	proc setVideoMode
		ARG 	@@VM:byte
		USES 	eax

	    	movzx ax,[@@VM]
	    	int 10h
			ret
	endp setVideoMode

;terminate a process correctly
	proc terminateProcess
		ARG @@color:word,@@size:word
		USES eax,ebx,ecx,edx
	
    	;restore to txt-mode and close videomode
	    	call setVideoMode, 03h
			mov ah, 09h 				;om string naar standaard input te schrijven
			mov bx,[@@color] 
			mov cx,[@@size]
			int 10h
			mov edx, offset msg			;string die afgeprint moet worden bij het verlaten van de app
			int 21h
	   		mov	ax,04C00h
	    	int 21h
			ret
	endp terminateProcess

DATASEG
;;;;Internal constants
	;end message
		msg db "You just exited the app. Thanks for playing! Relaunch the app via C4.exe",'$'
	
;;;;Constants
	;field is the array that will contain information about the current game
	;in the array we represent each player by its color so a piece from players
	;will be represented by they color and an empyty space by 0.
		field db 70 dup(0)
	;gridValues are the values used to determine the size of the grid
	;they are orded : horizontal spaces,vertical spaces.
		gridValues db 6,7
	;how many elements are on 1 row
		rowInBetween dd 7
	;the last piece on the board
		upperRightCorner dd 41
	;indicate what the last valid input in the game is
		validateInput db '7'
	;these values indicate where in the array the next row starts
		rowSeparation db 0,0,0,0,0,0,0
	;indicate wher the first top start in the array
		firstTop dd 35
	;statusGrid will hold all the states usfull to element of the grid
	;they are : has some won,did we ask to undo the previous move
	;and to reprensent a winner. we use 0 for no winner yet and you can still make a move,
	;1 for player1 has won, 2 for player2 has won and 3 to indicate a draw
	;to indicate if we asked to undo a move we use 0 for false and 1 for true
		statusGrid db 0,0
	;these are the positions of the spaces in the grid
	;vertical for the vertical postion in the grid and horizontal for the horizontal postion
	;if you combine the first element from vertical + any off the elements from horizontal 
	;you can access the bottom row of the grid to place a piece.
		vertical  dd 0,0,0,0,0,0,0,0
		horizontal dd 0,0,0,0,0,0,0,0,0,0
	;this are the colors used in the graphics
	;the colors are: black,blue,white,yellow,purple and green
		colors dw 0,1,15,14,13,2
	;current menu you are watching
        currentMenu db 0
	;field chosen to play on
		fieldType db 0
	;player you chose to start
		playerColor db 0

END