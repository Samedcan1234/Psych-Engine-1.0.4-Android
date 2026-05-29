package states.multiplayer.api;

import haxe.Http;
import haxe.Json;
import haxe.io.Bytes;
import states.multiplayer.data.ModTypes;
import sys.thread.Thread;
import sys.ssl.Socket as SSLSocket;
import sys.net.Socket as NetSocket;
import sys.net.Host;

class GameBananaAPI
{
    static final API_SEARCH:String     = "https://gamebanana.com/apiv11/Game/8694/Subfeed";
    static final API_MOD_INFO:String   = "https://gamebanana.com/apiv11/Mod";
    static final API_COLLECTION:String = "https://gamebanana.com/apiv11/Collection";
    static final FNF_GAME_ID:Int       = 8694;
    static final RESULTS_PER_PAGE:Int  = 15;

    static var pendingCallbacks:Array<() -> Void> = [];
    static var imageCache:Map<String, Bytes>      = new Map();

    public static function runOnMain(fn:() -> Void):Void {
        pendingCallbacks.push(fn);
    }

    public static function processPendingCallbacks():Void {
        if (pendingCallbacks.length == 0) return;
        var toRun = pendingCallbacks.copy();
        pendingCallbacks = [];
        for (fn in toRun) {
            try { fn(); }
            catch (e:Dynamic) { trace("[API] Callback error: " + e); }
        }
    }

    public static function clearImageCache():Void {
        imageCache.clear();
    }

    static function parseURL(url:String):{host:String, path:String, port:Int, isHttps:Bool}
    {
        var isHttps = StringTools.startsWith(url, "https://");
        var rest    = url.substr(isHttps ? 8 : 7);

        var slashIdx = rest.indexOf("/");
        var hostPort = slashIdx == -1 ? rest       : rest.substr(0, slashIdx);
        var path     = slashIdx == -1 ? "/"        : rest.substr(slashIdx);

        var port     = isHttps ? 443 : 80;
        var colonIdx = hostPort.indexOf(":");
        var host     = colonIdx == -1 ? hostPort : hostPort.substr(0, colonIdx);
        if (colonIdx != -1)
            port = Std.parseInt(hostPort.substr(colonIdx + 1)) ?? port;

        return {host: host, path: path, port: port, isHttps: isHttps};
    }

	static function rawRequest(url:String, wantBytes:Bool):{ text:Null<String>, bytes:Null<Bytes>, error:Null<String> }
	{
		var result = {text: null, bytes: null, error: null};

		try {
			var p      = parseURL(url);
			var reqStr = 'GET ${p.path} HTTP/1.0\r\n'
					   + 'Host: ${p.host}\r\n'
					   + 'User-Agent: PsychEngineUltra/1.0\r\n'
					   + 'Accept: */*\r\n'
					   + 'Connection: close\r\n\r\n';

			trace('[API] Connecting to ${p.host}:${p.port} (SSL: ${p.isHttps})');

			var input:haxe.io.Input;

			if (p.isHttps) {
				var ssl        = new sys.ssl.Socket();
				ssl.verifyCert = false;
				ssl.connect(new sys.net.Host(p.host), p.port);
				ssl.write(reqStr);
				input = ssl.input;
			} else {
				var tcp = new sys.net.Socket();
				tcp.connect(new sys.net.Host(p.host), p.port);
				tcp.write(reqStr);
				input = tcp.input;
			}

			var rawOut = new haxe.io.BytesOutput();
			var buf    = haxe.io.Bytes.alloc(16384);

			while (true) {
				var n = 0;
				try { n = input.readBytes(buf, 0, buf.length); }
				catch (_:Dynamic) { break; }
				if (n <= 0) break;
				rawOut.writeBytes(buf, 0, n);
			}

			var fullBytes = rawOut.getBytes();
			var fullLen   = fullBytes.length;
			trace('[API] Total response size: $fullLen bytes');

			if (fullLen == 0) {
				result.error = "Empty response";
				return result;
			}

			var sepPos = -1;
			var sepLen = 4;

			for (i in 0...(fullLen - 3)) {
				if (fullBytes.get(i)   == 13 && 

					fullBytes.get(i+1) == 10 && 

					fullBytes.get(i+2) == 13 && 

					fullBytes.get(i+3) == 10)   

				{
					sepPos = i;
					break;
				}
			}

			if (sepPos == -1) {
				trace("[API] No header separator found, using full response");
				sepPos = 0;
				sepLen = 0;
			}

			var bodyStart = sepPos + sepLen;
			var bodyLen   = fullLen - bodyStart;

			trace('[API] Header ends at: $sepPos, body starts at: $bodyStart, body length: $bodyLen');

			var headerBytes = fullBytes.sub(0, sepPos);
			var headerStr   = headerBytes.toString();
			var statusLine  = headerStr.split("\r\n")[0];
			trace('[API] HTTP Status: $statusLine');

			if (bodyLen <= 0) {
				result.error = "Empty body";
				return result;
			}

			var bodyBytes = fullBytes.sub(bodyStart, bodyLen);

			if (wantBytes) {
				result.bytes = bodyBytes;
				trace('[API] Body bytes length: ${bodyBytes.length}');
			} else {
				result.text = bodyBytes.toString();
				trace('[API] Body text length: ${result.text.length}');
			}
		}
		catch (e:Dynamic) {
			result.error = Std.string(e);
			trace("[API] rawRequest error: " + result.error);
		}

		return result;
	}

