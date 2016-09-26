package emu;
import flash.display.BitmapData;

class Display
{
    public static inline var WIDTH:Int = 64;
    public static inline var HEIGHT:Int = 32;
	public static inline var OFF_COLOR:UInt = 0xff000000;
	public static inline var ON_COLOR:UInt = 0xffffffff;

    private var screen:Array<Bool>;

    public function new()
    {
        screen = new Array<Bool>();

        // initialize blank display
        clear();
    }

    public function clear() : Void
    {
        for (x in 0...WIDTH)
        {
            for( y in 0...HEIGHT)
            {
                screen[x + (y * HEIGHT)] = false;
            }
        }
    }

    private function wrapXAndY(x:Int, y:Int):Point
    {
        var xToSet = 0;
        var yToSet = 0;

        if (x > WIDTH)
        {
            xToSet = x -= WIDTH;
        }
        else if (x < 0)
        {
            xToSet = x += WIDTH;
        }

        if (y > HEIGHT)
        {
            yToSet = y -= HEIGHT;
        }
        else if (y < 0)
        {
            yToSet = y += HEIGHT;
        }

        return { X: xToSet, Y: yToSet };
    }

    // Returns true if the pixel toggled from set to unset
    public function setPixel(x:Int, y:Int):Bool
    {
        var location = wrapXAndY(x, y);
        var previousPixelValue = screen[location.X + (location.Y * WIDTH)];

        screen[location.X + (location.Y * WIDTH)] = !previousPixelValue;

        return previousPixelValue;
    }

    public function getPixel(x:Int, y:Int):Bool
    {
        var location = wrapXAndY(x, y);
        return screen[location.X + (location.Y * WIDTH)];
    }
	
	public function draw(pixels:BitmapData): Void
	{
		pixels.lock();
		
		// do drawing
		for (x in 0...WIDTH)
        {
            for( y in 0...HEIGHT)
            {
                pixels.setPixel32(x, y, screen[x + (y * WIDTH)] ? ON_COLOR : OFF_COLOR);
            }
        }
		
		pixels.unlock();
	}
}

typedef Point = { X:Int, Y:Int }