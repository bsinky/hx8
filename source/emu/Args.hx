package emu;

#if js
// import tink.Url;
#else
import arguable.ArgParser;
#end

class Args
{
    #if !js
    private static var _values:ArgValues;
    #end

    private static function initValues(): Void
    {
        #if !js
        if (_values == null)
        {
            _values = ArgParser.parse(Sys.args());
        }
        #end
    }

    public static function getROMArg(): String
    {
        initValues();

        #if js
        return "";
        #else
        return _values.has("rom")
            ? _values.get("rom").value
            : null;
        #end
    }

    public static function isFullscreen(): Bool
    {
        #if js
        return false;
        #else
        return _values.has("fullscreen");
        #end
    }

    public static function getCyclesPerFrame(): Int
    {
        var defaultValue = 6;
        #if html5
        return defaultValue;
        #else
        return _values.has("cyclesperframe")
            ? Std.parseInt(_values.get("cyclesperframe").value)
            : defaultValue;
        #end
    }
}