# Architecture

## WORDS:
    - 32-bit word-oriented CPU
        - Each memory address UNIQUELY addresses a single 32 bit word rather than a single byte
            - 32-bit bytes

## MEMORY:
    - Sequence of words which are addressed starting at 0
        - `load` and `store`


## REGISTERS:
    - The CPU has `8 registers` which are numbered `0 - 7`
    - `Register 7` is also the `instruction ptr` 
    - Each register stores a single word
    - `r0` through `r7`

## I/O
    - CPU is attached to one input and one output device
    - `read` and `write` a single byte directly from/to the I/O devices

    - The CPU is word-oriented so we need to convert between `32-bit words` and `8-bit bytes` in order to interact with the I/O devices 
        We only consider the `lease-significant 8 bits` of a word and discard the rest


    ### Example
        ```
            read r3 
            write r5
        ```
        - `read r3` reads one byte from the input device and overwrites the contents of r3 witha  `32-bit word` whose `lowest-order 8 bites are set to the value of the input`
            The remaining (higher order) bits are set to zero

        - `write r5` writes one byte to the output device.
            - The byte written is taken from the lowest-order 8 bits of `r5`

## Halting

    - The CPU can halt due to an explicit call to the `halt` instruction or because an instruction that puts the CPU in an illegal state is executed 
        - Trying to read from a memory address that is out of bounds
        - Trying to read from a mory address that is out of bounds
        - Instructions that refer to registers that do not exist

## Execution
    Order of execution:
        - Execute the "kernel pre-execute hook"
            - Can cause the CPU to halt
        - Reads the value of the `iptr`
        - Loads the word at address `iptr` in memory or halts if out of bounds
        - Decords this word as an instruction or halts
        - Increment the `iptr`
        - Executes the instruction 


## Instruction encoding
    - Encoded as a single word
        - One code byte followed by three argument bytes
    ```
    MSB                          LSB
    v                              v
    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    |------||------||------||------|
    code     a0      a1      a2

    ```

    - `code` identifies which instruction is encoded
    - `a0` `a1` and `a2` differ by instructions
        - not all instructions use all the arguments
            `halt` ignores all of these args

        - second args may contain either literals or register values
            - register vals: MSB is 0
            - literal vals: MSB is 1

## Instruction Reference

    ### Arithmetic Instructions
        - `<instr> <a0> <a1> <a2>`
            - Treat `<a0>` and `<a1>` as either registers or values
            - Stores results into `<a1>`

        ```
            Instruction	Operation (using Go syntax)
                add	    <a0> + <a1>
                sub 	<a0> - <a1>
                mul 	<a0> * <a1>
                div	    <a0> / <a1>
                shl	    <a0> << <a1>
                shr	    <a0> >> <a1>
                and	    <a0> & <a1>
                or	    <a0> | <a1>
                xor	    <a0> ^ <a1>
        ```

    ### Comparison Instructions

        ```
            Instruction	Operation (using Go syntax)
                gt	    <a0> > <a1>
                lt	    <a0> < <a1>
                eq	    <a0> == <a1>

        ```

    ### Others

        `MOVE`
            `move <a0> <a1>`
                - Copites the register or literal from <a10> to <a1>

        `CMOVE`
            ` cmove <a0> <a1> <a2> `
                If the register or liteal at <a0> is non zero then it copies the literal or register <a1> into <a2>

            This is the instruction used for `branch`

        `Load`
            `load <a0> <a1>
                Treats <a0> as a memory address and loads the word and stores it into <a1>

        `Store`
            `store <a0> <a1>`
                Treats the register or literal <a1> as a memory address and stores <a1> into it

        `Load Literal`
            `loadLiteral <a0> <a1>` deviates from noraml instruction encoding
                ```
                MSB                          LSB
                v                              v
                xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                |------||--------------||------|
                code         a0          a1
                ```

                stores the 16-bit value a0 in the least significatn 16 bits of the register a1

        `read`
            reads a byte from the input device and stores it in the least significant bits of register <a0>

        `write`
            writes the least-significant l8 bits of the register or literal <a0> to the output device
            - The cpu will block until the byte is written or halt if there is an error

        `debug`
            Causes the emulator to print the CPU's current state to stderr
            - If the register or literal <a0> is non-zero then the contents of the memory are also printed

        `unreachable`
            Works like an assertion that the instruction should never be executed

# Assembler 