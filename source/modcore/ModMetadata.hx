package modcore;

/**
 * Hem Psych hem Polymod mod metadata'sını temsil eden unified yapı.
 */
class ModMetadata {
    public var id:String;
    public var title:String;
    public var description:String;
    public var author:String;
    public var version:String;
    public var apiVersion:String;
    public var modType:ModType;
    public var priority:Int;
    public var enabled:Bool;
    public var path:String;
    public var dependencies:Array<String>;
    public var incompatibilities:Array<String>;
    public var psychPackData:Null<PsychPackData>;
    public var polymodMeta:Null<PolymodMetaData>;

    public function new() {
        id = "";
        title = "";
        description = "";
        author = "";
        version = "1.0.0";
        apiVersion = "1.0.0";
        modType = HYBRID;
        priority = 0;
        enabled = true;
        path = "";
        dependencies = [];
        incompatibilities = [];
        psychPackData = null;
        polymodMeta = null;
    }

    public static function fromPsychPack(packJson:Dynamic, modPath:String):ModMetadata {
        var meta = new ModMetadata();
        meta.id = extractModId(modPath);
        meta.path = modPath;
        meta.modType = PSYCH_ONLY;

        if (packJson != null) {
            meta.title = Reflect.hasField(packJson, "name") ? packJson.name : meta.id;
            meta.description = Reflect.hasField(packJson, "description") ? packJson.description : "";
            meta.author = Reflect.hasField(packJson, "author") ? packJson.author : "Unknown";
            meta.version = Reflect.hasField(packJson, "version") ? packJson.version : "1.0.0";
            meta.psychPackData = {
                name: meta.title,
                description: meta.description,
                runsGlobally: Reflect.hasField(packJson, "runsGlobally") ? packJson.runsGlobally : false,
                color: Reflect.hasField(packJson, "color") ? packJson.color : [170, 0, 255]
            };
        }

        return meta;
    }

    public static function fromPolymodMeta(polyMeta:Dynamic, modPath:String):ModMetadata {
        var meta = new ModMetadata();
        meta.id = extractModId(modPath);
        meta.path = modPath;
        meta.modType = POLYMOD_ONLY;

        if (polyMeta != null) {
            meta.title = Reflect.hasField(polyMeta, "title") ? polyMeta.title : meta.id;
            meta.description = Reflect.hasField(polyMeta, "description") ? polyMeta.description : "";
            meta.author = Reflect.hasField(polyMeta, "author") ? polyMeta.author : "Unknown";
            meta.version = Reflect.hasField(polyMeta, "modVersion") ? polyMeta.modVersion : "1.0.0";
            meta.apiVersion = Reflect.hasField(polyMeta, "apiVersion") ? polyMeta.apiVersion : "1.0.0";

            if (Reflect.hasField(polyMeta, "dependencies") && polyMeta.dependencies != null) {
                meta.dependencies = polyMeta.dependencies;
            }

            meta.polymodMeta = {
                title: meta.title,
                description: meta.description,
                author: meta.author,
                modVersion: meta.version,
                apiVersion: meta.apiVersion
            };
        }

        return meta;
    }

    public function mergeWithPolymod(polyMeta:Dynamic):Void {
        modType = HYBRID;
        if (polyMeta != null) {
            polymodMeta = {
                title: Reflect.hasField(polyMeta, "title") ? polyMeta.title : title,
                description: Reflect.hasField(polyMeta, "description") ? polyMeta.description : description,
                author: Reflect.hasField(polyMeta, "author") ? polyMeta.author : author,
                modVersion: Reflect.hasField(polyMeta, "modVersion") ? polyMeta.modVersion : version,
                apiVersion: Reflect.hasField(polyMeta, "apiVersion") ? polyMeta.apiVersion : "1.0.0"
            };

            if (Reflect.hasField(polyMeta, "dependencies") && polyMeta.dependencies != null) {
                dependencies = polyMeta.dependencies;
            }
        }
    }

    public function mergeWithPsych(packJson:Dynamic):Void {
        modType = HYBRID;
        if (packJson != null) {
            psychPackData = {
                name: Reflect.hasField(packJson, "name") ? packJson.name : title,
                description: Reflect.hasField(packJson, "description") ? packJson.description : description,
                runsGlobally: Reflect.hasField(packJson, "runsGlobally") ? packJson.runsGlobally : false,
                color: Reflect.hasField(packJson, "color") ? packJson.color : [170, 0, 255]
            };
        }
    }

    private static function extractModId(modPath:String):String {
        var normalized = StringTools.replace(modPath, "\\", "/");
        // Sondaki slash'ı kaldır
        if (StringTools.endsWith(normalized, "/"))
            normalized = normalized.substr(0, normalized.length - 1);

        var parts = normalized.split("/");
        return parts[parts.length - 1];
    }

    public function toString():String {
        return '[Mod: ' + id + ' | Type: ' + modType + ' | v' + version + ' | Enabled: ' + enabled + ']';
    }
}

// Bu enum'lar dosya dışında, package seviyesinde tanımlanıyor
// böylece modcore.ModType olarak erişilebilir

enum ModType {
    PSYCH_ONLY;
    POLYMOD_ONLY;
    HYBRID;
}

typedef PsychPackData = {
    var name:String;
    var description:String;
    var runsGlobally:Bool;
    var color:Array<Int>;
}

typedef PolymodMetaData = {
    var title:String;
    var description:String;
    var author:String;
    var modVersion:String;
    var apiVersion:String;
}