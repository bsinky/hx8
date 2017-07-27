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
		
		// TODO: create chip8_fontset
		// Load fontset
		/*
		for(i in 0...80)
		{
			memory[i] = chip8_fontset[i];
		}
		*/
		
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
	
	public function cycle():Void 
	{
		// TODO: might need to handle timers even when not running
		if (!isRunning)
		{
			return;
		}

		// Fetch opcode
		opcode = memory[pc] << 8 | memory[pc + 1];
		
		// Decode opcode
		// Examine only the first digit
		switch(opcode & 0xF000)
		{				
			case 0x0000:
				switch(opcode & 0x000F)
				{
					case 0x0000: // 00E0: Clears the screen
						screen.clear();
						
					case 0x000E: // 00EE: Returns from subroutine
						pc = stack[sp];
						sp--;
					default:
						trace("Unknown opcode: " + StringTools.hex(opcode));
				}
				
			case 0x1000: // 1NNN: Jump to address NNN
				pc = opcode & 0x0FFF;
				
			case 0x2000: // 2NNN: Calls subroutine at NNN
				stack[sp] = pc;
				sp++;
				pc = opcode & 0x0FFF;
				
			case 0x3000: // 3XNN: Skip if VX equals constant NN
				if (V[(opcode & 0x0F00) >> 8] == (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				pc += 2;		// Normal opcode increment
				
			case 0x4000: // 4XNN: Skip if VX does not equal NN
				if (V[(opcode & 0x0F00) >> 8] != (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				pc += 2;
				
			case 0x5000: // 5XY0: Skip if VX equals VY
				if (V[(opcode & 0x0F00) >> 8] == V[(opcode & 0x00F0) >> 4])
					pc += 2;	// Skip next opcode
				pc += 2;
				
			case 0x6000: // 6XNN: Store NN in register VX
				V[(opcode & 0x0F00) >> 8] = opcode & 0x00FF;
				pc += 2;
				
			case 0x7000: // 7XNN: Add NN to VX.  No carry.
				var register = (opcode & 0x0F00) >> 8;
				V[register] += opcode & 0x00FF;
				// Constrain the value to 8 bits in length (no carry)
				if (V[register] > REG_MAX)
					V[register] -= REG_MAX + 1; // +1 for off-by-one
				pc += 2;
				
			case 0x8000:
				switch (opcode & 0x000F) 
				{
					case 0x0000: // 8XY0: Move VY into VX
						V[(opcode & 0x0F00) >> 8] = V[(opcode & 0x00F0) >> 4];
						pc += 2;
						
					case 0x0001: // 8XY1: bitwise OR of VY and VX, store in VX
						var x = (opcode & 0x0F00) >> 8;
						var y = (opcode & 0x00F0) >> 4;
						V[x] = V[x] | V[y];
						pc += 2;
						
					case 0x0002: // 8XY2: bitwise AND of VY and VX, store in VX
						var x = (opcode & 0x0F00) >> 8;
						var y = (opcode & 0x00F0) >> 4;
						V[x] = V[x] & V[y];
						pc += 2;
						
					case 0x0003: // 8XY3: bitwise XOR of VY and VX, store in VX
						var x = (opcode & 0x0F00) >> 8;
						var y = (opcode & 0x00F0) >> 4;
						V[x] = V[x] ^ V[y];
						pc += 2;
						
					case 0x0004: // 8XY4: Add value of VY to VX
						if (V[(opcode & 0x00F0) >> 4] > (0xFF - V[(opcode & 0x0F00) >> 8]))
							V[0xF] = 1; // carry flag
						else
							V[0xF] = 0; // No carry
						
						// VX - 0X00				 VY - 00Y0
						V[(opcode & 0x0F00) >> 8] += V[(opcode & 0x00F0) >> 4];
						pc += 2;
					
					// TODO: double-check borrow logic
					case 0x0005: // 8XY5: subtract VY from VX, borrow flag in VF
						var x = (opcode & 0x0F00) >> 8;
						var y = (opcode & 0x00F0) >> 4;
						if (V[x] < V[y])
							V[0xF] = 0; // borrow flag
						else
							V[0xF] = 1; // no borrow flag
							
						V[x] -= V[y];
						pc += 2;
						
					case 0x0006: // 8X06: shift VX right, bit 0 goes to VF
						var x = (opcode & 0x0F00) >> 8;
						V[0xF] = V[x] & 0x1;
						V[x] = V[x] >> 1;
						pc += 2;
					
					// TODO: double-check borrow logic
					case 0x0007: // 8XY7: subtract VX from VY, store in VX.  1 in VF if borrows.
						var x = (opcode & 0x0F00) >> 8;
						var y = (opcode & 0x00F0) >> 4;
						if (V[y] < V[x])
							V[0xF] = 0;		// borrow flag
						else
							V[0x0F] = 1;	// no borrow flag
						
						V[x] = V[y] - V[x];
						pc += 2;
						
					case 0x000E: // 8X0E: shift VX left 1 bit, 7th bit goes in VF
						var x = (opcode & 0x0F00) >> 8;
						// AND with 0x80 to get leftmost bit of VX
						V[0xF] = V[x] & 0x80;
						// Left shift and AND to get rid of any bits outside of the 8 bits the register is supposed to be
						V[x] = (V[x] << 1) & 0xFF;
						pc += 2;
				}
				
			case 0x9000: // 9XY0: skip if VX != VY
				var x = (opcode & 0x0F00) >> 8;
				var y = (opcode & 0x00F0) >> 4;
				if (V[x] != V[y])
					pc += 2;
				pc += 2;
				
			case 0xA000: // ANNN: Sets I to address NNN
				I = opcode & 0x0FFF;
				pc += 2;
				
			case 0xB000: // BNNN: Jump to address NNN + V0
				pc = opcode & (0x0FFF + V[0x0]);
				
			case 0xC000: // CXNN: Set VX to a random number less than or equal to NN
				var x = (opcode & 0x0F00) >> 8;
				V[x] = Math.round(Math.random() * (opcode & 0x00FF));
				pc += 2;
				
			case 0xD000: // DXYN: draw to screen
				// TODO: draw sprite to screen
				V[0xF] = 0;
				var x = (opcode & 0x0F00) >> 8;
				var y = (opcode & 0x00F0) >> 4;

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
					case 0x0090: // EX9E: skip if key noted by code in VX is pressed
						var x = (opcode & 0x0F00) >> 8;
						// TODO: key number???
						if (key[V[x]])
							pc += 2;
						pc += 2;
						
					case 0x00a0: // EXA1: skip if key noted by code in VX is NOT pressed
						var x = (opcode & 0x0F00) >> 8;
						// TODO: key number??
						if (!key[V[x]])
							pc += 2;
						pc += 2;
				}
				
			case 0xF000:
				switch(opcode & 0x00F0)
				{
					case 0x0000:
						switch(opcode & 0x000F)
						{
							case 0x0007: // FX07
								var x = (opcode & 0x0F00) >> 8;
								V[x] = delay_timer;
								pc += 2;
								
							case 0x000A: // FX0A
								// TODO: await a key press, then store in VX
								stop();
						}
					case 0x0010:
						switch(opcode & 0x000F)
						{
							case 0x0005: // FX15
								var x = (opcode & 0x0F00) >> 8;
								delay_timer = V[x];
								pc += 2;
								
							case 0x0008: // FX18
								var x = (opcode & 0x0F00) >> 8;
								sound_timer = V[x];
								
							case 0x000E: // FX1E
								var x = (opcode & 0x0F00) >> 8;
								I += V[x];
								// Don't care about overflow?
								// if (I > REG_MAX)
								// 	I = REG_MAX;
								pc += 2;
						}
						
					case 0x0020: // FX29
						// TODO: this might not be right?
						var x = (opcode & 0x0F00) >> 8;
						I += V[x] * 5;
						
					case 0x0030: // FX33
						// TODO: Not sure if this works/is correct?
						var x = (opcode & 0x0F00) >> 8;
						var number:Float = V[x];
						var i = 3;
						while (i > 0)
						{
							memory[i + i - 1] = cast(number % 10, Int);
							number /= 10;

							i--;
						}
						
					case 0x0050: // FX55
						var x = (opcode & 0x0F00) >> 8;
						// Store V0 to VX, inclusive, in memory starting at I
						for (r in 0...(x+1))
						{
							memory[I + r] = V[r];
						}
						pc += 2;
						
					case 0x0060: // FX65
						var x = (opcode & 0x0F00) >> 8;
						// Fill V0 to VX, inclusive, from memory starting at I
						for (r in 0...(x + 1))
						{
							V[r] = memory[I + r];
						}
						pc += 2;
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
	
	public function setKeys():Void 
	{
		
	}
}