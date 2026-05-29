package backend;

import openfl.display.BitmapData;
import openfl.display.JPEGEncoderOptions;
import openfl.display.PNGEncoderOptions;
import openfl.utils.ByteArray;
import openfl.geom.Rectangle;
import openfl.events.Event;
import openfl.Lib;
import sys.FileSystem;
import sys.io.File;
import flixel.FlxG;
import haxe.Timer;
import haxe.io.Bytes;

/**
 * Psych Engine Ultra - Built-in Recording System
 * 
 * Harici program GEREKTIRMEZ.
 * OpenFL render'ını kullanır, frame'leri JPEG olarak kaydeder.
 * 
 * Platform desteği:
 *   ✓ Windows
 *   ✓ macOS  
 *   ✓ Linux
 *   ✓ Android
 */
class RecordingSystem
{
    // =========================================================
    // Sabitler
    // =========================================================
    public static inline var RECORDINGS_FOLDER:String  = "recordings";
    public static inline var FRAMES_FOLDER:String      = ".rec_frames";

    // =========================================================
    // Public State
    // =========================================================
    public static var isRecording:Bool   = false;
    public static var frameCount:Int     = 0;
    public static var startTime:Float    = 0.0;
    public static var currentSpec:String = "Balanced";

    // Kayıt bitti callback (UI için)
    public static var onRecordingFinished:String -> Void = null;

    // =========================================================
    // Private
    // =========================================================

    // Frame yakalama
    static var _captureRect:Rectangle   = null;
    static var _frameBuffer:Array<Bytes> = [];
    static var _maxBufferSize:Int        = 300; // 300 frame = ~5 saniye buffer

    // Timing
    static var _lastCaptureTime:Float    = 0.0;
    static var _captureInterval:Float    = 1.0 / 30.0; // 30 FPS default

    // Dosya
    static var _sessionId:String         = "";
    static var _framesDir:String         = "";
    static var _outputPath:String        = "";

    // Async yazma için
    static var _writeQueue:Array<{path:String, data:Bytes}> = [];
    static var _isWriting:Bool           = false;

    // JPEG kalite ayarları
    static var _jpegQuality:Int          = 85;

    // =========================================================
    // Public API
    // =========================================================

    public static function startRecording(spec:String = "Balanced"):Bool
    {
        if (isRecording)
        {
            trace("[RecordingSystem] Zaten kayıt yapılıyor!");
            return false;
        }

        currentSpec = spec;
        _applySpec(spec);

        // Klasörleri hazırla
        _sessionId  = _getTimestamp();
        _framesDir  = '$RECORDINGS_FOLDER/$FRAMES_FOLDER/session_$_sessionId';
        _outputPath = '$RECORDINGS_FOLDER/recording_$_sessionId';

        _ensureFolder(RECORDINGS_FOLDER);
        _ensureFolder('$RECORDINGS_FOLDER/$FRAMES_FOLDER');
        _ensureFolder(_framesDir);

        // Capture rect
        _captureRect = new Rectangle(
            0, 0,
            FlxG.stage.stageWidth,
            FlxG.stage.stageHeight
        );

        // State sıfırla
        isRecording      = true;
        frameCount       = 0;
        startTime        = Timer.stamp();
        _lastCaptureTime = 0.0;
        _frameBuffer     = [];
        _writeQueue      = [];

        trace('[RecordingSystem] ✓ Kayıt başladı!');
        trace('[RecordingSystem] Spec: $spec | Interval: ${_captureInterval}s');
        trace('[RecordingSystem] Frames dir: $_framesDir');

        return true;
    }

    public static function stopRecording():Void
    {
        if (!isRecording)
            return;

        isRecording = false;

        trace('[RecordingSystem] Kayıt durduruluyor... ($frameCount frame)');

        // Kalan buffer'ı diske flush et
        _flushBufferToDisk();

        // Frame'leri birleştirip video oluştur (async)
        _buildVideo();
    }

