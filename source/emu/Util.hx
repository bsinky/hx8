package emu;

class Util
{
    public static inline function log(message:String):Void
    {
        #if debug
        trace(message);
        #end
    }
}