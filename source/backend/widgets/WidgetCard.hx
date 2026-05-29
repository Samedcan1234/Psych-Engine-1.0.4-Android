package backend.widgets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.BitmapData;
import openfl.display.Shape;

class WidgetCard extends FlxSpriteGroup
{
    public var widgetId:String;
    public var isInstalled:Bool = false;
    
    private var _cardBG:FlxSprite;
    private var _iconBG:FlxSprite;
    private var _iconText:FlxText;
    private var _nameText:FlxText;
    private var _descText:FlxText;
    private var _actionBtn:FlxSprite;
    private var _actionIcon:FlxText;
    private var _statusBar:FlxSprite;
    private var _statusText:FlxText;
    
    private var _width:Int;
    private var _height:Int;
    private var _isHovered:Bool = false;
    private var _isBtnHovered:Bool = false;
    private var _onToggle:String->Bool->Void;
    
    // Buton pozisyonları
    private var _btnLocalX:Float;
    private var _btnLocalY:Float;
    private var _btnSize:Int = 50;
    
    public function new(xPos:Float, yPos:Float, w:Int, h:Int, id:String, name:String, desc:String, icon:String, installed:Bool, onToggle:String->Bool->Void)
    {
        super(xPos, yPos);
        
        widgetId = id;
        isInstalled = installed;
        _width = w;
        _height = h;
        _onToggle = onToggle;
        
        scrollFactor.set();
        
        createCard(name, desc, icon);
        updateStatus();
    }
    
    private function createCard(name:String, desc:String, icon:String):Void
    {
        // Card background
        _cardBG = new FlxSprite(0, 0);
        drawGlassCard(_cardBG, _width, _height, 12, 0xFF1a1a2e, 0.85);
        add(_cardBG);
        
        // Icon background (circle)
        _iconBG = new FlxSprite((_width - 80) / 2, 25);
        drawGlassCard(_iconBG, 80, 80, 40, 0xFF2a2a3e, 0.9);
        add(_iconBG);
        
        // Icon text
        _iconText = new FlxText((_width - 80) / 2, 50, 80, icon, 24);
        _iconText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        add(_iconText);
        
        // Widget name
        _nameText = new FlxText(10, 120, _width - 20, name.toUpperCase(), 16);
        _nameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        add(_nameText);
        
        // Description
        _descText = new FlxText(15, 145, _width - 30, desc, 11);
        _descText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF888899, CENTER);
        add(_descText);
        
        // Action button pozisyonları kaydet
        _btnLocalX = (_width - _btnSize) / 2;
        _btnLocalY = 190;
        
        // Action button (hidden by default)
        _actionBtn = new FlxSprite(_btnLocalX, _btnLocalY);
        drawGlassCard(_actionBtn, _btnSize, _btnSize, 25, 0xFF3a3a4e, 0.9);
        _actionBtn.alpha = 0;
        add(_actionBtn);
        
        _actionIcon = new FlxText(_btnLocalX, _btnLocalY + 12, _btnSize, "+", 28);
        _actionIcon.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
        _actionIcon.alpha = 0;
        add(_actionIcon);
        
        // Status bar at bottom
        _statusBar = new FlxSprite(0, _height - 45);
        updateStatusBarGraphic();
        add(_statusBar);
        
