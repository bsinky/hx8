package emu;

import lime.graphics.CairoRenderContext;
import lime.graphics.CanvasRenderContext;

typedef Palette = {
    var off:UInt;
    var on:UInt;
};

typedef RGBPercent = {
    var Red:Float;
    var Green:Float;
    var Blue:Float;
};

class Renderer
{
    private var _display:Display;
    private var _paletteIndex:Int;
    private var _palette:Palette;
    private var _isInverted:Bool;
    private var _isContextInitialized:Bool;

    public var scale:Float;
    public var forceRedraw(default, null):Bool;
    public var onHex(get, null):UInt;
    public function get_onHex(): UInt
    {
        return _isInverted
            ? _palette.off
            : _palette.on;
    }

    public var offHex(get, null):UInt;
    public function get_offHex(): UInt
    {
        return _isInverted
            ? _palette.on
            : _palette.off;
    }

    public var width(get, null):Int;
    public function get_width(): Int
    {
        return Display.WIDTH;
    }

    public var height(get, null):Int;
    public function get_height():Int
    {
        return Display.HEIGHT;
    }

    public var offRGB(default, null):RGBPercent;
    public var onRGB(default, null):RGBPercent;
    
    public static var Palettes = [
        { off: 0x000000, on: 0xFFFFFF },    // Black and white
        { off: 0x996600, on: 0xFFCC00 },    // Brown and yellow
        { off: 0x8BAC0F, on: 0x306230 },    // Shades of green
        { off: 0xAA3939, on: 0x550000 },    // Reds
        { off: 0x045777, on: 0x6BB1CC },    // Blues
        { off: 0xED9A00, on: 0x936000 },    // "Haxe" theme
    ];

    public function new(display:Display)
    {
        _display = display;
        _paletteIndex = 0;
        _palette = Palettes[_paletteIndex];
        _isInverted = false;
        _isContextInitialized = false;
        forceRedraw = false;
        scale = 1.0;
        updateRGBPercents();
    }

    private function internalDraw(renderCallback:Float->Float->Float->Float->RGBPercent->Void): Void
    {
        for (x in 0...Display.WIDTH)
        {
            for( y in 0...Display.HEIGHT)
            {
                var isPixelOn = _display.getPixel(x, y);
                renderCallback(x * scale, y * scale, scale, scale, isPixelOn ? onRGB : offRGB);
            }
        }

        // Done drawing, reset force redraw flag
        forceRedraw = false;

        Util.displayLog(_display);
    }

    private function internalDrawHexColor(renderCallback:Float->Float->Float->Float->UInt->Void): Void
    {
        for (x in 0...Display.WIDTH)
        {
            for( y in 0...Display.HEIGHT)
            {
                var isPixelOn = _display.getPixel(x, y);
                renderCallback(x * scale, y * scale, scale, scale, isPixelOn ? onHex : offHex);
            }
        }

        // Done drawing, reset force redraw flag
        forceRedraw = false;

        Util.displayLog(_display);
    }

    public function drawCairo(cairo:CairoRenderContext): Void
    {
        cairo.setSourceRGB(offRGB.Red, offRGB.Green, offRGB.Blue);
        cairo.fill();
        internalDraw(function(x,y,width,height,color) {
            cairo.moveTo(x, y);
            cairo.setSourceRGB(color.Red, color.Green, color.Blue);
            cairo.rectangle(x,y,width,height);
            cairo.fill();
        });
    }
    
    public function drawCanvas(canvas:CanvasRenderContext): Void
    {
        canvas.fillStyle = '#${StringTools.lpad(StringTools.hex(offHex), "0", 6)}';
        canvas.fill();
        internalDrawHexColor(function(x,y,width,height,color) {
            var colorString = '#${StringTools.lpad(StringTools.hex(color), "0", 6)}';
            canvas.fillStyle = colorString;
            canvas.fillRect(x,y,width,height);
        });
    }

    public function swapPalette(): Void
    {
        _paletteIndex = (_paletteIndex + 1) % Palettes.length;
        _palette = Palettes[_paletteIndex];
        updateRGBPercents();        

        // Reset any palette inversion
        _isInverted = false;

        // Ensure the screen redraws the next frame
        forceRedraw = true;

        trace("Palette swap");
    }

    public function invertPalette(): Void
    {
        _isInverted = !_isInverted;
        updateRGBPercents();

        // Ensure the screen redraws the next frame
        forceRedraw = true;

        trace("Palette invert");
    }

    private function updateRGBPercents(): Void
    {
        var on = onHex;
        var off = offHex;
        onRGB = {
            Red: Util.rValue(on) / 255,
            Green: Util.gValue(on) / 255,
            Blue: Util.bValue(on) / 255
        };

        offRGB = {
            Red: Util.rValue(off) / 255,
            Green: Util.gValue(off) / 255,
            Blue: Util.bValue(off) / 255
        };
    }
}