package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.ThemeManager;
import objects.HealthIcon;
import objects.MusicPlayer;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.utils.Assets;
import openfl.events.KeyboardEvent;
import haxe.Json;
import backend.ui.PsychUIInputText;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxTimer;
import flixel.ui.FlxBar;
import objects.Alphabet;
import objects.EmojiText;
import objects.EmojiAtlas;

class FreeplayState extends MusicBeatState
{
	public static var instance:FreeplayState;

	public var songs:Array<SongMetadata> = [];
	var allSongs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	public var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var bg:FlxSprite;
	var bgOverlay:FlxSprite;
	var songBG:FlxSprite;
	var gridBG:FlxBackdrop;
	var gradientTop:FlxSprite;
	var gradientBottom:FlxSprite;
	var gradientLeft:FlxSprite;
	var intendedColor:Int;
	var particles:FlxEmitter;
	var floatingOrbs:Array<FlxSprite> = [];
	var ambientPulse:Float = 0;
	var breathingEffect:Float = 0;
	var customSongBGs:Map<String, String> = new Map();

	var topBar:FlxSprite;
	var topBarLine:FlxSprite;
	var topBarGlow:FlxSprite;
	var topBarGradient:FlxSprite;
	var titleText:FlxText;
	var titleIcon:FlxText;
	var songCountText:FlxText;
	var songCountBadge:FlxSprite;

	var tabBar:FlxSprite;
	var tabButtons:Array<FlxSprite> = [];
	var tabTexts:Array<FlxText> = [];
	var tabIndicator:FlxSprite;
	var tabGlows:Array<FlxSprite> = [];
	var categories:Array<String> = ['All', 'Favorites', 'Last Played', 'Hidden'];
	var curCategoryIndex:Int = 0;
	var curCategory:String = 'All';

	var lastBeatTime:Float = 0;
	var beatBPM:Float = 100;
	var iconBeatScale:Float = 1.0;

	var showcasePanel:FlxSprite;
	var showcasePanelGlow:FlxSprite;
	var showcaseBorder:FlxSprite;
	var showcaseWidth:Int = 340;

	var showcaseIconBG:FlxSprite;
	var showcaseIconGlow:FlxSprite;
	var showcaseIcon:FlxSprite;
	var showcaseIconFrame:FlxSprite;

	var showcaseTitle:FlxText;
	var showcaseSubtitle:FlxText;
	var showcaseWeekText:FlxText;
	var showcaseCharText:FlxText;

	var scorePanel:FlxSprite;
	var scorePanelGlow:FlxSprite;
	var scoreLabel:FlxText;
	public var scoreText:FlxText;
	var accuracyText:FlxText;
	var accuracyBar:FlxBar;
	var gradeText:FlxText;
	var gradeIcon:EmojiText;

	var diffPanel:FlxSprite;
	var diffPanelGlow:FlxSprite;
	public var diffText:FlxText;
	var diffLabel:FlxText;
	var diffDots:Array<FlxSprite> = [];

	var statsPanel:FlxSprite;
	var totalSongsText:FlxText;
	var favCountText:FlxText;
	var completionText:FlxText;
	var completionBar:FlxBar;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;
	private var curPlaying:Bool = false;

	var randomText:Alphabet;
	var randomIcon:HealthIcon;

	var searchGroup:FlxSpriteGroup;
	var searchScreenBG:FlxSprite;
	var searchScreenTitle:FlxText;
	var spotlightSearchBox:PsychUIInputText;
	var searchScreenWait:Bool = false;
	var searchHint:FlxText;

	var bottomBG:FlxSprite;
	var bottomBarLine:FlxSprite;
	public var bottomText:FlxText;
	public var bottomString:String;

	var selected:Bool = false;
	var selectedItem:Int = 0;
	var menuBG:FlxSprite;
	var menuContainer:FlxSpriteGroup;
	var diffSelect:Alphabet;
	var modifiersSelect:Alphabet;
	var resetSelect:Alphabet;
	var backSelect:Alphabet;

	var menuSelectionGlow:FlxSprite;
	var menuSelectionBar:FlxSprite;

	var player:MusicPlayer;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var missesText:FlxText;

	var favorites:Array<String> = [];
	var hiddenSongs:Array<String> = [];
	var recentPlays:Array<String> = [];

	var pulseTimer:Float = 0;
	public var scoreBG:FlxSprite;
	public var holdTime:Float = 0;
	var accentColor:FlxColor = 0xFF9271FD;

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var stopMusicPlay:Bool = false;
	var _drawDistance:Int = 6;

	var categoryIcons:Map<String, String> = [
		'All' => '📂',
		'Favorites' => '⭐',
		'Last Played' => '🕐',
		'Hiddens' => '👁️'
	];

	var mobileTipBG:FlxSprite;
	var mobileTipText:FlxText;
	var mobileTipTimer:Float = 0;
	var mobileTipVisible:Bool = false;

