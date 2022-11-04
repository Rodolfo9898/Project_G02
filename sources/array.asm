IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"
include "print.inc"
include "draw.inc"
include "array.inc"
include "mouse.inc"

CODESEG
;uptade the arrary
	proc updateStatus
		ARG @@arraypos:word,@@newStatus:byte
		USES eax,ebx
	
			movzx eax,[@@arraypos]
			movzx ebx, [@@newStatus]
			mov [field+eax], bl
			ret
	endp updateStatus

;adapt the values for gridValues
	proc adaptGridValues
		ARG @@value:byte
		USES eax,ebx,ecx,edx,edi
			movzx eax,[@@value]
			mov edi,0 ;acces the vectors
			mov edx, offset gridValuesVector

		@@prepOverride:
			mov ebx,[edx+4*edi] ;the vector you need 
			mov ecx,[ebx+eax] ;the value you need
		
		@@override:
			mov [gridValues+edi],cl

		@@checkIfDone:
			cmp edi,1
			jge @@end
		
		@@computeNext:
			add edi,1
			jmp @@prepOverride

		@@end:
		ret
	endp adaptGridValues

;adapt the values that draw the grid
	proc adaptDrawGird
		ARG @@value:byte
		USES eax,ebx,ecx,edx,edi
			movzx edi,[@@value]
			mov ebx,offset gridDrawVector
			mov ecx,0 ;access in gridDrawVector
			
		;load the correct vector from grid draw vector
		@@load:
			mov edx,[ebx+ecx];the correct vector
			movzx ax,[edx+edi];the value you need
		
		@@ovveride:
			mov [grid+ecx],eax;overridde in the grid vector the correct value
			add ecx,4
			cmp ecx,12
			jg @@end
			jmp @@load

		@@end:
			ret
	endp adaptDrawGird
	
;adapt the dimintions for the piece on the board
	proc adaptPieceDim
		ARG @@value:byte
		USES eax,ebx

			;load and adapt the size of the piece you can draw
			movzx eax,[@@value]
			movzx ebx,[pieceDimetions+eax]
			mov [pieceDim],ebx
			ret
	endp adaptPieceDim

;adapt the interpeation off the field for the gamelogic
	proc adaptFieldLogic
		ARG	@@value:byte
		USES eax,ebx,ecx,edx,edi
			movzx edi,[@@value]
			mov ebx,offset gridBorderVector
			mov ecx,0 ;access in gridBorderVector

		;load the correct vector from grid border vector
		@@load:
			mov edx,[ebx+ecx];the correct vector
			movzx ax,[edx+edi];the value you need

		@@ovverideDispatch:
			cmp ecx,0
			je @@overrideRightCorner
			cmp ecx,4
			je @@overrideIntercalation
		
		@@overrideLeftTop:
			mov [firstTop],eax;overridde in the grid vector the correct value
			jmp @@nextOverride
		
		@@overrideRightCorner:
			mov [upperRightCorner],eax;overridde in the grid vector the correct value
			jmp @@nextOverride
		
		@@overrideIntercalation:
			mov [rowInBetween],eax;overridde in the grid vector the correct value
		
		@@nextOverride:
			add ecx,4
			cmp ecx,8
			jg @@prepRowsOverride
			jmp @@load
		
		@@prepRowsOverride:
			mov ebx,offset gridRowsVector
			mov ecx,0 ;access in gridRowsVector
		
		;load the correct vector from grid rows vector
		@@loadrow:
			mov edx,[ebx+4*ecx];the correct vector
			movzx ax,[edx+edi];the value you need
		
		@@override:
			mov [rowSeparation+ecx],al;overridde in the grid vector the correct value
			add ecx,1
			cmp ecx,6
			jg @@end
			jmp @@loadrow

		@@end:
			ret
	endp adaptFieldLogic

;adapt the coordinates off where you can draw
	proc adaptCoordinates
		ARG	@@value:byte
		USES eax,ebx,ecx,edx,edi
			movzx edi,[@@value]
			mov ebx,offset gridCooHorVector
			mov ecx,0 ;access in gridCooHorVector

		;load the correct vector from grid coor hor vector
		@@loadHor:
			mov edx,[ebx+4*ecx];the correct vector
			mov eax,[edx+4*edi];the value you need
		
		@@overideHor:
			mov [horizontal+4*ecx],eax;overridde in the grid vector the correct value
			add ecx,1
			cmp ecx,9
			jg @@prepVert
			jmp @@loadHor

		@@prepVert:
			mov ebx,offset gridCooVertVector
			mov ecx,0 ;access in gridCooVertVector
		
		;load the correct vector from grid coor vert vector
		@@loadVert:
			mov edx,[ebx+4*ecx];the correct vector
			movzx ax,[edx+edi];the value you need
		
		@@overideVert:
			mov [vertical+4*ecx],eax;overridde in the grid vector the correct value
			add ecx,1
			cmp ecx,7
			jg @@end
			jmp @@loadVert
		
		@@end:
			ret
	endp adaptCoordinates
	
