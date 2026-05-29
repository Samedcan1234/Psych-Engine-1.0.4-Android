package ui;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.AntiAliasType;
import openfl.events.Event;
import openfl.Lib;
import haxe.Timer;
import backend.RecordingSystem;

/**
 * Psych Engine Ultra - Global Recording HUD
 *
 * OpenFL Sprite olarak çalışır (FlxSprite DEĞİL!).
 * Doğrudan stage'e eklenir, her state'in üstünde görünür.
 */
class RecordingHUD extends Sprite
{
    // =========================================================
    // UI Elemanları
    // =========================================================

    /** Arka plan (yuvarlatılmış dikdörtgen) */
    var _bg:Shape;

    /** Kırmızı nokta */
    var _dot:Shape;

    /** REC yazısı */
    var _label:TextField;

    /** Hata arka planı - SPRITE olarak değiştirildi! */
    var _errorBg:Sprite;

    /** Hata metni */
    var _errorLabel:TextField;

    // =========================================================
    // Animasyon State
    // =========================================================

    var _visible:Bool       = false;
    var _targetX:Float      = 0;
    var _currentX:Float     = 0;
    var _blinkTimer:Timer   = null;
    var _dotShowing:Bool    = true;

    // Hata mesajı için
    var _errorTimer:Timer   = null;
    var _errorAlpha:Float   = 0.0;
    var _errorTarget:Float  = 0.0;

    // Pozisyon sabitleri
    static inline var PAD_X:Float     = 14;
    static inline var PAD_Y:Float     = 14;
    static inline var BG_W:Float      = 88;
    static inline var BG_H:Float      = 30;
    static inline var HIDDEN_X:Float  = -(BG_W + PAD_X + 10);

    // =========================================================
    // Constructor
    // =========================================================

    public function new()
    {
        super();

        _buildBackground();
        _buildDot();
        _buildLabel();
        _buildErrorUI();

        // Başlangıç pozisyonu: ekran dışı (sol)
        _currentX = HIDDEN_X;
        _targetX  = HIDDEN_X;
        this.x    = _currentX;
        this.y    = PAD_Y;

        // Mouse events'i geçir
        this.mouseEnabled  = false;
        this.mouseChildren = false;

        // Her frame güncelle
        Lib.current.stage.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
    }

    // =========================================================
    // Public API
    // =========================================================

    public function showREC():Void
    {
        _visible = true;
        _targetX = PAD_X;
        _startBlink();
    }

    public function hideREC():Void
    {
        _visible = false;
        _targetX = HIDDEN_X;
        _stopBlink();

        // Bitmeden önce dot'u göster
        _dot.alpha = 1.0;
        _dotShowing = true;
    }

    public function showError(message:String):Void
    {
        _errorLabel.text = message;
        _errorTarget     = 1.0;

        // 4 saniye sonra kaybol
        if (_errorTimer != null) _errorTimer.stop();
        _errorTimer = Timer.delay(function()
        {
            _errorTarget = 0.0;
        }, 4000);
    }

    // =========================================================
    // Private - Build UI
    // =========================================================

    function _buildBackground():Void
    {
        _bg = new Shape();
        _redrawBG(1.0);
        addChild(_bg);
    }

    function _redrawBG(alpha:Float):Void
    {
        var g = _bg.graphics;
        g.clear();

        // Gölge efekti
        g.beginFill(0x000000, 0.25 * alpha);
        g.drawRoundRect(2, 2, BG_W, BG_H, 12, 12);
        g.endFill();

        // Ana arka plan
        g.beginFill(0x111111, 0.82 * alpha);
        g.lineStyle(1.5, 0xFF2222, 0.9 * alpha);
        g.drawRoundRect(0, 0, BG_W, BG_H, 12, 12);
        g.endFill();
    }

