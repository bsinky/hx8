hx8 ~ Haxe Chip-8 Emulator
==========================

hx8 is a simple Chip-8 emulator/interpreter written in [Haxe](http://haxe.org/), with [HaxeFlixel](http://haxeflixel.com/) as the Input/Graphics framework.

Usage
-----

```bash
hx8 --rom /path/to/rom [--cyclesperframe X]
```

Compiling
---------

Assuming you have `lime-tools` installed and the `lime` alias set up:

```bash
lime build Project.xml <target>
```

The only tested target is Linux (Fedora 25), other desktop targets (Windows, OS X) should work theory.

An HTML5 target is in the works (html5-target branch).

Contributing
------------

Pull requests are welcome!