    public static function searchMods(
        options:SearchOptions,
        callback:(mods:Array<ModEntry>, error:Null<String>) -> Void
    ):Void {
        Thread.create(() -> {
            try {
                var url = buildSearchURL(options);
                trace("[API] Search URL: " + url);

                var res = rawRequest(url, false);

                if (res.error != null || res.text == null) {
                    runOnMain(() -> callback(null, res.error ?? "No response"));
                    return;
                }

                trace("[API] Response preview: " + res.text.substr(0, 200));
                var parsed = parseSearchResults(res.text);
                trace("[API] Parsed mods: " + parsed.length);
                runOnMain(() -> callback(parsed, null));
            }
            catch (e:Dynamic) {
                runOnMain(() -> callback(null, "Search error: " + Std.string(e)));
            }
        });
    }

    public static function fetchCollection(
        collectionID:String,
        page:Int,
        callback:(mods:Array<ModEntry>, error:Null<String>) -> Void
    ):Void {
        Thread.create(() -> {
            try {
                var url = '$API_COLLECTION/$collectionID/Items'
                        + '?_nPage=$page&_nPerpage=$RESULTS_PER_PAGE';

                var res = rawRequest(url, false);

                if (res.error != null || res.text == null) {
                    runOnMain(() -> callback(null, res.error ?? "No response"));
                    return;
                }

                var parsed = parseSearchResults(res.text);
                runOnMain(() -> callback(parsed, null));
            }
            catch (e:Dynamic) {
                runOnMain(() -> callback(null, "Collection error: " + Std.string(e)));
            }
        });
    }

	public static function fetchModDownloads(
		modID:Float,
		callback:(info:Null<ModDownloadInfo>, error:Null<String>) -> Void
	):Void {
		Thread.create(() -> {
			try {

				var url = 'https://gamebanana.com/apiv11/Mod/${Std.int(modID)}?'
						+ '_csvProperties=_aFiles,_bIsTrashed,_bIsWithheld,_sName,_idRow';

				trace("[API] Download URL: " + url);

				var res = rawRequest(url, false);

				if (res.error != null || res.text == null) {
					runOnMain(() -> callback(null, res.error ?? "No response"));
					return;
				}

				trace("[API] Download response: " + res.text.substr(0, 400));
				var info = parseDownloadInfo(res.text, modID);
				runOnMain(() -> callback(info, null));
			}
			catch (e:Dynamic) {
				runOnMain(() -> callback(null, "Download error: " + Std.string(e)));
			}
		});
	}

    public static function fetchImage(
        url:String,
        callback:(bytes:Null<Bytes>, error:Null<String>) -> Void
    ):Void {
        if (url == null || url.trim() == "") {
            callback(null, "Invalid URL");
            return;
        }

        if (imageCache.exists(url)) {
            callback(imageCache.get(url), null);
            return;
        }

        Thread.create(() -> {
            var res = rawRequest(url, true);

            if (res.error != null || res.bytes == null) {
                runOnMain(() -> callback(null, res.error ?? "No image data"));
                return;
            }

            if (res.bytes.length < 100) {
                runOnMain(() -> callback(null, "Invalid image data"));
                return;
            }

            imageCache.set(url, res.bytes);
            runOnMain(() -> callback(res.bytes, null));
        });
    }

    static function buildSearchURL(options:SearchOptions):String
    {
        if (options.query != null && options.query.trim() != "")
            return buildSearchQueryURL(options);

        var params = [
            '_nPage=${options.page}',
            '_nPerpage=$RESULTS_PER_PAGE',
            '_sSort=${options.sortOrder != null ? options.sortOrder : "new"}'
        ];
        return '$API_SEARCH?${params.join("&")}';
    }

    static function buildSearchQueryURL(options:SearchOptions):String
    {
        var base   = "https://gamebanana.com/apiv11/Util/Search/Results";
        var params = [
            '_sModelName=Mod',
            '_idGameRow=$FNF_GAME_ID',
            '_nPage=${options.page}',
            '_nPerpage=$RESULTS_PER_PAGE',
            '_sSearch=${StringTools.urlEncode(options.query.trim())}'
        ];
        return '$base?${params.join("&")}';
    }

