package;

import GameJolt;
import GameJolt.GameJoltAPI;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
#if mobile
import mobile.CopyState;
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = MainLoad; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // Wowwowoowowowowowowowowowowowowowowowow wtf dude, start with at least 120 FPS
	var skipSplash:Bool = true; // Hope we add this to the mod xd
	var startFullscreen:Bool = false; // N o
	public static var gjToastManager:GJToastManager; //Toast For Advice
	public static var fpsVar:FPS;

	public static var focusMusicTween:FlxTween;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		CrashHandler.init();

		#if windows
		@:functionCode("
		#include <windows.h>
		#include <winuser.h>
		setProcessDPIAware() // allows for more crisp visuals
		DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
		")
		#end
		
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		gjToastManager = new GJToastManager();
		addChild(gjToastManager); //adding the toddler
	
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(gameWidth, gameHeight, #if (mobile && MODS_ALLOWED) !CopyState.checkExistingFiles() ? CopyState : #end initialState, framerate, framerate, skipSplash, startFullscreen));

		fpsVar = new FPS(10, 3, 0xFFFFFF);
		#if !mobile
		addChild(fpsVar);
		#else
		FlxG.game.addChild(fpsVar);
		#end
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}

		FlxG.autoPause = false;
		FlxG.mouse.visible = false;

		#if mobile
		lime.system.System.allowScreenTimeout = ClientPrefs.screensaver;
		#if android
		FlxG.android.preventDefaultKeys = [BACK]; 
		#end
		#end

		//Application.current.window.onFocusOut.add(onWindowFocusOut);
		//Application.current.window.onFocusIn.add(onWindowFocusIn);
	}

	var game:FlxGame;
	var oldVol:Float = 1.0;
	var newVol:Float = 0.3;

	public static var focused:Bool = true;

	// funi Indie Cross volume code
	function onWindowFocusOut()
		{
			focused = false;
	
			// Lower global volume when unfocused
			if (Type.getClass(FlxG.state) != PlayState) // imagine stealing my code smh
			{
				oldVol = FlxG.sound.volume;
				if (oldVol > 0.3)
				{
					newVol = 0.3;
				}
				else
				{
					if (oldVol > 0.1)
					{
						newVol = 0.1;
					}
					else
					{
						newVol = 0;
					}
				}
	
				trace("Game unfocused");
	
				if (focusMusicTween != null)
					focusMusicTween.cancel();
				focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);
	
				// Conserve power by lowering draw framerate when unfocuced
				FlxG.drawFramerate = 60;
			}
		}

		public function onResize(width:Int, height:Int) { //bro too easy
			FlxG.resizeWindow(width, height);
		}
	
		function onWindowFocusIn()
		{
			new FlxTimer().start(0.2, function(tmr:FlxTimer)
			{
				focused = true;
			});
	
			// Lower global volume when unfocused
			if (Type.getClass(FlxG.state) != PlayState)
			{
				trace("Game focused");
	
				// Normal global volume when focused
				if (focusMusicTween != null)
					focusMusicTween.cancel();
	
				focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);
	
				// Bring framerate back when focused
				FlxG.drawFramerate = 60;
			}
		}

		/*function onCrash(e:UncaughtErrorEvent):Void
			{
				var errMsg:String = "";
				var path:String;
				var callStack:Array<StackItem> = CallStack.exceptionStack(true);
				var dateNow:String = Date.now().toString();
		
				dateNow = StringTools.replace(dateNow, " ", "_");
				dateNow = StringTools.replace(dateNow, ":", "'");
		
				path = "./crash/" + "FunkinAVI_" + dateNow + ".txt";
		
				errMsg = "Version: " + Lib.application.meta["version"] + "\n";
		
				for (stackItem in callStack)
				{
					switch (stackItem)
					{
						case FilePos(s, file, line, column):
							errMsg += file + " (line " + line + ")\n";
						default:
							Sys.println(stackItem);
					}
				}
		
				errMsg += "\nUncaught Error: " + e.error + "\nReport the error here: https://discord.gg/cZydhxFYpp";
		
				if (!FileSystem.exists("./crash/"))
					FileSystem.createDirectory("./crash/");
		
				File.saveContent(path, errMsg + "\n");
		
				Sys.println(errMsg);
				Sys.println("Crash dump saved in " + Path.normalize(path));
		
				var crashDialoguePath:String = "FlixelCrashHandler";
		
				#if windows
				crashDialoguePath += ".exe";
				#end
		
				if (FileSystem.exists("./" + crashDialoguePath))
				{
					Sys.println("Found crash dialog: " + crashDialoguePath);
		
					#if linux
					crashDialoguePath = "./" + crashDialoguePath;
					#end
					new Process(crashDialoguePath, [path]);
				}
				else
				{
					Sys.println("No crash dialog found! Making a simple alert instead...");
					Application.current.window.alert(errMsg, "Error!");
				}
		
				Sys.exit(1);
			}*/
}
	
