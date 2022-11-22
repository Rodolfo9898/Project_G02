IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "keys.inc"
include "setup.inc"

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
			jmp @@noKey
		
		@@number:
			cmp ecx,02h; first number input in scacode this is number 1
			jge @@menus
			jmp @@noKey
		
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
            call numberInputGame,eax

		@@inGameMenu:
			mov al, [__keyb_keyboardState + 19h] ;letter p
            cmp al, 1	; if 1 = key pressed
            je @@pause
			;;;;;debugging
			mov al, [__keyb_keyboardState + 30h] ;letter b
            cmp al, 1	; if 1 = key pressed
            je @@exit 
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
			jmp @@noKey

		@@endGame:
			mov [currentMenu],9

		@@endGameMenu:
			mov al, [__keyb_keyboardState + 26h] ;letter l
            cmp al, 1	; if 1 = key pressed
            je @@main
			mov al, [__keyb_keyboardState + 20h] ;letter s
            cmp al, 1	; if 1 = key pressed
           	je @@statistics
			mov al, [__keyb_keyboardState + 12h] ;letter e
            cmp al, 1	; if 1 = key pressed
           	je @@choise
			mov al, [__keyb_keyboardState + 01h] ;escape
            cmp al, 1	; if 1 = key pressed
           	je @@exit
            jmp @@noKey

        @@exit: 
            mov [currentMenu],1

        @@noKey:
            ret

    endp keysMenuNavigation

DATASEG
	;;tobe coorected with bugfix
	; last valid input for the array
		validEntry db 08h ;number 7
	; move where
		movingSpace db 0


    ; scancode values				
	    keybscancodes db 29h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 	52h, 47h, 49h, 	45h, 35h, 00h, 4Ah
					  db 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh, 		53h, 4Fh, 51h, 	47h, 48h, 49h, 		1Ch, 4Eh
					  db 3Ah, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 2Bh,    						4Bh, 4Ch, 4Dh
					  db 2Ah, 00h, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h, 34h, 35h, 36h,  			 48h, 		4Fh, 50h, 51h,  1Ch
					  db 1Dh, 0h, 38h,  				39h,  				0h, 0h, 0h, 1Dh,  		4Bh, 50h, 4Dh,  52h, 53h
    ;originalkeyboard    
        originalKeyboardHandlerS	dw ?			; SELECTOR of original keyboard handler
        originalKeyboardHandlerO	dd ?			; OFFSET of original keyboard handler
    
    ;intearct with the keyboard
        __keyb_keyboardState		db 128 dup(?)	; state for all 128 keys
        __keyb_rawScanCode			db ?			; scan code of last pressed key
        __keyb_keysActive			db ?			; number of actively pressed keys

END