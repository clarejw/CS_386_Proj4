; bootloader.asm - A simple bootloader for loading a program into memory and executing it.

;  expects the program's length (in words) to be provided
; in the input buffer in big-endian byte order
; followed by the program itself, also in big-endian byte order.

; read this data from the input device and store it in memory starting at address 1024, then jump to address 1024
; to execute the program.

; Set up a register to act as the memory address pointer
loadLiteral 1024 r1 ; r1 now points to memory address 1024

loadLiteral 0 r2 ; this will act like our loop to read how many words of the program has been read and stored

; read the program length 
read r3 ; read high byte of program length
read r4 ; read low byte of program length
shl r3 8 r3 ; shift high byte
or r3 r4 r5 ; r5 now contains the program length in words

; read the program data into memory starting at address 1024
read_program:
    eq r2 r5 r6 ; compare loop counter r2 with program length r5 -- check to see if we have exhausted the loop
    cmove r6 end_read r7 ; if we are at the end of the loop then we should move the end_read into r7

    ; read a word from input and store it at current memory address pointed by r1
    read r3 ; read high byte of word
    shl r3 24 r3 ; shift to correct position
    read r4 ; read second byte of word
    shl r4 16 r4 ; shift to correct position
    or r3 r4 r3 ; combine the two bytes

    ; this is the first half of the word done

    read r4 ; Read third byte of word
    shl r4 8 r4 ; shift to correct position
    or r3 r4 r3 ; combine
    read r4 ; read low byte of word
    or r3 r4 r3 ; r3 now contains the full word
    store r3 r1 ; store the word in memory at address in r1

    ; Increment memory address and loop counter
    add r1 4 r1 ; move to the next memory address
    add r2 1 r2 ; increment the loop counter
    jmp read_program ; loop back to read next word -- need to replace the jmp instruction with a proper way to restart the loop -- similar to line 89 in prime_embedded.asm

end_read:
; the program has been read into memory -- we can now execute it 
loadLiteral 1024 r7 ; put the pointer back to the start of the program

; end of bootloader.asm
halt 
