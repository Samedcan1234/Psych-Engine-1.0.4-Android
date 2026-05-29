package options;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import objects.CheckboxThingie;
import objects.AttachedText;
import options.Option;
import options.OptionCategory;
import backend.InputFormatter;

class CategoryOptionsMenu extends MusicBeatSubstate
{

	var categories:Array<OptionCategory> = [];

	var flatList:Array<Dynamic> = [];

	var curSelected:Int = 0;
	var curOption:Option  = null;   

	public var title:String    = 'Ayarlar';
	public var rpcTitle:String = 'Ayarlar Menüsü';

	var bg:FlxSprite;
	var bgDarken:FlxSprite;
	var bgGradient:FlxSprite;
	var topBar:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var bottomBar:FlxSprite;
	var descBox:FlxSprite;
	var descText:FlxText;
	var scrollIndicator:FlxSprite;
	var glowEffect:FlxSprite;
	var particleEmitter:FlxEmitter;

	var rowGroup:FlxTypedGroup<FlxSprite>;       

	var labelGroup:FlxTypedGroup<FlxText>;        

	var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	var valueGroup:FlxTypedGroup<AttachedText>;

	var animTimer:Float  = 0;
	var pulseTimer:Float = 0;

	static inline var ROW_H:Float        = 72;    

	static inline var ROW_W:Float        = 820;
	static inline var LIST_TOP:Float     = 155;   

	static inline var INDENT:Float       = 36;    

	static inline var VISIBLE_ROWS:Int   = 6;     

	static inline var CAT_COLOR:Int      = 0xFF222233;
	static inline var OPT_COLOR:Int      = 0xFF111122;
	static inline var SEL_COLOR:Int      = 0xFF2a2a4a;
	static inline var LOCKED_GRAY:Int    = 0xFF888888;

	var nextAccept:Int  = 5;
	var holdTime:Float  = 0;
	var holdValue:Float = 0;

	var rebuildPending:Bool = false;

	public function new()
	{
		super();
	}

	public function addCategory(cat:OptionCategory):OptionCategory
	{
		categories.push(cat);
		return cat;
	}

	public function buildMenu()
	{
		if(title == null)   title   = 'Ayarlar';
		if(rpcTitle == null) rpcTitle = 'Ayarlar Menüsü';

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		_buildBackground();
		_buildTopBar();
		_buildBottomBar();
		_buildRowContainers();
		_buildParticles();

		rebuildFlatList();
		rebuildRows(true);
		changeSelection(0);
	}

