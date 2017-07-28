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
						Util.log("00E0: Clear screen");
						screen.clear();
						
					case 0x000E:
						Util.log("00EE: Returns from subroutine");
						pc = stack[sp];
						sp--;
					default:
						Util.log("Unknown opcode: " + StringTools.hex(opcode));
				}
				
			case 0x1000:
				Util.log("1NNN: Jump to address NNN");
				pc = opcode & 0x0FFF;
				
			case 0x2000:
				Util.log("2NNN: Calls subroutine at NNN");
				stack[sp] = pc;
				sp++;
				pc = opcode & 0x0FFF;
				
			case 0x3000:
				Util.log("3XNN: Skip if VX equals constant NN");
				if (V[(opcode & 0x0F00) >> 8] == (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				
			case 0x4000:
				Util.log("4XNN: Skip if VX does not equal NN");
				if (V[(opcode & 0x0F00) >> 8] != (opcode & 0x00FF))
					pc += 2;	// Skip next opcode
				
			case 0x5000:
				Util.log("5XY0: Skip if VX equals VY");
				if (V[(opcode & 0x0F00) >> 8] == V[(opcode & 0x00F0) >> 4])
					pc += 2;	// Skip next opcode
				
			case 0x6000:
				Util.log("6XNN: Store NN in register VX");
				V[(opcode & 0x0F00) >> 8] = opcode & 0x00FF;
				
			case 0x7000:
				Util.log("7XNN: Add NN to VX.  No carry.");
				var register = (opcode & 0x0F00) >> 8;
				V[register] += opcode & 0x00FF;
				// Constrain the value to 8 bits in length (no carry)
				if (V[register] > REG_MAX)
					V[register] -= REG_MAX + 1; // +1 for off-by-one
				
			case 0x8000:
				switch (opcode & 0x000F) 
				{
					case 0x0000:
						Util.log("8XY0: Move VY into VX");
						V[(opcode & 0x0F00) >> 8] = V[(opcode & 0x00F0) >> 4];
						
					case 0x0001:
						Util.log("8XY1: bitwise OR of VY and VX, store in VX");
						V[x] = V[x] | V[y];
						
					case 0x0002:
						Util.log("8XY2: bitwise AND of VY and VX, store in VX");
						V[x] = V[x] & V[y];
						
					case 0x0003:
						Util.log("8XY3: bitwise XOR of VY and VX, store in VX");
						V[x] = V[x] ^ V[y];
						
					case 0x0004:
						Util.log("8XY4: Add value of VY to VX");
						if (V[(opcode & 0x00F0) >> 4] > (0xFF - V[(opcode & 0x0F00) >> 8]))
							V[0xF] = 1; // carry flag
						else
							V[0xF] = 0; // No carry
						
						// VX - 0X00				 VY - 00Y0
						V[(opcode & 0x0F00) >> 8] += V[(opcode & 0x00F0) >> 4];
					
					// TODO: double-check borrow logic
					case 0x0005:
						Util.log("8XY5: subtract VY from VX, borrow flag in VF");
						if (V[x] < V[y])
							V[0xF] = 0; // borrow flag
						else
							V[0xF] = 1; // no borrow flag
							
						V[x] -= V[y];
						
					case 0x0006:
						Util.log("8X06: shift VX right, bit 0 goes to VF");
						V[0xF] = V[x] & 0x1;
						V[x] = V[x] >> 1;
					
					// TODO: double-check borrow logic
					case 0x0007:
						Util.log("8XY7: subtract VX from VY, store in VX.  1 in VF if borrows.");
						if (V[y] < V[x])
							V[0xF] = 0;		// borrow flag
						else
							V[0x0F] = 1;	// no borrow flag
						
						V[x] = V[y] - V[x];
						
					case 0x000E:
						Util.log("8X0E: shift VX left 1 bit, 7th bit goes in VF");
						// AND with 0x80 to get leftmost bit of VX
						V[0xF] = V[x] & 0x80;
						// Left shift and AND to get rid of any bits outside of the 8 bits the register is supposed to be
						V[x] = (V[x] << 1) & 0xFF;
				}
				
			case 0x9000:
				Util.log("9XY0: skip if VX != VY");
				if (V[x] != V[y])
					pc += 2;
				
			case 0xA000:
				Util.log("ANNN: Sets I to address NNN");
				I = opcode & 0x0FFF;
				
			case 0xB000:
				Util.log("BNNN: Jump to address NNN + V0");
				pc = opcode & (0x0FFF + V[0x0]);
				
			case 0xC000:
				Util.log("CXNN: Set VX to a random number less than or equal to NN");
				V[x] = Math.round(Math.random() * (opcode & 0x00FF));
				
			case 0xD000:
				Util.log("DXYN: draw to screen");
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
						Util.log("EX9E: skip if key noted by code in VX is pressed");
						// TODO: key number???
						if (key[V[x]])
							pc += 2;
						
					case 0x00a0:
						Util.log("EXA1: skip if key noted by code in VX is NOT pressed");
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
								Util.log("FX07");
								V[x] = delay_timer;
								
							case 0x000A:
								Util.log("FX0A");
								// TODO: await a key press, then store in VX
								stop();
						}
					case 0x0010:
						switch(opcode & 0x000F)
						{
							case 0x0005:
								Util.log("FX15");
								delay_timer = V[x];
								
							case 0x0008:
								Util.log("FX18");
								sound_timer = V[x];
								
							case 0x000E:
								Util.log("FX1E");
								I += V[x];
								// Don't care about overflow?
								// if (I > REG_MAX)
								// 	I = REG_MAX;
						}
						
					case 0x0020:
						Util.log("FX29");
						// TODO: this might not be right?
						I += V[x] * 5;
						
					case 0x0030:
						Util.log("FX33");
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
						Util.log("FX55: Store V0 to VX, inclusive, in memory starting at I");
						for (r in 0...(x+1))
						{
							memory[I + r] = V[r];
						}
						
					case 0x0060:
						Util.log("FX65: Fill V0 to VX, inclusive, from memory starting at I");
						for (r in 0...(x + 1))
						{
							V[r] = memory[I + r];
						}
				}
			
			default:
				Util.log("Unkown opcode: " + StringTools.hex(opcode));
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