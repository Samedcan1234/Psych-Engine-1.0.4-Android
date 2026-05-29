package psychton;

import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import sys.thread.Thread;
import sys.thread.Deque;

import haxe.Json;
import haxe.io.Path;
import haxe.io.Eof;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

using StringTools;

class PythonScript
{
	public var scriptPath:String;
	public var scriptName:String;
	public var closed:Bool = false;

	private var pythonProcess:Process = null;

	private var stdoutQueue:Deque<String>;
	private var stderrQueue:Deque<String>;
	private var readerThreadsStarted:Bool = false;

	private var activeTimers:Map<String, FlxTimer> = new Map();

	public static var pythonScripts:Array<PythonScript> = [];

	#if windows
	public static var pythonPath:String = "python";
	#else
	public static var pythonPath:String = "python";
	#end

	public function new(path:String)
	{
		scriptPath = path;
		scriptName = Path.withoutDirectory(path);

		if (!FileSystem.exists(path))
		{
			trace('[PythonScript] Script bulunamadı: $path');
			closed = true;
			return;
		}

		trace('[PythonScript] Yükleniyor: $scriptName');
		pythonScripts.push(this);
		initPythonBridge();
	}

	private function initPythonBridge():Void
	{
		try
		{
			var bridgePath = createBridgeScript();

			stdoutQueue = new Deque<String>();
			stderrQueue = new Deque<String>();

			pythonProcess = new Process(pythonPath, [bridgePath, scriptPath]);
			startReaderThreads();

			trace('[PythonScript] Python process başlatıldı: $scriptName');
		}
		catch (e:Dynamic)
		{
			trace('[PythonScript] Python başlatma hatası: $e');
			closed = true;
		}
	}

	private function createBridgeScript():String
	{
		if (!FileSystem.exists("mods"))
			FileSystem.createDirectory("mods");

		var bridgePath = "mods/pybridge_temp.py";
		File.saveContent(bridgePath, getBridgeCode());
		return bridgePath;
	}

