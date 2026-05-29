package modcore;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

/**
 * Psych Engine'in mevcut mod sistemini yöneten handler.
 * Mevcut Mods.hx ve Paths.hx ile uyumlu çalışır.
 */
class PsychModHandler {
    public static var modsDirectory:String = "mods/";
    public static var currentModDirectory:String = "";
    public static var globalMods:Array<String> = [];

    /**
     * Tüm Psych modlarını tara
     */
    public static function scanPsychMods():Array<ModMetadata> {
        var result:Array<ModMetadata> = [];

        if (!FileSystem.exists(modsDirectory))
            return result;

        for (dir in FileSystem.readDirectory(modsDirectory)) {
            var fullPath = modsDirectory + dir;
            if (!FileSystem.isDirectory(fullPath))
                continue;

            // Gizli klasörleri atla
            if (StringTools.startsWith(dir, "."))
                continue;

            var meta = scanSingleMod(fullPath);
            if (meta != null) {
                result.push(meta);
            }
        }

        return result;
    }

    /**
     * Tek bir mod klasörünü tara
     */
    public static function scanSingleMod(modPath:String):Null<ModMetadata> {
        if (!FileSystem.isDirectory(modPath))
            return null;

        var packPath = '$modPath/pack.json';
        var packData:Dynamic = null;

        // pack.json oku
        if (FileSystem.exists(packPath)) {
            try {
                packData = Json.parse(File.getContent(packPath));
            } catch (e:Dynamic) {
                trace('[PsychModHandler] pack.json okuma hatası ($modPath): $e');
            }
        }

        var meta = ModMetadata.fromPsychPack(packData, modPath);

        // Polymod meta da var mı kontrol et
        var polymodMetaPath = '$modPath/_polymod_meta.json';
        if (FileSystem.exists(polymodMetaPath)) {
            try {
                var polyMeta = Json.parse(File.getContent(polymodMetaPath));
                meta.mergeWithPolymod(polyMeta);
            } catch (e:Dynamic) {
                trace('[PsychModHandler] Polymod meta okuma hatası ($modPath): $e');
            }
        }

        return meta;
    }

    /**
     * Psych Engine mod asset yolunu çözümle
     */
    public static function getModPath(modFolder:String, assetPath:String):String {
        return '$modsDirectory$modFolder/$assetPath';
    }

    /**
     * Global modları yükle
     */
    public static function loadGlobalMods():Array<String> {
        globalMods = [];

        var allMods = scanPsychMods();
        for (mod in allMods) {
            if (mod.psychPackData != null && mod.psychPackData.runsGlobally) {
                globalMods.push(mod.id);
            }
        }

        return globalMods;
    }

    /**
     * Mod klasöründe belirli bir dosya var mı?
     */
    public static function modFileExists(modFolder:String, filePath:String):Bool {
        var fullPath = getModPath(modFolder, filePath);
        return FileSystem.exists(fullPath);
    }

    /**
     * Mod klasöründen dosya oku
     */
    public static function readModFile(modFolder:String, filePath:String):Null<String> {
        var fullPath = getModPath(modFolder, filePath);
        if (!FileSystem.exists(fullPath))
            return null;

        try {
            return File.getContent(fullPath);
        } catch (e:Dynamic) {
            trace('[PsychModHandler] Dosya okuma hatası ($fullPath): $e');
            return null;
        }
    }

    /**
     * Aktif mod dizinindeki tüm script dosyalarını bul
     */
    public static function getModScripts(modFolder:String, ?subfolder:String):Array<String> {
        var scriptsDir = (subfolder != null)
            ? getModPath(modFolder, subfolder)
            : getModPath(modFolder, "scripts");

        var result:Array<String> = [];

        if (!FileSystem.exists(scriptsDir) || !FileSystem.isDirectory(scriptsDir))
            return result;

        for (file in FileSystem.readDirectory(scriptsDir)) {
            if (StringTools.endsWith(file, ".hx") || StringTools.endsWith(file, ".lua")) {
                result.push('$scriptsDir/$file');
            }
        }

        return result;
    }

    /**
     * Mod'un aktif olup olmadığını kontrol et
     */
    public static function isModEnabled(modId:String):Bool {
        // modsList.txt'den oku
        var modsListPath = '${modsDirectory}modsList.txt';
        if (!FileSystem.exists(modsListPath))
            return true; // Liste yoksa hepsi aktif

        try {
            var content = File.getContent(modsListPath);
            var lines = content.split("\n");
            for (line in lines) {
                var trimmed = StringTools.trim(line);
                if (trimmed == "")
                    continue;

                var parts = trimmed.split("|");
                if (parts.length >= 2) {
                    var name = StringTools.trim(parts[0]);
                    var enabled = StringTools.trim(parts[1]) == "1";
                    if (name == modId)
                        return enabled;
                }
            }
        } catch (e:Dynamic) {
            trace('[PsychModHandler] modsList.txt okuma hatası: $e');
        }

        return true;
    }
}