;adapt the ennumeation text
	proc adaptEnnumeration
		ARG	@@value:byte
		USES eax,ebx,ecx,edx,edi
			movzx edi,[@@value]
			mov ebx,offset gridEnnumVector
			mov ecx,0 ;access in gridEnnumVector
		
		;load the correct vector from grid border vector
		@@load:
			mov edx,[ebx+4*edi];the correct vector
			movzx ax,[edx+ecx];the value you need
		
		@@overide:
			mov [enumeration+ecx],al;overidde in the grid vector the correct value
			add ecx,1
			cmp ecx,23
			jg @@end
			jmp @@load

		@@end:
			ret
	endp adaptEnnumeration

;adapt the move text
	proc adaptMoveText
		ARG	@@value:byte
		USES eax,ebx,ecx,edx,edi
			movzx edi,[@@value]
			mov ebx,offset moveDisplayVector
			mov ecx,0 ;access in moveDisplayVector
		
		;load the correct vector from grid border vector
		@@load:
			mov edx,[ebx+4*edi];the correct vector
			movzx ax,[edx+ecx];the value you need
		
		@@overide:
			mov [movement+ecx],al;overidde in the grid vector the correct value
			add ecx,1
			cmp ecx,10
			jg @@end
			jmp @@load

		@@end:
			ret
	endp adaptMoveText


;adapt validator for the inputs
	proc adaptValidator
		ARG	@@value:byte
		USES eax,ebx
			movzx eax,[@@value]
			movzx ebx,[validators+eax]
			mov [validateInput],bl
			ret
	endp adaptValidator

;adapt win condition
	proc adaptWinCondition
		ARG	@@value:word, @@direction:byte
		USES eax,ebx,ecx,edx,edi
			movzx edi,[@@value]
			mov ecx,0 ;access insde the vector that you find in ebx
		
		@@loadDispatcher:
			cmp [@@direction],0
			je @@hor
			cmp [@@direction],1
			je @@vert
			cmp [@@direction],2
			je @@pos
		
		;the negative slope
		@@neg:
			mov ebx,offset negWinVector
			
		;load the correct vector from negWinVector
		@@loadneg:
			mov edx,[ebx+4*ecx];the correct vector
			movzx ax,[edx+edi];the value you need
			mov [negCheck+4*ecx],eax;overridde in the grid vector the correct value
			jmp @@overide

		;the horizontal direction
		@@hor:
			mov ebx,offset horWinVector
			
		;load the correct vector from horWinVector
		@@loadhor:
			mov edx,[ebx+4*ecx];the correct vector
			movzx ax,[edx+edi];the value you need
			mov [horCheck+4*ecx],eax;overridde in the grid vector the correct value
			jmp @@overide
		
		;the vertical direction
		@@vert:
			mov ebx,offset vertWinVector
			
		;load the correct vector from vertWinVector
		@@loadvert:
			mov edx,[ebx+4*ecx];the correct vector
			movzx ax,[edx+edi];the value you need
			mov [vertCheck+4*ecx],eax;overridde in the grid vector the correct value
			jmp @@overide
		
		;the positve slope
		@@pos:
			mov ebx,offset posWinVector
			
		;load the correct vector from posWinVector
		@@loadpos:
			mov edx,[ebx+4*ecx];the correct vector
			movzx ax,[edx+edi];the value you need
			mov [posCheck+4*ecx],eax;overridde in the grid vector the correct value

		@@overide:
			add ecx,1
			cmp ecx,3
			jg @@end
			jmp @@loadDispatcher

		@@end:
			ret
	endp adaptWinCondition
	
;clear the grid for a new game
	proc clearGrid
		USES 	ecx

			xor ecx,ecx; zero is the neutral value 
		@@loop:;fill the grig up with zeros
			mov [field+ecx],0
			add ecx,1
			cmp ecx,[upperRightCorner] ;last element in the grid
			jg @@end
			jmp @@loop
	
		@@end:
			ret 
	endp clearGrid

