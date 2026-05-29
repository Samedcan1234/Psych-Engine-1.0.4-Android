package backend;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import openfl.media.Sound;
import flixel.FlxG;
import flixel.sound.FlxSound;
import backend.VoicePreset;

class VoiceSystem {
	public static inline var ROOT_MODS_PATH:String = "mods/";
	public static inline var GLOBAL_VOICES_PATH:String = "mods/characters/sounds/voices/";
	public static inline var GLOBAL_SF2_PATH:String = "mods/characters/sounds/sf2/";
	public static inline var GLOBAL_SAMPLES_PATH:String = "mods/characters/sounds/samples/";

	public static var activePresets:Map<String, VoicePresetData> = new Map();
	public static var availablePresets:Array<VoicePresetData> = [];
	public static var availableSF2Files:Array<String> = [];

	static var cachedSamples:Map<String, Sound> = new Map();

	public static function init():Void {
		trace("[VoiceSystem] Initializing...");
		activePresets = new Map();
		scanPresets();
		scanSF2Files();
		trace("[VoiceSystem] Found " + availablePresets.length + " presets");
		trace("[VoiceSystem] Found " + availableSF2Files.length + " SF2 files");
	}

	public static function scanPresets():Void {
		availablePresets = [];
		var usedNames:Map<String, Bool> = new Map();

		var defaultPreset = VoicePreset.getDefault();
		availablePresets.push(defaultPreset);
		usedNames.set(defaultPreset.name, true);

		var dirs = getVoiceDirectories();
		for (dir in dirs) {
			if (!FileSystem.exists(dir)) continue;

			var files = FileSystem.readDirectory(dir);
			for (file in files) {
				if (!StringTools.endsWith(file.toLowerCase(), ".json")) continue;

				var fullPath = Path.normalize(dir + "/" + file);
				var preset = loadPresetFromPath(fullPath);
				if (preset != null && preset.name != null && !usedNames.exists(preset.name)) {
					availablePresets.push(preset);
					usedNames.set(preset.name, true);
				}
			}
		}
	}

	public static function scanSF2Files():Void {
		availableSF2Files = [];
		var usedNames:Map<String, Bool> = new Map();

		var dirs = getSF2Directories();
		for (dir in dirs) {
			if (!FileSystem.exists(dir)) continue;

			var files = FileSystem.readDirectory(dir);
			for (file in files) {
				var lower = file.toLowerCase();
				if (!StringTools.endsWith(lower, ".sf2")) continue;

				if (!usedNames.exists(file)) {
					availableSF2Files.push(file);
					usedNames.set(file, true);
				}
			}
		}
	}

	static function getVoiceDirectories():Array<String> {
		var result:Array<String> = [];

		if (FileSystem.exists(GLOBAL_VOICES_PATH))
			result.push(GLOBAL_VOICES_PATH);

		if (FileSystem.exists(ROOT_MODS_PATH)) {
			var modDirs = FileSystem.readDirectory(ROOT_MODS_PATH);
			for (modDir in modDirs) {
				var fullModPath = ROOT_MODS_PATH + modDir;
				if (!FileSystem.isDirectory(fullModPath)) continue;

				var voiceDir = fullModPath + "/characters/sounds/voices";
				if (FileSystem.exists(voiceDir))
					result.push(voiceDir);
			}
		}

		return result;
	}

	static function getSF2Directories():Array<String> {
		var result:Array<String> = [];

		if (FileSystem.exists(GLOBAL_SF2_PATH))
			result.push(GLOBAL_SF2_PATH);

		if (FileSystem.exists(ROOT_MODS_PATH)) {
			var modDirs = FileSystem.readDirectory(ROOT_MODS_PATH);
			for (modDir in modDirs) {
				var fullModPath = ROOT_MODS_PATH + modDir;
				if (!FileSystem.isDirectory(fullModPath)) continue;

				var sf2Dir = fullModPath + "/characters/sounds/sf2";
				if (FileSystem.exists(sf2Dir))
					result.push(sf2Dir);
			}
		}

		return result;
	}

