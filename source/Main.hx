package;

import emu.CPU;
import emu.Args;
import emu.Util;
import emu.Keyboard;

import lime.ui.Window;
import lime.ui.FileDialog;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.app.Application;
import lime.graphics.Renderer;

class Main extends Application
{
    private var keys:Map<Int, Bool>;
    private var fileDialog:FileDialog;
    private var myChip8:CPU;
    private var chip8Renderer:emu.Renderer;
    private var step:Int;
    private var cyclesPerFrame:Int;
    private var chip8KeyMap:Map<Int, Int>;
    private var chip8Keys = [
        Keyboard.X, 	// 0
        Keyboard.ONE,	// 1
        Keyboard.TWO,	// 2
        Keyboard.THREE,	// 3
        Keyboard.Q,     // 4
        Keyboard.W,     // 5
        Keyboard.E, 	// 6
        Keyboard.A, 	// 7
        Keyboard.S, 	// 8
        Keyboard.D, 	// 9
        Keyboard.Z,		// A
        Keyboard.C,		// B
        Keyboard.FOUR,	// C
        Keyboard.R,		// D
        Keyboard.F,		// E
        Keyboard.V		// F
    ];
    private var romFilePath:String;

    public function new ()
    {
        chip8KeyMap = new Map<Int, Int>();        
        keys = new Map<Int, Bool>();

        fileDialog = new FileDialog();
        fileDialog.onSelect.add(handleFileBrowse);

        // Initialize key map
        for (i in 0...chip8Keys.length)
        {
            chip8KeyMap.set(chip8Keys[i], i);
        }

        myChip8 = new CPU();

        romFilePath = Args.getROMArg();		
        
        resetChip8();

        cyclesPerFrame = Args.getCyclesPerFrame();

        chip8Renderer = new emu.Renderer(myChip8.screen);

        super();		
    }

    public override function onWindowResize(window:Window, width:Int, height:Int):Void
    {
        resizeRenderer(width, height);
    }

    public override function onWindowCreate(window:Window):Void
    {
        resizeRenderer(window.width, window.height);
    }

    private function resizeRenderer(windowWidth:Int, windowHeight:Int):Void
    {
        chip8Renderer.scale = Math.min(windowWidth / chip8Renderer.width, windowHeight / chip8Renderer.height);
    }

    public override function onKeyDown (window:Window, keyCode:KeyCode, modifier:KeyModifier): Void
    {
        keys.set(keyCode, true);

        if (myChip8.isWaitingForKey)
        {
            var chip8KeyCode = chip8KeyMap.get(keyCode);
            myChip8.setKey(chip8KeyCode);
            myChip8.start();
        }
    }

    public override function onKeyUp (window:Window, keyCode:KeyCode, modifier:KeyModifier): Void
    {
        switch (keyCode)
        {
            // Reset key
            case Keyboard.G:
                resetChip8();

            // Change palette
            case Keyboard.P:
                chip8Renderer.swapPalette();

            // Invert palette
            case Keyboard.I:
                chip8Renderer.invertPalette();
            
            // Exit key
            case Keyboard.ESCAPE:
                #if !html5
                Sys.exit(0);
                #end
        
            // Open file key
            case Keyboard.O:
                #if (cpp||neko)
                myChip8.stop();
                fileDialog.browse(lime.ui.FileDialogType.OPEN, null, null, "Select ROM");
                #end

            default:
                keys.set(keyCode, false);
        }
    }

    override public function update(delta:Int):Void
    {
        for (x in 0...cyclesPerFrame)
        {
            myChip8.cycle();
        }

        var keyStates = [
            for (i in 0...chip8Keys.length)
            {
                i => keys.get(chip8Keys[i]);
            }
        ];

        myChip8.setKeys(keyStates);

        if (step++ % 2 == 0)
        {
            myChip8.handleTimers();
        }
        
        super.update(delta);
    }
    
    public override function render (renderer:Renderer):Void
    {
        switch (renderer.context) {
            
            case CAIRO (cairo):
                chip8Renderer.drawCairo(cairo);
            
            case CANVAS (context):
                chip8Renderer.drawCanvas(context);
            
            case DOM (element):
                throw "DOM rendering not supported";
            
            case FLASH (sprite):
                throw "Flash rendering not supported";
            
            case OPENGL (gl):
                throw "OpenGL rendering not supported";
            
            default:
        }
    }

    private function resetChip8(): Void
    {
        myChip8.initialize();

        if (romFilePath != null)
        {
            Util.log('Loading ${romFilePath}');

            myChip8.loadGameFromPath(romFilePath);
            myChip8.start();	
        }
    }

    private function handleFileBrowse(selectedFile:String): Void {
        romFilePath = selectedFile;
        resetChip8();
    }
}