IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "incFiles/setup.inc"
include "incFiles/keys.inc"

CODESEG
; Installs the custom keyboard handler
    PROC __keyb_installKeyboardHandler
        push	ebp
        mov		ebp, esp

	    push	eax
	    push	ebx
    	push	ecx
	    push	edx
    	push	edi
    	push	ds
    	push	es
    
	    ; clear state buffer and the two state bytes
    	cld
	    mov		ecx, (128 / 2) + 1
	    mov		edi, offset __keyb_keyboardState
	    xor		eax, eax
	    rep		stosw
	
    	; store current handler
    	push	es			
    	mov		eax, 3509h			; get current interrupt handler 09h
    	int		21h					; in ES:EBX
    	mov		[originalKeyboardHandlerS], es	; store SELECTOR
    	mov		[originalKeyboardHandlerO], ebx	; store OFFSET
    	pop		es
    
    	; set new handler
    	push	ds
    	mov		ax, cs
    	mov		ds, ax
    	mov		edx, offset keyboardHandler			; new OFFSET
    	mov		eax, 2509h							; set custom interrupt handler 09h
	    int		21h									; uses DS:EDX
    	pop		ds
    
    	pop		es
    	pop		ds
    	pop		edi
    	pop		edx
    	pop		ecx
    	pop		ebx
    	pop		eax	
    
        mov		esp, ebp
        pop		ebp
        ret

    ENDP __keyb_installKeyboardHandler

; Restores the original keyboard handler
    PROC __keyb_uninstallKeyboardHandler
        push	ebp
        mov		ebp, esp

    	push	eax
    	push	edx
    	push	ds
		
    	mov		edx, [originalKeyboardHandlerO]		; retrieve OFFSET
    	mov		ds, [originalKeyboardHandlerS]		; retrieve SELECTOR
	    mov		eax, 2509h							; set original interrupt handler 09h
    	int		21h									; uses DS:EDX
	
    	pop		ds
    	pop		edx
    	pop		eax
	
        mov		esp, ebp
        pop		ebp
        ret

    ENDP __keyb_uninstallKeyboardHandler

; Keyboard handler (Interrupt function, DO NOT CALL MANUALLY!)
    PROC keyboardHandler
	    KEY_BUFFER	EQU 60h			; the port of the keyboard buffer
	    KEY_CONTROL	EQU 61h			; the port of the keyboard controller
	    PIC_PORT	EQU 20h			; the port of the peripheral

	    push	eax
	    push	ebx
	    push	esi
	    push	ds
	
	    ; setup DS for access to data variables
	    mov		ax, _DATA
    	mov		ds, ax
	
	    ; handle the keyboard input
    	sti							; re-enable CPU interrupts
    	in		al, KEY_BUFFER		; get the key that was pressed from the keyboard
    	mov		bl, al				; store scan code for later use
    	mov		[__keyb_rawScanCode], al	; store the key in global variable
    	in		al, KEY_CONTROL		; set the control register to reflect key was read
    	or		al, 82h				; set the proper bits to reset the keyboard flip flop
    	out		KEY_CONTROL, al		; send the new data back to the control register
    	and		al, 7fh				; mask off high bit
    	out		KEY_CONTROL, al		; complete the reset
    	mov		al, 20h				; reset command
    	out		PIC_PORT, al		; tell PIC to re-enable interrupts

    	; process the retrieved scan code and update __keyboardState and __keysActive
    	; scan codes of 128 or larger are key release codes
    	mov		al, bl				; put scan code in al
    	shl		ax, 1				; bit 7 is now bit 0 in ah
    	not		ah
    	and		ah, 1				; ah now contains 0 if key released, and 1 if key pressed
    	shr		al, 1				; al now contains the actual scan code ([0;127])
    	xor		ebx, ebx	
    	mov		bl, al				; bl now contains the actual scan code ([0;127])
    	lea		esi, [__keyb_keyboardState + ebx]	; load address of key relative to __keyboardState in ebx
    	mov		al, [esi]			; load the keyboard state of the scan code in al
    	; al = tracked state (0 or 1) of pressed key (the value in memory)
    	; ah = physical state (0 or 1) of pressed key
    	neg		al
    	add		al, ah				; al contains -1, 0 or +1 (-1 on key release, 0 on no change and +1 on key press)
    	add		[__keyb_keysActive], al	; update __keysActive counter
    	mov		al, ah
    	mov		[esi], al			; update tracked state
	
    	pop		ds
    	pop		esi
	    pop		ebx
    	pop		eax
	
    	iretd

    ENDP keyboardHandler

