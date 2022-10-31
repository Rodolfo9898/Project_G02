;used procs outised the file
global  __keyb_installKeyboardHandler:proc,\
        __keyb_uninstallKeyboardHandler:proc

;constants
global __keyb_rawScanCode:byte,\
       __keyb_keysActive:byte,\
       __keyb_keyboardState:byte:128