        _statusText = new FlxText(0, _height - 32, _width, "NOT INSTALLED", 13);
        _statusText.setFormat(Paths.font("vcr.ttf"), 13, FlxColor.WHITE, CENTER);
        add(_statusText);
    }
    
    private function updateStatusBarGraphic():Void
    {
        var color:FlxColor = isInstalled ? 0xFF2a8a4e : 0xFF4a4a5e;
        
        var shape:Shape = new Shape();
        shape.graphics.beginFill(color, 1.0);
        shape.graphics.moveTo(0, 0);
        shape.graphics.lineTo(_width, 0);
        shape.graphics.lineTo(_width, 45 - 12);
        shape.graphics.curveTo(_width, 45, _width - 12, 45);
        shape.graphics.lineTo(12, 45);
        shape.graphics.curveTo(0, 45, 0, 45 - 12);
        shape.graphics.lineTo(0, 0);
        shape.graphics.endFill();
        
        var bitmapData:BitmapData = new BitmapData(_width, 45, true, 0x00000000);
        bitmapData.draw(shape);
        
        _statusBar.loadGraphic(bitmapData);
    }
    
    public function setInstalled(installed:Bool):Void
    {
        isInstalled = installed;
        updateStatus();
    }
    
    private function updateStatus():Void
    {
        updateStatusBarGraphic();
        
        if (isInstalled)
        {
            _statusText.text = "INSTALLED";
            _actionIcon.text = "-";
        }
        else
        {
            _statusText.text = "NOT INSTALLED";
            _actionIcon.text = "+";
        }
    }
    
    private function drawGlassCard(sprite:FlxSprite, w:Int, h:Int, radius:Int, color:FlxColor, alphaVal:Float):Void
    {
        var shape:Shape = new Shape();
        
        shape.graphics.beginFill(color & 0x00FFFFFF, alphaVal);
        shape.graphics.drawRoundRect(0, 0, w, h, radius, radius);
        shape.graphics.endFill();
        
        shape.graphics.lineStyle(1, 0xFFFFFF, 0.15);
        shape.graphics.drawRoundRect(0.5, 0.5, w - 1, h - 1, radius, radius);
        
        var bitmapData:BitmapData = new BitmapData(w, h, true, 0x00000000);
        bitmapData.draw(shape);
        
        sprite.loadGraphic(bitmapData);
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if (!WidgetShop.isOpen) return;
        
        handleHover();
        handleClick();
    }
    
    private function handleHover():Void
    {
        var mx:Float = FlxG.mouse.screenX;
        var my:Float = FlxG.mouse.screenY;
        
        var overCard:Bool = mx >= x && mx <= x + _width &&
                            my >= y && my <= y + _height;
        
        // Hover başladı
        if (overCard && !_isHovered)
        {
            _isHovered = true;
            FlxTween.cancelTweensOf(_actionBtn);
            FlxTween.cancelTweensOf(_actionIcon);
            
            FlxTween.tween(_actionBtn, {alpha: 1}, 0.2, {ease: FlxEase.quartOut});
            FlxTween.tween(_actionIcon, {alpha: 1}, 0.2, {ease: FlxEase.quartOut});
            _cardBG.color = 0xFF4a4a6e;
        }
        // Hover bitti
        else if (!overCard && _isHovered)
        {
            _isHovered = false;
            _isBtnHovered = false;
            FlxTween.cancelTweensOf(_actionBtn);
            FlxTween.cancelTweensOf(_actionIcon);
            
            FlxTween.tween(_actionBtn, {alpha: 0}, 0.2, {ease: FlxEase.quartIn});
            FlxTween.tween(_actionIcon, {alpha: 0}, 0.2, {ease: FlxEase.quartIn});
            _cardBG.color = FlxColor.WHITE;
            _actionBtn.color = FlxColor.WHITE;
        }
        
        // Buton hover kontrolü
        if (_isHovered)
        {
            var btnX:Float = x + _btnLocalX;
            var btnY:Float = y + _btnLocalY;
            var overBtn:Bool = mx >= btnX && mx <= btnX + _btnSize &&
                               my >= btnY && my <= btnY + _btnSize;
            
            if (overBtn && !_isBtnHovered)
            {
                _isBtnHovered = true;
                if (isInstalled)
                    _actionBtn.color = 0xFFCC4455;
                else
                    _actionBtn.color = 0xFF4a9a6e;
            }
            else if (!overBtn && _isBtnHovered)
            {
                _isBtnHovered = false;
                _actionBtn.color = FlxColor.WHITE;
            }
        }
    }
    
    private function handleClick():Void
    {
        if (!_isHovered) return;
        if (!FlxG.mouse.justPressed) return;
        
        var mx:Float = FlxG.mouse.screenX;
        var my:Float = FlxG.mouse.screenY;
        
        var btnX:Float = x + _btnLocalX;
        var btnY:Float = y + _btnLocalY;
        var overBtn:Bool = mx >= btnX && mx <= btnX + _btnSize &&
                           my >= btnY && my <= btnY + _btnSize;
        
        if (overBtn)
        {
            trace("=== BUTTON CLICKED ===");
            trace("Widget ID: " + widgetId);
            trace("Current state: " + (isInstalled ? "INSTALLED" : "NOT INSTALLED"));
            trace("New state will be: " + (!isInstalled ? "INSTALLED" : "NOT INSTALLED"));
            
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
            
            var newState:Bool = !isInstalled;
            
            if (_onToggle != null)
            {
                trace("Calling onToggle callback...");
                _onToggle(widgetId, newState);
            }
            else
            {
                trace("ERROR: _onToggle is null!");
            }
        }
    }
}