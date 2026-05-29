package modcore;

import sys.FileSystem;
import sys.io.File;
import modcore.ModMetadata;

using StringTools;

/**
 * Psych ve Polymod asset sistemlerini birleştiren köprü.
 * Asset çözümleme önceliği:
 * 1. Aktif Psych mod klasörü
 * 2. Polymod override
 * 3. Global modlar
 * 4. Varsayılan assets
 */
class ModAssetBridge {
    private static var assetCache:Map<String, CachedAsset> = new Map();
    private static var cacheEnabled:Bool = true;
    private static var maxCacheSize:Int = 500;

    /**
     * Unified asset çözümleme
     * Hem Psych hem Polymod'u kontrol eder
     */
    public static function resolveAssetPath(relativePath:String):String {
        // Cache kontrol
        if (cacheEnabled && assetCache.exists(relativePath)) {
            var cached = assetCache.get(relativePath);
            if (cached != null && FileSystem.exists(cached.resolvedPath)) {
                return cached.resolvedPath;
            }
        }

        var resolved = resolveInternal(relativePath);

        // Cache boyut kontrolü
        if (cacheEnabled) {
            var count = 0;
            for (_ in assetCache.keys()) count++;
            if (count > maxCacheSize) clearCache();

            assetCache.set(relativePath, {
                resolvedPath: resolved,
                source: determineSource(resolved),
                timestamp: Sys.time()
            });
        }

        return resolved;
    }

    /**
     * Asset'in hangi kaynaktan geldiğini belirle
     */
    public static function getAssetSource(relativePath:String):AssetSource {
        var resolved = resolveAssetPath(relativePath);
        return determineSource(resolved);
    }

    /**
     * Birden fazla moddan gelen aynı asset'leri listele
     */
    public static function findAllVersions(relativePath:String, mods:Array<ModMetadata>):Array<AssetVersion> {
        var versions:Array<AssetVersion> = [];

        for (mod in mods) {
            if (!mod.enabled)
                continue;

            var modAssetPath = '${mod.path}/$relativePath';
            if (FileSystem.exists(modAssetPath)) {
                versions.push({
                    modId: mod.id,
                    path: modAssetPath,
                    modType: mod.modType,
                    priority: mod.priority
                });
            }
        }

        // Varsayılan assets
        var defaultPath = 'assets/$relativePath';
        if (FileSystem.exists(defaultPath)) {
            versions.push({
                modId: "__default__",
                path: defaultPath,
                modType: ModMetadata.ModType.PSYCH_ONLY,
                priority: -1
            });
        }

        // Önceliğe göre sırala
        versions.sort((a, b) -> b.priority - a.priority);

        return versions;
    }

    /**
     * Metin tabanlı asset'leri birleştir (append)
     */
    public static function mergeTextAssets(relativePath:String, mods:Array<ModMetadata>, ?separator:String = "\n"):Null<String> {
        var versions = findAllVersions(relativePath, mods);
        if (versions.length == 0)
            return null;

        var merged = new StringBuf();
        var first = true;

        // Varsayılan önce
        for (v in versions) {
            if (v.modId == "__default__") {
                try {
                    merged.add(File.getContent(v.path));
                    first = false;
                } catch (e:Dynamic) {}
                break;
            }
        }

        // Mod override/append
        for (v in versions) {
            if (v.modId == "__default__")
                continue;
            try {
                if (!first) merged.add(separator);
                merged.add(File.getContent(v.path));
                first = false;
            } catch (e:Dynamic) {}
        }

        return merged.toString();
    }

    /**
     * JSON asset'leri deep merge et
     */
    public static function mergeJsonAssets(relativePath:String, mods:Array<ModMetadata>):Null<Dynamic> {
        var versions = findAllVersions(relativePath, mods);
        if (versions.length == 0)
            return null;

        var baseObj:Dynamic = null;

        // Varsayılan'ı base olarak al
        for (v in versions) {
            if (v.modId == "__default__") {
                try {
                    baseObj = haxe.Json.parse(File.getContent(v.path));
                } catch (e:Dynamic) {}
                break;
            }
        }

        // Mod JSON'larını merge et
        for (v in versions) {
            if (v.modId == "__default__")
                continue;
            try {
                var modObj = haxe.Json.parse(File.getContent(v.path));
                baseObj = deepMerge(baseObj, modObj);
            } catch (e:Dynamic) {}
        }

        return baseObj;
    }

