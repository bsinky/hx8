package emu;

import haxe.io.Bytes;
import flash.display.BitmapData;

/**
 * ...
 * @author Benjamin Sinkula
 */
class CPU
{

	public var drawFlag:Bool;		// Whether to draw to screen this cycle
	public var isWaitingForKey:Bool;

	private var opcode:Int;			// Current opcode to execute
	private var memory:Array<Int>;	// Chip 8 total memory
	private var V:Array<Int>;		// CPU registers
	private var I:Int;				// Index register
	private var pc:Int;				// Program counter
	private var gfx:Array<Bool>;	// Screen
	private var screen:Display;
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
		for (i in 0...0xf)
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
		isRunning = true;
	}

	public function stop():Void
	{
		isRunning = false;
	}
	
	public function drawScreen(pixels:BitmapData): Void
	{
		screen.draw(pixels);
	}

	public function waitForKey(): Void
	{
		stop();
		isWaitingForKey = true;
	}

	public function setKey(key:Int): Void
	{
		isWaitingForKey = false;
		V[nextKeyRegister] = key;
	}
	
	public function cycle():Void 
	{
		// TODO: might need to handle timers even when not running
		if (!isRunning)
		{
			return;
		}

		// Fetch opcode
		opcode = memory[pc] << 8 | memory[pc + 1];

		var x = (opcode & 0x0F00) >> 8;
		var y = (opcode & 0x00F0) >> 4;

		pc += 2;
		
		// Decode opcode
		// Examine only the first digit
		switch(opcode & 0xF000)
		{				
			case 0x0000:
				switch(opcode & 0x000F)
				{
					case 0x0000:
						trace("00E0: Clear screen");
						screen.clear();
						
					case 0x000E:
						trace("00EE: Returns from subroutine");
						pc = stack[sp];
						sp--;
					default:
						trace("Unknown opcode: " + StringTools.hex(opcode));
				}
				
			case 0x1000:
				trace("1NNN: Jump to address NNN");
				pc = opcode & 0x0FFF;
				
			case 0x2000:
				trace("2NNN: Calls subroutine at NNN");
				stack[sp] = pc;
				sp++;
				pc = opcode & 0x0FFF;
				
			case 0x3000:
				trace("3XNN: Skip if VX equals constant NN");
				if (V[(opcode & 0x0F00) >> 8] == (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				
			case 0x4000:
				trace("4XNN: Skip if VX does not equal NN");
				if (V[(opcode & 0x0F00) >> 8] != (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				
			case 0x5000:
				trace("5XY0: Skip if VX equals VY");
				if (V[(opcode & 0x0F00) >> 8] == V[(opcode & 0x00F0) >> 4])
					pc += 2;	// Skip next opcode
				
			case 0x6000:
				trace("6XNN: Store NN in register VX");
				V[(opcode & 0x0F00) >> 8] = opcode & 0x00FF;
				
			case 0x7000:
				trace("7XNN: Add NN to VX.  No carry.");
				var register = (opcode & 0x0F00) >> 8;
				V[register] += opcode & 0x00FF;
				// Constrain the value to 8 bits in length (no carry)
				if (V[register] > REG_MAX)
					V[register] -= REG_MAX + 1; // +1 for off-by-one
				
			case 0x8000:
				switch (opcode & 0x000F) 
				{
					case 0x0000:
						trace("8XY0: Move VY into VX");
						V[(opcode & 0x0F00) >> 8] = V[(opcode & 0x00F0) >> 4];
						
					case 0x0001:
						trace("8XY1: bitwise OR of VY and VX, store in VX");
						V[x] = V[x] | V[y];
						
					case 0x0002:
						trace("8XY2: bitwise AND of VY and VX, store in VX");
						V[x] = V[x] & V[y];
						
					case 0x0003:
						trace("8XY3: bitwise XOR of VY and VX, store in VX");
						V[x] = V[x] ^ V[y];
						
					case 0x0004:
						trace("8XY4: Add value of VY to VX");
						if (V[(opcode & 0x00F0) >> 4] > (0xFF - V[(opcode & 0x0F00) >> 8]))
							V[0xF] = 1; // carry flag
						else
							V[0xF] = 0; // No carry
						
						// VX - 0X00				 VY - 00Y0
						V[(opcode & 0x0F00) >> 8] += V[(opcode & 0x00F0) >> 4];
					
					// TODO: double-check borrow logic
					case 0x0005:
						trace("8XY5: subtract VY from VX, borrow flag in VF");
						if (V[x] < V[y])
							V[0xF] = 0; // borrow flag
						else
							V[0xF] = 1; // no borrow flag
							
						V[x] -= V[y];
						
					case 0x0006:
						trace("8X06: shift VX right, bit 0 goes to VF");
						V[0xF] = V[x] & 0x1;
						V[x] = V[x] >> 1;
					
					// TODO: double-check borrow logic
					case 0x0007:
						trace("8XY7: subtract VX from VY, store in VX.  1 in VF if borrows.");
						if (V[y] < V[x])
							V[0xF] = 0;		// borrow flag
						else
							V[0x0F] = 1;	// no borrow flag
						
						V[x] = V[y] - V[x];
						
					case 0x000E:
						trace("8X0E: shift VX left 1 bit, 7th bit goes in VF");
						// AND with 0x80 to get leftmost bit of VX
						V[0xF] = V[x] & 0x80;
						// Left shift and AND to get rid of any bits outside of the 8 bits the register is supposed to be
						V[x] = (V[x] << 1) & 0xFF;
				}
				
			case 0x9000:
				trace("9XY0: skip if VX != VY");
				if (V[x] != V[y])
					pc += 2;
				
			case 0xA000:
				trace("ANNN: Sets I to address NNN");
				I = opcode & 0x0FFF;
				
			case 0xB000:
				trace("BNNN: Jump to address NNN + V0");
				pc = opcode & (0x0FFF + V[0x0]);
				
			case 0xC000:
				trace("CXNN: Set VX to a random number less than or equal to NN");
				V[x] = Math.round(Math.random() * (opcode & 0x00FF));
				
			case 0xD000:
				trace("DXYN: draw to screen");
				// TODO: draw sprite to screen
				V[0xF] = 0;

                var height = opcode & 0x000F;
                var registerX = V[x];
            	var registerY = V[y];
				var spr = 0;

				for (screenY in 0...Display.HEIGHT)
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
					drawFlag = true;
				}
				
			case 0xE000:
				switch(opcode & 0x00F0)
				{
					
					case 0x0090:
						trace("EX9E: skip if key noted by code in VX is pressed");
						// TODO: key number???
						if (key[V[x]])
							pc += 2;
						
					case 0x00a0:
						trace("EXA1: skip if key noted by code in VX is NOT pressed");
						// TODO: key number??
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
								trace("FX07");
								V[x] = delay_timer;
								
							case 0x000A:
								trace("FX0A");
								// TODO: await a key press, then store in VX
								nextKeyRegister = x;
								waitForKey();
						}
					case 0x0010:
						switch(opcode & 0x000F)
						{
							case 0x0005:
								trace("FX15");
								delay_timer = V[x];
								
							case 0x0008:
								trace("FX18");
								sound_timer = V[x];
								
							case 0x000E:
								trace("FX1E");
								I += V[x];
								// Don't care about overflow?
								// if (I > REG_MAX)
								// 	I = REG_MAX;
						}
						
					case 0x0020:
						trace("FX29");
						// TODO: this might not be right?
						I += V[x] * 5;
						
					case 0x0030:
						trace("FX33");
						// TODO: Not sure if this works/is correct?
						var number:Float = V[x];
						var i = 3;
						while (i > 0)
						{
							memory[i + i - 1] = cast(number % 10, Int);
							number /= 10;

							i--;
						}
						
					case 0x0050:
						trace("FX55: Store V0 to VX, inclusive, in memory starting at I");
						for (r in 0...(x+1))
						{
							memory[I + r] = V[r];
						}
						
					case 0x0060:
						trace("FX65: Fill V0 to VX, inclusive, from memory starting at I");
						for (r in 0...(x + 1))
						{
							V[r] = memory[I + r];
						}
				}
			
			default:
				trace("Unkown opcode: " + StringTools.hex(opcode));
		}
		
		// Update timers
		if (delay_timer > 0)
			delay_timer--;
			
		if (sound_timer > 0)
		{
			if (sound_timer == 1)
				trace("BEEP!");
			sound_timer--;
		}
	}
}