	override function create()
	{
		super.create();
		
		if (!EmojiAtlas.instance.isLoaded())
			EmojiAtlas.instance.load("emoji_atlas", 72);
		instance = this;
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Freeplay", null);
		#end
		
		final accept:String = (controls.mobileC) ? "A" : "ACCEPT";
		final reject:String  = (controls.mobileC) ? "B" : "BACK";

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState(
				"NO WEEKS ADDED FOR FREEPLAY\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject + " to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		if (FlxG.save.data.favorites != null) favorites = FlxG.save.data.favorites;
		if (FlxG.save.data.hiddenSongs != null) hiddenSongs = FlxG.save.data.hiddenSongs;
		if (FlxG.save.data.recentPlays != null) recentPlays = FlxG.save.data.recentPlays;

		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
					colors = [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();
		allSongs = songs.copy();
		songs = [];
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		bg.color = 0xFF0a0a18;
		add(bg);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(45, 45, 90, 90, true, 0x05FFFFFF, 0x0));
		gridBG.velocity.set(-10, 8);
		gridBG.alpha = 0.06;
		add(gridBG);

		bgOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bgOverlay.color = FlxColor.BLACK;
		bgOverlay.alpha = 0.2;
		add(bgOverlay);

		songBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		songBG.color = FlxColor.BLACK;
		songBG.alpha = 0;
		add(songBG);

		gradientTop = FlxGradient.createGradientFlxSprite(FlxG.width, 150, [0xCC000000, 0x88000000, 0x00000000], 1, 180);
		add(gradientTop);

		gradientBottom = FlxGradient.createGradientFlxSprite(FlxG.width, 150, [0x00000000, 0x88000000, 0xCC000000], 1, 180);
		gradientBottom.y = FlxG.height - 150;
		add(gradientBottom);

		particles = new FlxEmitter(FlxG.width / 2, -50);
		particles.launchMode = FlxEmitterMode.SQUARE;
		particles.velocity.set(-15, 40, 15, 120);
		particles.scale.set(0.2, 0.2, 0.6, 0.6);
		particles.lifespan.set(4, 8);
		particles.alpha.set(0.3, 0.6, 0, 0);
		particles.color.set(0xFF9271FD, 0xFF6B4FFF, 0xFFFF00FF, 0xFF00FFFF);
		particles.width = FlxG.width;

		for (i in 0...40)
		{
			var p = new FlxParticle();
			p.makeGraphic(3, 3, FlxColor.WHITE);
			particles.add(p);
		}
		particles.start(false, 0.15);
		add(particles);

		for (i in 0...6)
		{
			var orb = new FlxSprite(FlxG.random.float(50, FlxG.width - 50), FlxG.random.float(80, FlxG.height - 80));
			orb.makeGraphic(Std.int(FlxG.random.float(12, 25)), Std.int(FlxG.random.float(12, 25)), FlxColor.WHITE);
			orb.color = accentColor;
			orb.alpha = FlxG.random.float(0.02, 0.06);
			add(orb);
			floatingOrbs.push(orb);
		}

		createShowcasePanel();

		topBarGlow = new FlxSprite(0, 0).makeGraphic(FlxG.width, 58, FlxColor.WHITE);
		topBarGlow.color = accentColor;
		topBarGlow.alpha = 0.04;
		add(topBarGlow);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 55, FlxColor.WHITE);
		topBar.color = 0xFF050510;
		topBar.alpha = 0.86;
		add(topBar);

		topBarLine = new FlxSprite(0, 53).makeGraphic(FlxG.width, 2, FlxColor.WHITE);
		topBarLine.color = accentColor;
		topBarLine.alpha = 0.5;
		add(topBarLine);

		topBarGradient = FlxGradient.createGradientFlxSprite(FlxG.width, 60, [0xDD050510, 0x88050510, 0x00050510], 1, 180);
		topBarGradient.y = 55;
		add(topBarGradient);

		titleIcon = new FlxText(18, 10, 40, "♪", 32);
		titleIcon.setFormat(Paths.font("vcr.ttf"), 32, accentColor, LEFT);
		add(titleIcon);

		titleText = new FlxText(50, 8, 250, "FREEPLAY", 30);
		titleText.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		titleText.borderSize = 2;
		add(titleText);

		var editionLabel = new FlxText(50, 38, 120, "XQ EDITION", 10);
		editionLabel.setFormat(Paths.font("vcr.ttf"), 10, accentColor, LEFT);
		add(editionLabel);

		songCountBadge = new FlxSprite(FlxG.width - 130, 15).makeGraphic(120, 26, FlxColor.WHITE);
		songCountBadge.color = accentColor;
		songCountBadge.alpha = 0.2;
		add(songCountBadge);

		songCountText = new FlxText(FlxG.width - 130, 18, 120, "0 Songs", 14);
		songCountText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		add(songCountText);

		var hintStr:String = controls.mobileC ? "Z: Search | Y: Filter | F: Fav | H: Hide" : "F: Search | TAB: Filter | G: Fav | H: Hide";
		searchHint = new FlxText(FlxG.width - 340, 20, 200, hintStr, 11);
		searchHint.setFormat(Paths.font("vcr.ttf"), 11, 0xFF555555, RIGHT);
		add(searchHint);

		menuBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		menuBG.color = FlxColor.BLACK;
		menuBG.alpha = 0;
		add(menuBG);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);
		
		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		randomText = new Alphabet(showcaseWidth + 30, 320, "RANDOM", true);
		randomText.targetY = -1;
		randomText.snapToPosition();
		add(randomText);

		randomIcon = new HealthIcon('bf');
		add(randomIcon);
		
		createTabBar();
		createSelectionMenu();

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		missingTextBG.color = FlxColor.BLACK;
		missingTextBG.alpha = 0.8;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		player = new MusicPlayer(this);
		add(player);

