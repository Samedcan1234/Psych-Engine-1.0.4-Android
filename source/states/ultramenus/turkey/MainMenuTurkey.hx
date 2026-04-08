package states.ultramenus.turkey;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import backend.ThemeManager;

class MainMenuTurkey extends MusicBeatState
{
	public static var curSelected:Int = 0;

	var optionShit:Array<String> = [
		'hikaye_modu',
		'serbest_oyun',
		#if MODS_ALLOWED 'modlar', #end
		#if ACHIEVEMENTS_ALLOWED 'basarimlar', #end
		'yapimcilar',
		'ayarlar'
	];

	var menuTitles:Array<String> = [
		'HİKAYE MODU',
		'SERBEST OYUN',
		#if MODS_ALLOWED 'MODLAR', #end
		#if ACHIEVEMENTS_ALLOWED 'BAŞARILAR', #end
		'YAPIMCILAR',
		'AYARLAR'
	];

	var menuIcons:Array<String> = [
		'📖', '🎵',
		#if MODS_ALLOWED '📦', #end
		#if ACHIEVEMENTS_ALLOWED '🏆', #end
		'👥', '⚙️'
	];

	static final RED:FlxColor        = 0xFFE30A17;
	static final RED_DARK:FlxColor   = 0xFF8B0000;
	static final RED_LIGHT:FlxColor  = 0xFFFF4444;
	static final WHITE:FlxColor      = 0xFFFFFFFF;
	static final BG_DARK:FlxColor    = 0xFF0D0005;
	static final CARD_BG:FlxColor    = 0xCC140008;

	var bgImages:Array<FlxSprite> = [];
	var bgImagePaths:Array<String> = ['pet/turkey/1', 'pet/turkey/2', 'pet/turkey/3', 'pet/turkey/5'];
	var curBgIndex:Int = 0;
	var bgTimer:Float = 0;
	static final BG_CHANGE_TIME:Float = 10.0;
	var isBgTransitioning:Bool = false;

	var petLogo:FlxSprite;
	var petLogoBaseScale:Float = 0.06;

	var bg:FlxSprite;
	var logoText:FlxText;
	var logoSubText:FlxText;
	var versionText:FlxText;

	var menuCards:Array<FlxSprite> = [];
	var menuCardGlows:Array<FlxSprite> = [];
	var menuTexts:Array<FlxText> = [];
	var menuIconTexts:Array<FlxText> = [];
	var menuArrows:Array<FlxText> = [];

	var selectorBar:FlxSprite;
	var selectorGlow:FlxSprite;
	var particles:Array<FlxSprite> = [];

	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var ambientTime:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Ana Menüde - Türkiye Edition", null);
		#end