    /**
     * Her ENTER_FRAME'de Main.hx tarafından çağrılır.
     */
    public static function captureFrame():Void
    {
        if (!isRecording)
            return;

        var now:Float = Timer.stamp();

        // FPS limiti
        if (now - _lastCaptureTime < _captureInterval)
            return;

        _lastCaptureTime = now;

        try
        {
            // ── OpenFL Stage'den yakala ────────────────────────
            var w:Int = Std.int(FlxG.stage.stageWidth);
            var h:Int = Std.int(FlxG.stage.stageHeight);

            var bmd:BitmapData = new BitmapData(w, h, false, 0xFF000000);
            bmd.draw(FlxG.stage); // Tüm ekran, her state dahil

            // ── JPEG encode (hızlı, küçük dosya) ──────────────
            var byteArray:ByteArray = new ByteArray();
            bmd.encode(
                new Rectangle(0, 0, w, h),
                new JPEGEncoderOptions(_jpegQuality),
                byteArray
            );

            bmd.dispose();

            // Haxe Bytes'a çevir
            byteArray.position = 0;
            var bytes:Bytes = Bytes.ofData(byteArray);

            // ── Buffer'a ekle ──────────────────────────────────
            _frameBuffer.push(bytes);
            frameCount++;

            // Buffer dolunca diske yaz
            if (_frameBuffer.length >= _maxBufferSize)
                _flushBufferToDisk();
        }
        catch (e:Dynamic)
        {
            trace('[RecordingSystem] Frame yakalanamadı: $e');
        }
    }

    public static function getElapsedTime():Float
    {
        if (!isRecording) return 0.0;
        return Timer.stamp() - startTime;
    }

    // =========================================================
    // Private - Spec
    // =========================================================

    static function _applySpec(spec:String):Void
    {
        switch (spec)
        {
            case "More Performance":
                _captureInterval = 1.0 / 24.0; // 24 FPS
                _jpegQuality     = 70;
                _maxBufferSize   = 120;

            case "Highest Quality":
                _captureInterval = 1.0 / 60.0; // 60 FPS
                _jpegQuality     = 95;
                _maxBufferSize   = 600;

            default: // Balanced
                _captureInterval = 1.0 / 30.0; // 30 FPS
                _jpegQuality     = 85;
                _maxBufferSize   = 300;
        }
    }

    // =========================================================
    // Private - Disk IO
    // =========================================================

    /**
     * RAM'deki frame buffer'ı diske yazar.
     * Bu sayede uzun kayıtlarda RAM şişmez.
     */
    static function _flushBufferToDisk():Void
    {
        if (_frameBuffer.length == 0)
            return;

        var startIdx:Int = frameCount - _frameBuffer.length;

        for (i in 0..._frameBuffer.length)
        {
            var frameIdx:Int    = startIdx + i;
            var framePath:String = '$_framesDir/frame_${_pad6(frameIdx)}.jpg';

            try
            {
                File.saveBytes(framePath, _frameBuffer[i]);
            }
            catch (e:Dynamic)
            {
                trace('[RecordingSystem] Frame yazma hatası: $e');
            }
        }

        trace('[RecordingSystem] Buffer flush: ${_frameBuffer.length} frame diske yazıldı.');
        _frameBuffer = [];
    }

    // =========================================================
    // Private - Video Build
    // =========================================================

    /**
     * JPEG frame'lerinden video oluşturur.
     * 
     * Strateji:
     *   1. Frame'leri listele
     *   2. Her frame'i oku
     *   3. MJpeg container'a yaz (= motion JPEG, .avi)
     *      Bu format: sadece JPEG frame'leri arka arkaya koymak!
     *      Ekstra kütüphane GEREKTIRMEZ.
     */
    static function _buildVideo():Void
    {
        trace('[RecordingSystem] Video oluşturuluyor...');

        try
        {
            var frames:Array<String> = [];

            // Frame listesini al ve sırala
            if (!FileSystem.exists(_framesDir))
            {
                trace('[RecordingSystem] Frame klasörü bulunamadı!');
                return;
            }

            var files = FileSystem.readDirectory(_framesDir);
            files.sort(function(a, b) return a < b ? -1 : a > b ? 1 : 0);

            for (f in files)
            {
                if (f.endsWith(".jpg"))
                    frames.push('$_framesDir/$f');
            }

            if (frames.length == 0)
            {
                trace('[RecordingSystem] Hiç frame bulunamadı!');
                return;
            }

            trace('[RecordingSystem] ${frames.length} frame bulundu, AVI oluşturuluyor...');

            // ── MJPEG AVI yaz ──────────────────────────────────
            var fps:Int = _getFPS();
            var aviPath:String = _outputPath + ".avi";

            _writeMJpegAvi(frames, aviPath, fps);

            // ── Temp frame'leri temizle ─────────────────────────
            _cleanupFrames();

            trace('[RecordingSystem] ✓ Video tamamlandı: $aviPath');

            if (onRecordingFinished != null)
                onRecordingFinished(aviPath);
        }
        catch (e:Dynamic)
        {
            trace('[RecordingSystem] Video oluşturma hatası: $e');
        }
    }

