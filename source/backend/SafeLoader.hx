package backend;

import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flash.media.Sound;
import haxe.CallStack;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef CrashReport = {
    var timestamp:String;
    var reason:String;
    var stackTrace:String;
    var failedMods:Array<String>;
    var failedAssets:Array<String>;
    var systemInfo:SystemInfo;
}

typedef SystemInfo = {
    var platform:String;
    var haxeVersion:String;
    var flixelVersion:String;
    var openflVersion:String;
    var totalRAM:Float;
    var freeRAM:Float;
}

class SafeLoader
{
    private static var CRASH_FLAG_FILE:String = "CRASH_FLAG";
    private static var CRASH_LOG_FILE:String = "crash_log.txt";
    private static var CRASH_REPORT_FILE:String = "crash_report.json";
    private static var SAFE_MODE_FILE:String = "SAFE_MODE";
    private static var RECOVERY_LOG_FILE:String = "recovery_log.txt";
    
    public static var safeMode:Bool = false;
    public static var lastCrashReason:String = "";
    public static var failedAssets:Array<String> = [];
    public static var failedMods:Array<String> = [];
    public static var crashHistory:Array<CrashReport> = [];
    
    private static var errorCount:Int = 0;
    private static var maxErrorsBeforeRecovery:Int = 5;
    private static var consecutiveCrashes:Int = 0;
    private static var maxConsecutiveCrashes:Int = 3;
    
    public static var autoRecoveryEnabled:Bool = true;
    public static var verboseLogging:Bool = #if debug true #else false #end;

    public static function init():Bool
    {
        #if sys
        if (verboseLogging) trace('[SafeLoader] Initializing crash recovery system...');
        
        loadCrashHistory();
        
        var crashFlagPath = getCrashFlagPath();
        var safeModePath = getSafeModePath();
        
        if (FileSystem.exists(safeModePath))
        {
            trace('[SafeLoader] Safe mode file detected - entering safe mode');
            safeMode = true;
            disableAllMods();
            logRecovery("Entered safe mode (forced)");
            return true;
        }
        
        if (FileSystem.exists(crashFlagPath))
        {
            trace('[SafeLoader] Previous session crashed!');
            consecutiveCrashes++;
            
            var crashData:String = "";
            try {
                crashData = File.getContent(crashFlagPath);
                lastCrashReason = crashData;
                trace('[SafeLoader] Crash reason: ' + lastCrashReason);
            } catch(e:Dynamic) {
                trace('[SafeLoader] Could not read crash flag: ' + e);
            }
            
            try { 
                FileSystem.deleteFile(crashFlagPath); 
            } catch(e:Dynamic) {}
            
            analyzeCrashAndRecover(crashData);
            createCrashReport(crashData);
            
            if (consecutiveCrashes >= maxConsecutiveCrashes)
            {
                trace('[SafeLoader] TOO MANY CRASHES! Emergency mode...');
                emergencyRecovery();
                return true;
            }
        }
        else
        {
            consecutiveCrashes = 0;
        }
        
        createCrashFlag("Session started normally");
        
        if (!safeMode && autoRecoveryEnabled)
        {
            validateAllMods();
        }
        
        trace('[SafeLoader] Initialization complete. Safe mode: ' + safeMode);
        #end
        return true;
    }
    
    private static function analyzeCrashAndRecover(crashData:String):Void
    {
        #if sys
        if (!autoRecoveryEnabled) return;
        
        var modRelated = isModRelatedCrash(crashData);
        var assetRelated = isAssetRelatedCrash(crashData);
        var memoryRelated = isMemoryRelatedCrash(crashData);
        var scriptRelated = isScriptRelatedCrash(crashData);
        
        if (modRelated || scriptRelated)
        {
            safeMode = true;
            disableAllMods();
            logRecovery("Auto-recovery: Mods disabled");
        }
        else if (memoryRelated)
        {
            reduceQualitySettings();
            logRecovery("Auto-recovery: Quality reduced");
        }
        else if (assetRelated)
        {
            clearAssetCache();
            logRecovery("Auto-recovery: Cache cleared");
        }
        else if (consecutiveCrashes >= 2)
        {
            safeMode = true;
            disableAllMods();
            logRecovery("Auto-recovery: Mods disabled (repeated crash)");
        }
        #end
    }
    
