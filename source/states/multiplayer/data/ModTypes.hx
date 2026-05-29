package states.multiplayer.data;

/**
 * Psych Engine Ultra - Online Mods System
 * Mod veri yapıları
 */

typedef ModEntry = {
    var id:Float;
    var name:String;
    var url:String;
    var category:String;
    var categoryIconURL:Null<String>;
    var likes:Null<Float>;
    var downloadCount:Null<Float>;
    var thumbnail:ModThumbnail;
    var previews:Array<ModThumbnail>;
}

typedef ModThumbnail = {
    var url:String;
    var width:Float;
    var height:Float;
}

typedef ModDownloadFile = {
    var filename:String;
    var downloadURL:String;
    var fileSize:Null<Float>;
    var description:Null<String>;
    var dateAdded:Null<Float>;
}

typedef ModDownloadInfo = {
    var files:Array<ModDownloadFile>;
    var isTrashed:Bool;
    var isWithheld:Bool;
    var name:String;
    var id:Float;
}

typedef SearchOptions = {
    var ?query:Null<String>;
    var ?sortOrder:Null<String>;
    var ?collectionID:Null<String>;
    var page:Int;
}