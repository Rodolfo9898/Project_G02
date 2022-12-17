IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "incFiles/setup.inc"
include "incFiles/print.inc"
include "incFiles/draw.inc"
include "incFiles/sprites.inc"

;;;;global constants
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

CODESEG
;fill background
	proc fillBackground
		ARG 	@@fillcolor:byte
		USES 	eax, ecx, edi
	
	    	mov	edi, VMEMADR ; Initialize video memory address.
	    	mov	ecx, SCRWIDTH*SCRHEIGHT ; Scan the whole video memory and assign the background colour.
	    	mov	al,[@@fillcolor]
	    	rep	stosb
	    	ret
	endp fillBackground

;draw a rectangle filled or only the border depending on the value of  @@filled
;filled will indicate if you want to draw a filled rectangle or not 0 false and 1 true
	proc drawRectangle
		ARG @@x0:word,@@y0:word,@@width:word,@@height:word,@@color:word,@@filled:byte
		USES 	eax,ebx,ecx,edx, edi ; note: MUL USES edx!

			movzx eax, [@@y0]; Compute the index of the rectangle's top left corner
			mov edx, SCRWIDTH
			mul edx
			add	ax, [@@x0]
			mov edi, VMEMADR; Compute top left corner address
			add edi, eax
		
		; Plot the top horizontal edge.
			movzx edx, [@@width]	; store width in edx for later reuse
			mov	ecx, edx
			movzx	eax,[@@color]
			rep stosb
			sub edi, edx		; reset edi to left-top corner
			movzx ebx,[@@filled] ;look if you want a filled or only the border off a rectangle
			cmp ebx,1
			je @@fill
			movzx ecx,[@@height]; plot both vertical edges

		@@vertLoop:
			mov	[edi],ax		; left edge
			mov	[edi+edx-1],ax	; right edge
			add	edi, SCRWIDTH
			loop @@vertLoop
			sub edi, SCRWIDTH; edi should point at the bottom-left corner now
			mov	ecx, edx; Plot the bottom horizontal edge.
			rep stosb
			jmp @@end
		
		@@fill:
			movzx ebx,[@@height]
			movzx ecx,[@@width]
		
		@@filledLoop:
			rep stosb
	    	movzx ecx,[@@width]
	    	sub edi, edx
	    	add edi, SCRWIDTH
	    	dec ebx
	    	cmp ebx,0
	    	jnz @@filledLoop
	
		@@end:
			ret
	endp drawRectangle

;draw grid
	proc drawGrid
		ARG 	@@x0:word, @@y0:word
		USES 	eax,ebx,ecx,edx

			movzx eax,[@@x0] ;x-coordinate begin
			movzx ebx,[@@y0] ;y-coordinate begin
			movzx ecx,[gridValues+1];this are the rows
			movzx edx,[gridValues] ;this are the columns

    	@@horizontal:;loop to draw all horizontal lines of the grid
			call drawer,eax,ebx,0
			;call drawSprite,eax,ebx,offset fieldXL,22,22,0     ;;;;add the adjustemnts in array
			cmp ecx,1
			je @@next
			sub ecx,1
			;add ebx,[grid+1*4]
			add eax,[grid]; add the width of the image in pixels
			jmp @@horizontal

    	@@next: ;adjuts the next line
			sub edx,1
			cmp edx,0
			je @@end
			movzx ecx,[gridValues+1];this are the rows
			movzx eax,[@@x0] ;reset the x-coordinate
			add ebx,[grid]; add the height of the image in pixels
			jmp @@horizontal

    	@@end:
        	ret
	endp drawGrid

;draw a move on the board
;row is op de horizontaale as kiezen
;col is op de verticale as kiezen
;row : 0<=row<=6
;col: 0<=col<=5
	proc drawMove
		ARG 	@@row:word,@@col:word,@@plyr:byte
		USES 	eax,ebx,ecx,edx
	
			movzx eax,[@@col] ;column
			movzx ebx,[@@row];row
			mov ebx,[vertical+4*ebx] ;acces the value in the array to the corespnding row
			mov eax,[horizontal +4*eax];acces the value in the array to the corespnding column
			movzx ecx,[@@plyr]
			mov edx,1
			call drawer,eax,ebx,ecx
			ret
	endp drawMove

