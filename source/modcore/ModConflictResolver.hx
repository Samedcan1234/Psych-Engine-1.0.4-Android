package modcore;

import sys.FileSystem;

/**
 * Mod çakışmalarını tespit edip çözen sistem.
 * Psych ve Polymod modları arasındaki öncelik ve çakışma yönetimi.
 */
class ModConflictResolver {

    /**
     * Çakışma raporu oluştur
     */
    public static function analyzeConflicts(mods:Array<ModMetadata>):Array<ModConflict> {
        var conflicts:Array<ModConflict> = [];

        // Sadece aktif modları al
        var activeMods = mods.filter(m -> m.enabled);

        // Her mod çifti için dosya çakışmalarını kontrol et
        for (i in 0...activeMods.length) {
            for (j in (i + 1)...activeMods.length) {
                var modA = activeMods[i];
                var modB = activeMods[j];

                // Dosya çakışmaları
                var fileConflicts = findFileConflicts(modA, modB);
                for (fc in fileConflicts) {
                    conflicts.push(fc);
                }

                // Bağımlılık çakışmaları
                var depConflict = checkDependencyConflict(modA, modB);
                if (depConflict != null) {
                    conflicts.push(depConflict);
                }

                // Uyumsuzluk kontrolü
                var incompatConflict = checkIncompatibility(modA, modB);
                if (incompatConflict != null) {
                    conflicts.push(incompatConflict);
                }
            }
        }

        return conflicts;
    }

    /**
     * Çakışmayı çöz (öncelik tabanlı)
     */
    public static function resolveConflict(conflict:ModConflict, mods:Array<ModMetadata>):ConflictResolution {
        switch (conflict.type) {
            case FILE_OVERRIDE:
                // Yüksek öncelikli mod kazanır
                var modA = findMod(conflict.modAId, mods);
                var modB = findMod(conflict.modBId, mods);

                if (modA == null || modB == null)
                    return {winner: conflict.modAId, action: SKIP, message: "Mod bulunamadı"};

                // HYBRID modlar öncelikli
                if (modA.modType == HYBRID && modB.modType != HYBRID)
                    return {winner: modA.id, action: USE_A, message: "Hybrid mod öncelikli"};
                if (modB.modType == HYBRID && modA.modType != HYBRID)
                    return {winner: modB.id, action: USE_B, message: "Hybrid mod öncelikli"};

                // Aynı tip ise priority'ye bak
                if (modA.priority >= modB.priority)
                    return {winner: modA.id, action: USE_A, message: "Yüksek öncelik"};
                else
                    return {winner: modB.id, action: USE_B, message: "Yüksek öncelik"};

            case DEPENDENCY_MISSING:
                return {winner: "", action: DISABLE_MOD, message: 'Bağımlılık eksik: ${conflict.details}'};

            case INCOMPATIBLE:
                return {winner: conflict.modAId, action: DISABLE_MOD_B, message: 'Uyumsuz modlar: ${conflict.modAId} <-> ${conflict.modBId}'};

            case MERGE_POSSIBLE:
                return {winner: "", action: MERGE, message: "Polymod merge ile birleştirilebilir"};
        }
    }

    /**
     * Otomatik çakışma çözümü uygula
     */
    public static function autoResolveAll(mods:Array<ModMetadata>):Array<ConflictResolution> {
        var conflicts = analyzeConflicts(mods);
        var resolutions:Array<ConflictResolution> = [];

        for (conflict in conflicts) {
            var resolution = resolveConflict(conflict, mods);
            resolutions.push(resolution);

            // Çözümü uygula
            applyResolution(resolution, mods);
        }

        return resolutions;
    }

    // --- Private Methods ---

