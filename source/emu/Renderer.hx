package emu;

import flash.display.BitmapData;

typedef Palette = {
    var off:UInt;
    var on:UInt;
};

class Renderer
{
    private var _display:Display;
    private var _pixels:BitmapData;
    private var _paletteIndex:Int;
    private var _palette:Palette;
    private var _isInverted:Bool;

    public var forceRedraw(default, null):Bool;

    public static var Palettes = [
        { off: 0xFF000000, on: 0xFFFFFFFF },    // Black and white
        { off: 0xFF996600, on: 0xFFFFCC00 },    // Brown and yellow
        { off: 0xFF8BAC0F, on: 0xFF306230 },    // Shades of green
        { off: 0xFFAA3939, on: 0xFF550000 },    // Reds
        { off: 0xFF045777, on: 0xFF6BB1CC },    // Blues
        { off: 0xFFED9A00, on: 0xFF936000 },    // "Haxe" theme
    ];

    public function new(display:Display, pixels:BitmapData)
    {
        _display = display;
        _pixels = pixels;
        _paletteIndex = 0;
        _palette = Palettes[_paletteIndex];
        _isInverted = false;
        forceRedraw = false;
    }

    public function draw(): Void
    {
        _pixels.lock();

        var onColor =
            if (!_isInverted) _palette.on
            else _palette.off;

        var offColor =
            if (!_isInverted) _palette.off
            else _palette.on;
        
        // do drawing
        for (x in 0...Display.WIDTH)
        {
            for( y in 0...Display.HEIGHT)
            {
                _pixels.setPixel32(x, y, _display.getPixel(x, y) ? onColor : offColor);
            }
        }
        
        _pixels.unlock();

        // Done drawing, reset force redraw flag
        forceRedraw = false;

        Util.displayLog(_display);
    }

    public function swapPalette(): Void
    {
        _paletteIndex = (_paletteIndex + 1) % Palettes.length;
        _palette = Palettes[_paletteIndex];

        // Reset any palette inversion
        _isInverted = false;

        // Ensure the screen redraws the next frame
        forceRedraw = true;
    }

    public function invertPalette(): Void
    {
        _isInverted = !_isInverted;

        // Ensure the screen redraws the next frame
        forceRedraw = true;
    }
}