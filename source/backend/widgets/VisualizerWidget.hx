package backend.widgets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class VisualizerWidget extends WidgetBase
{
    private var _bars:Array<FlxSprite> = [];
    private var _barHeights:Array<Float> = [];
    private var _targetHeights:Array<Float> = [];
    
    private var _numBars:Int = 16;
    private var _maxBarHeight:Float = 55;
    private var _animTimer:Float = 0;
    
    private static inline var WIDGET_WIDTH:Int = 180;
    private static inline var WIDGET_HEIGHT:Int = 80;
    
    public function new(startX:Float, startY:Float)
    {
        super("visualizer", WIDGET_WIDTH, WIDGET_HEIGHT, startX, startY);
        
        trace("VisualizerWidget created");
        
        createBars();
    }
    
    private function createBars():Void
    {
        var barWidth:Int = 8;
        var spacing:Int = 3;
        var totalWidth:Float = _numBars * barWidth + (_numBars - 1) * spacing;
        var startX:Float = (WIDGET_WIDTH - totalWidth) / 2;
        var bottomY:Float = WIDGET_HEIGHT - 12;
        
        for (i in 0..._numBars)
        {
            var bar = new FlxSprite(startX + i * (barWidth + spacing), bottomY);
            bar.makeGraphic(barWidth, 2, getBarColor(i));
            add(bar);
            _bars.push(bar);
            _barHeights.push(2);
            _targetHeights.push(Math.random() * 20 + 5);
        }
    }
    
    private function getBarColor(index:Int):FlxColor
    {
        var ratio:Float = index / (_numBars - 1);
        var r:Int = Std.int(100 + ratio * 155);
        var g:Int = Std.int(130 - ratio * 30);
        var b:Int = 255;
        return FlxColor.fromRGB(r, g, b);
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        _animTimer += elapsed;
        
        if (_animTimer >= 0.08)
        {
            _animTimer = 0;
            for (i in 0..._numBars)
            {
                var intensity:Float = 0.3;
                if (FlxG.sound.music != null && FlxG.sound.music.playing)
                    intensity = 0.8;
                
                _targetHeights[i] = Math.random() * _maxBarHeight * intensity + 3;
            }
        }
        
        var bottomY:Float = WIDGET_HEIGHT - 12;
        for (i in 0..._bars.length)
        {
            _barHeights[i] += (_targetHeights[i] - _barHeights[i]) * elapsed * 12;
            
            var h:Int = Std.int(Math.max(2, _barHeights[i]));
            var bar = _bars[i];
            bar.makeGraphic(8, h, getBarColor(i));
            bar.y = bottomY - h;
        }
    }
}