    /**
     * Pure Haxe MJPEG AVI writer.
     * 
     * MJPEG AVI formatı:
     *   - Standart AVI container
     *   - Her frame = JPEG data
     *   - Hiçbir harici kütüphane gerektirmez
     *   - Windows Media Player, VLC, her player açar
     */
    static function _writeMJpegAvi(
        framePaths:Array<String>,
        outputPath:String,
        fps:Int
    ):Void
    {
        // Frame'leri oku
        var frameDataList:Array<Bytes> = [];
        var totalDataSize:Int = 0;

        for (path in framePaths)
        {
            try
            {
                var data:Bytes = File.getBytes(path);
                frameDataList.push(data);
                totalDataSize += data.length + 8; // chunk header dahil
            }
            catch (e:Dynamic)
            {
                trace('[RecordingSystem] Frame okunamadı: $path | $e');
            }
        }

        if (frameDataList.length == 0)
        {
            trace('[RecordingSystem] Okunabilir frame yok!');
            return;
        }

        // İlk frame'den boyut al
        var firstFrame:Bytes = frameDataList[0];
        var width:Int  = Std.int(FlxG.stage.stageWidth);
        var height:Int = Std.int(FlxG.stage.stageHeight);

        var numFrames:Int    = frameDataList.length;
        var microPerFrame:Int = Std.int(1000000 / fps);

        // ── AVI yapısını hesapla ────────────────────────────────
        // AVI Header boyutları (sabit)
        var aviHeaderSize:Int  = 56;   // avih chunk data
        var strhSize:Int       = 56;   // strh chunk data
        var strfSize:Int       = 40;   // strf chunk data (BITMAPINFOHEADER)

        // LIST 'hdrl' = 4 + (8+aviHeaderSize) + LIST 'strl'
        // LIST 'strl' = 4 + (8+strhSize) + (8+strfSize)
        var strlSize:Int = 4 + (8 + strhSize) + (8 + strfSize);
        var hdrlSize:Int = 4 + (8 + aviHeaderSize) + (8 + strlSize);

        // movi chunk
        var moviDataSize:Int = totalDataSize; // tüm frame'ler
        var moviSize:Int = 4 + moviDataSize;  // 'movi' FourCC + data

        // RIFF boyutu = 4 (AVI ) + (8+hdrlSize) + (8+moviSize)
        var riffSize:Int = 4 + (8 + hdrlSize) + (8 + moviSize);

        // ── Yaz ────────────────────────────────────────────────
        var out = new haxe.io.BytesOutput();
        out.bigEndian = false; // AVI little-endian

        // RIFF header
        _writeStr(out, "RIFF");
        out.writeInt32(riffSize);
        _writeStr(out, "AVI ");

        // LIST hdrl
        _writeStr(out, "LIST");
        out.writeInt32(hdrlSize);
        _writeStr(out, "hdrl");

        // avih - AVI Main Header
        _writeStr(out, "avih");
        out.writeInt32(aviHeaderSize);
        out.writeInt32(microPerFrame);          // dwMicroSecPerFrame
        out.writeInt32(0);                      // dwMaxBytesPerSec
        out.writeInt32(0);                      // dwPaddingGranularity
        out.writeInt32(0x10);                   // dwFlags (AVIF_HASINDEX = 0x10 ... set later)
        out.writeInt32(numFrames);              // dwTotalFrames
        out.writeInt32(0);                      // dwInitialFrames
        out.writeInt32(1);                      // dwStreams
        out.writeInt32(0);                      // dwSuggestedBufferSize
        out.writeInt32(width);                  // dwWidth
        out.writeInt32(height);                 // dwHeight
        out.writeInt32(0);                      // dwReserved[0]
        out.writeInt32(0);                      // dwReserved[1]
        out.writeInt32(0);                      // dwReserved[2]
        out.writeInt32(0);                      // dwReserved[3]

        // LIST strl
        _writeStr(out, "LIST");
        out.writeInt32(strlSize);
        _writeStr(out, "strl");

        // strh - Stream Header (video)
        _writeStr(out, "strh");
        out.writeInt32(strhSize);
        _writeStr(out, "vids");              // fccType
        _writeStr(out, "MJPG");              // fccHandler (MJPEG codec)
        out.writeInt32(0);                   // dwFlags
        out.writeInt16(0);                   // wPriority
        out.writeInt16(0);                   // wLanguage
        out.writeInt32(0);                   // dwInitialFrames
        out.writeInt32(1);                   // dwScale
        out.writeInt32(fps);                 // dwRate (fps/scale = fps)
        out.writeInt32(0);                   // dwStart
        out.writeInt32(numFrames);           // dwLength
        out.writeInt32(0);                   // dwSuggestedBufferSize
        out.writeInt32(-1);                  // dwQuality
        out.writeInt32(0);                   // dwSampleSize
        out.writeInt16(0);                   // rcFrame.left
        out.writeInt16(0);                   // rcFrame.top
        out.writeInt16(width);               // rcFrame.right
        out.writeInt16(height);              // rcFrame.bottom

        // strf - Stream Format (BITMAPINFOHEADER for video)
        _writeStr(out, "strf");
        out.writeInt32(strfSize);
        out.writeInt32(40);                  // biSize
        out.writeInt32(width);               // biWidth
        out.writeInt32(height);              // biHeight
        out.writeInt16(1);                   // biPlanes
        out.writeInt16(24);                  // biBitCount (24bpp)
        _writeStr(out, "MJPG");             // biCompression
        out.writeInt32(width * height * 3); // biSizeImage
        out.writeInt32(0);                   // biXPelsPerMeter
        out.writeInt32(0);                   // biYPelsPerMeter
        out.writeInt32(0);                   // biClrUsed
        out.writeInt32(0);                   // biClrImportant

        // LIST movi - Frame data
        _writeStr(out, "LIST");
        out.writeInt32(moviSize);
        _writeStr(out, "movi");

        // Index için offset kaydet
        var indexEntries:Array<{offset:Int, size:Int}> = [];
        var currentOffset:Int = 4; // 'movi' FourCC sonrası

        for (frameData in frameDataList)
        {
            var frameSize:Int = frameData.length;

            // Padding (AVI chunk'ları 2-byte aligned olmalı)
            var paddedSize:Int = frameSize + (frameSize % 2);

            indexEntries.push({
                offset: currentOffset,
                size: frameSize
            });

            // '00dc' = video frame chunk ID (stream 0, compressed video)
            _writeStr(out, "00dc");
            out.writeInt32(frameSize);
            out.write(frameData);

            // Padding byte
            if (frameSize % 2 != 0)
                out.writeByte(0);

            currentOffset += 8 + paddedSize;
        }

        // idx1 - AVI Index (eski format ama geniş uyumluluk için)
        var idxSize:Int = indexEntries.length * 16;
        _writeStr(out, "idx1");
        out.writeInt32(idxSize);

        for (entry in indexEntries)
        {
            _writeStr(out, "00dc");          // chunk ID
            out.writeInt32(0x10);            // flags (AVIIF_KEYFRAME)
            out.writeInt32(entry.offset);    // offset (movi'den)
            out.writeInt32(entry.size);      // chunk size
        }

        // ── Dosyaya yaz ────────────────────────────────────────
        File.saveBytes(outputPath, out.getBytes());

        trace('[RecordingSystem] ✓ AVI yazıldı: $outputPath (${frameDataList.length} frame, ${fps}fps)');
    }

