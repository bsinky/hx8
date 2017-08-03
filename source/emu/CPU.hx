package emu;

import sys.io.File;
import haxe.io.Bytes;

/**
 * ...
 * @author Benjamin Sinkula
 */
class CPU
{
	public var drawFlag:Bool;		// Whether to draw to screen this cycle
	public var isWaitingForKey:Bool;
	public var screen:Display;

	private var opcode:Int;			// Current opcode to execute
	private var memory:Array<Int>;	// Chip 8 total memory
	private var V:Array<Int>;		// CPU registers
	private var I:Int;				// Index register
	private var pc:Int;				// Program counter
	private var delay_timer:Int;	// Delay timer register
	private var sound_timer:Int;	// Sound timer register
	private var stack:Array<Int>;	// Stack for pc before subroutine calls
	private var sp:Int;				// Stack pointer
	private var key:Array<Bool>;	// HEX based keypad for input
	private var isRunning:Bool;	    // Whether the CPU is running
	private var nextKeyRegister:Int; // Register to store next key press in while waiting for a key

	private var chip8_fontset =
	[
		0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
		0x20, 0x60, 0x20, 0x20, 0x70, // 1
		0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
		0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
		0x90, 0x90, 0xF0, 0x10, 0x10, // 4
		0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
		0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
		0xF0, 0x10, 0x20, 0x40, 0x40, // 7
		0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
		0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
		0xF0, 0x90, 0xF0, 0x90, 0x90, // A
		0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
		0xF0, 0x80, 0x80, 0x80, 0xF0, // C
		0xE0, 0x90, 0x90, 0x90, 0xE0, // D
		0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
		0xF0, 0x80, 0xF0, 0x80, 0x80  // F
	];
	
	static inline public var WORD:Int = 2;		// Word size
	static inline public var REG_MAX:Int = 255;	// Max value a register can hold
	static inline public var MEMORY_SIZE = 0x1000; // 4096 or 0x1000 memory size
	
	public function new() 
	{
		memory = new Array<Int>();
		clearMemory();
		V = new Array<Int>();
		clearRegisters();
		screen = new Display();
		key = new Array<Bool>();
		initialize();
	}
	
	public function initialize():Void 
	{
		pc = 0x200;					// Program counter starts at 0x200
		opcode = 0;					// Reset opcode
		I = 0;						// Reset index register
		sp = 0;						// Reset stack pointer
		
		// Clear Display
		screen.clear();
		// Clear Stack
		stack = new Array<Int>();
		// Clear Registers V0-VF
		clearRegisters();
		// Clear memory
		clearMemory();
		
		// Load fontset
		for(i in 0...80)
		{
			memory[i] = chip8_fontset[i];
		}
		
		// Reset timers
		sound_timer = 0;
		delay_timer = 0;
	}

	public function loadGameFromPath(gamePath:String):Void
	{
		loadGame(File.getBytes(gamePath));
	}

	public function loadGame(game:Bytes):Void
	{
		// Load program into memory a byte at a time
		for(i in 0...game.length)
		{	
			memory[i + 0x200] = game.get(i);
		}
	}

	private function clearRegisters():Void
	{
		for (i in 0...0xf + 1)
		{
			V[i] = 0;
		}
	}

	private function clearMemory():Void
	{
		for (i in 0...MEMORY_SIZE)
		{
			memory[i] = 0;
		}
	}

	public function start():Void
	{
		Util.cpuLog("CPU starting");
		isRunning = true;
	}

	public function stop():Void
	{
		Util.cpuLog("CPU stopping");
		isRunning = false;
	}

	public function waitForKey(): Void
	{
		Util.cpuLog("CPU waiting for key...");
		stop();
		isWaitingForKey = true;
	}

	public function setKeys(keyStates:Map<Int, Bool>): Void
	{
		for (keyCode in keyStates.keys())
		{
			key[keyCode] = keyStates[keyCode];
		}

		Util.keysLog(keyStates);
	}

	public function setKey(key:Int): Void
	{
		isWaitingForKey = false;
		V[nextKeyRegister] = key;
	}
	
