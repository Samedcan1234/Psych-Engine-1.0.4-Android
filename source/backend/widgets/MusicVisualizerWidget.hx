package backend.widgets;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;

class MusicVisualizerWidget extends WidgetBase
{
    private var _bars:Array<FlxSprite> = [];
    private var _barCount:Int = 24;
    private var _barWidth:Int = 5;
    private var _barSpacing:Int = 2;
    private var _maxBarHeight:Int = 55;
    private var _barHeights:Array<Float> = [];
    private var _targetHeights:Array<Float> = [];
    private var _smoothing:Float = 12.0;
    private var _peakHistory:Array<Float> = [];
    private var _historySize:Int = 8;
    private var _beatDetected:Bool = false;
    private var _lastBeatTime:Float = 0;
    private var _beatCooldown:Float = 0.1;
    
    public function new(startX:Float = -1, startY:Float = -1)
    {
        var totalWidth:Int = (_barWidth + _barSpacing) * _barCount - _barSpacing + 24;
        var defaultX:Float = startX >= 0 ? startX : FlxG.width - 200;
        var defaultY:Float = startY >= 0 ? startY : 215;
        
        super("visualizer", totalWidth, _maxBarHeight + 24, defaultX, defaultY);
        
        for (i in 0..._historySize)
            _peakHistory.push(0);
        
        createBars();
    }
    
    private function createBars():Void
    {
        _bars = [];
        _barHeights = [];
        _targetHeights = [];
        
        for (i in 0..._barCount)
        {
            var bar:FlxSprite = new FlxSprite();
            bar.makeGraphic(_barWidth, _maxBarHeight, FlxColor.WHITE);
            bar.x = 12 + i * (_barWidth + _barSpacing);
            bar.y = 12;
            bar.origin.set(0, 0);
            bar.scale.set(1, 0.05);
            bar.scrollFactor.set(0, 0); // Önemli: Barlar da sabit kalmalı
            add(bar);
            _bars.push(bar);
            
            _barHeights.push(0.05);
            _targetHeights.push(0.05);
        }
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        updateVisualization(elapsed);
    }
    
	private function updateVisualization(elapsed:Float):Void
	{
		// Widget pozisyonuna göre base koordinatlar
		var baseX:Float = 12; // Local koordinat (0 değil çünkü padding var)
		var baseY:Float = 12;
		
		var leftPeak:Float = 0;
		var rightPeak:Float = 0;
		var musicPlaying:Bool = false;
		
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			musicPlaying = true;
			
			@:privateAccess
			if (FlxG.sound.music._channel != null)
			{
				leftPeak = FlxG.sound.music._channel.leftPeak;
				rightPeak = FlxG.sound.music._channel.rightPeak;
			}
		}
		
		if (backend.MusicPlayer.instance != null && backend.MusicPlayer.instance.isPlaying)
		{
			musicPlaying = true;
			
			var musicSound = backend.MusicPlayer.instance._musicSound;
			if (musicSound != null)
			{
				@:privateAccess
				var channel = musicSound._channel;
				if (channel != null)
				{
					leftPeak = Math.max(leftPeak, channel.leftPeak);
					rightPeak = Math.max(rightPeak, channel.rightPeak);
				}
			}
		}
		
		var avgPeak:Float = (leftPeak + rightPeak) / 2;
		
		_peakHistory.shift();
		_peakHistory.push(avgPeak);
		
		var avgHistory:Float = 0;
		for (p in _peakHistory)
			avgHistory += p;
		avgHistory /= _peakHistory.length;
		
		_lastBeatTime += elapsed;
		if (avgPeak > avgHistory * 1.3 && avgPeak > 0.2 && _lastBeatTime > _beatCooldown)
		{
			_beatDetected = true;
			_lastBeatTime = 0;
		}
		else
		{
			_beatDetected = false;
		}
		
		for (i in 0..._barCount)
		{
			if (musicPlaying && (leftPeak > 0.01 || rightPeak > 0.01))
			{
				var normalizedPos:Float = i / (_barCount - 1);
				
				var bassInfluence:Float = 1.0 - normalizedPos;
				var trebleInfluence:Float = normalizedPos;
				
				var barPeak:Float = leftPeak * bassInfluence * 0.5 + rightPeak * trebleInfluence * 0.5;
				
				var centerDist:Float = Math.abs(normalizedPos - 0.5) * 2;
				var centerBoost:Float = 1.0 - centerDist * 0.4;
				
				var variation:Float = Math.sin(FlxG.game.ticks * 0.02 + i * 0.5) * 0.1;
				var randomness:Float = (Math.random() - 0.5) * 0.08;
				
				var targetHeight:Float = barPeak * centerBoost * 0.6 + variation + randomness;
				
				if (_beatDetected)
					targetHeight += 0.1 * (1 - centerDist * 0.5);
				
				_targetHeights[i] = Math.min(0.7, Math.max(0.05, targetHeight));
			}
			else
			{
				_targetHeights[i] = 0.05 + Math.sin(FlxG.game.ticks * 0.003 + i * 0.2) * 0.03;
			}
			
			var speed:Float = _targetHeights[i] > _barHeights[i] ? _smoothing * 1.2 : _smoothing * 0.6;
			_barHeights[i] += (_targetHeights[i] - _barHeights[i]) * elapsed * speed;
			
			// Bar güncelle - POZİSYONLAR LOKAL (widget'ın x,y'sine göre otomatik)
			if (i < _bars.length && _bars[i] != null)
			{
				var bar:FlxSprite = _bars[i];
				bar.scale.y = Math.max(0.03, _barHeights[i]);
				
				// X ve Y widget'in local koordinatlarında
				bar.x = baseX + i * (_barWidth + _barSpacing);
				bar.y = baseY + _maxBarHeight * (1 - bar.scale.y);
				
				bar.alpha = 0.4 + _barHeights[i] * 0.6;
				
				if (_beatDetected && _barHeights[i] > 0.4)
				{
					bar.color = FlxColor.interpolate(FlxColor.WHITE, 0xFF88CCFF, _barHeights[i] * 0.5);
				}
				else
				{
					bar.color = FlxColor.WHITE;
				}
			}
		}
	}
}