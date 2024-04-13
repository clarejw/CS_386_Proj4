; bootloader.asm - A simple bootloader for loading a program into memory and executing it.

; Initialize memory address pointer and loop counter
loadLiteral 1024 r1 ; r1 points to memory address 1024 for storing the program
loadLiteral 0 r2    ; r2 acts as the loop counter

; Read the program length
read r3             ; Read high byte of program length
read r4             ; Read low byte of program length
shl r3 8 r3         ; Shift high byte left to form the high part of the word
or r3 r4 r5         ; r5 now holds the program length in words

; Compute the absolute address for end_read by adding the offset
loadLiteral 1024 r4 ; Load base address (1024) into r4
loadLiteral .end_read r6 ; Assuming this is how we get the offset for 'end_read'
add r4 r6 r4        ; r4 now has the absolute address of 'end_read'

start_loop:
    eq r2 r5 r6      ; Compare current count r2 with total length r5
    cmove r6 r4 r7   ; If r2 == r5, conditionally move the end_read address to r7 to jump there

    ; Read and store a word from input
    read r3          ; Read high byte of a word
    shl r3 24 r3     ; Position high byte
    read r4
    shl r4 16 r4
    or r3 r4 r3      ; Combine high and second byte
    read r4
    shl r4 8 r4
    or r3 r4 r3      ; Combine with third byte
    read r4
    or r3 r4 r3      ; r3 now contains the full word
    store r3 r1      ; Store the word in memory at address pointed by r1

    add r1 4 r1      ; Increment the memory address pointer
    add r2 1 r2      ; Increment the word count

    ; Calculate the address to continue the loop, considering the base offset
    loadLiteral 1024 r5       ; Load the base offset
    add r5 .start_loop r5              ; Adjust the loop start address by adding the base offset
    move r5 r7                ; Unconditionally set the instruction pointer to loop start

end_read:
    loadLiteral 1024 r7       ; Set the instruction pointer to start executing the program
    halt                      ; Optionally halt if something follows that should not execute