		persistentUpdate = persistentDraw = true;
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, BG_DARK);
		add(bg);
		for (i in 0...bgImagePaths.length)
		{
			var bgImg = new FlxSprite(0, 0);
			bgImg.loadGraphic(Paths.image(bgImagePaths[i]));
			bgImg.antialiasing = ClientPrefs.data.antialiasing;
			bgImg.setGraphicSize(FlxG.width, FlxG.height); 
			bgImg.updateHitbox();
			bgImg.x = 0;
			bgImg.y = 0;
			bgImg.alpha = (i == 0) ? 0.5 : 0;
			add(bgImg);
			bgImages.push(bgImg);
		}

		var gradLeft = FlxGradient.createGradientFlxSprite(
			Std.int(FlxG.width / 2), FlxG.height,
			[0x55E30A17, 0x00E30A17],
			1, 0
		);
		gradLeft.x = 0;
		add(gradLeft);

		createParticles();

		petLogo = new FlxSprite();
		petLogo.loadGraphic(Paths.image('pet/petlogo'));
		petLogo.antialiasing = ClientPrefs.data.antialiasing;
		petLogo.setGraphicSize(Std.int(FlxG.width * 0.48));
		petLogo.updateHitbox();
		petLogo.x = FlxG.width - petLogo.width - 15;
		petLogo.y = (FlxG.height - petLogo.height) / 2;
		petLogo.alpha = 0.92;
		add(petLogo);

		var leftArrowHint = new FlxText(FlxG.width - Std.int(FlxG.width * 0.48) - 15, FlxG.height - 35, 30, "◄", 18);
		leftArrowHint.setFormat(Paths.font("vcr.ttf"), 18, 0xFF444444, LEFT);
		add(leftArrowHint);

		var rightArrowHint = new FlxText(FlxG.width - 35, FlxG.height - 35, 30, "►", 18);
		rightArrowHint.setFormat(Paths.font("vcr.ttf"), 18, 0xFF444444, RIGHT);
		add(rightArrowHint);

		var bgHint = new FlxText(FlxG.width - Std.int(FlxG.width * 0.48), FlxG.height - 35, Std.int(FlxG.width * 0.48) - 10, "◄ ► Arka Plan", 13);
		bgHint.setFormat(Paths.font("vcr.ttf"), 13, 0xFF444444, CENTER);
		add(bgHint);

		var logoBG = FlxGradient.createGradientFlxSprite(
			500, 100,
			[0xAAE30A17, 0x00E30A17],
			1, 0
		);
		logoBG.x = 0;
		logoBG.y = 15;
		add(logoBG);

		var logoLine = new FlxSprite(0, 15).makeGraphic(6, 80, WHITE);
		logoLine.alpha = 0.9;
		add(logoLine);

		logoText = new FlxText(20, 20, 0, "PSYCH ENGINE", 36);
		logoText.setFormat(Paths.font("vcr.ttf"), 36, WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		logoText.borderSize = 2;
		add(logoText);

		logoSubText = new FlxText(20, 60, 0, "TÜRKİYE EDİTİON", 18);
		logoSubText.setFormat(Paths.font("vcr.ttf"), 18, RED_LIGHT, LEFT);
		add(logoSubText);

		versionText = new FlxText(FlxG.width - 200, FlxG.height - 28, 190, "v" + MainMenuState.psychEngineVersion, 14);
		versionText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF666666, RIGHT);
		add(versionText);

		var hint = new FlxText(10, FlxG.height - 28, 300, "↑↓ Seç   ENTER Onayla   ESC Geri", 14);
		hint.setFormat(Paths.font("vcr.ttf"), 14, 0xFF555555, LEFT);
		add(hint);

		selectorGlow = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 0.47) - 40, 82, RED);
		selectorGlow.x = 20;
		selectorGlow.alpha = 0.12;
		add(selectorGlow);

		selectorBar = new FlxSprite(0, 0).makeGraphic(6, 72, RED);
		selectorBar.x = 20;
		add(selectorBar);

		var cardWidth:Int = Std.int(FlxG.width * 0.47) - 48;

		for (i in 0...optionShit.length)
		{
			var cardGlow = new FlxSprite(22, 0).makeGraphic(cardWidth + 4, 76, RED);
			cardGlow.alpha = 0;
			add(cardGlow);
			menuCardGlows.push(cardGlow);

			var card = new FlxSprite(24, 0).makeGraphic(cardWidth, 72, CARD_BG);
			add(card);
			menuCards.push(card);

			var iconTxt = new FlxText(40, 0, 50, menuIcons[i], 30);
			iconTxt.setFormat(null, 30, WHITE, CENTER);
			add(iconTxt);
			menuIconTexts.push(iconTxt);

			var txt = new FlxText(100, 0, cardWidth - 120, menuTitles[i], 26);
			txt.setFormat(Paths.font("vcr.ttf"), 26, WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
			txt.borderSize = 1.5;
			add(txt);
			menuTexts.push(txt);

			var arrow = new FlxText(cardWidth - 10, 0, 40, "▶", 22);
			arrow.setFormat(Paths.font("vcr.ttf"), 22, RED, RIGHT);
			arrow.alpha = 0;
			add(arrow);
			menuArrows.push(arrow);
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		camFollow.screenCenter();
		camFollowPos.screenCenter();
		FlxG.camera.follow(camFollowPos, null, 1);

		changeItem();

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		addTouchPad("UP_DOWN", "A_B_E");
		super.create();
	}

	function createParticles()
	{
		for (i in 0...25)
		{
			var p = new FlxSprite(
				FlxG.random.float(0, FlxG.width),
				FlxG.random.float(0, FlxG.height)
			);
			var size = Std.int(FlxG.random.float(1, 3));
			p.makeGraphic(size, size, i % 3 == 0 ? RED : WHITE);
			p.alpha = FlxG.random.float(0.05, 0.25);
			p.velocity.y = FlxG.random.float(-20, -5);
			p.velocity.x = FlxG.random.float(-3, 3);
			add(p);
			particles.push(p);
		}
	}

	function changeBg(targetIndex:Int)
	{
		if (isBgTransitioning || targetIndex == curBgIndex) return;
		isBgTransitioning = true;

		var oldIndex = curBgIndex;
		curBgIndex = targetIndex;
		bgTimer = 0;

		FlxTween.tween(bgImages[oldIndex], {alpha: 0}, 0.8, {ease: FlxEase.quadInOut});

		FlxTween.tween(bgImages[curBgIndex], {alpha: 0.35}, 0.8, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween) {
				isBgTransitioning = false;
			}
		});

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
	}

	function changeBgRandom()
	{
		var newIndex:Int = curBgIndex;
		while (newIndex == curBgIndex)
			newIndex = FlxG.random.int(0, bgImages.length - 1);
		changeBg(newIndex);
	}

	function changeBgNext()
	{
		var next = (curBgIndex + 1) % bgImages.length;
		changeBg(next);
	}

	function changeBgPrev()
	{
		var prev = curBgIndex - 1;
		if (prev < 0) prev = bgImages.length - 1;
		changeBg(prev);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		ambientTime += elapsed;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		var lerpVal:Float = FlxMath.bound(elapsed * 9, 0, 1);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);

		if (!isBgTransitioning)
		{
			bgTimer += elapsed;
			if (bgTimer >= BG_CHANGE_TIME)
				changeBgRandom();
		}

		for (p in particles)
			if (p.y < -5) { p.y = FlxG.height + 5; p.x = FlxG.random.float(0, FlxG.width); }

		if (petLogo != null)
		{
			var breathe = petLogoBaseScale + Math.sin(ambientTime * 1.2) * 0.012;
			petLogo.scale.set(breathe, breathe);
		}

		selectorGlow.alpha = 0.10 + Math.sin(ambientTime * 3) * 0.05;

		for (i in 0...menuArrows.length)
			if (i == curSelected)
				menuArrows[i].x = (Std.int(FlxG.width * 0.47) - 58) + Math.sin(ambientTime * 4) * 4;

		var breathe = 1 + Math.sin(ambientTime * 1.5) * 0.008;
		logoText.scale.set(breathe, breathe);

		updateMenuPositions(lerpVal);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)    changeItem(-1);
			if (controls.UI_DOWN_P)  changeItem(1);

			if (controls.UI_LEFT_P)  changeBgPrev();
			if (controls.UI_RIGHT_P) changeBgNext();

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT) selectEntry();

			else if (controls.justPressed('debug_1') || mobilePadJustPressed("E"))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}
	}

	function updateMenuPositions(lerpVal:Float)
	{
		var startY:Float = 130;
		var spacing:Float = 82;

		for (i in 0...menuCards.length)
		{
			var targetY:Float = startY + i * spacing;

			menuCards[i].y      = FlxMath.lerp(menuCards[i].y, targetY, lerpVal);
			menuCardGlows[i].y  = FlxMath.lerp(menuCardGlows[i].y, targetY - 2, lerpVal);
			menuTexts[i].y      = FlxMath.lerp(menuTexts[i].y, targetY + 22, lerpVal);
			menuIconTexts[i].y  = FlxMath.lerp(menuIconTexts[i].y, targetY + 18, lerpVal);
			menuArrows[i].y     = FlxMath.lerp(menuArrows[i].y, targetY + 24, lerpVal);

			if (i == curSelected)
			{
				menuCards[i].alpha     = FlxMath.lerp(menuCards[i].alpha, 1, lerpVal);
				menuTexts[i].alpha     = 1;
				menuTexts[i].color     = WHITE;
				menuIconTexts[i].alpha = 1;
				menuCardGlows[i].alpha = FlxMath.lerp(menuCardGlows[i].alpha, 0.08, lerpVal);
				menuArrows[i].alpha    = FlxMath.lerp(menuArrows[i].alpha, 1, lerpVal);

				selectorBar.y  = FlxMath.lerp(selectorBar.y, targetY + 3, lerpVal);
				selectorGlow.y = FlxMath.lerp(selectorGlow.y, targetY - 2, lerpVal);
			}
			else
			{
				menuCards[i].alpha     = FlxMath.lerp(menuCards[i].alpha, 0.4, lerpVal);
				menuTexts[i].alpha     = 0.45;
				menuTexts[i].color     = 0xFFCCCCCC;
				menuIconTexts[i].alpha = 0.45;
				menuCardGlows[i].alpha = 0;
				menuArrows[i].alpha    = FlxMath.lerp(menuArrows[i].alpha, 0, lerpVal);
			}
		}
	}

	function changeItem(change:Int = 0)
	{
		curSelected += change;
		if (curSelected >= menuCards.length) curSelected = 0;
		if (curSelected < 0) curSelected = menuCards.length - 1;

		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function selectEntry()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		for (i in 0...menuCards.length)
		{
			if (i != curSelected)
			{
				FlxTween.tween(menuCards[i],     {x: -FlxG.width}, 0.4, {ease: FlxEase.backIn, startDelay: i * 0.03});
				FlxTween.tween(menuTexts[i],     {x: -FlxG.width}, 0.4, {ease: FlxEase.backIn, startDelay: i * 0.03});
				FlxTween.tween(menuIconTexts[i], {x: -FlxG.width}, 0.4, {ease: FlxEase.backIn, startDelay: i * 0.03});
				FlxTween.tween(menuArrows[i],    {x: -FlxG.width}, 0.4, {ease: FlxEase.backIn, startDelay: i * 0.03});
			}
		}

		FlxFlicker.flicker(menuCards[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
		{
			switch (optionShit[curSelected])
			{
				case 'hikaye_modu':  ThemeManager.switchToStoryMenu();
				case 'serbest_oyun': ThemeManager.switchToFreeplay();
				#if MODS_ALLOWED
				case 'modlar':       MusicBeatState.switchState(new ModsMenuState());
				#end
				case 'basarimlar':   ThemeManager.switchToAchievements();
				case 'yapimcilar':   ThemeManager.switchToCredits();
				case 'ayarlar':
					MusicBeatState.switchState(new OptionsState());
					OptionsState.onPlayState = false;
			}
		});

		FlxTween.tween(logoText,     {alpha: 0, y: logoText.y - 30},    0.4, {ease: FlxEase.backIn});
		FlxTween.tween(logoSubText,  {alpha: 0, y: logoSubText.y - 20}, 0.3, {ease: FlxEase.backIn});
		FlxTween.tween(selectorBar,  {alpha: 0}, 0.3);
		FlxTween.tween(selectorGlow, {alpha: 0}, 0.3);
		FlxTween.tween(petLogo,      {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
	}

	override function beatHit()
	{
		super.beatHit();

		FlxTween.cancelTweensOf(logoText.scale);
		logoText.scale.set(1.06, 1.06);
		FlxTween.tween(logoText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});

		FlxTween.cancelTweensOf(selectorBar);
		selectorBar.color = WHITE;
		FlxTween.color(selectorBar, 0.3, WHITE, RED);

		if (petLogo != null)
		{
			FlxTween.cancelTweensOf(petLogo.scale);
			petLogo.scale.set(petLogoBaseScale + 0.06, petLogoBaseScale + 0.06);
			FlxTween.tween(petLogo.scale, {x: petLogoBaseScale, y: petLogoBaseScale}, 0.35, {ease: FlxEase.quadOut});
		}
	}
}