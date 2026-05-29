package backend;

import openfl.utils.Assets;
import modcore.HybridModManager;
import modcore.ModAssetBridge;
import modcore.PolymodHandler;
import modcore.PsychModHandler;

import haxe.Json;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	static public var currentModDirectory:String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	private static var globalMods:Array<String> = [];

	public static var hybridInitialized:Bool = false;

	public static function initHybridSystem():Void
	{
		if (hybridInitialized) return;

		trace('[Mods] Hibrit mod sistemi başlatılıyor...');

		PsychModHandler.modsDirectory = getModsFolder();
		PsychModHandler.currentModDirectory = currentModDirectory;

		HybridModManager.init();

		HybridModManager.onModEnabled = function(mod) {
			trace('[Mods] Hibrit: Mod etkinleştirildi — ${mod.id}');

			updatedOnState = false;
		};

		HybridModManager.onModDisabled = function(mod) {
			trace('[Mods] Hibrit: Mod devre dışı — ${mod.id}');
			updatedOnState = false;
		};

		HybridModManager.onConflictDetected = function(conflict) {
			trace('[Mods] Hibrit: Çakışma tespit edildi — ${conflict.modAId} <-> ${conflict.modBId}: ${conflict.details}');
		};

		HybridModManager.onModsReloaded = function() {
			trace('[Mods] Hibrit: Modlar yeniden yüklendi');

			Paths.clearStoredMemory();
		};

		hybridInitialized = true;

		#if debug
		HybridModManager.debugPrintStatus();
		#end

		trace('[Mods] Hibrit mod sistemi başarıyla başlatıldı.');
	}

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods()
	{
		globalMods = [];
		for(mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			if(pack != null && pack.runsGlobally) globalMods.push(mod);
		}

		PsychModHandler.globalMods = globalMods.copy();

		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in Paths.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}

	public static function resolveModAsset(assetPath:String):String
	{
		if (hybridInitialized)
			return ModAssetBridge.resolveAssetPath(assetPath);

		return assetPath;
	}

	public static function isPolymodCompatible(?folder:String):Bool
	{
		if (folder == null) folder = currentModDirectory;
		if (folder == null || folder.length == 0) return false;

		return PolymodHandler.isPolymodCompatible(Paths.mods(folder));
	}

	public static function getModType(?folder:String):String
	{
		if (!hybridInitialized) return "PSYCH_ONLY";
		if (folder == null) folder = currentModDirectory;
		if (folder == null || folder.length == 0) return "UNKNOWN";

		var info = HybridModManager.getModInfo(folder);
		if (info == null) return "UNKNOWN";

		return switch(info.modType) {
			case PSYCH_ONLY: "PSYCH_ONLY";
			case POLYMOD_ONLY: "POLYMOD_ONLY";
			case HYBRID: "HYBRID";
		};
	}

	public static function generatePolymodTemplatesForAll():Int
	{
		if (!hybridInitialized) {
			trace('[Mods] Hibrit sistem başlatılmamış, şablon oluşturulamıyor.');
			return 0;
		}
		return HybridModManager.generatePolymodTemplates();
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if(defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}

		#if POLYMOD_SUPPORT
		if (hybridInitialized && PolymodHandler.initialized)
		{
			var polymodMerged = ModAssetBridge.mergeTextAssets(path, HybridModManager.activeMods);
			if (polymodMerged != null)
			{
				var polyLines = polymodMerged.split("\n");
				for (pLine in polyLines)
				{
					var trimmed = pLine.trim();
					if (trimmed.length > 0 && (allowDuplicates || !mergedList.contains(trimmed)))
						mergedList.push(trimmed);
				}
			}
		}
		#end

		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		if(FileSystem.exists(path + fileToFind))
			foldersToCheck.push(path + fileToFind);

		if(Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if(!foldersToCheck.contains(pth) && FileSystem.exists(pth))
				foldersToCheck.push(pth);
		}

		#if MODS_ALLOWED
		if(mods)
		{
			for(mod in Mods.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}

			var folder:String = Paths.mods(fileToFind);
			if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));

			if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}

			#if POLYMOD_SUPPORT
			if (hybridInitialized)
			{
				for (mod in HybridModManager.activeMods)
				{
					if (mod.modType == POLYMOD_ONLY)
					{
						var polyFolder:String = '${mod.path}/$fileToFind';
						if (FileSystem.exists(polyFolder) && !foldersToCheck.contains(polyFolder))
							foldersToCheck.push(polyFolder);
					}
				}
			}
			#end
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic
	{
		#if MODS_ALLOWED
		if(folder == null) folder = Mods.currentModDirectory;

		var path = Paths.mods(folder + '/pack.json');
		if(FileSystem.exists(path)) {
			try {
				#if sys
				var rawJson:String = File.getContent(path);
				#else
				var rawJson:String = Assets.getText(path);
				#end

				if(rawJson != null && rawJson.length > 0)
				{
					try {
						return tjson.TJSON.parse(rawJson);
					} catch(jsonError:Dynamic) {
						trace('[Mods] Invalid pack.json in $folder: $jsonError');
						SafeLoader.failedMods.push(folder);
						return null;
					}
				}
			} catch(e:Dynamic) {
				trace('[Mods] Error reading pack.json for $folder: $e');
				SafeLoader.failedMods.push(folder);
			}
		}

		#if POLYMOD_SUPPORT
		if (hybridInitialized)
		{
			var polyMeta = PolymodHandler.readPolymodMeta(Paths.mods(folder));
			if (polyMeta != null)
			{
				return {
					name: polyMeta.title,
					description: polyMeta.description,
					author: polyMeta.author,
					version: polyMeta.modVersion,
					runsGlobally: false,
					color: [170, 0, 255]
				};
			}
		}
		#end
		#end
		return null;
	}

	public static function getExtendedPack(?folder:String = null):Dynamic
	{
		if (folder == null) folder = currentModDirectory;
		if (folder == null || folder.length == 0) return null;

		var pack = getPack(folder);

		#if POLYMOD_SUPPORT
		if (hybridInitialized)
		{
			var polyMeta = PolymodHandler.readPolymodMeta(Paths.mods(folder));
			if (polyMeta != null)
			{
				if (pack == null)
				{
					pack = {
						name: polyMeta.title,
						description: polyMeta.description,
						author: polyMeta.author,
						version: polyMeta.modVersion,
						runsGlobally: false,
						color: [170, 0, 255]
					};
				}

				Reflect.setField(pack, "polymod", {
					apiVersion: polyMeta.apiVersion,
					modVersion: polyMeta.modVersion,
					dependencies: polyMeta.dependencies
				});
				Reflect.setField(pack, "isHybrid", true);
			}
		}
		#end

		return pack;
	}

	private static function getModsListPath():String
	{
		var customPath:String = ClientPrefs.data.modsPath;
		trace('[Mods] getModsListPath — modsPath: "' + customPath + '"');
		if (customPath != null && customPath.trim().length > 0)
			return haxe.io.Path.addTrailingSlash(customPath) + 'modsList.txt';

		#if android
		return StorageUtil.getExternalStorageDirectory() + 'modsList.txt';
		#else
		return Sys.getCwd() + 'modsList.txt';
		#end
	}

	public static function getModsFolder(?subfolder:String = null):String
	{
		#if (android || ios)
		var base:String = StorageUtil.getModsDirectory();
		#else
		var base:String = 'mods/';
		#end
		if (subfolder != null && subfolder.length > 0)
			return base + subfolder;
		return base;
	}

	public static var updatedOnState:Bool = false;

	public static function parseList():ModsList
	{
		if(!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try {
			var modsListPath = getModsListPath();

			if (!FileSystem.exists(modsListPath))
			{
				trace('[Mods] modsList.txt not found, returning empty list');
				return list;
			}

			for (mod in CoolUtil.coolTextFile(modsListPath))
			{
				if(mod.trim().length < 1) continue;
				var dat = mod.split("|");

				var modFolder = dat[0];
				if (!FileSystem.exists(Paths.mods(modFolder)) || !FileSystem.isDirectory(Paths.mods(modFolder)))
				{
					trace('[Mods] Mod folder not found, skipping: $modFolder');
					continue;
				}

				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
			}
		} catch(e:Dynamic) {
			trace('[Mods] Error parsing modsList: $e');
			SafeLoader.createCrashFlag("ModsList parse error: " + Std.string(e));
		}
		#end

		if (hybridInitialized)
		{
			syncWithHybridManager(list);
		}

		return list;
	}

	private static function syncWithHybridManager(list:ModsList):Void
	{

		for (mod in HybridModManager.allMods)
		{
			if (!list.all.contains(mod.id))
			{

				list.all.push(mod.id);
				if (mod.enabled)
					list.enabled.push(mod.id);
				else
					list.disabled.push(mod.id);
			}
		}

		for (mod in HybridModManager.allMods)
		{
			mod.enabled = list.enabled.contains(mod.id);
		}

		HybridModManager.activeMods = HybridModManager.allMods.filter(m -> m.enabled);
	}

	private static function updateModList()
	{
		#if MODS_ALLOWED
		var modsListPath:String = getModsListPath();
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];

		try {
			for (mod in CoolUtil.coolTextFile(modsListPath))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if(folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		} catch(e) {
			trace(e);
		}

		for (folder in getModDirectories())
		{
			if(folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) &&
			!ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]);
			}
		}

		#if POLYMOD_SUPPORT
		if (hybridInitialized)
		{
			for (mod in HybridModManager.allMods)
			{
				if (mod.modType == POLYMOD_ONLY && !added.contains(mod.id))
				{
					added.push(mod.id);
					list.push([mod.id, mod.enabled]);
				}
			}
		}
		#end

		var fileStr:String = '';
		for (values in list)
		{
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		var modsListDir:String = haxe.io.Path.directory(modsListPath);
		if (modsListDir.length > 0 && !FileSystem.exists(modsListDir))
		{
			try { FileSystem.createDirectory(modsListDir); }
			catch (e:Dynamic) { trace('[Mods] Dizin oluşturulamadı: $modsListDir | $e'); }
		}

		try
		{
			File.saveContent(modsListPath, fileStr);
		}
		catch (e:Dynamic)
		{
			trace('[Mods] modsList.txt yazılamadı: $modsListPath | $e');
		}
		updatedOnState = true;
		#end
	}

	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if(list != null && list[0] != null)
			Mods.currentModDirectory = list[0];
		#end

		PsychModHandler.currentModDirectory = currentModDirectory;

		if (hybridInitialized && currentModDirectory.length > 0)
		{
			HybridModManager.setCurrentMod(currentModDirectory);
		}
	}

	public static function switchMod(modFolder:String):Void
	{
		currentModDirectory = modFolder;
		PsychModHandler.currentModDirectory = modFolder;

		if (hybridInitialized)
		{
			HybridModManager.setCurrentMod(modFolder);
			trace('[Mods] Mod değiştirildi (hibrit): $modFolder | Tip: ${getModType(modFolder)}');
		}
		else
		{
			trace('[Mods] Mod değiştirildi (klasik): $modFolder');
		}
	}

	public static function enableMod(modFolder:String):Bool
	{
		if (hybridInitialized)
		{
			var result = HybridModManager.enableMod(modFolder);
			if (result) updatedOnState = false;
			return result;
		}
		return false;
	}

	public static function disableMod(modFolder:String):Bool
	{
		if (hybridInitialized)
		{
			var result = HybridModManager.disableMod(modFolder);
			if (result) updatedOnState = false;
			return result;
		}
		return false;
	}

	public static function getConflictReport():Array<modcore.ModConflictResolver.ModConflict>
	{
		if (!hybridInitialized) return [];
		return HybridModManager.getConflictReport();
	}

	public static function clearHybridCache():Void
	{
		if (hybridInitialized)
		{
			ModAssetBridge.clearCache();
			trace('[Mods] Hibrit asset cache temizlendi.');
		}
	}
}