;restore the current state off the game after being unpaused
	proc restoreField
		USES eax,ebx,ecx,edx,edi
	
			xor ecx,ecx; current place inside the grid
			xor eax,eax; current row
			xor ebx,ebx; current col
			xor edi,edi;position isdie the grid vector
		
		@@restore:
			movzx edx,[field+ecx];the state of the field
			cmp edx,0 ;did a player make a move into this space
			je @@computeNext
	
		@@nonEmptySpace:
			;draw the piece that occupies the space
			call drawMove,eax,ebx,edx 
			jmp @@computeNext
		
		;loop through the whole array to redraw the game before the pause
		@@computeNext:
			add ecx,1
			cmp cl,[rowSeparation+edi]
			je @@nextRow
			cmp ecx,[upperRightCorner]
			jg @@end
		
		;go to the next space to the right
		@@nextColumn:
			add ebx,1
			jmp @@restore

		;since you go from left to right in this process when you need to restart one space above again	
		@@nextRow:
			xor ebx,ebx
			add eax,1
			add edi,1
			jmp @@restore 
	
		@@end:
			ret
	endp restoreField

;adapt the field to a given size
	proc adaptField
		ARG	@@value:byte
		USES eax,ebx
			movzx eax,[@@value]
			mov ebx,0

			;change the size off the field
			call adaptGridValues,eax
 			;change the values to draw the grid
			call adaptDrawGird,eax
			;change the values off the piece size	
			call adaptPieceDim,eax		
 			;change the interpretation off the field size
			call adaptFieldLogic,eax
 			;change the spaces where you can draw verticaly +horizontaly
			call adaptCoordinates,eax
			;change the ennumeration to indicate the valid inputs
			call adaptEnnumeration,eax
			;change the valid inputs
			call adaptValidator,eax
			;change the move instruction on screen
			call adaptMoveText,eax
		;change the win condition
		@@winCondition:
			call adaptWinCondition,eax,ebx
			add ebx,1
			cmp ebx,4
			je @@end
			jmp @@winCondition
			
		@@end:
			ret 
	endp adaptField

