IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "incFiles/setup.inc"
include "incFiles/mouse.inc"
include "incFiles/draw.inc"
include "incFiles/interact.inc"
include "incFiles/keys.inc"

CODESEG
;main
	proc main
	    	sti
	    	cld
	    	push ds
	    	pop	es
			call setVideoMode,13h
	    	call fillBackground,[colors];black
 			call mouse_install, offset buttonInteraction
			call __keyb_installKeyboardHandler
			call game
	endp main

Stack 100h
END main