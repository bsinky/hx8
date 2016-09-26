package;

import emu.CPU;
import emu.Display;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
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
		//setupGraphics();
		//setupInput();
		
		myChip8 = new CPU();
		//myChip8.load("pong");
		
		graphics = new FlxSprite(0, 0);
		graphics.makeGraphic(Display.WIDTH, Display.HEIGHT, FlxColor.BLACK, true);
		
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
		graphics = null;
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
			myChip8.drawScreen(graphics.pixels);
		}
		
		myChip8.setKeys();
		
		super.update(elapsed);
	}
}