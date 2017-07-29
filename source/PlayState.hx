package;

import sys.io.File;
import Sys;
import emu.CPU;
import emu.Display;
import arguable.ArgParser;
import flixel.input.keyboard.FlxKeyList;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var myChip8:CPU;
	private var graphics:FlxSprite;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		var results = ArgParser.parse(Sys.args());

		if (!results.has("rom"))
		{
			Sys.println("Please supply a \"--rom /path/to/rom/\" argument");
			Sys.exit(-1);
		}

		var filePath = results.get("rom").value;
		
		chip8KeyMap = new Map<FlxKey, Int>();

		// Initialize key map
		for (i in 0...chip8Keys.length)
		{
			chip8KeyMap.set(chip8Keys[i], i);
		}

		myChip8 = new CPU();
		
		trace('Loading ${filePath}');

		myChip8.loadGame(File.getBytes(filePath));
		
		graphics = new FlxSprite(0, 0);
		graphics.makeGraphic(Display.WIDTH, Display.HEIGHT, FlxColor.BLACK, true);
		
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
		graphics = null;
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(elapsed:Float):Void
	{
		trace("cycle...");
		myChip8.cycle();
		
		if (myChip8.drawFlag)
		{
			trace("drawScreen");
			myChip8.drawScreen(graphics.pixels);
		}
		
		if (myChip8.isWaitingForKey && FlxG.keys.anyJustPressed(chip8Keys))
		{
			var keyCode = chip8KeyMap.get(FlxG.keys.firstJustPressed());
			myChip8.setKey(keyCode);
			myChip8.start();
		}
		
		super.update(elapsed);
	}

	private var chip8Keys = [
		FlxKey.A,
		FlxKey.S,
		FlxKey.Z,
		FlxKey.X
	];

	private var chip8KeyMap:Map<FlxKey, Int>;
}