	private function getBridgeCode():String
	{
		return '
import sys
import json
import threading
import queue
import time
import traceback

_response_queue = queue.Queue()
_event_queue = queue.Queue()

class PsychEngine:
    def _send(self, cmd, args):
        msg = json.dumps({"cmd": cmd, "args": args}, ensure_ascii=False)
        print("__PSCMD__" + msg + "__PSEND__", flush=True)

    def _read_response(self, timeout=2.0):
        try:
            return _response_queue.get(timeout=timeout)
        except Exception:
            return None

    def debugPrint(self, text, color=None):
        self._send("debugPrint", {"text": str(text), "color": color})

    def setProperty(self, variable, value):
        self._send("setProperty", {"variable": variable, "value": value})

    def getProperty(self, variable):
        self._send("getProperty", {"variable": variable})
        return self._read_response()

    def setSpriteProperty(self, tag, variable, value):
        self._send("setSpriteProperty", {"tag": tag, "variable": variable, "value": value})

    def makeLuaSprite(self, tag, image=None, x=0, y=0):
        self._send("makeLuaSprite", {"tag": tag, "image": image, "x": x, "y": y})

    def makeAnimatedLuaSprite(self, tag, image=None, x=0, y=0):
        self._send("makeAnimatedLuaSprite", {"tag": tag, "image": image, "x": x, "y": y})

    def addLuaSprite(self, tag, front=False):
        self._send("addLuaSprite", {"tag": tag, "front": front})

    def removeLuaSprite(self, tag, destroy=True):
        self._send("removeLuaSprite", {"tag": tag, "destroy": destroy})

    def setGraphicSize(self, tag, width, height=0):
        self._send("setGraphicSize", {"tag": tag, "width": width, "height": height})

    def scaleObject(self, tag, x, y, updateHitbox=True):
        self._send("scaleObject", {"tag": tag, "x": x, "y": y, "updateHitbox": updateHitbox})

    def updateHitbox(self, tag):
        self._send("updateHitbox", {"tag": tag})

    def setScrollFactor(self, tag, x, y):
        self._send("setScrollFactor", {"tag": tag, "x": x, "y": y})

    def screenCenter(self, tag, axis="xy"):
        self._send("screenCenter", {"tag": tag, "axis": axis})

    def setObjectCamera(self, tag, camera="game"):
        self._send("setObjectCamera", {"tag": tag, "camera": camera})

    def addAnimation(self, tag, name, frames, framerate=24, loop=True):
        self._send("addAnimation", {"tag": tag, "name": name, "frames": frames, "framerate": framerate, "loop": loop})

    def addAnimationByPrefix(self, tag, name, prefix, framerate=24, loop=True):
        self._send("addAnimationByPrefix", {"tag": tag, "name": name, "prefix": prefix, "framerate": framerate, "loop": loop})

    def playAnim(self, tag, name, forced=False, reverse=False, startFrame=0):
        self._send("playAnim", {"tag": tag, "name": name, "forced": forced, "reverse": reverse, "startFrame": startFrame})

    def makeLuaText(self, tag, text, width, x=0, y=0):
        self._send("makeLuaText", {"tag": tag, "text": text, "width": width, "x": x, "y": y})

    def addLuaText(self, tag):
        self._send("addLuaText", {"tag": tag})

    def removeLuaText(self, tag, destroy=True):
        self._send("removeLuaText", {"tag": tag, "destroy": destroy})

    def setTextString(self, tag, text):
        self._send("setTextString", {"tag": tag, "text": text})

    def setTextSize(self, tag, size):
        self._send("setTextSize", {"tag": tag, "size": size})

    def setTextColor(self, tag, color):
        self._send("setTextColor", {"tag": tag, "color": color})

    def playSound(self, sound, volume=1.0):
        self._send("playSound", {"sound": sound, "volume": volume})

    def playMusic(self, music, volume=1.0, loop=False):
        self._send("playMusic", {"music": music, "volume": volume, "loop": loop})

    def doTweenX(self, tag, vars, value, duration, ease="linear"):
        self._send("doTweenX", {"tag": tag, "vars": vars, "value": value, "duration": duration, "ease": ease})

    def doTweenY(self, tag, vars, value, duration, ease="linear"):
        self._send("doTweenY", {"tag": tag, "vars": vars, "value": value, "duration": duration, "ease": ease})

    def doTweenAlpha(self, tag, vars, value, duration, ease="linear"):
        self._send("doTweenAlpha", {"tag": tag, "vars": vars, "value": value, "duration": duration, "ease": ease})

    def doTweenAngle(self, tag, vars, value, duration, ease="linear"):
        self._send("doTweenAngle", {"tag": tag, "vars": vars, "value": value, "duration": duration, "ease": ease})

    def runTimer(self, tag, timeValue, loops=1):
        self._send("runTimer", {"tag": tag, "time": timeValue, "loops": loops})

    def cancelTimer(self, tag):
        self._send("cancelTimer", {"tag": tag})

    def characterPlayAnim(self, character, anim, forced=False):
        self._send("characterPlayAnim", {"character": character, "anim": anim, "forced": forced})

    def characterDance(self, character):
        self._send("characterDance", {"character": character})

    def cameraShake(self, camera, intensity, duration):
        self._send("cameraShake", {"camera": camera, "intensity": intensity, "duration": duration})

    def cameraFlash(self, camera, color, duration, forced=False):
        self._send("cameraFlash", {"camera": camera, "color": color, "duration": duration, "forced": forced})

    def cameraFade(self, camera, color, duration, forced=False):
        self._send("cameraFade", {"camera": camera, "color": color, "duration": duration, "forced": forced})

    def triggerEvent(self, name, value1="", value2=""):
        self._send("triggerEvent", {"name": name, "value1": value1, "value2": value2})

    def setVar(self, name, value):
        self._send("setVar", {"name": name, "value": value})

    def getVar(self, name):
        self._send("getVar", {"name": name})
        return self._read_response()

    def close(self):
        self._send("close", {})

engine = PsychEngine()

script_globals = {
    "engine": engine,

    "debugPrint": engine.debugPrint,
    "setProperty": engine.setProperty,
    "getProperty": engine.getProperty,
    "setSpriteProperty": engine.setSpriteProperty,

    "makeLuaSprite": engine.makeLuaSprite,
    "makeAnimatedLuaSprite": engine.makeAnimatedLuaSprite,
    "addLuaSprite": engine.addLuaSprite,
    "removeLuaSprite": engine.removeLuaSprite,
    "setGraphicSize": engine.setGraphicSize,
    "scaleObject": engine.scaleObject,
    "updateHitbox": engine.updateHitbox,
    "setScrollFactor": engine.setScrollFactor,
    "screenCenter": engine.screenCenter,
    "setObjectCamera": engine.setObjectCamera,
    "addAnimation": engine.addAnimation,
    "addAnimationByPrefix": engine.addAnimationByPrefix,
    "playAnim": engine.playAnim,

    "makeLuaText": engine.makeLuaText,
    "addLuaText": engine.addLuaText,
    "removeLuaText": engine.removeLuaText,
    "setTextString": engine.setTextString,
    "setTextSize": engine.setTextSize,
    "setTextColor": engine.setTextColor,

    "playSound": engine.playSound,
    "playMusic": engine.playMusic,

    "doTweenX": engine.doTweenX,
    "doTweenY": engine.doTweenY,
    "doTweenAlpha": engine.doTweenAlpha,
    "doTweenAngle": engine.doTweenAngle,

    "runTimer": engine.runTimer,
    "cancelTimer": engine.cancelTimer,

    "characterPlayAnim": engine.characterPlayAnim,
    "characterDance": engine.characterDance,

    "cameraShake": engine.cameraShake,
    "cameraFlash": engine.cameraFlash,
    "cameraFade": engine.cameraFade,

    "triggerEvent": engine.triggerEvent,
    "setVar": engine.setVar,
    "getVar": engine.getVar
}

def stdin_reader():
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                _event_queue.put(("__quit__", []))
                return

            line = line.strip()

            if line.startswith("__PSRES__"):
                data = line[9:]
                if data.endswith("__PSEND__"):
                    data = data[:-9]
                try:
                    _response_queue.put(json.loads(data))
                except Exception:
                    _response_queue.put(None)

            elif line.startswith("__PSEVT__"):
                data = line[9:]
                if data.endswith("__PSEND__"):
                    data = data[:-9]
                try:
                    evt = json.loads(data)
                    _event_queue.put((evt.get("event", ""), evt.get("args", [])))
                except Exception:
                    pass

            elif line == "__PSQUIT__":
                _event_queue.put(("__quit__", []))
                return

        except Exception:
            _event_queue.put(("__quit__", []))
            return

threading.Thread(target=stdin_reader, daemon=True).start()

script_path = sys.argv[1]

try:
    with open(script_path, "r", encoding="utf-8") as f:
        script_code = f.read()
    compiled = compile(script_code, script_path, "exec")
    exec(compiled, script_globals)
except Exception as e:
    engine.debugPrint("Python Error: " + str(e), "0xFFFF0000")
    print("__PSERR__" + traceback.format_exc().replace("\\n", " | ") + "__PSEND__", flush=True)

if "onCreate" in script_globals and callable(script_globals["onCreate"]):
    try:
        script_globals["onCreate"]()
    except Exception as e:
        engine.debugPrint("Python onCreate Error: " + str(e), "0xFFFF0000")
        print("__PSERR__" + traceback.format_exc().replace("\\n", " | ") + "__PSEND__", flush=True)

while True:
    try:
        evt_name, evt_args = _event_queue.get(timeout=0.1)

        if evt_name == "__quit__":
            break

        if evt_name in script_globals and callable(script_globals[evt_name]):
            try:
                script_globals[evt_name](*evt_args)
            except Exception as e:
                engine.debugPrint("Python Callback Error (" + str(evt_name) + "): " + str(e), "0xFFFF0000")
                print("__PSERR__" + traceback.format_exc().replace("\\n", " | ") + "__PSEND__", flush=True)

    except queue.Empty:
        pass
    except KeyboardInterrupt:
        break
    except Exception:
        pass
';
	}