	static function parseSearchResults(rawData:String):Array<ModEntry>
	{
		var entries:Array<ModEntry> = [];
		var json:Dynamic = null;

		try { json = Json.parse(rawData); }
		catch (e:Dynamic) {
			trace("[API] JSON parse error: " + e);
			return entries;
		}

		var records:Array<Dynamic> = null;
		if      (json._aRecords != null)    records = cast json._aRecords;
		else if (Std.isOfType(json, Array)) records = cast json;
		else {
			if (json.error != null) trace("[API] API error: " + json.error);
			return entries;
		}

		trace("[API] Total records: " + records.length);

		for (record in records) {

			var modelName:String = record._sModelName != null ? record._sModelName : "";
			if (modelName != "Mod") {
				trace("[API] Skipping non-Mod: " + modelName + " - " + record._sName);
				continue;
			}

			var entry = buildModEntry(record);
			if (entry != null) {
				entries.push(entry);
				trace("[API] Added mod: " + entry.name);
			}
		}

		trace("[API] Final mod count: " + entries.length);
		return entries;
	}

	static function buildModEntry(record:Dynamic):Null<ModEntry>
	{
		try {
			var id:Float    = record._idRow       != null ? record._idRow       : 0;
			var name:String = record._sName       != null ? record._sName       : "Unknown";
			var profileUrl  = record._sProfileUrl != null ? record._sProfileUrl : "";

			var media:Dynamic         = record._aPreviewMedia;
			var images:Array<Dynamic> = [];
			if (media != null) {
				if      (media._aImages != null) images = cast media._aImages;
				else if (media.images   != null) images = cast media.images;
			}

			var thumbnail:ModThumbnail;
			var previews:Array<ModThumbnail> = [];

			if (images.length > 0) {
				var fi = images[0];

				var baseUrl:String = fi._sBaseUrl != null ? fi._sBaseUrl : "";
				var tUrl = buildImageURL(baseUrl, fi);

				thumbnail = {
					url:    tUrl,
					width:  fi._wFile220 != null ? fi._wFile220 : 220,
					height: fi._hFile220 != null ? fi._hFile220 : 125
				};

				trace("[API] Thumbnail URL: " + tUrl);

				for (i in 1...images.length) {
					var img  = images[i];
					var iUrl = buildImageURL(
						img._sBaseUrl != null ? img._sBaseUrl : baseUrl,
						img
					);
					if (iUrl != "") {
						previews.push({url: iUrl, width: 220, height: 125});
					}
				}
			} else {
				thumbnail = {url: "", width: 220, height: 125};
			}

			var cat:Dynamic = record._aRootCategory != null ? record._aRootCategory : {};

			return {
				id:             id,
				name:           name,
				url:            profileUrl,
				category:       cat._sName    != null ? cat._sName    : "Mod",
				categoryIconURL: cat._sIconUrl != null ? cat._sIconUrl : null,
				likes:          record._nLikeCount     != null ? record._nLikeCount     : 0,
				downloadCount:  record._nDownloadCount != null ? record._nDownloadCount : null,
				thumbnail:      thumbnail,
				previews:       previews
			};
		}
		catch (e:Dynamic) {
			trace("[API] buildModEntry error: " + e);
			return null;
		}
	}

	static function buildImageURL(baseUrl:String, imageData:Dynamic):String
	{

		if (imageData._sFile220 != null && imageData._sFile220 != "") {
			var file220:String = imageData._sFile220;

			if (StringTools.startsWith(file220, "http")) return file220;

			return '$baseUrl/$file220';
		}

		if (imageData._sFile != null && imageData._sFile != "") {
			var file:String = imageData._sFile;
			if (StringTools.startsWith(file, "http")) return file;
			return '$baseUrl/$file';
		}

		if (imageData.url != null) return imageData.url;

		return "";
	}

    static function parseDownloadInfo(rawData:String, modID:Float):Null<ModDownloadInfo>
    {
        var json:Dynamic = null;
        try { json = Json.parse(rawData); }
        catch (e:Dynamic) { return null; }

        var files:Array<Dynamic>             = json._aFiles != null ? json._aFiles : [];
        var downloadFiles:Array<ModDownloadFile> = [];

        for (file in files) {
            downloadFiles.push({
                filename:    file._sFile        != null ? file._sFile        : "mod.zip",
                downloadURL: file._sDownloadUrl != null ? file._sDownloadUrl : "",
                fileSize:    file._nFilesize    != null ? file._nFilesize    : null,
                description: file._sDescription != null ? file._sDescription : null,
                dateAdded:   file._tsDateAdded  != null ? file._tsDateAdded  : null
            });
        }

        return {
            files:      downloadFiles,
            isTrashed:  json._bIsTrashed  != null ? json._bIsTrashed  : false,
            isWithheld: json._bIsWithheld != null ? json._bIsWithheld : false,
            name:       json._sName       != null ? json._sName       : "Unknown",
            id:         modID
        };
    }
}