    function _buildDot():Void
    {
        _dot = new Shape();
        _redrawDot(true);
        _dot.x = 12;
        _dot.y = BG_H / 2 - 5;
        addChild(_dot);
    }

    function _redrawDot(visible:Bool):Void
    {
        var g = _dot.graphics;
        g.clear();

        if (visible)
        {
            // Parlak kırmızı nokta + glow
            g.beginFill(0xFF0000, 0.3);
            g.drawCircle(5, 5, 8);
            g.endFill();

            g.beginFill(0xFF3333, 1.0);
            g.drawCircle(5, 5, 5);
            g.endFill();

            g.beginFill(0xFF9999, 0.6);
            g.drawCircle(4, 4, 2);
            g.endFill();
        }
    }

    function _buildLabel():Void
    {
        _label = new TextField();
        _label.selectable   = false;
        _label.mouseEnabled = false;
        _label.text         = "REC";

        var fmt = new TextFormat("_sans", 13, 0xFFFFFF, true);
        fmt.letterSpacing = 1.5;
        _label.defaultTextFormat = fmt;
        _label.setTextFormat(fmt);
        _label.width  = 50;
        _label.height = 20;
        _label.x      = 28;
        _label.y      = BG_H / 2 - 9;

        addChild(_label);
    }

    function _buildErrorUI():Void
    {
        // ── DÜZELTME: Shape yerine Sprite kullanıyoruz ──
        _errorBg = new Sprite();

        var g = _errorBg.graphics;
        g.beginFill(0x880000, 0.9);
        g.lineStyle(1, 0xFF0000, 1.0);
        g.drawRoundRect(0, 0, 320, 42, 8, 8);
        g.endFill();

        _errorBg.alpha = 0.0;

        // Hata etiketi
        _errorLabel = new TextField();
        _errorLabel.selectable   = false;
        _errorLabel.mouseEnabled = false;
        _errorLabel.width        = 310;
        _errorLabel.height       = 36;
        _errorLabel.wordWrap     = true;
        _errorLabel.x            = 5;
        _errorLabel.y            = 3;

        var fmt = new TextFormat("_sans", 11, 0xFFFFFF, true);
        _errorLabel.defaultTextFormat = fmt;

        // ── DÜZELTME: addChild yerine addChild (Sprite olduğu için) ──
        _errorBg.addChild(_errorLabel);

        // Pozisyon: Sol üst, REC'in altı
        _errorBg.x = PAD_X;
        _errorBg.y = PAD_Y + BG_H + 6;

        addChild(_errorBg);
    }

    // =========================================================
    // Private - Animasyon
    // =========================================================

    function _onEnterFrame(e:Event):Void
    {
        // Smooth slide animasyonu
        _currentX += (_targetX - _currentX) * 0.18;

        // Çok yakınsa snap et
        if (Math.abs(_currentX - _targetX) < 0.5)
            _currentX = _targetX;

        this.x = _currentX;

        // Hata mesajı alpha
        if (Math.abs(_errorAlpha - _errorTarget) > 0.01)
        {
            _errorAlpha += (_errorTarget - _errorAlpha) * 0.12;
            _errorBg.alpha = _errorAlpha;
        }
        else
        {
            _errorAlpha    = _errorTarget;
            _errorBg.alpha = _errorAlpha;
        }
    }

    function _startBlink():Void
    {
        _stopBlink();

        _blinkTimer = new Timer(550);
        _blinkTimer.run = function()
        {
            _dotShowing = !_dotShowing;
            _redrawDot(_dotShowing);
        };
    }

    function _stopBlink():Void
    {
        if (_blinkTimer != null)
        {
            _blinkTimer.stop();
            _blinkTimer = null;
        }
    }

    // =========================================================
    // Cleanup
    // =========================================================

    public function destroy():Void
    {
        _stopBlink();

        if (_errorTimer != null)
        {
            _errorTimer.stop();
            _errorTimer = null;
        }

        Lib.current.stage.removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
    }
}