	public function cycle():Void 
	{
		if (!isRunning)
		{
			return;
		}

		Util.cpuLog("cycle start...");
		Util.cpuLog('program counter: ${pc} (0x${StringTools.hex(pc)})');
		Util.cpuLog('stack pointer: ${sp}');

		// Fetch opcode
		opcode = memory[pc] << 8 | memory[pc + 1];

		var x = (opcode & 0x0F00) >> 8;
		var y = (opcode & 0x00F0) >> 4;

		Util.cpuLog('X: ${x} (0x${StringTools.hex(x)}), Y: ${y} (0x${StringTools.hex(y)})');

		pc += 2;
		
		// Decode opcode
		// Examine only the first digit
		switch(opcode & 0xF000)
		{				
			case 0x0000:
				switch(opcode & 0x000F)
				{
					case 0x0000:
						Util.cpuLog("00E0: Clear screen");
						screen.clear();
						
					case 0x000E:
						Util.cpuLog("00EE: Returns from subroutine");
						sp--;
						pc = stack[sp];
					default:
						Util.cpuLog("Unknown opcode: " + StringTools.hex(opcode));
				}
				
			case 0x1000:
				Util.cpuLog('1NNN: Jump to address NNN (NNN: ${opcode & 0x0FFF})');
				pc = opcode & 0x0FFF;
				
			case 0x2000:
				Util.cpuLog('2NNN: Calls subroutine at NNN (NNN: ${opcode & 0x0FFF})');
				stack[sp] = pc;
				sp++;
				pc = opcode & 0x0FFF;
				
			case 0x3000:
				Util.cpuLog('3XNN: Skip if VX equals constant NN (NN: ${opcode & 0x00FF})');
				if (V[x] == (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				
			case 0x4000:
				Util.cpuLog('4XNN: Skip if VX does not equal NN (NN: ${opcode & 0x00FF})');
				if (V[x] != (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				
			case 0x5000:
				Util.cpuLog("5XY0: Skip if VX equals VY");
				if (V[x] == V[y])
					pc += 2;	// Skip next opcode
				
			case 0x6000:
				Util.cpuLog('6XNN: Store NN in register VX (NN: ${opcode & 0x00FF})');
				V[x] = opcode & 0x00FF;
				
			case 0x7000:
				Util.cpuLog('7XNN: Add NN to VX.  No carry (NN: ${opcode & 0x00FF})');
				V[x] += opcode & 0x00FF;
				// Constrain the value to 8 bits in length (no carry)
				if (V[x] > REG_MAX)
				{
					V[x] -= REG_MAX + 1; // +1 for off-by-one
				}
				
			case 0x8000:
				switch (opcode & 0x000F) 
				{
					case 0x0000:
						Util.cpuLog("8XY0: Move VY into VX");
						V[x] = V[y];
						
					case 0x0001:
						Util.cpuLog("8XY1: bitwise OR of VY and VX, store in VX");
						V[x] = V[x] | V[y];
						
					case 0x0002:
						Util.cpuLog("8XY2: bitwise AND of VY and VX, store in VX");
						V[x] = V[x] & V[y];
						
					case 0x0003:
						Util.cpuLog("8XY3: bitwise XOR of VY and VX, store in VX");
						V[x] = V[x] ^ V[y];
						
					case 0x0004:
						Util.cpuLog("8XY4: Add value of VY to VX, set VF equal to carry");
						var carryFlag = 0;
						V[x] += V[y];

						if (V[x] > 255)
						{
							V[x] -= 256;
							carryFlag = 1;
						}
						V[0xF] = carryFlag;
					
					case 0x0005:
						Util.cpuLog("8XY5: subtract VY from VX, borrow flag in VF");
						var borrowFlag = 0;
						if (V[x] > V[y])
						{
							borrowFlag = 1;
						}
						V[x] -= V[y];
						V[0xF] = borrowFlag;

						if (V[x] < 0)
						{
							V[x] += 256;
						}
							
						
					case 0x0006:
						Util.cpuLog("8X06: shift VX right, bit 0 goes to VF");
						V[0xF] = V[x] & 0x1;
						V[x] = V[x] >> 1;
					
					case 0x0007:
						Util.cpuLog("8XY7: subtract VX from VY, store in VX.  1 in VF if borrows.");
						var borrowFlag = 0;
						if (V[y] > V[x])
						{
							borrowFlag = 1;		// borrow flag
						}

						V[x] = V[y] - V[x];
						V[0xF] = borrowFlag;

						if (V[x] < 0)
						{
							V[x] += 256;
						}
						
					case 0x000E:
						Util.cpuLog("8X0E: shift VX left 1 bit, 7th bit goes in VF");
						// AND with 0x80 to get leftmost bit of VX
						V[0xF] = V[x] & 0x80;
						// Left shift and AND to get rid of any bits outside of the 8 bits the register is supposed to be
						V[x] = (V[x] << 1) & 0xFF;
				}
				
			case 0x9000:
				Util.cpuLog("9XY0: skip if VX != VY");
				if (V[x] != V[y])
					pc += 2;
				
			case 0xA000:
				Util.cpuLog('ANNN: Sets I to address NNN (NNN: ${opcode & 0x0FFF})');
				I = opcode & 0x0FFF;
				
			case 0xB000:
				Util.cpuLog("BNNN: Jump to address NNN + V0");
				pc = opcode & (0x0FFF + V[0x0]);
				
			case 0xC000:
				Util.cpuLog('CXNN: Set VX to a random number less than or equal to NN (NN: ${opcode & 0x00FF})');
				V[x] = Math.round(Math.random() * (opcode & 0x00FF)) & 0xFF;
				
			case 0xD000:
				Util.cpuLog('DXYN: draw to screen (N: ${opcode & 0x000F})');
				V[0xF] = 0;

                var height = opcode & 0x000F;
                var registerX = V[x];
            	var registerY = V[y];
				var spr = 0;

				for (screenY in 0...height)
				{
					spr = memory[I + screenY];
					for (x in 0...8) {
						if ((spr & 0x80) > 0)
						{
							if (screen.setPixel(registerX + x, registerY + y))
							{
								V[0xF] = 1;
							}
						}
						spr <<= 1;
					}
				}
				drawFlag = true;				
				
			case 0xE000:
				switch(opcode & 0x00F0)
				{
					case 0x0090:
						Util.cpuLog("EX9E: skip if key noted by code in VX is pressed");
						if (key[V[x]])
							pc += 2;
						
					case 0x00a0:
						Util.cpuLog("EXA1: skip if key noted by code in VX is NOT pressed");
						if (!key[V[x]])
							pc += 2;
				}
				
			case 0xF000:
				switch(opcode & 0x00F0)
				{
					case 0x0000:
						switch(opcode & 0x000F)
						{
							case 0x0007:
								Util.cpuLog("FX07");
								V[x] = delay_timer;
								
							case 0x000A:
								Util.cpuLog("FX0A");
								nextKeyRegister = x;
								waitForKey();
						}
					case 0x0010:
						switch(opcode & 0x000F)
						{
							case 0x0005:
								Util.cpuLog("FX15: Set delay timer to VX");
								delay_timer = V[x];
								
							case 0x0008:
								Util.cpuLog("FX18: Set sound timer to VX");
								sound_timer = V[x];
								
							case 0x000E:
								Util.cpuLog("FX1E: Set I equal to I + VX");
								I += V[x];
						}
						
					case 0x0020:
						Util.cpuLog("FX29: Set I equal to location of sprite for digit Vx.");
						// Multiply by number of rows per character
						I += V[x] * 5;
						
					case 0x0030:
						Util.cpuLog("FX33: Store BCD representation of Vx in memory location starting at location I");
						var number:Float = V[x];
						var i = 3;
						while (i > 0)
						{
							memory[I + i - 1] = Std.int(number % 10);
							number /= 10;

							i--;
						}
						
					case 0x0050:
						Util.cpuLog("FX55: Store V0 to VX, inclusive, in memory starting at I");
						for (r in 0...(x+1))
						{
							memory[I + r] = V[r];
						}
						
					case 0x0060:
						Util.cpuLog("FX65: Fill V0 to VX, inclusive, from memory starting at I");
						for (r in 0...(x + 1))
						{
							V[r] = memory[I + r];
						}
				}
			
			default:
				Util.cpuLog("Unknown opcode: " + StringTools.hex(opcode));
		}

		Util.cpuLog("After opcode execute...");
		Util.cpuLog(registerDump());
		Util.cpuLog('I: ${I}');
	}

	public function handleTimers(): Void
	{
		// Update timers
		if (delay_timer > 0)
			delay_timer--;
			
		if (sound_timer > 0)
		{
			if (sound_timer == 1)
			{
				// TODO: implement sound
				Util.cpuLog("BEEP!");
			}
			sound_timer--;
		}
	}

	public function memoryDump(?starting = 0, ?length:Int): String
	{
		length = length == null ? memory.length : length;
		var dump = "\n";

		for (x in 0...length)
		{
			if (x > memory.length)
			{
				break;
			}

			var memoryLocation = starting + x;
			var memoryValue = memory[memoryLocation];

			dump += '[${memoryLocation}]: ${memoryValue} (0x${StringTools.hex(memoryValue)})';

			if (x % 5 == 0)
			{
				dump += "\n";
			}
		}

		return dump;
	}

	private function registerDump(): String
	{
		var dump = "\n";

		for (x in 0...V.length)
		{
			dump += 'V[${StringTools.hex(x)}]: ${V[x]}';
			if (x != V.length - 1)
			{
				dump += "\n";
			}

		}

		return dump;
	}
}