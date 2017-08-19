package emu;

#if !html5
import arguable.ArgParser;
#end

class Args
{
    public static inline var DEFAULT_CYCLES_PER_FRAME:Int = 6;

    #if !html5
    private static var _values:ArgValues;

    private static function initValues(): Void
    {
        if (_values == null)
        {
            _values = ArgParser.parse(Sys.args());
        }
    }

    public static function getROMArg(): String
    {
        initValues();

        return _values.has("rom")
            ? _values.get("rom").value
            : null;
    }

    public static function isFullscreen(): Bool
    {
        return _values.has("fullscreen");
    }

    public static function getCyclesPerFrame(): Int
    {
        return _values.has("cyclesperframe")
            ? Std.parseInt(_values.get("cyclesperframe").value)
            : DEFAULT_CYCLES_PER_FRAME;
    }
    #end
}