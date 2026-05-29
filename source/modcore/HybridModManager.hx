package modcore;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import modcore.ModMetadata;
import modcore.ModConflictResolver;
/**
 * Psych Engine Ultra - Hibrit Mod Yöneticisi
 * 
 * Hem Psych Engine'in kendi mod sistemini hem de Polymod'u
 * tek bir unified API altında yönetir.
 * 
 * Kullanım:
 *   HybridModManager.init();
 *   HybridModManager.enableMod("mymod");
 *   HybridModManager.apply();
 */
class HybridModManager {
    // Tüm tespit edilen modlar
    public static var allMods:Array<ModMetadata> = [];

    // Aktif modlar (sıralı)
    public static var activeMods:Array<ModMetadata> = [];

    // Başlatılmış mı?
    public static var initialized:Bool = false;

    // Event callbacks
    public static var onModEnabled:Null<ModMetadata->Void> = null;
    public static var onModDisabled:Null<ModMetadata->Void> = null;
    public static var onConflictDetected:Null<ModConflict->Void> = null;
    public static var onModsReloaded:Null<Void->Void> = null;

    // Config
    private static var configPath:String = "mods/hybrid_config.json";

    /**
     * Hibrit mod sistemini başlat
     */
    public static function init():Void {
        if (initialized) return;

        trace("=== Psych Engine Ultra - Hibrit Mod Sistemi ===");
        trace("[HybridModManager] Başlatılıyor...");

        // 1. Tüm modları tara
        scanAllMods();

        // 2. Kaydedilmiş config'i yükle
        loadConfig();

        // 3. Polymod'u başlat
        initPolymod();

        // 4. Çakışmaları kontrol et
        checkConflicts();

        // 5. Asset bridge'i hazırla
        setupAssetBridge();

        initialized = true;

        trace('[HybridModManager] Başlatma tamamlandı. ${allMods.length} mod tespit edildi, ${activeMods.length} aktif.');
        for (mod in allMods) {
            trace('  ${mod.toString()}');
        }
    }

    /**
     * Tüm modları yeniden tara
     */
    public static function rescan():Void {
        trace("[HybridModManager] Modlar yeniden taranıyor...");

        allMods = [];
        activeMods = [];

        scanAllMods();
        loadConfig();
        checkConflicts();

        // Polymod'u yeniden yükle
        reloadPolymod();

        // Cache temizle
        ModAssetBridge.clearCache();

        if (onModsReloaded != null)
            onModsReloaded();

        trace('[HybridModManager] Yeniden tarama tamamlandı. ${allMods.length} mod.');
    }

    /**
     * Mod'u etkinleştir
     */
    public static function enableMod(modId:String):Bool {
        var mod = findMod(modId);
        if (mod == null) {
            trace('[HybridModManager] Mod bulunamadı: $modId');
            return false;
        }

        if (mod.enabled) return true;

        mod.enabled = true;

        if (activeMods.indexOf(mod) == -1) {
            activeMods.push(mod);
        }

        // Cache temizle
        ModAssetBridge.clearModCache(modId);

        saveConfig();

        if (onModEnabled != null)
            onModEnabled(mod);

        trace('[HybridModManager] Mod etkinleştirildi: $modId');
        return true;
    }

    /**
     * Mod'u devre dışı bırak
     */
    public static function disableMod(modId:String):Bool {
        var mod = findMod(modId);
        if (mod == null) return false;

        mod.enabled = false;
        activeMods.remove(mod);

        // Cache temizle
        ModAssetBridge.clearModCache(modId);

        saveConfig();

        if (onModDisabled != null)
            onModDisabled(mod);

        trace('[HybridModManager] Mod devre dışı bırakıldı: $modId');
        return true;
    }

    /**
     * Mod önceliğini ayarla
     */
    public static function setModPriority(modId:String, priority:Int):Void {
        var mod = findMod(modId);
        if (mod == null) return;

        mod.priority = priority;
        sortActiveMods();
        saveConfig();
    }