	function _buildBackground()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.3));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha         = 0.35;
		bg.scrollFactor.set(0.04, 0.04);
		add(bg);

		bgGradient = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0d0d1a);
		bgGradient.scrollFactor.set();
		bgGradient.alpha = 0;
		add(bgGradient);
		FlxTween.tween(bgGradient, {alpha: 0.92}, 0.5, {ease: FlxEase.quartOut});

		bgDarken = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bgDarken.scrollFactor.set();
		bgDarken.alpha = 0;
		add(bgDarken);
		FlxTween.tween(bgDarken, {alpha: 0.45}, 0.6, {ease: FlxEase.quartOut});

		glowEffect = new FlxSprite(FlxG.width / 2 - 400, FlxG.height / 2 - 400);
		glowEffect.makeGraphic(800, 800, FlxColor.WHITE);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		glowEffect.scrollFactor.set();
		add(glowEffect);
		FlxTween.tween(glowEffect, {alpha: 0.05}, 0.8, {ease: FlxEase.quartOut});
	}

	function _buildTopBar()
	{
		topBar = new FlxSprite(0, -140).makeGraphic(FlxG.width, 135, 0xDD000000);
		topBar.scrollFactor.set();
		add(topBar);
		FlxTween.tween(topBar, {y: 0}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.1});

		titleText = new FlxText(60, 28, FlxG.width - 120, title, 50);
		titleText.setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, 0xFF8D58FD);
		titleText.borderSize  = 3;
		titleText.scrollFactor.set();
		titleText.alpha = 0;
		add(titleText);
		FlxTween.tween(titleText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3});

		subtitleText = new FlxText(60, 88, FlxG.width - 120,
			'YUKARI/AŞAĞI = Gezin  |  ENTER = Aç/Kapat & Seç  |  SOL/SAĞ = Değiştir  |  R = Sıfırla  |  ESC = Geri', 18);
		subtitleText.setFormat(Paths.font('vcr.ttf'), 18, 0xFFCCCCCC, LEFT);
		subtitleText.scrollFactor.set();
		subtitleText.alpha = 0;
		add(subtitleText);
		FlxTween.tween(subtitleText, {alpha: 0.65}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.5});
	}

	function _buildBottomBar()
	{
		bottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 150, 0xDD000000);
		bottomBar.scrollFactor.set();
		add(bottomBar);
		FlxTween.tween(bottomBar, {y: FlxG.height - 150}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.3});

		descBox = new FlxSprite(30, FlxG.height - 130).makeGraphic(FlxG.width - 60, 110, 0x88000000);
		descBox.scrollFactor.set();
		descBox.alpha = 0;
		add(descBox);
		FlxTween.tween(descBox, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.8});

		descText = new FlxText(50, FlxG.height - 120, FlxG.width - 100, '', 24);
		descText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2;
		descText.alpha = 0;
		add(descText);
		FlxTween.tween(descText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 1.0});

		scrollIndicator = new FlxSprite(FlxG.width - 18, FlxG.height / 2 - 40)
			.makeGraphic(8, 80, FlxColor.WHITE);
		scrollIndicator.alpha         = 0.25;
		scrollIndicator.scrollFactor.set();
		add(scrollIndicator);
	}

	function _buildRowContainers()
	{
		rowGroup      = new FlxTypedGroup<FlxSprite>();           add(rowGroup);
		labelGroup    = new FlxTypedGroup<FlxText>();             add(labelGroup);
		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();     add(checkboxGroup);
		valueGroup    = new FlxTypedGroup<AttachedText>();        add(valueGroup);
	}

	function _buildParticles()
	{
		particleEmitter = new FlxEmitter(FlxG.width / 2, 80, 30);
		particleEmitter.width = FlxG.width;
		for (i in 0...30)
		{
			var p = new FlxParticle();
			p.makeGraphic(2, 2, FlxColor.WHITE);
			p.exists = false;
			particleEmitter.add(p);
		}
		particleEmitter.launchMode = FlxEmitterMode.SQUARE;
		particleEmitter.velocity.set(-20, 60, 20, 160);
		particleEmitter.lifespan.set(3, 6);
		particleEmitter.alpha.set(0.15, 0.35, 0, 0);
		particleEmitter.start(false, 0.12);
		add(particleEmitter);
	}

	function rebuildFlatList()
	{
		flatList = [];
		for (cat in categories)
		{
			flatList.push(cat);          

			if (cat.isOpen)
				for (opt in cat.options)
					flatList.push(opt);  

		}
	}

	function rebuildRows(instant:Bool = false)
	{

		rowGroup.clear();
		labelGroup.clear();
		checkboxGroup.clear();
		valueGroup.clear();

		var centerX:Float = (FlxG.width - ROW_W) / 2;

		for (i in 0...flatList.length)
		{
			var item     = flatList[i];
			var isCategory = Std.isOfType(item, OptionCategory);
			var targetY  = _rowTargetY(i);
			var startY   = instant ? targetY : targetY - 30;
			var startAlpha:Float = instant ? 1 : 0;

			var cardColor:Int = isCategory ? CAT_COLOR : OPT_COLOR;
			if (i == curSelected) cardColor = SEL_COLOR;

			var card = new FlxSprite(centerX, startY).makeGraphic(Std.int(ROW_W), Std.int(ROW_H - 4), cardColor);
			card.alpha        = startAlpha;
			card.scrollFactor.set();
			card.ID           = i;
			rowGroup.add(card);

			if (!instant)
				FlxTween.tween(card, {alpha: 0.85, y: targetY}, 0.35,
					{ease: FlxEase.quartOut, startDelay: i * 0.03});

			var labelX:Float;
			var labelStr:String;
			var labelSize:Int;
			var labelColor:Int;

			if (isCategory)
			{
				var cat:OptionCategory = cast item;
				labelX     = centerX + 16;
				labelStr   = (cat.isOpen ? '▼  ' : '▶  ') + cat.name;
				labelSize  = 26;
				labelColor = 0xFFFFFFFF;
			}
			else
			{
				var opt:Option = cast item;
				var locked     = _isLocked(opt);
				labelX         = centerX + INDENT + 16;
				labelStr       = opt.name;
				labelSize      = 22;
				labelColor     = locked ? LOCKED_GRAY : 0xFFDDDDDD;
			}

			var lbl = new FlxText(labelX, startY + 14, ROW_W - 200, labelStr, labelSize);
			lbl.setFormat(Paths.font('vcr.ttf'), labelSize, labelColor, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lbl.borderSize    = 2;
			lbl.alpha         = startAlpha;
			lbl.scrollFactor.set();
			lbl.ID            = i;
			labelGroup.add(lbl);

			if (!instant)
				FlxTween.tween(lbl, {alpha: 1, y: startY + 14 + (targetY - startY)}, 0.35,
					{ease: FlxEase.quartOut, startDelay: i * 0.03});

			if (!isCategory)
			{
				var opt:Option = cast item;
				if (opt.type == BOOL)
				{
					var cb = new CheckboxThingie(
						centerX + ROW_W - 70,
						startY + (ROW_H - 4) / 2 - 18,
						Std.string(opt.getValue()) == 'true'
					);
					cb.alpha         = startAlpha;
					cb.scrollFactor.set();
					cb.ID            = i;
					checkboxGroup.add(cb);

					if (!instant)
						FlxTween.tween(cb, {alpha: 1}, 0.35,
							{ease: FlxEase.quartOut, startDelay: i * 0.03});
				}
				else
				{
					var valStr = _getDisplayValue(opt);
					var vt = new AttachedText(valStr, 0);
					vt.x          = centerX + ROW_W - 200;
					vt.y          = startY + 14;
					vt.alpha      = startAlpha;
					vt.scrollFactor.set();
					vt.ID         = i;
					vt.color      = _isLocked(opt) ? LOCKED_GRAY : FlxColor.WHITE;
					valueGroup.add(vt);

					if (!instant)
						FlxTween.tween(vt, {alpha: 1}, 0.35,
							{ease: FlxEase.quartOut, startDelay: i * 0.03});
				}
			}
		}

		if (curSelected >= flatList.length)
			curSelected = flatList.length - 1;
		if (curSelected < 0)
			curSelected = 0;
	}

	function _rowTargetY(i:Int):Float
	{

		var scrollOffset:Float = Math.max(0, curSelected - 2) * ROW_H;
		return LIST_TOP + i * ROW_H - scrollOffset;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		animTimer  += elapsed;
		pulseTimer += elapsed;

		if (bg       != null) bg.angle        = Math.sin(animTimer * 0.3) * 2;
		if (glowEffect != null)
		{
			glowEffect.alpha = 0.05 + Math.sin(pulseTimer * 2) * 0.02;
			glowEffect.angle += elapsed * 12;
		}

		if (flatList.length > 1)
		{
			var prog    = curSelected / (flatList.length - 1);
			var indY    = 180 + prog * (FlxG.height - 400);
			scrollIndicator.y = FlxMath.lerp(scrollIndicator.y, indY, elapsed * 10);
		}

		_updateRowPositions(elapsed);

		if (controls.UI_UP_P)   changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		if (controls.BACK)
		{
			FlxTween.tween(bgGradient, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(bgDarken,   {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(topBar,     {y: -150},  0.3, {ease: FlxEase.backIn});
			FlxTween.tween(bottomBar,  {y: FlxG.height}, 0.3, {ease: FlxEase.backIn});
			new FlxTimer().start(0.3, function(_) close());
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept <= 0 && flatList.length > 0)
		{
			var item = flatList[curSelected];

			if (Std.isOfType(item, OptionCategory))
			{

				if (controls.ACCEPT)
					_toggleCategory(cast item);
			}
			else
			{

				var opt:Option = cast item;

				if (_isLocked(opt))
				{
					if (controls.UI_LEFT_P || controls.UI_RIGHT_P || controls.ACCEPT)
						FlxG.sound.play(Paths.sound('cancelMenu'));
				}
				else
				{
					switch (opt.type)
					{
						case BOOL:
							if (controls.ACCEPT)
							{
								opt.setValue(opt.getValue() == true ? false : true);
								opt.change();
								_reloadCheckboxes();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}

						default:
							if (controls.UI_LEFT || controls.UI_RIGHT)
							{
								var pressed = controls.UI_LEFT_P || controls.UI_RIGHT_P;
								if (holdTime > 0.5 || pressed)
								{
									if (pressed)
									{
										switch (opt.type)
										{
											case INT, FLOAT, PERCENT:
												var add:Dynamic = controls.UI_LEFT ? -opt.changeValue : opt.changeValue;
												holdValue = opt.getValue() + add;
												if (holdValue < opt.minValue) holdValue = opt.minValue;
												if (holdValue > opt.maxValue) holdValue = opt.maxValue;
												opt.setValue(opt.type == INT ? Math.round(holdValue)
													: FlxMath.roundDecimal(holdValue, opt.decimals));

											case STRING:
												var n:Int = opt.curOption + (controls.UI_LEFT_P ? -1 : 1);
												if (n < 0) n = opt.options.length - 1;
												else if (n >= opt.options.length) n = 0;
												opt.curOption = n;
												opt.setValue(opt.options[n]);

											default:
										}
										opt.change();
										_refreshValueText(opt);
										FlxG.sound.play(Paths.sound('scrollMenu'));
									}
									else if (opt.type != STRING)
									{
										holdValue += opt.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
										if (holdValue < opt.minValue) holdValue = opt.minValue;
										if (holdValue > opt.maxValue) holdValue = opt.maxValue;
										opt.setValue(opt.type == INT ? Math.round(holdValue)
											: FlxMath.roundDecimal(holdValue, opt.decimals));
										opt.change();
										_refreshValueText(opt);
									}
								}
								if (opt.type != STRING) holdTime += elapsed;
							}
							else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
							{
								if (holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
								holdTime = 0;
							}
					}
				}

				if (controls.RESET)
				{
					opt.setValue(opt.defaultValue);
					if (opt.type == STRING)
						opt.curOption = opt.options.indexOf(opt.getValue());
					opt.change();
					_reloadCheckboxes();
					_refreshValueText(opt);
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxG.camera.flash(FlxColor.WHITE, 0.15);
				}
			}
		}

		if (nextAccept > 0) nextAccept--;
	}

	function _toggleCategory(cat:OptionCategory)
	{
		cat.isOpen = !cat.isOpen;
		FlxG.sound.play(Paths.sound('scrollMenu'));

		_updateDesc(cat.isOpen
			? cat.description
			: '${cat.name} — ENTER ile aç/kapat');

		rebuildFlatList();
		rebuildRows(false);   

		_updateSelectionVisuals();
	}

	function changeSelection(dir:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + dir, 0, flatList.length - 1);

		var item = flatList[curSelected];
		if (Std.isOfType(item, OptionCategory))
		{
			var cat:OptionCategory = cast item;
			curOption = null;
			_updateDesc('${cat.name}${cat.isOpen ? " — ENTER ile kapat" : " — ENTER ile aç"}');
		}
		else
		{
			curOption = cast item;
			_updateDesc(curOption.description != '' ? curOption.description : curOption.name);
		}

		holdTime = 0;
		_updateSelectionVisuals();
		if (dir != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function _updateSelectionVisuals()
	{
		for (i in 0...rowGroup.members.length)
		{
			var card  = rowGroup.members[i];
			var label = labelGroup.members[i];
			if (card == null || label == null) continue;

			var isSelected = (i == curSelected);
			var item       = flatList[i];
			var isCat      = Std.isOfType(item, OptionCategory);

			var baseColor:Int = isCat ? CAT_COLOR : OPT_COLOR;
			card.color = isSelected ? SEL_COLOR : baseColor;
			card.alpha  = isSelected ? 1.0 : 0.75;

			if (isCat)
			{
				label.alpha = isSelected ? 1.0 : 0.75;
			}
			else
			{
				var opt:Option = cast item;
				var locked     = _isLocked(opt);
				label.color    = locked ? LOCKED_GRAY : FlxColor.WHITE;
				label.alpha    = isSelected ? 1.0 : (locked ? 0.4 : 0.65);
			}
		}
	}

	function _updateRowPositions(elapsed:Float)
	{
		var centerX:Float = (FlxG.width - ROW_W) / 2;

		for (i in 0...flatList.length)
		{
			var targetY = _rowTargetY(i);

			var card  = rowGroup.members[i];
			var label = labelGroup.members[i];
			if (card  != null) card.y  = FlxMath.lerp(card.y,  targetY,           elapsed * 12);
			if (label != null) label.y = FlxMath.lerp(label.y, targetY + 14,      elapsed * 12);

			for (cb in checkboxGroup.members)
				if (cb != null && cb.ID == i)
					cb.y = FlxMath.lerp(cb.y, targetY + (ROW_H - 4) / 2 - 18, elapsed * 12);

			for (vt in valueGroup.members)
				if (vt != null && vt.ID == i)
					vt.y = FlxMath.lerp(vt.y, targetY + 14, elapsed * 12);
		}
	}

	function _isLocked(opt:Option):Bool
	{
		if (opt.dependsOn == null) return false;
		for (cat in categories)
			for (parent in cat.options)
				if (parent.variable == opt.dependsOn)
					return Std.string(parent.getValue()) != 'true';
		return false;
	}

	function _getDisplayValue(opt:Option):String
	{
		var val:Dynamic = opt.getValue();
		if (opt.type == PERCENT) val = FlxMath.roundDecimal(val * 100, 1);
		return opt.displayFormat.replace('%v', Std.string(val))
			.replace('%d', Std.string(opt.defaultValue));
	}

	function _refreshValueText(opt:Option)
	{
		var idx = flatList.indexOf(opt);
		if (idx < 0) return;
		for (vt in valueGroup.members)
			if (vt != null && vt.ID == idx)
			{
				vt.text  = _getDisplayValue(opt);
				vt.color = _isLocked(opt) ? LOCKED_GRAY : FlxColor.WHITE;
				return;
			}
	}

	function _reloadCheckboxes()
	{
		for (i in 0...flatList.length)
		{
			var item = flatList[i];
			if (Std.isOfType(item, Option))
			{
				var opt:Option = cast item;
				if (opt.type == BOOL)
					for (cb in checkboxGroup.members)
						if (cb != null && cb.ID == i)
							cb.daValue = Std.string(opt.getValue()) == 'true';
			}
		}

		_refreshDependencyColors();
	}

	function _refreshDependencyColors()
	{
		for (i in 0...flatList.length)
		{
			var item = flatList[i];
			if (!Std.isOfType(item, Option)) continue;
			var opt:Option = cast item;
			if (opt.dependsOn == null) continue;

			var locked = _isLocked(opt);
			var lbl    = labelGroup.members[i];
			if (lbl != null) lbl.color = locked ? LOCKED_GRAY : 0xFFDDDDDD;
			for (vt in valueGroup.members)
				if (vt != null && vt.ID == i)
					vt.color = locked ? LOCKED_GRAY : FlxColor.WHITE;
		}
	}

	function _updateDesc(text:String)
	{
		FlxTween.cancelTweensOf(descText);
		descText.alpha = 0;
		descText.text  = text;
		FlxTween.tween(descText, {alpha: 1}, 0.25, {ease: FlxEase.quartOut});
	}
}