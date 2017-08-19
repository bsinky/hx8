package;

import emu.CPU;
import emu.Args;
import emu.Keyboard;

import lime.ui.Window;
#if native
import emu.Util;
import lime.ui.FileDialog;
#elseif html5
import haxe.io.Bytes;
import js.Browser;
import js.html.Uint8Array;
import js.html.InputElement;
import js.html.FileReader;
#end
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.app.Application;
import lime.graphics.Renderer;

class Main extends Application
{
    private var keys:Map<Int, Bool>;
    #if native
    private var romFilePath:String;
    private var fileDialog:FileDialog;
    #elseif html5
    private var fileOpenButton:InputElement;
    private var lastLoadedROMBytes:Bytes;
    #end
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

    public function new ()
    {
        chip8KeyMap = new Map<Int, Int>();        
        keys = new Map<Int, Bool>();

        #if native
        fileDialog = new FileDialog();
        fileDialog.onSelect.add(handleFileBrowse);
        #elseif html5
        initDOMElements();
        #end

        // Initialize key map
        for (i in 0...chip8Keys.length)
        {
            chip8KeyMap.set(chip8Keys[i], i);
        }

        myChip8 = new CPU();

        #if native
        romFilePath = Args.getROMArg();
        cyclesPerFrame = Args.getCyclesPerFrame();
        #elseif html5
        cyclesPerFrame = Args.DEFAULT_CYCLES_PER_FRAME;
        #end
        
        resetChip8();

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
                #if native
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
        switch (renderer.context)
        {
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
        step = 0;
        myChip8.initialize();

        #if native
        if (romFilePath != null)
        {
            Util.log('Loading ${romFilePath}');

            myChip8.loadGameFromPath(romFilePath);
            myChip8.start();	
        }
        #elseif html5
        if (lastLoadedROMBytes != null)
        {
            myChip8.loadGame(lastLoadedROMBytes);
            myChip8.start();
        }
        #end
    }

    #if native
    private function handleFileBrowse(selectedFile:String): Void
    {
        romFilePath = selectedFile;
        resetChip8();
    }
    #elseif html5
    private function initDOMElements(): Void
    {
        Browser.document.addEventListener("DOMContentLoaded", function(event)
        {
            // Select ROM button
            fileOpenButton = Browser.document.createInputElement();
            fileOpenButton.setAttribute("type", "file");
            fileOpenButton.setAttribute("value", "Open ROM");
            fileOpenButton.setAttribute("id", "OpenROM");
            fileOpenButton.style.position = "fixed";
            fileOpenButton.style.bottom = "0";
            fileOpenButton.addEventListener("change", handleFileOpen, false);
            Browser.document.body.appendChild(fileOpenButton);

            // Cycles per frame selector
            var cyclesPerFrameSelect = Browser.document.createSelectElement();
            cyclesPerFrameSelect.id = "cyclesperframe";
            var cyclesPerFramePossibleValues = [
                6,
                15,
                20,
                30,
                100,
                200,
                500,
                1000
            ];
            for (cyclesValue in cyclesPerFramePossibleValues)
            {
                cyclesPerFrameSelect.options.add(createOptionElement(Std.string(cyclesValue), '${cyclesValue} Cycles/Frame'));
            }
            cyclesPerFrameSelect.addEventListener("change", function ()
            {
                var newCyclesValue = Std.parseInt(cyclesPerFrameSelect.value);
                if (newCyclesValue != null)
                {
                    cyclesPerFrame = newCyclesValue;
                }
            }, false);
            cyclesPerFrameSelect.style.position = "fixed";
            cyclesPerFrameSelect.style.bottom = "0";
            cyclesPerFrameSelect.style.left = "25%";
            Browser.document.body.appendChild(cyclesPerFrameSelect);
        });
    }

    private function createOptionElement(value:String, text:String): js.html.OptionElement
    {
        var newOption = Browser.document.createOptionElement();
        newOption.value = value;
        newOption.text = text;
        return newOption;
    }

    private function handleFileOpen(event:js.html.Event):Void
    {
        if (untyped event.target.files[0])
        {
            var selectedFile = untyped event.target.files[0];
            var reader = new FileReader();
            reader.onload = function(){
                var arrayBuffer = reader.result;
                var byteArray = new Uint8Array(arrayBuffer);
                var bytes:Bytes = Bytes.alloc(byteArray.length);
                
                for (i in 0...byteArray.length)
                {
                    bytes.set(i, byteArray[i]);
                }
                
                lastLoadedROMBytes = bytes;
                resetChip8();
            };
            reader.readAsArrayBuffer(selectedFile);
        }
    }
    #end
}