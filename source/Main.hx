package;

import backend.SafeLoader;
import backend.ThemeManager;

import backend.RecordingSystem;
import ui.RecordingHUD;

import objects.AlertMgr;
import backend.ServerAlertSystem;
import debug.FPSCounter;
import backend.Highscore;
import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end
import mobile.backend.MobileScaleMode;
import lime.system.System as LimeSystem;

#if (linux || mac)
import lime.graphics.Image;
#end
#if COPYSTATE_ALLOWED
import states.CopyState;
#end

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

class Main extends Sprite
{
    public static final game = {
        width: 1280,
        height: 720,
        initialState: TitleState,
        framerate: 60,
        skipSplash: true,
        startFullscreen: false
    };

    public static var fpsVar:FPSCounter;

    public static var recordingHUD:RecordingHUD;

    public static final platform:String = #if mobile "Phones" #else "PCs" #end;

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
        super();

        #if sys
        trace('[Main] Initializing SafeLoader...');
        try {
            SafeLoader.setupExceptionHandler();
            var initSuccess = SafeLoader.init();

            if (SafeLoader.safeMode)
            {
                trace('[Main] ⚠️ SAFE MODE ACTIVE - Mods have been disabled due to previous crash');
                trace('[Main] Crash reason: ${SafeLoader.lastCrashReason}');
                if (SafeLoader.failedMods.length > 0)
                    trace('[Main] Failed mods: ${SafeLoader.failedMods.join(", ")}');
            }
            else if (initSuccess)
            {
                trace('[Main] SafeLoader initialized successfully');
            }
        } catch(e:Dynamic) {
            trace('[Main] ⚠️ SafeLoader init failed: $e');
            trace('[Main] Attempting emergency recovery...');
            try {
                SafeLoader.resetModsList();
                SafeLoader.safeMode = true;
            } catch(e2:Dynamic) {
                trace('[Main] Emergency recovery failed: $e2');
            }
        }
        #end

        #if mobile
        #if android
        StorageUtil.requestPermissions();
        #end
        Sys.setCwd(StorageUtil.getStorageDirectory());
        #end

        backend.CrashHandler.init();

        #if (cpp && windows)
        backend.Native.fixScaling();
        #end

        #if VIDEOS_ALLOWED
        hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
        #end

        #if LUA_ALLOWED
        if (!SafeLoader.safeMode)
            Mods.pushGlobalMods();
        #end

        if (!SafeLoader.safeMode)
            Mods.loadTopMod();
        else {
            Mods.currentModDirectory = '';
            trace('[Main] Skipping mod loading due to safe mode');
        }

        FlxG.save.bind('funkin', CoolUtil.getSavePath());
        Highscore.load();

        #if HSCRIPT_ALLOWED
        Iris.warn = function(x, ?pos:haxe.PosInfos) {
            Iris.logLevel(WARN, x, pos);
            var newPos:HScriptInfos = cast pos;
            if (newPos.showLine == null) newPos.showLine = true;
            var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
            #if LUA_ALLOWED
            if (newPos.isLua == true) {
                msgInfo += 'HScript:';
                newPos.showLine = false;
            }
            #end
            if (newPos.showLine == true)
                msgInfo += '${newPos.lineNumber}:';
            msgInfo += ' $x';
            if (PlayState.instance != null)
                PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
        }
        Iris.error = function(x, ?pos:haxe.PosInfos) {
            Iris.logLevel(ERROR, x, pos);
            var newPos:HScriptInfos = cast pos;
            if (newPos.showLine == null) newPos.showLine = true;
            var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
            #if LUA_ALLOWED
            if (newPos.isLua == true) {
                msgInfo += 'HScript:';
                newPos.showLine = false;
            }
            #end
            if (newPos.showLine == true)
                msgInfo += '${newPos.lineNumber}:';
            msgInfo += ' $x';
            if (PlayState.instance != null)
                PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
        }
        Iris.fatal = function(x, ?pos:haxe.PosInfos) {
            Iris.logLevel(FATAL, x, pos);
            var newPos:HScriptInfos = cast pos;
            if (newPos.showLine == null) newPos.showLine = true;
            var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
            #if LUA_ALLOWED
            if (newPos.isLua == true) {
                msgInfo += 'HScript:';
                newPos.showLine = false;
            }
            #end
            if (newPos.showLine == true)
                msgInfo += '${newPos.lineNumber}:';
            msgInfo += ' $x';
            if (PlayState.instance != null)
                PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);