;delay the keyboard read
;source http://vitaly_filatov.tripod.com/ng/asm/asm_026.13.html
	proc delay
		USES eax,ecx,edx
			MOV     CX, 05H
			MOV     DX, 100H
			MOV     AH, 86H
			INT     15H
			ret
	endp delay

;handle the number input in menus
    proc numbersInput
        ARG @@keyInput:byte
        USES eax,ebx,ecx
			movzx ecx,[@@keyInput]
			cmp ecx,0bh ;last valid number key in scancodes this is number 0
			jle @@number
			jmp short @@noKey
		
		@@number:
			cmp ecx,02h; first number input in scacode this is number 1
			jge @@menus
			jmp short @@noKey
		
		@@menus:
			movzx ebx,[currentMenu]
			cmp ebx,4
			je @@difficulty
			cmp ebx,5
			je @@choise
			jmp @@noKey
		
		@@difficulty:
			cmp ecx,08h ;number 7
			jle @@interaction
			jmp @@noKey
		
		@@choise:
			cmp ecx,03h ;number 2
			jle @@interaction
			jmp @@noKey


		@@interaction:
			mov al, [__keyb_keyboardState + ecx] ; number pressed down
           	cmp al, 1	; if 1 = key pressed
			je @@change
			jmp @@noKey

		@@change:
			cmp ebx,4
			je @@changeDifficulty
			cmp ebx,5
			je @@changeChoise
			jmp @@noKey

		@@changeDifficulty:
			sub ecx,02h ;get the actual value from the key you pressed
			mov [fieldType],cl
			mov [currentMenu],5
			jmp @@delay

		@@changeChoise:
			add ecx,01h; you need to access in the arrar colors pos 3 or 4 so you add 1 after the choise is done becuase of the scancode values 02h and 03h
			mov [playerColor],cl
			mov [currentMenu],6
		
		@@delay:
			call delay
		
		@@noKey:
			ret

    endp numbersInput

;handle number input in game
	proc numberInputGame
		ARG @@keyInput:byte
        USES eax,ecx

			movzx ecx,[@@keyInput]
			cmp cl,[validEntry] ;last valid number key in scancodes this is number 0
			jle @@number
			jmp @@noKey

		@@number:
			cmp ecx,02h; first number input in scacode this is number 1
			jge @@interaction
			jmp @@noKey

		@@interaction:
			mov al, [__keyb_keyboardState + ecx] ; number pressed down
          	cmp al, 1	; if 1 = key pressed
			je @@move
			jmp @@noKey
		
		@@move:
			sub ecx,02h ;get the actual value from the key you presed
			mov [movingSpace],cl
			mov [currentMenu],8
			mov [moveDone],1
			call delay
		
		@@noKey:
			ret

	endp numberInputGame

