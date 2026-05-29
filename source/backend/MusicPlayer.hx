package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import openfl.display.BitmapData;
import openfl.display.Shape;
import backend.Language;

#if sys
import sys.FileSystem;
#end

class MusicPlayer extends FlxSpriteGroup
{
    public static var instance:MusicPlayer;

    public var isPlaying:Bool = false;
    public var currentTrackIndex:Int = 0;
    public var _musicSound:FlxSound;

    private var _mainPanel:FlxSprite;
    private var _titleText:FlxText;
    private var _diskSprite:FlxSprite;
    private var _diskRotation:Float = 0;

    private var _songNameText:FlxText;
    private var _songLabel:FlxText;

    private var _progressBarBG:FlxSprite;
    private var _progressBarFill:FlxSprite;
    private var _timeText:FlxText;

    private var _prevBtn:FlxSprite;
    private var _prevIcon:FlxText;
    private var _playPauseBtn:FlxSprite;
    private var _playPauseIcon:FlxText;
    private var _nextBtn:FlxSprite;
    private var _nextIcon:FlxText;

    private var _resizeHandle:FlxSprite;
    private var _isResizing:Bool = false;
    private var _resizeStartPoint:FlxPoint;
    private var _resizeStartSize:FlxPoint;

    private var _isDragging:Bool = false;
    private var _dragOffset:FlxPoint;

    private var _trackList:Array<String> = [];
    private var _trackNames:Array<String> = [];

    private var _panelWidth:Int = 320;
    private var _panelHeight:Int = 160;
    private var _minWidth:Int = 250;
    private var _maxWidth:Int = 500;
    private var _minHeight:Int = 140;
    private var _maxHeight:Int = 250;

    private var _currentTime:Float = 0;
    private var _totalTime:Float = 0;

    private var _btnY:Float = 0;
    private var _btnSize:Int = 40;
    private var _btnStartX:Float = 0;
    private var _btnSpacing:Int = 20;

    private var _originalMusicVolume:Float = 0;
    private var _originalMusicWasPlaying:Bool = false;

    public function new()
    {
        super();
        instance = this;

        scrollFactor.set();

        _dragOffset = FlxPoint.get();
        _resizeStartPoint = FlxPoint.get();
        _resizeStartSize = FlxPoint.get();

        loadMusicList();
        loadSavedPosition();
        createUI();

        if (_trackList.length > 0 && _trackList[0] != "default")
        {
            new FlxTimer().start(0.5, function(_) {
                playTrack(0);
            });
        }
    }

    private function loadSavedPosition():Void
    {
        var savedX = Reflect.field(FlxG.save.data, "musicplayer_x");
        var savedY = Reflect.field(FlxG.save.data, "musicplayer_y");
        var savedW = Reflect.field(FlxG.save.data, "musicplayer_w");
        var savedH = Reflect.field(FlxG.save.data, "musicplayer_h");

        if (savedX != null && savedY != null)
        {
            x = savedX;
            y = savedY;
        }
        else
        {
            x = FlxG.width - _panelWidth - 20;
            y = 20;
        }

        if (savedW != null && savedH != null)
        {
            _panelWidth = Std.int(Math.max(_minWidth, Math.min(_maxWidth, savedW)));
            _panelHeight = Std.int(Math.max(_minHeight, Math.min(_maxHeight, savedH)));
        }
    }

    private function savePosition():Void
    {
        Reflect.setField(FlxG.save.data, "musicplayer_x", x);
        Reflect.setField(FlxG.save.data, "musicplayer_y", y);
        Reflect.setField(FlxG.save.data, "musicplayer_w", _panelWidth);
        Reflect.setField(FlxG.save.data, "musicplayer_h", _panelHeight);
        FlxG.save.flush();
    }

