package states;

import flixel.FlxObject;
import flixel.util.FlxSort;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxMath;
import objects.Alphabet;
import objects.Bar;
import backend.Achievements;
import backend.Language;

#if ACHIEVEMENTS_ALLOWED
class AchievementsMenuState extends MusicBeatState
{
	public var curSelected:Int = 0;
	public var options:Array<Dynamic> = [];

	var bgBase:FlxSprite;
	var bgGradient:FlxSprite;
	var gridBG:FlxBackdrop;
	var bgOrbs:Array<FlxSprite> = [];
	var floatingShapes:Array<FlxSprite> = [];
	var bgVignette:FlxSprite;

	var headerPanel:FlxSprite;
	var headerGlow:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var breadcrumbText:FlxText;
	var statsHeaderText:FlxText;

	var leftPanel:FlxSprite;
	var leftPanelGlow:FlxSprite;
	var leftPanelBorder:FlxSprite;
	var achievementItems:FlxTypedGroup<AchievementItem>;
	var selectionBar:FlxSprite;
	var selectionBarGlow:FlxSprite;

	var rightPanel:FlxSprite;
	var rightPanelGlow:FlxSprite;
	var rightPanelBorder:FlxSprite;
	var showcaseIcon:FlxSprite;
	var showcaseLockIcon:FlxSprite;
	var showcaseGlow:FlxSprite;
	var nameText:FlxText;
	var descPanel:FlxSprite;
	var descPanelGlow:FlxSprite;
	var descText:FlxText;
	var progressPanel:FlxSprite;
	var progressBar:Bar;
	var progressTxt:FlxText;
	var progressLabel:FlxText;
	var unlockedBadge:FlxSprite;
	var unlockedBadgeText:FlxText;
	var lockedOverlay:FlxSprite;

	var statsPanel:FlxSprite;
	var statsPanelGlow:FlxSprite;
	var statsTotalText:FlxText;
	var statsUnlockedText:FlxText;
	var statsPercentText:FlxText;
	var statsProgressBar:Bar;

	var controlHintsPanel:FlxSprite;
	var controlHintsText:FlxText;

	var camFollow:FlxObject;
	var cameraTween:FlxTween = null;
	var showcaseIconTween:FlxTween = null;

	var animTimer:Float = 0;
	var pulseTimer:Float = 0;
	var waveTimer:Float = 0;
	var floatTimer:Float = 0;
	var glowTimer:Float = 0;

	static inline var LEFT_PANEL_W:Int  = 430;
	static inline var HEADER_H:Int      = 110;
	static inline var ITEM_H:Int        = 100;
	static inline var ITEM_SPACING:Int  = 8;
	static inline var ACCENT_COLOR:Int  = 0xFFFFC400;
	static inline var ACCENT_COLOR2:Int = 0xFFEC4899;

	public var barTween:FlxTween = null;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(Language.getPhrase('achievements_rpc', 'Achievements'), null);
		#end

		var totalUnlocked:Int = 0;
		for (achievement => data in Achievements.achievements)
		{
			var unlocked:Bool = Achievements.isUnlocked(achievement);
			if (data.hidden != true || unlocked)
				options.push(makeAchievement(achievement, data, unlocked, data.mod));
			if (unlocked) totalUnlocked++;
		}
		options.sort(function(a, b) return sortByID(a, b));

		createBackgroundSystem();
		createLeftPanel();
		createHeader(totalUnlocked);
		createRightPanel();
		createStatsPanel(totalUnlocked);
		createControlHints();
		_changeSelection();
		
		addTouchPad('LEFT_FULL', 'B_C');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.scrollFactor.set(0, 1);
		add(camFollow);
		FlxG.camera.follow(camFollow, null, 0.1);