    // =========================================================
    // Private - Cleanup
    // =========================================================

    static function _cleanupFrames():Void
    {
        try
        {
            if (FileSystem.exists(_framesDir))
            {
                for (f in FileSystem.readDirectory(_framesDir))
                    FileSystem.deleteFile('$_framesDir/$f');

                FileSystem.deleteDirectory(_framesDir);
            }
        }
        catch (e:Dynamic)
        {
            trace('[RecordingSystem] Cleanup hatası: $e');
        }
    }

    // =========================================================
    // Private - Utilities
    // =========================================================

    static function _writeStr(out:haxe.io.BytesOutput, s:String):Void
    {
        for (i in 0...s.length)
            out.writeByte(s.charCodeAt(i));
    }

    static function _getFPS():Int
    {
        return switch (currentSpec)
        {
            case "More Performance": 24;
            case "Highest Quality":  60;
            default:                 30;
        };
    }

    static function _ensureFolder(path:String):Void
    {
        #if sys
        if (!FileSystem.exists(path))
            FileSystem.createDirectory(path);
        #end
    }

    static function _getTimestamp():String
    {
        var d:Date = Date.now();
        return '${d.getFullYear()}-${_pad(d.getMonth()+1)}-${_pad(d.getDate())}'
             + '_${_pad(d.getHours())}-${_pad(d.getMinutes())}-${_pad(d.getSeconds())}';
    }

    static function _pad(n:Int):String
        return n < 10 ? '0$n' : '$n';

    static function _pad6(n:Int):String
    {
        var s = Std.string(n);
        while (s.length < 6) s = '0$s';
        return s;
    }
}