	private function startReaderThreads():Void
	{
		if (pythonProcess == null || readerThreadsStarted) return;
		readerThreadsStarted = true;

		var proc = pythonProcess;
		var self = this;

		Thread.create(function()
		{
			try
			{
				while (!self.closed)
				{
					var line = proc.stdout.readLine();
					if (line == null) break;
					self.stdoutQueue.add(line);
				}
			}
			catch (e:Eof) {}
			catch (e:Dynamic)
			{
				if (!self.closed) self.stderrQueue.add('[stdout-thread] ' + Std.string(e));
			}
		});

		Thread.create(function()
		{
			try
			{
				while (!self.closed)
				{
					var line = proc.stderr.readLine();
					if (line == null) break;
					self.stderrQueue.add(line);
				}
			}
			catch (e:Eof) {}
			catch (e:Dynamic)
			{
				if (!self.closed) self.stderrQueue.add('[stderr-thread] ' + Std.string(e));
			}
		});
	}

	public function update(elapsed:Float):Void
	{
		if (closed) return;
		drainQueues();
	}

	private function drainQueues():Void
	{
		if (stdoutQueue != null)
		{
			while (true)
			{
				var line = stdoutQueue.pop(false);
				if (line == null) break;
				processOutputLine(line);
			}
		}

		if (stderrQueue != null)
		{
			while (true)
			{
				var err = stderrQueue.pop(false);
				if (err == null) break;
				trace('[PythonScript][$scriptName][stderr] $err');
			}
		}
	}

