package states;

import backend.Discord;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxGradient;
import objects.AttachedSprite;
import states.ThanksCreditsState;
import flixel.effects.FlxFlicker;

class CreditsState extends MusicBeatState
{
	private var creditsStuff:Array<Array<String>> = [];
	var curSelected:Int      = 0;
	var curLinkSelected:Int  = 0;
	var inLinkSelection:Bool = false;

	// ── Arka plan ──────────────────────────────────────────
	var bg:FlxSprite;
	var bgDarken:FlxSprite;
	var gridBG:FlxBackdrop;
	var scanlines:FlxBackdrop;
	var ambientOrb1:FlxSprite;
	var ambientOrb2:FlxSprite;
	var ambientOrb3:FlxSprite;
	var ambientParticles:Array<FlxSprite> = [];

	// ── Sol panel ──────────────────────────────────────────
	var leftPanel:FlxSprite;
	var leftPanelGlow:FlxSprite;
	var leftPanelEdge:FlxSprite;
	var leftName:FlxText;
	var leftNameShadow:FlxText;
	var leftAccentLine:FlxSprite;
	var leftAccentLineShadow:FlxSprite;
	var sectionChip:FlxSprite;
	var sectionChipText:FlxText;
	var indexText:FlxText;

	// ── Sağ panel ──────────────────────────────────────────
	var rightSideCover:FlxSprite;
	var charIconBG:FlxSprite;
	var charIconRing:FlxSprite;
	var charIconGlow:FlxSprite;
	var charIcon:FlxSprite;
	var charName:Alphabet;
	var charRoleBox:FlxSprite;
	var charRoleSeparator:FlxSprite;
	var charRole:FlxText;
	var charSectionLabel:FlxText;

	// ── Üst bar ────────────────────────────────────────────
	var topBar:FlxSprite;
	var topBarAccentLine:FlxSprite;
	var topBarGlowStrip:FlxSprite;
	var topBarTitle:FlxText;
	var topBarSection:FlxText;
	var topBarHint:FlxText;

	// ── Link sistemi ───────────────────────────────────────
	var linkContainers:Array<{
		name:String,
		container:FlxSprite,
		containerGlow:FlxSprite,
		accentStripe:FlxSprite,
		icon:FlxSprite,
		text:FlxText,
		subText:FlxText,
		url:String
	}> = [];
	var activeLinkIndices:Array<Int> = [];
	var linkSelectionBar:FlxSprite;
	var linkSelectionBarGlow:FlxSprite;
	var noLinksText:FlxText;

	// ── Alt bar ────────────────────────────────────────────
	var helpGrad:FlxSprite;
	var helpText:FlxText;
	var progressBarBg:FlxSprite;
	var progressBar:FlxSprite;
	var progressPip:FlxSprite;
	var progressLabel:FlxText;

	// ── Renk & animasyon ───────────────────────────────────
	var intendedColor:FlxColor      = 0xFF4A90E2;
	var currentAccentColor:FlxColor = 0xFF4A90E2;
	var ambientTimer:Float = 0;
	var breathTimer:Float  = 0;
	var entranceDone:Bool  = false;

	static inline var SPLIT_X:Int     = 520;
	static inline var TOP_H:Int       = 68;
	static inline var BOTTOM_H:Int    = 60;
	static inline var LINK_H:Int      = 70;
	static inline var LINK_GAP:Int    = 10;
	static inline var LINK_START_Y:Int = 165;

	// ═══════════════════════════════════════════════════════
	// CREATE
	// ═══════════════════════════════════════════════════════

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(Language.getPhrase('credits_rpc', 'Credits'), null);
		#end

		persistentUpdate = true;

