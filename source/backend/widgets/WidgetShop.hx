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

class WidgetShop extends FlxSpriteGroup
{
    public static var instance:WidgetShop;
    public static var isOpen:Bool = false;
    
    private var _dimBG:FlxSprite;
    private var _mainPanel:FlxSprite;
    private var _searchBar:FlxSprite;
    private var _searchIcon:FlxText;
    private var _searchPlaceholder:FlxText;
    private var _titleText:FlxText;
    private var _subtitleText:FlxText;
    private var _closeBtn:FlxSprite;
    private var _closeIcon:FlxText;
    
    private var _widgetCards:Array<WidgetCard> = [];
    
    private var _panelWidth:Int = 700;
    private var _panelHeight:Int = 450;
    private var _searchBarHeight:Int = 50;
    private var _cornerRadius:Int = 16;
    
    private var _centerX:Float = 0;
    private var _centerY:Float = 0;
    
    public function new()
    {
        super();
        instance = this;
        
        scrollFactor.set();
        
        createUI();
        
        visible = false;
        alpha = 0;
    }
    
    private function createUI():Void
    {
        _centerX = (FlxG.width - _panelWidth) / 2;
        _centerY = (FlxG.height - _panelHeight - _searchBarHeight - 15) / 2;
        
        // Dim background
        _dimBG = new FlxSprite(0, 0);
        _dimBG.makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        _dimBG.alpha = 0.6;
        add(_dimBG);
        
        // Search bar
        _searchBar = new FlxSprite(_centerX, _centerY);
        drawGlassPanel(_searchBar, _panelWidth, _searchBarHeight, 12, 0xFF1a1a2e, 0.85);
        add(_searchBar);
        
        _searchIcon = new FlxText(_centerX + 20, _centerY + 14, 30, "O", 20);
        _searchIcon.setFormat(Paths.font("vcr.ttf"), 20, 0xFF666688, LEFT);
        add(_searchIcon);
        
        _searchPlaceholder = new FlxText(_centerX + 55, _centerY + 14, _panelWidth - 100, "Search widgets...", 18);
        _searchPlaceholder.setFormat(Paths.font("vcr.ttf"), 18, 0xFF555566, LEFT);
        add(_searchPlaceholder);
        
        // Main panel
        _mainPanel = new FlxSprite(_centerX, _centerY + _searchBarHeight + 15);
        drawGlassPanel(_mainPanel, _panelWidth, _panelHeight, _cornerRadius, 0xFF0d0d1a, 0.9);
        add(_mainPanel);
        
        // Title
        _titleText = new FlxText(_centerX + 30, _centerY + _searchBarHeight + 30, _panelWidth - 60, "WIDGET SHOP", 28);
        _titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT);
        _titleText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
        add(_titleText);
        