	private function processOutputLine(line:String):Void
	{
		if (line == null || line.length < 1) return;

		if (line.indexOf("__PSCMD__") != -1)
		{
			var startIdx = line.indexOf("__PSCMD__") + 9;
			var endIdx = line.indexOf("__PSEND__");
			if (endIdx == -1) endIdx = line.length;

			var jsonStr = line.substring(startIdx, endIdx);
			try
			{
				var data:Dynamic = Json.parse(jsonStr);
				executeCommand(Std.string(data.cmd), data.args);
			}
			catch (e:Dynamic)
			{
				trace('[PythonScript] JSON parse hatası: $e | Satır: $line');
			}
		}
		else if (line.indexOf("__PSERR__") != -1)
		{
			var startIdx = line.indexOf("__PSERR__") + 9;
			var endIdx = line.indexOf("__PSEND__");
			if (endIdx == -1) endIdx = line.length;
			var errMsg = line.substring(startIdx, endIdx);
			trace('[PythonScript] Python Error: $errMsg');
		}
		else
		{
			trace('[PythonScript][$scriptName] $line');
		}
	}

	private function executeCommand(cmd:String, args:Dynamic):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		switch (cmd)
		{
			case "debugPrint":
				#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
				game.addTextToDebug(
					Std.string(args.text),
					args.color != null ? Std.parseInt(Std.string(args.color)) : FlxColor.WHITE
				);
				#else
				trace('[Python] ' + Std.string(args.text));
				#end

			case "makeLuaSprite":
				makeLuaSprite(Std.string(args.tag), args.image != null ? Std.string(args.image) : null, getFloat(args.x), getFloat(args.y));

			case "makeAnimatedLuaSprite":
				makeAnimatedLuaSprite(Std.string(args.tag), args.image != null ? Std.string(args.image) : null, getFloat(args.x), getFloat(args.y));

			case "addLuaSprite":
				addLuaSprite(Std.string(args.tag), getBool(args.front));

			case "removeLuaSprite":
				removeLuaSprite(Std.string(args.tag), args.destroy == null ? true : getBool(args.destroy));

			case "setGraphicSize":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
				{
					spr.setGraphicSize(Std.int(getFloat(args.width)), Std.int(getFloat(args.height)));
					spr.updateHitbox();
				}

			case "scaleObject":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
				{
					spr.scale.set(getFloat(args.x, 1), getFloat(args.y, 1));
					if (args.updateHitbox == null || getBool(args.updateHitbox)) spr.updateHitbox();
				}

			case "updateHitbox":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null) spr.updateHitbox();

