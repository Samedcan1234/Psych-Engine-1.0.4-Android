package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class WorkspaceSwitcher
{
	public static final THEME_NAMES:Array<String> = [
		"V3",
		"TÜRKIYE",
		"ORIGINAL",
		"V1"
	];

	public static final THEME_DISPLAY_NAMES:Array<String> = [
		"V3 - Modern",
		"Türkiye",
		"Orjinal - Klasik",
		"V1 - Eski"
	];

    public static final THEME_COLORS:Array<FlxColor> = [
        0xFF4A90E2,
        0xFFE30A17,
        0xFF9C27B0,
        0xFF4CAF50
    ];

    public static var isOpen:Bool = false;
    public static var isBusy:Bool = false;

    private static var _selectedIndex:Int = 0;
    private static var _startIndex:Int = 0;

    private static var _overlayCamera:FlxCamera;
    private static var _dimBG:FlxSprite;
    private static var _previewCards:Array<FlxSpriteGroup> = [];
    private static var _previewImages:Array<FlxSprite> = [];
    private static var _cardBorders:Array<FlxSprite> = [];
    private static var _cardGlows:Array<FlxSprite> = [];
    private static var _cardLabels:Array<FlxText> = [];
    private static var _instructionText:FlxText;
    private static var _titleText:FlxText;
    private static var _dotIndicators:Array<FlxSprite> = [];
    private static var _activeTweens:Array<FlxTween> = [];
    private static var _initialized:Bool = false;

    private static var CARD_WIDTH:Float;
    private static var CARD_HEIGHT:Float;
    private static var CARD_SCALE:Float = 0.75;
    private static var CARD_SPACING:Float;

    public static function init():Void
    {
        isOpen = false;
        isBusy = false;
        _initialized = true;
        _selectedIndex = ThemeManager.getThemeIndex();
        _startIndex = _selectedIndex;
        
        CARD_WIDTH = FlxG.width * CARD_SCALE;
        CARD_HEIGHT = FlxG.height * CARD_SCALE;
        CARD_SPACING = CARD_WIDTH + 50;
        
        cleanupArrays();
    }

	public static function handleInput(elapsed:Float):Void
	{
		if (!_initialized) return;
		if (isBusy) return;

		if (FlxG.keys.justPressed.SHIFT && !isOpen)
		{
			openWorkspace();
			return;
		}

		if (!isOpen) return;

		if (FlxG.keys.justPressed.LEFT)
		{
			navigateLeft();
			return;
		}
		
		if (FlxG.keys.justPressed.RIGHT)
		{
			navigateRight();
			return;
		}

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
		{
			confirmSelection();
			return;
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			closeWorkspace(false);
			return;
		}

		if (FlxG.keys.justReleased.SHIFT)
		{
			if (_selectedIndex != _startIndex)
				confirmSelection();
			else
				closeWorkspace(false);
		}
	}

    private static function openWorkspace():Void
    {
        if (isOpen || isBusy) return;

        isOpen = true;
        isBusy = true;
        _selectedIndex = ThemeManager.getThemeIndex();
        _startIndex = _selectedIndex;

        createOverlayUI();
        animateOpen();
    }

    private static function closeWorkspace(switchTheme:Bool):Void
    {
        if (!isOpen || isBusy) return;

        isBusy = true;
        animateClose(function()
        {
            if (switchTheme && _selectedIndex != _startIndex)
                applyTheme(_selectedIndex);

            destroyOverlayUI();
            isOpen = false;
            isBusy = false;
        });
    }

    private static function confirmSelection():Void
    {
        if (!isOpen || isBusy) return;

        isBusy = true;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        if (_selectedIndex >= 0 && _selectedIndex < _cardGlows.length && _cardGlows[_selectedIndex] != null)
        {
            FlxTween.tween(_cardGlows[_selectedIndex], {alpha: 0.9}, 0.1, {
                ease: FlxEase.quartOut,
                onComplete: function(_) {
                    FlxTween.tween(_cardGlows[_selectedIndex], {alpha: 0.4}, 0.1);
                }
            });
        }

        animateClose(function()
        {
            var needsSwitch:Bool = (_selectedIndex != _startIndex);
            destroyOverlayUI();
            isOpen = false;
            isBusy = false;

            if (needsSwitch)
                applyTheme(_selectedIndex);
        });
    }

    private static function navigateLeft():Void
    {
        if (isBusy) return;

        var newIndex:Int = _selectedIndex - 1;
        if (newIndex < 0) newIndex = THEME_NAMES.length - 1;

        if (newIndex != _selectedIndex)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            slideTo(newIndex);
        }
    }

    private static function navigateRight():Void
    {
        if (isBusy) return;

        var newIndex:Int = _selectedIndex + 1;
        if (newIndex >= THEME_NAMES.length) newIndex = 0;

        if (newIndex != _selectedIndex)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            slideTo(newIndex);
        }
    }

    private static function slideTo(newIndex:Int):Void
    {
        isBusy = true;
        _selectedIndex = newIndex;

        cancelAllTweens();

        for (i in 0...THEME_NAMES.length)
        {
            var card:FlxSpriteGroup = _previewCards[i];
            if (card == null) continue;

            var isSelected:Bool = (i == _selectedIndex);
            var targetX:Float = getCardTargetX(i, _selectedIndex);
            var targetScale:Float = isSelected ? 0.8 : 0.55;
            var targetAlpha:Float = isSelected ? 1.0 : 0.4;

            _activeTweens.push(FlxTween.tween(card, {x: targetX}, 0.2, {ease: FlxEase.quintOut}));
            _activeTweens.push(FlxTween.tween(card.scale, {x: targetScale, y: targetScale}, 0.2, {ease: FlxEase.quintOut}));
            _activeTweens.push(FlxTween.tween(card, {alpha: targetAlpha}, 0.2, {ease: FlxEase.quintOut}));

            if (i < _cardGlows.length && _cardGlows[i] != null)
                _activeTweens.push(FlxTween.tween(_cardGlows[i], {alpha: isSelected ? 0.4 : 0.0}, 0.2, {ease: FlxEase.quintOut}));

            if (i < _cardBorders.length && _cardBorders[i] != null)
                _activeTweens.push(FlxTween.tween(_cardBorders[i], {alpha: isSelected ? 1.0 : 0.3}, 0.2, {ease: FlxEase.quintOut}));
        }

        updateDotIndicators();

        if (_titleText != null)
        {
            _titleText.text = THEME_DISPLAY_NAMES[_selectedIndex];
            _titleText.color = THEME_COLORS[_selectedIndex];
        }

        _activeTweens.push(FlxTween.tween({value: 0}, {value: 1}, 0.22, {
            onComplete: function(_) { isBusy = false; }
        }));
    }

    private static function createOverlayUI():Void
    {
        _overlayCamera = new FlxCamera();
        _overlayCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(_overlayCamera, false);

        _dimBG = new FlxSprite(0, 0);
        _dimBG.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        _dimBG.alpha = 0;
        _dimBG.scrollFactor.set();
        _dimBG.cameras = [_overlayCamera];
        FlxG.state.add(_dimBG);

        _titleText = new FlxText(0, 30, FlxG.width, THEME_DISPLAY_NAMES[_selectedIndex], 42);
        _titleText.setFormat(Paths.font("vcr.ttf"), 42, THEME_COLORS[_selectedIndex], CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        _titleText.borderSize = 3;
        _titleText.alpha = 0;
        _titleText.scrollFactor.set();
        _titleText.cameras = [_overlayCamera];
        FlxG.state.add(_titleText);

        _previewCards = [];
        _previewImages = [];
        _cardBorders = [];
        _cardGlows = [];
        _cardLabels = [];

        var previewW:Int = Std.int(CARD_WIDTH);
        var previewH:Int = Std.int(CARD_HEIGHT);

        for (i in 0...THEME_NAMES.length)
        {
            var card:FlxSpriteGroup = new FlxSpriteGroup();

            var glow:FlxSprite = new FlxSprite(-15, -15);
            glow.makeGraphic(previewW + 30, previewH + 30, THEME_COLORS[i]);
            glow.alpha = 0;
            card.add(glow);
            _cardGlows.push(glow);

            var border:FlxSprite = new FlxSprite(-5, -5);
            border.makeGraphic(previewW + 10, previewH + 10, THEME_COLORS[i]);
            border.alpha = 0.3;
            card.add(border);
            _cardBorders.push(border);

            var previewImg:FlxSprite = new FlxSprite(0, 0);
            var previewPath:String = 'ultra/preview/${THEME_NAMES[i].toLowerCase()}';
            
            if (Paths.image(previewPath) != null)
            {
                previewImg.loadGraphic(Paths.image(previewPath));
                previewImg.setGraphicSize(previewW, previewH);
                previewImg.updateHitbox();
            }
            else
            {
                previewImg.makeGraphic(previewW, previewH, 0xFF1a1a2e);
                
                var placeholderText:FlxText = new FlxText(0, previewH / 2 - 20, previewW, THEME_DISPLAY_NAMES[i], 32);
                placeholderText.setFormat(Paths.font("vcr.ttf"), 32, THEME_COLORS[i], CENTER);
                card.add(placeholderText);
            }
            card.add(previewImg);
            _previewImages.push(previewImg);

            var nameLabel:FlxText = new FlxText(0, previewH + 10, previewW, THEME_DISPLAY_NAMES[i], 24);
            nameLabel.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            nameLabel.borderSize = 2;
            card.add(nameLabel);
            _cardLabels.push(nameLabel);

            card.x = getCardTargetX(i, _selectedIndex);
            card.y = (FlxG.height - previewH) / 2;
            card.scale.set(0.01, 0.01);
            card.alpha = 0;
            card.scrollFactor.set();
            card.cameras = [_overlayCamera];
            FlxG.state.add(card);
            _previewCards.push(card);
        }

        createDotIndicators();

        _instructionText = new FlxText(0, FlxG.height - 50, FlxG.width, "← → Tema Seç  |  SHIFT Bırak = Geçiş  |  ESC = İptal", 20);
        _instructionText.setFormat(Paths.font("vcr.ttf"), 20, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        _instructionText.borderSize = 1;
        _instructionText.alpha = 0;
        _instructionText.scrollFactor.set();
        _instructionText.cameras = [_overlayCamera];
        FlxG.state.add(_instructionText);
    }

    private static function createDotIndicators():Void
    {
        _dotIndicators = [];
        var dotSize:Int = 14;
        var dotSpacing:Int = 24;
        var totalWidth:Float = THEME_NAMES.length * dotSpacing;
        var startX:Float = (FlxG.width - totalWidth) / 2;

        for (i in 0...THEME_NAMES.length)
        {
            var dot:FlxSprite = new FlxSprite(startX + i * dotSpacing, FlxG.height - 85);
            dot.makeGraphic(dotSize, dotSize, (i == _selectedIndex) ? THEME_COLORS[_selectedIndex] : 0xFF555555);
            dot.alpha = 0;
            dot.scrollFactor.set();
            dot.cameras = [_overlayCamera];
            FlxG.state.add(dot);
            _dotIndicators.push(dot);
        }
    }

    private static function updateDotIndicators():Void
    {
        for (i in 0..._dotIndicators.length)
        {
            if (_dotIndicators[i] == null) continue;
            _dotIndicators[i].color = (i == _selectedIndex) ? THEME_COLORS[_selectedIndex] : 0xFF555555;
            var targetScale:Float = (i == _selectedIndex) ? 1.5 : 1.0;
            FlxTween.tween(_dotIndicators[i].scale, {x: targetScale, y: targetScale}, 0.15, {ease: FlxEase.quintOut});
        }
    }

    private static function getCardTargetX(index:Int, centerIndex:Int):Float
    {
        var offset:Int = index - centerIndex;
        var centerX:Float = (FlxG.width - CARD_WIDTH) / 2;
        return centerX + offset * CARD_SPACING;
    }

    private static function animateOpen():Void
    {
        cancelAllTweens();

        _activeTweens.push(FlxTween.tween(_dimBG, {alpha: 0.8}, 0.3, {ease: FlxEase.quartOut}));
        _activeTweens.push(FlxTween.tween(_titleText, {alpha: 1.0}, 0.35, {ease: FlxEase.quartOut}));

        for (i in 0...THEME_NAMES.length)
        {
            var card:FlxSpriteGroup = _previewCards[i];
            if (card == null) continue;

            var isSelected:Bool = (i == _selectedIndex);
            var targetScale:Float = isSelected ? 0.8 : 0.55;
            var targetAlpha:Float = isSelected ? 1.0 : 0.4;
            var delay:Float = i * 0.05;

            _activeTweens.push(FlxTween.tween(card.scale, {x: targetScale, y: targetScale}, 0.35, {ease: FlxEase.backOut, startDelay: delay}));
            _activeTweens.push(FlxTween.tween(card, {alpha: targetAlpha}, 0.3, {ease: FlxEase.quartOut, startDelay: delay}));

            if (isSelected && i < _cardGlows.length && _cardGlows[i] != null)
                _activeTweens.push(FlxTween.tween(_cardGlows[i], {alpha: 0.4}, 0.3, {ease: FlxEase.quartOut, startDelay: delay}));

            if (i < _cardBorders.length && _cardBorders[i] != null)
                _activeTweens.push(FlxTween.tween(_cardBorders[i], {alpha: isSelected ? 1.0 : 0.3}, 0.3, {ease: FlxEase.quartOut, startDelay: delay}));
        }

        for (dot in _dotIndicators)
            if (dot != null)
                _activeTweens.push(FlxTween.tween(dot, {alpha: 1.0}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.2}));

        _activeTweens.push(FlxTween.tween(_instructionText, {alpha: 0.9}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.25}));
        _activeTweens.push(FlxTween.tween({value: 0}, {value: 1}, 0.4, {onComplete: function(_) { isBusy = false; }}));
    }

    private static function animateClose(onComplete:Void->Void):Void
    {
        cancelAllTweens();

        _activeTweens.push(FlxTween.tween(_dimBG, {alpha: 0}, 0.25, {ease: FlxEase.quartIn}));
        _activeTweens.push(FlxTween.tween(_titleText, {alpha: 0}, 0.2, {ease: FlxEase.quartIn}));

        for (i in 0...THEME_NAMES.length)
        {
            var card:FlxSpriteGroup = _previewCards[i];
            if (card == null) continue;

            if (i == _selectedIndex)
            {
                _activeTweens.push(FlxTween.tween(card.scale, {x: 1.1, y: 1.1}, 0.25, {ease: FlxEase.quartIn}));
                _activeTweens.push(FlxTween.tween(card, {x: 0, y: 0, alpha: 0}, 0.25, {ease: FlxEase.quartIn}));
            }
            else
            {
                _activeTweens.push(FlxTween.tween(card, {alpha: 0}, 0.15, {ease: FlxEase.quartIn}));
                _activeTweens.push(FlxTween.tween(card.scale, {x: 0.01, y: 0.01}, 0.2, {ease: FlxEase.quartIn}));
            }
        }

        for (dot in _dotIndicators)
            if (dot != null)
                _activeTweens.push(FlxTween.tween(dot, {alpha: 0}, 0.15, {ease: FlxEase.quartIn}));

        _activeTweens.push(FlxTween.tween(_instructionText, {alpha: 0}, 0.15, {ease: FlxEase.quartIn}));
        _activeTweens.push(FlxTween.tween({value: 0}, {value: 1}, 0.3, {onComplete: function(_) { if (onComplete != null) onComplete(); }}));
    }

    private static function applyTheme(index:Int):Void
    {
        if (index < 0 || index >= THEME_NAMES.length) return;

        ClientPrefs.data.menuTheme = THEME_NAMES[index];
        ClientPrefs.saveSettings();
        ThemeManager.switchToMainMenu();
    }

    private static function cancelAllTweens():Void
    {
        for (tween in _activeTweens)
            if (tween != null && tween.active)
                tween.cancel();
        _activeTweens = [];
    }

    private static function cleanupArrays():Void
    {
        _previewCards = [];
        _previewImages = [];
        _cardBorders = [];
        _cardGlows = [];
        _cardLabels = [];
        _dotIndicators = [];
        _activeTweens = [];
    }

    private static function destroyOverlayUI():Void
    {
        cancelAllTweens();

        if (_dimBG != null) { FlxG.state.remove(_dimBG); _dimBG.destroy(); _dimBG = null; }
        if (_titleText != null) { FlxG.state.remove(_titleText); _titleText.destroy(); _titleText = null; }

        for (card in _previewCards)
            if (card != null) { FlxG.state.remove(card); card.destroy(); }

        for (dot in _dotIndicators)
            if (dot != null) { FlxG.state.remove(dot); dot.destroy(); }

        if (_instructionText != null) { FlxG.state.remove(_instructionText); _instructionText.destroy(); _instructionText = null; }
        if (_overlayCamera != null) { FlxG.cameras.remove(_overlayCamera); _overlayCamera = null; }

        cleanupArrays();
    }

    public static function forceClose():Void
    {
        cancelAllTweens();
        destroyOverlayUI();
        isOpen = false;
        isBusy = false;
    }
}