	public static function loadPresetFromPath(fullPath:String):VoicePresetData {
		if (!FileSystem.exists(fullPath)) {
			trace("[VoiceSystem] Preset file not found: " + fullPath);
			return null;
		}

		try {
			var content:String = File.getContent(fullPath);
			var json:Dynamic = Json.parse(content);

			var sampleMap:VoiceSampleMapping = null;
			if (json.samples != null) {
				var sm:Dynamic = json.samples;
				sampleMap = {};
				if (sm.left != null) sampleMap.left = Std.string(sm.left);
				if (sm.down != null) sampleMap.down = Std.string(sm.down);
				if (sm.up != null) sampleMap.up = Std.string(sm.up);
				if (sm.right != null) sampleMap.right = Std.string(sm.right);
			}

			var preset:VoicePresetData = {
				name: json.name != null ? json.name : "unnamed",
				displayName: json.displayName != null ? json.displayName : (json.name != null ? json.name : "Unnamed"),
				type: json.type != null ? json.type : "ogg",
				file: json.file != null ? json.file : "",
				bank: json.bank != null ? json.bank : 0,
				preset: json.preset != null ? json.preset : 0,
				transpose: json.transpose != null ? json.transpose : 0,
				volume: json.volume != null ? json.volume : 1.0,
				pan: json.pan != null ? json.pan : 0.0,
				noteMapping: {
					left: 60,
					down: 62,
					up: 64,
					right: 65
				},
				sustainMode: json.sustainMode != null ? json.sustainMode : "retrigger",
				retriggerRate: json.retriggerRate != null ? json.retriggerRate : 0.08,
				enabled: json.enabled != null ? json.enabled : true,
				description: json.description != null ? json.description : "",
				sourcePath: fullPath
			};

			if (sampleMap != null)
				preset.samples = sampleMap;

			if (json.noteMapping != null) {
				var nm:Dynamic = json.noteMapping;
				if (nm.left != null) preset.noteMapping.left = nm.left;
				if (nm.down != null) preset.noteMapping.down = nm.down;
				if (nm.up != null) preset.noteMapping.up = nm.up;
				if (nm.right != null) preset.noteMapping.right = nm.right;
			}

			trace("[VoiceSystem] Loaded preset: " + preset.displayName);
			return preset;
		}
		catch (e:Dynamic) {
			trace("[VoiceSystem] Error loading preset " + fullPath + ": " + e);
			return null;
		}
	}

	public static function setCharacterPreset(character:String, presetName:String):Void {
		for (p in availablePresets) {
			if (p.name == presetName) {
				activePresets.set(character, p);
				trace("[VoiceSystem] Set " + character + " voice to: " + p.displayName);
				return;
			}
		}

		trace("[VoiceSystem] Preset not found: " + presetName + ", using default");
		activePresets.set(character, VoicePreset.getDefault());
	}

	public static function getCharacterPreset(character:String):VoicePresetData {
		if (activePresets.exists(character)) {
			return activePresets.get(character);
		}
		return VoicePreset.getDefault();
	}

	// Geriye uyumluluk için ismi aynı bıraktık
	public static function isSF2Mode(character:String):Bool {
		var preset = getCharacterPreset(character);
		return (preset.type == "sf2" || preset.type == "sample") && preset.enabled;
	}

	public static function anySF2Active():Bool {
		for (key in activePresets.keys()) {
			if (isSF2Mode(key)) return true;
		}
		return false;
	}

	public static function getMidiNote(character:String, noteDirection:Int):Int {
		var preset = getCharacterPreset(character);
		var baseNote:Int = switch (noteDirection % 4) {
			case 0: preset.noteMapping.left;
			case 1: preset.noteMapping.down;
			case 2: preset.noteMapping.up;
			case 3: preset.noteMapping.right;
			default: 60;
		};
		return baseNote + preset.transpose;
	}

	public static function onNoteHit(character:String, noteDirection:Int, isSustain:Bool):Void {
		if (!isSF2Mode(character)) return;

		var preset = getCharacterPreset(character);

		switch (preset.type) {
			case "sample":
				if (!isSustain || preset.sustainMode == "retrigger") {
					triggerSample(preset, noteDirection);
				}

			case "sf2":
				var midiNote = getMidiNote(character, noteDirection);

				trace("[VoiceSystem] NOTE HIT -> "
					+ "char: " + character
					+ " | dir: " + noteDirection
					+ " | midi: " + midiNote
					+ " | sustain: " + isSustain
					+ " | sf2: " + preset.file
					+ " | bank: " + preset.bank
					+ " | program: " + preset.preset
				);

				if (!isSustain) {
					triggerSF2Note(preset, midiNote);
				} else if (preset.sustainMode == "retrigger") {
					triggerSF2Note(preset, midiNote);
				}

			default:
		}
	}

