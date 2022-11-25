IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"
include "print.inc"
include "draw.inc"
include "array.inc"
include "logic.inc"
include "mouse.inc"

CODESEG
;make a move on the board+update the array correctly
	proc makeMove
		ARG @@col:word,@@plyr:byte,@@undo:byte
		USES eax,ebx,ecx,edx
			
			call hideMouse
		;prepare to make the correct move
			movzx eax, [@@col]
			movzx edx,[@@undo]
			xor ebx,ebx
		;look where the move can be made in the given column
		@@lookForEmptySpace:
			movzx ecx ,[field + eax]
			cmp ecx,0
			je @@foundEmpty
			jmp @@occupiedCurrent
		
		;undo the move	if undo = 1 else you are making a normal move
		@@foundEmpty:
			cmp edx,1
			je @@undoMove
			movzx cx, [@@plyr]
			call updateStatus,eax,cx  
			movzx eax,[@@col]
			call drawMove,ebx,eax,cx
			jmp @@end
		
		@@undoMove:
			xor ecx,ecx
			sub eax,[rowInBetween]
			sub ebx,1
			cmp ebx,0
			jl @@end
			call updateStatus,eax,cx  
			movzx eax,[@@col]
			call drawMove,ebx,eax,cx
			jmp @@end

		;check for same colum 1 row higher
		@@occupiedCurrent:	
			add eax,[rowInBetween]
			add ebx,1  
			cmp eax,[upperRightCorner]
			jg @@outOfBoundsComputed
			jmp @@lookForEmptySpace

		;you are looking outside the grid	
		@@outOfBoundsComputed:
			cmp edx,1
			je @@undoMove

		@@end:
			call displayMouse
			ret
	endp makeMove

;check if the board is full
	proc fullCheck
		;compare each top off each column to see if it is empty or not
		;if top empty you can still make a move  in that column and the board is not full yet
		;else the column is full and check the rest off columns
		;if all top off columns are not empty the board is full.
		USES ecx
	
			mov ecx,[firstTop]

		@@fullCheck:	
			cmp ecx,[upperRightCorner]
			jg @@full
			cmp [field+ecx],0
			je @@endCheck
			add ecx,1
			jmp @@fullCheck
	
		@@full:
			mov [statusGrid],3
			movzx ecx,[winnerCount]
			add ecx,1
			mov [winnerCount],cl
	
		@@endCheck:
			ret 
	endp fullCheck

;check for one 4 in row in any direction
	proc winCondition
		;the direction depends on the size of the step
		;horizontal step =1
		;vertical step = 7
		;positive slope = 8
		;negative slope = -6
		;but with the negative slope we will start at the end off the slope and work our way up to the beginning so the step is actualy 6 instead of -6
		ARG @@row:word,@@col:word,@@step:word,@@player:byte
		USES eax,ebx,ecx,edx
	
			movzx eax,[@@row] ;postion verticaly
			mov ebx,eax
			mov ecx,0
		
		@@adjust_verticaly:
			cmp ecx,ebx
			je @@adjusted
			add al,[gridValues] ; to add the correct height
			add ecx,1
			jmp @@adjust_verticaly
		
		@@adjusted:
			movzx ebx,[@@col]
			xor ecx,ecx ;prepare to count if you found 4 in a row
			add eax,ebx ;adjust the position to the correct column where you want to start looking
			movzx ebx,[@@step]
			movzx edx,[@@player]
		
		@@lookFor4:
			cmp [field+eax],dl
			je @@foundOne;the piece matches the given player
			jne @@doNotLook ;the piece does not matches the given player so stop looking for a possibility off 4 in a row
		
		@@foundOne:
			cmp ecx,3 ;since we count from zero you have a connect4 if ecx=3
			jl @@possibleWin
			je @@winFound
			jg @@endWinCondition
		
		@@possibleWin:
			add ecx,1
			add eax,ebx
			jmp @@lookFor4
		
		@@winFound:
			cmp dx,[colors+3*2]
			je @@p1
			mov[statusGrid],2
			movzx ecx,[winnerCount+2]
			jmp @@adjustStats
	
		@@doNotLook:
			mov[statusGrid],0
			jmp @@endWinCondition
		
		@@p1:
			mov[statusGrid],1
			movzx ecx,[winnerCount+1]
		
		@@adjustStats:
			movzx ebx,[statusGrid]
			add ecx,1
			mov [winnerCount+ebx],cl
		
		@@endWinCondition:
			ret
	endp winCondition

;check all possible wins in 1 direction
	proc checkWinForDirection
			;max will specify where the last possibility for a connect four start is
			;verticaly this will be at height 2 since we start to count from 0 bottom to top
			;the negative slope will be at width 6(max cols)
			;the rest will have it at width 3 since we start to count from 0 left to right(this is the middle column)
		ARG @@maxH:word,@@maxV:word,@@beginH:word,@@step:word,@@player:byte,@@expectedStatus:byte
		USES eax,ebx,ecx,edx
	
			movzx eax,[@@beginH]; col 
			mov ebx,0; row "vertical begin"
			movzx edx,[@@step]
	
		@@checkDirection:
			movzx ecx,[@@player]
			call winCondition,ebx,eax,edx,ecx
			movzx ecx,[@@expectedStatus]
			cmp [statusGrid],cl
			je @@endCheckDirection
		
		@@checkNext:
			movzx ecx,[@@maxH] ;max
			add eax,1
			add ecx,1
			cmp eax,ecx
			jl @@checkDirection
		
		@@nextSet:
			movzx eax,[@@beginH]; col
			movzx ecx,[@@maxV] ;max
			add ebx,1
			add ecx,1
			cmp ebx,ecx
			jl @@checkDirection
	
		@@endCheckDirection:
			ret 
	endp checkWinForDirection


;check field for a win in all directions
	proc checkWinner
		ARG @@player:byte,@@expectedStatus:byte
		USES eax,ebx,ecx,edx
			movzx eax,[@@player]
			movzx ebx,[@@expectedStatus]
			xor ecx, ecx

		;loop to check all directions for a player
		@@checker:	
			mov edx,[winChecker+4*ecx]
			call checkWinForDirection,[edx],[edx+4],[edx+8],[edx+12],eax,ebx
			cmp [statusGrid],bl
			je @@end
			cmp ecx,3
			je @@changePlayerCheck
			add ecx,1
			jne @@checker
		
		;setup the check for player 2
		@@changePlayerCheck: 
			cmp ax,[colors+3*2]
			jne @@end
			movzx eax,[colors+4*2]
			add ebx,1
			xor ecx,ecx
			jmp @@checker

		@@end:
			ret 
	endp checkWinner
	
;check status game
	proc gameStatus
		USES eax
	
			movzx eax,[colors+3*2]
			call checkWinner,eax,1
			cmp [statusGrid],0
			jg @@endCheck
			call fullCheck
	
		@@endCheck:
			ret
	endp gameStatus

DATASEG
    ;used to look if there is a winner in any direction
		winChecker dd offset horCheck, offset vertCheck, offset posCheck, offset negCheck

END