package emu;

class Display
{
    public static inline var WIDTH:Int = 64;
    public static inline var HEIGHT:Int = 32;

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
            for y in 0...HEIGHT)
            {
                screen[x + (y * HEIGHT)] = false;
            }
        }
    }

    private function wrapXAndY(x:Int, y:Int):Point
    {
        var xToSet;
        var yToSet;

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

        return { X = xToSet, Y = yToSet };
    }

    // Returns true if the pixel toggled from set to unset
    private function setPixel(x:Int, y:Int):Bool
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

    typedef Point = { X:Int, Y:Int }
}