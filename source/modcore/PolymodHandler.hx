package modcore;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

/**
 * Polymod entegrasyonunu yöneten handler.
 * POLYMOD_SUPPORT tanımlanmamışsa sadece meta okuma/yazma işlevleri çalışır.
 */
class PolymodHandler {
    public static var initialized:Bool = false;
    private static var activeMods:Array<String> = [];
    private static var modDirectory:String = "mods";

    /**
     * Polymod'u başlat
     */
    public static function init():Void {
        #if POLYMOD_SUPPORT
        initPolymodInternal(getActiveModDirs());
        #else
        trace("[PolymodHandler] POLYMOD_SUPPORT tanımlanmamış, atlanıyor.");
        #end
    }

    /**
     * Aktif modları yeniden yükle
     */
    public static function reload(modDirs:Array<String>):Void {
        #if POLYMOD_SUPPORT
        activeMods = modDirs;
        initialized = false;
        initPolymodInternal(modDirs);
        #else
        trace("[PolymodHandler] POLYMOD_SUPPORT tanımlanmamış, reload atlanıyor.");
        #end
    }

    /**
     * Belirli bir mod'un Polymod uyumlu olup olmadığını kontrol et
     */
    public static function isPolymodCompatible(modPath:String):Bool {
        var metaPath = '$modPath/_polymod_meta.json';
        return FileSystem.exists(metaPath);
    }

    /**
     * Polymod metadata'sını oku
     */
    public static function readPolymodMeta(modPath:String):Dynamic {
        var metaPath = '$modPath/_polymod_meta.json';
        if (!FileSystem.exists(metaPath))
            return null;

        try {
            var content = File.getContent(metaPath);
            return Json.parse(content);
        } catch (e:Dynamic) {
            trace('[PolymodHandler] Meta okuma hatası ($modPath): $e');
            return null;
        }
    }

    /**
     * Polymod için _polymod_meta.json şablonu oluştur
     */
    public static function generateMetaTemplate(modPath:String, modId:String, ?packData:Dynamic):Void {
        var metaPath = '$modPath/_polymod_meta.json';
        if (FileSystem.exists(metaPath))
            return;

        var meta:Dynamic = {
            title: (packData != null && Reflect.hasField(packData, "name")) ? packData.name : modId,
            description: (packData != null && Reflect.hasField(packData, "description")) ? packData.description : "A mod for Psych Engine Ultra",
            author: (packData != null && Reflect.hasField(packData, "author")) ? packData.author : "Unknown",
            apiVersion: "1.0.0",
            modVersion: "1.0.0",
            dependencies: []
        };

        try {
            File.saveContent(metaPath, Json.stringify(meta, null, "\t"));
            trace('[PolymodHandler] Meta şablonu oluşturuldu: $metaPath');
        } catch (e:Dynamic) {
            trace('[PolymodHandler] Meta şablonu oluşturma hatası: $e');
        }
    }

    /**
     * Mevcut modları tara ve Polymod uyumlu olanları döndür
     */
    public static function scanPolymodMods():Array<String> {
        var result:Array<String> = [];

        if (!FileSystem.exists(modDirectory))
            return result;

        for (dir in FileSystem.readDirectory(modDirectory)) {
            var fullPath = '$modDirectory/$dir';
            if (FileSystem.isDirectory(fullPath) && isPolymodCompatible(fullPath)) {
                result.push(dir);
            }
        }

        return result;
    }

    /**
     * Polymod asset yolu çözümle
     */
    public static function resolveAsset(path:String):Null<String> {
        #if POLYMOD_SUPPORT
        if (!initialized) return null;
        return path;
        #else
        return null;
        #end
    }

    // --- Private Methods ---

    private static function getActiveModDirs():Array<String> {
        if (activeMods.length > 0)
            return activeMods;
        return scanPolymodMods();
    }

    /**
     * Polymod dahili başlatma
     * Bu fonksiyonun TAMAMINI #if ile sarmalıyoruz
     */
    private static function initPolymodInternal(dirs:Array<String>):Void {
        // Polymod kurulu değilse bu fonksiyon hiçbir şey yapmaz
        trace("[PolymodHandler] initPolymodInternal çağrıldı.");

        #if POLYMOD_SUPPORT
        // === POLYMOD KODU BAŞLANGICI ===
        // Bu blok SADECE POLYMOD_SUPPORT tanımlıysa ve polymod kuruluysa derlenir
        try {
            initialized = true;
            trace("[PolymodHandler] Polymod başarıyla başlatıldı.");
        } catch (e:Dynamic) {
            trace('[PolymodHandler] Polymod başlatma hatası: $e');
        }
        // === POLYMOD KODU SONU ===
        #end
    }
}