            #if sys
            SafeLoader.createCrashFlag("HScript Fatal: " + x);
            #end
        }
        #end

        #if LUA_ALLOWED
        Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
        #end

        Controls.instance = new Controls();
        ClientPrefs.loadDefaultKeys();

        #if ACHIEVEMENTS_ALLOWED
        Achievements.load();
        #end

        #if mobile
        FlxG.signals.postGameStart.addOnce(() -> {
            FlxG.scaleMode = new MobileScaleMode();
        });
        #end

        MobileData.init();
        trace('[DEBUG] dpadModes keys: ' + [for (k in MobileData.dpadModes.keys()) k]);
        trace('[DEBUG] Shared path: ' + Paths.getSharedPath('mobile/DPadModes'));

        addChild(new FlxGame(
            game.width, game.height,
            #if COPYSTATE_ALLOWED !CopyState.checkExistingFiles() ? CopyState : #end game.initialState,
            game.framerate, game.framerate,
            game.skipSplash, game.startFullscreen
        ));

        fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
        addChild(fpsVar);

        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        Lib.current.stage.addChild(new AlertMgr());

        trace('[Main] ServerAlertSystem init çağrılıyor...');
        ServerAlertSystem.init();
        trace('[Main] ServerAlertSystem init tamamlandı');

        if (fpsVar != null)
            fpsVar.visible = ClientPrefs.data.showFPS;

        #if (linux || mac)
        var icon = Image.fromFile("icon.png");
        Lib.current.stage.window.setIcon(icon);
        #end

        #if html5
        FlxG.autoPause = false;
        FlxG.mouse.visible = false;
        #end

        FlxG.fixedTimestep = false;
        FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;

        #if web
        FlxG.keys.preventDefaultKeys.push(TAB);
        #else
        FlxG.keys.preventDefaultKeys = [TAB];
        #end

        #if DISCORD_ALLOWED
        DiscordClient.prepare();
        #end

        #if desktop
        FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
        #end

        #if mobile
        #if android
        FlxG.android.preventDefaultKeys = [BACK];
        #end
        LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
        #end

        Application.current.window.vsync = ClientPrefs.data.vsync;

        #if desktop
        Lib.application.window.onClose.add(function() {

            if (RecordingSystem.isRecording)
            {
                trace('[Main] Uygulama kapanıyor, kayıt durduruluyor...');
                RecordingSystem.stopRecording();
            }

            #if sys
            trace('[Main] Clean exit - clearing crash flag');
            SafeLoader.onCleanExit();
            #end
        });
        #end

        FlxG.signals.gameResized.add(function(w, h) {
            if (fpsVar != null)
                fpsVar.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));

            if (FlxG.cameras != null) {
                for (cam in FlxG.cameras.list) {
                    if (cam != null && cam.filters != null)
                        resetSpriteCache(cam.flashSprite);
                }
            }

            if (FlxG.game != null)
                resetSpriteCache(FlxG.game);
        });

        _initRecordingSystem();
    }

    function _initRecordingSystem():Void
    {

        recordingHUD = new RecordingHUD();
        Lib.current.stage.addChild(recordingHUD);

        Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, _onGlobalKeyDown);

        Lib.current.stage.addEventListener(Event.ENTER_FRAME, _onEnterFrame);

        trace('[Main] ✓ Recording sistemi hazır! (F12 ile başlat/durdur)');
    }

    function _onGlobalKeyDown(e:KeyboardEvent):Void
    {

        if (e.keyCode == 123)
            _toggleRecording();
    }

    function _onEnterFrame(e:Event):Void
    {

        if (RecordingSystem.isRecording)
            RecordingSystem.captureFrame();
    }

	function _toggleRecording():Void
	{
		if (RecordingSystem.isRecording)
		{
			RecordingSystem.stopRecording();
			recordingHUD.hideREC();

			// Kayıt bitti callback - dosya yolunu göster
			RecordingSystem.onRecordingFinished = function(path:String)
			{
				recordingHUD.showError('✓ Kaydedildi:\n$path');
				trace('[Main] Kayıt tamamlandı: $path');
			};

			trace('[Main] Kayıt durduruluyor...');
		}
		else
		{
			var spec:String = "Balanced";
			try {
				if (ClientPrefs.data != null && ClientPrefs.data.recordingSpec != null)
					spec = Std.string(ClientPrefs.data.recordingSpec);
			} catch (e:Dynamic) {
				spec = "Balanced";
			}

			// Callback'i başlamadan önce ayarla
			RecordingSystem.onRecordingFinished = function(path:String)
			{
				recordingHUD.showError('✓ Kaydedildi:\n$path');
			};

			var success:Bool = RecordingSystem.startRecording(spec);

			if (success)
				recordingHUD.showREC();
			else
				recordingHUD.showError("Kayıt başlatılamadı!");
		}
	}

    static function resetSpriteCache(sprite:Sprite):Void {
        @:privateAccess {
            sprite.__cacheBitmap = null;
            sprite.__cacheBitmapData = null;
        }
    }

    function _onKeyUp(event:KeyboardEvent):Void
    {

        if (Controls.instance.justReleased('fullscreen'))
            FlxG.fullscreen = !FlxG.fullscreen;
    }
}