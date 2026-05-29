package backend.widgets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.BitmapData;
import openfl.display.Shape;

class WidgetBase extends FlxSpriteGroup
{
    private static var _currentlyDraggingWidget:WidgetBase = null;
    
    public var widgetID:String = "";
    public var isDragging:Bool = false;
    public var isHovered:Bool = false;
    public var canDrag:Bool = true;
    
    private var _dragOffset:FlxPoint;
    private var _background:FlxSprite;
    private var _widgetWidth:Int;
    private var _widgetHeight:Int;
    private var _cornerRadius:Int = 20;
    
    public function new(id:String, widgetW:Int, widgetH:Int, startX:Float, startY:Float)
    {
        super();
        
        widgetID = id;
        _widgetWidth = widgetW;
        _widgetHeight = widgetH;
        _dragOffset = FlxPoint.get();
        
        createBackground();
        
        var savedPos = loadPosition();
        if (savedPos != null)
        {
            x = savedPos.x;
            y = savedPos.y;
            savedPos.put();
        }
        else
        {
            x = startX;
            y = startY;
        }
        
        scrollFactor.set(0, 0);
    }
    
    private function createBackground():Void
    {
        _background = new FlxSprite(0, 0);
        _background.makeGraphic(_widgetWidth, _widgetHeight, FlxColor.TRANSPARENT);
        
        drawRoundedRect(_background, _widgetWidth, _widgetHeight, _cornerRadius, 0xFFFFFFFF, 0.5);
        
        add(_background);
    }
    
	private function drawRoundedRect(sprite:FlxSprite, w:Int, h:Int, radius:Int, color:FlxColor, alpha:Float):Void
	{
		var shape:Shape = new Shape();
		
		shape.graphics.lineStyle(2, 0xFFFFFF, 0.5); 
		shape.graphics.beginFill(color, alpha);
		shape.graphics.drawRoundRect(1, 1, w - 2, h - 2, radius, radius);
		shape.graphics.endFill();
		
		var bitmapData:BitmapData = new BitmapData(w, h, true, 0x00000000);
		bitmapData.draw(shape);
		sprite.loadGraphic(bitmapData);
	}
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if (!canDrag) return;
        
        handleDragging();
        handleHover();
    }
    
    private function handleDragging():Void
    {
        var mouseX:Float = FlxG.mouse.screenX;
        var mouseY:Float = FlxG.mouse.screenY;
        
        var isOverWidget:Bool = mouseX >= x && mouseX <= x + _widgetWidth &&
                                mouseY >= y && mouseY <= y + _widgetHeight;
        
        if (FlxG.mouse.justPressed && isOverWidget)
        {
            if (_currentlyDraggingWidget == null)
            {
                isDragging = true;
                _currentlyDraggingWidget = this;
                _dragOffset.set(mouseX - x, mouseY - y);
            }
        }
        
        if (isDragging && _currentlyDraggingWidget == this)
        {
            if (FlxG.mouse.pressed)
            {
                x = mouseX - _dragOffset.x;
                y = mouseY - _dragOffset.y;
                
                x = Math.max(0, Math.min(FlxG.width - _widgetWidth, x));
                y = Math.max(0, Math.min(FlxG.height - _widgetHeight, y));
            }
            else
            {
                isDragging = false;
                _currentlyDraggingWidget = null;
                savePosition();
            }
        }
        
        if (!FlxG.mouse.pressed && isDragging)
        {
            isDragging = false;
            if (_currentlyDraggingWidget == this)
                _currentlyDraggingWidget = null;
            savePosition();
        }
    }
    
    private function handleHover():Void
    {
        if (_currentlyDraggingWidget != null && _currentlyDraggingWidget != this)
            return;
        
        var mouseX:Float = FlxG.mouse.screenX;
        var mouseY:Float = FlxG.mouse.screenY;
        
        var wasHovered:Bool = isHovered;
        isHovered = mouseX >= x && mouseX <= x + _widgetWidth &&
                    mouseY >= y && mouseY <= y + _widgetHeight;
        
        if (isHovered && !wasHovered)
        {
            onHoverEnter();
        }
        else if (!isHovered && wasHovered)
        {
            onHoverExit();
        }
    }
    
    public function onHoverEnter():Void
    {
        drawRoundedRect(_background, _widgetWidth, _widgetHeight, _cornerRadius, 0xFFFFFFFF, 0.4);
    }
    
    public function onHoverExit():Void
    {
        drawRoundedRect(_background, _widgetWidth, _widgetHeight, _cornerRadius, 0xFFFFFFFF, 0.5);
    }
    
    public function savePosition():Void
    {
        var keyX:String = "widget_" + widgetID + "_x";
        var keyY:String = "widget_" + widgetID + "_y";
        Reflect.setField(FlxG.save.data, keyX, x);
        Reflect.setField(FlxG.save.data, keyY, y);
        FlxG.save.flush();
    }
    
    public function loadPosition():FlxPoint
    {
        var keyX:String = "widget_" + widgetID + "_x";
        var keyY:String = "widget_" + widgetID + "_y";
        var savedX = Reflect.field(FlxG.save.data, keyX);
        var savedY = Reflect.field(FlxG.save.data, keyY);
        
        if (savedX != null && savedY != null)
        {
            return FlxPoint.get(savedX, savedY);
        }
        return null;
    }
    
    public function resetPosition(defaultX:Float, defaultY:Float):Void
    {
        x = defaultX;
        y = defaultY;
        savePosition();
    }
    
    public static function resetDragState():Void
    {
        _currentlyDraggingWidget = null;
    }
    
    override function destroy():Void
    {
        if (_currentlyDraggingWidget == this)
            _currentlyDraggingWidget = null;
        
        if (_dragOffset != null)
        {
            _dragOffset.put();
            _dragOffset = null;
        }
        super.destroy();
    }
}