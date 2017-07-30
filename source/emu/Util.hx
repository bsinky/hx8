package emu;

class Util
{
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
}