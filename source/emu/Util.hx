package emu;

#if js
import js.Browser;
#end

class Util
{
    public static function log(message:String): Void
    {
        #if js
        Browser.window.console.log(message);
        #else
        Sys.println(message);
        #end
    }

    public static inline function cpuLog(message:String): Void
    {
        #if debugCPU
        trace(message);
        #end
    }

    public static inline function keysLog(keysMap:Map<Int,Bool>): Void
    {
        #if debugKeys
        for (keyIndex in keysMap.keys())
        {
            trace('${keyIndex}: ${keysMap[keyIndex]}');
        }
        #end
    }

    public static inline function displayLog(display:Display): Void
    {
        #if debugDisplay
        trace(display.toString());
        #end
    }

    public static function alphaValue(argb:UInt): Int
    {
        return (argb & 0xFF000000) >> 24;
    }

    public static function rValue(argb:UInt): Int
    {
        return (argb & 0x00FF0000) >> 16;
    }

    public static function gValue(argb:UInt): Int
    {
        return (argb & 0x0000FF00) >> 8;
    }

    public static function bValue(argb:UInt): Int
    {
        return (argb & 0x000000FF);
    }
}