    private static function isModRelatedCrash(data:String):Bool
    {
        if (data == null) return false;
        var lower = data.toLowerCase();
        return lower.indexOf("mods/") != -1 || lower.indexOf(".lua") != -1 || lower.indexOf("hscript") != -1;
    }
    
    private static function isAssetRelatedCrash(data:String):Bool
    {
        if (data == null) return false;
        var lower = data.toLowerCase();
        return lower.indexOf("bitmapdata") != -1 || lower.indexOf("assets") != -1 || lower.indexOf("file not found") != -1;
    }
    
    private static function isMemoryRelatedCrash(data:String):Bool
    {
        if (data == null) return false;
        var lower = data.toLowerCase();
        return lower.indexOf("out of memory") != -1 || lower.indexOf("allocation") != -1 || lower.indexOf("heap") != -1;
    }
    
    private static function isScriptRelatedCrash(data:String):Bool
    {
        if (data == null) return false;
        var lower = data.toLowerCase();
        return lower.indexOf("script") != -1 || lower.indexOf("lua error") != -1 || lower.indexOf("null object") != -1;
    }
    
    private static function emergencyRecovery():Void
    {
        #if sys
        trace('[SafeLoader] EMERGENCY RECOVERY!');
        
        safeMode = true;
        disableAllMods();
        
        try {
            FlxG.save.erase();
            FlxG.save.bind('funkin', CoolUtil.getSavePath());
            ClientPrefs.loadDefaultKeys();
        } catch(e:Dynamic) {}
        
        clearAssetCache();
        
        try {
            File.saveContent(getSafeModePath(), "EMERGENCY MODE\n" + Date.now().toString());
        } catch(e:Dynamic) {}
        
        logRecovery("EMERGENCY RECOVERY COMPLETE");
        #end
    }
    
    private static function reduceQualitySettings():Void
    {
        #if sys
        try {
            ClientPrefs.data.lowQuality = true;
            ClientPrefs.data.shaders = false;
            ClientPrefs.data.cacheOnGPU = false;
            ClientPrefs.data.antialiasing = false;
            ClientPrefs.saveSettings();
        } catch(e:Dynamic) {}
        #end
    }
    
	private static function clearAssetCache():Void
	{
		try {
			@:privateAccess {
				if (FlxG.bitmap != null && FlxG.bitmap._cache != null)
					FlxG.bitmap.clearCache();
			}
			
			// FlxG.sound.cache.clear() HATALI!
			// Doğrusu:
			if (FlxG.sound != null)
			{
				FlxG.sound.destroy(true); // Tüm sesleri temizle
			}
			
			OpenFlAssets.cache.clear();
		} catch(e:Dynamic) {}
	}
    
