; we need to initialize where the trap handler lives here in the asm code

; read in the instr of the program and jump to them

; kernel needs to respond to things that happened in user mode

; sets up the world and responds to events requested by the program


;loadLiteral .trap_handler r0  ; Assuming .trap_handler is an address defined elsewhere
; setTrapHandler r0            ; This instruction sets the trap handler to the address in r0
