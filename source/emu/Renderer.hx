package emu;

import flash.display.BitmapData;

class Renderer
{
    private var _display:Display;
    private var _pixels:BitmapData;

    public function new(display:Display, pixels:BitmapData)
    {
        _display = display;
        _pixels = pixels;
    }

    public function draw(): Void
	{
		_pixels.lock();
		
		// do drawing
		for (x in 0...Display.WIDTH)
        {
            for( y in 0...Display.HEIGHT)
            {
                _pixels.setPixel32(x, y, _display.getPixel(x, y) ? Display.ON_COLOR : Display.OFF_COLOR);
            }
        }
		
		_pixels.unlock();

        Util.displayLog(_display);
	}
}