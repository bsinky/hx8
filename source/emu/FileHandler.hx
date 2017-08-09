package emu;

import haxe.io.Bytes;

import lime.app.Event;
import lime.ui.FileDialog;

class FileHandler
{
	public static function openFile(selectCallback:Event<String> -> Void): Void
	{
        var dialog = new FileDialog();
        dialog.onSelect = handleSelect;
        dialog.open(null, null, "Select ROM");
	}
}