		// ── Arka plan ────────────────────────────────────
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(FlxG.width * 1.15));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.35;
		add(bg);

		bgDarken = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF060610);
		bgDarken.alpha = 0.82;
		add(bgDarken);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(55, 55, 110, 110, true, 0x10FFFFFF, 0x0));
		gridBG.velocity.set(14, 12);
		gridBG.alpha = 0;
		FlxTween.tween(gridBG, {alpha: 0.22}, 1.5, {ease: FlxEase.quartOut});
		add(gridBG);

		scanlines = new FlxBackdrop(null, Y, 0, 3);
		scanlines.makeGraphic(FlxG.width, 2, 0x07FFFFFF);
		scanlines.velocity.y = 28;
		add(scanlines);

		ambientOrb1 = new FlxSprite(-80, -60).makeGraphic(420, 340, 0x00000000);
		_makeRadialGlow(ambientOrb1, 420, 340, 0xFF4A90E2, 0.14);
		add(ambientOrb1);

		ambientOrb2 = new FlxSprite(FlxG.width - 260, FlxG.height - 300).makeGraphic(380, 380, 0x00000000);
		_makeRadialGlow(ambientOrb2, 380, 380, 0xFF8B5CF6, 0.11);
		add(ambientOrb2);

		ambientOrb3 = new FlxSprite(SPLIT_X - 180, Std.int(FlxG.height / 2) - 160).makeGraphic(360, 320, 0x00000000);
		_makeRadialGlow(ambientOrb3, 360, 320, 0xFF10B981, 0.07);
		add(ambientOrb3);

		createAmbientParticles();

		// ── Sol panel ────────────────────────────────────
		leftPanelGlow = new FlxSprite(0, 0).makeGraphic(SPLIT_X + 30, FlxG.height, 0xFF4A90E2);
		leftPanelGlow.alpha = 0.035;
		add(leftPanelGlow);

		leftPanel = FlxGradient.createGradientFlxSprite(
			SPLIT_X, FlxG.height,
			[0xF20A0A14, 0xF8050510, 0xFF020208],
			1, 0
		);
		leftPanel.y = FlxG.height;
		FlxTween.tween(leftPanel, {y: 0}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.05});
		add(leftPanel);

		leftPanelEdge = new FlxSprite(SPLIT_X - 2, 0).makeGraphic(2, FlxG.height, 0xFF4A90E2);
		leftPanelEdge.alpha = 0.22;
		add(leftPanelEdge);

		sectionChip = new FlxSprite(18, TOP_H + 14).makeGraphic(SPLIT_X - 36, 26, 0xFF4A90E2);
		sectionChip.alpha = 0.10;
		add(sectionChip);

		sectionChipText = new FlxText(22, TOP_H + 16, SPLIT_X - 44,
			Language.getPhrase('credits_section_default', 'CREDITS'), 11);
		sectionChipText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF4A90E2, LEFT);
		sectionChipText.alpha = 0.85;
		add(sectionChipText);

		leftNameShadow = new FlxText(5, TOP_H + 54, SPLIT_X, "", 48);
		leftNameShadow.setFormat(Paths.font("vcr.ttf"), 48, 0xFF000000, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftNameShadow.alpha = 0.30;
		add(leftNameShadow);

		leftName = new FlxText(8, TOP_H + 51, SPLIT_X - 16, "", 48);
		leftName.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftName.borderSize = 3;
		add(leftName);

		leftAccentLineShadow = new FlxSprite(20, TOP_H + 112).makeGraphic(SPLIT_X - 40, 3, 0xFF000000);
		leftAccentLineShadow.alpha = 0.35;
		add(leftAccentLineShadow);

		leftAccentLine = new FlxSprite(20, TOP_H + 110).makeGraphic(SPLIT_X - 40, 3, FlxColor.WHITE);
		leftAccentLine.alpha = 0.65;
		add(leftAccentLine);

		indexText = new FlxText(18, TOP_H + 118, SPLIT_X - 36, "", 11);
		indexText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF555577, RIGHT);
		add(indexText);

		linkSelectionBarGlow = new FlxSprite(10, LINK_START_Y).makeGraphic(SPLIT_X - 20, LINK_H + 2, 0xFF4A90E2);
		linkSelectionBarGlow.alpha = 0;
		add(linkSelectionBarGlow);

		linkSelectionBar = new FlxSprite(10, LINK_START_Y).makeGraphic(SPLIT_X - 20, LINK_H, 0xFF4A90E2);
		linkSelectionBar.alpha = 0;
		add(linkSelectionBar);

		initializeLinkContainers();

		noLinksText = new FlxText(20, LINK_START_Y + 40, SPLIT_X - 40,
			Language.getPhrase('credits_no_links', 'No links available'), 16);
		noLinksText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF333355, CENTER);
		noLinksText.alpha = 0;
		add(noLinksText);

		// ── Sağ panel ────────────────────────────────────
		rightSideCover = new FlxSprite(FlxG.width, 0).makeGraphic(FlxG.width - SPLIT_X, FlxG.height, FlxColor.WHITE);
		FlxTween.tween(rightSideCover, {x: SPLIT_X}, 0.65, {ease: FlxEase.expoOut, startDelay: 0.08});
		add(rightSideCover);

		var iconCX = SPLIT_X + (FlxG.width - SPLIT_X) / 2;
		var iconCY = FlxG.height * 0.35;

		charIconBG = new FlxSprite(iconCX - 110, iconCY - 110).makeGraphic(220, 220, 0xFFEEEEF5);
		charIconBG.alpha = 0.55;
		add(charIconBG);

		charIconRing = new FlxSprite(iconCX - 112, iconCY - 112).makeGraphic(224, 224, 0xFF4A90E2);
		charIconRing.alpha = 0.12;
		add(charIconRing);

		charIconGlow = new FlxSprite(0, 0).makeGraphic(240, 240, FlxColor.WHITE);
		charIconGlow.blend = ADD;
		charIconGlow.alpha = 0.18;
		charIconGlow.antialiasing = ClientPrefs.data.antialiasing;
		add(charIconGlow);

		charIcon = new FlxSprite(0, 0);
		charIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(charIcon);

		charSectionLabel = new FlxText(SPLIT_X + 14, TOP_H + 8, FlxG.width - SPLIT_X - 20,
			Language.getPhrase('credits_team_label', '— TEAM —'), 13);
		charSectionLabel.setFormat(Paths.font("vcr.ttf"), 13, 0xFFAAAAAA, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charSectionLabel.borderSize = 1.2;
		charSectionLabel.alpha = 0.75;
		add(charSectionLabel);

		charName = new Alphabet(0, 0, "", true);
		charName.scaleX = 0.72;
		charName.scaleY = 0.72;
		add(charName);

		charRoleBox = FlxGradient.createGradientFlxSprite(
			FlxG.width - SPLIT_X, 145,
			[0x00000000, 0x88000000, 0xCC000000],
			1, 90
		);
		charRoleBox.x = SPLIT_X;
		charRoleBox.y = FlxG.height - 145;
		add(charRoleBox);

		charRoleSeparator = new FlxSprite(SPLIT_X + 40, FlxG.height - 104).makeGraphic(
			FlxG.width - SPLIT_X - 80, 2, FlxColor.WHITE);
		charRoleSeparator.alpha = 0.22;
		add(charRoleSeparator);

		charRole = new FlxText(SPLIT_X + 20, FlxG.height - 98, FlxG.width - SPLIT_X - 40, "", 21);
		charRole.setFormat(Paths.font("vcr.ttf"), 21, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charRole.borderSize = 2.5;
		add(charRole);

		// ── Üst bar ──────────────────────────────────────
		topBarGlowStrip = new FlxSprite(0, 0).makeGraphic(FlxG.width, TOP_H + 10, 0xFF4A90E2);
		topBarGlowStrip.alpha = 0.04;
		add(topBarGlowStrip);

		topBar = new FlxSprite(0, -TOP_H).makeGraphic(FlxG.width, TOP_H, 0xFF060610);
		topBar.alpha = 0.96;
		FlxTween.tween(topBar, {y: 0}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		add(topBar);

		topBarAccentLine = new FlxSprite(0, -(TOP_H - 2 + 80)).makeGraphic(FlxG.width, 2, 0xFF4A90E2);
		topBarAccentLine.alpha = 0.45;
		FlxTween.tween(topBarAccentLine, {y: TOP_H - 2}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.12});
		add(topBarAccentLine);

		topBarTitle = new FlxText(18, 12, 350,
			Language.getPhrase('credits_title', '✦  CREDITS'), 26);
		topBarTitle.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topBarTitle.borderSize = 2;
		add(topBarTitle);

		topBarSection = new FlxText(0, 14, FlxG.width - 20, "", 16);
		topBarSection.setFormat(Paths.font("vcr.ttf"), 16, 0xFF888888, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		topBarSection.borderSize = 1.2;
		add(topBarSection);

		topBarHint = new FlxText(0, TOP_H - 19, FlxG.width - 14,
			Language.getPhrase('credits_hint', '[ CTRL ] Flow  •  [ ESC ] Back  •  [ ENTER / ← ] Links'), 10);
		topBarHint.setFormat(Paths.font("vcr.ttf"), 10, 0xFF444466, RIGHT);
		add(topBarHint);

		// ── Alt bar ──────────────────────────────────────
		helpGrad = FlxGradient.createGradientFlxSprite(SPLIT_X, BOTTOM_H, [0x00000000, 0xCC000000], 1, 90);
		helpGrad.setPosition(0, FlxG.height - BOTTOM_H);
		add(helpGrad);

		helpText = new FlxText(8, FlxG.height - BOTTOM_H + 8, SPLIT_X - 16,
			Language.getPhrase('credits_help_normal',
				'▲ ▼  Select   •   ENTER / ←  Links\nCTRL  Watch Credits Flow'), 12);
		helpText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888899, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpText.borderSize = 1.2;
		add(helpText);

		progressBarBg = new FlxSprite(0, FlxG.height - 3).makeGraphic(SPLIT_X, 3, 0xFF0D0D1A);
		add(progressBarBg);

		progressBar = new FlxSprite(0, FlxG.height - 3).makeGraphic(2, 3, FlxColor.WHITE);
		add(progressBar);

		progressPip = new FlxSprite(0, FlxG.height - 5).makeGraphic(4, 7, FlxColor.WHITE);
		progressPip.alpha = 0.8;
		add(progressPip);

		progressLabel = new FlxText(0, FlxG.height - 16, SPLIT_X, "0 / 0", 10);
		progressLabel.setFormat(Paths.font("vcr.ttf"), 10, 0xFF333355, CENTER);
		add(progressLabel);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end
		if (creditsStuff.length == 0) pushDefaultCredits();

		new FlxTimer().start(0.4, function(_) {
			changeSelection();
			entranceDone = true;
		});

		FlxG.camera.fade(FlxColor.BLACK, 0.4, true);
		addTouchPad('LEFT_FULL', 'A_B_C');
		super.create();
	}

	function _makeRadialGlow(spr:FlxSprite, w:Int, h:Int, col:FlxColor, intensity:Float):Void
	{
		var bmp = new openfl.display.BitmapData(w, h, true, 0x00000000);
		var cx  = w * 0.5;
		var cy  = h * 0.5;
		var r   = Math.min(cx, cy);
		for (px in 0...w)
		for (py in 0...h)
		{
			var dx   = px - cx;
			var dy   = py - cy;
			var dist = Math.sqrt(dx * dx + dy * dy);
			if (dist >= r) continue;
			var t = 1.0 - dist / r;
			t = t * t;
			var a = Std.int(t * intensity * 255);
			if (a <= 0) continue;
			bmp.setPixel32(px, py, (a << 24) | (col.rgb));
		}
		spr.pixels = bmp;
	}

	function createAmbientParticles()
	{
		for (i in 0...22)
		{
			var size = Std.int(FlxG.random.float(1, 3));
			var p    = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			p.makeGraphic(size, size, FlxColor.WHITE);
			p.alpha      = FlxG.random.float(0.03, 0.10);
			p.velocity.y = FlxG.random.float(-8, -2);
			p.velocity.x = FlxG.random.float(-3, 3);
			add(p);
			ambientParticles.push(p);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		ambientTimer += elapsed;
		breathTimer  += elapsed * 1.5;

		if (ambientOrb1 != null) ambientOrb1.alpha = 0.55 + Math.sin(ambientTimer * 0.65) * 0.15;
		if (ambientOrb2 != null) ambientOrb2.alpha = 0.42 + Math.sin(ambientTimer * 0.85 + 1.2) * 0.12;
		if (ambientOrb3 != null) ambientOrb3.alpha = 0.30 + Math.sin(ambientTimer * 1.1  + 2.4) * 0.1;

		if (charIcon != null)
		{
			var bs = 1 + Math.sin(breathTimer) * 0.011;
			charIcon.scale.set(bs, bs);
		}

		if (charIconRing    != null) charIconRing.alpha    = 0.08 + Math.sin(ambientTimer * 2.2) * 0.06;
		if (topBarGlowStrip != null) topBarGlowStrip.alpha = 0.03 + Math.sin(ambientTimer * 1.4) * 0.02;

		updateAccentColor(elapsed);

		for (p in ambientParticles)
			if (p.y < -5) { p.y = FlxG.height + 5; p.x = FlxG.random.float(0, FlxG.width); }

		if (!entranceDone) return;

		#if desktop
		if (FlxG.mouse.wheel != 0)
		{
			if (!inLinkSelection) changeSelection(-FlxG.mouse.wheel);
			else                   changeLinkSelection(FlxG.mouse.wheel);
		}
		#end

		if (FlxG.keys.justPressed.CONTROL || mobilePadJustPressed("C"))
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			MusicBeatState.switchState(new ThanksCreditsState());
			return;
		}

		if (controls.BACK)
		{
			if (inLinkSelection)
			{
				toggleLinkSelection(false);
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			return;
		}

		if (!inLinkSelection)
		{
			if (controls.UI_UP_P)   changeSelection(-1);
			if (controls.UI_DOWN_P) changeSelection(1);

			if ((controls.UI_LEFT_P || controls.ACCEPT) && !isHeader(curSelected))
			{
				if (activeLinkIndices.length > 0)
				{
					toggleLinkSelection(true);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
					FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		else
		{
			if (controls.UI_UP_P || controls.UI_DOWN_P)
				changeLinkSelection(controls.UI_UP_P ? -1 : 1);

			if (controls.UI_RIGHT_P)
			{
				toggleLinkSelection(false);
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (controls.ACCEPT)
			{
				var linkToOpen = getSelectedLinkUrl();
				if (linkToOpen != null && linkToOpen.length > 4)
					CoolUtil.browserLoad(linkToOpen);
				else
				{
					FlxG.camera.shake(0.006, 0.4);
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
	}

	function updateAccentColor(elapsed:Float)
	{
		currentAccentColor = FlxColor.interpolate(currentAccentColor, intendedColor, 0.07);

		if (topBarTitle        != null) topBarTitle.color        = FlxColor.interpolate(topBarTitle.color, currentAccentColor, 0.09);
		if (topBarAccentLine   != null) topBarAccentLine.color   = currentAccentColor;
		if (leftAccentLine     != null) leftAccentLine.color     = currentAccentColor;
		if (leftPanelEdge      != null) leftPanelEdge.color      = currentAccentColor;
		if (leftPanelGlow      != null) leftPanelGlow.color      = currentAccentColor;
		if (sectionChip        != null) sectionChip.color        = currentAccentColor;
		if (sectionChipText    != null) sectionChipText.color    = currentAccentColor;
		if (charIconGlow       != null) charIconGlow.color       = currentAccentColor;
		if (charIconRing       != null) charIconRing.color       = currentAccentColor;
		if (progressBar        != null) progressBar.color        = currentAccentColor;
		if (progressPip        != null) progressPip.color        = currentAccentColor;
		if (linkSelectionBar   != null) linkSelectionBar.color   = currentAccentColor;
		if (linkSelectionBarGlow != null) linkSelectionBarGlow.color = currentAccentColor;
		if (topBarGlowStrip    != null) topBarGlowStrip.color    = currentAccentColor;
	}

	override function beatHit()
	{
		super.beatHit();

		if (charIcon != null)
		{
			FlxTween.cancelTweensOf(charIcon.scale);
			charIcon.scale.set(1.11, 1.11);
			FlxTween.tween(charIcon.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});
		}

		if (charIconGlow != null)
		{
			charIconGlow.alpha = 0.5;
			FlxTween.cancelTweensOf(charIconGlow);
			FlxTween.tween(charIconGlow, {alpha: 0.18}, 0.6, {ease: FlxEase.quartOut});
		}
	}
	function changeSelection(change:Int = 0)
	{
		if (creditsStuff.length == 0) return;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;
		if (curSelected < 0)                   curSelected = creditsStuff.length - 1;
		if (curSelected >= creditsStuff.length) curSelected = 0;

		if (isHeader(curSelected))
		{
			changeSelection(change >= 0 ? 1 : -1);
			return;
		}

		var data    = creditsStuff[curSelected];
		var nameStr = data[0];
		var fontSize = 48;
		if (nameStr.length > 12) fontSize = Std.int(Math.max(20, 48 * 12 / nameStr.length));

		leftName.text = nameStr;
		leftName.size = fontSize;
		leftName.x   = (SPLIT_X / 2) - (leftName.width / 2);

		leftNameShadow.text = nameStr;
		leftNameShadow.size = fontSize;
		leftNameShadow.x    = leftName.x + 3;
		leftNameShadow.y    = leftName.y + 3;

		var lineW = Std.int(Math.min(nameStr.length * 13 + 40, SPLIT_X - 40));
		leftAccentLine.makeGraphic(lineW, 3, FlxColor.WHITE);
		leftAccentLine.x = (SPLIT_X / 2) - (lineW / 2);
		leftAccentLine.y = leftName.y + fontSize + 8;
		leftAccentLineShadow.makeGraphic(lineW, 3, 0xFF000000);
		leftAccentLineShadow.x = leftAccentLine.x + 2;
		leftAccentLineShadow.y = leftAccentLine.y + 2;

		charName.text = nameStr;
		var centerRight:Float = SPLIT_X + (FlxG.width - SPLIT_X) / 2;
		charName.x = centerRight - (charName.width / 2);
		charName.y = FlxG.height * 0.57;

		charRole.text = data[2];

		var sectionName = "";
		for (i in 0...curSelected)
			if (creditsStuff[i].length <= 1 && creditsStuff[i][0] != null && creditsStuff[i][0].length > 0)
				sectionName = creditsStuff[i][0];

		charSectionLabel.text = sectionName.length > 0
			? '— $sectionName —'
			: Language.getPhrase('credits_team_label', '— TEAM —');
		sectionChipText.text  = sectionName.length > 0
			? sectionName.toUpperCase()
			: Language.getPhrase('credits_section_default', 'CREDITS');
		topBarSection.text    = sectionName.length > 0 ? sectionName : "";

		var totalReal = 0;
		var curReal   = 0;
		for (i in 0...creditsStuff.length)
		{
			if (!isHeader(i)) { totalReal++; if (i <= curSelected) curReal++; }
		}
		indexText.text = '$curReal / $totalReal';

		// Ghost ikon geçiş
		if (change != 0 && charIcon.graphic != null)
		{
			var ghost = new FlxSprite(charIcon.x, charIcon.y);
			ghost.loadGraphic(charIcon.graphic);
			ghost.scale.copyFrom(charIcon.scale);
			ghost.updateHitbox();
			ghost.offset.copyFrom(charIcon.offset);
			ghost.antialiasing = charIcon.antialiasing;
			ghost.alpha = 0.9;
			insert(members.indexOf(charIcon), ghost);
			var moveY = change == 1 ? -90 : 90;
			FlxTween.tween(ghost, {y: charIcon.y + moveY, alpha: 0}, 0.3, {
				ease: FlxEase.quartOut,
				onComplete: function(_) ghost.destroy()
			});
		}

		// İkon yükle
		var iconPath = 'credits/' + data[1];
		if (!Paths.fileExists('images/$iconPath.png', IMAGE))
			iconPath = 'credits/missing_icon';

		charIcon.loadGraphic(Paths.image(iconPath));
		var scl = charIcon.width > 200 ? 0.78 : 1.0;
		charIcon.setGraphicSize(Std.int(charIcon.width * 1.3 * scl));
		charIcon.updateHitbox();

		var targetY:Float = (FlxG.height * 0.34) - (charIcon.height / 2);
		charIcon.x = centerRight - (charIcon.width / 2);

		charIconBG.x = charIcon.x - (charIconBG.width  - charIcon.width)  / 2;
		charIconBG.y = charIcon.y - (charIconBG.height - charIcon.height) / 2;

		if (charIconGlow != null)
		{
			charIconGlow.setGraphicSize(Std.int(charIcon.width * 1.42), Std.int(charIcon.height * 1.42));
			charIconGlow.updateHitbox();
			charIconGlow.x = charIcon.x - (charIconGlow.width  - charIcon.width)  / 2;
			charIconGlow.y = charIcon.y - (charIconGlow.height - charIcon.height) / 2;
		}

		if (charIconRing != null)
		{
			charIconRing.setGraphicSize(Std.int(charIcon.width + 14), Std.int(charIcon.height + 14));
			charIconRing.updateHitbox();
			charIconRing.x = charIcon.x - 7;
			charIconRing.y = charIcon.y - 7;
		}

		if (change != 0)
		{
			FlxTween.cancelTweensOf(charIcon);
			charIcon.y     = targetY + (change == 1 ? 85 : -85);
			charIcon.alpha = 0;
			FlxTween.tween(charIcon, {y: targetY, alpha: 1}, 0.35, {ease: FlxEase.quartOut});
		}
		else
		{
			charIcon.y    = targetY;
			charIcon.alpha = 1;
		}

		// Renk
		var newColor:FlxColor = CoolUtil.colorFromString(data[4]);
		if (newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.cancelTweensOf(rightSideCover);
			FlxTween.color(bg,             0.7, bg.color,             intendedColor);
			FlxTween.color(rightSideCover, 0.7, rightSideCover.color, intendedColor);
		}

		parseAndCategorizeLinks(data[3]);
		updateLinkVisuals();
		updateProgressBar();
	}

	// ═══════════════════════════════════════════════════════
	// PROGRESS BAR
	// ═══════════════════════════════════════════════════════

	function updateProgressBar()
	{
		if (progressBar == null || creditsStuff.length == 0) return;

		var totalReal = 0;
		var curReal   = 0;
		for (i in 0...creditsStuff.length)
		{
			if (!isHeader(i)) { totalReal++; if (i <= curSelected) curReal++; }
		}
		if (totalReal == 0) return;

		var frac    = curReal / totalReal;
		var targetW = Math.max(2, SPLIT_X * frac);

		FlxTween.cancelTweensOf(progressBar);
		progressBar.makeGraphic(SPLIT_X, 3, FlxColor.WHITE);
		progressBar.color   = currentAccentColor;
		progressBar.scale.x = targetW / SPLIT_X;
		progressBar.x       = 0;

		progressPip.x     = targetW - 2;
		progressPip.color = currentAccentColor;
		progressLabel.text = '$curReal / $totalReal';
	}

	// ═══════════════════════════════════════════════════════
	// LINK KONTEYNERLERİ
	// ═══════════════════════════════════════════════════════

	function initializeLinkContainers()
	{
		var linkData = [
			{name: "youtube",    imageName: "yt",         fallbackColor: 0xFFFF0000},
			{name: "tiktok",     imageName: "tt",         fallbackColor: 0xFF010101},
			{name: "twitter",    imageName: "twitter",    fallbackColor: 0xFF1DA1F2},
			{name: "discord",    imageName: "discord",    fallbackColor: 0xFF5865F2},
			{name: "github",     imageName: "github",     fallbackColor: 0xFF333333},
			{name: "gamebanana", imageName: "gamebanana", fallbackColor: 0xFFE1A000},
			{name: "ko-fi",      imageName: "kofi",       fallbackColor: 0xFF29ABE0},
			{name: "bsky",       imageName: "bsky",       fallbackColor: 0xFF0085FF},
			{name: "instagram",  imageName: "instagram",  fallbackColor: 0xFFE1306C}
		];

		for (linkInfo in linkData)
		{
			var containerGlow = new FlxSprite(10, LINK_START_Y).makeGraphic(SPLIT_X - 20, LINK_H + 4, linkInfo.fallbackColor);
			containerGlow.alpha = 0;
			add(containerGlow);

			var container = FlxGradient.createGradientFlxSprite(
				SPLIT_X - 20, LINK_H,
				[0xCC0C0C1A, 0xEE060610],
				1, 0
			);
			container.alpha = 0;
			add(container);

			var accentStripe = new FlxSprite(10, LINK_START_Y).makeGraphic(4, LINK_H, linkInfo.fallbackColor);
			accentStripe.alpha = 0;
			add(accentStripe);

			var icon = new FlxSprite(0, 0);
			var iconPath = 'credits/images/${linkInfo.imageName}';
			if (Paths.fileExists('images/$iconPath.png', IMAGE))
				icon.loadGraphic(Paths.image(iconPath));
			else
				icon.makeGraphic(52, 52, linkInfo.fallbackColor);
			icon.setGraphicSize(52, 52);
			icon.updateHitbox();
			icon.alpha = 0;
			add(icon);

			var text = new FlxText(0, 0, SPLIT_X - 100, "@handle", 22);
			text.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 1.5;
			text.alpha = 0;
			add(text);

			var subText = new FlxText(0, 0, SPLIT_X - 100, linkInfo.name.toUpperCase(), 11);
			subText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF777788, LEFT);
			subText.alpha = 0;
			add(subText);

			linkContainers.push({
				name:          linkInfo.name,
				container:     container,
				containerGlow: containerGlow,
				accentStripe:  accentStripe,
				icon:          icon,
				text:          text,
				subText:       subText,
				url:           ""
			});
		}
	}

	function updateLinkVisuals()
	{
		for (lc in linkContainers)
		{
			lc.container.visible     = false;
			lc.containerGlow.visible = false;
			lc.accentStripe.visible  = false;
			lc.icon.visible          = false;
			lc.text.visible          = false;
			lc.subText.visible       = false;
		}

		noLinksText.alpha = activeLinkIndices.length == 0 ? 0.5 : 0;

		var marginX = 10;
		var spacing = LINK_H + LINK_GAP;

		for (idx in 0...activeLinkIndices.length)
		{
			var containerIdx = activeLinkIndices[idx];
			var lc           = linkContainers[containerIdx];
			var currentY     = LINK_START_Y + idx * spacing;
			var isSelected   = inLinkSelection && (idx == curLinkSelected);

			lc.container.visible     = true;
			lc.containerGlow.visible = true;
			lc.accentStripe.visible  = true;
			lc.icon.visible          = true;
			lc.text.visible          = true;
			lc.subText.visible       = true;

			lc.container.setPosition(marginX, currentY);
			lc.containerGlow.setPosition(marginX - 1, currentY - 1);
			lc.accentStripe.setPosition(marginX, currentY);
			lc.icon.setPosition(marginX + 12, currentY + (LINK_H - 52) / 2);
			lc.text.setPosition(marginX + 70, currentY + 11);
			lc.subText.setPosition(marginX + 70, currentY + 38);

			FlxTween.cancelTweensOf(lc.container);
			FlxTween.cancelTweensOf(lc.container.scale);
			FlxTween.cancelTweensOf(lc.containerGlow);

			if (isSelected)
			{
				FlxTween.tween(lc.container,     {alpha: 1.0},  0.18);
				FlxTween.tween(lc.containerGlow, {alpha: 0.20}, 0.18);
				FlxTween.tween(lc.container.scale, {x: 1.04, y: 1.04}, 0.22, {ease: FlxEase.quartOut});
				lc.accentStripe.alpha = 1.0;
				lc.accentStripe.color = currentAccentColor;
				lc.icon.alpha         = 1.0;
				lc.text.color         = FlxColor.WHITE;
				lc.text.size          = 23;
				lc.subText.color      = currentAccentColor;
				lc.subText.alpha      = 1.0;

				linkSelectionBar.setPosition(marginX, currentY);
				linkSelectionBarGlow.setPosition(marginX - 1, currentY - 1);
				linkSelectionBar.alpha    = 0.06;
				linkSelectionBarGlow.alpha = 0.10;
			}
			else if (inLinkSelection)
			{
				FlxTween.tween(lc.container,     {alpha: 0.28}, 0.18);
				FlxTween.tween(lc.containerGlow, {alpha: 0},    0.18);
				FlxTween.tween(lc.container.scale, {x: 1, y: 1}, 0.22, {ease: FlxEase.quartOut});
				lc.accentStripe.alpha = 0.18;
				lc.icon.alpha         = 0.38;
				lc.text.color         = 0xFF555566;
				lc.text.size          = 21;
				lc.subText.color      = 0xFF444455;
				lc.subText.alpha      = 0.5;
			}
			else
			{
				FlxTween.tween(lc.container,     {alpha: 0.80}, 0.18);
				FlxTween.tween(lc.containerGlow, {alpha: 0},    0.18);
				FlxTween.tween(lc.container.scale, {x: 1, y: 1}, 0.22, {ease: FlxEase.quartOut});
				lc.accentStripe.alpha = 0.68;
				lc.icon.alpha         = 0.90;
				lc.text.color         = FlxColor.WHITE;
				lc.text.size          = 22;
				lc.subText.color      = 0xFF777788;
				lc.subText.alpha      = 0.85;
			}

			lc.text.text    = extractHandle(lc.url, lc.name);
			lc.subText.text = lc.name.toUpperCase();
		}

		if (!inLinkSelection)
		{
			linkSelectionBar.alpha    = 0;
			linkSelectionBarGlow.alpha = 0;
		}

		helpText.text = inLinkSelection
			? Language.getPhrase('credits_help_links',
				'ENTER  Open Link   •   → / ESC  Back\nCTRL  Watch Credits Flow')
			: Language.getPhrase('credits_help_normal',
				'▲ ▼  Select   •   ENTER / ←  Links\nCTRL  Watch Credits Flow');
	}

	// ═══════════════════════════════════════════════════════
	// YARDIMCI FONKSİYONLAR
	// ═══════════════════════════════════════════════════════

	function parseAndCategorizeLinks(rawLinks:String)
	{
		for (link in linkContainers) link.url = "";
		activeLinkIndices = [];
		if (rawLinks == null || rawLinks.length == 0) return;

		for (linkUrl in rawLinks.split('|'))
		{
			if (linkUrl == null || linkUrl.length < 5) continue;
			var domain = extractDomainFromUrl(linkUrl);
			for (i in 0...linkContainers.length)
			{
				if (linkContainers[i].name == domain)
				{
					linkContainers[i].url = linkUrl;
					activeLinkIndices.push(i);
					break;
				}
			}
		}
		if (activeLinkIndices.length > 0) curLinkSelected = 0;
	}

	function extractDomainFromUrl(url:String):String
	{
		if (url.indexOf("youtube.com")    != -1 || url.indexOf("youtu.be")    != -1) return "youtube";
		if (url.indexOf("tiktok.com")     != -1)                                     return "tiktok";
		if (url.indexOf("twitter.com")    != -1 || url.indexOf("x.com")       != -1) return "twitter";
		if (url.indexOf("discord.gg")     != -1 || url.indexOf("discord.com") != -1) return "discord";
		if (url.indexOf("github.com")     != -1)                                     return "github";
		if (url.indexOf("gamebanana.com") != -1)                                     return "gamebanana";
		if (url.indexOf("ko-fi.com")      != -1)                                     return "ko-fi";
		if (url.indexOf("bsky.app")       != -1)                                     return "bsky";
		if (url.indexOf("instagram.com")  != -1)                                     return "instagram";
		return "unknown";
	}

	function toggleLinkSelection(entering:Bool)
	{
		inLinkSelection = entering;
		if (entering && activeLinkIndices.length > 0) curLinkSelected = 0;
		updateLinkVisuals();
	}

	function changeLinkSelection(change:Int)
	{
		if (activeLinkIndices.length == 0) return;
		curLinkSelected += change;
		if (curLinkSelected >= activeLinkIndices.length) curLinkSelected = 0;
		if (curLinkSelected < 0) curLinkSelected = activeLinkIndices.length - 1;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		updateLinkVisuals();
	}

	function getSelectedLinkUrl():String
	{
		if (activeLinkIndices.length == 0 || curLinkSelected >= activeLinkIndices.length) return "";
		return linkContainers[activeLinkIndices[curLinkSelected]].url;
	}

	function extractHandle(url:String, defaultName:String):String
	{
		if (url == null || url.length < 5) return Language.getPhrase('credits_no_link', 'No Link');
		var parts  = url.split('/');
		var handle = parts[parts.length - 1];
		if (handle == "") handle = parts[parts.length - 2];
		return (handle.startsWith('@') ? "" : "@") + handle;
	}

	function isHeader(num:Int):Bool
	{
		return creditsStuff[num].length <= 1;
	}


	function pushDefaultCredits()
	{
		creditsStuff = [
			[Language.getPhrase('credits_sec_peu', 'Psych Engine Ultra')],
			['SametGkTe',       'gkte',          Language.getPhrase('credits_role_samet',   'Header Of And Creator Of Psych Engine Ultra'),                       'https://tiktok.com/@gktegameplay',           'FFE7C0'],
			['ArkoseLabs', 'arkoselabs', Language.getPhrase('credits_role_arkose', 'Mobile Porter & Co-Owner of Psych Ultra'), 'https://youtube.com/@arkoselabsofficial', 'FFE7C0'],
			['Nexus',           'nex',            Language.getPhrase('credits_role_nexus',   'Translator Of Psych Engine Ultra'),                                  'https://tiktok.com/@skynexus.0.03',          'FFE7C0'],
			[''],
			[Language.getPhrase('spanishteam_peu', 'Spanish')],
			['emi3',           'puta',            Language.getPhrase('credits_role_emi3',   'Spanish Ratings, İmages etc.'),                              'https://gamebanana.com/members/1709917',          '6FA8DC'],
			[''],
			[Language.getPhrase('credits_sec_psychteam', 'Psych Engine Team')],
			['Shadow Mario',    'shadowmario',    Language.getPhrase('credits_role_shadow',  'Main Programmer and Head of Psych Engine'),                          'https://ko-fi.com/shadowmario',              '444444'],
			['Riveren',         'riveren',        Language.getPhrase('credits_role_riveren', 'Main Artist/Animator of Psych Engine'),                              'https://x.com/riverennn',                    '14967B'],
			[''],
			[Language.getPhrase('credits_sec_former', 'Former Engine Members')],
			['bb-panzu',        'bb',             Language.getPhrase('credits_role_bb',      'Ex-Programmer of Psych Engine'),                                     'https://x.com/bbsub3',                       '3E813A'],
			[''],
			[Language.getPhrase('credits_sec_contrib', 'Engine Contributors')],
			['crowplexus',      'crowplexus',     Language.getPhrase('credits_role_crow',    'Linux Support, HScript Iris, Input System v3, and Other PRs'),       'https://twitter.com/IamMorwen',              'CFCFCF'],
			['Kamizeta',        'kamizeta',       Language.getPhrase('credits_role_kami',    'Creator of Pessy, Psych Engine\'s mascot.'),                         'https://www.instagram.com/cewweey/',         'D21C11'],
			['MaxNeton',        'maxneton',       Language.getPhrase('credits_role_maxneton','Loading Screen Easter Egg Artist/Animator.'),                        'https://bsky.app/profile/maxneton.bsky.social','3C2E4E'],
			['Keoiki',          'keoiki',         Language.getPhrase('credits_role_keoiki',  'Note Splash Animations and Latin Alphabet'),                          'https://x.com/Keoiki_',                      'D2D2D2'],
			['SqirraRNG',       'sqirra',         Language.getPhrase('credits_role_sqirra',  'Crash Handler and Base code for\nChart Editor\'s Waveform'),         'https://x.com/gedehari',                     'E1843A'],
			['EliteMasterEric', 'mastereric',     Language.getPhrase('credits_role_eric',    'Runtime Shaders support and Other PRs'),                             'https://x.com/EliteMasterEric',              'FFBD40'],
			['MAJigsaw77',      'majigsaw',       Language.getPhrase('credits_role_maj',     '.MP4 Video Loader Library (hxvlc)'),                                 'https://x.com/MAJigsaw77',                   '5F5F5F'],
			['iFlicky',         'flicky',         Language.getPhrase('credits_role_flicky',  'Composer of Psync and Tea Time\nAnd some sound effects'),            'https://x.com/flicky_i',                     '9E29CF'],
			['KadeDev',         'kade',           Language.getPhrase('credits_role_kade',    'Fixed some issues on Chart Editor and Other PRs'),                  'https://x.com/kade0912',                     '64A250'],
			['superpowers04',   'superpowers04',  Language.getPhrase('credits_role_super',   'LUA JIT Fork'),                                                      'https://x.com/superpowers04',                'B957ED'],
			['CheemsAndFriends','cheems',         Language.getPhrase('credits_role_cheems',  'Creator of FlxAnimate'),                                             'https://x.com/CheemsnFriendos',              'E1E1E1'],
			[''],
			[Language.getPhrase('credits_sec_funkin', "Funkin' Crew")],
			['ninjamuffin99',   'ninjamuffin99',  Language.getPhrase('credits_role_ninja',   "Programmer of Friday Night Funkin'"),                                'https://x.com/ninja_muffin99',               'CF2D2D'],
			['PhantomArcade',   'phantomarcade',  Language.getPhrase('credits_role_phantom', "Animator of Friday Night Funkin'"),                                  'https://x.com/PhantomArcade3K',              'FADC45'],
			['evilsk8r',        'evilsk8r',       Language.getPhrase('credits_role_evil',    "Artist of Friday Night Funkin'"),                                    'https://x.com/evilsk8r',                     '5ABD4B'],
			['kawaisprite',     'kawaisprite',    Language.getPhrase('credits_role_kawai',   "Composer of Friday Night Funkin'"),                                  'https://x.com/kawaisprite',                  '378FC7'],
			[''],
			[Language.getPhrase('credits_sec_discord', 'Psych Engine Discord')],
			[Language.getPhrase('credits_role_discord', 'Join the Psych Ward!'), 'discord', '', 'https://discord.gg/2ka77eMXDv', '5165F6']
		];
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED
			(FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) ||
			#end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end
}
