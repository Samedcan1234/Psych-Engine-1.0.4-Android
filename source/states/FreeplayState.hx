package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.ThemeManager;
import backend.ClientPrefs; 

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
import lime.system.Clipboard;

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

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

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
	private var curPlaying:Bool = false;
	private var iconArray:Array<HealthIcon> = [];

	var randomText:Alphabet;
	var randomIcon:HealthIcon;

	var searchOverlay:FlxSprite;
	var searchPanel:FlxSprite;
	var searchPanelBorder:FlxSprite;
	var searchBox:PsychUIInputText;
	var searchContainer:FlxSpriteGroup;
	var searchIcon:FlxText;
	var searchResultText:FlxText;
	var searchActive:Bool = false;
	var searchHint:FlxText;

	var searchInputWait:Bool = false;
	var searchString:String = '';
	var searchInputText:FlxText;
	var searchInputBG:FlxSprite;

	var bottomBG:FlxSprite;
	var bottomBarLine:FlxSprite;
	public var bottomText:FlxText;
	public var bottomString:String;

	var selected:Bool = false;
	var selectedItem:Int = 0;
	var menuBG:FlxSprite;
	var menuContainer:FlxSpriteGroup;
	var menuInfoCard:FlxSprite;
	var menuInfoCardBorder:FlxSprite;
	var menuSongTitle:FlxText;
	var menuSongArtist:FlxText;
	var menuScoreDisplay:FlxText;
	var menuAccuracyDisplay:FlxText;
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
	var _lastVisibles:Array<Int> = [];
	var _drawDistance:Int = 4;

	var categoryIcons:Map<String, String> = [
		'All'         => '📂',
		'Favorites'   => '⭐',
		'Last Played' => '🕐',
		'Hidden'      => '👁️' 

	];

	var showcaseIconTargetY:Float = 0;

	var leftPanelX:Float = 0;
	var rightPanelX:Float = 0;
	var topBarY:Float = 0;
	var bottomBarY:Float = 0;

	var leftPanel:FlxSprite;
	var rightPanel:FlxSprite;
	var categoryText:FlxText;
	var categoryIcon:FlxText;
	var infoCard:FlxSprite;
	var scoreCard:FlxSprite;
	var difficultyCard:FlxSprite;
	var statsCard:FlxSprite;
	var catButtons:Array<FlxSprite> = [];
	var catButtonTexts:Array<FlxText> = [];

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

		if (FlxG.save.data.favorites != null)  favorites   = FlxG.save.data.favorites;
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

		bgOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x33000000);
		add(bgOverlay);

		songBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		songBG.alpha = 0;
		add(songBG);

		gradientTop = FlxGradient.createGradientFlxSprite(FlxG.width, 150,
			[0xCC000000, 0x88000000, 0x00000000], 1, 180);
		add(gradientTop);

		gradientBottom = FlxGradient.createGradientFlxSprite(FlxG.width, 150,
			[0x00000000, 0x88000000, 0xCC000000], 1, 180);
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
			var orb = new FlxSprite(FlxG.random.float(50, FlxG.width - 50),
				FlxG.random.float(80, FlxG.height - 80));
			orb.makeGraphic(Std.int(FlxG.random.float(12, 25)),
				Std.int(FlxG.random.float(12, 25)), accentColor);
			orb.alpha = FlxG.random.float(0.02, 0.06);
			add(orb);
			floatingOrbs.push(orb);
		}

		topBarGlow = new FlxSprite(0, 0).makeGraphic(FlxG.width, 58, accentColor);
		topBarGlow.alpha = 0.04;
		add(topBarGlow);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 55, 0xDD050510);
		add(topBar);

		topBarLine = new FlxSprite(0, 53).makeGraphic(FlxG.width, 2, accentColor);
		topBarLine.alpha = 0.5;
		add(topBarLine);

		topBarGradient = FlxGradient.createGradientFlxSprite(FlxG.width, 60,
			[0xDD050510, 0x88050510, 0x00050510], 1, 180);
		topBarGradient.y = 55;
		add(topBarGradient);

		titleIcon = new FlxText(18, 10, 40, "♪", 32);
		titleIcon.setFormat(Paths.font("vcr.ttf"), 32, accentColor, LEFT);
		add(titleIcon);

		titleText = new FlxText(50, 8, 250, Language.getPhrase('freeplay_title', 'FREEPLAY'), 30);
		titleText.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, 0xFF000000);
		titleText.borderSize = 2;
		add(titleText);

		var editionLabel = new FlxText(50, 38, 120, "XQ EDITION", 10);
		editionLabel.setFormat(Paths.font("vcr.ttf"), 10, accentColor, LEFT);
		add(editionLabel);

		songCountBadge = new FlxSprite(FlxG.width - 130, 15).makeGraphic(120, 26, accentColor);
		songCountBadge.alpha = 0.2;
		add(songCountBadge);

		songCountText = new FlxText(FlxG.width - 130, 18, 120,
			Language.getPhrase('freeplay_songs', 'Songs'), 14);
		songCountText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		add(songCountText);

		var hintStr:String = controls.mobileC
			? Language.getPhrase('freeplay_hint_mobile', 'Z: Search | Y: Filter')
			: Language.getPhrase('freeplay_hint_pc',     'F: Search | TAB: Filter');
		searchHint = new FlxText(FlxG.width - 280, 20, 140, hintStr, 11);
		searchHint.setFormat(Paths.font("vcr.ttf"), 11, 0xFF555555, RIGHT);
		add(searchHint);

		createShowcasePanel();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		randomText = new Alphabet(showcaseWidth + 30, 320, Language.getPhrase('freeplay_random', 'RANDOM'), true);
		randomText.targetY = -1;
		randomText.snapToPosition();
		add(randomText);

		randomIcon = new HealthIcon('bf');
		randomIcon.sprTracker = randomText;
		add(randomIcon);

		createTabBar();
		createSearchSystem();
		createSelectionMenu();

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.8;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		player = new MusicPlayer(this);
		add(player);

		mobileTipBG = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 34, 0xFF000000);
		mobileTipBG.alpha = 0;
		add(mobileTipBG);

		mobileTipText = new FlxText(0, FlxG.height - 66, FlxG.width, "", 14);
		mobileTipText.setFormat(Paths.font("vcr.ttf"), 14, accentColor, CENTER);
		mobileTipText.alpha = 0;
		add(mobileTipText);

		WeekData.setDirectoryFromWeek();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		updateList();
		updateQuickStats();

		if (curSelected >= songs.length) curSelected = -1;
		bg.color = (curSelected >= 0 && songs.length > 0) ? songs[curSelected].color : 0xFF0a0a18;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		changeSelection();
		updateTexts();

		playEntranceAnimation();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

		addTouchPad('LEFT_FULL', 'A_B_C_X_Y_Z');
	}

	function createTabBar()
	{
		var tabY      = 62;
		var tabH      = 30;
		var tabStartX = showcaseWidth + 30;
		var tabW      = 110;
		var tabGap    = 8;

		tabBar = new FlxSprite(tabStartX - 5, tabY - 3).makeGraphic(
			(tabW + tabGap) * categories.length + 10, tabH + 6, 0x33000000);
		add(tabBar);

		tabIndicator = new FlxSprite(tabStartX, tabY + tabH - 3).makeGraphic(tabW, 3, accentColor);
		tabIndicator.alpha = 0.8;

		for (i in 0...categories.length)
		{
			var tx = tabStartX + i * (tabW + tabGap);

			var glow = new FlxSprite(tx - 1, tabY - 1).makeGraphic(tabW + 2, tabH + 2, accentColor);
			glow.alpha = 0;
			add(glow);
			tabGlows.push(glow);

			var btn = new FlxSprite(tx, tabY).makeGraphic(tabW, tabH, 0x44000000);
			add(btn);
			tabButtons.push(btn);

			var categoryKey:String = 'freeplay_category_' + categories[i].toLowerCase().replace(' ', '_');
			var categoryTextStr:String = Language.getPhrase(categoryKey, categories[i]);

			var tabTxt = new FlxText(tx + 28, tabY + 8, tabW - 30, categoryTextStr, 13);
			tabTxt.setFormat(Paths.font("vcr.ttf"), 13, FlxColor.WHITE, LEFT);
			add(tabTxt);
			tabTexts.push(tabTxt);

			var iconStr = categoryIcons.exists(categories[i]) ? categoryIcons.get(categories[i]) : "📁";
			var tabEmoji = new EmojiText(tx + 6, tabY + 6, 24, iconStr, 0);
			tabEmoji.emojiScale = 0.28;
			add(tabEmoji);
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
				tabTexts[i].color   = FlxColor.WHITE;
				tabButtons[i].color = accentColor;
				tabButtons[i].alpha = 0.3;
				tabGlows[i].alpha   = 0.1;
			}
			else
			{
				tabTexts[i].color   = 0xFF888888;
				tabButtons[i].color = FlxColor.BLACK;
				tabButtons[i].alpha = 0.3;
				tabGlows[i].alpha   = 0;
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

		showcasePanelGlow = new FlxSprite(panelX - 1, panelY - 1).makeGraphic(
			showcaseWidth + 2, panelH + 2, accentColor);
		showcasePanelGlow.alpha = 0.04;
		add(showcasePanelGlow);

		showcasePanel = new FlxSprite(panelX, panelY).makeGraphic(showcaseWidth, panelH, 0xCC050510);
		add(showcasePanel);

		showcaseBorder = new FlxSprite(showcaseWidth - 2, panelY).makeGraphic(2, panelH, accentColor);
		showcaseBorder.alpha = 0.3;
		add(showcaseBorder);

		var iconY    = panelY + 20;
		var iconSize = 130;
		var iconCX   = Std.int(showcaseWidth / 2);

		showcaseIconGlow = new FlxSprite(iconCX - iconSize / 2 - 3, iconY - 3).makeGraphic(
			iconSize + 6, iconSize + 6, accentColor);
		showcaseIconGlow.alpha = 0.1;
		add(showcaseIconGlow);

		showcaseIconBG = new FlxSprite(iconCX - iconSize / 2, iconY).makeGraphic(iconSize, iconSize, 0xFF111122);
		add(showcaseIconBG);

		showcaseIcon = new FlxSprite(iconCX - iconSize / 2 + 5, iconY + 5);
		showcaseIcon.antialiasing = ClientPrefs.data.antialiasing;
		showcaseIcon.makeGraphic(120, 120, FlxColor.TRANSPARENT);
		add(showcaseIcon);

		showcaseIconFrame = new FlxSprite(iconCX - iconSize / 2, iconY).makeGraphic(iconSize, 2, accentColor);
		showcaseIconFrame.alpha = 0.5;
		add(showcaseIconFrame);

		var textStartY = iconY + iconSize + 15;

		showcaseTitle = new FlxText(15, textStartY, showcaseWidth - 30,
			Language.getPhrase('freeplay_song_name', 'SONG NAME'), 22);
		showcaseTitle.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, 0xFF000000);
		showcaseTitle.borderSize = 2;
		add(showcaseTitle);

		showcaseSubtitle = new FlxText(15, textStartY + 28, showcaseWidth - 30, "Artist", 14);
		showcaseSubtitle.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, CENTER);
		add(showcaseSubtitle);

		var scoreY = textStartY + 60;

		scorePanelGlow = new FlxSprite(13, scoreY - 2).makeGraphic(showcaseWidth - 26, 82, accentColor);
		scorePanelGlow.alpha = 0.05;
		add(scorePanelGlow);

		scorePanel = new FlxSprite(15, scoreY).makeGraphic(showcaseWidth - 30, 78, 0x88000000);
		add(scorePanel);

		var scorePanelBorder = new FlxSprite(15, scoreY).makeGraphic(showcaseWidth - 30, 2, accentColor);
		scorePanelBorder.alpha = 0.4;
		add(scorePanelBorder);

		scoreLabel = new FlxText(25, scoreY + 6, 100,
			Language.getPhrase('freeplay_score_label', '◈ SCORE'), 12);
		scoreLabel.setFormat(Paths.font("vcr.ttf"), 12, accentColor, LEFT);
		add(scoreLabel);

		scoreText = new FlxText(25, scoreY + 22, showcaseWidth - 60, "0", 28);
		scoreText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, 0xFF000000);
		scoreText.borderSize = 2;
		add(scoreText);

		accuracyText = new FlxText(25, scoreY + 54, 120, "0.00%", 16);
		accuracyText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF00FFFF, LEFT);
		add(accuracyText);

		gradeIcon = new EmojiText(showcaseWidth - 70, scoreY + 20, 48, "🎵", 0);
		gradeIcon.emojiScale = 0.9;
		add(gradeIcon);

		gradeText = new FlxText(showcaseWidth - 80, scoreY + 52, 60,
			Language.getPhrase('freeplay_grade_na', 'N/A'), 14);
		gradeText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFD700, CENTER);
		add(gradeText);

		var diffY = scoreY + 88;

		diffPanelGlow = new FlxSprite(13, diffY - 2).makeGraphic(showcaseWidth - 26, 57, 0xFFFFD700);
		diffPanelGlow.alpha = 0.04;
		add(diffPanelGlow);

		diffPanel = new FlxSprite(15, diffY).makeGraphic(showcaseWidth - 30, 53, 0x88000000);
		add(diffPanel);

		diffLabel = new FlxText(25, diffY + 5, 100,
			Language.getPhrase('freeplay_difficulty_label', '◈ DIFFICULTY'), 12);
		diffLabel.setFormat(Paths.font("vcr.ttf"), 12, 0xFFFFD700, LEFT);
		add(diffLabel);

		diffText = new FlxText(25, diffY + 22, showcaseWidth - 60, "< NORMAL >", 22);
		diffText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFD700, CENTER,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		diffText.borderSize = 2;
		add(diffText);

		var statY = diffY + 62;

		statsPanel = new FlxSprite(15, statY).makeGraphic(showcaseWidth - 30, 85, 0x88000000);
		add(statsPanel);

		var statBorder = new FlxSprite(15, statY).makeGraphic(showcaseWidth - 30, 2, 0xFF00FF87);
		statBorder.alpha = 0.4;
		add(statBorder);

		var statLabel = new FlxText(25, statY + 5, 100,
			Language.getPhrase('freeplay_stats_label', '◈ STATISTICS'), 12);
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

		totalSongsText = new FlxText(50, statY + 22, showcaseWidth - 75,
			Language.getPhrase('freeplay_stat_total', 'Total: 0'), 14);
		totalSongsText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		add(totalSongsText);

		favCountText = new FlxText(50, statY + 40, showcaseWidth - 75,
			Language.getPhrase('freeplay_stat_favorites', 'Favorites: 0'), 14);
		favCountText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFD700, LEFT);
		add(favCountText);

		completionText = new FlxText(50, statY + 58, showcaseWidth - 75,
			Language.getPhrase('freeplay_stat_completed', 'Completed: 0%'), 14);
		completionText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF00FF87, LEFT);
		add(completionText);

		scoreBG = new FlxSprite().makeGraphic(1, 1, 0x00000000);
		scoreBG.visible = false;
		add(scoreBG);

		missesText = new FlxText(25, statY + 76, showcaseWidth - 60, "", 12);
		missesText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		add(missesText);

		leftPanel      = showcasePanel;
		rightPanel     = showcasePanel;
		infoCard       = showcasePanel;
		scoreCard      = scorePanel;
		difficultyCard = diffPanel;
		statsCard      = statsPanel;
		categoryText   = new FlxText(0, 0, 0, "");
		categoryIcon   = new FlxText(0, 0, 0, "");
	}

	function createSearchSystem()
	{
		searchContainer = new FlxSpriteGroup();

		var sBG = new FlxSprite(showcaseWidth + 10, 15).makeGraphic(150, 30, 0x44000000);
		searchContainer.add(sBG);

		var sBorder = new FlxSprite(showcaseWidth + 10, 15).makeGraphic(150, 1, accentColor);
		sBorder.alpha = 0.2;
		searchContainer.add(sBorder);

		var searchEmojiIcon = new EmojiText(showcaseWidth + 14, 17, 28, "🔍", 0);
		searchEmojiIcon.emojiScale = 0.28;
		searchContainer.add(searchEmojiIcon);

		searchBox = new PsychUIInputText(Std.int(showcaseWidth + 38), 20, 115, "", 14);
		searchBox.onChange = function(old:String, newText:String)
		{
			updateList();
			updateSearchResults();
		};
		searchContainer.add(searchBox);

		searchResultText = new FlxText(showcaseWidth + 10, 48, 150, "", 11);
		searchResultText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF00FFFF, CENTER);
		searchResultText.alpha = 0;
		searchContainer.add(searchResultText);

		add(searchContainer);

		searchInputBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
		searchInputBG.visible = false;
		add(searchInputBG);

		searchInputText = new FlxText(FlxG.width / 2 - 250, FlxG.height / 2 - 25, 500, "", 28);
		searchInputText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER,
			FlxTextBorderStyle.OUTLINE, accentColor);
		searchInputText.borderSize = 2;
		searchInputText.visible = false;
		add(searchInputText);
	}

	function createSelectionMenu()
	{
		menuContainer = new FlxSpriteGroup();
		menuContainer.visible = false;

		menuBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
		menuBG.alpha = 0;
		add(menuBG);

		menuInfoCard = new FlxSprite(0, -500).makeGraphic(1, 1, 0x00000000);
		menuContainer.add(menuInfoCard);
		menuInfoCardBorder = new FlxSprite(0, -500).makeGraphic(1, 1, 0x00000000);
		menuContainer.add(menuInfoCardBorder);

		menuSongTitle = new FlxText(0, -500, 1, "", 1);
		menuSongTitle.visible = false;
		menuContainer.add(menuSongTitle);

		menuSongArtist = new FlxText(0, -500, 1, "", 1);
		menuSongArtist.visible = false;
		menuContainer.add(menuSongArtist);

		bottomBG = new FlxSprite(0, FlxG.height - 35).makeGraphic(FlxG.width, 35, FlxColor.BLACK);
		bottomBG.alpha = 0.8;
		add(bottomBG);

		bottomText = new FlxText(50, FlxG.height - 28, FlxG.width - 100, "", 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(bottomText);

		bottomString = controls.mobileC
			? Language.getPhrase('freeplay_controls_mobile', 'A: Select  B: Back  X: Play Song  Y: Category  Z: Search')
			: Language.getPhrase('freeplay_controls_pc',     'ENTER: Select  ESC: Back  SPACE: Play Song  TAB: Category  F: Search');
		bottomText.text = bottomString;

		menuScoreDisplay = new FlxText(0, -500, 1, "", 1);
		menuScoreDisplay.visible = false;
		menuContainer.add(menuScoreDisplay);

		menuAccuracyDisplay = new FlxText(0, -500, 1, "", 1);
		menuAccuracyDisplay.visible = false;
		menuContainer.add(menuAccuracyDisplay);

		menuSelectionGlow = new FlxSprite(0, 0).makeGraphic(400, 45, accentColor);
		menuSelectionGlow.alpha = 0.08;
		menuContainer.add(menuSelectionGlow);

		menuSelectionBar = new FlxSprite(0, 0).makeGraphic(4, 35, accentColor);
		menuContainer.add(menuSelectionBar);

		diffSelect = new Alphabet(0, 0, "< NORMAL >", true);
		diffSelect.setScale(0.7);
		menuContainer.add(diffSelect);

		modifiersSelect = new Alphabet(0, 0, Language.getPhrase('freeplay_menu_modifiers', 'GAMEPLAY MODIFIERS'), true);
		modifiersSelect.setScale(0.6);
		menuContainer.add(modifiersSelect);

		resetSelect = new Alphabet(0, 0, Language.getPhrase('freeplay_menu_reset', 'RESET SCORE'), true);
		resetSelect.setScale(0.6);
		menuContainer.add(resetSelect);

		backSelect = new Alphabet(0, 0, Language.getPhrase('freeplay_menu_back', 'BACK'), true);
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
		totalSongsText.text = Language.getPhrase('freeplay_stat_total', 'Total: ') + allSongs.length;
		favCountText.text   = Language.getPhrase('freeplay_stat_favorites', 'Favorites: ') + favorites.length;

		var completed = 0;
		for (song in allSongs)
			if (Highscore.getScore(song.songName, 0) > 0) completed++;

		var percent = allSongs.length > 0 ? Math.floor((completed / allSongs.length) * 100) : 0;
		completionText.text = Language.getPhrase('freeplay_stat_completed', 'Completed: ') + percent + "%";
	}

	function updateSearchResults()
	{
		if (searchBox.text.length > 0)
		{
			searchResultText.text  = songs.length + " " + Language.getPhrase('freeplay_result', 'result');
			searchResultText.alpha = 1;
			searchResultText.color = songs.length == 0 ? 0xFFFF4444 : 0xFF00FFFF;
		}
		else
			FlxTween.tween(searchResultText, {alpha: 0}, 0.3);

		songCountText.text = songs.length + " " + Language.getPhrase('freeplay_songs', 'Songs');
	}

	function updateList()
	{
		grpSongs.forEach(function(s:Alphabet) s.destroy());
		grpSongs.clear();
		for (icon in iconArray) icon.destroy();
		iconArray     = [];
		_lastVisibles = [];

		songs = [];
		var query = searchBox.text.toLowerCase();

		for (i in 0...allSongs.length)
		{
			var meta      = allSongs[i];
			var name      = meta.songName;
			var nameLower = name.toLowerCase();

			var matchSearch = (query.length == 0 || nameLower.indexOf(query) != -1
				|| meta.songCharacter.toLowerCase().indexOf(query) != -1);

			var matchCat = false;
			if (curCategory == 'All')              matchCat = !hiddenSongs.contains(name);
			else if (curCategory == 'Favorites')   matchCat = favorites.contains(name);
			else if (curCategory == 'Last Played') matchCat = recentPlays.contains(name);
			else if (curCategory == 'Hidden')      matchCat = hiddenSongs.contains(name);

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
			icon.sprTracker = songText;

			if (favorites.contains(songs[i].songName))
				songText.color = 0xFFFFD700;

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			iconArray.push(icon);
			add(icon);
		}

		songCountText.text = songs.length + " " + Language.getPhrase('freeplay_songs', 'Songs');
		if (curSelected >= songs.length) curSelected = songs.length > 0 ? 0 : -1;
		changeSelection(0, false);
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		if (selected) changeDiff();
		persistentUpdate = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C_X_Y_Z');
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore)
				|| !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
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
		mobileTipText.text  = msg;
		FlxTween.cancelTweensOf(mobileTipBG);
		FlxTween.cancelTweensOf(mobileTipText);
		mobileTipBG.alpha   = 0.85;
		mobileTipText.alpha = 1;
		FlxTween.tween(mobileTipBG,   {alpha: 0}, 2.5, {startDelay: 1.0});
		FlxTween.tween(mobileTipText, {alpha: 0}, 2.5, {startDelay: 1.0});
	}

	override function update(elapsed:Float)
	{
		if (WeekData.weeksList.length < 1) return;

		ambientPulse    += elapsed;
		breathingEffect += elapsed * 2;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore  = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)    lerpScore  = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

		pulseTimer += elapsed;
		if (!selected)
			titleText.scale.set(1 + Math.sin(pulseTimer * 2) * 0.02, 1 + Math.sin(pulseTimer * 2) * 0.02);

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) ratingSplit.push('');
		while (ratingSplit[1].length < 2) ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if ((FlxG.keys.pressed.SHIFT || touchPad.buttonZ.pressed) && !player.playingMusic) shiftMult = 3;

		updateAmbientEffects(elapsed);
		updateBeatIcon(elapsed);

		if (showcasePanelGlow != null)
			showcasePanelGlow.alpha = 0.03 + Math.sin(ambientPulse * 1.5) * 0.02;
		if (scorePanelGlow != null)
			scorePanelGlow.alpha    = 0.04 + Math.sin(ambientPulse * 2) * 0.02;
		if (topBarGlow != null)
			topBarGlow.alpha        = 0.03 + Math.sin(ambientPulse) * 0.02;

		if (searchInputWait)
		{
			searchInputText.visible = true;
			searchInputBG.visible   = true;
			searchInputText.text    = "🔍 " + Language.getPhrase('freeplay_search_prompt', 'SEARCH') + ": '" + searchString + "'_";

			if (touchPad.buttonA.justPressed)
			{
				searchInputWait = false;
				applySearch();
			}
			else if (touchPad.buttonB.justPressed)
			{
				searchInputWait = false;
				searchString    = '';
				applySearch();
			}

			updateTexts(elapsed);
			super.update(elapsed);
			return;
		}
		else
		{
			searchInputText.visible = false;
			searchInputBG.visible   = false;
		}

		if (selected && PsychUIInputText.focusOn != searchBox)
		{
			handleSelectedMenu(elapsed);
			updateMenuPositions(elapsed);
			super.update(elapsed);
			return;
		}

		if (PsychUIInputText.focusOn == searchBox)
		{
			if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE
				|| touchPad.buttonA.justPressed || touchPad.buttonB.justPressed)
			{
				PsychUIInputText.focusOn = null;
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		else if (!player.playingMusic)
		{
			if (FlxG.keys.justPressed.F || touchPad.buttonZ.justPressed)
			{
				searchInputWait = true;
				searchString    = '';
				FlxG.sound.play(Paths.sound('scrollMenu'));

				#if android
				lime.system.System.openURL("intent:#Intent;action=android.intent.action.INPUT_METHOD_PICKER;end");
				FlxG.stage.focus = cast(searchBox, openfl.display.InteractiveObject);
				#end

				if (controls.mobileC)
					showMobileTip(Language.getPhrase('freeplay_tip_search_mobile', '🔍 Search — A: Enter  B: Cancel'));
			}

			if (FlxG.keys.justPressed.C || touchPad.buttonC.justPressed)
			{
				PsychUIInputText.focusOn = searchBox;

				#if mobile
				FlxG.stage.focus = cast(searchBox, openfl.display.InteractiveObject);
				#end

				FlxG.sound.play(Paths.sound('scrollMenu'));
				if (controls.mobileC)
					showMobileTip(Language.getPhrase('freeplay_tip_searchbox_mobile', '⌨ Search box active — A/B: Close'));
			}

			if (FlxG.keys.justPressed.ESCAPE && searchBox.text.length > 0)
			{
				searchBox.text = "";
				updateList();
				updateSearchResults();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (FlxG.keys.justPressed.TAB || touchPad.buttonY.justPressed)
			{
				curCategoryIndex = (curCategoryIndex + 1) % categories.length;
				curCategory      = categories[curCategoryIndex];
				updateTabVisuals();
				FlxG.sound.play(Paths.sound('scrollMenu'));
				updateList();
				updateQuickStats();

				if (controls.mobileC)
					showMobileTip(Language.getPhrase('freeplay_tip_category', '📂 Category: ') + curCategory);
			}

			if (FlxG.keys.justPressed.G && songs.length > 0 && curSelected >= 0)
				toggleFavorite();

			if (FlxG.keys.justPressed.H && songs.length > 0 && curSelected >= 0)
				toggleHidden();

			if (touchPad.buttonC.pressed && touchPad.buttonY.justPressed
				&& songs.length > 0 && curSelected >= 0)
				toggleHidden();

			if (touchPad.buttonX.pressed && touchPad.buttonY.justPressed
				&& songs.length > 0 && curSelected >= 0)
				toggleFavorite();

			if (curSelected == -1)
				scoreText.text = "🎲 " + Language.getPhrase('freeplay_random', 'RANDOM');
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

				if (controls.UI_UP_P)   { changeSelection(-shiftMult); holdTime = 0; }
				if (controls.UI_DOWN_P) { changeSelection(shiftMult);  holdTime = 0; }

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int  = Math.floor((holdTime - 0.5) * 10);

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
				if (controls.UI_LEFT_P)       { changeDiff(-1); _updateSongLastDifficulty(); }
				else if (controls.UI_RIGHT_P) { changeDiff(1);  _updateSongLastDifficulty(); }
			}
		}

		if (controls.BACK && PsychUIInputText.focusOn != searchBox)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying             = -1;

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

		// Şarkıyı doğrudan başlatma tuşu
		if ((FlxG.keys.justPressed.SPACE || touchPad.buttonX.justPressed)
			&& PsychUIInputText.focusOn != searchBox && !player.playingMusic)
		{
			if (songs.length == 0) return;

			if (curSelected == -1) // RANDOM seçiliyse rastgele şarkı seç
			{
				var newSel = FlxG.random.int(0, songs.length - 1);
				curSelected = newSel;
				changeSelection();
				// Şarkı seçildikten sonra otomatik olarak menüyü aç
				openSelectionMenu();
				return;
			}
			
			// Şarkıyı doğrudan başlatmak yerine menüyü aç
			openSelectionMenu();
		}

		// Menüyü açma tuşu (ACCEPT)
		else if (controls.ACCEPT && !player.playingMusic && PsychUIInputText.focusOn != searchBox)
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

		if ((FlxG.keys.justPressed.CONTROL || touchPad.buttonC.justPressed)
			&& !player.playingMusic && PsychUIInputText.focusOn != searchBox
			&& !searchInputWait)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
			removeTouchPad();
		}

		var mobileReset:Bool = touchPad.buttonC.pressed && touchPad.buttonA.justPressed;
		if ((controls.RESET || mobileReset) && !player.playingMusic
			&& PsychUIInputText.focusOn != searchBox
			&& songs.length > 0 && curSelected >= 0)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty,
				songs[curSelected].songCharacter));
			removeTouchPad();
			FlxG.sound.play(Paths.sound('scrollMenu'));

			if (controls.mobileC)
				showMobileTip(Language.getPhrase('freeplay_tip_reset', '🗑 Resetting SCORE...'));
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
			FlxTween.color(item, 0.3, item.color, FlxColor.WHITE);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			if (controls.mobileC)
				showMobileTip(Language.getPhrase('freeplay_tip_fav_removed', 'Removed from Favorites: ') + song);
		}
		else
		{
			favorites.push(song);
			FlxTween.color(item, 0.3, item.color, 0xFFFFD700);
			FlxG.sound.play(Paths.sound('fav'), 0.8);
			if (controls.mobileC)
				showMobileTip(Language.getPhrase('freeplay_tip_fav_added', 'Added to Favorites: ') + song);

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
		if (curCategory == 'Favorites') updateList();
	}

	function toggleHidden()
	{
		if (songs.length == 0 || curSelected < 0) return;

		var song = songs[curSelected].songName;

		if (hiddenSongs.contains(song))
		{
			hiddenSongs.remove(song);
			if (controls.mobileC)
				showMobileTip(Language.getPhrase('freeplay_tip_hidden_removed', '👁 Removed from Hidden: ') + song);
		}
		else
		{
			hiddenSongs.push(song);
			if (controls.mobileC)
				showMobileTip(Language.getPhrase('freeplay_tip_hidden_added', '🙈 Added to Hidden: ') + song);
		}

		FlxG.save.data.hiddenSongs = hiddenSongs;
		FlxG.save.flush();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		updateList();
		updateQuickStats();
	}

	function updateBeatIcon(elapsed:Float)
	{
		if (selected && PlayState.SONG != null && PlayState.SONG.bpm > 0)
			beatBPM = PlayState.SONG.bpm;
		else
			beatBPM = 100;

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			var musicTime    = FlxG.sound.music.time / 1000.0;
			var beatInterval = 60.0 / beatBPM;
			var currentBeat  = Math.floor(musicTime / beatInterval);

			if (currentBeat != Math.floor(lastBeatTime / beatInterval))
			{
				lastBeatTime = musicTime;

				if (showcaseIcon != null)
				{
					FlxTween.cancelTweensOf(showcaseIcon.scale);
					showcaseIcon.scale.set(1.2, 1.2);
					FlxTween.tween(showcaseIcon.scale, {x: 1, y: 1}, beatInterval * 0.5, {ease: FlxEase.quartOut});
				}

				if (curSelected >= 0 && curSelected < iconArray.length)
				{
					var selIcon = iconArray[curSelected];
					if (selIcon != null && selIcon.visible)
					{
						FlxTween.cancelTweensOf(selIcon.scale);
						selIcon.scale.set(1.25, 1.25);
						FlxTween.tween(selIcon.scale, {x: 1, y: 1}, beatInterval * 0.5, {ease: FlxEase.quartOut});
					}
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
			if (orb.x < 0)           orb.x = FlxG.width - 30;
			if (orb.x > FlxG.width)  orb.x = 5;
			if (orb.y < 0)           orb.y = FlxG.height - 30;
			if (orb.y > FlxG.height) orb.y = 5;
		}
	}

	function updateGrade()
	{
		var rating = lerpRating * 100;
		if (curSelected == -1 || intendedScore == 0)
		{
			gradeText.text  = Language.getPhrase('freeplay_grade_na', 'N/A');
			gradeIcon.setText("🎵");
			gradeText.color = 0xFF888888;
		}
		else if (rating >= 100) { gradeText.text = "S+"; gradeIcon.setText("👑"); gradeText.color = 0xFFFFD700; }
		else if (rating >= 95)  { gradeText.text = "S";  gradeIcon.setText("⭐"); gradeText.color = 0xFFFFD700; }
		else if (rating >= 90)  { gradeText.text = "A";  gradeIcon.setText("🏆"); gradeText.color = 0xFF00FF87; }
		else if (rating >= 80)  { gradeText.text = "B";  gradeIcon.setText("✨"); gradeText.color = 0xFF00FFFF; }
		else if (rating >= 70)  { gradeText.text = "C";  gradeIcon.setText("📊"); gradeText.color = 0xFFFFD700; }
		else                    { gradeText.text = "D";  gradeIcon.setText("📉"); gradeText.color = 0xFFFF5555; }
	}

	function openSelectionMenu()
	{
		selected      = true;
		selectedItem  = 0;
		menuContainer.visible = true;

		if (curSelected >= 0 && curSelected < songs.length)
		{
			menuSongTitle.text       = songs[curSelected].songName.toUpperCase();
			menuSongArtist.text      = Language.getPhrase('freeplay_week_prefix', 'Week ') + (songs[curSelected].week + 1) + " • " + Difficulty.getString(curDifficulty);
			menuScoreDisplay.text    = Language.getPhrase('freeplay_score_label_short', 'Score: ')    + intendedScore;
			menuAccuracyDisplay.text = Language.getPhrase('freeplay_accuracy_label',    'Accuracy: ') + CoolUtil.floorDecimal(intendedRating * 100, 2) + "%";
			loadSongBackground(songs[curSelected].songName);
		}

		FlxTween.tween(showcasePanel, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(showcasePanelGlow, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(showcaseBorder, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(showcaseIconBG, {alpha: 0}, 0.3);
		FlxTween.tween(showcaseIconGlow, {alpha: 0}, 0.3);
		FlxTween.tween(showcaseIcon, {alpha: 0}, 0.3);
		FlxTween.tween(showcaseIconFrame, {alpha: 0}, 0.3);
		FlxTween.tween(showcaseTitle, {alpha: 0}, 0.3);
		FlxTween.tween(showcaseSubtitle, {alpha: 0}, 0.3);

		FlxTween.tween(scorePanel, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(scorePanelGlow, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});

		FlxTween.tween(diffPanel, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(diffPanelGlow, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});

		FlxTween.tween(statsPanel, {x: -showcaseWidth}, 0.4, {ease: FlxEase.quartOut});

		FlxTween.tween(topBar, {y: -topBar.height}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(topBarGlow, {y: -topBarGlow.height}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(topBarLine, {y: -topBarLine.height}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(topBarGradient, {y: -topBarGradient.height}, 0.3, {ease: FlxEase.quadIn});

		FlxTween.tween(bottomBG, {y: FlxG.height + bottomBG.height}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(bottomText, {y: FlxG.height + bottomText.height}, 0.3, {ease: FlxEase.quadIn});

		FlxTween.tween(tabBar, {y: -tabBar.height}, 0.3, {ease: FlxEase.quadIn});
		FlxTween.tween(tabIndicator, {y: -tabIndicator.height}, 0.3, {ease: FlxEase.quadIn});
		for (g in tabGlows) FlxTween.tween(g, {y: -g.height}, 0.3, {ease: FlxEase.quadIn});
		for (t in tabButtons) FlxTween.tween(t, {y: -t.height}, 0.3, {ease: FlxEase.quadIn});
		for (t in tabTexts) FlxTween.tween(t, {y: -t.height}, 0.3, {ease: FlxEase.quadIn});

		FlxTween.tween(searchContainer, {alpha: 0}, 0.3);
		FlxTween.tween(randomText, {alpha: 0}, 0.3);
		FlxTween.tween(randomIcon, {alpha: 0}, 0.3);

		for (i in 0...grpSongs.members.length) {
			var songAlpha = (i == curSelected) ? 1 : 0; 

			FlxTween.tween(grpSongs.members[i], {alpha: songAlpha}, 0.3);
			if (iconArray[i] != null) {
				FlxTween.tween(iconArray[i], {alpha: songAlpha}, 0.3);
			}
		}

		FlxTween.tween(menuBG, {alpha: 0.85}, 0.3);
		FlxTween.tween(songBG, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});

		if (curSelected >= 0 && curSelected < grpSongs.members.length)
		{
			var selectedSong:Alphabet   = grpSongs.members[curSelected];
			var selectedIcon:HealthIcon = iconArray[curSelected];

			FlxTween.cancelTweensOf(selectedSong);
			FlxTween.tween(selectedSong, {
				x: FlxG.width / 2 - selectedSong.width / 2,
				y: 60
			}, 0.5, {ease: FlxEase.quartOut});

			if (selectedIcon != null)
			{
				selectedIcon.sprTracker = null;
				FlxTween.cancelTweensOf(selectedIcon);
				FlxTween.tween(selectedIcon, {
					x: FlxG.width / 2 + selectedSong.width / 2 + 15,
					y: 50
				}, 0.5, {ease: FlxEase.backOut});
				FlxTween.tween(selectedIcon.scale, {x: 1.4, y: 1.4}, 0.4, {ease: FlxEase.backOut});
			}
		}

		diffSelect.alpha = 0;
		FlxTween.tween(diffSelect,      {alpha: 1},   0.2, {startDelay: 0.30});
		modifiersSelect.alpha = 0;
		FlxTween.tween(modifiersSelect, {alpha: 0.6}, 0.2, {startDelay: 0.35});
		resetSelect.alpha = 0;
		FlxTween.tween(resetSelect,     {alpha: 0.6}, 0.2, {startDelay: 0.40});
		backSelect.alpha = 0;
		FlxTween.tween(backSelect,      {alpha: 0.6}, 0.2, {startDelay: 0.45});

		if (curSelected >= 0 && songs.length > 0 && instPlaying != curSelected)
		{
			destroyFreeplayVocals();
			FlxG.sound.music.volume = 0;

			Mods.currentModDirectory = songs[curSelected].folder;
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			try
			{
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				FlxG.sound.music.pause(); 

				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song,
							(playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if (loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						if (loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume  = 0.8;
							vocals.pause(); 

						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch (e:Dynamic) { vocals = FlxDestroyUtil.destroy(vocals); }

					opponentVocals = new FlxSound();
					try
					{
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song,
							(oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						if (loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume  = 0.8;
							opponentVocals.pause(); 

						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch (e:Dynamic) { opponentVocals = FlxDestroyUtil.destroy(opponentVocals); }
				}
				instPlaying = curSelected; 

				new FlxTimer().start(0.5, function(t:FlxTimer) {
					if (FlxG.sound.music != null) FlxG.sound.music.play();
					if (vocals != null) vocals.play();
					if (opponentVocals != null) opponentVocals.play();
				});

			}
			catch (e:Dynamic) {

				instPlaying = -1;
				FlxG.log.error('Error loading song for preview: $e');
			}
		}

		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);

		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C_X_Y_Z');

		if (controls.mobileC)
			showMobileTip(Language.getPhrase('freeplay_tip_menu_mobile', '↕ Select  A: Confirm  B: Back  ←/→: Difficulty'));
	}

	function closeSelectionMenu()
	{
		selected     = false;
		selectedItem = 0;

		FlxTween.tween(showcasePanel, {x: 0}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(showcasePanelGlow, {x: -1}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(showcaseBorder, {x: showcaseWidth - 2}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(showcaseIconBG, {alpha: 1}, 0.3);
		FlxTween.tween(showcaseIconGlow, {alpha: 1}, 0.3);
		FlxTween.tween(showcaseIcon, {alpha: 1}, 0.3);
		FlxTween.tween(showcaseIconFrame, {alpha: 1}, 0.3);
		FlxTween.tween(showcaseTitle, {alpha: 1}, 0.3);
		FlxTween.tween(showcaseSubtitle, {alpha: 1}, 0.3);

		FlxTween.tween(scorePanel, {x: 15}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(scorePanelGlow, {x: 13}, 0.4, {ease: FlxEase.backOut});

		FlxTween.tween(diffPanel, {x: 15}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(diffPanelGlow, {x: 13}, 0.4, {ease: FlxEase.backOut});

		FlxTween.tween(statsPanel, {x: 15}, 0.4, {ease: FlxEase.backOut});

		FlxTween.tween(topBar, {y: 0}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(topBarGlow, {y: 0}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(topBarLine, {y: 53}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(topBarGradient, {y: 55}, 0.3, {ease: FlxEase.quadOut});

		FlxTween.tween(bottomBG, {y: FlxG.height - 35}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(bottomText, {y: FlxG.height - 28}, 0.3, {ease: FlxEase.quadOut});

		FlxTween.tween(tabBar, {y: 62 - 3}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(tabIndicator, {y: 62 + 30 - 3}, 0.3, {ease: FlxEase.quadOut});
		for (g in tabGlows) FlxTween.tween(g, {y: 62 - 1}, 0.3, {ease: FlxEase.quadOut});
		for (t in tabButtons) FlxTween.tween(t, {y: 62}, 0.3, {ease: FlxEase.quadOut});
		for (t in tabTexts) FlxTween.tween(t, {y: 62 + 8}, 0.3, {ease: FlxEase.quadOut});

		FlxTween.tween(searchContainer, {alpha: 1}, 0.3);
		FlxTween.tween(randomText, {alpha: 1}, 0.3);
		FlxTween.tween(randomIcon, {alpha: 1}, 0.3);

		for (i in 0...grpSongs.members.length) {
			FlxTween.tween(grpSongs.members[i], {alpha: 1}, 0.3);
			if (iconArray[i] != null) {
				FlxTween.tween(iconArray[i], {alpha: 1}, 0.3);
			}
		}

		FlxTween.cancelTweensOf(menuBG);
		FlxTween.cancelTweensOf(songBG);
		FlxTween.tween(menuBG, {alpha: 0}, 0.2, {
			onComplete: function(t) { menuContainer.visible = false; }
		});
		FlxTween.tween(songBG, {alpha: 0}, 0.3);

		if (curSelected >= 0 && curSelected < iconArray.length && curSelected < grpSongs.members.length)
		{
			var selectedIcon:HealthIcon = iconArray[curSelected];
			if (selectedIcon != null)
			{
				FlxTween.tween(selectedIcon.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quartOut});
				new FlxTimer().start(0.4, function(t)
				{
					if (curSelected >= 0 && curSelected < grpSongs.members.length)
						selectedIcon.sprTracker = grpSongs.members[curSelected];
				});
			}
		}

		if (player.playingMusic)
		{
			FlxG.sound.music.stop();
			destroyFreeplayVocals();
			FlxG.sound.music.volume = 0;
			instPlaying         = -1;
			player.playingMusic = false;
			player.switchPlayMusic();
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
		}

		FlxG.sound.play(Paths.sound('cancelMenu'));

		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C_X_Y_Z');
	}

	function loadSongBackground(songName:String)
	{
		if (!ClientPrefs.data.ultraModSystem)
		{
			songBG.alpha = 0;
			return;
		}

		var formattedSong:String = Paths.formatToSongPath(songName);
		var bgLoaded:Bool = false;

		var defaultSongBGs:Map<String, String> = [
			"tutorial" => "stage",
			"bopeebo" => "stage",
			"fresh" => "stage",
			"dad-battle" => "stage",
			"dadbattle" => "stage",
			"spookeez" => "spooky",
			"south" => "spooky",
			"monster" => "spooky",
			"pico" => "pico",
			"philly" => "pico",
			"philly-nice" => "pico",
			"blammed" => "pico",
			"satin-panties" => "limo",
			"satinpanties" => "limo",
			"high" => "limo",
			"milf" => "limo",
			"cocoa" => "mall",
			"eggnog" => "mall",
			"winter-horrorland" => "mall-evil",
			"winterhorrorland" => "mall-evil",
			"senpai" => "school",
			"roses" => "school",
			"thorns" => "school-evil",
			"ugh" => "tank",
			"guns" => "tank",
			"stress" => "tank"
		];

		if (curSelected >= 0 && curSelected < songs.length)
		{
			var songFolder:String = songs[curSelected].folder;

			if (songFolder != null && songFolder.length > 0)
			{
				#if MODS_ALLOWED
				var modBgPath:String = Paths.mods(songFolder + '/images/songbg/' + formattedSong + '.png');

				if (FileSystem.exists(modBgPath))
				{
					try
					{
						var bitmapData = openfl.display.BitmapData.fromFile(modBgPath);
						if (bitmapData != null)
						{
							songBG.loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bitmapData));
							songBG.setGraphicSize(FlxG.width, FlxG.height);
							songBG.updateHitbox();
							songBG.screenCenter();
							bgLoaded = true;
						}
					}
					catch (e:Dynamic)
					{
						trace('Mod songbg yuklenemedi: ' + e);
					}
				}
				#end
			}
		}

		if (!bgLoaded && defaultSongBGs.exists(formattedSong))
		{
			var mappedBG:String = defaultSongBGs.get(formattedSong);
			var mappedBgPath:String = 'songbg/' + mappedBG;
			var mappedImg = Paths.image(mappedBgPath);

			if (mappedImg != null)
			{
				songBG.loadGraphic(mappedImg);
				songBG.setGraphicSize(FlxG.width, FlxG.height);
				songBG.updateHitbox();
				songBG.screenCenter();
				bgLoaded = true;
			}
		}

		if (!bgLoaded)
		{
			var defaultBgPath:String = 'songbg/' + formattedSong;
			var defaultImg = Paths.image(defaultBgPath);

			if (defaultImg != null)
			{
				songBG.loadGraphic(defaultImg);
				songBG.setGraphicSize(FlxG.width, FlxG.height);
				songBG.updateHitbox();
				songBG.screenCenter();
				bgLoaded = true;
			}
		}

		if (!bgLoaded)
		{
			if (curSelected >= 0 && curSelected < songs.length)
			{
				songBG.makeGraphic(FlxG.width, FlxG.height, songs[curSelected].color);
			}
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
			if (controls.UI_LEFT_P)       { changeDiff(-1); _updateSongLastDifficulty(); updateMenuInfo(); }
			else if (controls.UI_RIGHT_P) { changeDiff(1);  _updateSongLastDifficulty(); updateMenuInfo(); }
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
					openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty,
						songs[curSelected].songCharacter));
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
			FlxTween.cancelTweensOf(menuSelectionGlow);
			FlxTween.tween(menuSelectionGlow, {
				y: targetItem.y - 5,
				x: FlxG.width / 2 - 200
			}, 0.15, {ease: FlxEase.quartOut});

			FlxTween.cancelTweensOf(menuSelectionBar);
			FlxTween.tween(menuSelectionBar, {
				y: targetItem.y,
				x: FlxG.width / 2 - 205
			}, 0.15, {ease: FlxEase.quartOut});
		}
	}

	function updateMenuInfo()
	{
		if (curSelected >= 0 && curSelected < songs.length)
		{
			menuSongArtist.text      = Language.getPhrase('freeplay_week_prefix', 'Week ') + (songs[curSelected].week + 1) + " • " + Difficulty.getString(curDifficulty);
			menuScoreDisplay.text    = Language.getPhrase('freeplay_score_label_short', 'Score: ')    + intendedScore;
			menuAccuracyDisplay.text = Language.getPhrase('freeplay_accuracy_label',    'Accuracy: ') + CoolUtil.floorDecimal(intendedRating * 100, 2) + "%";
		}
	}

	function updateMenuPositions(elapsed:Float)
	{
		var centerX = FlxG.width / 2;
		var startY  = 240;
		var spacing = 55;

		diffSelect.x      = centerX - diffSelect.width / 2;
		diffSelect.y      = startY;

		modifiersSelect.x = centerX - modifiersSelect.width / 2;
		modifiersSelect.y = startY + spacing;

		resetSelect.x     = centerX - resetSelect.width / 2;
		resetSelect.y     = startY + spacing * 2;

		backSelect.x      = centerX - backSelect.width / 2;
		backSelect.y      = startY + spacing * 3;
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
		var poop:String          = Highscore.formatSong(songLowercase, curDifficulty);

		try
		{
			Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode     = false;
			PlayState.storyDifficulty = curDifficulty;
		}
		catch (e:haxe.Exception)
		{
			var errorStr:String = e.message;
			if (errorStr.contains('There is no TEXT asset with an ID of'))
				errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1);
			else
				errorStr += '\n\n' + e.stack;

			missingText.text   = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);
			missingText.visible   = true;
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

	function onKeyDown(e:KeyboardEvent)
	{
		if (!searchInputWait) return;

		var key = e.keyCode;
		if (e.charCode == 0) return;

		if (key == 8)       { searchString = searchString.substring(0, searchString.length - 1); applySearch(); return; }
		else if (key == 13) { searchInputWait = false; applySearch(); return; }
		else if (key == 27) { searchInputWait = false; searchString = ''; applySearch(); return; }

		var newText:String = String.fromCharCode(e.charCode);
		if (key == 86 && e.ctrlKey) newText = Clipboard.text;
		if (newText.length > 0) { searchString += newText; applySearch(); }
	}

	function applySearch()
	{
		searchBox.text = searchString;
		updateList();
		updateSearchResults();
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

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic || songs.length == 0 || curSelected < 0) return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);

		#if !switch
		intendedScore  = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);

		diffText.text   = Difficulty.list.length > 1 ? '< ' + displayDiff.toUpperCase() + ' >' : displayDiff.toUpperCase();
		diffSelect.text = diffText.text;

		switch (displayDiff.toLowerCase())
		{
			case 'kolay':  diffText.color = 0xFF00FF87;
			case 'normal': diffText.color = 0xFFFFD700;
			case 'zor':    diffText.color = 0xFFFF4444;
			default:       diffText.color = FlxColor.WHITE;
		}

		FlxTween.cancelTweensOf(diffText.scale);
		diffText.scale.set(1.2, 1.2);
		FlxTween.tween(diffText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

		missingText.visible = missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic || songs.length == 0) return;

		curSelected += change;
		if (curSelected < -1)           curSelected = songs.length - 1;
		if (curSelected >= songs.length) curSelected = -1;

		if (curSelected >= 0) _updateSongLastDifficulty();
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var unknownImg = Paths.image('unknownMod');
		if (unknownImg != null)
		{
			showcaseIcon.loadGraphic(unknownImg);
			showcaseIcon.setGraphicSize(120, 120);
			showcaseIcon.updateHitbox();
		}

		if (curSelected == -1)
		{
			randomText.alpha = 1;
			randomIcon.alpha = 1;
			intendedScore    = 0;
			intendedRating   = 0;

			showcaseTitle.text    = Language.getPhrase('freeplay_random', 'RANDOM');
			showcaseSubtitle.text = Language.getPhrase('freeplay_random_subtitle', 'Pick a random song!');

			for (num => item in grpSongs.members)
			{
				item.alpha = 0.5;
				if (iconArray[num] != null) iconArray[num].alpha = 0.5;
			}
		}
		else
		{
			randomText.alpha = 0.4;
			randomIcon.alpha = 0.4;

			var newColor:Int = songs[curSelected].color;
			if (newColor != intendedColor)
			{
				intendedColor = newColor;
				FlxTween.cancelTweensOf(bg);
				FlxTween.color(bg, 0.8, bg.color, intendedColor, {ease: FlxEase.quadOut});
				FlxTween.color(topBarLine,     0.3, topBarLine.color,     intendedColor);
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

			showcaseTitle.text    = songs[curSelected].songName;
			showcaseSubtitle.text = Language.getPhrase('freeplay_week_prefix', 'Week ') + (songs[curSelected].week + 1) + " • " + songs[curSelected].songCharacter;

			for (num => item in grpSongs.members)
			{
				var icon:HealthIcon = iconArray[num];
				item.alpha = 0.5;
				if (icon != null) icon.alpha = 0.5;

				if (!favorites.contains(songs[num].songName))
					item.color = FlxColor.WHITE;

				if (item.targetY == curSelected)
				{
					item.alpha = 1;
					if (icon != null)
					{
						icon.alpha = 1;
						FlxTween.cancelTweensOf(icon.scale);
						icon.scale.set(1.15, 1.15);
						FlxTween.tween(icon.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});
					}
				}
			}

			Mods.currentModDirectory = songs[curSelected].folder;
			PlayState.storyWeek      = songs[curSelected].week;
			Difficulty.loadFromWeek();

			var savedDiff:String = songs[curSelected].lastDifficulty;
			var lastDiff:Int     = Difficulty.list.indexOf(lastDifficultyName);
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

	var lerpScore:Int        = 0;
	var lerpRating:Float     = 0;
	var intendedScore:Int    = 0;
	var intendedRating:Float = 0;

	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		if (selected)
		{
			for (i in 0...iconArray.length)
			{
				iconArray[i].visible = (i == curSelected);
				iconArray[i].active  = (i == curSelected);
			}
			for (i in 0...grpSongs.members.length)
			{
				grpSongs.members[i].visible = (i == curSelected);
				grpSongs.members[i].active  = (i == curSelected);
			}
			randomText.visible = false;
			randomIcon.visible = false;
			updateMenuPositions(elapsed);
			return;
		}

		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible        = iconArray[i].active        = false;
		}
		_lastVisibles = [];

		randomText.visible = true;
		randomText.x = showcaseWidth + 30 + ((-1 - lerpSelected) * randomText.distancePerItem.x);
		randomText.y = 320 + ((-1 - lerpSelected) * 1.3 * randomText.distancePerItem.y);
		randomIcon.visible = true;

		if (songs.length == 0) return;

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));

		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = showcaseWidth + 30 + ((item.targetY - lerpSelected) * item.distancePerItem.x);
			item.y = 320 + ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y);

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function destroy():Void
	{
		super.destroy();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}

class SongMetadata
{
	public var songName:String       = "";
	public var week:Int              = 0;
	public var songCharacter:String  = "";
	public var color:Int             = -7179779;
	public var folder:String         = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName      = song;
		this.week          = week;
		this.songCharacter = songCharacter;
		this.color         = color;
		this.folder        = Mods.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}