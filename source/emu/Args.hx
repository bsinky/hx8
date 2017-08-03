package emu;

import arguable.ArgParser;

class Args
{
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
}