    private function loadMusicList():Void
    {
        _trackList = [];
        _trackNames = [];

        #if sys
        var musicPath:String = "assets/shared/music/musicplayer/";

        try
        {
            if (FileSystem.exists(musicPath) && FileSystem.isDirectory(musicPath))
            {
                for (file in FileSystem.readDirectory(musicPath))
                {
                    var lower:String = file.toLowerCase();

                    if (StringTools.endsWith(lower, ".ogg") || StringTools.endsWith(lower, ".mp3"))
                    {
                        _trackList.push(musicPath + file);

                        var name:String = file;
                        name = StringTools.replace(name, ".ogg", "");
                        name = StringTools.replace(name, ".mp3", "");
                        name = StringTools.replace(name, "_", " ");
                        _trackNames.push(name);
                    }
                }
            }
        }
        catch (e:Dynamic)
        {
            trace("Error loading music list: " + e);
        }
        #end

        if (_trackList.length == 0)
        {
            _trackList.push("default");
            _trackNames.push(Language.getPhrase('musicplayer_no_music', 'No Music Found'));
        }
    }

    private function createUI():Void
    {
        rebuildUI();
    }

    private function rebuildUI():Void
    {

        clear();

        _mainPanel = new FlxSprite(0, 0);
        drawFrostedPanel(_mainPanel, _panelWidth, _panelHeight, 16);
        add(_mainPanel);

        _titleText = new FlxText(50, 12, _panelWidth - 60, Language.getPhrase('musicplayer_title', 'MUSIC PLAYER'), 14);
        _titleText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
        _titleText.alpha = 0.9;
        add(_titleText);

        _diskSprite = new FlxSprite(15, 8);
        drawVinylIcon(_diskSprite, 28);
        _diskSprite.centerOffsets();
        _diskSprite.origin.set(14, 14);
        add(_diskSprite);

        _songLabel = new FlxText(15, 45, _panelWidth - 30, Language.getPhrase('musicplayer_now_playing', 'NOW PLAYING'), 10);
        _songLabel.setFormat(Paths.font("vcr.ttf"), 10, 0xFF888888, LEFT);
        add(_songLabel);

        var currentName:String = Language.getPhrase('musicplayer_loading', 'Loading...');
        if (_trackNames.length > currentTrackIndex)
            currentName = _trackNames[currentTrackIndex];

        _songNameText = new FlxText(15, 58, _panelWidth - 30, currentName, 14);
        _songNameText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
        add(_songNameText);

        _progressBarBG = new FlxSprite(15, 85);
        _progressBarBG.makeGraphic(_panelWidth - 70, 3, 0xFF333333);
        _progressBarBG.alpha = 0.6;
        add(_progressBarBG);

        _progressBarFill = new FlxSprite(15, 85);
        _progressBarFill.makeGraphic(1, 3, FlxColor.WHITE);
        _progressBarFill.alpha = 0.9;
        add(_progressBarFill);

        _timeText = new FlxText(_panelWidth - 50, 80, 40, "0:00", 12);
        _timeText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT);
        _timeText.alpha = 0.8;
        add(_timeText);

        _btnY = _panelHeight - 50;
        _btnSize = 40;
        _btnSpacing = 20;
        var totalBtnWidth:Float = _btnSize * 3 + _btnSpacing * 2;
        _btnStartX = (_panelWidth - totalBtnWidth) / 2;

        _prevBtn = new FlxSprite(_btnStartX, _btnY);
        drawControlButton(_prevBtn, _btnSize, false);
        add(_prevBtn);

        _prevIcon = new FlxText(_btnStartX, _btnY + 10, _btnSize, "<<", 18);
        _prevIcon.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
        add(_prevIcon);

        _playPauseBtn = new FlxSprite(_btnStartX + _btnSize + _btnSpacing, _btnY - 2);
        drawControlButton(_playPauseBtn, _btnSize + 4, true);
        add(_playPauseBtn);

        var ppIcon:String = isPlaying ? "||" : ">";
        _playPauseIcon = new FlxText(_btnStartX + _btnSize + _btnSpacing, _btnY + 8, _btnSize + 4, ppIcon, 22);
        _playPauseIcon.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
        add(_playPauseIcon);