			case "setScrollFactor":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null) spr.scrollFactor.set(getFloat(args.x, 1), getFloat(args.y, 1));

			case "screenCenter":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null) spr.screenCenter();

			case "setObjectCamera":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
				{
					var camName:String = args.camera != null ? Std.string(args.camera).toLowerCase() : "game";
					switch (camName)
					{
						case "hud", "camhud":
							spr.cameras = [game.camHUD];
						case "other", "camother":
							spr.cameras = [game.camOther];
						default:
							spr.cameras = [game.camGame];
					}
				}

			case "addAnimation":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
				{
					spr.animation.add(
						Std.string(args.name),
						cast args.frames,
						Std.int(getFloat(args.framerate, 24)),
						args.loop == null ? true : getBool(args.loop)
					);
				}

			case "addAnimationByPrefix":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
				{
					spr.animation.addByPrefix(
						Std.string(args.name),
						Std.string(args.prefix),
						Std.int(getFloat(args.framerate, 24)),
						args.loop == null ? true : getBool(args.loop)
					);
				}

			case "playAnim":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
				{
					spr.animation.play(
						Std.string(args.name),
						getBool(args.forced),
						getBool(args.reverse),
						Std.int(getFloat(args.startFrame))
					);
				}

			case "makeLuaText":
				makeLuaText(
					Std.string(args.tag),
					Std.string(args.text),
					Std.int(getFloat(args.width)),
					getFloat(args.x),
					getFloat(args.y)
				);

			case "addLuaText":
				addLuaText(Std.string(args.tag));

			case "removeLuaText":
				removeLuaText(Std.string(args.tag), args.destroy == null ? true : getBool(args.destroy));

			case "setTextString":
				var obj:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (obj != null && Std.isOfType(obj, FlxText))
					cast(obj, FlxText).text = Std.string(args.text);

			case "setTextSize":
				var obj:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (obj != null && Std.isOfType(obj, FlxText))
					cast(obj, FlxText).size = Std.int(getFloat(args.size, 16));

			case "setTextColor":
				var obj:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (obj != null && Std.isOfType(obj, FlxText))
					cast(obj, FlxText).color = Std.parseInt(Std.string(args.color));

			case "setProperty":
				setProperty(Std.string(args.variable), args.value);

			case "getProperty":
				sendResponse(getProperty(Std.string(args.variable)));

			case "setSpriteProperty":
				var spr:Dynamic = game.getLuaObject(Std.string(args.tag));
				if (spr != null)
					Reflect.setProperty(spr, Std.string(args.variable), args.value);

			case "playSound":
				FlxG.sound.play(Paths.sound(Std.string(args.sound)), getFloat(args.volume, 1));

			case "playMusic":
				FlxG.sound.playMusic(Paths.music(Std.string(args.music)), getFloat(args.volume, 1), getBool(args.loop));

			case "doTweenX":
				var target = resolveTweenTarget(Std.string(args.vars));
				if (target != null) FlxTween.tween(target, {x: getFloat(args.value)}, getFloat(args.duration), {ease: getEase(args.ease != null ? Std.string(args.ease) : "linear")});

			case "doTweenY":
				var target = resolveTweenTarget(Std.string(args.vars));
				if (target != null) FlxTween.tween(target, {y: getFloat(args.value)}, getFloat(args.duration), {ease: getEase(args.ease != null ? Std.string(args.ease) : "linear")});

			case "doTweenAlpha":
				var target = resolveTweenTarget(Std.string(args.vars));
				if (target != null) FlxTween.tween(target, {alpha: getFloat(args.value)}, getFloat(args.duration), {ease: getEase(args.ease != null ? Std.string(args.ease) : "linear")});

			case "doTweenAngle":
				var target = resolveTweenTarget(Std.string(args.vars));
				if (target != null) FlxTween.tween(target, {angle: getFloat(args.value)}, getFloat(args.duration), {ease: getEase(args.ease != null ? Std.string(args.ease) : "linear")});

			case "cameraShake":
				var cam = getCamera(args.camera != null ? Std.string(args.camera) : "game");
				if (cam != null) cam.shake(getFloat(args.intensity), getFloat(args.duration));

			case "cameraFlash":
				var cam = getCamera(args.camera != null ? Std.string(args.camera) : "game");
				if (cam != null) cam.flash(Std.parseInt(Std.string(args.color)), getFloat(args.duration), null, getBool(args.forced));

			case "cameraFade":
				var cam = getCamera(args.camera != null ? Std.string(args.camera) : "game");
				if (cam != null) cam.fade(Std.parseInt(Std.string(args.color)), getFloat(args.duration), false, null, getBool(args.forced));

			case "characterPlayAnim":
				characterPlayAnim(Std.string(args.character), Std.string(args.anim), getBool(args.forced));

			case "characterDance":
				characterDance(Std.string(args.character));

			case "runTimer":
				runTimerInternal(Std.string(args.tag), getFloat(args.time), Std.int(getFloat(args.loops, 1)));

			case "cancelTimer":
				cancelTimerInternal(Std.string(args.tag));

			case "setVar":
				game.variables.set(Std.string(args.name), args.value);

			case "getVar":
				sendResponse(game.variables.get(Std.string(args.name)));

			case "triggerEvent":
				var v1:String = args.value1 != null ? Std.string(args.value1) : "";
				var v2:String = args.value2 != null ? Std.string(args.value2) : "";
				game.triggerEvent(Std.string(args.name), v1, v2, 0.0);

			case "close":
				close();

			default:
				trace('[PythonScript] Bilinmeyen komut: $cmd');
		}
	}

	private function resolveTweenTarget(name:String):Dynamic
	{
		var game = states.PlayState.instance;
		if (game == null) return null;

		var obj:Dynamic = game.getLuaObject(name);
		if (obj != null) return obj;

		switch (name.toLowerCase())
		{
			case "dad", "opponent": return game.dad;
			case "bf", "boyfriend": return game.boyfriend;
			case "gf", "girlfriend": return game.gf;
			case "camgame", "game": return game.camGame;
			case "camhud", "hud": return game.camHUD;
			case "camother", "other": return game.camOther;
		}

		try
		{
			return Reflect.field(game, name);
		}
		catch (e:Dynamic) {}

		return null;
	}

	private function getCamera(name:String):FlxCamera
	{
		var game = states.PlayState.instance;
		if (game == null) return FlxG.camera;

		switch (name.toLowerCase())
		{
			case "hud", "camhud":
				return game.camHUD;
			case "other", "camother":
				return game.camOther;
			default:
				return game.camGame;
		}
	}

	private function getEase(ease:String):Float->Float
	{
		switch (ease.toLowerCase())
		{
			case "linear": return FlxEase.linear;
			case "quadin": return FlxEase.quadIn;
			case "quadout": return FlxEase.quadOut;
			case "quadinout": return FlxEase.quadInOut;
			case "cubein": return FlxEase.cubeIn;
			case "cubeout": return FlxEase.cubeOut;
			case "cubeinout": return FlxEase.cubeInOut;
			case "quartin": return FlxEase.quartIn;
			case "quartout": return FlxEase.quartOut;
			case "quartinout": return FlxEase.quartInOut;
			case "sinein": return FlxEase.sineIn;
			case "sineout": return FlxEase.sineOut;
			case "sineinout": return FlxEase.sineInOut;
			case "bouncein": return FlxEase.bounceIn;
			case "bounceout": return FlxEase.bounceOut;
			case "bounceinout": return FlxEase.bounceInOut;
			case "backin": return FlxEase.backIn;
			case "backout": return FlxEase.backOut;
			case "backinout": return FlxEase.backInOut;
			case "elasticin": return FlxEase.elasticIn;
			case "elasticout": return FlxEase.elasticOut;
			case "elasticinout": return FlxEase.elasticInOut;
			default: return FlxEase.linear;
		}
	}

	private function getFloat(v:Dynamic, defaultValue:Float = 0):Float
	{
		if (v == null) return defaultValue;
		var f:Float = Std.parseFloat(Std.string(v));
		return Math.isNaN(f) ? defaultValue : f;
	}

	private function getBool(v:Dynamic, defaultValue:Bool = false):Bool
	{
		if (v == null) return defaultValue;
		if (Std.isOfType(v, Bool)) return v;
		var s = Std.string(v).toLowerCase().trim();
		return s == "true" || s == "1";
	}

	private function setProperty(variable:String, value:Dynamic):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		try
		{
			var split:Array<String> = variable.split(".");
			if (split.length > 1)
			{
				var obj:Dynamic = Reflect.getProperty(game, split[0]);
				for (i in 1...split.length - 1)
					obj = Reflect.getProperty(obj, split[i]);
				Reflect.setProperty(obj, split[split.length - 1], value);
			}
			else
			{
				Reflect.setProperty(game, variable, value);
			}
		}
		catch (e:Dynamic)
		{
			trace('[PythonScript] setProperty hatası: $e');
		}
	}

	private function getProperty(variable:String):Dynamic
	{
		var game = states.PlayState.instance;
		if (game == null) return null;

		try
		{
			var split:Array<String> = variable.split(".");
			if (split.length > 1)
			{
				var obj:Dynamic = Reflect.getProperty(game, split[0]);
				for (i in 1...split.length - 1)
					obj = Reflect.getProperty(obj, split[i]);
				return Reflect.getProperty(obj, split[split.length - 1]);
			}
			return Reflect.getProperty(game, variable);
		}
		catch (e:Dynamic)
		{
			trace('[PythonScript] getProperty hatası: $e');
		}
		return null;
	}

	private function makeLuaSprite(tag:String, ?image:String, x:Float = 0, y:Float = 0):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var spr = new FlxSprite(x, y);
		if (image != null && image.length > 0)
			spr.loadGraphic(Paths.image(image));

		game.variables.set(tag, spr);
	}

	private function makeAnimatedLuaSprite(tag:String, ?image:String, x:Float = 0, y:Float = 0):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var spr = new FlxSprite(x, y);
		if (image != null && image.length > 0)
			spr.frames = Paths.getSparrowAtlas(image);

		game.variables.set(tag, spr);
	}

	private function addLuaSprite(tag:String, front:Bool = false):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var spr:Dynamic = game.getLuaObject(tag);
		if (spr == null) return;

		if (front)
		{
			game.add(spr);
		}
		else
		{
			var idx = game.members.indexOf(game.uiGroup);
			if (idx < 0) game.add(spr);
			else game.insert(idx, spr);
		}
	}

	private function removeLuaSprite(tag:String, destroy:Bool = true):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var spr:Dynamic = game.getLuaObject(tag);
		if (spr == null) return;

		game.remove(spr, true);
		if (destroy)
		{
			spr.destroy();
			game.variables.remove(tag);
		}
	}

	private function makeLuaText(tag:String, text:String, width:Int, x:Float = 0, y:Float = 0):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var txt = new FlxText(x, y, width, text, 16);
		txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
		game.variables.set(tag, txt);
	}

	private function addLuaText(tag:String):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var txt:Dynamic = game.getLuaObject(tag);
		if (txt != null) game.add(txt);
	}

	private function removeLuaText(tag:String, destroy:Bool = true):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		var txt:Dynamic = game.getLuaObject(tag);
		if (txt == null) return;

		game.remove(txt, true);
		if (destroy)
		{
			txt.destroy();
			game.variables.remove(tag);
		}
	}

	private function characterPlayAnim(character:String, anim:String, forced:Bool = false):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		switch (character.toLowerCase())
		{
			case "dad", "opponent":
				if (game.dad != null) game.dad.playAnim(anim, forced);
			case "bf", "boyfriend":
				if (game.boyfriend != null) game.boyfriend.playAnim(anim, forced);
			case "gf", "girlfriend":
				if (game.gf != null) game.gf.playAnim(anim, forced);
		}
	}

	private function characterDance(character:String):Void
	{
		var game = states.PlayState.instance;
		if (game == null) return;

		switch (character.toLowerCase())
		{
			case "dad", "opponent":
				if (game.dad != null) game.dad.dance();
			case "bf", "boyfriend":
				if (game.boyfriend != null) game.boyfriend.dance();
			case "gf", "girlfriend":
				if (game.gf != null) game.gf.dance();
		}
	}

	private function runTimerInternal(tag:String, time:Float, loops:Int = 1):Void
	{
		cancelTimerInternal(tag);

		var timer = new FlxTimer();
		activeTimers.set(tag, timer);

		timer.start(time, function(tmr:FlxTimer)
		{
			callEvent("onTimerCompleted", [tag, tmr.loopsLeft]);
			if (tmr.finished) activeTimers.remove(tag);
		}, loops);
	}

	private function cancelTimerInternal(tag:String):Void
	{
		if (!activeTimers.exists(tag)) return;

		var timer = activeTimers.get(tag);
		if (timer != null)
		{
			timer.cancel();
			timer.destroy();
		}
		activeTimers.remove(tag);
	}

	public function callEvent(eventName:String, ?args:Array<Dynamic>):Void
	{
		if (closed || pythonProcess == null) return;

		var eventData = {
			event: eventName,
			args: args != null ? args : []
		};

		try
		{
			var jsonStr = Json.stringify(eventData);
			pythonProcess.stdin.writeString('__PSEVT__${jsonStr}__PSEND__\n');
			pythonProcess.stdin.flush();
		}
		catch (e:Dynamic)
		{
			trace('[PythonScript] Event gönderme hatası: $e');
		}
	}

	private function sendResponse(value:Dynamic):Void
	{
		if (closed || pythonProcess == null) return;

		try
		{
			var jsonStr = Json.stringify(value);
			pythonProcess.stdin.writeString('__PSRES__${jsonStr}__PSEND__\n');
			pythonProcess.stdin.flush();
		}
		catch (e:Dynamic)
		{
			trace('[PythonScript] Response gönderme hatası: $e');
		}
	}

	public function close():Void
	{
		if (closed) return;
		closed = true;

		for (timer in activeTimers)
		{
			if (timer != null)
			{
				timer.cancel();
				timer.destroy();
			}
		}
		activeTimers = new Map();

		if (pythonProcess != null)
		{
			try
			{
				pythonProcess.stdin.writeString("__PSQUIT__\n");
				pythonProcess.stdin.flush();
			}
			catch (e:Dynamic) {}

			try pythonProcess.kill() catch (e:Dynamic) {}
			try pythonProcess.close() catch (e:Dynamic) {}

			pythonProcess = null;
		}

		pythonScripts.remove(this);
		trace('[PythonScript] Kapatıldı: $scriptName');
	}

	public static function closeAll():Void
	{
		var arr = pythonScripts.copy();
		for (script in arr)
			if (script != null)
				script.close();

		pythonScripts = [];
	}

	public static function callEventAll(eventName:String, ?args:Array<Dynamic>):Void
	{
		for (script in pythonScripts)
			if (script != null && !script.closed)
				script.callEvent(eventName, args);
	}

	public static function updateAll(elapsed:Float):Void
	{
		for (script in pythonScripts)
			if (script != null && !script.closed)
				script.update(elapsed);
	}
}