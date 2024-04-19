package main

import "fmt"

// ************* Kernel support *************
//
// All of your CPU emulator changes for Assignment 2 will go in this file.

// The state kept by the CPU in order to implement kernel support.
type kernelCpuState struct {
	// TODO: Fill this in.
	Mode              string // user or kernel mode
	InterruptsEnabled bool
	SyscallID         int
	TrapHandlerAddr   uint32
	TimerTickCount    uint32
}

// The initial kernel state when the CPU boots.
var initKernelCpuState = kernelCpuState{
	// TODO: Fill this in.
	Mode:              "kernel",
	InterruptsEnabled: false,
	SyscallID:         -1,     // no syscall
	TrapHandlerAddr:   0x0000, // need to figure out where the trap handler is at?
	TimerTickCount:    0,
}

// A hook which is executed at the beginning of each instruction step.
//
// This permits the kernel support subsystem to perform extra validation that is
// not part of the core CPU emulator functionality.
//
// If `preExecuteHook` returns an error, the CPU is considered to have entered
// an illegal state, and it halts.
//
// If `preExecuteHook` returns `true`, the instruction is "skipped": `cpu.step`
// will immediately return without any further execution.
func (k *kernelCpuState) preExecuteHook(c *cpu) (bool, error) {
	// TODO: Fill this in.

	// get the current iptr
	iptr := c.registers[7]
	if int(iptr) >= len(c.memory) {
		return false, fmt.Errorf("instr pointer out of bounds: %v", iptr)

	}

	// the actual instruction at to be executed
	instr := c.memory[int(iptr)]

	_, err := c.instructions.decode(instr) // do i need the decodedInstr???

	if err != nil {
		return false, fmt.Errorf("Trying to decode the instruction failed: %v", err)
	}

	return false, nil
}

// Initialize kernel support.
//
// (In Go, any function named `init` automatically runs before `main`.)
func init() {
	if false {
		// This is an example of adding a hook to an instruction. You probably
		// don't actually want to add a hook to the `add` instruction.
		instrAdd.addHook(func(c *cpu, args [3]uint8) (bool, error) {
			a0 := resolveArg(c, args[0])
			a1 := resolveArg(c, args[1])
			if a0 == a1 {
				// Adding a number to itself? That seems like a weird thing to
				// do. Best just to skip it...
				return true, nil
			}

			if args[2] == 7 {
				// This instruction is trying to write to the instruction
				// pointer. That sounds dangerous!
				return false, fmt.Errorf("You're not allowed to ever change the instruction pointer. No loops for you!")
			}

			return false, nil
		})
	}

	// TODO: Add hooks to other existing instructions to implement kernel
	// support.

	// hook to deny read for user
	instrRead.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if c.kernel.Mode == "user" {
			return false, fmt.Errorf("privileged instruction 'read' attempted in user mode")
		}
		return false, nil // Continue with the normal execution if not in user mode
	})

	// hook to deny write for user
	instrWrite.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if c.kernel.Mode == "user" {
			return false, fmt.Errorf("privileged instruction 'write' attempted in user mode")
		}
		return false, nil // Continue with the normal execution if not in user mode
	})

	// hook to deny halt for user
	instrHalt.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if c.kernel.Mode == "user" {
			return false, fmt.Errorf("privileged instruction 'halt' attempted in user mode")
		}
		return false, nil // Continue with the normal execution if not in user mode
	})

	var (
		// syscall <code>
		//
		// Executes a syscall. The first argument is a literal which identifies
		// what kernel functionality is requested:
		// - 0/read:  Read a byte from the input device and store it in the
		//            lowest byte of r6 (and set the other bytes of r6 to 0)
		// - 1/write: Write the lowest byte of r6 to the output device
		// - 2/exit:  The program exits; print "Program has exited" and halt the
		// 	 		  machine.
		//
		// You may add new syscall codes if you want, but you may not modify
		// these existing codes, as `prime.asm` assumes that they are supported.
		instrSyscall = &instr{
			name: "syscall",
			cb: func(c *cpu, args [3]byte) error {
				// TODO: Fill this in.

				syscallNum := args[0]
				switch syscallNum {
				case 0: // read
					// read byte
					// set the lowest byte of r6 to what is read
					// set all other bytes to 0
					readArgs := [3]byte{6, 0, 0} // putting args[0] to be 6 to correlate to r6
					return instrRead.cb(c, readArgs)

				case 1: // write
					// write the lowest byte of r6 to the output devide
					writeArgs := [3]byte{6, 0, 0} // putting args[0] to be 6 to correlate to r6
					return instrWrite.cb(c, writeArgs)

				case 2: // exit
					fmt.Println("Program has exited")
					// halt the cpu
					return instrHalt.cb(c, [3]byte{}) // just call halt
				default:
					return fmt.Errorf("this syscall is undefined %d", syscallNum)
				}
			},
			validate: nil,
		}

		// TODO: Add other instructions that can be used to implement a kernel.
	)

	// Add kernel instructions to the instruction set.
	instructionSet.add(instrSyscall)
}