;handle the menuNavigation
    proc keysMenuNavigation
        USES eax,ebx
			movzx ebx,[currentMenu]

            cmp ebx,0
            je @@main
            cmp ebx,1
            je @@exit
            cmp ebx,2
            je @@rules
            cmp ebx,3
            je @@statistics
            cmp ebx,4
            je @@difficulty
			cmp ebx,5
			je @@choise
			cmp ebx,6
			je @@inGame
			cmp ebx,7
			je @@pause
			cmp ebx,8
			je @@move
			cmp ebx,9
			je @@endGame
			cmp ebx,10
			je @@undo
            jmp @@noKey

        @@main:
			cmp ebx,5
			je @@difficulty
            mov [currentMenu],0

        @@mainMenu:
            mov al, [__keyb_keyboardState + 01h] ;escape
            cmp al, 1	; if 1 = key pressed
            je @@exit
            mov al, [__keyb_keyboardState + 13h] ; letter r
            cmp al, 1	; if 1 = key pressed
            je @@rules
            mov al, [__keyb_keyboardState + 1fh] ; letter s
            cmp al, 1	; if 1 = key pressed
            je @@statistics
            mov al, [__keyb_keyboardState + 39h] ; spacebar
            cmp al, 1	; if 1 = key pressed
			je @@difficulty
            jmp @@noKey

        @@rules:
            mov [currentMenu],2
            jmp @@staticMenu
        
        @@statistics:
            mov [currentMenu],3
            jmp @@staticMenu

        @@difficulty:
            mov[currentMenu],4
			jmp @@numberInteractionsMenu
		
		@@choise:
			mov[currentMenu],5
			
        @@numberInteractionsMenu:
			movzx eax,[__keyb_rawScanCode]
            call numbersInput,eax
			jmp @@staticMenu
					
        @@staticMenu:
            mov al, [__keyb_keyboardState + 30h] ;letter b
            cmp al, 1	; if 1 = key pressed
            je @@main
            jmp @@noKey
        
		@@inGame:
			mov [currentMenu],6
			
		@@gameplay:
			movzx eax,[__keyb_rawScanCode]
			;;bug found disco mode activation with numbers 3 and 7
            call numberInputGame,eax

		@@inGameMenu:
			mov al, [__keyb_keyboardState + 19h] ;letter p
            cmp al, 1	; if 1 = key pressed
            je @@pause
			mov al, [__keyb_keyboardState + 20h] ;letter d
            cmp al, 1	; if 1 = key pressed
            je @@undo
            jmp @@noKey

		@@pause:
			mov [currentMenu],7
		
		@@pauseMenu:
			mov al, [__keyb_keyboardState + 16h] ;letter u
            cmp al, 1	; if 1 = key pressed
            je @@inGame
            jmp @@noKey

		@@move:
			mov [currentMenu],8

		@@moving:
			cmp[statusGrid],0
			jg @@endGame 
			cmp [moveDone],1
			je @@moveMade
			jmp @@noKey

		@@moveMade:
			mov [currentMenu],6
			mov [moveDone],0
			mov [__keyb_rawScanCode], 0ch; numberinput outside the hexcode to for numbers ,symbol ")"
			call delay
			jmp short @@noKey

		@@endGame:
			mov [currentMenu],9

		@@endGameMenu:
			mov al, [__keyb_keyboardState + 26h] ;letter l
            cmp al, 1	; if 1 = key pressed
            je @@main
			mov al, [__keyb_keyboardState + 1fh] ;letter s
            cmp al, 1	; if 1 = key pressed
           	je @@statistics
			mov al, [__keyb_keyboardState + 12h] ;letter e
            cmp al, 1	; if 1 = key pressed
           	je @@choise
			mov al, [__keyb_keyboardState + 01h] ;escape
            cmp al, 1	; if 1 = key pressed
           	je @@exit
            jmp @@noKey
		
		@@undo:
			mov[currentMenu],10
		
		@@undoning:
			mov [moveDone],1
			cmp [statusGrid+1],1
			je @@undone
			jmp @@noKey
		
		@@undone:
			mov [statusGrid+1],1
			mov [currentMenu],6
			call delay
			call delay
			mov [moveDone],0
			jmp @@noKey

        @@exit: 
            mov [currentMenu],1

        @@noKey:
            ret

    endp keysMenuNavigation

DATASEG
    ;originalkeyboard    
        originalKeyboardHandlerS	dw ?			; SELECTOR of original keyboard handler
        originalKeyboardHandlerO	dd ?			; OFFSET of original keyboard handler
    
    ;intearct with the keyboard
        __keyb_keyboardState		db 128 dup(?)	; state for all 128 keys
        __keyb_rawScanCode			db ?			; scan code of last pressed key
        __keyb_keysActive			db ?			; number of actively pressed keys

END