    /**
     * Cache'i temizle
     */
    public static function clearCache():Void {
        assetCache.clear();
        trace("[ModAssetBridge] Asset cache temizlendi.");
    }

    /**
     * Belirli bir mod'un cache'ini temizle
     */
    public static function clearModCache(modId:String):Void {
        var keysToRemove:Array<String> = [];
        for (key => value in assetCache) {
            if (value.resolvedPath.indexOf(modId) != -1) {
                keysToRemove.push(key);
            }
        }
        for (key in keysToRemove) {
            assetCache.remove(key);
        }
    }

    // --- Private Methods ---

    private static function resolveInternal(relativePath:String):String {
        // 1. Aktif Psych mod klasörü
        var currentMod = PsychModHandler.currentModDirectory;
        if (currentMod != "") {
            var modPath = PsychModHandler.getModPath(currentMod, relativePath);
            if (FileSystem.exists(modPath))
                return modPath;
        }

        // 2. Global modlar (Psych)
        for (globalMod in PsychModHandler.globalMods) {
            var globalPath = PsychModHandler.getModPath(globalMod, relativePath);
            if (FileSystem.exists(globalPath))
                return globalPath;
        }

        // 3. Polymod override (Polymod aktifse otomatik handle eder)
        #if POLYMOD_SUPPORT
        if (PolymodHandler.initialized) {
            var polyPath = PolymodHandler.resolveAsset(relativePath);
            if (polyPath != null)
                return polyPath;
        }
        #end

        // 4. Genel mods klasörü
        var generalModPath = 'mods/$relativePath';
        if (FileSystem.exists(generalModPath))
            return generalModPath;

        // 5. Varsayılan assets
        return 'assets/$relativePath';
    }

    private static function determineSource(resolvedPath:String):AssetSource {
        if (resolvedPath.startsWith("mods/")) {
            var parts = resolvedPath.split("/");
            if (parts.length >= 2) {
                var modDir = parts[1];
                if (PolymodHandler.isPolymodCompatible('mods/$modDir'))
                    return POLYMOD_MOD;
                return PSYCH_MOD;
            }
            return PSYCH_MOD;
        }
        return DEFAULT_ASSET;
    }

    /**
     * İki Dynamic nesneyi deep merge et
     */
    private static function deepMerge(base:Dynamic, overrideObj:Dynamic):Dynamic {
        if (base == null) return overrideObj;
        if (overrideObj == null) return base;

        var result:Dynamic = {};

        // Base alanları
        if (base != null) {
            for (field in Reflect.fields(base)) {
                Reflect.setField(result, field, Reflect.field(base, field));
            }
        }

        // Override alanları (deep merge)
        if (overrideObj != null) {
            for (field in Reflect.fields(overrideObj)) {
                var overrideVal = Reflect.field(overrideObj, field);
                var baseVal = Reflect.field(base, field);

                if (baseVal != null
                    && Reflect.isObject(baseVal)
                    && !Std.isOfType(baseVal, String)
                    && !Std.isOfType(baseVal, Array)
                    && Reflect.isObject(overrideVal)
                    && !Std.isOfType(overrideVal, String)
                    && !Std.isOfType(overrideVal, Array))
                {
                    Reflect.setField(result, field, deepMerge(baseVal, overrideVal));
                } else {
                    Reflect.setField(result, field, overrideVal);
                }
            }
        }

        return result;
    }
}

// --- Types ---

typedef CachedAsset = {
    var resolvedPath:String;
    var source:AssetSource;
    var timestamp:Float;
}

typedef AssetVersion = {
    var modId:String;
    var path:String;
    var modType:ModMetadata.ModType;
    var priority:Int;
}

enum AssetSource {
    PSYCH_MOD;
    POLYMOD_MOD;
    DEFAULT_ASSET;
}