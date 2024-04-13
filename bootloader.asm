; bootloader.asm - A simple bootloader for loading a program into memory and executing it.

; The bootloader expects the program's length (in words) to be provided
; in the input buffer in big-endian byte order, followed by the program
; itself, also in big-endian byte order.

; The bootloader's job is to read this data from the input device and
; store it in memory starting at address 1024, then jump to address 1024
; to execute the program.

; Set up a register to act as the memory address pointer
loadLiteral 1024 r1 ; r1 now points to memory address 1024

; Initialize r2 to 0 to act as the loop counter for reading program length and program data
loadLiteral 0 r2 ; this will act like our loop to read how many words of the program has been read and stored

; Read the program length 
read r3 ; Read high byte of program length
read r4 ; Read low byte of program length
shl r3 8 r3 ; Shift high byte
or r3 r4 r5 ; r5 now contains the program length in words

; Read the program data into memory starting at address 1024
read_program:
    eq r2 r5 r6 ; Compare loop counter r2 with program length r5
    cmove r6 .end_read r7 ; If they are equal, jump to .end_read

    ; Read a word from input and store it at current memory address pointed by r1
    read r3 ; Read high byte of word
    shl r3 24 r3 ; Shift to correct position
    read r4 ; Read second byte of word
    shl r4 16 r4 ; Shift to correct position
    or r3 r4 r3 ; Combine the two bytes
    read r4 ; Read third byte of word
    shl r4 8 r4 ; Shift to correct position
    or r3 r4 r3 ; Combine
    read r4 ; Read low byte of word
    or r3 r4 r3 ; r3 now contains the full word
    store r3 r1 ; Store the word in memory at address in r1

    ; Increment memory address and loop counter
    add r1 4 r1 ; Move to the next memory address
    add r2 1 r2 ; Increment the loop counter
    jmp read_program ; Loop back to read next word

.end_read:
; The program has been read into memory, now jump to the start of the program to execute it.
loadLiteral 1024 r7 ; Set the instruction pointer to the start of the program at memory address 1024

; End of bootloader.asm
halt ; Stop execution (should never be reached if program is executed correctly)
