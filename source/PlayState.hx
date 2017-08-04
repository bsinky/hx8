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
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		var filePath = Args.getROMArg();
		
		if (filePath == null)
		{
			Util.log("Please supply a \"--rom /path/to/rom/\" argument");
		}

		chip8KeyMap = new Map<FlxKey, Int>();

		// Initialize key map
		for (i in 0...chip8Keys.length)
		{
			chip8KeyMap.set(chip8Keys[i], i);
		}

		myChip8 = new CPU();
		
		Util.log('Loading ${filePath}');

		myChip8.loadGameFromPath(filePath);
		
		var graphics = new FlxSprite(0, 0);
		graphics.makeGraphic(Display.WIDTH, Display.HEIGHT, Display.OFF_COLOR, true);

		renderer = new Renderer(myChip8.screen, graphics.pixels);
		
		add(graphics);

		myChip8.start();
		
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
		myChip8.cycle();

		if (myChip8.drawFlag)
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

	private var chip8Keys = [
		FlxKey.Q,
		FlxKey.W,
		FlxKey.E,
		FlxKey.R,
		FlxKey.A,
		FlxKey.S,
		FlxKey.D,
		FlxKey.F,
		FlxKey.Z,
		FlxKey.X,
		FlxKey.C,
		FlxKey.V,
		FlxKey.LEFT,
		FlxKey.RIGHT,
		FlxKey.UP,
		FlxKey.DOWN
	];

	private var chip8KeyMap:Map<FlxKey, Int>;
}