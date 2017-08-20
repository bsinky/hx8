package emu;

#if html5
import js.Browser;
#end

class Util
{
    public static function log(message:String): Void
    {
        #if html5
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

    public static function rValue(rgb:UInt): Int
    {
        return (rgb & 0xFF0000) >> 16;
    }

    public static function gValue(rgb:UInt): Int
    {
        return (rgb & 0x00FF00) >> 8;
    }

    public static function bValue(rgb:UInt): Int
    {
        return (rgb & 0x0000FF);
    }
}