;draw a button 
;a button on screen is an action you can perform in the app
	proc makeButton
		ARG @@string:dword,@@color:word,@@row:byte,@@column:byte,@@smaller:byte 
		USES eax,ebx,ecx,edx,edi
	
			mov eax,[@@string]
			movzx edi,[@@color]
			movzx ebx,[@@row]
			movzx edx,[@@column]
			call printString,eax,edi,ebx,edx
			movzx eax,[buttonSize] ;size of the border of the button
			mov ecx,1
	
		@@adjustHeight:
			cmp ecx,ebx
			je @@adjusted
			add al,[buttonSize+1] ;outer edges of the button
			add ecx,1
			jmp @@adjustHeight
	
		@@adjusted:
			mov ebx,eax
			movzx eax,[buttonSize]
			mov ecx,1
	
		@@adjustWidth:
			cmp ecx,edx
			je @@mkButton
			add al,[buttonSize+1*1]
			add ecx,1
			jmp @@adjustWidth
	
		@@mkButton:
			movzx ecx,[@@smaller]
			movzx edx, [buttonSize+1*2] ;height of the button
			cmp ecx,1
			je @@inGame
			movzx ecx, [buttonSize+1*3] ;width of the button
			jmp @@draw
			
		@@inGame:
			movzx ecx, [buttonSize+1*4] ;width of the button
		
		@@draw:
			call drawRectangle,eax,ebx,ecx,edx,edi,0
			ret 
	endp makeButton

;display the current turn
	proc playerTurn
		ARG @@color:byte
		USES eax,ebx,ecx,edx
			movzx eax,[colors+2*2]
			mov edx,offset turn
			call printString,edx,eax,1,1 ;turn :
			movzx edx,[@@color] ;this is the color of the current player
			mov eax,[turnPiece] ;xpos
			mov ebx,[turnPiece+1*4];ypos
			mov ecx,[turnPiece+2*4];piece dimention
			call drawSprite,eax,ebx,offset fieldXS,ecx,ecx,edx,1;to indicate the current turn
			ret 
	endp playerTurn

;draw the change the turn
	proc changeTurn
		ARG @@color:byte
		USES edx
	
			movzx edx,[@@color] ;this is the color corresponding to the player who just made a move
			cmp dx,[colors+3*2];color of player1
			je @@p1
			movzx edx,[colors+3*2]
			jmp @@drawTurn

		@@p1:
			movzx edx,[colors+4*2];color of player2
		
		@@drawTurn:
			call playerTurn,edx
			ret
	endp changeTurn

;announce the winner
	proc announceInfo
		USES eax,ebx,ecx

			movzx eax,[colors];black
			movzx ebx,[statusGrid];status of the game
			call drawRectangle,0,0,100,200,eax,1 ;hide the info that is useless in this menu since you stay onto the same page
			movzx eax,[colors+2*2];white
			cmp ebx,3
			jl @@winnerFound
			mov ecx,offset draw	
			call printString,ecx,eax,1,1;draw!
			jmp @@end

		@@winnerFound:
			mov ecx,offset winner
			call printString,ecx,eax,1,1;winner:
		
		@@end:
			ret
	endp announceInfo

