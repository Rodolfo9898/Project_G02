;used procs outised the file
global printString:proc,\
       printScore:proc,\
       moveCursor:proc,\
       printChar:proc
       ;printchar and move cursor used for debbugging
       
;constants
global winnerCount:byte

;titles
global connect4:byte,\
       titleRules:byte,\
       statistics:byte,\
       beginner:byte,\
       paused:byte,\
       difficulty:byte,\
       enumeration:byte

;interations
global start:byte,\
       rule:byte,\
       stats:byte,\
       exit:byte,\
	player1:byte,\
       player2:byte,\
       movement:byte,\
       pauze:byte,\
       undo:byte,\
       restart:byte,\
       menu:byte

;game announcements  
global draw:byte,\
       turn:byte,\
       winner:byte

;extra text
global draws:byte,\
       p1:byte,\
       p2:byte,\
       credits:byte

;difficulties
global veasy:byte,\ 
       easy:byte,\
       standard:byte,\
       tricky:byte,\
       hard:byte,\
       extreme:byte,\
       square:byte       