        _nextBtn = new FlxSprite(_btnStartX + (_btnSize + _btnSpacing) * 2, _btnY);
        drawControlButton(_nextBtn, _btnSize, false);
        add(_nextBtn);

        _nextIcon = new FlxText(_btnStartX + (_btnSize + _btnSpacing) * 2, _btnY + 10, _btnSize, ">>", 18);
        _nextIcon.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
        add(_nextIcon);

        _resizeHandle = new FlxSprite(_panelWidth - 20, _panelHeight - 20);
        drawResizeHandle(_resizeHandle, 18, false);
        add(_resizeHandle);
    }

    private function drawFrostedPanel(sprite:FlxSprite, w:Int, h:Int, radius:Int):Void
    {
        var shape:Shape = new Shape();

        shape.graphics.beginFill(0x1A1A1A, 0.85);
        shape.graphics.drawRoundRect(0, 0, w, h, radius, radius);
        shape.graphics.endFill();

        shape.graphics.lineStyle(1, 0xFFFFFF, 0.15);
        shape.graphics.drawRoundRect(0.5, 0.5, w - 1, h - 1, radius, radius);

        shape.graphics.beginFill(0xFFFFFF, 0.03);
        shape.graphics.drawRoundRect(2, 2, w - 4, h / 3, radius - 2, radius - 2);
        shape.graphics.endFill();

        var bitmapData:BitmapData = new BitmapData(w, h, true, 0x00000000);
        bitmapData.draw(shape);

        sprite.loadGraphic(bitmapData);
    }

    private function drawControlButton(sprite:FlxSprite, size:Int, isMain:Bool):Void
    {
        var shape:Shape = new Shape();

        if (isMain)
        {
            shape.graphics.lineStyle(2, 0xFFFFFF, 0.8);
            shape.graphics.beginFill(0x2A2A2A, 0.6);
            shape.graphics.drawRoundRect(0, 0, size, size, size / 2, size / 2);
            shape.graphics.endFill();
        }
        else
        {
            shape.graphics.beginFill(0x2A2A2A, 0.4);
            shape.graphics.drawRoundRect(0, 0, size, size, 10, 10);
            shape.graphics.endFill();
        }

        var bitmapData:BitmapData = new BitmapData(size, size, true, 0x00000000);
        bitmapData.draw(shape);

        sprite.loadGraphic(bitmapData);
    }

    private function drawVinylIcon(sprite:FlxSprite, size:Int):Void
    {
        var shape:Shape = new Shape();

        shape.graphics.beginFill(0x111111, 1);
        shape.graphics.drawCircle(size / 2, size / 2, size / 2);
        shape.graphics.endFill();

        shape.graphics.beginFill(0x333333, 1);
        shape.graphics.drawCircle(size / 2, size / 2, size / 4);
        shape.graphics.endFill();

        shape.graphics.beginFill(0x000000, 1);
        shape.graphics.drawCircle(size / 2, size / 2, size / 10);
        shape.graphics.endFill();

        shape.graphics.lineStyle(1, 0xFFFFFF, 0.3);
        shape.graphics.drawCircle(size / 2, size / 2, size / 3);

        var bitmapData:BitmapData = new BitmapData(size, size, true, 0x00000000);
        bitmapData.draw(shape);

        sprite.loadGraphic(bitmapData);
    }

    private function drawResizeHandle(sprite:FlxSprite, size:Int, hovered:Bool):Void
    {
        var shape:Shape = new Shape();

        var alpha:Float = hovered ? 0.8 : 0.4;
        var color:Int = hovered ? 0x6688FF : 0xFFFFFF;

        shape.graphics.beginFill(color, alpha);
        shape.graphics.moveTo(size, 0);
        shape.graphics.lineTo(size, size);
        shape.graphics.lineTo(0, size);
        shape.graphics.lineTo(size, 0);
        shape.graphics.endFill();

        shape.graphics.lineStyle(1, 0x000000, 0.3);
        shape.graphics.moveTo(size - 4, 4);
        shape.graphics.lineTo(size - 4, size - 4);
        shape.graphics.lineTo(4, size - 4);

        shape.graphics.moveTo(size - 8, 8);
        shape.graphics.lineTo(size - 8, size - 8);
        shape.graphics.lineTo(8, size - 8);

        var bitmapData:BitmapData = new BitmapData(size, size, true, 0x00000000);
        bitmapData.draw(shape);

        sprite.loadGraphic(bitmapData);
    }

    public function playTrack(index:Int):Void
    {
        if (index < 0 || index >= _trackList.length) return;
        if (_trackList[index] == "default") 
        {
            _songNameText.text = Language.getPhrase('musicplayer_no_music', 'No Music Found');
            return;
        }

        currentTrackIndex = index;
        stopMusic();

        pauseFreakyMenu();

        var path:String = _trackList[index];

        #if sys
        if (!FileSystem.exists(path))
        {
            _songNameText.text = Language.getPhrase('musicplayer_file_not_found', 'File Not Found');
            return;
        }
        #end

        try
        {
            var soundPath:String = path;
            soundPath = StringTools.replace(soundPath, "assets/shared/music/", "");
            soundPath = StringTools.replace(soundPath, ".ogg", "");
            soundPath = StringTools.replace(soundPath, ".mp3", "");

            _musicSound = FlxG.sound.play(Paths.music(soundPath), 1, false);

            if (_musicSound != null)
            {
                _musicSound.onComplete = function() {
                    nextTrack();
                };

                isPlaying = true;
                if (_playPauseIcon != null)
                    _playPauseIcon.text = "||";
                if (_songNameText != null)
                    _songNameText.text = _trackNames[index];
                _totalTime = 0;
                _currentTime = 0;
            }
            else
            {
                _songNameText.text = Language.getPhrase('musicplayer_play_error', 'Play Error');
            }
        }
        catch (e:Dynamic)
        {
            trace("Error loading track: " + e);
            _songNameText.text = Language.getPhrase('musicplayer_error', 'Error');
        }
    }

    private function pauseFreakyMenu():Void
    {
        if (FlxG.sound.music != null && FlxG.sound.music.playing)
        {
            _originalMusicWasPlaying = true;
            _originalMusicVolume = FlxG.sound.music.volume;
            FlxG.sound.music.pause();
        }
    }

    private function resumeFreakyMenu():Void
    {
        if (_originalMusicWasPlaying && FlxG.sound.music != null)
        {
            FlxG.sound.music.resume();
            FlxG.sound.music.volume = _originalMusicVolume;
        }
    }

    public function stopMusic():Void
    {
        if (_musicSound != null)
        {
            _musicSound.stop();
            _musicSound.destroy();
            _musicSound = null;
        }
        isPlaying = false;
        if (_playPauseIcon != null)
            _playPauseIcon.text = ">";
        _currentTime = 0;
        updateProgressBar();

        resumeFreakyMenu();
    }

    public function togglePlayPause():Void
    {
        if (_musicSound != null)
        {
            if (isPlaying)
            {
                _musicSound.pause();
                isPlaying = false;
                _playPauseIcon.text = ">";

                resumeFreakyMenu();
            }
            else
            {

                pauseFreakyMenu();
                _musicSound.resume();
                isPlaying = true;
                _playPauseIcon.text = "||";
            }
        }
        else if (_trackList.length > 0 && _trackList[0] != "default")
        {
            playTrack(currentTrackIndex);
        }
    }

    public function nextTrack():Void
    {
        var newIndex:Int = currentTrackIndex + 1;
        if (newIndex >= _trackList.length) newIndex = 0;
        playTrack(newIndex);
    }

    public function prevTrack():Void
    {
        if (_currentTime > 3)
        {
            if (_musicSound != null)
            {
                _musicSound.time = 0;
                _currentTime = 0;
            }
            return;
        }

        var newIndex:Int = currentTrackIndex - 1;
        if (newIndex < 0) newIndex = _trackList.length - 1;
        playTrack(newIndex);
    }

    private function updateProgressBar():Void
    {
        if (_progressBarFill == null || _progressBarBG == null) return;

        if (_totalTime > 0)
        {
            var progress:Float = _currentTime / _totalTime;
            var maxBarWidth:Int = _panelWidth - 70;
            var barWidth:Int = Std.int(maxBarWidth * Math.min(1, Math.max(0, progress)));
            if (barWidth < 1) barWidth = 1;
            _progressBarFill.makeGraphic(barWidth, 3, FlxColor.WHITE);
        }

        if (_timeText != null)
        {
            var minutes:Int = Math.floor(_currentTime / 60);
            var seconds:Int = Math.floor(_currentTime % 60);
            _timeText.text = minutes + ":" + StringTools.lpad(Std.string(seconds), "0", 2);
        }
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (isPlaying && _diskSprite != null)
        {
            _diskRotation += elapsed * 45;
            if (_diskRotation >= 360) _diskRotation -= 360;
            _diskSprite.angle = _diskRotation;
        }

        if (_musicSound != null && isPlaying)
        {
            _currentTime = _musicSound.time / 1000;

            @:privateAccess
            if (_musicSound._sound != null && _musicSound._sound.length > 0)
            {
                _totalTime = _musicSound._sound.length / 1000;
            }

            updateProgressBar();
        }

        handleDragging();
        handleResizing();
        handleInput();
    }

    private function handleDragging():Void
    {
        var mx:Float = FlxG.mouse.screenX;
        var my:Float = FlxG.mouse.screenY;

        if (FlxG.mouse.justPressed && !_isResizing)
        {
            var headerX:Float = x;
            var headerY:Float = y;
            var headerW:Float = _panelWidth;
            var headerH:Float = 40;

            var resizeX:Float = x + _panelWidth - 20;
            var resizeY:Float = y + _panelHeight - 20;
            var overResize:Bool = mx >= resizeX && mx <= resizeX + 20 && my >= resizeY && my <= resizeY + 20;

            if (!overResize && mx >= headerX && mx <= headerX + headerW && my >= headerY && my <= headerY + headerH)
            {
                _isDragging = true;
                _dragOffset.set(mx - x, my - y);
            }
        }

        if (_isDragging)
        {
            if (FlxG.mouse.pressed)
            {
                x = mx - _dragOffset.x;
                y = my - _dragOffset.y;

                x = Math.max(0, Math.min(FlxG.width - _panelWidth, x));
                y = Math.max(0, Math.min(FlxG.height - _panelHeight, y));
            }
            else
            {
                _isDragging = false;
                savePosition();
            }
        }
    }

    private function handleResizing():Void
    {
        var mx:Float = FlxG.mouse.screenX;
        var my:Float = FlxG.mouse.screenY;

        var resizeX:Float = x + _panelWidth - 20;
        var resizeY:Float = y + _panelHeight - 20;
        var overResize:Bool = mx >= resizeX && mx <= resizeX + 20 && my >= resizeY && my <= resizeY + 20;

        if (_resizeHandle != null)
        {
            if (overResize || _isResizing)
            {
                drawResizeHandle(_resizeHandle, 22, true);
                _resizeHandle.x = _panelWidth - 22;
                _resizeHandle.y = _panelHeight - 22;
            }
            else
            {
                drawResizeHandle(_resizeHandle, 18, false);
                _resizeHandle.x = _panelWidth - 20;
                _resizeHandle.y = _panelHeight - 20;
            }
        }

        if (FlxG.mouse.justPressed && overResize && !_isDragging)
        {
            _isResizing = true;
            _resizeStartPoint.set(mx, my);
            _resizeStartSize.set(_panelWidth, _panelHeight);
        }

        if (_isResizing)
        {
            if (FlxG.mouse.pressed)
            {
                var deltaX:Float = mx - _resizeStartPoint.x;
                var deltaY:Float = my - _resizeStartPoint.y;

                var newWidth:Int = Std.int(_resizeStartSize.x + deltaX);
                var newHeight:Int = Std.int(_resizeStartSize.y + deltaY);

                newWidth = Std.int(Math.max(_minWidth, Math.min(_maxWidth, newWidth)));
                newHeight = Std.int(Math.max(_minHeight, Math.min(_maxHeight, newHeight)));

                if (newWidth != _panelWidth || newHeight != _panelHeight)
                {
                    _panelWidth = newWidth;
                    _panelHeight = newHeight;
                    rebuildUI();
                }
            }
            else
            {
                _isResizing = false;
                savePosition();
            }
        }
    }

    private function handleInput():Void
    {
        if (_isDragging || _isResizing) return;

        if (FlxG.mouse.justPressed)
        {
            var mx:Float = FlxG.mouse.screenX;
            var my:Float = FlxG.mouse.screenY;

            var ppX:Float = x + _btnStartX + _btnSize + _btnSpacing;
            var ppY:Float = y + _btnY - 2;
            var ppSize:Int = _btnSize + 4;

            if (mx >= ppX && mx <= ppX + ppSize && my >= ppY && my <= ppY + ppSize)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
                togglePlayPause();
                return;
            }

            var nextX:Float = x + _btnStartX + (_btnSize + _btnSpacing) * 2;
            var nextY:Float = y + _btnY;

            if (mx >= nextX && mx <= nextX + _btnSize && my >= nextY && my <= nextY + _btnSize)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
                nextTrack();
                return;
            }

            var prevX:Float = x + _btnStartX;
            var prevY:Float = y + _btnY;

            if (mx >= prevX && mx <= prevX + _btnSize && my >= prevY && my <= prevY + _btnSize)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
                prevTrack();
                return;
            }
        }

        var mx:Float = FlxG.mouse.screenX;
        var my:Float = FlxG.mouse.screenY;

        var ppX:Float = x + _btnStartX + _btnSize + _btnSpacing;
        var ppY:Float = y + _btnY - 2;
        var ppSize:Int = _btnSize + 4;

        if (_playPauseBtn != null)
        {
            if (mx >= ppX && mx <= ppX + ppSize && my >= ppY && my <= ppY + ppSize)
                _playPauseBtn.color = 0xFF6688FF;
            else
                _playPauseBtn.color = FlxColor.WHITE;
        }

        var nextX:Float = x + _btnStartX + (_btnSize + _btnSpacing) * 2;
        var nextY:Float = y + _btnY;

        if (_nextBtn != null)
        {
            if (mx >= nextX && mx <= nextX + _btnSize && my >= nextY && my <= nextY + _btnSize)
                _nextBtn.color = 0xFF6688FF;
            else
                _nextBtn.color = FlxColor.WHITE;
        }

        var prevX:Float = x + _btnStartX;
        var prevY:Float = y + _btnY;

        if (_prevBtn != null)
        {
            if (mx >= prevX && mx <= prevX + _btnSize && my >= prevY && my <= prevY + _btnSize)
                _prevBtn.color = 0xFF6688FF;
            else
                _prevBtn.color = FlxColor.WHITE;
        }
    }

    override function destroy():Void
    {
        stopMusic();

        if (_dragOffset != null)
        {
            _dragOffset.put();
            _dragOffset = null;
        }

        if (_resizeStartPoint != null)
        {
            _resizeStartPoint.put();
            _resizeStartPoint = null;
        }

        if (_resizeStartSize != null)
        {
            _resizeStartSize.put();
            _resizeStartSize = null;
        }

        instance = null;
        super.destroy();
    }
}