;draw a sprite onto the screen
	proc drawSprite
		ARG 	@@x:dword, @@y:dword, @@sprite:dword, @@w:dword, @@h:dword,@@indication:dword,@@mask:dword
		USES eax, edx, ecx, ebx, edi

			mov edi, VMEMADR	; Start addres

		; Calculate current pixel by
		; multiplying Y with screenwidth
		; and adding X 
			mov eax, [@@y]
			mov edx, SCRWIDTH
			mul edx
			add	eax, [@@x]	
			add edi, eax

			mov ebx, [@@sprite]
			mov ecx, [@@h]	; amount of Y pixels in sprite

		@@scanLineDraw: 
			push ecx
			mov ecx, [@@w]	; amount of X pixels in sprite


		@@spritePixelDrawer:
			mov al, [ebx]
			cmp al,00h ;black
			je @@fill_in
			cmp al,01h
			je @@backgroundFiller
			jmp @@contour

		@@backgroundFiller:
			push eax
			mov eax,[@@mask]
			cmp eax,0
			je @@background
			pop eax
			sub eax,1
			jmp @@contour

		@@fill_in:
			push eax
			mov eax,[@@indication]
			cmp eax,0
			je @@background
			cmp eax,14
			je @@player1
			pop eax
			add ax,[colors+8]
			jmp @@contour

		@@player1:
			pop eax
			add ax,[colors+6]
			jmp @@contour

		@@background:
			pop eax

		@@contour:
			stosb
			inc ebx
			loop @@spritePixelDrawer
		
			pop ecx
			add edi, SCRWIDTH
			sub edi, [@@w]
			loop @@scanLineDraw			
			ret
	endp drawSprite

;helper function to draw a sprite
	proc drawer
		arg @@xValue:dword, @@yValue:dword, @@indication:byte
		uses eax,ebx,ecx,edx

		movzx eax,[fieldType]
		mov edx, [sprites+eax*4]; the sprite you need 
		movzx ecx,[@@indication]
		mov eax, [@@xValue] ; in pixels
		mov ebx, [@@yValue] ;in pixels
		call drawSprite,eax,ebx,edx,[pieceDim],[pieceDim],ecx,0
		ret

	endp drawer

;helper to draw the logos
	proc drawLogoDistribution
		uses eax,ebx,ecx,edx,edi
		ARG @@position:byte,@@indication:byte

			movzx edi,[@@position]
			mov ecx,0
		
		@@loadLogo:
			mov eax, offset logos
			mov ebx,[eax+4*edi];the correct vector
			push ebx

		@@loadLogoValues:
			mov eax, offset logoPlace
			mov edx,[eax+4*ecx];the correct vector
			movzx ebx,[edx+edi]; the value you want
			cmp ecx,2
			je @@drawLogo
			add ecx,1
			push ebx
			jmp @@loadLogoValues
		
		@@duplicate:
			add eax,237
			pop ecx
			call drawSprite,eax,ebx,ecx,edx,edx,0,0
			jmp @@done

		@@drawLogo:
			mov edx,ebx ;dimentions where the last item computed
			pop ebx ;y value
			pop eax ; x value
			pop ecx; offset to sprite
			call drawSprite,eax,ebx,ecx,edx,edx,0,0
		
		@@checkForDuplicate:
			push ecx
			movzx ecx,[@@indication]
			cmp ecx,1
			je @@duplicate
			pop ecx
		
		@@done:
			ret
	endp drawLogoDistribution

DATASEG
;;Constants
	;these are the constants used for the graphics of the grid
	;they have been ordered as follows:
	;tickness of the grid,spacing between each column or row,the height,the width
		grid dd 30
	;this are the constants used to place the turn piece onto the gamescreen
	; they are stores as follow xpos,ypos,dimention
		turnPiece dd 10,30,42
	;the size off the piece that needs to be drawn
		pieceDim dd 20
	;these are the elments used to define a button
	;the represent the following: how long is each letter in the box,how wide is each letter in the box,height of the box, width off the box
		buttonSize         db 7,8,11,130,90
	;logo dimentions
		logoDimentions db 50,61,61,61
	;logo startpoint
		logoStartPoint db 15,15,5,5
	;logo begin y
 		logoYValue db 80,15,80,75

;;Vectors
	;sprites vector
		sprites dd offset fieldXS, offset fieldS, offset fieldM, offset fieldL, offset fieldXL, offset fieldXL, offset fieldXL

	;logos vector
		logos dd offset logo, offset statIMG, offset choiseIMG, offset playerIMG
	
	;logo placement
		logoPlace dd offset logoStartPoint, offset logoYValue, offset logoDimentions
	
END