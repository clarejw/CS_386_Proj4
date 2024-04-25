; read in the instr of the program and jump to them

; kernel needs to respond to things that happened in user mode

; sets up the world and responds to events requested by the program
    ; How do I know what is requested by the program?

; [TODO] Need a way to switch to user mode before jumping to program
; [TODO] Making setTrapHandler privileged
; [TODO] Does unreachable need to be made privileged? Is it already privileged?

; -------------------------------------------------------------------------------------------
; -------------------------------------------------------------------------------------------
; -------------------------------------------------------------------------------------------

; 1. Boot like bootloader?
; 2. Instead of just jumping to the program, babysit it?

; The job of the kernal is:
; (1) Read the program from the input device and store it in memory starting at address 1,024
    ; - Nothing changes about how the CPU implements booting compared to Assignment 1. The 
    ; CPU still loads your kernel at address 0. It still provides the program to be executed 
    ; on the input device. Etc.
; (2) Execute the program by jumping to address 1,024, treating it as a user-land program
    ; - What changes is what happens once your code is already executing. In particular, 
    ; instead of just jumping to the program you've loaded, you must treat it as a 
    ; user-land program. You must set up the world so that the program is "sandboxed" and can 
    ; only interact with the outside world (reading from and writing to the input and output 
    ; devices) by asking the kernel to do so on its behalf. You must also prevent the program 
    ; from running any longer than it's allowed to (more on this below).

; r0 = has word
; r1 = counter
; r2 = program length
; r3 = used to loop
; r4 = boolean for cmove
; r5 = bounds check; stores next byte
; r6 = too_long/after_loop cmove
; r7 = iptr

    ; The first thing we do before anything else is make sure that the trapHandler is set
    loadLiteral .trap_handler r0  
    setTrapHandler r0            

    ; Read first two bytes, which represent the length of the program 
    read r0
    read r1

    ; Must be less than 1024. We bounds check here to see if program is too long
    add r0 r1 r2

    ; If r2 > 1024 (words), the program is too long
    loadLiteral 1024 r1
    gt r2 r1 r5
    loadLiteral 0 r6
    add r6 .too_long r6 ; Store 0 + .too_long in r6
    loadLiteral 0 r3
    add r3 .loop r3 ; Store 0 + .loop in r3

    add r2 r1 r2 ; Set r2 to last valid memory address 

    cmove r5 r6 r3       ; If r2 > 1024, jump to 1024 + .too_long, else start .loop

; This loop loads program into memory
loop:
    read r0 

    read r5 ; second byte
    shl r0 8 r0
    add r0 r5 r0

    read r5 ; third byte
    shl r0 8 r0
    add r0 r5 r0

    read r5 ; fourth byte
    shl r0 8 r0
    add r0 r5 r0

    ; Store in the next available memory slot, 1024 + r1 (number of words we've read)
    store r0 r1 

    ; Increment number of words we've read
    add r1 1 r1
    
    eq r1 r2 r4 ; r4 <- r1 > r2 (aka, r4 <- words logged in memory greater than program length (in words)) --> this is wrong
    loadLiteral 0 r6
    add r6 .after_loop r6 ; Store 0 + .after_loop in r6
    cmove r4 r6 r7        ; If r1 > r2, break out of the loop --> I don't really know what r7 is here

    ; This restarts/continues the loop
    loadLiteral 0 r3
    add r3 .loop r3      ; Store 0 + .loop in r3
    move r3 r7           ; Continue the loop --> I don't know what r7 is here

; after_loop 
    ; Instead of just jumping to the program you've loaded, you must treat it as a 
    ; user-land program. 

    ; You must set up the world so that the program is "sandboxed" and can only interact with 
    ; the outside world (reading from and writing to the input and output devices) by asking the 
    ; kernel to do so on its behalf. You must also prevent the program from running any longer 
    ; than it's allowed to (more on this below).
    ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ; This means that you will need a single sequence of instructions that executes on every trap, 
    ; determines the cause of the trap (timer fire, syscall, etc), and implements the appropriate 
    ; behavior based on the cause.
after_loop:
    ; Switch to user mode? At the same time as jumping to start of program?
    ; Set iptr to 1024 --> this jumps straight to the program
    write '@'
    loadLiteral 1024 r7 

trap_handler:
    ; What does trap_handler do?
    ; How do I determine the cause of the trap?

    ; EXITING:
    ; The program may exit by executing the instruction syscall 2. When this happens, the kernel 
    ; prints \nProgram has exited\nTimer fired XXXXXXXX times\n to the output device and then halts 
    ; the CPU.

    ; MEMORY BOUNDS:
    ; If the program attempts to access memory which is not in the address range [1024, 2048), the 
    ; kernel must print \nOut of bounds memory access!\nTimer fired XXXXXXXX times\n to the output 
    ; device and halt the CPU.

    ; PRIVILEGED INSTRUCTIONS:
    ; Some instructions are considered "privileged." If the program executes any privileged 
    ; instruction, the kernel must print \nIllegal instruction!\nTimer fired XXXXXXXX times\n to 
    ; the output device and halt the CPU.
    ; The following instructions are privileged:
        ; read
        ; write
        ; halt
        ; unreachable
        ; setTrapHandler !!!!

    ; Am I in charge of time slice stuff??

        ; "\nTrap!\n"
        write 10  ; Newline character
        write 'T'
        write 'r'
        write 'a'
        write 'p'
        write '!'
        write 10  ; Newline character
        halt


too_long:
    ; "Program is too long!\n"
    write 'P'
    write 'r'
    write 'o'
    write 'g'
    write 'r'
    write 'a'
    write 'm'
    write 32  ; Space character
    write 'i'
    write 's'
    write 32  ; Space character
    write 't'
    write 'o'
    write 'o'
    write 32  ; Space character
    write 'l'
    write 'o'
    write 'n'
    write 'g'
    write '!'
    write 10  ; Newline character
    halt