        // Subtitle
        _subtitleText = new FlxText(_centerX + 30, _centerY + _searchBarHeight + 65, _panelWidth - 60, "Add widgets to your menu", 14);
        _subtitleText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888899, LEFT);
        add(_subtitleText);
        
        // Close button
        _closeBtn = new FlxSprite(_centerX + _panelWidth - 50, _centerY + _searchBarHeight + 25);
        drawGlassPanel(_closeBtn, 35, 35, 8, 0xFF2a2a3e, 0.9);
        add(_closeBtn);
        
        _closeIcon = new FlxText(_centerX + _panelWidth - 50, _centerY + _searchBarHeight + 32, 35, "X", 18);
        _closeIcon.setFormat(Paths.font("vcr.ttf"), 18, 0xFFAAAAAA, CENTER);
        add(_closeIcon);
        
        createWidgetCards();
    }
    
    private function createWidgetCards():Void
    {
        var cardWidth:Int = 200;
        var cardHeight:Int = 280;
        var cardSpacing:Int = 30;
        
        var totalWidth:Float = cardWidth * 2 + cardSpacing;
        var offsetX:Float = (_panelWidth - totalWidth) / 2;
        var startY:Float = _centerY + _searchBarHeight + 100;
        
        var widgets:Array<{id:String, name:String, desc:String, icon:String}> = [
            {id: "clock", name: "Clock", desc: "Display current time\nand date", icon: "12:00"},
            {id: "visualizer", name: "Visualizer", desc: "Audio reactive\nbars animation", icon: "|||"}
        ];
        
        for (i in 0...widgets.length)
        {
            var widget = widgets[i];
            var col:Int = i % 3;
            var row:Int = Math.floor(i / 3);
            
            var cardX:Float = _centerX + offsetX + col * (cardWidth + cardSpacing);
            var cardY:Float = startY + row * (cardHeight + cardSpacing);
            
            var isInstalled:Bool = false;
            if (WidgetManager.instance != null)
            {
                isInstalled = WidgetManager.instance.isWidgetInstalled(widget.id);
                trace("Widget " + widget.id + " installed state: " + isInstalled);
            }
            else
            {
                trace("WARNING: WidgetManager.instance is null!");
            }
            
            var card = new WidgetCard(
                cardX, cardY, cardWidth, cardHeight,
                widget.id, widget.name, widget.desc, widget.icon,
                isInstalled, onCardToggle
            );
            add(card);
            _widgetCards.push(card);
        }
    }
    
    private function onCardToggle(widgetId:String, shouldInstall:Bool):Void
    {
        trace("=== WidgetShop.onCardToggle ===");
        trace("Widget: " + widgetId + ", Install: " + shouldInstall);
        
        if (WidgetManager.instance != null)
        {
            trace("Calling WidgetManager.toggleWidget...");
            WidgetManager.instance.toggleWidget(widgetId, shouldInstall);
            trace("WidgetManager.toggleWidget completed");
        }
        else
        {
            trace("ERROR: WidgetManager.instance is null!");
        }
        
        // Kartı güncelle
        for (card in _widgetCards)
        {
            if (card.widgetId == widgetId)
            {
                card.setInstalled(shouldInstall);
                trace("Card state updated");
                break;
            }
        }
    }
    
    private function refreshCardStates():Void
    {
        trace("Refreshing card states...");
        for (card in _widgetCards)
        {
            var isInstalled:Bool = false;
            if (WidgetManager.instance != null)
                isInstalled = WidgetManager.instance.isWidgetInstalled(card.widgetId);
            card.setInstalled(isInstalled);
            trace("Card " + card.widgetId + " = " + isInstalled);
        }
    }
    
    private function drawGlassPanel(sprite:FlxSprite, w:Int, h:Int, radius:Int, color:FlxColor, alphaVal:Float):Void
    {
        var shape:Shape = new Shape();
        
        shape.graphics.beginFill(color & 0x00FFFFFF, alphaVal);
        shape.graphics.drawRoundRect(0, 0, w, h, radius, radius);
        shape.graphics.endFill();
        
        shape.graphics.lineStyle(1, 0xFFFFFF, 0.2);
        shape.graphics.drawRoundRect(0.5, 0.5, w - 1, h - 1, radius, radius);
        
        var bitmapData:BitmapData = new BitmapData(w, h, true, 0x00000000);
        bitmapData.draw(shape);
        
        sprite.loadGraphic(bitmapData);
    }
    
    public function open():Void
    {
        if (isOpen) return;
        
        trace("=== WidgetShop.open() ===");
        
        isOpen = true;
        visible = true;
        
        refreshCardStates();
        
        alpha = 0;
        FlxTween.tween(this, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});
        
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }
    
    public function close():Void
    {
        if (!isOpen) return;
        
        trace("=== WidgetShop.close() ===");
        
        isOpen = false;
        
        FlxTween.tween(this, {alpha: 0}, 0.25, {
            ease: FlxEase.quartIn,
            onComplete: function(_) {
                visible = false;
            }
        });
        
        FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
    }
    
    public function toggle():Void
    {
        if (isOpen)
            close();
        else
            open();
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if (!isOpen) return;
        
        handleCloseButton();
    }
    
    private function handleCloseButton():Void
    {
        var mx:Float = FlxG.mouse.screenX;
        var my:Float = FlxG.mouse.screenY;
        
        var overClose:Bool = mx >= _closeBtn.x && mx <= _closeBtn.x + _closeBtn.width &&
                             my >= _closeBtn.y && my <= _closeBtn.y + _closeBtn.height;
        
        if (overClose)
        {
            _closeBtn.color = 0xFFCC4455;
            _closeIcon.color = FlxColor.WHITE;
            
            if (FlxG.mouse.justPressed)
            {
                close();
            }
        }
        else
        {
            _closeBtn.color = FlxColor.WHITE;
            _closeIcon.color = 0xFFAAAAAA;
        }
    }
    
    override function destroy():Void
    {
        instance = null;
        _widgetCards = [];
        super.destroy();
    }
}