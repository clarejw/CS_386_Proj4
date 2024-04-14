; The job of the bootloader is:
; (1) Read the program from the input device and store it in memory starting at address 1,024
; (2) Execute the program by jumping to address 1,024

; r0 = has word
; r1 = counter
; r2 = program length
; r3 = used to loop
; r4 = boolean for cmove
; r5 = bounds check; stores next byte
; r6 = too_long/after_loop cmove
; r7 = iptr

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

after_loop:
    ; Set iptr to 1024
    loadLiteral 1024 r7 

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