		mobileTipBG = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 34, FlxColor.WHITE);
		mobileTipBG.color = FlxColor.BLACK;
		mobileTipBG.alpha = 0;
		add(mobileTipBG);

		mobileTipText = new FlxText(0, FlxG.height - 66, FlxG.width, "", 14);
		mobileTipText.setFormat(Paths.font("vcr.ttf"), 14, accentColor, CENTER);
		mobileTipText.alpha = 0;
		add(mobileTipText);
		
		createSearchSystem();

		WeekData.setDirectoryFromWeek();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		updateList();
		updateQuickStats();

		if (curSelected >= songs.length) curSelected = -1;
		bg.color = (curSelected >= 0 && songs.length > 0) ? songs[curSelected].color : 0xFF0a0a18;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		changeSelection(0, false);
		updateTexts(0);

		playEntranceAnimation();

		addTouchPad('LEFT_FULL', 'FREEPLAY');
	}

	function createTabBar()
	{
		var tabY = 62;
		var tabH = 30;
		var tabStartX = showcaseWidth + 30;
		var tabW = 110;
		var tabGap = 8;

		tabBar = new FlxSprite(tabStartX - 5, tabY - 3).makeGraphic((tabW + tabGap) * categories.length + 10, tabH + 6, FlxColor.WHITE);
		tabBar.color = FlxColor.BLACK;
		tabBar.alpha = 0.2;
		add(tabBar);

		tabIndicator = new FlxSprite(tabStartX, tabY + tabH - 3).makeGraphic(tabW, 3, FlxColor.WHITE);
		tabIndicator.color = accentColor;
		tabIndicator.alpha = 0.8;

		for (i in 0...categories.length)
		{
			var tx = tabStartX + i * (tabW + tabGap);

			var glow = new FlxSprite(tx - 1, tabY - 1).makeGraphic(tabW + 2, tabH + 2, FlxColor.WHITE);
			glow.color = accentColor;
			glow.alpha = 0;
			add(glow);
			tabGlows.push(glow);

			var btn = new FlxSprite(tx, tabY).makeGraphic(tabW, tabH, FlxColor.WHITE);
			btn.color = FlxColor.BLACK;
			btn.alpha = 0.3;
			add(btn);
			tabButtons.push(btn);

			var tabTxt = new FlxText(tx, tabY + 6, tabW, categories[i].toUpperCase(), 12);
			tabTxt.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER);
			add(tabTxt);
			tabTexts.push(tabTxt);
		}

		add(tabIndicator);
		updateTabVisuals();
	}

	function updateTabVisuals()
	{
		for (i in 0...tabTexts.length)
		{
			if (i == curCategoryIndex)
			{
				tabTexts[i].color = FlxColor.WHITE;
				tabButtons[i].color = accentColor;
				tabButtons[i].alpha = 0.3;
				tabGlows[i].alpha = 0.1;
			}
			else
			{
				tabTexts[i].color = 0xFF888888;
				tabButtons[i].color = FlxColor.BLACK;
				tabButtons[i].alpha = 0.3;
				tabGlows[i].alpha = 0;
			}
		}

		var targetX = tabButtons[curCategoryIndex].x;
		FlxTween.cancelTweensOf(tabIndicator);
		FlxTween.tween(tabIndicator, {x: targetX}, 0.25, {ease: FlxEase.quartOut});
	}

	function createShowcasePanel()
	{
		var panelX = 0;
		var panelY = 55;
		var panelH = FlxG.height - 90;

		showcasePanelGlow = new FlxSprite(panelX - 1, panelY - 1).makeGraphic(showcaseWidth + 2, panelH + 2, FlxColor.WHITE);
		showcasePanelGlow.color = accentColor;
		showcasePanelGlow.alpha = 0.04;
		add(showcasePanelGlow);

		showcasePanel = new FlxSprite(panelX, panelY).makeGraphic(showcaseWidth, panelH, FlxColor.WHITE);
		showcasePanel.color = 0xFF050510;
		showcasePanel.alpha = 0.8;
		add(showcasePanel);

		showcaseBorder = new FlxSprite(showcaseWidth - 2, panelY).makeGraphic(2, panelH, FlxColor.WHITE);
		showcaseBorder.color = accentColor;
		showcaseBorder.alpha = 0.3;
		add(showcaseBorder);

		var iconY = panelY + 20;
		var iconSize = 130;
		var iconCX = Std.int(showcaseWidth / 2);

		showcaseIconGlow = new FlxSprite(iconCX - iconSize / 2 - 3, iconY - 3).makeGraphic(iconSize + 6, iconSize + 6, FlxColor.WHITE);
		showcaseIconGlow.color = accentColor;
		showcaseIconGlow.alpha = 0.1;
		add(showcaseIconGlow);

		showcaseIconBG = new FlxSprite(iconCX - iconSize / 2, iconY).makeGraphic(iconSize, iconSize, FlxColor.WHITE);
		showcaseIconBG.color = 0xFF111122;
		add(showcaseIconBG);

		showcaseIcon = new FlxSprite(iconCX - iconSize / 2 + 5, iconY + 5);
		showcaseIcon.antialiasing = ClientPrefs.data.antialiasing;
		showcaseIcon.makeGraphic(120, 120, FlxColor.TRANSPARENT);
		add(showcaseIcon);

		showcaseIconFrame = new FlxSprite(iconCX - iconSize / 2, iconY).makeGraphic(iconSize, 2, FlxColor.WHITE);
		showcaseIconFrame.color = accentColor;
		showcaseIconFrame.alpha = 0.5;
		add(showcaseIconFrame);

		var textStartY = iconY + iconSize + 15;

		showcaseTitle = new FlxText(15, textStartY, showcaseWidth - 30, "SONG NAME", 22);
		showcaseTitle.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		showcaseTitle.borderSize = 2;
		add(showcaseTitle);

		showcaseSubtitle = new FlxText(15, textStartY + 28, showcaseWidth - 30, "Artist", 14);
		showcaseSubtitle.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, CENTER);
		add(showcaseSubtitle);

		var scoreY = textStartY + 60;

		scorePanelGlow = new FlxSprite(13, scoreY - 2).makeGraphic(showcaseWidth - 26, 82, FlxColor.WHITE);
		scorePanelGlow.color = accentColor;
		scorePanelGlow.alpha = 0.05;
		add(scorePanelGlow);

		scorePanel = new FlxSprite(15, scoreY).makeGraphic(showcaseWidth - 30, 78, FlxColor.WHITE);
		scorePanel.color = FlxColor.BLACK;
		scorePanel.alpha = 0.53;
		add(scorePanel);

		var scorePanelBorder = new FlxSprite(15, scoreY).makeGraphic(showcaseWidth - 30, 2, FlxColor.WHITE);
		scorePanelBorder.color = accentColor;
		scorePanelBorder.alpha = 0.4;
		add(scorePanelBorder);

		scoreLabel = new FlxText(25, scoreY + 6, 100, "◈ SCORE", 12);
		scoreLabel.setFormat(Paths.font("vcr.ttf"), 12, accentColor, LEFT);
		add(scoreLabel);

		scoreText = new FlxText(25, scoreY + 22, showcaseWidth - 60, "0", 28);
		scoreText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		scoreText.borderSize = 2;
		add(scoreText);

		accuracyText = new FlxText(25, scoreY + 54, 120, "0.00%", 16);
		accuracyText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF00FFFF, LEFT);
		add(accuracyText);

		gradeIcon = new EmojiText(showcaseWidth - 70, scoreY + 20, 48, "🎵", 0);
		gradeIcon.emojiScale = 0.9;
		add(gradeIcon);
		
		gradeText = new FlxText(showcaseWidth - 80, scoreY + 52, 60, "N/A", 14);
		gradeText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFD700, CENTER);
		add(gradeText);

		var diffY = scoreY + 88;

		diffPanelGlow = new FlxSprite(13, diffY - 2).makeGraphic(showcaseWidth - 26, 57, FlxColor.WHITE);
		diffPanelGlow.color = 0xFFFFD700;
		diffPanelGlow.alpha = 0.04;
		add(diffPanelGlow);

		diffPanel = new FlxSprite(15, diffY).makeGraphic(showcaseWidth - 30, 53, FlxColor.WHITE);
		diffPanel.color = FlxColor.BLACK;
		diffPanel.alpha = 0.53;
		add(diffPanel);

		diffLabel = new FlxText(25, diffY + 5, 100, "◈ DIFFICULTY", 12);
		diffLabel.setFormat(Paths.font("vcr.ttf"), 12, 0xFFFFD700, LEFT);
		add(diffLabel);

		diffText = new FlxText(25, diffY + 22, showcaseWidth - 60, "< NORMAL >", 22);
		diffText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFD700, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diffText.borderSize = 2;
		add(diffText);

		var statY = diffY + 62;

		statsPanel = new FlxSprite(15, statY).makeGraphic(showcaseWidth - 30, 85, FlxColor.WHITE);
		statsPanel.color = FlxColor.BLACK;
		statsPanel.alpha = 0.53;
		add(statsPanel);

		var statBorder = new FlxSprite(15, statY).makeGraphic(showcaseWidth - 30, 2, FlxColor.WHITE);
		statBorder.color = 0xFF00FF87;
		statBorder.alpha = 0.4;
		add(statBorder);

		var statLabel = new FlxText(25, statY + 5, 100, "◈ STATISTICS", 12);
		statLabel.setFormat(Paths.font("vcr.ttf"), 12, 0xFF00FF87, LEFT);
		add(statLabel);

		var statsEmoji1 = new EmojiText(25, statY + 22, 28, "📊", 0);
		statsEmoji1.emojiScale = 0.45;
		add(statsEmoji1);
		var statsEmoji2 = new EmojiText(25, statY + 40, 28, "⭐", 0);
		statsEmoji2.emojiScale = 0.45;
		add(statsEmoji2);
		var statsEmoji3 = new EmojiText(25, statY + 58, 28, "✓", 0);
		add(statsEmoji3);

		totalSongsText = new FlxText(50, statY + 22, showcaseWidth - 75, "Total: 0", 14);
		totalSongsText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(totalSongsText);

		favCountText = new FlxText(50, statY + 40, showcaseWidth - 75, "Favorites: 0", 14);
		favCountText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFD700, LEFT);
		add(favCountText);

		completionText = new FlxText(50, statY + 58, showcaseWidth - 75, "Completed: 0%", 14);
		completionText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF00FF87, LEFT);
		add(completionText);

		scoreBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		scoreBG.visible = false;
		add(scoreBG);

		missesText = new FlxText(25, statY + 76, showcaseWidth - 60, "", 12);
		missesText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		add(missesText);
	}

	function createSearchSystem()
	{
		searchGroup = new FlxSpriteGroup();
		searchGroup.visible = false;
		
		searchScreenBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		searchScreenBG.alpha = 0.85;
		searchGroup.add(searchScreenBG);

		searchScreenTitle = new FlxText(0, FlxG.height / 2 - 80, FlxG.width, "SEARCH SONG", 32);
		searchScreenTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		searchScreenTitle.borderSize = 2;
		searchGroup.add(searchScreenTitle);

		spotlightSearchBox = new PsychUIInputText(FlxG.width / 2 - 300, FlxG.height / 2 - 25, 600, "", 32);
		spotlightSearchBox.onChange = function(old:String, newText:String)
		{
			updateList();
		};
		searchGroup.add(spotlightSearchBox);
		
		add(searchGroup);
	}

	function openSearchScreen()
	{
		searchScreenWait = true;
		searchGroup.visible = true;
		
		searchGroup.alpha = 0;
		FlxTween.cancelTweensOf(searchGroup);
		FlxTween.tween(searchGroup, {alpha: 1}, 0.2);

		PsychUIInputText.focusOn = spotlightSearchBox;
		spotlightSearchBox.caretIndex = spotlightSearchBox.text.length;
	}

	function closeSearchScreen()
	{
		searchScreenWait = false;
		PsychUIInputText.focusOn = null;
		
		FlxTween.cancelTweensOf(searchGroup);
		FlxTween.tween(searchGroup, {alpha: 0}, 0.2, {
			onComplete: function(t) {
				searchGroup.visible = false;
			}
		});
		updateList();
	}

	function createSelectionMenu()
	{
		menuContainer = new FlxSpriteGroup();
		menuContainer.visible = false;

		bottomBG = new FlxSprite(0, FlxG.height - 35).makeGraphic(FlxG.width, 35, FlxColor.WHITE);
		bottomBG.color = FlxColor.BLACK;
		bottomBG.alpha = 0.8;
		add(bottomBG);

		bottomText = new FlxText(50, FlxG.height - 28, FlxG.width - 100, "", 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(bottomText);
		
		bottomString = controls.mobileC ? "A: Select  B: Back  X: Play  Y: Category  Z: Search  F: Fav  H: Hide" : "ENTER: Select  ESC: Back  SPACE: Play  TAB: Category  F: Search  G: Fav  H: Hide";
		bottomText.text = bottomString;

		menuSelectionGlow = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.WHITE);
		menuSelectionGlow.color = accentColor;
		menuSelectionGlow.alpha = 0.08;
		menuSelectionGlow.origin.set(0, 0);
		menuContainer.add(menuSelectionGlow);

		menuSelectionBar = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.WHITE);
		menuSelectionBar.color = accentColor;
		menuSelectionBar.origin.set(0, 0);
		menuContainer.add(menuSelectionBar);

		diffSelect = new Alphabet(0, 0, "< NORMAL >", true);
		diffSelect.setScale(0.7);
		menuContainer.add(diffSelect);

		modifiersSelect = new Alphabet(0, 0, "GAMEPLAY MODIFIERS", true);
		modifiersSelect.setScale(0.6);
		menuContainer.add(modifiersSelect);

		resetSelect = new Alphabet(0, 0, "RESET SCORE", true);
		resetSelect.setScale(0.6);
		menuContainer.add(resetSelect);

		backSelect = new Alphabet(0, 0, "BACK", true);
		backSelect.setScale(0.6);
		menuContainer.add(backSelect);

		add(menuContainer);
	}

	function playEntranceAnimation()
	{
		showcasePanel.x = -showcaseWidth;
		FlxTween.tween(showcasePanel, {x: 0}, 0.6, {ease: FlxEase.backOut});

		if (showcasePanelGlow != null)
		{
			showcasePanelGlow.x = -showcaseWidth;
			FlxTween.tween(showcasePanelGlow, {x: -1}, 0.6, {ease: FlxEase.backOut});
		}

		topBar.y = -60;
		FlxTween.tween(topBar, {y: 0}, 0.5, {ease: FlxEase.backOut, startDelay: 0.1});

		scorePanel.scale.set(0, 0);
		FlxTween.tween(scorePanel.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.backOut, startDelay: 0.3});

		diffPanel.scale.set(0, 0);
		FlxTween.tween(diffPanel.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.backOut, startDelay: 0.4});

		statsPanel.scale.set(0, 0);
		FlxTween.tween(statsPanel.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.backOut, startDelay: 0.5});

		FlxG.camera.fade(FlxColor.BLACK, 0.3, true);
	}

	function updateQuickStats()
	{
		totalSongsText.text = "Total: " + allSongs.length;
		favCountText.text   = "Favorites: " + favorites.length;

		var completed = 0;
		for (song in allSongs)
			if (Highscore.getScore(song.songName, 0) > 0) completed++;

		var percent = allSongs.length > 0 ? Math.floor((completed / allSongs.length) * 100) : 0;
		completionText.text = "Completed: " + percent + "%";
	}

	function updateList()
	{
		grpSongs.forEach(function(s:Alphabet) s.destroy());
		grpSongs.clear();
		grpIcons.forEach(function(i:HealthIcon) i.destroy());
		grpIcons.clear();

		songs = [];
		var query = spotlightSearchBox != null ? spotlightSearchBox.text.toLowerCase() : "";

		for (i in 0...allSongs.length)
		{
			var meta = allSongs[i];
			var name = meta.songName;
			var nameLower = name.toLowerCase();

			var matchSearch = (query.length == 0 || nameLower.indexOf(query) != -1 || meta.songCharacter.toLowerCase().indexOf(query) != -1);

			var matchCat = false;
			if (curCategory == 'All') matchCat = !hiddenSongs.contains(name);
			else if (curCategory == 'Favorites') matchCat = favorites.contains(name);
			else if (curCategory == 'Last Played') matchCat = recentPlays.contains(name);
			else if (curCategory == 'Hidden') matchCat = hiddenSongs.contains(name);

			if (matchSearch && matchCat) songs.push(meta);
		}

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(showcaseWidth + 30, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			var maxWidth:Float = FlxG.width - showcaseWidth - 300;
			songText.scaleX = Math.min(0.8, maxWidth / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			
			if (favorites.contains(songs[i].songName))
				songText.color = 0xFFFFD700;

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			grpIcons.add(icon);
		}

		songCountText.text = songs.length + " Songs";
		if (songs.length > 0)
		{
			if (curSelected >= songs.length) curSelected = Std.int(Math.max(0, songs.length - 1));
			if (curSelected < 0) curSelected = 0;
			changeSelection(0, false);
		}
		else
		{
			curSelected = -1;
			changeSelection(0, false);
		}
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		if (selected) changeDiff();
		persistentUpdate = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'FREEPLAY');
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);
		if (opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function showMobileTip(msg:String)
	{
		mobileTipText.text = msg;
		FlxTween.cancelTweensOf(mobileTipBG);
		FlxTween.cancelTweensOf(mobileTipText);
		mobileTipBG.alpha = 0.85;
		mobileTipText.alpha = 1;
		FlxTween.tween(mobileTipBG, {alpha: 0}, 2.5, {startDelay: 1.0});
		FlxTween.tween(mobileTipText, {alpha: 0}, 2.5, {startDelay: 1.0});
	}

	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1) return;

		ambientPulse += elapsed;
		breathingEffect += elapsed * 2;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		pulseTimer += elapsed;
		if (!selected)
			titleText.scale.set(1 + Math.sin(pulseTimer * 2) * 0.02, 1 + Math.sin(pulseTimer * 2) * 0.02);

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) ratingSplit.push('');
		while (ratingSplit[1].length < 2) ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if ((FlxG.keys.pressed.SHIFT || mobilePadPressed("Z")) && !player.playingMusic && !searchScreenWait) shiftMult = 3;

		updateAmbientEffects(elapsed);
		updateBeatIcon(elapsed);

		if (showcasePanelGlow != null)
			showcasePanelGlow.alpha = 0.03 + Math.sin(ambientPulse * 1.5) * 0.02;
		if (scorePanelGlow != null)
			scorePanelGlow.alpha = 0.04 + Math.sin(ambientPulse * 2) * 0.02;
		if (topBarGlow != null)
			topBarGlow.alpha = 0.03 + Math.sin(ambientPulse) * 0.02;

		if (searchScreenWait)
		{
			if (FlxG.keys.justPressed.ENTER || mobilePadJustPressed("A")) closeSearchScreen();
			else if (FlxG.keys.justPressed.ESCAPE || mobilePadJustPressed("B")) {
				spotlightSearchBox.text = "";
				closeSearchScreen();
			}
			updateTexts(elapsed);
			super.update(elapsed);
			return;
		}

		if (selected)
		{
			handleSelectedMenu(elapsed);
			updateMenuPositions(elapsed);
			updateTexts(elapsed);
			super.update(elapsed);
			return;
		}

		if (!player.playingMusic)
		{
			if (FlxG.keys.justPressed.F || mobilePadJustPressed("Z"))
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				openSearchScreen();
				if (controls.mobileC) showMobileTip("🔍 Search — A: Apply  B: Close");
			}

			if (FlxG.keys.justPressed.TAB || mobilePadJustPressed("Y"))
			{
				curCategoryIndex = (curCategoryIndex + 1) % categories.length;
				curCategory = categories[curCategoryIndex];
				updateTabVisuals();
				FlxG.sound.play(Paths.sound('scrollMenu'));
				updateList();
				updateQuickStats();

				if (controls.mobileC)
					showMobileTip("📂 Category: " + curCategory);
			}
			
			var pressedFav = FlxG.keys.justPressed.G || mobilePadJustPressed("F");
			var pressedHide = FlxG.keys.justPressed.H || mobilePadJustPressed("H");

			if (pressedFav && songs.length > 0 && curSelected >= 0)
			{
				toggleFavorite();
			}

			if (pressedHide && songs.length > 0 && curSelected >= 0)
			{
				toggleHidden();
			}

			if (curSelected == -1)
				scoreText.text = "🎲 RANDOM";
			else
				scoreText.text = "" + lerpScore;
			accuracyText.text = ratingSplit.join('.') + "%";

			updateGrade();

			if (songs.length > 0)
			{
				if (FlxG.keys.justPressed.HOME) { curSelected = -1; changeSelection(); holdTime = 0; }
				else if (FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;
				}

				if (controls.UI_UP_P) { changeSelection(-shiftMult); holdTime = 0; }
				if (controls.UI_DOWN_P) { changeSelection(shiftMult); holdTime = 0; }

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (curSelected >= 0)
			{
				if (controls.UI_LEFT_P) { changeDiff(-1); _updateSongLastDifficulty(); }
				else if (controls.UI_RIGHT_P) { changeDiff(1); _updateSongLastDifficulty(); }
			}
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				ThemeManager.switchToMainMenu();
			}
		}

		if ((FlxG.keys.justPressed.SPACE || mobilePadJustPressed("X")) && !player.playingMusic)
		{
			if (curSelected == -1)
			{
				var newSel = FlxG.random.int(0, songs.length - 1);
				curSelected = newSel;
				changeSelection();
				return;
			}

			if (songs.length == 0) return;

			if (instPlaying != curSelected)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if (loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);

						if (loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch (e:Dynamic) { vocals = FlxDestroyUtil.destroy(vocals); }

					opponentVocals = new FlxSound();
					try
					{
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');

						if (loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch (e:Dynamic) { opponentVocals = FlxDestroyUtil.destroy(opponentVocals); }
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && player.playingMusic)
				player.pauseOrResume(!player.playing);
		}
		
		else if (controls.ACCEPT && !player.playingMusic)
		{
			if (songs.length == 0) return;

			if (curSelected == -1)
			{
				var newSel = FlxG.random.int(0, songs.length - 1);
				curSelected = newSel;
				changeSelection();
				lerpSelected = curSelected;
			}

			openSelectionMenu();
		}

		if ((FlxG.keys.justPressed.CONTROL || mobilePadJustPressed("C")) && !player.playingMusic && !searchScreenWait)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
			removeTouchPad();
		}

		var mobileReset:Bool = mobilePadPressed("C") && mobilePadJustPressed("A");
		if ((controls.RESET || mobileReset) && !player.playingMusic && songs.length > 0 && curSelected >= 0)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			removeTouchPad();
			FlxG.sound.play(Paths.sound('scrollMenu'));

			if (controls.mobileC) showMobileTip("🗑 Resetting SCORE...");
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	function toggleFavorite()
	{
		if (songs.length == 0 || curSelected < 0) return;
		
		var song = songs[curSelected].songName;
		var item = grpSongs.members[curSelected];

		if (favorites.contains(song))
		{
			favorites.remove(song);
			if (curCategory != 'Favorites') item.color = FlxColor.WHITE;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			if (controls.mobileC) showMobileTip("Removed from favorites: " + song);
		}
		else
		{
			favorites.push(song);
			if (curCategory != 'Favorites') item.color = 0xFFFFD700;
			FlxG.sound.play(Paths.sound('fav'), 0.8);
			if (controls.mobileC) showMobileTip("Added to Favorites: " + song);

			for (i in 0...5)
			{
				var star = new FlxSprite(item.x + item.width / 2, item.y + item.height / 2);
				star.makeGraphic(6, 6, 0xFFFFD700);
				star.velocity.set(FlxG.random.float(-80, 80), FlxG.random.float(-120, -40));
				star.acceleration.y = 180;
				add(star);
				FlxTween.tween(star, {alpha: 0}, 0.8, {
					onComplete: function(t) star.destroy()
				});
			}
		}

		FlxG.save.data.favorites = favorites;
		FlxG.save.flush();
		updateQuickStats();
		
		if (curCategory == 'Favorites')
		{
			updateList();
		}
	}
	
	function toggleHidden()
	{
		if (songs.length == 0 || curSelected < 0) return;
		
		var song = songs[curSelected].songName;

		if (hiddenSongs.contains(song))
		{
			hiddenSongs.remove(song);
			if (controls.mobileC) showMobileTip("👁 Removed from Hiddens: " + song);
		}
		else
		{
			hiddenSongs.push(song);
			if (controls.mobileC) showMobileTip("🙈 Added Hiddens: " + song);
		}

		FlxG.save.data.hiddenSongs = hiddenSongs;
		FlxG.save.flush();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		updateQuickStats();
		
		if (curCategory == 'Hidden' || curCategory == 'All')
		{
			updateList();
		}
	}

	function updateBeatIcon(elapsed:Float)
	{
		if (selected && PlayState.SONG != null && PlayState.SONG.bpm > 0)
			beatBPM = PlayState.SONG.bpm;
		else
			beatBPM = 100;

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			var musicTime = FlxG.sound.music.time / 1000.0;
			var beatInterval = 60.0 / beatBPM;
			var currentBeat = Math.floor(musicTime / beatInterval);

			if (currentBeat != Math.floor(lastBeatTime / beatInterval))
			{
				lastBeatTime = musicTime;

				if (showcaseIcon != null)
				{
					FlxTween.cancelTweensOf(showcaseIcon.scale);
					showcaseIcon.scale.set(1.2, 1.2);
					FlxTween.tween(showcaseIcon.scale, {x: 1, y: 1}, beatInterval * 0.5, {ease: FlxEase.quartOut});
				}

				if (scorePanelGlow != null)
				{
					scorePanelGlow.alpha = 0.15;
					FlxTween.cancelTweensOf(scorePanelGlow);
					FlxTween.tween(scorePanelGlow, {alpha: 0.04}, beatInterval * 0.5);
				}
			}

			lastBeatTime = musicTime;
		}
		else
		{
			iconBeatScale = 1.0 + Math.sin(breathingEffect) * 0.02;
			if (showcaseIcon != null)
				showcaseIcon.scale.set(iconBeatScale, iconBeatScale);
		}
	}

	function updateAmbientEffects(elapsed:Float)
	{
		for (i in 0...floatingOrbs.length)
		{
			var orb = floatingOrbs[i];
			orb.y += Math.sin(ambientPulse + i) * 0.3;
			orb.x += Math.cos(ambientPulse * 0.5 + i) * 0.2;
			orb.alpha = 0.02 + Math.sin(ambientPulse + i * 0.5) * 0.02;
			if (orb.x < 0) orb.x = FlxG.width - 30;
			if (orb.x > FlxG.width) orb.x = 5;
			if (orb.y < 0) orb.y = FlxG.height - 30;
			if (orb.y > FlxG.height) orb.y = 5;
		}
	}

	function updateGrade()
	{
		var rating = lerpRating * 100;
		if (curSelected == -1 || intendedScore == 0)
		{
			gradeText.text = "N/A";
			gradeIcon.setText("🎵");
			gradeText.color = 0xFF888888;
		}
		else if (rating >= 100) { gradeText.text = "S+"; gradeIcon.setText("👑"); gradeText.color = 0xFFFFD700; }
		else if (rating >= 95)  { gradeText.text = "S";  gradeIcon.setText("⭐"); gradeText.color = 0xFFFFD700; }
		else if (rating >= 90)  { gradeText.text = "A";  gradeIcon.setText("🏆"); gradeText.color = 0xFF00FF87; }
		else if (rating >= 80)  { gradeText.text = "B";  gradeIcon.setText("✨"); gradeText.color = 0xFF00FFFF; }
		else if (rating >= 70)  { gradeText.text = "C";  gradeIcon.setText("📊"); gradeText.color = 0xFFFFD700; }
		else					{ gradeText.text = "D";  gradeIcon.setText("📉"); gradeText.color = 0xFFFF5555; }
	}

	function openSelectionMenu()
	{
		selected = true;
		selectedItem = 0;
		menuContainer.visible = true;

		if (curSelected >= 0 && curSelected < songs.length)
		{
			loadSongBackground(songs[curSelected].songName);
		}

		FlxTween.cancelTweensOf(menuBG);
		FlxTween.tween(menuBG, {alpha: 0.85}, 0.3);
		FlxTween.cancelTweensOf(songBG);
		FlxTween.tween(songBG, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});

		diffSelect.alpha = 0;
		FlxTween.tween(diffSelect, {alpha: 1}, 0.2, {startDelay: 0.3});
		modifiersSelect.alpha = 0;
		FlxTween.tween(modifiersSelect, {alpha: 0.6}, 0.2, {startDelay: 0.35});
		resetSelect.alpha = 0;
		FlxTween.tween(resetSelect, {alpha: 0.6}, 0.2, {startDelay: 0.4});
		backSelect.alpha = 0;
		FlxTween.tween(backSelect, {alpha: 0.6}, 0.2, {startDelay: 0.45});

		if (curSelected >= 0 && curSelected < grpSongs.members.length)
		{
			var selectedSong:Alphabet = grpSongs.members[curSelected];
			var selectedIcon:HealthIcon = grpIcons.members[curSelected];
			var rightSpaceCenter = showcaseWidth + (FlxG.width - showcaseWidth) / 2;

			FlxTween.cancelTweensOf(selectedSong);
			FlxTween.cancelTweensOf(selectedIcon);
			FlxTween.cancelTweensOf(selectedIcon.scale);
			
			FlxTween.tween(selectedSong, { x: rightSpaceCenter - selectedSong.width / 2, y: 150 }, 0.5, {ease: FlxEase.quartOut});
			FlxTween.tween(selectedIcon, { x: rightSpaceCenter + selectedSong.width / 2 + 10, y: 140 }, 0.5, {ease: FlxEase.quartOut});
			FlxTween.tween(selectedIcon.scale, {x: 1.3, y: 1.3}, 0.5, {ease: FlxEase.quartOut});
		}

		if (curSelected >= 0 && songs.length > 0 && instPlaying != curSelected)
		{
			destroyFreeplayVocals();
			FlxG.sound.music.volume = 0;

			Mods.currentModDirectory = songs[curSelected].folder;
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			try
			{
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if (loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						if (loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch (e:Dynamic) { vocals = FlxDestroyUtil.destroy(vocals); }

					opponentVocals = new FlxSound();
					try
					{
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						if (loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch (e:Dynamic) { opponentVocals = FlxDestroyUtil.destroy(opponentVocals); }
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				instPlaying = curSelected;
			}
			catch (e:Dynamic) {}
		}

		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);

		removeTouchPad();
		addTouchPad('LEFT_FULL', 'FREEPLAY');

		if (controls.mobileC)
			showMobileTip("↕ Select  A: Enter  B: Back  ←/→: Diff");
			
		updateMenuPositions(0);
		updateMenuSelection();
	}

	function closeSelectionMenu()
	{
		selected = false;
		selectedItem = 0;

		FlxTween.cancelTweensOf(menuBG);
		FlxTween.cancelTweensOf(songBG);
		FlxTween.tween(menuBG, {alpha: 0}, 0.2, {
			onComplete: function(t) { menuContainer.visible = false; }
		});
		FlxTween.tween(songBG, {alpha: 0}, 0.3);

		if (curSelected >= 0 && curSelected < grpSongs.members.length)
		{
			var selectedSong:Alphabet = grpSongs.members[curSelected];
			var selectedIcon:HealthIcon = grpIcons.members[curSelected];
			
			FlxTween.cancelTweensOf(selectedSong);
			FlxTween.cancelTweensOf(selectedIcon);
			FlxTween.cancelTweensOf(selectedIcon.scale);
			FlxTween.tween(selectedIcon.scale, {x: 1.15, y: 1.15}, 0.3, {ease: FlxEase.quartOut});
		}

		if (player.playingMusic)
		{
			FlxG.sound.music.stop();
			destroyFreeplayVocals();
			FlxG.sound.music.volume = 0;
			instPlaying = -1;
			player.playingMusic = false;
			player.switchPlayMusic();
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
		}

		FlxG.sound.play(Paths.sound('cancelMenu'));

		removeTouchPad();
		addTouchPad('LEFT_FULL', 'FREEPLAY');
	}

	function loadSongBackground(songName:String)
	{
		var bgPath = 'songbg/' + Paths.formatToSongPath(songName);

		if (Paths.image(bgPath) != null)
		{
			songBG.loadGraphic(Paths.image(bgPath));
			songBG.setGraphicSize(FlxG.width, FlxG.height);
			songBG.updateHitbox();
			songBG.screenCenter();
		}
		else
		{
			songBG.makeGraphic(FlxG.width, FlxG.height, songs[curSelected].color);
		}
		songBG.alpha = 0;
	}

	function handleSelectedMenu(elapsed:Float)
	{
		if (controls.BACK) { closeSelectionMenu(); return; }

		if (controls.UI_UP_P)
		{
			selectedItem--;
			if (selectedItem < 0) selectedItem = 3;
			updateMenuSelection();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		else if (controls.UI_DOWN_P)
		{
			selectedItem++;
			if (selectedItem > 3) selectedItem = 0;
			updateMenuSelection();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (selectedItem == 0)
		{
			if (controls.UI_LEFT_P) { changeDiff(-1); _updateSongLastDifficulty(); }
			else if (controls.UI_RIGHT_P) { changeDiff(1); _updateSongLastDifficulty(); }
		}

		if (controls.ACCEPT)
		{
			switch (selectedItem)
			{
				case 0: enterSong();
				case 1:
					persistentUpdate = false;
					openSubState(new GameplayChangersSubstate());
					removeTouchPad();
				case 2:
					persistentUpdate = false;
					openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
					removeTouchPad();
					FlxG.sound.play(Paths.sound('scrollMenu'));
				case 3: closeSelectionMenu();
			}
		}
	}

	function updateMenuSelection()
	{
		FlxTween.cancelTweensOf(diffSelect);
		FlxTween.cancelTweensOf(modifiersSelect);
		FlxTween.cancelTweensOf(resetSelect);
		FlxTween.cancelTweensOf(backSelect);

		var items = [diffSelect, modifiersSelect, resetSelect, backSelect];
		for (i in 0...items.length)
		{
			var targetAlpha = (i == selectedItem) ? 1.0 : 0.4;
			var targetScale = (i == selectedItem) ? (i == 0 ? 0.8 : 0.7) : (i == 0 ? 0.7 : 0.55);

			FlxTween.tween(items[i], {alpha: targetAlpha}, 0.15);
			FlxTween.tween(items[i].scale, {x: targetScale, y: targetScale}, 0.15, {ease: FlxEase.backOut});
		}

		if (menuSelectionGlow != null && selectedItem < items.length)
		{
			var targetItem = items[selectedItem];
			
			var targetWidth = targetItem.width + 60;
			var targetHeight = targetItem.height + 20;

			var targetX = targetItem.x - 30;
			var targetY = targetItem.y - 10;

			FlxTween.cancelTweensOf(menuSelectionGlow);
			FlxTween.tween(menuSelectionGlow, { x: targetX, y: targetY }, 0.15, {ease: FlxEase.quartOut});
			
			FlxTween.cancelTweensOf(menuSelectionGlow.scale);
			FlxTween.tween(menuSelectionGlow.scale, { x: targetWidth, y: targetHeight }, 0.15, {ease: FlxEase.quartOut});

			FlxTween.cancelTweensOf(menuSelectionBar);
			FlxTween.tween(menuSelectionBar, { x: targetX + 10, y: targetY }, 0.15, {ease: FlxEase.quartOut});
			
			FlxTween.cancelTweensOf(menuSelectionBar.scale);
			FlxTween.tween(menuSelectionBar.scale, { x: 6, y: targetHeight }, 0.15, {ease: FlxEase.quartOut});
		}
	}

	function updateMenuPositions(elapsed:Float)
	{
		var rightSpaceCenter = showcaseWidth + (FlxG.width - showcaseWidth) / 2;
		var startY = 320;
		var spacing = 65;

		diffSelect.x = rightSpaceCenter - diffSelect.width / 2;
		diffSelect.y = startY;

		modifiersSelect.x = rightSpaceCenter - modifiersSelect.width / 2;
		modifiersSelect.y = startY + spacing;

		resetSelect.x = rightSpaceCenter - resetSelect.width / 2;
		resetSelect.y = startY + spacing * 2;

		backSelect.x = rightSpaceCenter - backSelect.width / 2;
		backSelect.y = startY + spacing * 3;
	}

	function enterSong()
	{
		if (songs.length == 0 || curSelected < 0) return;

		var songName = songs[curSelected].songName;
		if (!recentPlays.contains(songName))
		{
			recentPlays.insert(0, songName);
			if (recentPlays.length > 10) recentPlays.pop();
			FlxG.save.data.recentPlays = recentPlays;
			FlxG.save.flush();
		}

		persistentUpdate = false;
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

		try
		{
			Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
		}
		catch (e:haxe.Exception)
		{
			var errorStr:String = e.message;
			if (errorStr.contains('There is no TEXT asset with an ID of'))
				errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1);
			else
				errorStr += '\n\n' + e.stack;

			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		@:privateAccess
		if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			Paths.freeGraphicsFromMemory();

		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		stopMusicPlay = true;

		destroyFreeplayVocals();
		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic || songs.length == 0 || curSelected < 0) return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);

		diffText.text = Difficulty.list.length > 1 ? '< ' + displayDiff.toUpperCase() + ' >' : displayDiff.toUpperCase();
		diffSelect.text = diffText.text;

		switch (displayDiff.toLowerCase())
		{
			case 'kolay':  diffText.color = 0xFF00FF87;
			case 'normal': diffText.color = 0xFFFFD700;
			case 'zor':	diffText.color = 0xFFFF4444;
			default:	   diffText.color = FlxColor.WHITE;
		}

		FlxTween.cancelTweensOf(diffText.scale);
		diffText.scale.set(1.2, 1.2);
		FlxTween.tween(diffText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

		missingText.visible = missingTextBG.visible = false;
	}

	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic || songs.length == 0) return;

		curSelected += change;
		if (curSelected < -1) curSelected = songs.length - 1;
		if (curSelected >= songs.length) curSelected = -1;

		if (curSelected >= 0) _updateSongLastDifficulty();
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var unknownImg = Paths.image('unknownMod');
		if (unknownImg != null) {
			showcaseIcon.loadGraphic(unknownImg);
			showcaseIcon.setGraphicSize(120, 120);
			showcaseIcon.updateHitbox();
		}

		if (curSelected == -1)
		{
			intendedScore = 0;
			intendedRating = 0;

			showcaseTitle.text = "RANDOM";
			showcaseSubtitle.text = "Random song!";
		}
		else
		{
			var newColor:Int = songs[curSelected].color;
			if (newColor != intendedColor)
			{
				intendedColor = newColor;
				FlxTween.cancelTweensOf(bg);
				FlxTween.color(bg, 0.8, bg.color, intendedColor, {ease: FlxEase.quadOut});
				FlxTween.color(topBarLine, 0.3, topBarLine.color, intendedColor);
				FlxTween.color(showcaseBorder, 0.3, showcaseBorder.color, intendedColor);
			}

			var charIcon = songs[curSelected].songCharacter;
			if (charIcon != null && charIcon.length > 0)
			{
				var iconPath = Paths.image('icons/icon-' + charIcon);
				if (iconPath != null)
				{
					showcaseIcon.loadGraphic(iconPath, true, 150, 150);
					showcaseIcon.animation.add("idle", [0], 0, false);
					showcaseIcon.animation.play("idle");
				}
				else
				{
					showcaseIcon.loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
					showcaseIcon.animation.add("idle", [0], 0, false);
					showcaseIcon.animation.play("idle");
				}
				showcaseIcon.setGraphicSize(120, 120);
				showcaseIcon.updateHitbox();
			}

			showcaseTitle.text = songs[curSelected].songName;
			showcaseSubtitle.text = "Week " + (songs[curSelected].week + 1) + " • " + songs[curSelected].songCharacter;

			Mods.currentModDirectory = songs[curSelected].folder;
			PlayState.storyWeek = songs[curSelected].week;
			Difficulty.loadFromWeek();

			var savedDiff:String = songs[curSelected].lastDifficulty;
			var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
			if (savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
				curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
			else if (lastDiff > -1)
				curDifficulty = lastDiff;
			else if (Difficulty.list.contains(Difficulty.getDefault()))
				curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
			else
				curDifficulty = 0;

			changeDiff();
			_updateSongLastDifficulty();
		}
	}

	inline private function _updateSongLastDifficulty()
	{
		if (songs.length > 0 && curSelected >= 0)
			songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
	}

	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		var rTargetX:Float = showcaseWidth + 30 + ((-1 - lerpSelected) * randomText.distancePerItem.x);
		var rTargetY:Float = 320 + ((-1 - lerpSelected) * 1.3 * randomText.distancePerItem.y);
		var rTargetAlpha:Float = 0.5;
		
		if (selected) {
			rTargetAlpha = 0.0;
			rTargetY += 200; 
		} else {
			if (curSelected == -1) rTargetAlpha = 1.0;
		}

		randomText.x = FlxMath.lerp(randomText.x, rTargetX, Math.exp(-elapsed * 9.6));
		randomText.y = FlxMath.lerp(randomText.y, rTargetY, Math.exp(-elapsed * 9.6));
		randomText.alpha = FlxMath.lerp(randomText.alpha, rTargetAlpha, Math.exp(-elapsed * 9.6));
		
		randomIcon.x = FlxMath.lerp(randomIcon.x, rTargetX + randomText.width + 10, Math.exp(-elapsed * 9.6));
		randomIcon.y = FlxMath.lerp(randomIcon.y, rTargetY - 10, Math.exp(-elapsed * 9.6));
		randomIcon.alpha = randomText.alpha;

		for (i in 0...grpSongs.members.length)
		{
			var item:Alphabet = grpSongs.members[i];
			var icon:HealthIcon = grpIcons.members[i];

			var isNear = Math.abs(i - lerpSelected) <= _drawDistance;
			
			var targetX:Float = showcaseWidth + 30 + ((item.targetY - lerpSelected) * item.distancePerItem.x);
			var targetY:Float = 320 + ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y);
			var targetIconX:Float = targetX + item.width + 10;
			var targetIconY:Float = targetY - 10;
			var targetAlpha:Float = 0.5;
			var targetIconScale:Float = 1.0;

			if (selected)
			{
				if (i == curSelected)
				{
					continue; // Let the manual tweens from openSelectionMenu handle this!
				}
				else
				{
					targetAlpha = 0.0;
					targetY += (i < curSelected) ? -200 : 200;
					targetIconY += (i < curSelected) ? -200 : 200;
				}
			}
			else
			{
				if (i == curSelected)
				{
					targetAlpha = 1.0;
					targetIconScale = 1.15;
				}
			}

			if (!isNear && !selected)
			{
				item.visible = false;
				icon.visible = false;
			}
			else
			{
				item.visible = true;
				icon.visible = true;

				item.x = FlxMath.lerp(item.x, targetX, Math.exp(-elapsed * 9.6));
				item.y = FlxMath.lerp(item.y, targetY, Math.exp(-elapsed * 9.6));
				item.alpha = FlxMath.lerp(item.alpha, targetAlpha, Math.exp(-elapsed * 9.6));

				icon.x = FlxMath.lerp(icon.x, targetIconX, Math.exp(-elapsed * 9.6));
				icon.y = FlxMath.lerp(icon.y, targetIconY, Math.exp(-elapsed * 9.6));
				icon.alpha = FlxMath.lerp(icon.alpha, targetAlpha, Math.exp(-elapsed * 9.6));
				
				icon.scale.x = FlxMath.lerp(icon.scale.x, targetIconScale, Math.exp(-elapsed * 9.6));
				icon.scale.y = FlxMath.lerp(icon.scale.y, targetIconScale, Math.exp(-elapsed * 9.6));
			}
		}
	}

	override function destroy():Void
	{
		super.destroy();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}
