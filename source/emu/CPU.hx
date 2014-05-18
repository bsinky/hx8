package emu;

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
	private var delay_timer:Int;	// Delay timer register
	private var sound_timer:Int;	// Sound timer register
	private var stack:Array<Int>;	// Stack for pc before subroutine calls
	private var sp:Int;				// Stack pointer
	private var key:Array<Int>;		// HEX based keypad for input
	
	public function new() 
	{
		memory = new Array<Int>();
		V = new Array<Int>();
		gfx = new Array<Bool>();
		key = new Array<Int>();
	}
	
	public function initialize():Void 
	{
		pc = 0x200;					// Program counter starts at 0x200
		opcode = 0;					// Reset opcode
		I = 0;						// Reset index register
		sp = 0;						// Reset stack pointer
		
		// Clear Display
		// Clear Stack
		// Clear Registers V0-VF
		// Clear memory
		
		// TODO: create chip8_fontset
		// Load fontset
		/*
		for(i in 0...80)
		{
			memory[i] = chip8_fontset[i];
		}
		*/
		
		// Reset timers
	}
	
	public function loadGame(Game:Dynamic):Void 
	{
		// TODO: fetch the game to open somehow
		
		// Load program into memory
		/*
		 * for( i in 0...bufferSize)
		 * {
		 * 		memory[i + 512] = buffer[i];
		 * }
		 */
	}
	
	public function cycle():Void 
	{
		// Fetch opcode
		opcode = memory[pc] << 8 | memory[pc + 1];
		
		// Decode opcode
		// Examine only the first digit
		switch(opcode & 0xF000)
		{
			case 0xA000: // ANNN: Sets I to address NNN
				I = opcode & 0x0FFF;
				pc += 2;
				
			case 0xD000: // DXYN: draw to screen
				// TODO: draw sprite to screen
				
			case 0x0000:
				switch(opcode & 0x000F)
				{
					case 0x0000: // 00E0: Clears the screen
						// TODO: clear Screen
						
					case 0x000E: // 00EE: Returns from subroutine
					
					default:
						trace("Unknown opcode: " + StringTools.hex(opcode));
				}
				
			case 0x2000: // 2NNN: Calls subroutine at NNN
				stack[sp] = pc;
				sp++;
				pc = opcode & 0x0FFF;
				
			case 0x8000:
				switch (opcode & 0x000F) 
				{
					case 0x0004: // 8XY4: Add value of VY to VX
						if (V[(opcode & 0x00F0) >> 4] > (0xFF - V[(opcode & 0x0F00) >> 8]))
							V[0xF] = 1; // carry flag
						else
							V[0xF] = 0; // No carry
						
						// VX - 0X00				 VY - 00Y0
						V[(opcode & 0x0F00) >> 8] += V[(opcode & 0x00F0) >> 4];
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