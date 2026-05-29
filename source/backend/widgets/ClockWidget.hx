package backend.widgets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ClockWidget extends WidgetBase
{
    private var _timeText:FlxText;
    private var _dateText:FlxText;
    private var _updateTimer:Float = 0;
    
    private static inline var WIDGET_WIDTH:Int = 180;
    private static inline var WIDGET_HEIGHT:Int = 80;
    
    public function new(startX:Float, startY:Float)
    {
        super("clock", WIDGET_WIDTH, WIDGET_HEIGHT, startX, startY);
        
        trace("ClockWidget created");
        
        createContent();
        updateTime();
    }
    
    private function createContent():Void
    {
        _timeText = new FlxText(10, 12, WIDGET_WIDTH - 20, "00:00", 32);
        _timeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        _timeText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1);
        add(_timeText);
        
        _dateText = new FlxText(10, 50, WIDGET_WIDTH - 20, "01/01/2024", 12);
        _dateText.setFormat(Paths.font("vcr.ttf"), 12, 0xFFCCCCCC, CENTER);
        add(_dateText);
    }
    
    private function updateTime():Void
    {
        var now = Date.now();
        var hours = StringTools.lpad(Std.string(now.getHours()), "0", 2);
        var mins = StringTools.lpad(Std.string(now.getMinutes()), "0", 2);
        _timeText.text = hours + ":" + mins;
        
        var day = StringTools.lpad(Std.string(now.getDate()), "0", 2);
        var month = StringTools.lpad(Std.string(now.getMonth() + 1), "0", 2);
        var year = Std.string(now.getFullYear());
        _dateText.text = day + "/" + month + "/" + year;
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        _updateTimer += elapsed;
        if (_updateTimer >= 1.0)
        {
            _updateTimer = 0;
            updateTime();
        }
    }
}