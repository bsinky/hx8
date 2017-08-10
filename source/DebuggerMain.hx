package ;

import emu.CPU;
import emu.Args;

class DebuggerMain {
    public static function main() {
        new DebuggerMain();
    }

    public function new() {
        var romPath = Args.getROMArg();

        if (romPath == null)
        {
            Sys.println("--rom [path/to/rom] argument must be provided");
            Sys.exit(-1);
        }

        var chip8 = new CPU();
        chip8.loadGameFromPath(romPath);
        chip8.start();

        mainLoop(chip8);
    }

    private function mainLoop(chip8:CPU): Void
    {
        Sys.println("j to step, m to dump memory, x to quit");

        while (true)
        {
            var command = Sys.getChar(false);
            switch (command)
            {
                case 106: // j
                    step(chip8);
                case 120: // x
                    Sys.exit(0);
                case 109: // m
                    var location = getLine("Starting location");
                    var parsedLocation = Std.parseInt(location);
                    var length = getLine("Length of memory");
                    var parsedLength = Std.parseInt(length);

                    if (parsedLocation == null || parsedLength == null)
                    {
                        Sys.println("ERROR: Bad value");
                    }
                    else
                    {
                        Sys.println(chip8.memoryDump(parsedLocation, parsedLength));
                    }
                default:
                    trace('Pressed key of value: ${command}');
            }
        }
    }

    private function getLine(?message): String
    {
        if (message != null)
        {
            Sys.print('${message}: ');
        }

        return Sys.stdin().readLine();
    }

    private function step(chip8:CPU): Void
    {
        chip8.cycle();

        if (chip8.drawFlag)
        {
            // The debugger only shows the screen on command
            chip8.drawFlag = false;
        }

        // TODO: set keys?

        // TODO: waiting for key?

        // TODO: timers?
    }
}