    /**
     * Aktif mod'u değiştir (Psych Engine tarzı)
     */
    public static function setCurrentMod(modId:String):Void {
        PsychModHandler.currentModDirectory = modId;

        // Polymod'u da güncelle
        reloadPolymod();

        // Cache temizle
        ModAssetBridge.clearCache();

        trace('[HybridModManager] Aktif mod değiştirildi: $modId');
    }

    /**
     * Değişiklikleri uygula (Polymod reload)
     */
    public static function apply():Void {
        reloadPolymod();
        ModAssetBridge.clearCache();
        trace("[HybridModManager] Değişiklikler uygulandı.");
    }

    /**
     * Asset çözümle (Bridge üzerinden)
     */
    public static function resolveAsset(path:String):String {
        return ModAssetBridge.resolveAssetPath(path);
    }

    /**
     * Mod bilgisini al
     */
    public static function getModInfo(modId:String):Null<ModMetadata> {
        return findMod(modId);
    }

    /**
     * Tüm modları mod tipine göre filtrele
     */
    public static function getModsByType(type:ModType):Array<ModMetadata> {
        return allMods.filter(m -> m.modType == type);
    }

    /**
     * Çakışma raporunu al
     */
    public static function getConflictReport():Array<ModConflict> {
        return ModConflictResolver.analyzeConflicts(allMods);
    }

    /**
     * Psych Engine uyumluluk: Mevcut mod listesini al (modsList.txt formatında)
     */
    public static function exportPsychModsList():String {
        var buf = new StringBuf();
        for (mod in allMods) {
            var enabled = mod.enabled ? "1" : "0";
            buf.add('${mod.id}|$enabled\n');
        }
        return buf.toString();
    }

    /**
     * Her Psych mod'una Polymod meta şablonu oluştur
     */
    public static function generatePolymodTemplates():Int {
        var count = 0;
        for (mod in allMods) {
            if (mod.modType == PSYCH_ONLY) {
                PolymodHandler.generateMetaTemplate(mod.path, mod.id, mod.psychPackData);
                count++;
            }
        }
        trace('[HybridModManager] $count adet Polymod şablonu oluşturuldu.');
        return count;
    }

    /**
     * Debug: Tüm mod durumunu yazdır
     */
    public static function debugPrintStatus():Void {
        trace("=== HybridModManager Status ===");
        trace('Toplam mod: ${allMods.length}');
        trace('Aktif mod: ${activeMods.length}');
        trace('Psych modları: ${getModsByType(PSYCH_ONLY).length}');
        trace('Polymod modları: ${getModsByType(POLYMOD_ONLY).length}');
        trace('Hibrit modlar: ${getModsByType(HYBRID).length}');
        trace('Polymod initialized: ${PolymodHandler.initialized}');
        trace("");

        for (mod in allMods) {
            trace('  ${mod.toString()}');
        }

        var conflicts = getConflictReport();
        if (conflicts.length > 0) {
            trace('');
            trace('Çakışmalar: ${conflicts.length}');
            for (c in conflicts) {
                trace('  [${c.severity}] ${c.type}: ${c.modAId} <-> ${c.modBId} - ${c.details}');
            }
        }

        trace("================================");
    }

    // ========================================
    // Private Methods
    // ========================================

    private static function scanAllMods():Void {
        // Psych modlarını tara (bu otomatik olarak hybrid olanları da tespit eder)
        var psychMods = PsychModHandler.scanPsychMods();
        for (mod in psychMods) {
            allMods.push(mod);
        }

        // Sadece Polymod olan modları tara (Psych tarafından tespit edilmemiş)
        var existingIds = allMods.map(m -> m.id);
        var polymodDirs = PolymodHandler.scanPolymodMods();

        for (dir in polymodDirs) {
            if (existingIds.indexOf(dir) == -1) {
                // Sadece polymod meta var, pack.json yok
                var polyMeta = PolymodHandler.readPolymodMeta('mods/$dir');
                if (polyMeta != null) {
                    var meta = ModMetadata.fromPolymodMeta(polyMeta, 'mods/$dir');
                    allMods.push(meta);
                }
            }
        }

        // Psych modsList.txt'den enabled durumunu oku
        for (mod in allMods) {
            mod.enabled = PsychModHandler.isModEnabled(mod.id);
        }

        // Aktif modları ayarla
        activeMods = allMods.filter(m -> m.enabled);
        sortActiveMods();
    }

