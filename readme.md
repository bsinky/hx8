hx8 ~ Haxe Chip-8 Emulator
==========================

hx8 is a simple Chip-8 emulator/interpreter written in [Haxe](http://haxe.org/), with [HaxeFlixel](http://haxeflixel.com/) as the Input/Graphics framework.

Usage
-----

Currently, the rom must be provided from the command line when launching the program.

```bash
hx8 --rom /path/to/rom [--cyclesperframe X]
```

Controls
--------

`ESC` to quit.

`G` to reset.

`P` to change the palette colors.

`I` to invert the colors of the current palette.

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

The only tested target is Linux (Fedora 25), other desktop targets (Windows, OS X) should work theory.

An HTML5 target is in the works (html5-target branch).

License
-------

This project is licensed under the MIT License.  Full terms may be found in the LICENSE file.

Contributing
------------

Pull requests are welcome!