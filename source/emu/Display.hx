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
                screen[getScreenIndex(x, y)] = false;
            }
        }
    }

    private function wrapXAndY(x:Int, y:Int):Point
    {
        var xToSet = x;
        var yToSet = y;

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
        var screenIndex = getScreenIndex(location.X, location.Y);
        var previousPixelValue = screen[screenIndex];

        screen[screenIndex] = !previousPixelValue;

        return previousPixelValue;
    }

    public function getPixel(x:Int, y:Int):Bool
    {
        var location = wrapXAndY(x, y);
        return screen[getScreenIndex(location.X, location.Y)];
    }
	
	public function draw(pixels:BitmapData): Void
	{
		pixels.lock();
		
		// do drawing
		for (x in 0...WIDTH)
        {
            for( y in 0...HEIGHT)
            {
                pixels.setPixel32(x, y, getPixel(x, y) ? ON_COLOR : OFF_COLOR);
            }
        }
		
		pixels.unlock();

        Util.displayLog(this);
	}

    public function toString(): String
    {
        var screenString = "\n";

        for (x in 0...WIDTH)
        {
            for (y in 0...HEIGHT)
            {
                screenString += getPixel(x, y) ? "1" : "0";
            }
            screenString += "\n";
        }

        return screenString;
    }

    private function getScreenIndex(x:Int, y:Int):Int
    {
        return x + (y * WIDTH);
    }
}

typedef Point = { X:Int, Y:Int }