DATASEG
;;;;Values that are used to create the vectors
	;they are used to calculate the win condition	
	;these values are used as follows:
	;max horizontal pos for the win to start, max vertical pos for the win to start,start looking from here(horizontal pos), where woud you find the next piece for 4 in a row
	;the values you need to give in CheckWinForDirection when checking horizontal
		horCheck dd 3,5,0,1
	;the values you need to give in CheckWinForDirection when checking vertical
		vertCheck dd 6,2,0,7 
	;the values you need to give in CheckWinForDirection when checking positve slope
		posCheck  dd 3,2,0,8
	;the values you need to give in CheckWinForDirection when checking negative slope
		negCheck dd 6,2,3,6
	;these are the values that are used to overide the move instuction on the screen
		game5by4 db "Move = 0-4",'$'
		game6by5 db "Move = 0-5",'$'
		game7by6 db "Move = 0-6",'$'
		game8by7 db "Move = 0-7",'$'
		game9by7 db "Move = 0-8",'$'
		game0by7 db "Move = 0-9",'$'
    ;these ohter ennumerations will replace the standard one to make the player aware off what the valid inputs are
	    enum5by4 db " 0     1    2     3    4",'$'
	    enum6by5 db " 0   1    2   3   4    5",'$'
	    enum7by6 db " 0  1   2   3   4  5   6",'$'
	    enum8by7 db " 0  1  2  3  4   5  6  7",'$'
	    enum9by7 db "0  1  2  3  4  5  6 7  8",'$'
	    enum0by7 db "0  1 2  3 4  5  6 7  8 9",'$'
	    enum8by8 db "0  1  2  3  4  5  6  7  ",'$'
    ;values that can replace the standard ones in gridValues
		gridVerticals db 4,5,6,7,7,7,8
		gridHorizontals db 5,6,7,8,9,10,8
    ;values that can replace the standard ones in grid
		gridTickness db 10,10,10,12,13,10,10
		gridSpacing db 42,35,30,26,23,21,23
		gridHeight db 178,175,180,182,161,147,194
		gridWidth db 220,220,220,220,220,220,184
    ;these values will override the values in rowSeparation
	;row zero is not present since they all start from 0
		r1 db 5,6,7,8,9,10,8 ;fisrt row
		r2 db 10,12,14,16,18,20,16 ;second row
		r3 db 15,18,21,24,27,30,24 ;third row
		r4 db 0,24,28,32,36,40,32 ; forth row
		r5 db 0,0,35,40,45,50,40 ;fifth row
		r6 db 0,0,0,48,54,60,48 ; sixth row
		r7 db 0,0,0,0,0,0,56 ;seventh row
    ;these values can change firstTop to indiace the fisrt top in the grid
		tops db 15,24,35,48,54,60,56
    ;these values can change rowInBetween acording to the size off the grid
		rowElements db 5,6,7,8,9,10,8
    ;these are the possible last elements off the grid (upperRightCorner)
		corners db 19,29,41,55,62,69,63
    ;indicate what the last valid input in the game is
		validators db '5','6','7','8','9',':','8'
    ;these will help you adapt the spaces for the given field in vertical
		v0 db 146,160,170,178,161,146,181
		v1 db 104,125,140,152,138,125,158
		v2 db 62,90,110,126,115,104,135
		v3 db 20,55,80,100,92,83,112
		v4 db 0,20,50,74,69,62,89
		v5 db 0,0,20,48,46,41,66
		v6 db 0,0,0,22,23,20,43
		v7 db 0,0,0,0,0,0,20
    ;these will help you adapt the spaces for the given field in horizontal
		h0 dd 110,110,110,112,113,110,110
		h1 dd 152,145,140,138,136,131,133
		h2 dd 194,180,170,164,159,152,156
		h3 dd 236,215,200,190,182,173,179
		h4 dd 278,250,230,216,205,194,202
		h5 dd 0,285,260,242,228,215,225
		h6 dd 0,0,290,268,251,236,248
		h7 dd 0,0,0,294,274,257,271
		h8 dd 0,0,0,0,297,278,0,0
		h9 dd 0,0,0,0,0,299,0,0
		;vertical  dd 170,140,110,80,50,20 ;original
		;horizontal dd 110,140,170,200,230,260,290 ;original
    ;these values can change pieceDim to the corresponding size	
		pieceDimetions db 32,25,20,14,10,11,13
    ;last starting position horizonal(looking to the hoizontal elements only)
		startLastHor db 1,2,3,4,5,6,4
		startLastVert db 4,5,6,7,7,7,8
		startLastPos db 1,2,3,4,5,6,4
		startLastNeg db 4,5,6,7,8,9,7
    ;last starting position vertical (looking to the vertical elements only)
		lastStartHor db 3,4,5,6,6,6,7
		lastStartVert db 0,1,2,3,3,3,4
		lastStartSlope db 0,1,2,3,3,3,4
    ;starting position horizontal
		positionHor db 0,0,0,0,0,0,0
		positionHorNegSlope db 3,3,3,3,3,3,3
    ;steps to take in the board
		stepsHorizontal db 1,1,1,1,1,1,1
		stepsVertical db 5,6,7,8,9,10,8
		stepsPos db 6,7,8,9,10,11,9
		stepsNeg db 4,5,6,7,8,9,7

;;;;Vectors used in adaptField
    ;vetor for the grid values
		gridValuesVector dd offset gridVerticals, offset gridHorizontals
	;vector for draw grid
		gridDrawVector dd offset gridTickness, offset gridSpacing, offset gridHeight, offset gridWidth
	;vector for the board definition
		gridBorderVector dd offset corners, offset rowElements, offset tops
	;vector for the row separations
		gridRowsVector dd offset r1, offset r2, offset r3, offset r4, offset r5, offset r6, offset r7
	;vector horizontal coordinates
		gridCooHorVector dd offset h0, offset h1, offset h2, offset h3, offset h4, offset h5, offset h6, offset h7, offset h8, offset h9
	;vector vertical coordinates
		gridCooVertVector dd offset v0, offset v1, offset v2, offset v3, offset v4, offset v5, offset v6, offset v7
	;vector for changing the horizontal wincondition
		horWinVector dd offset startLastHor, offset lastStartHor, offset positionHor, offset stepsHorizontal
	;vector for changing the vertical wincondition
		vertWinVector dd offset startLastVert, offset lastStartVert, offset positionHor, offset stepsVertical
	;vector for changing the vertical wincondition
		posWinVector dd offset startLastPos, offset lastStartSlope, offset positionHor, offset stepsPos
	;vector for changing the vertical wincondition
		negWinVector dd offset startLastNeg, offset lastStartSlope, offset positionHorNegSlope, offset stepsNeg
    ;vector for the ennumerations
	 	gridEnnumVector dd offset enum5by4,offset enum6by5, offset enum7by6, offset enum8by7, offset enum9by7, offset enum0by7, offset enum8by8
	;vector to change the move instruction
		moveDisplayVector dd offset game5by4, offset game6by5,offset game7by6, offset game8by7, offset game9by7, offset game0by7, offset game8by7

END