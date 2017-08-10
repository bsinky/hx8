package;

import emu.CPU;
import emu.Display;
import emu.Args;
import emu.Renderer;
import emu.Util;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var myChip8:CPU;
	private var renderer:Renderer;
	private var step:Int;
	private var cyclesPerFrame:Int;
	private var chip8KeyMap:Map<FlxKey, Int>;
	private var chip8Keys = [
		FlxKey.X, 		// 0
		FlxKey.ONE,		// 1
		FlxKey.TWO,		// 2
		FlxKey.THREE,	// 3
		FlxKey.Q, 		// 4
		FlxKey.W, 		// 5
		FlxKey.E, 		// 6
		FlxKey.A, 		// 7
		FlxKey.S, 		// 8
		FlxKey.D, 		// 9
		FlxKey.Z,		// A
		FlxKey.C,		// B
		FlxKey.FOUR,	// C
		FlxKey.R,		// D
		FlxKey.F,		// E
		FlxKey.V		// F
	];

	private function resetChip8(): Void
	{
		myChip8.initialize();

		var filePath = Args.getROMArg();
		
		if (filePath == null)
		{
			Util.log("Please supply a \"--rom /path/to/rom/\" argument");
		}

		Util.log('Loading ${filePath}');

		myChip8.loadGameFromPath(filePath);

		myChip8.start();
	}

	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void
	{
        // Hide the mouse
        FlxG.mouse.visible = false;

		chip8KeyMap = new Map<FlxKey, Int>();

		// Initialize key map
		for (i in 0...chip8Keys.length)
		{
			chip8KeyMap.set(chip8Keys[i], i);
		}

		myChip8 = new CPU();
		
		resetChip8();

		cyclesPerFrame = Args.getCyclesPerFrame();
		
		var graphics = new FlxSprite(0, 0);
		graphics.makeGraphic(Display.WIDTH, Display.HEIGHT, Renderer.Palettes[0].on, true);

		renderer = new Renderer(myChip8.screen, graphics.pixels);
		
		add(graphics);
		
		super.create();
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to 
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		myChip8 = null;
		renderer = null;
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(elapsed:Float):Void
	{
		handleEmulatorKeys();

		for (x in 0...cyclesPerFrame)
		{
			myChip8.cycle();
		}

		if (myChip8.drawFlag || renderer.forceRedraw)
		{
			renderer.draw();
			myChip8.drawFlag = false;
		}

		var keyStates = [
			for (i in 0...chip8Keys.length)
			{
				i => FlxG.keys.checkStatus(chip8Keys[i], FlxInputState.PRESSED);
			}
		];

		myChip8.setKeys(keyStates);
		
		if (myChip8.isWaitingForKey && FlxG.keys.anyJustPressed(chip8Keys))
		{
			var keyCode = chip8KeyMap.get(FlxG.keys.firstJustPressed());
			myChip8.setKey(keyCode);
			myChip8.start();
		}

		if (step++ % 2 == 0)
		{
			myChip8.handleTimers();
		}
		
		super.update(elapsed);
	}

	private function handleEmulatorKeys(): Void
	{
		// Reset key
		if (FlxG.keys.justReleased.G)
		{
			resetChip8();
		}

		// Change palette
		if (FlxG.keys.justReleased.P)
		{
			renderer.swapPalette();
		}

		// Invert palette
		if (FlxG.keys.justReleased.I)
		{
			renderer.invertPalette();
		}

		// Exit key
		if (FlxG.keys.justReleased.ESCAPE)
		{
			#if !html5
			Sys.exit(0);
			#end
		}
	}
}