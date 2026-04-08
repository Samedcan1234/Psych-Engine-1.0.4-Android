package substates;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.util.FlxStringUtil;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.ui.FlxBar;

import states.StoryMenuState;
import states.FreeplayState;
import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxSpriteGroup>;

	var menuItems:Array<String>         = [];
	var menuItemsOG:Array<String>       = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices:Array<String> = [];
	var curSelected:Int = 0;

	var menuFont:String = "assets/fonts/vcr.ttf";
	var pauseMusic:FlxSound;

	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:FlxSpriteGroup;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	// Background
	var blurOverlay:FlxSprite;
	var gridBG:FlxBackdrop;
	var gradientTop:FlxSprite;
	var gradientBot:FlxSprite;
	var particles:Array<FlxSprite> = [];

	// Top panel
	var topPanel:FlxSprite;
	var topPanelLine:FlxSprite;
	var songNameText:FlxText;
	var diffText:FlxText;
	var deathText:FlxText;
	var practiceTag:FlxText;
	var chartingTag:FlxText;

	// Left menu panel
	var menuPanel:FlxSprite;
	var menuPanelGlow:FlxSprite;
	var menuPanelLine:FlxSprite;
	var selectionBar:FlxSprite;
	var selectionGlow:FlxSprite;

	// Right info panel
	var infoPanel:FlxSprite;
	var infoPanelLine:FlxSprite;
	var progressBar:FlxBar;
	var progressTimeText:FlxText;
	var scoreLive:FlxText;
	var accLive:FlxText;
	var missBadge:FlxText;
	var infoBeatLine:FlxSprite;

	// Bottom bar
	var bottomBar:FlxSprite;
	var botLine:FlxSprite;
	var ambientPulse:Float = 0;
	var breathe:Float      = 0;
	var isClosing:Bool     = false;
	var cantUnpause:Float  = 0.1;
	var holdTime:Float     = 0;

	var accentColor:FlxColor = 0xFF00E5FF;
	var menuIcons:Map<String,String> = [
		'Resume'                => '▶',
		'Restart Song'          => '↺',
		'Change Difficulty'     => '◈',
		'Options'               => '⚙',
		'Exit to menu'          => '✕',
		'Leave Charting Mode'   => '◀',
		'Skip Time'             => '⏩',
		'End Song'              => '⏭',
		'Toggle Practice Mode'  => '🎯',
		'Toggle Botplay'        => '🤖',
		'BACK'                  => '◀',
	];

	var menuColors:Map<String,FlxColor> = [
		'Resume'                => 0xFF10B981,
		'Restart Song'          => 0xFF4A90E2,
		'Change Difficulty'     => 0xFF8B5CF6,
		'Options'               => 0xFF64748B,
		'Exit to menu'          => 0xFFEC4899,
		'Leave Charting Mode'   => 0xFFF59E0B,
		'Skip Time'             => 0xFF00E5FF,
		'End Song'              => 0xFFFF5555,
		'Toggle Practice Mode'  => 0xFF10B981,
		'Toggle Botplay'        => 0xFF8B5CF6,
		'BACK'                  => 0xFF64748B,
	];

	public static var songName:String = null;

	// ─── Layout ────────────────────────────────────────────────────
	static inline var MENU_X:Float = 40.0;
	static inline var MENU_W:Float = 370.0;
	static inline var INFO_X:Float = 440.0;
	static inline var TOP_H:Float  = 78.0;
	static inline var BOT_H:Float  = 36.0;
	static inline var ITEM_H:Float = 72.0;

	// ═══════════════════════════════════════════════════════════════
	// CREATE
	// ═══════════════════════════════════════════════════════════════
	override function create()
	{
		// Prepare menu items
		if (Difficulty.list.length < 2)
			menuItemsOG.remove('Change Difficulty');

		if (PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			var num:Int = 0;
			if (!PlayState.instance.startingSong) { num = 1; menuItemsOG.insert(3, 'Skip Time'); }
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		else if (PlayState.instance.practiceMode && !PlayState.instance.startingSong)
			menuItemsOG.insert(3, 'Skip Time');

		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length)
			difficultyChoices.push(Difficulty.getString(i));
		difficultyChoices.push('BACK');

		// Music
		pauseMusic = new FlxSound();
		try
		{
			var ps = getPauseSong();
			if (ps != null) pauseMusic.loadEmbedded(Paths.music(ps), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		buildBackground();
		buildTopPanel();
		buildMenuPanel();
		buildInfoPanel();
		buildBottomBar();
		buildErrorUI();

		grpMenuShit = new FlxTypedGroup<FlxSpriteGroup>();
		add(grpMenuShit);

		regenMenu();
		playOpenAnimation();

		// ── Mobile controls ──────────────────────────────────────
		addTouchPad(menuItems.contains('Skip Time') ? 'LEFT_FULL' : 'UP_DOWN', 'A');
		addTouchPadCamera();

		super.create();
	}

	// ═══════════════════════════════════════════════════════════════
	// BACKGROUND
	// ═══════════════════════════════════════════════════════════════
	function buildBackground()
	{
		blurOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blurOverlay.alpha = 0;
		blurOverlay.scrollFactor.set();
		add(blurOverlay);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(36, 36, 72, 72, true, 0x0AFFFFFF, 0x0));
		gridBG.velocity.set(8, 8);
		gridBG.alpha = 0;
		gridBG.scrollFactor.set();
		add(gridBG);

		gradientTop = FlxGradient.createGradientFlxSprite(
			FlxG.width, 220, [0xCC000000, 0x00000000], 1, 90);
		gradientTop.scrollFactor.set();
		gradientTop.alpha = 0;
		add(gradientTop);

		gradientBot = FlxGradient.createGradientFlxSprite(
			FlxG.width, 220, [0x00000000, 0xCC000000], 1, 90);
		gradientBot.y = FlxG.height - 220;
		gradientBot.scrollFactor.set();
		gradientBot.alpha = 0;
		add(gradientBot);

		for (i in 0...28)
		{
			var p = new FlxSprite(
				FlxG.random.float(0, FlxG.width),
				FlxG.random.float(0, FlxG.height));
			var sz = Std.int(FlxG.random.float(1, 3));
			p.makeGraphic(sz, sz, FlxColor.WHITE);
			p.alpha      = 0;
			p.velocity.y = FlxG.random.float(-20, -5);
			p.velocity.x = FlxG.random.float(-4, 4);
			p.scrollFactor.set();
			add(p);
			particles.push(p);
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// TOP PANEL
	// ═══════════════════════════════════════════════════════════════
	function buildTopPanel()
	{
		topPanel = new FlxSprite(0, -TOP_H).makeGraphic(FlxG.width, Std.int(TOP_H), 0xF0040408);
		topPanel.scrollFactor.set();
		add(topPanel);

		topPanelLine = new FlxSprite(0, -3).makeGraphic(FlxG.width, 3, accentColor);
		topPanelLine.alpha = 0.6;
		topPanelLine.scrollFactor.set();
		add(topPanelLine);

		songNameText = new FlxText(20, -TOP_H + 10, 0, PlayState.SONG.song, 28);
		songNameText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songNameText.borderSize = 2;
		songNameText.scrollFactor.set();
		add(songNameText);

		diffText = new FlxText(20, -TOP_H + 44, 0, Difficulty.getString().toUpperCase(), 17);
		diffText.setFormat(Paths.font("vcr.ttf"), 17, accentColor, LEFT);
		diffText.scrollFactor.set();
		add(diffText);

		deathText = new FlxText(0, -TOP_H + 44, 0,
			Language.getPhrase("blueballed", "Blueballed: {1}", [PlayState.deathCounter]), 17);
		deathText.setFormat(Paths.font("vcr.ttf"), 17, 0xFF666688, RIGHT);
		deathText.scrollFactor.set();
		add(deathText);

		practiceTag = new FlxText(0, -TOP_H + 10, 0,
			Language.getPhrase("Practice Mode").toUpperCase(), 16);
		practiceTag.setFormat(Paths.font("vcr.ttf"), 16, 0xFF10B981, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		practiceTag.borderSize = 1;
		practiceTag.scrollFactor.set();
		practiceTag.visible = PlayState.instance.practiceMode;
		add(practiceTag);

		chartingTag = new FlxText(0, -TOP_H + 10, 0,
			Language.getPhrase("Charting Mode").toUpperCase(), 16);
		chartingTag.setFormat(Paths.font("vcr.ttf"), 16, 0xFFF59E0B, RIGHT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		chartingTag.borderSize = 1;
		chartingTag.scrollFactor.set();
		chartingTag.visible = PlayState.chartingMode;
		add(chartingTag);

		repositionTopRight();
	}

	function repositionTopRight()
	{
		deathText.x   = FlxG.width - deathText.width - 20;
		practiceTag.x = FlxG.width - practiceTag.width - 20;
		chartingTag.x = FlxG.width - chartingTag.width - 20;
	}

	// ═══════════════════════════════════════════════════════════════
	// LEFT MENU PANEL
	// ═══════════════════════════════════════════════════════════════
	function buildMenuPanel()
	{
		var panelH = FlxG.height - TOP_H - BOT_H;

		menuPanelGlow = new FlxSprite(MENU_X - 4, TOP_H - 4)
			.makeGraphic(Std.int(MENU_W + 8), Std.int(panelH + 8), accentColor);
		menuPanelGlow.alpha = 0.07;
		menuPanelGlow.scrollFactor.set();
		add(menuPanelGlow);

		menuPanel = FlxGradient.createGradientFlxSprite(
			Std.int(MENU_W), Std.int(panelH),
			[0xEE040408, 0xFF020206], 1, 0);
		menuPanel.x = MENU_X;
		menuPanel.y = TOP_H;
		menuPanel.scrollFactor.set();
		add(menuPanel);

		menuPanelLine = new FlxSprite(MENU_X + MENU_W, TOP_H)
			.makeGraphic(2, Std.int(panelH), accentColor);
		menuPanelLine.alpha = 0.35;
		menuPanelLine.scrollFactor.set();
		add(menuPanelLine);

		selectionGlow = new FlxSprite(MENU_X, TOP_H)
			.makeGraphic(Std.int(MENU_W), Std.int(ITEM_H), accentColor);
		selectionGlow.alpha = 0.11;
		selectionGlow.scrollFactor.set();
		add(selectionGlow);

		selectionBar = new FlxSprite(MENU_X, TOP_H)
			.makeGraphic(4, Std.int(ITEM_H - 8), accentColor);
		selectionBar.scrollFactor.set();
		add(selectionBar);
	}

	// ═══════════════════════════════════════════════════════════════
	// RIGHT INFO PANEL
	// ═══════════════════════════════════════════════════════════════
	function buildInfoPanel()
	{
		var iPanW = FlxG.width - INFO_X - 20;
		var iPanH = FlxG.height - TOP_H - BOT_H - 20;

		infoPanel = new FlxSprite(INFO_X, TOP_H + 10)
			.makeGraphic(Std.int(iPanW), Std.int(iPanH), 0xAA040408);
		infoPanel.scrollFactor.set();
		add(infoPanel);

		infoPanelLine = new FlxSprite(INFO_X, TOP_H + 10)
			.makeGraphic(Std.int(iPanW), 3, accentColor);
		infoPanelLine.alpha = 0.45;
		infoPanelLine.scrollFactor.set();
		add(infoPanelLine);

		infoBeatLine = new FlxSprite(INFO_X, TOP_H + 10)
			.makeGraphic(3, Std.int(iPanH), accentColor);
		infoBeatLine.alpha = 0.25;
		infoBeatLine.scrollFactor.set();
		add(infoBeatLine);

		// ── Progress bar ──────────────────────────────────────────
		var progY = TOP_H + 22;

		var progLabel = new FlxText(INFO_X + 15, progY, 300,
			Language.getPhrase("pause_song_progress", "SONG PROGRESS"), 12);
		progLabel.setFormat(Paths.font("vcr.ttf"), 12, accentColor, LEFT);
		progLabel.scrollFactor.set();
		add(progLabel);

		var barW = Std.int(iPanW - 30);
		var barBG = new FlxSprite(INFO_X + 15, progY + 16).makeGraphic(barW, 13, 0xFF0d0d1a);
		barBG.scrollFactor.set();
		add(barBG);

		progressBar = new FlxBar(INFO_X + 15, progY + 16, LEFT_TO_RIGHT, barW, 13, null, "", 0, 100, true);
		progressBar.createFilledBar(0xFF0d0d1a, accentColor, true, 0xFF000000);
		progressBar.scrollFactor.set();
		add(progressBar);

		progressTimeText = new FlxText(INFO_X + 15, progY + 32, barW, "0:00 / 0:00", 11);
		progressTimeText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF555577, RIGHT);
		progressTimeText.scrollFactor.set();
		add(progressTimeText);

		// ── Live stats ────────────────────────────────────────────
		var sY = TOP_H + 88;

		var scoreLabel = new FlxText(INFO_X + 15, sY, 200,
			Language.getPhrase("pause_score", "SCORE"), 12);
		scoreLabel.setFormat(Paths.font("vcr.ttf"), 12, 0xFF666688, LEFT);
		scoreLabel.scrollFactor.set();
		add(scoreLabel);

		scoreLive = new FlxText(INFO_X + 15, sY + 16, 260, "0", 26);
		scoreLive.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreLive.borderSize = 2;
		scoreLive.scrollFactor.set();
		add(scoreLive);

		var accLabel = new FlxText(INFO_X + 220, sY, 200,
			Language.getPhrase("pause_accuracy", "ACCURACY"), 12);
		accLabel.setFormat(Paths.font("vcr.ttf"), 12, 0xFF666688, LEFT);
		accLabel.scrollFactor.set();
		add(accLabel);

		accLive = new FlxText(INFO_X + 220, sY + 16, 200, "N/A", 26);
		accLive.setFormat(Paths.font("vcr.ttf"), 26, 0xFF10B981, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		accLive.borderSize = 2;
		accLive.scrollFactor.set();
		add(accLive);

		var missLabel = new FlxText(INFO_X + 400, sY, 200,
			Language.getPhrase("pause_misses", "MISSES"), 12);
		missLabel.setFormat(Paths.font("vcr.ttf"), 12, 0xFF666688, LEFT);
		missLabel.scrollFactor.set();
		add(missLabel);

		missBadge = new FlxText(INFO_X + 400, sY + 16, 200, "0", 26);
		missBadge.setFormat(Paths.font("vcr.ttf"), 26, 0xFFFF5555, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missBadge.borderSize = 2;
		missBadge.scrollFactor.set();
		add(missBadge);

		var sep = new FlxSprite(INFO_X + 15, sY + 52).makeGraphic(Std.int(iPanW - 30), 1, accentColor);
		sep.alpha = 0.2;
		sep.scrollFactor.set();
		add(sep);

		updateLiveStats();
	}

	function updateLiveStats()
	{
		if (PlayState.instance == null) return;

		scoreLive.text = Std.string(PlayState.instance.songScore);

		var acc = PlayState.instance.ratingPercent;
		var pct = FlxMath.roundDecimal(acc * 100, 2);
		accLive.text  = pct + "%";
		accLive.color = acc >= 0.95 ? 0xFF10B981 : acc >= 0.80 ? 0xFFF59E0B : 0xFFFF5555;

		missBadge.text = Std.string(PlayState.instance.songMisses);

		if (FlxG.sound.music != null && FlxG.sound.music.length > 0)
		{
			var ratio = FlxMath.bound(Conductor.songPosition / FlxG.sound.music.length, 0, 1);
			progressBar.value = ratio * 100;
			progressTimeText.text =
				FlxStringUtil.formatTime(Math.max(0, Math.floor(Conductor.songPosition / 1000)), false)
				+ " / "
				+ FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// BOTTOM BAR
	// ═══════════════════════════════════════════════════════════════
	function buildBottomBar()
	{
		bottomBar = new FlxSprite(0, FlxG.height - BOT_H)
			.makeGraphic(FlxG.width, Std.int(BOT_H), 0xF0040408);
		bottomBar.scrollFactor.set();
		add(bottomBar);

		botLine = new FlxSprite(0, FlxG.height - BOT_H)
			.makeGraphic(FlxG.width, 2, accentColor);
		botLine.alpha = 0.35;
		botLine.scrollFactor.set();
		add(botLine);

		var hint = new FlxText(20, FlxG.height - BOT_H + 9, FlxG.width - 40,
			Language.getPhrase("pause_hint", "↑↓: Navigate   ENTER: Confirm   ESC: Resume   F5: Reload"), 12);
		hint.setFormat(Paths.font("vcr.ttf"), 12, 0xFF333355, CENTER);
		hint.scrollFactor.set();
		add(hint);
	}

	// ═══════════════════════════════════════════════════════════════
	// ERROR UI
	// ═══════════════════════════════════════════════════════════════
	function buildErrorUI()
	{
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha    = 0.75;
		missingTextBG.visible  = false;
		missingTextBG.scrollFactor.set();
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 22);
		missingText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);
	}

	// ═══════════════════════════════════════════════════════════════
	// OPEN ANIMATION
	// ═══════════════════════════════════════════════════════════════
	function playOpenAnimation()
	{
		FlxTween.tween(blurOverlay, {alpha: 0.72}, 0.35, {ease: FlxEase.quartInOut});
		FlxTween.tween(gridBG,      {alpha: 0.10}, 0.50, {ease: FlxEase.quartInOut, startDelay: 0.08});
		FlxTween.tween(gradientTop, {alpha: 1},    0.40, {ease: FlxEase.quartInOut, startDelay: 0.08});
		FlxTween.tween(gradientBot, {alpha: 1},    0.40, {ease: FlxEase.quartInOut, startDelay: 0.08});

		for (i in 0...particles.length)
			FlxTween.tween(particles[i], {alpha: FlxG.random.float(0.04, 0.22)}, 0.6,
				{ease: FlxEase.quartInOut, startDelay: 0.1 + i * 0.008});

		FlxTween.tween(topPanel,     {y: 0},      0.45, {ease: FlxEase.backOut, startDelay: 0.04});
		FlxTween.tween(topPanelLine, {y: TOP_H},  0.45, {ease: FlxEase.backOut, startDelay: 0.04});
		FlxTween.tween(songNameText, {y: 10},      0.40, {ease: FlxEase.quadOut, startDelay: 0.18});
		FlxTween.tween(diffText,     {y: 44},      0.38, {ease: FlxEase.quadOut, startDelay: 0.22});
		FlxTween.tween(deathText,    {y: 44},      0.38, {ease: FlxEase.quadOut, startDelay: 0.26});
		FlxTween.tween(practiceTag,  {y: 10},      0.38, {ease: FlxEase.quadOut, startDelay: 0.26});
		FlxTween.tween(chartingTag,  {y: 10},      0.38, {ease: FlxEase.quadOut, startDelay: 0.26});

		menuPanel.x      = -MENU_W;
		menuPanelGlow.x  = -MENU_W - 8;
		menuPanelLine.x  = -4;
		selectionGlow.x  = -MENU_W;
		selectionBar.x   = -8;

		FlxTween.tween(menuPanel,     {x: MENU_X},           0.50, {ease: FlxEase.backOut, startDelay: 0.14});
		FlxTween.tween(menuPanelGlow, {x: MENU_X - 4},       0.50, {ease: FlxEase.backOut, startDelay: 0.14});
		FlxTween.tween(menuPanelLine, {x: MENU_X + MENU_W},  0.50, {ease: FlxEase.backOut, startDelay: 0.14});
		FlxTween.tween(selectionGlow, {x: MENU_X},           0.48, {ease: FlxEase.backOut, startDelay: 0.20});
		FlxTween.tween(selectionBar,  {x: MENU_X},           0.48, {ease: FlxEase.backOut, startDelay: 0.20});

		infoPanel.alpha      = 0;
		infoPanelLine.alpha  = 0;
		infoPanel.x          = INFO_X + 35;
		FlxTween.tween(infoPanel,     {alpha: 1, x: INFO_X}, 0.50, {ease: FlxEase.quadOut, startDelay: 0.24});
		FlxTween.tween(infoPanelLine, {alpha: 0.45},         0.50, {ease: FlxEase.quadOut, startDelay: 0.28});

		bottomBar.y = FlxG.height + 10;
		botLine.y   = FlxG.height + 10;
		FlxTween.tween(bottomBar, {y: FlxG.height - BOT_H}, 0.42, {ease: FlxEase.backOut, startDelay: 0.08});
		FlxTween.tween(botLine,   {y: FlxG.height - BOT_H}, 0.42, {ease: FlxEase.backOut, startDelay: 0.08});
	}

	// ═══════════════════════════════════════════════════════════════
	// CLOSE ANIMATION
	// ═══════════════════════════════════════════════════════════════
	function playCloseAnimation(onDone:Void->Void)
	{
		if (isClosing) return;
		isClosing = true;

		FlxTween.tween(menuPanel,     {x: -MENU_W},    0.32, {ease: FlxEase.backIn});
		FlxTween.tween(menuPanelGlow, {x: -MENU_W-8},  0.32, {ease: FlxEase.backIn});
		FlxTween.tween(menuPanelLine, {x: -4},         0.32, {ease: FlxEase.backIn});
		FlxTween.tween(selectionGlow, {x: -MENU_W},    0.28, {ease: FlxEase.backIn});
		FlxTween.tween(selectionBar,  {x: -8},         0.28, {ease: FlxEase.backIn});
		FlxTween.tween(infoPanel,     {alpha: 0, x: INFO_X + 40}, 0.28, {ease: FlxEase.quadIn});
		FlxTween.tween(infoPanelLine, {alpha: 0},      0.28, {ease: FlxEase.quadIn});
		FlxTween.tween(topPanel,      {y: -TOP_H},     0.30, {ease: FlxEase.backIn});
		FlxTween.tween(topPanelLine,  {y: -3},         0.30, {ease: FlxEase.backIn});
		FlxTween.tween(bottomBar,     {y: FlxG.height + 10}, 0.30, {ease: FlxEase.backIn});
		FlxTween.tween(botLine,       {y: FlxG.height + 10}, 0.30, {ease: FlxEase.backIn});

		for (item in grpMenuShit.members)
			FlxTween.tween(item, {alpha: 0, x: item.x - 50}, 0.26, {ease: FlxEase.quadIn});

		FlxTween.tween(gridBG,      {alpha: 0}, 0.36, {ease: FlxEase.quartInOut});
		FlxTween.tween(gradientTop, {alpha: 0}, 0.36, {ease: FlxEase.quartInOut});
		FlxTween.tween(gradientBot, {alpha: 0}, 0.36, {ease: FlxEase.quartInOut});
		FlxTween.tween(blurOverlay, {alpha: 0}, 0.38, {
			ease: FlxEase.quartInOut,
			onComplete: function(_) { onDone(); }
		});
	}

	// ═══════════════════════════════════════════════════════════════
	// MENU ITEMS
	// ═══════════════════════════════════════════════════════════════
	function regenMenu():Void
	{
		for (i in 0...grpMenuShit.members.length)
		{
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}
		deleteSkipTimeText();

		for (num => str in menuItems)
		{
			var itemGroup = new FlxSpriteGroup();
			itemGroup.scrollFactor.set();

			var itemBG = new FlxSprite(0, 0)
				.makeGraphic(Std.int(MENU_W - 6), Std.int(ITEM_H - 4), 0xFF0d0d1a);
			itemBG.alpha = 0.85;
			itemGroup.add(itemBG);

			var accent = new FlxSprite(0, 0).makeGraphic(5, Std.int(ITEM_H - 4),
				menuColors.exists(str) ? menuColors.get(str) : accentColor);
			accent.alpha = 0;
			itemGroup.add(accent);

			var glowBar = new FlxSprite(0, Std.int(ITEM_H - 8))
				.makeGraphic(Std.int(MENU_W - 6), 4,
				menuColors.exists(str) ? menuColors.get(str) : accentColor);
			glowBar.alpha = 0;
			itemGroup.add(glowBar);

			var ic = new FlxText(12, 6, 40,
				menuIcons.exists(str) ? menuIcons.get(str) : "►", 28);
			ic.setFormat(null, 28,
				menuColors.exists(str) ? menuColors.get(str) : accentColor, LEFT);
			itemGroup.add(ic);

			var lbl = new FlxText(58, 10, Std.int(MENU_W - 75),
				Language.getPhrase('pause_$str', str), 26);
			lbl.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lbl.borderSize = 2;
			itemGroup.add(lbl);

			if (str == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 50);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 50, FlxColor.WHITE, CENTER,
					FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.borderSize = 2;
				skipTimeText.scrollFactor.set();
				skipTimeTracker = itemGroup;
				add(skipTimeText);
				updateSkipTextStuff();
				updateSkipTimeText();
			}

			itemGroup.ID = num;
			itemGroup.x  = MENU_X + 5;
			itemGroup.y  = TOP_H + 8 + num * ITEM_H;
			grpMenuShit.add(itemGroup);
		}

		curSelected = 0;
		changeSelection();

		// ── Refresh touch pad when menu changes ───────────────────
		if (mobileManager.mobilePad != null)
		{
			removeTouchPad();
			addTouchPad(menuItems.contains('Skip Time') ? 'LEFT_FULL' : 'UP_DOWN', 'A');
			addTouchPadCamera();
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// UPDATE
	// ═══════════════════════════════════════════════════════════════
	override function update(elapsed:Float)
	{
		if (isClosing) { super.update(elapsed); return; }

		cantUnpause -= elapsed;
		ambientPulse += elapsed;
		breathe      += elapsed * 2.2;

		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		// ── Mobile touch pad null-check ───────────────────────────
		if (mobileManager.mobilePad == null)
		{
			addTouchPad(menuItems.contains('Skip Time') ? 'LEFT_FULL' : 'UP_DOWN', 'A');
			addTouchPadCamera();
		}

		for (p in particles)
		{
			if (p.y < -10) { p.y = FlxG.height + 10; p.x = FlxG.random.float(0, FlxG.width); }
			p.alpha = 0.04 + Math.sin(ambientPulse + p.x * 0.01) * 0.04;
		}

		updateLiveStats();

		var lv = FlxMath.bound(elapsed * 11, 0, 1);
		for (item in grpMenuShit.members)
		{
			var grp:FlxSpriteGroup = cast item;
			if (grp == null) continue;

			var ty = TOP_H + 8 + grp.ID * ITEM_H;
			grp.y = FlxMath.lerp(grp.y, ty, lv);
			var sel = (grp.ID == curSelected);
			grp.alpha = FlxMath.lerp(grp.alpha, sel ? 1.0 : 0.38, lv);

			if (grp.members.length > 1)
				grp.members[1].alpha = FlxMath.lerp(grp.members[1].alpha, sel ? 1.0 : 0.0, lv);

			if (grp.members.length > 2)
				grp.members[2].alpha = FlxMath.lerp(grp.members[2].alpha, sel ? 0.6 : 0.0, lv);

			if (grp.members.length > 0)
			{
				var targetColor = sel
					? FlxColor.interpolate(0xFF0d0d1a,
						menuColors.exists(menuItems[curSelected]) ? menuColors.get(menuItems[curSelected]) : accentColor,
						0.15)
					: 0xFF0d0d1a;
				grp.members[0].color = FlxColor.interpolate(grp.members[0].color, targetColor, lv);
			}
		}

		var gy = TOP_H + 8 + curSelected * ITEM_H;
		selectionGlow.y = FlxMath.lerp(selectionGlow.y, gy, lv);
		selectionBar.y  = FlxMath.lerp(selectionBar.y,  gy + 4, lv);
		selectionGlow.alpha = 0.09 + Math.sin(breathe) * 0.04;

		menuPanelGlow.alpha = 0.05 + Math.sin(ambientPulse * 1.6) * 0.03;
		infoBeatLine.alpha  = 0.18 + Math.sin(ambientPulse * 2)   * 0.08;

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			playCloseAnimation(function() { close(); });
			return;
		}

		if (FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn  = true;
			FlxTransitionableState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			MusicBeatState.resetState();
		}

		if (controls.UI_UP_P)   changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		var daSelected = menuItems[curSelected];
		handleSkipTime(elapsed, daSelected);

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
			handleAccept(daSelected);
	}

	// ═══════════════════════════════════════════════════════════════
	// BEAT HIT
	// ═══════════════════════════════════════════════════════════════
	override function beatHit()
	{
		super.beatHit();
		if (isClosing) return;

		FlxTween.cancelTweensOf(infoBeatLine);
		infoBeatLine.alpha = 0.9;
		FlxTween.tween(infoBeatLine, {alpha: 0.18}, 0.40, {ease: FlxEase.quadOut});

		FlxTween.cancelTweensOf(selectionBar.scale);
		selectionBar.scale.set(1.0, 1.25);
		FlxTween.tween(selectionBar.scale, {x: 1.0, y: 1.0}, 0.22, {ease: FlxEase.quadOut});

		FlxTween.cancelTweensOf(menuPanelGlow);
		menuPanelGlow.alpha = 0.20;
		FlxTween.tween(menuPanelGlow, {alpha: 0.05}, 0.40, {ease: FlxEase.quadOut});

		for (item in grpMenuShit.members)
		{
			var grp:FlxSpriteGroup = cast item;
			if (grp == null || grp.ID != curSelected) continue;

			FlxTween.cancelTweensOf(grp.scale);
			grp.scale.set(1.025, 1.025);
			FlxTween.tween(grp.scale, {x: 1.0, y: 1.0}, 0.22, {ease: FlxEase.quadOut});

			if (grp.members.length > 2)
			{
				FlxTween.cancelTweensOf(grp.members[2]);
				grp.members[2].alpha = 1.0;
				FlxTween.tween(grp.members[2], {alpha: 0.6}, 0.3, {ease: FlxEase.quadOut});
			}
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// ACCEPT
	// ═══════════════════════════════════════════════════════════════
	function handleAccept(daSelected:String)
	{
		if (menuItems == difficultyChoices)
		{
			var sl = Paths.formatToSongPath(PlayState.SONG.song);
			var poop = Highscore.formatSong(sl, curSelected);
			try
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					Song.loadFromJson(poop, sl);
					PlayState.storyDifficulty   = curSelected;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode      = false;
					FlxG.sound.music.volume     = 0;
					MusicBeatState.resetState();
					return;
				}
			}
			catch(e:haxe.Exception)
			{
				var err = e.message;
				if (err.startsWith('[lime.utils.Assets] ERROR:'))
					err = Language.getPhrase("pause_missing_file", "Missing file: ") + err.substring(err.indexOf(sl), err.length - 1);
				else
					err += '\n\n' + e.stack;
				missingText.text    = Language.getPhrase("pause_chart_error", "ERROR WHILE LOADING CHART:\n{1}", [err]);
				missingText.screenCenter(Y);
				missingText.visible   = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}
			menuItems = menuItemsOG;
			regenMenu();
			return;
		}

		FlxG.sound.play(Paths.sound('confirmMenu'));

		switch (daSelected)
		{
			case "Resume":
				playCloseAnimation(function() { close(); });

			case 'Change Difficulty':
				menuItems = difficultyChoices;
				deleteSkipTimeText();
				regenMenu();

			case 'Toggle Practice Mode':
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				PlayState.changedDifficulty     = true;
				practiceTag.visible             = PlayState.instance.practiceMode;

			case "Restart Song":
				restartSong();

			case "Leave Charting Mode":
				restartSong();
				PlayState.chartingMode = false;

			case 'Skip Time':
				if (curTime < Conductor.songPosition) { PlayState.startOnTime = curTime; restartSong(true); }
				else
				{
					if (curTime != Conductor.songPosition)
					{
						PlayState.instance.clearNotesBefore(curTime);
						PlayState.instance.setSongTime(curTime);
					}
					playCloseAnimation(function() { close(); });
				}

			case 'End Song':
				close();
				PlayState.instance.notes.clear();
				PlayState.instance.unspawnNotes = [];
				PlayState.instance.finishSong(true);

			case 'Toggle Botplay':
				PlayState.instance.cpuControlled          = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty               = true;
				PlayState.instance.botplayTxt.visible     = PlayState.instance.cpuControlled;
				PlayState.instance.botplayTxt.alpha       = 1;
				PlayState.instance.botplaySine            = 0;

			case 'Options':
				PlayState.instance.paused        = true;
				PlayState.instance.vocals.volume = 0;
				PlayState.instance.canResync     = false;
				MusicBeatState.switchState(new OptionsState());
				if (ClientPrefs.data.pauseMusic != 'None')
				{
					FlxG.sound.playMusic(
						Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)),
						pauseMusic.volume);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
					FlxG.sound.music.time = pauseMusic.time;
				}
				OptionsState.onPlayState = true;

			case "Exit to menu":
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				PlayState.deathCounter       = 0;
				PlayState.seenCutscene       = false;
				PlayState.instance.canResync = false;
				Mods.loadTopMod();
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty  = false;
				PlayState.chartingMode       = false;
				FlxG.camera.followLerp       = 0;
				if (PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
				else                       MusicBeatState.switchState(new FreeplayState());
		}
	}

	// ═══════════════════════════════════════════════════════════════
	// SKIP TIME
	// ═══════════════════════════════════════════════════════════════
	function handleSkipTime(elapsed:Float, daSelected:String)
	{
		if (daSelected != 'Skip Time') return;
		if (controls.UI_LEFT_P)  { FlxG.sound.play(Paths.sound('scrollMenu'), 0.4); curTime -= 1000; holdTime = 0; }
		if (controls.UI_RIGHT_P) { FlxG.sound.play(Paths.sound('scrollMenu'), 0.4); curTime += 1000; holdTime = 0; }
		if (controls.UI_LEFT || controls.UI_RIGHT)
		{
			holdTime += elapsed;
			if (holdTime > 0.5) curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
			if (curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
			else if (curTime < 0) curTime += FlxG.sound.music.length;
			updateSkipTimeText();
		}
	}

	function getPauseSong():String
	{
		var formattedSong  = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPause = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if (formattedSong == 'none' || (formattedSong != 'none' && formattedPause == 'none')) return null;
		return (formattedSong != '') ? formattedSong : formattedPause;
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		missingText.visible   = false;
		missingTextBG.visible = false;
		for (item in grpMenuShit.members)
			if (item.ID == curSelected && item == skipTimeTracker) { curTime = Math.max(0, Conductor.songPosition); updateSkipTimeText(); }
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function deleteSkipTimeText()
	{
		if (skipTimeText != null) { skipTimeText.kill(); remove(skipTimeText); skipTimeText.destroy(); }
		skipTimeText    = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused        = true;
		FlxG.sound.music.volume          = 0;
		PlayState.instance.vocals.volume = 0;
		if (noTrans)
		{
			FlxTransitionableState.skipNextTransIn  = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	function updateSkipTextStuff()
	{
		if (skipTimeText == null || skipTimeTracker == null) return;
		skipTimeText.x       = skipTimeTracker.x + skipTimeTracker.width + 50;
		skipTimeText.y       = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		if (skipTimeText == null) return;
		skipTimeText.text =
			FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			+ ' / '
			+ FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}

	override function destroy()
	{
		pauseMusic.destroy();
		super.destroy();
	}
}
