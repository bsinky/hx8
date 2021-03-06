hx8 ~ Haxe Chip-8 Emulator
==========================

[![Build Status](https://travis-ci.org/bsinky/hx8.svg?branch=master)](https://travis-ci.org/bsinky/hx8) [![Build status](https://ci.appveyor.com/api/projects/status/lf2qkqal2tob1xme/branch/master?svg=true)](https://ci.appveyor.com/project/bsinky/hx8/branch/master)

hx8 is a simple Chip-8 emulator/interpreter written in [Haxe](http://haxe.org/), with [Lime](https://github.com/openfl/lime) as the Input/Graphics framework.

Usage
-----

When targeting `native`, `hx8` accepts a few (optional) CLI arguments.

```bash
hx8 [--rom /path/to/rom] [--cyclesperframe X]
```

`--rom` specifies a ROM to load at startup.

`--cyclesperframe` specifies how many CPU cycles will be run every update cycle.

Controls
--------

`ESC` to quit.

`G` to reset.

`P` to change the palette colors.

`I` to invert the colors of the current palette.

`O` to open the "Select ROM" dialog. **(only for native targets)**

The 16-button Chip-8 keyboard is mapped as follows:

```
[Chip-8]    [Keyboard]
0           X
1           1
2           2
3           3
4           Q
5           W
6           E
7           A
8           S
9           D
A           Z
B           C
C           4
D           R
E           F
F           V
```

Basically, the 4x4 block of 16 keys on the left half of a standard QWERTY keyboard makes up your Chip-8 keyboard.

Compiling
---------

First, install the required dependencies.  From the project root directory:

```bash
haxelib install dependencies.hxml
```

Then to compile, assuming you have `lime-tools` installed and the `lime` alias set up:

```bash
lime build Project.xml <target>
```

Current targets are:
 * `linux` using Lime's Cairo software renderer (tested on Fedora 25), other desktop targets (Windows, OS X) should work theory
 * `html5` using canvas rendering - you can try this target in your browser right now, [here](http://bsinky.github.io/hx8)!

License
-------

This project is licensed under the MIT License.  Full terms may be found in the LICENSE file.

Contributing
------------

Pull requests are welcome!

TODO
----

* ~~ROM File open dialog~~ "File" menu with "Open..." option
* Additional targets (Android, ???)