    private static function initPolymod():Void {
        var polymodMods = activeMods.filter(m -> m.modType == POLYMOD_ONLY || m.modType == HYBRID);
        if (polymodMods.length > 0) {
            var dirs = polymodMods.map(m -> m.id);
            PolymodHandler.reload(dirs);
        } else {
            PolymodHandler.init();
        }
    }

    private static function reloadPolymod():Void {
        var polymodMods = activeMods.filter(m -> m.modType == POLYMOD_ONLY || m.modType == HYBRID);
        var dirs = polymodMods.map(m -> m.id);
        PolymodHandler.reload(dirs);
    }

    private static function checkConflicts():Void {
        var conflicts = ModConflictResolver.analyzeConflicts(allMods);

        for (conflict in conflicts) {
            if (onConflictDetected != null) {
                onConflictDetected(conflict);
            }

            switch (conflict.severity) {
                case HIGH:
                    trace('[HybridModManager] YÜKSEK ÖNCELİKLİ ÇAKIŞMA: ${conflict.details}');
                    // Otomatik çöz
                    ModConflictResolver.resolveConflict(conflict, allMods);
                case MEDIUM:
                    trace('[HybridModManager] Çakışma: ${conflict.details}');
                case LOW:
                    trace('[HybridModManager] Düşük çakışma: ${conflict.details}');
            }
        }
    }

    private static function setupAssetBridge():Void {
        // Global modları yükle
        PsychModHandler.loadGlobalMods();

        // Cache'i temizle
        ModAssetBridge.clearCache();
    }

    private static function sortActiveMods():Void {
        activeMods.sort((a, b) -> b.priority - a.priority);
    }

    private static function findMod(modId:String):Null<ModMetadata> {
        for (mod in allMods) {
            if (mod.id == modId)
                return mod;
        }
        return null;
    }

    // --- Config Persistence ---

    private static function saveConfig():Void {
        var config:Dynamic = {
            version: "1.0.0",
            mods: []
        };

        for (mod in allMods) {
            var modConfig:Dynamic = {
                id: mod.id,
                enabled: mod.enabled,
                priority: mod.priority
            };
            config.mods.push(modConfig);
        }

        try {
            File.saveContent(configPath, Json.stringify(config, null, "\t"));
        } catch (e:Dynamic) {
            trace('[HybridModManager] Config kaydetme hatası: $e');
        }

        // Psych uyumluluk: modsList.txt'yi de güncelle
        try {
            File.saveContent("mods/modsList.txt", exportPsychModsList());
        } catch (e:Dynamic) {
            trace('[HybridModManager] modsList.txt güncelleme hatası: $e');
        }
    }

    private static function loadConfig():Void {
        if (!FileSystem.exists(configPath))
            return;

        try {
            var content = File.getContent(configPath);
            var config = Json.parse(content);

            if (config.mods != null) {
                var modsArray:Array<Dynamic> = config.mods;
                for (modConfig in modsArray) {
                    var mod = findMod(modConfig.id);
                    if (mod != null) {
                        mod.enabled = modConfig.enabled ?? true;
                        mod.priority = modConfig.priority ?? 0;
                    }
                }
            }

            // Aktif mod listesini güncelle
            activeMods = allMods.filter(m -> m.enabled);
            sortActiveMods();

        } catch (e:Dynamic) {
            trace('[HybridModManager] Config yükleme hatası: $e');
        }
    }
}