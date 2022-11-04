IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "setup.inc"
include "mouse.inc"
include "draw.inc"
include "interact.inc"

CODESEG
;main
	proc main
	    	sti
	    	cld
	    	push ds
	    	pop	es
			call setVideoMode,13h
	    	call fillBackground,[colors];black
 			call mouse_install, offset mouseHandler
			call game
	endp main

Stack 100h
END main