package;

import emu.CPU;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	private var myChip8:CPU;
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		//setupGraphics();
		//setupInput();
		
		myChip8 = new CPU();
		//myChip8.load("pong");
		
		super.create();
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to 
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		myChip8.cycle();
		
		if (myChip8.drawFlag)
		{
			//drawGraphics();
		}
		
		myChip8.setKeys();
		
		super.update();
	}	
}