    public static function createCrashFlag(reason:String):Void
    {
        #if sys
        try {
            var path = getCrashFlagPath();
            var dir = haxe.io.Path.directory(path);
            
            if (dir.length > 0 && !FileSystem.exists(dir))
                FileSystem.createDirectory(dir);
            
            var data = reason + "\n" + Date.now().toString();
            
            try {
                var stack = CallStack.callStack();
                if (stack != null && stack.length > 0)
                    data += "\n\nStack:\n" + CallStack.toString(stack);
            } catch(e:Dynamic) {}
            
            File.saveContent(path, data);
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function clearCrashFlag():Void
    {
        #if sys
        try {
            var path = getCrashFlagPath();
            if (FileSystem.exists(path))
                FileSystem.deleteFile(path);
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function onCleanExit():Void
    {
        clearCrashFlag();
        consecutiveCrashes = 0;
        trace('[SafeLoader] Clean exit');
    }
    
    public static function validateAllMods():Void
    {
        #if (sys && MODS_ALLOWED)
        var modsListPath = getModsListPath();
        if (!FileSystem.exists(modsListPath)) return;
        
        try {
            var content = File.getContent(modsListPath);
            var lines = content.split('\n');
            var validLines:Array<String> = [];
            var invalidCount = 0;
            
            for (line in lines)
            {
                var trimmed = StringTools.trim(line);
                if (trimmed.length == 0) continue;
                
                var parts = trimmed.split('|');
                var modName = parts[0];
                var enabled = (parts.length > 1) ? (parts[1] == '1') : true;
                
                if (!enabled)
                {
                    validLines.push(trimmed);
                    continue;
                }
                
                var result = validateMod(modName);
                if (result.valid)
                {
                    validLines.push(trimmed);
                }
                else
                {
                    failedMods.push(modName);
                    validLines.push(modName + '|0');
                    invalidCount++;
                }
            }
            
            if (invalidCount > 0)
            {
                File.saveContent(modsListPath, validLines.join('\n'));
                logRecovery('Disabled $invalidCount invalid mods');
            }
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function validateMod(modName:String):{valid:Bool, reason:String}
    {
        #if (sys && MODS_ALLOWED)
        if (modName == null || modName.length == 0)
            return {valid: false, reason: "Empty mod name"};
        
        var modPath = Paths.mods(modName);
        
        if (!FileSystem.exists(modPath))
            return {valid: false, reason: "Folder not found"};
        
        if (!FileSystem.isDirectory(modPath))
            return {valid: false, reason: "Not a directory"};
        
        var packPath = modPath + '/pack.json';
        if (FileSystem.exists(packPath))
        {
            try {
                var content = File.getContent(packPath);
                if (content == null || content.length == 0)
                    return {valid: false, reason: "Empty pack.json"};
                haxe.Json.parse(content);
            } catch(e:Dynamic) {
                return {valid: false, reason: "Invalid pack.json"};
            }
        }
        
        return {valid: true, reason: "OK"};
        #else
        return {valid: true, reason: "OK"};
        #end
    }
    
    public static function disableAllMods():Void
    {
        #if (sys && MODS_ALLOWED)
        var modsListPath = getModsListPath();
        
        try {
            if (!FileSystem.exists(modsListPath))
            {
                File.saveContent(modsListPath, '');
                return;
            }
            
            var content = File.getContent(modsListPath);
            var lines = content.split('\n');
            var newLines:Array<String> = [];
            
            for (line in lines)
            {
                var trimmed = StringTools.trim(line);
                if (trimmed.length == 0) continue;
                
                var parts = trimmed.split('|');
                var modName = parts[0];
                newLines.push(modName + '|0');
            }
            
            File.saveContent(modsListPath, newLines.join('\n'));
        } catch(e:Dynamic) {
            try { FileSystem.deleteFile(modsListPath); } catch(e2:Dynamic) {}
        }
        #end
    }
    
    public static function resetModsList():Void
    {
        #if sys
        try {
            File.saveContent(getModsListPath(), '');
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function disableFailedMods():Void
    {
        #if (sys && MODS_ALLOWED)
        if (failedMods.length == 0) return;
        
        var modsListPath = getModsListPath();
        
        try {
            if (!FileSystem.exists(modsListPath)) return;
            
            var content = File.getContent(modsListPath);
            var lines = content.split('\n');
            var newLines:Array<String> = [];
            
            for (line in lines)
            {
                var trimmed = StringTools.trim(line);
                if (trimmed.length == 0) continue;
                
                var parts = trimmed.split('|');
                var modName = parts[0];
                
                if (failedMods.contains(modName))
                    newLines.push(modName + '|0');
                else
                    newLines.push(trimmed);
            }
            
            File.saveContent(modsListPath, newLines.join('\n'));
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function loadBitmapData(path:String):BitmapData
    {
        try {
            #if sys
            if (FileSystem.exists(path))
            {
                var bmp = BitmapData.fromFile(path);
                if (bmp != null) return bmp;
            }
            #end
            
            if (OpenFlAssets.exists(path))
                return OpenFlAssets.getBitmapData(path);
        } catch(e:Dynamic) {
            logAssetError('BitmapData', path, Std.string(e));
        }
        
        return new BitmapData(1, 1, true, 0x00000000);
    }
    
    public static function loadSound(path:String):Sound
    {
        try {
            #if sys
            if (FileSystem.exists(path))
            {
                var snd = Sound.fromFile(path);
                if (snd != null) return snd;
            }
            #end
            
            if (OpenFlAssets.exists(path))
                return OpenFlAssets.getSound(path);
        } catch(e:Dynamic) {
            logAssetError('Sound', path, Std.string(e));
        }
        
        return new Sound();
    }
    
    public static function loadText(path:String):String
    {
        #if sys
        try {
            if (FileSystem.exists(path))
                return File.getContent(path);
        } catch(e:Dynamic) {
            logAssetError('Text', path, Std.string(e));
        }
        #end
        
        try {
            if (OpenFlAssets.exists(path))
                return OpenFlAssets.getText(path);
        } catch(e:Dynamic) {}
        
        return null;
    }
    
    public static function parseJSON(content:String, ?sourcePath:String):Dynamic
    {
        if (content == null || content.length == 0) return null;
        
        try {
            return haxe.Json.parse(content);
        } catch(e:Dynamic) {
            logAssetError('JSON', sourcePath ?? "unknown", Std.string(e));
        }
        
        return null;
    }
    
    public static function logAssetError(type:String, path:String, error:String):Void
    {
        errorCount++;
        var msg = '[$type] $path - $error';
        trace('[SafeLoader] Asset error: ' + msg);
        failedAssets.push(msg);
        
        if (path != null && path.indexOf('mods/') != -1)
        {
            var modName = extractModNameFromPath(path);
            if (modName != null && !failedMods.contains(modName))
                failedMods.push(modName);
        }
        
        if (errorCount >= maxErrorsBeforeRecovery)
            createCrashFlag("Too many asset errors");
    }
    
    private static function extractModNameFromPath(path:String):Null<String>
    {
        if (path == null) return null;
        var parts = path.split('/');
        for (i in 0...parts.length)
        {
            if (parts[i] == 'mods' && i + 1 < parts.length)
                return parts[i + 1];
        }
        return null;
    }
    
    public static function logCrash(reason:String):Void
    {
        #if sys
        try {
            var logPath = getCrashLogPath();
            var existing = "";
            
            if (FileSystem.exists(logPath))
                try { existing = File.getContent(logPath); } catch(e:Dynamic) {}
            
            var entry = "\n=== " + Date.now().toString() + " ===\n" + reason + "\n";
            if (failedMods.length > 0)
                entry += "Failed mods: " + failedMods.join(", ") + "\n";
            
            File.saveContent(logPath, existing + entry);
        } catch(e:Dynamic) {}
        #end
    }
    
    private static function logRecovery(action:String):Void
    {
        #if sys
        try {
            var logPath = getRecoveryLogPath();
            var existing = "";
            if (FileSystem.exists(logPath))
                try { existing = File.getContent(logPath); } catch(e:Dynamic) {}
            
            var entry = "[" + Date.now().toString() + "] " + action + "\n";
            File.saveContent(logPath, existing + entry);
        } catch(e:Dynamic) {}
        #end
    }
    
    private static function createCrashReport(crashData:String):Void
    {
        #if sys
        try {
            var report:CrashReport = {
                timestamp: Date.now().toString(),
                reason: crashData,
                stackTrace: "",
                failedMods: failedMods.copy(),
                failedAssets: failedAssets.copy(),
                systemInfo: getSystemInfo()
            };
            
            try {
                var stack = CallStack.callStack();
                if (stack != null)
                    report.stackTrace = CallStack.toString(stack);
            } catch(e:Dynamic) {}
            
            var json = haxe.Json.stringify(report, null, "  ");
            var path = getCrashReportPath();
            
            var reports:Array<CrashReport> = [];
            if (FileSystem.exists(path))
            {
                try {
                    var existing = File.getContent(path);
                    reports = haxe.Json.parse(existing);
                } catch(e:Dynamic) {}
            }
            
            reports.push(report);
            if (reports.length > 10)
                reports = reports.slice(reports.length - 10);
            
            File.saveContent(path, haxe.Json.stringify(reports, null, "  "));
        } catch(e:Dynamic) {}
        #end
    }
    
    private static function loadCrashHistory():Void
    {
        #if sys
        try {
            var path = getCrashReportPath();
            if (FileSystem.exists(path))
            {
                var content = File.getContent(path);
                crashHistory = haxe.Json.parse(content);
            }
        } catch(e:Dynamic) {}
        #end
    }
    
    private static function getSystemInfo():SystemInfo
    {
        var platform = #if mobile "Mobile" #elseif web "Web" #elseif desktop "Desktop" #else "Unknown" #end;
        var flixelVer = "Unknown";
        
        try {
            flixelVer = FlxG.VERSION.toString();
        } catch(e:Dynamic) {}
        
        return {
            platform: platform,
            haxeVersion: "4.x",
            flixelVersion: flixelVer,
            openflVersion: "Unknown",
            totalRAM: getTotalRAM(),
            freeRAM: getFreeRAM()
        };
    }
    
    private static function getTotalRAM():Float
    {
        #if cpp
        try {
            return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED) / 1024 / 1024;
        } catch(e:Dynamic) {}
        #end
        return 0;
    }
    
    private static function getFreeRAM():Float
    {
        #if cpp
        try {
            return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE) / 1024 / 1024;
        } catch(e:Dynamic) {}
        #end
        return 0;
    }
    
    public static function setupExceptionHandler():Void
    {
        #if cpp
        untyped __global__.__hxcpp_set_critical_error_handler(function(msg:String) {
            trace('[SafeLoader] CRITICAL ERROR: ' + msg);
            createCrashFlag("Critical: " + msg);
            logCrash("Critical error: " + msg);
            try { FlxG.save.flush(); } catch(e:Dynamic) {}
        });
        #end
    }
    
    public static function enableSafeModeOnNextBoot():Void
    {
        #if sys
        try {
            File.saveContent(getSafeModePath(), "Safe mode requested\n" + Date.now().toString());
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function clearSafeMode():Void
    {
        #if sys
        try {
            var path = getSafeModePath();
            if (FileSystem.exists(path))
                FileSystem.deleteFile(path);
            safeMode = false;
        } catch(e:Dynamic) {}
        #end
    }
    
    private static function getCrashFlagPath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + CRASH_FLAG_FILE;
        #elseif sys
        return Sys.getCwd() + CRASH_FLAG_FILE;
        #else
        return CRASH_FLAG_FILE;
        #end
    }
    
    private static function getSafeModePath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + SAFE_MODE_FILE;
        #elseif sys
        return Sys.getCwd() + SAFE_MODE_FILE;
        #else
        return SAFE_MODE_FILE;
        #end
    }
    
    private static function getCrashLogPath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + CRASH_LOG_FILE;
        #elseif sys
        return Sys.getCwd() + CRASH_LOG_FILE;
        #else
        return CRASH_LOG_FILE;
        #end
    }
    
    private static function getCrashReportPath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + CRASH_REPORT_FILE;
        #elseif sys
        return Sys.getCwd() + CRASH_REPORT_FILE;
        #else
        return CRASH_REPORT_FILE;
        #end
    }
    
    private static function getRecoveryLogPath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + RECOVERY_LOG_FILE;
        #elseif sys
        return Sys.getCwd() + RECOVERY_LOG_FILE;
        #else
        return RECOVERY_LOG_FILE;
        #end
    }
    
    private static function getModsListPath():String
    {
        #if MODS_ALLOWED
        var customPath = ClientPrefs.data.modsPath;
        if (customPath != null && customPath.length > 0)
            return haxe.io.Path.addTrailingSlash(customPath) + 'modsList.txt';
        #end
        
        #if android
        return StorageUtil.getExternalStorageDirectory() + 'modsList.txt';
        #elseif sys
        return Sys.getCwd() + 'modsList.txt';
        #else
        return 'modsList.txt';
        #end
    }
    
    public static function getSafeModeTitle():String
    {
        return Language.getPhrase('safemode_title', 'Safe Mode Active');
    }
    
    public static function getSafeModeMessage():String
    {
        return Language.getPhrase('safemode_message', 'Mods have been temporarily disabled for safety.');
    }
    
    public static function getSafeModeModsInfo():String
    {
        return Language.getPhrase('safemode_mods_info', 'Problematic mods:');
    }
    
    public static function getSafeModeReenableHint():String
    {
        return Language.getPhrase('safemode_reenable_hint', 'You can re-enable mods from the settings.');
    }
}