		playEntranceAnimation();
		super.create();
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'B_C');
	}

	function createBackgroundSystem()
	{
		bgBase = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF080812);
		bgBase.scrollFactor.set(0, 0);
		add(bgBase);

		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0xFF1a1a2e, 0xFF16213e, 0xFF0f2a40, 0xFF080812],
			1, 135
		);
		bgGradient.scrollFactor.set(0, 0);
		bgGradient.alpha = 0.9;
		add(bgGradient);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(40, 40, 80, 80, true, 0x0AFFFFFF, 0x0));
		gridBG.velocity.set(8, 6);
		gridBG.alpha = 0.12;
		gridBG.scrollFactor.set(0, 0);
		add(gridBG);

		for (i in 0...8)
		{
			var orb = new FlxSprite(
				FlxG.random.float(LEFT_PANEL_W, FlxG.width),
				FlxG.random.float(HEADER_H, FlxG.height - 50)
			);
			orb.makeGraphic(
				Std.int(80 + FlxG.random.float(0, 100)),
				Std.int(80 + FlxG.random.float(0, 100)),
				ACCENT_COLOR
			);
			orb.blend = ADD;
			orb.alpha = 0.04 + FlxG.random.float(0, 0.04);
			orb.scrollFactor.set(0.02, 0.02);
			orb.ID = i;
			add(orb);
			bgOrbs.push(orb);
		}

		for (i in 0...12)
		{
			var shape = new FlxSprite(
				FlxG.random.float(LEFT_PANEL_W, FlxG.width),
				FlxG.random.float(0, FlxG.height)
			);
			shape.makeGraphic(
				Std.int(15 + FlxG.random.float(0, 25)),
				Std.int(15 + FlxG.random.float(0, 25)),
				FlxColor.WHITE
			);
			shape.blend = ADD;
			shape.alpha = 0.05 + FlxG.random.float(0, 0.08);
			shape.scrollFactor.set(0.03 + FlxG.random.float(0, 0.05), 0.03 + FlxG.random.float(0, 0.05));
			shape.ID = i;
			add(shape);
			floatingShapes.push(shape);
		}

		bgVignette = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0x00000000, 0x00000000, 0x55000000],
			1, 0, true
		);
		bgVignette.scrollFactor.set(0, 0);
		add(bgVignette);
	}

	function createHeader(totalUnlocked:Int)
	{
		headerPanel = new FlxSprite(0, -HEADER_H).makeGraphic(FlxG.width, HEADER_H, 0xEE000000);
		headerPanel.scrollFactor.set(0, 0);
		add(headerPanel);

		headerGlow = new FlxSprite(0, HEADER_H - 4).makeGraphic(FlxG.width, 4, ACCENT_COLOR);
		headerGlow.blend = ADD;
		headerGlow.alpha = 0.7;
		headerGlow.scrollFactor.set(0, 0);
		add(headerGlow);

		var titleIcon = new FlxText(35, 15, 60, "🏆", 40);
		titleIcon.scrollFactor.set(0, 0);
		add(titleIcon);

		titleText = new FlxText(88, 16, FlxG.width - 300,
			Language.getPhrase('achievements_title', 'ACHIEVEMENTS'), 42);
		titleText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF8D4800);
		titleText.borderSize = 3;
		titleText.scrollFactor.set(0, 0);
		titleText.alpha = 0;
		add(titleText);

		subtitleText = new FlxText(88, 62, FlxG.width - 300,
			Language.getPhrase('achievements_subtitle', 'Check your earned achievements!'), 18);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFBBBBBB, LEFT);
		subtitleText.scrollFactor.set(0, 0);
		subtitleText.alpha = 0;
		add(subtitleText);

		breadcrumbText = new FlxText(88, 86, FlxG.width - 300,
			Language.getPhrase('achievements_breadcrumb', 'Main Menu > Achievements'), 12);
		breadcrumbText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		breadcrumbText.scrollFactor.set(0, 0);
		breadcrumbText.alpha = 0;
		add(breadcrumbText);

		var totalCount = options.length > 0 ? options.length : 1;
		var pct = Math.floor((totalUnlocked / totalCount) * 100);
		statsHeaderText = new FlxText(FlxG.width - 280, 20, 260,
			'$totalUnlocked / $totalCount ' + Language.getPhrase('achievements_completed', 'Completed') + ' ($pct%)', 18);
		statsHeaderText.setFormat(Paths.font("vcr.ttf"), 18, ACCENT_COLOR, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statsHeaderText.borderSize = 1.5;
		statsHeaderText.scrollFactor.set(0, 0);
		statsHeaderText.alpha = 0;
		add(statsHeaderText);
	}

	function createLeftPanel()
	{
		leftPanelGlow = new FlxSprite(0, 0).makeGraphic(LEFT_PANEL_W + 6, FlxG.height, ACCENT_COLOR);
		leftPanelGlow.alpha = 0.08;
		leftPanelGlow.scrollFactor.set(0, 0);
		add(leftPanelGlow);

		leftPanel = FlxGradient.createGradientFlxSprite(
			LEFT_PANEL_W, FlxG.height,
			[0xDD0a0a12, 0xEE050508, 0xFF020204],
			1, 0
		);
		leftPanel.scrollFactor.set(0, 0);
		add(leftPanel);

		leftPanelBorder = new FlxSprite(LEFT_PANEL_W - 3, 0).makeGraphic(3, FlxG.height, ACCENT_COLOR);
		leftPanelBorder.alpha = 0.5;
		leftPanelBorder.scrollFactor.set(0, 0);
		add(leftPanelBorder);

		selectionBarGlow = new FlxSprite(0, HEADER_H).makeGraphic(LEFT_PANEL_W, ITEM_H + ITEM_SPACING, ACCENT_COLOR);
		selectionBarGlow.alpha = 0.08;
		selectionBarGlow.scrollFactor.set(0, 1);
		add(selectionBarGlow);

		selectionBar = new FlxSprite(0, HEADER_H).makeGraphic(5, ITEM_H, ACCENT_COLOR);
		selectionBar.scrollFactor.set(0, 1);
		add(selectionBar);

		achievementItems = new FlxTypedGroup<AchievementItem>();
		add(achievementItems);

		for (i in 0...options.length)
		{
			var item = new AchievementItem(8, HEADER_H + 8 + i * (ITEM_H + ITEM_SPACING), options[i]);
			item.targetY = i;
			item.ID = i;
			item.scrollFactor.set(0, 1);
			item.alpha = 0;
			achievementItems.add(item);
		}
	}

	function createRightPanel()
	{
		var rx:Float = LEFT_PANEL_W + 20;
		var panelW:Float = FlxG.width - LEFT_PANEL_W - 40;

		rightPanelGlow = new FlxSprite(rx - 4, HEADER_H + 16).makeGraphic(Std.int(panelW + 8), Std.int(FlxG.height - HEADER_H - 70), ACCENT_COLOR);
		rightPanelGlow.alpha = 0.06;
		rightPanelGlow.scrollFactor.set(0, 0);
		add(rightPanelGlow);

		rightPanel = FlxGradient.createGradientFlxSprite(
			Std.int(panelW), Std.int(FlxG.height - HEADER_H - 70),
			[0xBB0a0a12, 0xCC050508],
			1, 0
		);
		rightPanel.x = rx;
		rightPanel.y = HEADER_H + 16;
		rightPanel.scrollFactor.set(0, 0);
		add(rightPanel);

		rightPanelBorder = new FlxSprite(rx, HEADER_H + 16).makeGraphic(Std.int(panelW), 3, ACCENT_COLOR);
		rightPanelBorder.alpha = 0.6;
		rightPanelBorder.scrollFactor.set(0, 0);
		add(rightPanelBorder);

		showcaseGlow = new FlxSprite(rx + panelW / 2 - 150, HEADER_H + 80);
		showcaseGlow.makeGraphic(300, 300, ACCENT_COLOR);
		showcaseGlow.blend = ADD;
		showcaseGlow.alpha = 0;
		showcaseGlow.scrollFactor.set(0, 0);
		add(showcaseGlow);

		lockedOverlay = new FlxSprite(rx, HEADER_H + 16).makeGraphic(Std.int(panelW), Std.int(FlxG.height - HEADER_H - 70), 0xFF000000);
		lockedOverlay.alpha = 0;
		lockedOverlay.scrollFactor.set(0, 0);
		add(lockedOverlay);

		showcaseIcon = new FlxSprite();
		showcaseIcon.antialiasing = ClientPrefs.data.antialiasing;
		showcaseIcon.scrollFactor.set(0, 0);
		add(showcaseIcon);

		showcaseLockIcon = new FlxText(0, 0, 100, "🔒", 72);
		showcaseLockIcon.scrollFactor.set(0, 0);
		showcaseLockIcon.alpha = 0;
		add(showcaseLockIcon);

		nameText = new FlxText(rx + 20, HEADER_H + 30, panelW - 40, "", 36);
		nameText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 3;
		nameText.scrollFactor.set(0, 0);
		add(nameText);

		var descY:Float = FlxG.height - 220;
		descPanelGlow = new FlxSprite(rx - 2, descY - 2).makeGraphic(Std.int(panelW + 4), 94, ACCENT_COLOR);
		descPanelGlow.alpha = 0.12;
		descPanelGlow.scrollFactor.set(0, 0);
		add(descPanelGlow);

		descPanel = new FlxSprite(rx, descY).makeGraphic(Std.int(panelW), 90, 0xAA000000);
		descPanel.scrollFactor.set(0, 0);
		add(descPanel);

		var descTopLine = new FlxSprite(rx, descY).makeGraphic(Std.int(panelW), 3, ACCENT_COLOR);
		descTopLine.alpha = 0.5;
		descTopLine.scrollFactor.set(0, 0);
		add(descTopLine);

		descText = new FlxText(rx + 20, descY + 12, panelW - 40, "", 18);
		descText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFCCCCCC, CENTER);
		descText.scrollFactor.set(0, 0);
		add(descText);

		var lockMsg = new FlxText(rx + 20, descY + 52, panelW - 40,
			Language.getPhrase('achievement_lock_hint', 'Meet the conditions to unlock this achievement!'), 13);
		lockMsg.setFormat(Paths.font("vcr.ttf"), 13, 0xFF888888, CENTER);
		lockMsg.scrollFactor.set(0, 0);
		lockMsg.alpha = 0;
		add(lockMsg);

		progressPanel = new FlxSprite(rx, FlxG.height - 125).makeGraphic(Std.int(panelW), 55, 0xAA000000);
		progressPanel.scrollFactor.set(0, 0);
		add(progressPanel);

		progressLabel = new FlxText(rx + 20, FlxG.height - 122, 150,
			Language.getPhrase('achievements_progress', 'PROGRESS'), 12);
		progressLabel.setFormat(Paths.font("vcr.ttf"), 12, ACCENT_COLOR, LEFT);
		progressLabel.scrollFactor.set(0, 0);
		add(progressLabel);

		progressTxt = new FlxText(FlxG.width - 180, FlxG.height - 122, 150, "", 12);
		progressTxt.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, RIGHT);
		progressTxt.scrollFactor.set(0, 0);
		add(progressTxt);

		progressBar = new Bar(
			rx + 20, FlxG.height - 106,
			'healthBar',
			function() return options.length > 0 ? options[curSelected].curProgress : 0,
			0, 1
		);
		progressBar.setGraphicSize(Std.int(panelW - 40), 16);
		progressBar.updateHitbox();
		progressBar.scrollFactor.set(0, 0);
		progressBar.enabled = false;
		progressBar.leftBar.color  = ACCENT_COLOR;
		progressBar.rightBar.color = 0xFF222233;
		add(progressBar);

		unlockedBadge = new FlxSprite(rx + panelW - 130, HEADER_H + 22).makeGraphic(115, 28, 0xFF10B981);
		unlockedBadge.alpha = 0;
		unlockedBadge.scrollFactor.set(0, 0);
		add(unlockedBadge);

		unlockedBadgeText = new FlxText(rx + panelW - 128, HEADER_H + 26, 111,
			Language.getPhrase('achievement_done_badge', '✓ COMPLETED'), 14);
		unlockedBadgeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		unlockedBadgeText.alpha = 0;
		unlockedBadgeText.scrollFactor.set(0, 0);
		add(unlockedBadgeText);
	}

	function createStatsPanel(totalUnlocked:Int)
	{
		var total  = options.length > 0 ? options.length : 1;
		var pct    = totalUnlocked / total;
		var pctInt = Math.floor(pct * 100);

		var sx:Float    = LEFT_PANEL_W + 20;
		var panelW:Float = FlxG.width - LEFT_PANEL_W - 40;
		var sy:Float    = FlxG.height - 65;

		statsPanelGlow = new FlxSprite(sx - 2, sy - 2).makeGraphic(Std.int(panelW + 4), 52, ACCENT_COLOR2);
		statsPanelGlow.alpha = 0.1;
		statsPanelGlow.scrollFactor.set(0, 0);
		add(statsPanelGlow);

		statsPanel = new FlxSprite(sx, sy).makeGraphic(Std.int(panelW), 48, 0xAA000000);
		statsPanel.scrollFactor.set(0, 0);
		add(statsPanel);

		var statsBorder = new FlxSprite(sx, sy).makeGraphic(Std.int(panelW), 3, ACCENT_COLOR2);
		statsBorder.alpha = 0.5;
		statsBorder.scrollFactor.set(0, 0);
		add(statsBorder);

		statsTotalText = new FlxText(sx + 15, sy + 10, 200,
			'📊 ' + Language.getPhrase('achievements_total', 'Total') + ': $total', 16);
		statsTotalText.setFormat(Paths.font("vcr.ttf"), 16, 0xFFCCCCCC, LEFT);
		statsTotalText.scrollFactor.set(0, 0);
		add(statsTotalText);

		statsUnlockedText = new FlxText(sx + 220, sy + 10, 200,
			'🏆 ' + Language.getPhrase('achievements_unlocked', 'Unlocked') + ': $totalUnlocked', 16);
		statsUnlockedText.setFormat(Paths.font("vcr.ttf"), 16, ACCENT_COLOR, LEFT);
		statsUnlockedText.scrollFactor.set(0, 0);
		add(statsUnlockedText);

		statsPercentText = new FlxText(sx + panelW - 180, sy + 10, 165,
			Language.getPhrase('achievements_completion', 'Completion') + ': $pctInt%', 16);
		statsPercentText.setFormat(Paths.font("vcr.ttf"), 16, ACCENT_COLOR2, RIGHT);
		statsPercentText.scrollFactor.set(0, 0);
		add(statsPercentText);
	}

	function createControlHints()
	{
		controlHintsPanel = new FlxSprite(0, FlxG.height - 28).makeGraphic(LEFT_PANEL_W, 28, 0xAA000000);
		controlHintsPanel.scrollFactor.set(0, 0);
		add(controlHintsPanel);

		controlHintsText = new FlxText(0, FlxG.height - 22, LEFT_PANEL_W,
			Language.getPhrase('achievements_hints', '↑↓: Navigate  |  DEL: Reset  |  ESC: Back'), 12);
		controlHintsText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, CENTER);
		controlHintsText.scrollFactor.set(0, 0);
		add(controlHintsText);
	}

	function playEntranceAnimation()
	{
		FlxTween.tween(headerPanel,    {y: 0},           0.7, {ease: FlxEase.expoOut,  startDelay: 0.05});
		FlxTween.tween(headerGlow,     {y: HEADER_H - 4},0.7, {ease: FlxEase.expoOut,  startDelay: 0.05});
		FlxTween.tween(titleText,      {alpha: 1},        0.6, {ease: FlxEase.quartOut, startDelay: 0.25});
		FlxTween.tween(subtitleText,   {alpha: 0.85},     0.6, {ease: FlxEase.quartOut, startDelay: 0.35});
		FlxTween.tween(breadcrumbText, {alpha: 0.7},      0.6, {ease: FlxEase.quartOut, startDelay: 0.45});
		FlxTween.tween(statsHeaderText,{alpha: 1},        0.6, {ease: FlxEase.quartOut, startDelay: 0.5});

		leftPanel.x      = -LEFT_PANEL_W;
		leftPanelGlow.x  = -LEFT_PANEL_W;
		leftPanelBorder.x = -10;
		FlxTween.tween(leftPanel,       {x: 0},              0.7, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(leftPanelGlow,   {x: 0},              0.7, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(leftPanelBorder, {x: LEFT_PANEL_W - 3},0.7,{ease: FlxEase.expoOut, startDelay: 0.15});

		for (i in 0...achievementItems.members.length)
		{
			var item  = achievementItems.members[i];
			var delay:Float = 0.3 + i * 0.04;
			if (delay > 1.2) delay = 1.2;
			FlxTween.tween(item, {alpha: i == curSelected ? 1 : 0.6}, 0.5, {ease: FlxEase.quartOut, startDelay: delay});
		}

		rightPanel.x      = FlxG.width;
		rightPanelGlow.x  = FlxG.width;
		rightPanelBorder.x = FlxG.width;
		FlxTween.tween(rightPanel,       {x: LEFT_PANEL_W + 20}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.2});
		FlxTween.tween(rightPanelGlow,   {x: LEFT_PANEL_W + 16}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.2});
		FlxTween.tween(rightPanelBorder, {x: LEFT_PANEL_W + 20}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.25});
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;
		_changeSelection();
	}

	public function _changeSelection()
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		var option      = options[curSelected];
		var hasProgress = option.maxProgress > 0;

		var graphic    = null;
		var hasAntialias = ClientPrefs.data.antialiasing;
		if (option.unlocked)
		{
			#if MODS_ALLOWED Mods.currentModDirectory = option.mod; #end
			var image:String = 'achievements/' + option.name;
			if (Paths.fileExists('images/$image-pixel.png', IMAGE))
			{
				graphic      = Paths.image('$image-pixel');
				hasAntialias = false;
			}
			else
				graphic = Paths.image(image);
			if (graphic == null) graphic = Paths.image('unknownMod');
		}
		else
			graphic = Paths.image('achievements/lockedachievement');

		showcaseIcon.loadGraphic(graphic);
		showcaseIcon.antialiasing = hasAntialias;
		showcaseIcon.setGraphicSize(Std.int(showcaseIcon.width * 1.6));
		showcaseIcon.updateHitbox();

		var rx:Float     = LEFT_PANEL_W + 20;
		var panelW:Float = FlxG.width - LEFT_PANEL_W - 40;
		var centerX:Float = rx + panelW / 2;
		showcaseIcon.setPosition(centerX - showcaseIcon.width / 2, HEADER_H + 70);
		showcaseIcon.alpha = option.unlocked ? 1 : 0.35;

		showcaseLockIcon.alpha = option.unlocked ? 0 : 1;
		showcaseLockIcon.x = centerX - 50;
		showcaseLockIcon.y = HEADER_H + 80;

		if (showcaseIconTween != null) showcaseIconTween.cancel();
		showcaseIcon.scale.set(0.7, 0.7);
		showcaseIconTween = FlxTween.tween(showcaseIcon.scale, {x: 1, y: 1}, 0.45, {ease: FlxEase.elasticOut});

		showcaseGlow.color = option.unlocked ? ACCENT_COLOR : 0xFF555555;
		FlxTween.cancelTweensOf(showcaseGlow);
		FlxTween.tween(showcaseGlow, {alpha: option.unlocked ? 0.08 : 0.03}, 0.3);

		unlockedBadge.alpha     = option.unlocked ? 1 : 0;
		unlockedBadgeText.alpha = option.unlocked ? 1 : 0;

		FlxTween.cancelTweensOf(nameText);
		nameText.alpha = 0;
		nameText.text  = option.displayName;
		nameText.color = option.unlocked ? FlxColor.WHITE : 0xFF888888;
		FlxTween.tween(nameText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});

		FlxTween.cancelTweensOf(descText);
		descText.alpha = 0;
		descText.text  = option.unlocked ? option.description : "???";
		FlxTween.tween(descText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.05});

		progressPanel.visible  = hasProgress;
		progressBar.visible    = hasProgress;
		progressTxt.visible    = hasProgress;
		progressLabel.visible  = hasProgress;

		if (hasProgress)
		{
			var val1:Float = option.curProgress;
			var val2:Float = option.maxProgress;
			progressTxt.text = CoolUtil.floorDecimal(val1, option.decProgress) + ' / ' + CoolUtil.floorDecimal(val2, option.decProgress);

			if (barTween != null) barTween.cancel();
			progressBar.percent = 0;
			barTween = FlxTween.num(0, (val1 / val2) * 100, 0.6, {ease: FlxEase.quartOut}, function(v:Float)
			{
				progressBar.percent = v;
				progressBar.updateBar();
			});
		}
		else
		{
			progressBar.percent = 0;
			progressBar.updateBar();
		}

		for (i in 0...achievementItems.members.length)
		{
			var item = achievementItems.members[i];
			if (i == curSelected)
			{
				item.alpha       = 1;
				item.bg.color    = ACCENT_COLOR;
				item.bg.alpha    = 0.18;
				item.accentBar.alpha = 1;
				FlxTween.cancelTweensOf(item.scale);
				FlxTween.tween(item.scale, {x: 1.02, y: 1.02}, 0.2, {ease: FlxEase.quadOut});
			}
			else
			{
				item.alpha       = 0.55;
				item.bg.color    = 0xFF000000;
				item.bg.alpha    = 0.35;
				item.accentBar.alpha = 0;
				FlxTween.cancelTweensOf(item.scale);
				FlxTween.tween(item.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quadOut});
			}
		}

		var targetBarY = HEADER_H + 8 + curSelected * (ITEM_H + ITEM_SPACING);
		FlxTween.cancelTweensOf(selectionBar);
		FlxTween.cancelTweensOf(selectionBarGlow);
		FlxTween.tween(selectionBar,     {y: targetBarY},     0.25, {ease: FlxEase.expoOut});
		FlxTween.tween(selectionBarGlow, {y: targetBarY - 4}, 0.25, {ease: FlxEase.expoOut});

		updateCameraScroll();

		#if MODS_ALLOWED Mods.loadTopMod(); #end
	}

	function updateCameraScroll()
	{
		if (achievementItems.members.length == 0) return;
		var selectedItem  = achievementItems.members[curSelected];
		var targetY       = selectedItem.y + selectedItem.height / 2;
		var maxScroll     = Math.max(0, (achievementItems.members[achievementItems.members.length - 1].y + ITEM_H) - FlxG.height + 50);
		var targetScroll  = Math.min(Math.max(targetY - (FlxG.height / 2), 0), maxScroll);

		if (cameraTween != null) cameraTween.cancel();
		cameraTween = FlxTween.num(FlxG.camera.scroll.y, targetScroll, 0.35, {ease: FlxEase.quartOut}, function(v:Float) {
			FlxG.camera.scroll.y = v;
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		animTimer  += elapsed;
		pulseTimer += elapsed;
		waveTimer  += elapsed * 2;
		floatTimer += elapsed * 1.5;
		glowTimer  += elapsed * 3;

		for (i in 0...bgOrbs.length)
		{
			var orb = bgOrbs[i];
			orb.x += Math.sin(animTimer * 0.6 + i * 0.8) * 0.4;
			orb.y += Math.cos(animTimer * 0.5 + i * 0.8) * 0.3;
			orb.alpha = 0.04 + Math.sin(animTimer * 2 + i) * 0.02;
			orb.angle += elapsed * (4 + i * 2);
		}

		for (i in 0...floatingShapes.length)
		{
			var shape = floatingShapes[i];
			shape.y += Math.sin(floatTimer * 0.8 + i * 0.5) * 0.3;
			shape.x += Math.cos(floatTimer * 0.6 + i * 0.5) * 0.2;
			shape.alpha = 0.05 + Math.sin(floatTimer * 2 + i) * 0.03;
			shape.angle += elapsed * (8 + i);
		}

		if (headerGlow != null)
			headerGlow.alpha = 0.5 + Math.sin(waveTimer) * 0.2;

		if (selectionBarGlow != null)
			selectionBarGlow.alpha = 0.06 + Math.sin(glowTimer) * 0.04;

		if (showcaseGlow != null && options.length > 0 && options[curSelected].unlocked)
			showcaseGlow.alpha = 0.06 + Math.sin(pulseTimer * 1.8) * 0.03;

		if (options.length > 0)
		{
			if (controls.UI_UP_P)          changeSelection(-1);
			if (controls.UI_DOWN_P)        changeSelection(1);
			if (FlxG.mouse.wheel != 0)     changeSelection(-FlxG.mouse.wheel);

			if (MusicBeatState.getState().mobilePadJustPressed("C") ||
				controls.RESET && (options[curSelected].unlocked || options[curSelected].curProgress > 0))
			{
				removeTouchPad();
				openSubState(new ResetAchievementSubstate());
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTween.tween(leftPanel,   {x: -LEFT_PANEL_W},   0.45, {ease: FlxEase.backIn});
			FlxTween.tween(headerPanel, {y: -HEADER_H},       0.45, {ease: FlxEase.backIn});
			FlxTween.tween(rightPanel,  {x: FlxG.width + 50}, 0.45, {ease: FlxEase.backIn, startDelay: 0.05});

			new flixel.util.FlxTimer().start(0.5, function(_) {
				MusicBeatState.switchState(new MainMenuState());
			});
		}
	}

	function makeAchievement(achievement:String, data:Achievement, unlocked:Bool, mod:String = null)
	{
		return {
			name:        achievement,
			displayName: unlocked ? Language.getPhrase('achievement_$achievement', data.name) : '???',
			description: Language.getPhrase('description_$achievement', data.description),
			curProgress: data.maxScore > 0 ? Achievements.getScore(achievement) : 0,
			maxProgress: data.maxScore > 0 ? data.maxScore : 0,
			decProgress: data.maxScore > 0 ? data.maxDecimals : 0,
			unlocked:    unlocked,
			ID:          data.ID,
			mod:         mod
		};
	}

	public static function sortByID(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);
}

// ═══════════════════════════════════════════════════════════
// BAŞARI LİSTE ÖĞESİ
// ═══════════════════════════════════════════════════════════
class AchievementItem extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var accentBar:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var subText:FlxText;
	public var lockIcon:FlxText;
	public var targetY:Int = 0;

	public function new(x:Float, y:Float, data:Dynamic)
	{
		super(x, y);

		bg = FlxGradient.createGradientFlxSprite(412, 96, [0xCC0a0a18, 0xBB050510], 1, 0);
		bg.alpha = 0.35;
		add(bg);

		accentBar = new FlxSprite(0, 8).makeGraphic(4, 80, 0xFFFFC400);
		accentBar.alpha = 0;
		add(accentBar);

		var bottomLine = new FlxSprite(4, 92).makeGraphic(408, 2, 0x22FFFFFF);
		add(bottomLine);

		icon = new FlxSprite(14, 14);
		var graphic     = null;
		var hasAntialias = ClientPrefs.data.antialiasing;

		if (data.unlocked)
		{
			#if MODS_ALLOWED Mods.currentModDirectory = data.mod; #end
			var image:String = 'achievements/' + data.name;
			if (Paths.fileExists('images/$image-pixel.png', IMAGE))
			{
				graphic      = Paths.image('$image-pixel');
				hasAntialias = false;
			}
			else
				graphic = Paths.image(image);
			if (graphic == null) graphic = Paths.image('unknownMod');
		}
		else
			graphic = Paths.image('achievements/lockedachievement');

		icon.loadGraphic(graphic);
		icon.antialiasing = hasAntialias;
		icon.setGraphicSize(66, 66);
		icon.updateHitbox();
		icon.alpha = data.unlocked ? 1 : 0.4;
		add(icon);

		lockIcon = new FlxText(30, 28, 40, "🔒", 20);
		lockIcon.alpha = data.unlocked ? 0 : 0.7;
		add(lockIcon);

		text = new FlxText(90, 18, 315, data.displayName, 20);
		text.setFormat(Paths.font("vcr.ttf"), 20,
			data.unlocked ? FlxColor.WHITE : 0xFF888888,
			LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 1.5;
		add(text);

		var subStr:String   = data.unlocked
			? Language.getPhrase('achievement_done',   '✓ Completed')
			: Language.getPhrase('achievement_locked', 'Locked');
		var subColor:FlxColor = data.unlocked ? 0xFF10B981 : 0xFF555555;
		subText = new FlxText(90, 54, 200, subStr, 13);
		subText.setFormat(Paths.font("vcr.ttf"), 13, subColor, LEFT);
		add(subText);

		if (data.maxProgress > 0)
		{
			var pct = data.maxProgress > 0 ? Std.int((data.curProgress / data.maxProgress) * 100) : 0;
			var progText = new FlxText(290, 68, 120, '$pct%', 13);
			progText.setFormat(Paths.font("vcr.ttf"), 13, 0xFF666688, RIGHT);
			add(progText);
		}
	}
}

// ═══════════════════════════════════════════════════════════
// SIFIRLAMA SUBSTATE
// ═══════════════════════════════════════════════════════════
class ResetAchievementSubstate extends MusicBeatSubstate
{
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	public function new()
	{
		super();

		var bgDim:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bgDim.alpha = 0;
		bgDim.scrollFactor.set();
		add(bgDim);
		FlxTween.tween(bgDim, {alpha: 0.72}, 0.35, {ease: FlxEase.quartInOut});

		var panel = FlxGradient.createGradientFlxSprite(700, 320, [0xFF0a0a18, 0xFF050510], 1, 0);
		panel.screenCenter();
		panel.scrollFactor.set();
		add(panel);

		var panelBorder = new FlxSprite(panel.x, panel.y).makeGraphic(700, 4, 0xFFFFC400);
		panelBorder.alpha = 0.8;
		panelBorder.scrollFactor.set();
		add(panelBorder);

		var warnIcon = new FlxText(panel.x + 30, panel.y + 30, 60, "⚠️", 42);
		warnIcon.scrollFactor.set();
		add(warnIcon);

		var titleTxt = new FlxText(panel.x + 100, panel.y + 35, 570,
			Language.getPhrase('reset_achievement', 'Reset Achievement:'), 28);
		titleTxt.setFormat(Paths.font("vcr.ttf"), 28, 0xFFFFC400, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleTxt.borderSize = 2;
		titleTxt.scrollFactor.set();
		add(titleTxt);

		var state:AchievementsMenuState = cast FlxG.state;
		var achieveTxt = new FlxText(panel.x + 30, panel.y + 100, 640,
			state.options[state.curSelected].displayName, 32);
		achieveTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		achieveTxt.scrollFactor.set();
		achieveTxt.borderSize = 2;
		add(achieveTxt);

		var confirmTxt = new FlxText(panel.x + 30, panel.y + 155, 640,
			Language.getPhrase('reset_achievement_confirm', 'Achievement progress will be reset. Are you sure?'), 18);
		confirmTxt.setFormat(Paths.font("vcr.ttf"), 18, 0xFF888888, CENTER);
		confirmTxt.scrollFactor.set();
		add(confirmTxt);

		yesText = new Alphabet(panel.x + 140, panel.y + 215, Language.getPhrase('Yes', 'YES'), true);
		yesText.scrollFactor.set();
		for (letter in yesText.letters) letter.color = 0xFFFF5555;
		add(yesText);

		noText = new Alphabet(panel.x + 420, panel.y + 215, Language.getPhrase('No', 'NO'), true);
		noText.scrollFactor.set();
		add(noText);

		updateOptions();
		addTouchPad('LEFT_RIGHT', 'A');
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		super.update(elapsed);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			onYes = !onYes;
			updateOptions();
		}

		if (controls.ACCEPT)
		{
			if (onYes)
			{
				var state:AchievementsMenuState = cast FlxG.state;
				var option:Dynamic = state.options[state.curSelected];

				Achievements.variables.remove(option.name);
				Achievements.achievementsUnlocked.remove(option.name);
				option.unlocked     = false;
				option.curProgress  = 0;
				option.displayName  = '???';
				state.options[state.curSelected].displayName = '???';

				Achievements.save();
				FlxG.save.flush();

				@:privateAccess state._changeSelection();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			close();
			return;
		}
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.5, 1.2];
		var ci:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[ci];
		yesText.scale.set(scales[ci], scales[ci]);
		noText.alpha  = alphas[1 - ci];
		noText.scale.set(scales[1 - ci], scales[1 - ci]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
#end