	public static function onNoteRelease(character:String, noteDirection:Int):Void {
		if (!isSF2Mode(character)) return;

		var preset = getCharacterPreset(character);
		if (preset.type == "sf2" && preset.sustainMode == "hold") {
			var midiNote = getMidiNote(character, noteDirection);
			releaseSF2Note(preset, midiNote);
		}
	}

	static function getSampleForDirection(preset:VoicePresetData, noteDirection:Int):String {
		if (preset.samples == null) return null;

		return switch (noteDirection % 4) {
			case 0: preset.samples.left;
			case 1: preset.samples.down;
			case 2: preset.samples.up;
			case 3: preset.samples.right;
			default: null;
		}
	}

	static function resolveSamplePath(preset:VoicePresetData, relativeFile:String):String {
		if (relativeFile == null || relativeFile.length < 1)
			return null;

		var rel = StringTools.replace(relativeFile, "\\", "/");
		var candidates:Array<String> = [];

		// direkt verilmiş tam relative path ise
		if (StringTools.startsWith(rel, "mods/") && FileSystem.exists(rel))
			return rel;

		if (preset.sourcePath != null) {
			var voiceDir = Path.directory(StringTools.replace(preset.sourcePath, "\\", "/"));

			// preset ile aynı modun samples klasörü
			candidates.push(Path.normalize(Path.join([voiceDir, "..", "samples", rel])));

			// aynı klasörden de dene
			candidates.push(Path.normalize(Path.join([voiceDir, rel])));
		}

		// global samples
		candidates.push(Path.normalize(Path.join([GLOBAL_SAMPLES_PATH, rel])));

		// tüm modlarda ara
		if (FileSystem.exists(ROOT_MODS_PATH)) {
			var modDirs = FileSystem.readDirectory(ROOT_MODS_PATH);
			for (modDir in modDirs) {
				var fullModPath = ROOT_MODS_PATH + modDir;
				if (!FileSystem.isDirectory(fullModPath)) continue;

				candidates.push(Path.normalize(Path.join([
					fullModPath,
					"characters",
					"sounds",
					"samples",
					rel
				])));
			}
		}

		for (candidate in candidates) {
			if (FileSystem.exists(candidate))
				return candidate;
		}

		trace("[VoiceSystem] Sample file not found: " + relativeFile);
		for (candidate in candidates)
			trace("[VoiceSystem] tried -> " + candidate);

		return null;
	}

	static function getCachedSample(fullPath:String):Sound {
		if (cachedSamples.exists(fullPath))
			return cachedSamples.get(fullPath);

		try {
			var snd = Sound.fromFile(fullPath);
			cachedSamples.set(fullPath, snd);
			return snd;
		}
		catch (e:Dynamic) {
			trace("[VoiceSystem] Failed to load sample: " + fullPath + " | " + e);
		}
		return null;
	}

	static function triggerSample(preset:VoicePresetData, noteDirection:Int):Void {
		var sampleFile = getSampleForDirection(preset, noteDirection);
		if (sampleFile == null) {
			trace("[VoiceSystem] No sample mapped for dir " + noteDirection + " on preset " + preset.name);
			return;
		}

		var fullPath = resolveSamplePath(preset, sampleFile);
		if (fullPath == null)
			return;

		var asset = getCachedSample(fullPath);
		if (asset == null)
			return;

		var snd = new FlxSound();
		snd.loadEmbedded(asset, false, true);
		snd.volume = preset.volume;
		snd.pan = preset.pan;

		if (FlxG.sound.list != null)
			FlxG.sound.list.add(snd);

		snd.play();

		trace("[SAMPLE TRIGGER] " + fullPath);
	}

	private static function triggerSF2Note(preset:VoicePresetData, midiNote:Int):Void {
		trace("[SF2 TRIGGER] file=" + preset.file
			+ " bank=" + preset.bank
			+ " preset=" + preset.preset
			+ " note=" + midiNote
			+ " vol=" + preset.volume
		);
	}

	private static function releaseSF2Note(preset:VoicePresetData, midiNote:Int):Void {
		trace("[SF2 RELEASE] note=" + midiNote);
	}

	public static function getPresetNames():Array<String> {
		var names:Array<String> = [];
		for (p in availablePresets) {
			names.push(p.name);
		}
		return names;
	}

	public static function getPresetDisplayNames():Array<String> {
		var names:Array<String> = [];
		for (p in availablePresets) {
			names.push(p.displayName);
		}
		return names;
	}

	public static function cleanup():Void {
		activePresets = new Map();
		cachedSamples = new Map();
		trace("[VoiceSystem] Cleaned up");
	}
}