    private static function findFileConflicts(modA:ModMetadata, modB:ModMetadata):Array<ModConflict> {
        var conflicts:Array<ModConflict> = [];

        // Ortak klasörleri kontrol et
        var commonDirs = ["characters", "data", "images", "songs", "stages", "scripts", "weeks"];

        for (dir in commonDirs) {
            var dirA = '${modA.path}/$dir';
            var dirB = '${modB.path}/$dir';

            if (!FileSystem.exists(dirA) || !FileSystem.exists(dirB))
                continue;

            var filesA = getFilesRecursive(dirA);
            var filesB = getFilesRecursive(dirB);

            // Göreceli yolları karşılaştır
            var relativeA = filesA.map(f -> StringTools.replace(f, dirA, ""));
            var relativeB = filesB.map(f -> StringTools.replace(f, dirB, ""));

            for (relA in relativeA) {
                if (relativeB.indexOf(relA) != -1) {
                    // Dosya tipi kontrol - JSON ise merge mümkün
                    var conflictType = StringTools.endsWith(relA, ".json") ? MERGE_POSSIBLE : FILE_OVERRIDE;

                    conflicts.push({
                        type: conflictType,
                        modAId: modA.id,
                        modBId: modB.id,
                        details: '$dir$relA',
                        severity: conflictType == MERGE_POSSIBLE ? LOW : MEDIUM
                    });
                }
            }
        }

        return conflicts;
    }

    private static function checkDependencyConflict(modA:ModMetadata, modB:ModMetadata):Null<ModConflict> {
        // A, B'ye bağımlı mı?
        if (modA.dependencies.indexOf(modB.id) != -1 && !modB.enabled) {
            return {
                type: DEPENDENCY_MISSING,
                modAId: modA.id,
                modBId: modB.id,
                details: '${modA.id} requires ${modB.id}',
                severity: HIGH
            };
        }

        // B, A'ya bağımlı mı?
        if (modB.dependencies.indexOf(modA.id) != -1 && !modA.enabled) {
            return {
                type: DEPENDENCY_MISSING,
                modAId: modB.id,
                modBId: modA.id,
                details: '${modB.id} requires ${modA.id}',
                severity: HIGH
            };
        }

        return null;
    }

    private static function checkIncompatibility(modA:ModMetadata, modB:ModMetadata):Null<ModConflict> {
        if (modA.incompatibilities.indexOf(modB.id) != -1 || modB.incompatibilities.indexOf(modA.id) != -1) {
            return {
                type: INCOMPATIBLE,
                modAId: modA.id,
                modBId: modB.id,
                details: "Modlar uyumsuz olarak işaretlenmiş",
                severity: HIGH
            };
        }
        return null;
    }

    private static function findMod(id:String, mods:Array<ModMetadata>):Null<ModMetadata> {
        for (mod in mods) {
            if (mod.id == id)
                return mod;
        }
        return null;
    }

    private static function applyResolution(resolution:ConflictResolution, mods:Array<ModMetadata>):Void {
        switch (resolution.action) {
            case DISABLE_MOD:
                // İlgili mod'u devre dışı bırak
                var mod = findMod(resolution.winner, mods);
                if (mod != null) mod.enabled = false;

            case DISABLE_MOD_B:
                // Bu durumda winner modA, modB devre dışı
                // Resolution'da ek bilgi gerekir, basitleştirilmiş
                trace('[ConflictResolver] Çakışma çözümü: ${resolution.message}');

            default:
                // USE_A, USE_B, MERGE, SKIP - runtime'da handle edilir
                trace('[ConflictResolver] Çakışma çözümü: ${resolution.message}');
        }
    }

    private static function getFilesRecursive(dir:String):Array<String> {
        var result:Array<String> = [];

        if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
            return result;

        try {
            for (entry in FileSystem.readDirectory(dir)) {
                var fullPath = '$dir/$entry';
                if (FileSystem.isDirectory(fullPath)) {
                    result = result.concat(getFilesRecursive(fullPath));
                } else {
                    result.push(fullPath);
                }
            }
        } catch (e:Dynamic) {
            trace('[ConflictResolver] Klasör tarama hatası ($dir): $e');
        }

        return result;
    }
}

// --- Types ---

typedef ModConflict = {
    var type:ConflictType;
    var modAId:String;
    var modBId:String;
    var details:String;
    var severity:ConflictSeverity;
}

typedef ConflictResolution = {
    var winner:String;
    var action:ResolutionAction;
    var message:String;
}

enum ConflictType {
    FILE_OVERRIDE;
    DEPENDENCY_MISSING;
    INCOMPATIBLE;
    MERGE_POSSIBLE;
}

enum ConflictSeverity {
    LOW;
    MEDIUM;
    HIGH;
}

enum ResolutionAction {
    USE_A;
    USE_B;
    MERGE;
    SKIP;
    DISABLE_MOD;
    DISABLE_MOD_B;
}