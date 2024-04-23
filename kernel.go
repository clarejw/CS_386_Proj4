package main

import "fmt"

// ************* Kernel support *************
//
// All of your CPU emulator changes for Assignment 2 will go in this file.

// The state kept by the CPU in order to implement kernel support.

//everytime you jump from user mode to kernel mode you need to go to the same address -- trapAddress -- callback to this address when an error occurs

// need to keep track of the time slicing operations such as the timer, instructions within a slice, etc
type kernelCpuState struct {
	kernelMode        bool   // "kernel" or "user"
	InterruptsEnabled bool   // If interrupts are enabled
	SyscallID         int    // Active syscall ID, -1 if none
	TrapHandlerAddr   word   // Address of the trap handler routine
	TimerTickCount    uint32 // Timer ticks count
	InstructionCount  uint32 // Count of instructions executed in the current slice
	TimerFires        uint32 // How many times the timer has fired (128 instruction slices completed)
}

// The initial kernel state when the CPU boots.
var initKernelCpuState = kernelCpuState{
	kernelMode:        true,
	InterruptsEnabled: true,
	SyscallID:         -1,
	TrapHandlerAddr:   word(0), // we just put 0 for now //use a label as the place to put the trap handler address -- this is done in the asm code
	TimerTickCount:    0,
	InstructionCount:  0,
	TimerFires:        0,
}

func switchToKernelTrap(c *cpu) {
	c.kernel.kernelMode = true // Switch CPU to kernel mode
	c.kernel.SyscallID = -1    // Indicate no active syscall
	// Set the trap handler address or a specific error handler address
	c.registers[7] = c.kernel.TrapHandlerAddr // Assuming r7 is used for the instruction pointer

	fmt.Println("Switched to kernel mode due to an illegal operation in user mode.")
}

// we still need a way to save where the current iptr was in r7 befoer we switch to the kernel trap or else we lost execution
// cannot just store in the kernelCPU state

// we may need to restore where the iptr was when coming out of the trap handeler too

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

// runs before an instruction is even decoded
// need to go back to checking time slice problem here
// all logic that does NOT care about whatever instruction is going to be ran goes here

func (k *kernelCpuState) preExecuteHook(c *cpu) (bool, error) {
	// TODO: Fill this in.

	k.InstructionCount++ // Increment instruction count with every CPU step

	// Check if the timer slice has completed
	if k.InstructionCount >= 128 {
		k.TimerFires++
		k.InstructionCount = 0
		fmt.Print("\nTimer fired!\n")
	}

	// get the current iptr
	iptr := c.registers[7] //ptr lives at r7
	if int(iptr) >= len(c.memory) {
		return true, fmt.Errorf("instr pointer out of bounds: %v", iptr) // halt and go back to kernel state

	}

	// the actual instruction at to be executed
	instr := c.memory[int(iptr)]

	_, err := c.instructions.decode(instr) // do i need the decodedInstr??? YES

	if err != nil {
		return true, fmt.Errorf("Trying to decode the instruction failed: %v", err) //this isto mitigate vulnerability at main.go 181  // halt and go back to kernel state
	}

	// need a way to also check it fails to execute an instruction too

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
	// everytime a priviledged instr happens -- we need the CPU to switch back to the kernel mode and then tell the kernel we switched back because of an illegal instr
	instrRead.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if c.kernel.kernelMode == false {
			switchToKernelTrap(c)
			return true, nil //should just be nil -- we do not want a program in userland to make an error to our CPU

		}
		return false, nil // Continue with the normal execution if not in user mode
	})

	// hook to deny write for user
	instrWrite.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if c.kernel.kernelMode == false {
			switchToKernelTrap(c)
			return true, nil
		}
		return false, nil // Continue with the normal execution if not in user mode
	})

	// hook to deny halt for user
	instrHalt.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if c.kernel.kernelMode == false {
			switchToKernelTrap(c)
			return true, nil
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
					return fmt.Errorf("this syscall is undefined %d", syscallNum) // we may not want to error here because a user program will hurt the CPU
				}
			},
			validate: nil,
		}

		// TODO: Add other instructions that can be used to implement a kernel.

		// a new CPU instruction used to set the trap handler address --- used like setTrapHandler registerNum
		// instr  --take this value from this register and store it into the trap handler fromt the cpu

		// assembly code should  call this instruction

		instrSetTrapHandler = &instr{
			name: "setTrapHandler",
			cb: func(c *cpu, args [3]byte) error {
				// args[0] is expected to be the register containing the trap handler address
				regIndex := args[0] // assuming the register index is passed directly
				if regIndex >= 8 {  // need to also make sure the register is not r7
					return fmt.Errorf("register index out of bounds")
				}

				// set the trap handler address in the CPU's kernel state
				c.kernel.TrapHandlerAddr = word(uint32(c.registers[regIndex])) // Convert word to uint32 if necessary
				return nil
			},
			validate: nil, // Add validation as necessary
		}
	)

	// Add kernel instructions to the instruction set.
	instructionSet.add(instrSyscall)
	instructionSet.add(instrSetTrapHandler)
}
