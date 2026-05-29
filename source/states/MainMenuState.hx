package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import states.MultiplayerState;
import options.OptionsState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import objects.Alphabet;
import flixel.input.keyboard.FlxKey;
import backend.Achievements;
import backend.WeekData;
import backend.Highscore;
import backend.ThemeManager;
import backend.WorkspaceSwitcher;
import backend.AuthManager;
import objects.ProfileBox;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import backend.Song;
import objects.HealthIcon;
import flixel.ui.FlxBar;
import DateTools;
import states.PlayState;
import states.LoadingState;
import states.AdminPanel;
import objects.VideoSprite;
import objects.EmojiText;
import objects.EmojiAtlas;
import objects.EmojiUtil;
import objects.AIMenu;
import states.multiplayer.OnlineModsState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.1.3';
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSpriteGroup>;
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'changelog',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'achievements', #end
		'credits',
		'settings',
		'multiplayer',
	];

	var scanline:FlxBackdrop;
	var vignette:FlxSprite;
	var sideBar:FlxSprite;
	var sideBarGlow:FlxSprite;
	var menuCards:FlxTypedGroup<FlxSpriteGroup>;
	var cardGlows:Array<FlxSprite> = [];
	var cardIcons:Array<FlxSprite> = [];
	var cardTitles:Array<FlxText> = [];
	var mouseCursor:FlxSprite;

	var wallpaperBG:FlxSprite;
	var wallpaperImages:Array<String> = [];
	var wallpaperIndex:Int = 0;
	var wallpaperTimer:Float = 0;
	var wallpaperFadeTime:Float = 10;
	var wallpaperActive:Bool = false;
	var wallpaperNextBG:FlxSprite;
	var wallpaperTransitioning:Bool = false;

	#if VIDEOS_ALLOWED
	var menuVideoBG:VideoSprite;
	#end

	var allowMouse:Bool = true;

	var isChangelogOpen:Bool = false;
	var changelogBG:FlxSprite;
	var changelogLogo:FlxSprite;
	var changelogTextTitle:FlxText;
	var changelogTextNotes:FlxText;
	var changelogHint:FlxText;
	var bumpIntensity:Float = 0;

	var adminPanel:AdminPanel;
	var bgLayer1:FlxSprite;
	var bgLayer2:FlxSprite;
	var bgLayer3:FlxSprite;
	var gradientOverlay:FlxSprite;
	var gridBG:FlxBackdrop;
	var particles:Array<FlxSprite> = [];
	var glowParticles:Array<FlxSprite> = [];
	var floatingOrbs:Array<FlxSprite> = [];
	var topBar:FlxSprite;
	var topBarGlow:FlxSprite;
	var topBarLine:FlxSprite;
	var bottomBar:FlxSprite;
	var bottomBarGlow:FlxSprite;
	var bottomLine:FlxSprite;
	var selectionGlow:FlxSprite;
	var descriptionTitle:FlxText;
	var descriptionText:FlxText;
	
	var profileBox:ProfileBox;

	var statsPanel:FlxSprite;
	var statsPanelGlow:FlxSprite;
	var statsTotalScore:FlxText;
	var statsSongsPlayed:FlxText;
	var statsPlayTime:FlxText;
	var statsAccuracy:FlxText;
	var statsPerfects:FlxText;

	var scoreIcon:FlxText;
	var songsIcon:FlxText;
	var timeIcon:FlxText;
	var accIcon:FlxText;

	var clockText:FlxText;
	var dateText:FlxText;
	var greetingText:FlxText;
	var lastPlayedPanel:FlxSprite;
	var lastPlayedSong:FlxText;
	var lastPlayedScore:FlxText;
	var lastPlayedDifficulty:FlxText;
	var quickPlayButton:FlxSprite;
	var quickPlayText:FlxText;
	var quickPlayGlow:FlxSprite;
	var newsPanel:FlxSprite;
	var newsTitle:FlxText;
	var newsText:FlxText;
	var newsIndex:Int = 0;
	var newsTimer:Float = 0;
	var versionText:FlxText;
	var engineLogo:FlxText;
	var engineLogoGlow:FlxSprite;

	var currentTheme:FlxColor = 0xFF4A90E2;
	var themeColors:Array<FlxColor> = [0xFF4A90E2, 0xFF8B5CF6, 0xFF10B981, 0xFFF59E0B, 0xFFEC4899, 0xFF64748B];
	var ambientPulse:Float = 0;
	var breathingEffect:Float = 0;
	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var cheatSequence:Array<Int> = [];
	var cheatPattern:Array<Int> = [0, 3, 3, 2];
	var cheatLastInputTime:Float = 0;
	var cheatTimeout:Float = 1.5;
	var prevUp:Bool = false;
	var prevRight:Bool = false;
	var prevLeft:Bool = false;

	var menuColorMap:Map<String, FlxColor> = [
		'story_mode'   => 0xFF4A90E2,
		'freeplay'     => 0xFF00E5FF,
		'changelog'    => 0xFF8B5CF6,
		'mods'         => 0xFF10B981,
		'achievements' => 0xFF00E5FF,
		'credits'      => 0xFF10B981,
		'settings'     => 0xFF64748B,
		'multiplayer'  => 0xFF64748B
	];

	var menuIconMap:Map<String, String> = [
		'story_mode'   => "⭐",
		'freeplay'     => "🎵",
		'changelog'    => "📋",
		'mods'         => "🧬",
		'achievements' => "💎",
		'credits'      => "",
		'settings'     => "",
		'multiplayer'  => ""
	];
	var menuDescriptions:Map<String, String> = [];
	var menuTitles:Map<String, String>       = [];
	var newsItems:Array<String>              = [];

	var playerName(get, never):String;
	inline function get_playerName():String return backend.AuthManager.currentUsername;

	function _buildLanguageData():Void
	{
		menuTitles = [
			'story_mode'   => Language.getPhrase('menu_title_story',        'Story Mode'),
			'freeplay'     => Language.getPhrase('menu_title_freeplay',     'Freeplay'),
			'changelog'    => Language.getPhrase('menu_title_changelog',    'Change Log'),
			'mods'         => Language.getPhrase('menu_title_mods',         'Mods'),
			'achievements' => Language.getPhrase('menu_title_achievements', 'Achievements'),
			'credits'      => Language.getPhrase('menu_title_credits',      'Credits'),
			'settings'     => Language.getPhrase('menu_title_settings',     'Settings'),
			'multiplayer'  => Language.getPhrase('menu_title_settings',     'multiplayer')
		];

		menuDescriptions = [
			'story_mode'   => Language.getPhrase('menu_desc_story',        'Experience the main story and defeat your rivals!\nAn epic adventure awaits you.'),
			'freeplay'     => Language.getPhrase('menu_desc_freeplay',     'All the songs are here!\nPractice and break records.'),
			'changelog'    => Language.getPhrase('menu_desc_changelog',    'New features in Psych Engine Ultra!\nCheck out the release notes.'),
			'mods'         => Language.getPhrase('menu_desc_mods',         'Discover community mods!\nA world of unlimited content.'),
			'achievements' => Language.getPhrase('menu_desc_achievements', 'All your achievements!\nComplete your collection.'),
			'credits'      => Language.getPhrase('menu_desc_credits',      'Our team!\nThe people behind this project.'),
			'settings'     => Language.getPhrase('menu_desc_settings',     'Customize the game!\nYou\'re in full control.'),
			'multiplayer'  => Language.getPhrase('menu_desc_settings',     'Customize the game!\nYou\'re in full control.')
		];

		newsItems = [
			Language.getPhrase('news_1', 'A new update has been released! Check the Change Logs!'),
			Language.getPhrase('news_2', 'Psych Engine Ultra is sooo cool :D'),
			Language.getPhrase('news_3', 'The weekly tournament has started! Don\'t forget to join.'),
			Language.getPhrase('news_4', 'Don\'t forget to join our Discord server'),
			Language.getPhrase('news_5', 'Let\'s Gooo!')
		];
	}

	function loadWallpaperSystem()
	{
		if (!ClientPrefs.data.ultraModSystem) return;

		#if MODS_ALLOWED
		wallpaperImages = [];
		var currentMod:String = Mods.currentModDirectory;

		if (currentMod == null || currentMod.length == 0)
		{
			var modList = Mods.parseList();
			if (modList != null && modList.enabled != null && modList.enabled.length > 0)
				currentMod = modList.enabled[0];
		}

		if (currentMod == null || currentMod.length == 0) return;

		var wallpaperDir:String = Paths.mods(currentMod + '/images/wallpapers');

		if (!FileSystem.exists(wallpaperDir)) return;
		if (!FileSystem.isDirectory(wallpaperDir)) return;

		for (i in 1...11)
		{
			var filePath:String = wallpaperDir + '/' + i + '.png';
			if (FileSystem.exists(filePath))
				wallpaperImages.push(filePath);
		}

		if (wallpaperImages.length == 0) return;

		var timePath:String = wallpaperDir + '/time.txt';
		if (FileSystem.exists(timePath))
		{
			try
			{
				var timeStr:String = StringTools.trim(File.getContent(timePath));
				var parsed:Float = Std.parseFloat(timeStr);
				if (parsed > 0)
					wallpaperFadeTime = parsed;
			}
			catch (e:Dynamic)
			{
				wallpaperFadeTime = 10;
			}
		}
		else
		{
			wallpaperFadeTime = 10;
		}

		wallpaperActive = true;
		wallpaperIndex  = 0;
		wallpaperTimer  = 0;

		wallpaperBG = new FlxSprite();
		try
		{
			var bitmapData = openfl.display.BitmapData.fromFile(wallpaperImages[0]);
			if (bitmapData != null)
			{
				wallpaperBG.loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bitmapData));
				wallpaperBG.setGraphicSize(FlxG.width, FlxG.height);
				wallpaperBG.updateHitbox();
				wallpaperBG.screenCenter();
			}
		}
		catch (e:Dynamic)
		{
			wallpaperActive = false;
			return;
		}
		wallpaperBG.alpha = 0;

		var bgIndex = members.indexOf(bgLayer2);
		if (bgIndex >= 0)
			insert(bgIndex + 1, wallpaperBG);
		else
			add(wallpaperBG);

		wallpaperNextBG = new FlxSprite();
		wallpaperNextBG.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		wallpaperNextBG.alpha = 0;

		var nextIndex = members.indexOf(wallpaperBG);
		if (nextIndex >= 0)
			insert(nextIndex + 1, wallpaperNextBG);
		else
			add(wallpaperNextBG);

		FlxTween.tween(wallpaperBG, {alpha: 1}, 1.5, {ease: FlxEase.quartOut});
		bgLayer2.alpha = 0;
		#end
	}

	function updateWallpaper(elapsed:Float)
	{
		if (!wallpaperActive) return;
		if (!ClientPrefs.data.ultraModSystem) return;
		if (wallpaperImages.length <= 1) return;
		if (wallpaperTransitioning) return;

		wallpaperTimer += elapsed;

		if (wallpaperTimer >= wallpaperFadeTime)
		{
			wallpaperTimer = 0;
			wallpaperTransitioning = true;

			var nextIndex:Int = (wallpaperIndex + 1) % wallpaperImages.length;

			#if MODS_ALLOWED
			try
			{
				var bitmapData = openfl.display.BitmapData.fromFile(wallpaperImages[nextIndex]);
				if (bitmapData != null)
				{
					wallpaperNextBG.loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bitmapData));
					wallpaperNextBG.setGraphicSize(FlxG.width, FlxG.height);
					wallpaperNextBG.updateHitbox();
					wallpaperNextBG.screenCenter();
					wallpaperNextBG.alpha = 0;

					FlxTween.tween(wallpaperNextBG, {alpha: 1}, 1.5, {ease: FlxEase.quartOut});
					FlxTween.tween(wallpaperBG, {alpha: 0}, 1.5, {
						ease: FlxEase.quartOut,
						onComplete: function(t:FlxTween)
						{
							var tempGraphic = wallpaperNextBG.graphic;
							wallpaperBG.loadGraphic(tempGraphic);
							wallpaperBG.setGraphicSize(FlxG.width, FlxG.height);
							wallpaperBG.updateHitbox();
							wallpaperBG.screenCenter();
							wallpaperBG.alpha = 1;

							wallpaperNextBG.alpha = 0;
							wallpaperNextBG.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);

							wallpaperIndex = nextIndex;
							wallpaperTransitioning = false;
						}
					});
				}
				else
				{
					wallpaperTransitioning = false;
				}
			}
			catch (e:Dynamic)
			{
				wallpaperTransitioning = false;
			}
			#end
		}
	}

	override function create()
	{
		_buildLanguageData();

		#if mobile
		final enter:String = (controls.mobileC) ? 'A' : 'ENTER';
		final back:String  = (controls.mobileC) ? 'B' : 'BACK';
		#end
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Main Menu", null);
		#end

		persistentUpdate = persistentDraw = true;

		WorkspaceSwitcher.init();

		if (!EmojiAtlas.instance.isLoaded())
			EmojiAtlas.instance.load("emoji_atlas", 32);

		bgLayer1 = new FlxSprite().makeGraphic(Std.int(FlxG.width * 1.5), Std.int(FlxG.height * 1.5), 0xFF05050a);
		bgLayer1.screenCenter();
		add(bgLayer1);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(60, 60, 120, 120, true, 0x08FFFFFF, 0x0));
		gridBG.velocity.set(15, 15);
		gridBG.alpha = 0.2;
		gridBG.visible = ClientPrefs.data.showGridBG;
		add(gridBG);

		#if VIDEOS_ALLOWED
		if (ClientPrefs.data.menuVideo && ClientPrefs.data.menuVideoPath != null && ClientPrefs.data.menuVideoPath.trim() != '')
		{
			menuVideoBG = new VideoSprite(ClientPrefs.data.menuVideoPath, true, true);
			menuVideoBG.setGraphicSize(FlxG.width, FlxG.height);
			menuVideoBG.updateHitbox();
			menuVideoBG.screenCenter();
			add(menuVideoBG);
			menuVideoBG.videoSprite.bitmap.play();
			bgLayer2 = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
			add(bgLayer2);
		}
		else
		{
		#end
			bgLayer2 = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
			bgLayer2.antialiasing = ClientPrefs.data.antialiasing;
			bgLayer2.setGraphicSize(Std.int(FlxG.width * 1.3));
			bgLayer2.updateHitbox();
			bgLayer2.screenCenter();
			bgLayer2.alpha = 0.4;
			bgLayer2.color = currentTheme;
			add(bgLayer2);
		#if VIDEOS_ALLOWED
		}
		#end

		loadWallpaperSystem();

		scanline = new FlxBackdrop(null, Y, 0, 2);
		scanline.makeGraphic(FlxG.width, 4, 0x11FFFFFF);
		scanline.velocity.y = 40;
		scanline.visible = ClientPrefs.data.showScanlines;
		add(scanline);

		vignette = new FlxSprite().loadGraphic(Paths.image('vignette'));
		vignette.setGraphicSize(FlxG.width, FlxG.height);
		vignette.updateHitbox();
		vignette.alpha = 0.6;
		add(vignette);

		createParticles();
		createFloatingOrbs();

		topBarGlow = new FlxSprite(0, 0).makeGraphic(FlxG.width, 85, currentTheme);
		topBarGlow.alpha = 0.15;
		add(topBarGlow);

		topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0x99000000);
		add(topBar);

		topBarLine = new FlxSprite(0, 78).makeGraphic(FlxG.width, 2, currentTheme);
		topBarLine.alpha = 0.8;
		add(topBarLine);

		engineLogo = new FlxText(30, 15, 0, Language.getPhrase('main_menu_logo', 'PSYCH ENGINE ULTRA'), 36);
		engineLogo.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		engineLogo.borderSize = 2;
		add(engineLogo);

		var systemStatus = new FlxText(30, 52, 0, Language.getPhrase('main_menu_edition', 'ULTRA EDITION'), 14);
		systemStatus.setFormat(Paths.font("vcr.ttf"), 14, currentTheme, LEFT);
		add(systemStatus);

		clockText = new FlxText(FlxG.width - 200, 18, 180, "", 28);
		clockText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, RIGHT);
		clockText.visible = ClientPrefs.data.showClock;
		add(clockText);

		dateText = new FlxText(FlxG.width - 200, 48, 180, "", 14);
		dateText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFBBBBBB, RIGHT);
		dateText.visible = ClientPrefs.data.showClock;
		add(dateText);

		greetingText = new FlxText(FlxG.width - 450, 30, 240, "", 18);
		greetingText.setFormat(Paths.font("vcr.ttf"), 18, currentTheme, RIGHT);
		greetingText.visible = ClientPrefs.data.showGreeting;
		add(greetingText);

		updateTimeAndGreeting();

		menuCards = new FlxTypedGroup<FlxSpriteGroup>();
		add(menuCards);

		for (i in 0...optionShit.length)
		{
			var card = new FlxSpriteGroup();

			var bg = new FlxSprite(0, 0).makeGraphic(200, 280, 0xAA000000);
			card.add(bg);

			var border = new FlxSprite(-2, -2).makeGraphic(204, 284, currentTheme);
			border.alpha = 0.5;
			card.add(border);

			var glow = new FlxSprite(-10, -10).makeGraphic(220, 300, currentTheme);
			glow.alpha = 0;
			card.add(glow);
			cardGlows.push(glow);

			var iconName:String = optionShit[i];
			if (iconName == 'changelog')    iconName = 'changelogs';
			if (iconName == 'achievements') iconName = 'achievements';

			var icon = new FlxSprite(40, 30);
			try {
				icon.loadGraphic(Paths.image('ultra/mainmenu/' + iconName));
			} catch(e:Dynamic) {
				icon.makeGraphic(100, 100, FlxColor.WHITE);
			}
			icon.setGraphicSize(120, 120);
			icon.updateHitbox();
			card.add(icon);
			cardIcons.push(icon);

			var emojiStr:String = menuIconMap.exists(optionShit[i]) ? menuIconMap.get(optionShit[i]) : "❓";
			var iconEmoji = new EmojiText(40, 155, 120, emojiStr, 0);
			iconEmoji.emojiScale = 1.2;
			iconEmoji.x = 100 - 19;
			card.add(iconEmoji);

			var title = new FlxText(10, 180, 180, menuTitles.get(optionShit[i]), 24);
			title.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
			card.add(title);
			cardTitles.push(title);

			var decoLine = new FlxSprite(20, 170).makeGraphic(160, 2, currentTheme);
			card.add(decoLine);

			card.ID = i;
			card.screenCenter(Y);
			card.x = FlxG.width + 200;
			menuCards.add(card);
		}

		var descBG = new FlxSprite(FlxG.width - 420, 100).makeGraphic(400, 150, 0xAA000000);
		add(descBG);

		var descLine = new FlxSprite(FlxG.width - 420, 100).makeGraphic(400, 3, currentTheme);
		add(descLine);

		descriptionTitle = new FlxText(FlxG.width - 400, 115, 360, "", 32);
		descriptionTitle.setFormat(Paths.font("vcr.ttf"), 32, currentTheme, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(descriptionTitle);

		descriptionText = new FlxText(FlxG.width - 400, 160, 360, "", 18);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFDDDDDD, LEFT);
		add(descriptionText);

		// ==========================================
		//  PROFILEBOX - OFFLINE İSE HİÇ OLUŞTURMA!
		// ==========================================
		if (AuthManager.isLoggedIn && ClientPrefs.data.showProfilePanel)
		{
			profileBox = new ProfileBox(30, 110);
			add(profileBox);
		}

		// ==========================================
		//  STATS PANELİ
		// ==========================================
		// Stats panelinin Y pozisyonu ProfileBox'a göre ayarlanıyor
		var statsY:Int = (profileBox != null) ? 210 : 110;

		statsPanelGlow = new FlxSprite(28, statsY - 2).makeGraphic(244, 164, 0xFFF59E0B);
		statsPanelGlow.alpha = 0.1;
		add(statsPanelGlow);

		statsPanel = new FlxSprite(30, statsY).makeGraphic(240, 160, 0xCC000000);
		add(statsPanel);

		var statsBorder = new FlxSprite(30, statsY).makeGraphic(240, 2, 0xFFF59E0B);
		add(statsBorder);

		statsTotalScore = new FlxText(50, statsY + 20, 200, "SCORE: 0", 18);
		statsTotalScore.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(statsTotalScore);

		statsSongsPlayed = new FlxText(50, statsY + 50, 200, "SONGS: 0", 16);
		statsSongsPlayed.setFormat(Paths.font("vcr.ttf"), 16, 0xFFCCCCCC, LEFT);
		add(statsSongsPlayed);

		statsAccuracy = new FlxText(50, statsY + 80, 200, "ACC: 0%", 16);
		statsAccuracy.setFormat(Paths.font("vcr.ttf"), 16, 0xFF10B981, LEFT);
		add(statsAccuracy);

		statsPerfects = new FlxText(50, statsY + 110, 200, "FC: 0", 16);
		statsPerfects.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFD700, LEFT);
		add(statsPerfects);

		statsPlayTime = new FlxText(50, statsY + 140, 200, "TIME: 0", 14);
		statsPlayTime.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, LEFT);
		add(statsPlayTime);

		var _showStats:Bool = ClientPrefs.data.showStatsPanel;
		statsPanelGlow.visible   = _showStats;
		statsPanel.visible       = _showStats;
		statsBorder.visible      = _showStats;
		statsTotalScore.visible  = _showStats;
		statsSongsPlayed.visible = _showStats;
		statsAccuracy.visible    = _showStats;
		statsPerfects.visible    = _showStats;
		statsPlayTime.visible    = _showStats;

		loadStats();

		// ==========================================
		//  LAST PLAYED PANELİ
		// ==========================================
		var lastPlayedY:Int = statsY + 180;

		lastPlayedPanel = new FlxSprite(30, lastPlayedY).makeGraphic(240, 120, 0xCC000000);
		add(lastPlayedPanel);

		var lastBorder = new FlxSprite(30, lastPlayedY).makeGraphic(240, 2, 0xFF8B5CF6);
		add(lastBorder);

		lastPlayedSong = new FlxText(45, lastPlayedY + 15, 210, Language.getPhrase('last_played_none', 'NOT PLAYED'), 18);
		lastPlayedSong.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(lastPlayedSong);

		lastPlayedDifficulty = new FlxText(45, lastPlayedY + 45, 210, "HARD", 14);
		lastPlayedDifficulty.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFF5555, LEFT);
		add(lastPlayedDifficulty);

		lastPlayedScore = new FlxText(45, lastPlayedY + 60, 210, Language.getPhrase('score_label', 'Score') + ": 0", 12);
		lastPlayedScore.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		add(lastPlayedScore);

		quickPlayButton = new FlxSprite(45, lastPlayedY + 75).makeGraphic(210, 35, 0xFF8B5CF6);
		add(quickPlayButton);

		quickPlayText = new FlxText(45, lastPlayedY + 82, 210, Language.getPhrase('quick_play_replay', 'REPLAY'), 16);
		quickPlayText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(quickPlayText);

		quickPlayGlow = new FlxSprite(43, lastPlayedY + 73).makeGraphic(214, 39, 0xFF8B5CF6);
		quickPlayGlow.alpha = 0;
		add(quickPlayGlow);

		var _showLast:Bool = ClientPrefs.data.showLastPlayedPanel;
		lastPlayedPanel.visible      = _showLast;
		lastBorder.visible           = _showLast;
		lastPlayedSong.visible       = _showLast;
		lastPlayedDifficulty.visible = _showLast;
		lastPlayedScore.visible      = _showLast;
		quickPlayButton.visible      = _showLast;
		quickPlayText.visible        = _showLast;
		quickPlayGlow.visible        = _showLast;

		loadLastPlayed();

		newsPanel = new FlxSprite(0, FlxG.height - 110).makeGraphic(FlxG.width, 40, 0x66000000);
		add(newsPanel);

		newsTitle = new FlxText(20, FlxG.height - 100, 100, Language.getPhrase('news_label', 'NOTICE:'), 16);
		newsTitle.setFormat(Paths.font("vcr.ttf"), 16, currentTheme, LEFT);
		add(newsTitle);

		newsText = new FlxText(130, FlxG.height - 100, FlxG.width - 150, newsItems[0], 16);
		newsText.setFormat(Paths.font("vcr.ttf"), 16, 0xFFEEEEEE, LEFT);
		add(newsText);

		var _showNews:Bool = ClientPrefs.data.showNewsBar;
		newsPanel.visible = _showNews;
		newsTitle.visible = _showNews;
		newsText.visible  = _showNews;

		bottomBarGlow = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 75, currentTheme);
		bottomBarGlow.alpha = 0.1;
		add(bottomBarGlow);

		bottomBar = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 70, 0xCC000000);
		add(bottomBar);

		bottomLine = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 2, currentTheme);
		add(bottomLine);

		versionText = new FlxText(FlxG.width - 300, FlxG.height - 45, 280,
			Language.getPhrase('main_menu_version', 'Psych Engine Ultra') + " " + psychEngineVersion, 16);
		versionText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF888888, RIGHT);
		add(versionText);
		versionText.visible = ClientPrefs.data.showVersionText;

		var wsHint = new FlxText(FlxG.width - 300, FlxG.height - 65, 280,
			Language.getPhrase('workspace_hint', 'SHIFT → Workspace'), 13);
		wsHint.setFormat(Paths.font("vcr.ttf"), 13, 0xFF555555, RIGHT);
		add(wsHint);

		camFollow    = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		camFollow.screenCenter();
		camFollowPos.screenCenter();
		FlxG.camera.follow(camFollowPos, null, 1);

		changeItem();

		adminPanel = new AdminPanel();
		add(adminPanel);

		AIMenu.addToStage();

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);

		addTouchPad("LEFT_RIGHT", "A_B_E");
		super.create();
	}

	override function beatHit()
	{
		super.beatHit();
		if (adminPanel != null)
			adminPanel.onBeat();

		if (isChangelogOpen && changelogLogo != null)
		{
			var bumpSize = 0.7 + bumpIntensity;
			changelogLogo.scale.set(bumpSize, bumpSize);
			FlxTween.cancelTweensOf(changelogLogo.scale);
			FlxTween.tween(changelogLogo.scale, {x: 0.7, y: 0.7}, 0.3, {ease: FlxEase.quadOut});
		}
	}

	function openChangelog()
	{
		isChangelogOpen = true;

		changelogBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		changelogBG.alpha = 0;
		changelogBG.scrollFactor.set();
		add(changelogBG);

		changelogLogo = new FlxSprite().loadGraphic(Paths.image('pet/peulogo'));
		changelogLogo.antialiasing = ClientPrefs.data.antialiasing;
		changelogLogo.setGraphicSize(Std.int(changelogLogo.width * 0.04));
		changelogLogo.updateHitbox();
		changelogLogo.screenCenter(X);
		changelogLogo.y = 30;
		changelogLogo.alpha = 0;
		changelogLogo.scrollFactor.set();
		add(changelogLogo);

		changelogTextTitle = new FlxText(0, changelogLogo.y + changelogLogo.height + 20,
			FlxG.width, Language.getPhrase('changelog_title', 'Psych Engine Ultra'), 32);
		changelogTextTitle.setFormat(Paths.font("vcr.ttf"), 32, 0xFF00E5FF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		changelogTextTitle.screenCenter(X);
		changelogTextTitle.alpha = 0;
		changelogTextTitle.scrollFactor.set();
		add(changelogTextTitle);

		var notes = Language.getPhrase('changelog_notes',
			"\n- Interface Renewed!\n- Profile System Updated\n- Menu Themes Added.\n- Mod Support Optimized.\n- Based on P.E Ultra 0.5\n- Some Bugfixes.\n \n- CURRENT VERSION: Ultra Edition\n Status: Up to Date");

		changelogTextNotes = new FlxText(0, changelogTextTitle.y + 40, FlxG.width - 200, notes, 22);
		changelogTextNotes.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
		changelogTextNotes.screenCenter(X);
		changelogTextNotes.alpha = 0;
		changelogTextNotes.scrollFactor.set();
		add(changelogTextNotes);

		changelogHint = new FlxText(0, FlxG.height - 40, FlxG.width,
			Language.getPhrase('changelog_hint', 'Press ESC or ENTER to close'), 18);
		changelogHint.setFormat(Paths.font("vcr.ttf"), 18, 0xFF888888, CENTER);
		changelogHint.alpha = 0;
		changelogHint.scrollFactor.set();
		add(changelogHint);

		FlxTween.tween(changelogBG,        {alpha: 0.90}, 0.4);
		FlxTween.tween(changelogLogo,      {alpha: 1, y: 50}, 0.5, {ease: FlxEase.backOut,  startDelay: 0.1});
		FlxTween.tween(changelogTextTitle, {alpha: 1},    0.5, {ease: FlxEase.quadOut, startDelay: 0.2});
		FlxTween.tween(changelogTextNotes, {alpha: 1},    0.5, {ease: FlxEase.quadOut, startDelay: 0.3});
		FlxTween.tween(changelogHint,      {alpha: 1},    0.5, {ease: FlxEase.quadOut, startDelay: 0.4});
	}

	function closeChangelog()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));

		FlxTween.tween(changelogBG,        {alpha: 0}, 0.3);
		FlxTween.tween(changelogLogo,      {alpha: 0, "scale.x": 0.5, "scale.y": 0.5}, 0.3);
		FlxTween.tween(changelogTextTitle, {alpha: 0}, 0.3);
		FlxTween.tween(changelogTextNotes, {alpha: 0}, 0.3);
		FlxTween.tween(changelogHint,      {alpha: 0}, 0.3, {
			onComplete: function(t:FlxTween) {
				remove(changelogBG);       remove(changelogLogo);
				remove(changelogTextTitle); remove(changelogTextNotes);
				remove(changelogHint);

				changelogBG.destroy();        changelogLogo.destroy();
				changelogTextTitle.destroy(); changelogTextNotes.destroy();
				changelogHint.destroy();

				isChangelogOpen  = false;
				selectedSomethin = false;
			}
		});
	}

	function createParticles()
	{
		if (!ClientPrefs.data.showParticles) return;
		for (i in 0...40)
		{
			var p = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			var size = Std.int(FlxG.random.float(1, 4));
			p.makeGraphic(size, size, FlxColor.WHITE);
			p.alpha       = FlxG.random.float(0.1, 0.4);
			p.velocity.y  = FlxG.random.float(-15, -5);
			p.velocity.x  = FlxG.random.float(-3, 3);
			add(p);
			particles.push(p);
		}
	}

	function createFloatingOrbs()
	{
		if (!ClientPrefs.data.showFloatingOrbs) return;
		for (i in 0...8)
		{
			var orb = new FlxSprite(FlxG.random.float(400, FlxG.width - 50), FlxG.random.float(100, FlxG.height - 100));
			orb.makeGraphic(Std.int(FlxG.random.float(20, 40)), Std.int(FlxG.random.float(20, 40)), currentTheme);
			orb.alpha = FlxG.random.float(0.05, 0.15);
			add(orb);
			floatingOrbs.push(orb);
		}
	}

	// ==========================================
	//  STATS - PROFIL KISMI PROFILEBOX'A TAŞINDI
	// ==========================================
	function loadStats()
	{
		var totalScore:Int    = 0;
		var songsPlayed:Int   = 0;
		var totalAccuracy:Float = 0;
		var fcCount:Int       = 0;

		for (week in WeekData.weeksList)
		{
			var weekData = WeekData.weeksLoaded.get(week);
			if (weekData == null) continue;

			for (song in weekData.songs)
			{
				for (diff in 0...3)
				{
					var score = Highscore.getScore(song[0], diff);
					if (score > 0)
					{
						totalScore   += score;
						songsPlayed++;

						var acc = Highscore.getRating(song[0], diff);
						if (acc > 0) totalAccuracy += acc;
						if (Highscore.getRating(song[0], diff) >= 100) fcCount++;
					}
				}
			}
		}

		FlxG.save.data.totalScore  = totalScore;
		FlxG.save.data.songsPlayed = songsPlayed;
		FlxG.save.data.fcCount     = fcCount;
		FlxG.save.flush();

		statsTotalScore.text  = formatNumber(totalScore);
		statsSongsPlayed.text = songsPlayed + " " + Language.getPhrase('stats_songs', 'Songs');

		var avgAcc = songsPlayed > 0 ? totalAccuracy / songsPlayed : 0;
		statsAccuracy.text = "%" + FlxMath.roundDecimal(avgAcc, 2);

		if (avgAcc >= 95)      statsAccuracy.color = 0xFF10B981;
		else if (avgAcc >= 85) statsAccuracy.color = 0xFFF59E0B;
		else                   statsAccuracy.color = 0xFFFF5555;

		statsPerfects.text = "FC: " + fcCount;

		var totalMinutes = songsPlayed * 3;
		var hours   = Math.floor(totalMinutes / 60);
		var minutes = totalMinutes % 60;

		if (hours > 0)
			statsPlayTime.text = hours   + " " + Language.getPhrase('stats_hours',   'hr') + " "
			                   + minutes + " " + Language.getPhrase('stats_minutes', 'min');
		else
			statsPlayTime.text = minutes + " " + Language.getPhrase('stats_minutes', 'min');

		// ProfileBox varsa onu da güncelle
		if (profileBox != null)
		{
			profileBox.updateStats(totalScore, songsPlayed, avgAcc, fcCount);
		}
	}

	function loadLastPlayed()
	{
		if (FlxG.save.data.lastPlayedSong != null && FlxG.save.data.lastPlayedSong != "")
		{
			lastPlayedSong.text = FlxG.save.data.lastPlayedSong;

			if (FlxG.save.data.lastPlayedScore != null)
				lastPlayedScore.text = Language.getPhrase('score_label', 'Score') + ": " + formatNumber(FlxG.save.data.lastPlayedScore);

			if (FlxG.save.data.lastPlayedDifficulty != null)
			{
				var diff:Int = FlxG.save.data.lastPlayedDifficulty;
				var diffNames  = [
					Language.getPhrase('diff_easy',   'EASY'),
					Language.getPhrase('diff_normal', 'NORMAL'),
					Language.getPhrase('diff_hard',   'HARD')
				];
				var diffColors = [0xFF10B981, 0xFFF59E0B, 0xFFFF5555];

				if (diff >= 0 && diff < diffNames.length) {
					lastPlayedDifficulty.text  = diffNames[diff];
					lastPlayedDifficulty.color = diffColors[diff];
				} else {
					lastPlayedDifficulty.text  = Language.getPhrase('diff_custom', 'CUSTOM');
					lastPlayedDifficulty.color = 0xFF8B5CF6;
				}
			}
		}
		else
		{
			lastPlayedSong.text      = Language.getPhrase('last_played_none',  'Not played yet');
			lastPlayedDifficulty.text = "-";
			lastPlayedScore.text     = Language.getPhrase('last_played_empty', 'Time to Play!');

			quickPlayText.text  = Language.getPhrase('quick_play_none', 'NONE');
			quickPlayText.color = 0xFF555555;
			quickPlayButton.color = 0xFF222222;
		}
	}

	function playLastSong()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		var songName:String  = FlxG.save.data.lastPlayedSong;
		var difficulty:Int   = FlxG.save.data.lastPlayedDifficulty != null ? FlxG.save.data.lastPlayedDifficulty : 1;
		var songPath         = Paths.formatToSongPath(songName);
		var pooped:String    = Highscore.formatSong(songPath, difficulty);

		try
		{
			PlayState.SONG           = Song.loadFromJson(pooped, songPath);
			PlayState.isStoryMode    = false;
			PlayState.storyDifficulty = difficulty;

			FlxFlicker.flicker(quickPlayButton, 1, 0.06, true, false, function(flick:FlxFlicker)
			{
				LoadingState.loadAndSwitchState(new PlayState());
			});

			FlxTween.tween(lastPlayedPanel, {x: FlxG.width + 500}, 0.5, {ease: FlxEase.backIn});
			if (profileBox != null)
				FlxTween.tween(profileBox, {x: -300}, 0.5, {ease: FlxEase.backIn});
			FlxTween.tween(statsPanel,      {x: FlxG.width + 500}, 0.5, {ease: FlxEase.backIn});
		}
		catch(e:Dynamic)
		{
			trace('Error loading song: $e');
			selectedSomethin = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			lastPlayedSong.text  = Language.getPhrase('song_not_found', 'SONG NOT FOUND!');
			lastPlayedSong.color = 0xFFFF5555;
		}
	}

	function formatNumber(num:Int):String
	{
		var str    = Std.string(num);
		var result = "";
		var count  = 0;
		for (i in 0...str.length)
		{
			if (count > 0 && count % 3 == 0) result = "." + result;
			result = str.charAt(str.length - 1 - i) + result;
			count++;
		}
		return result;
	}

	function updateTimeAndGreeting()
	{
		var now    = Date.now();
		var hour   = now.getHours();
		var minute = now.getMinutes();

		clockText.text = StringTools.lpad(Std.string(hour), "0", 2) + ":" + StringTools.lpad(Std.string(minute), "0", 2);

		var days = [
			Language.getPhrase('day_sun', 'Sunday'),
			Language.getPhrase('day_mon', 'Monday'),
			Language.getPhrase('day_tue', 'Tuesday'),
			Language.getPhrase('day_wed', 'Wednesday'),
			Language.getPhrase('day_thu', 'Thursday'),
			Language.getPhrase('day_fri', 'Friday'),
			Language.getPhrase('day_sat', 'Saturday')
		];
		var months = [
			Language.getPhrase('month_jan', 'January'),
			Language.getPhrase('month_feb', 'February'),
			Language.getPhrase('month_mar', 'March'),
			Language.getPhrase('month_apr', 'April'),
			Language.getPhrase('month_may', 'May'),
			Language.getPhrase('month_jun', 'June'),
			Language.getPhrase('month_jul', 'July'),
			Language.getPhrase('month_aug', 'August'),
			Language.getPhrase('month_sep', 'September'),
			Language.getPhrase('month_oct', 'October'),
			Language.getPhrase('month_nov', 'November'),
			Language.getPhrase('month_dec', 'December')
		];
		dateText.text = days[now.getDay()] + ", " + now.getDate() + " " + months[now.getMonth()];

		var greeting = "";
		if      (hour >= 5  && hour < 12) greeting = Language.getPhrase('greeting_morning', 'Good morning');
		else if (hour >= 12 && hour < 18) greeting = Language.getPhrase('greeting_day',     'Good day');
		else if (hour >= 18 && hour < 22) greeting = Language.getPhrase('greeting_evening', 'Good evening');
		else                               greeting = Language.getPhrase('greeting_night',   'Good night');

		greetingText.text = greeting + ", " + playerName + "!";
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F2)
		{
			if (adminPanel.isOpen) adminPanel.closePanel();
			else                   adminPanel.openPanel();
		}

		if (adminPanel.isOpen)
		{
			adminPanel.handleInput(controls);
			adminPanel.handleUpdate(elapsed);
			if (controls.BACK) adminPanel.closePanel();
			return;
		}

		ambientPulse    += elapsed;
		breathingEffect += elapsed * 2;

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		var lerpVal:Float = FlxMath.bound(elapsed * 9, 0, 1);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);

		updateParticles(elapsed);
		updateWallpaper(elapsed);
		updateNews(elapsed);

		if (Math.floor(ambientPulse) % 30 == 0 && Math.floor(ambientPulse) > 0)
			updateTimeAndGreeting();

		if (!isChangelogOpen && !selectedSomethin)
			WorkspaceSwitcher.handleInput(elapsed);

		if (WorkspaceSwitcher.isOpen) return;

		if (isChangelogOpen)
		{
			if (controls.BACK || controls.ACCEPT) closeChangelog();
			return;
		}

		if (!selectedSomethin)
		{
			handleCheats(elapsed);

			if (controls.UI_LEFT_P)  changeItem(-1);
			if (controls.UI_RIGHT_P) changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectEntry();
			}
			else if (controls.justPressed('debug_1') || touchPad.buttonE.justPressed)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new OnlineModsState());
			}

			if (FlxG.save.data.lastPlayedSong != null && FlxG.save.data.lastPlayedSong != "")
			{
				if (FlxG.mouse.overlaps(quickPlayButton))
				{
					quickPlayGlow.alpha = 0.6 + Math.sin(breathingEffect * 4) * 0.4;
					quickPlayButton.scale.set(1.05, 1.05);
					if (FlxG.mouse.justPressed) playLastSong();
				}
				else
				{
					quickPlayGlow.alpha = 0;
					quickPlayButton.scale.set(1, 1);
				}
			}
		}

		updateCardPositions(elapsed, lerpVal);
		if (ClientPrefs.data.showParallax) updateParallax(elapsed, lerpVal);
		updateFloatingOrbs(elapsed);

		// ProfileBox glow animasyonu yok - kendi içinde hallediyor
		if (statsPanelGlow   != null) statsPanelGlow.alpha   = 0.1 + Math.sin(ambientPulse * 2 + 1) * 0.05;
		if (topBarGlow       != null) topBarGlow.alpha       = 0.15 + Math.sin(ambientPulse) * 0.05;
		if (bottomBarGlow    != null) bottomBarGlow.alpha    = 0.1 + Math.sin(ambientPulse + 2) * 0.05;
	}

	function updateCardPositions(elapsed:Float, lerpVal:Float)
	{
		var centerX = FlxG.width / 2;
		var spacing = 240;

		menuCards.forEach(function(card:FlxSpriteGroup)
		{
			var targetX = centerX - 100 + (card.ID - curSelected) * spacing;
			var targetY = FlxG.height / 2 - 140;

			if (card.ID == curSelected)
			{
				targetY -= 20;
				card.scale.set(FlxMath.lerp(card.scale.x, 1.1, lerpVal), FlxMath.lerp(card.scale.y, 1.1, lerpVal));
				card.alpha = FlxMath.lerp(card.alpha, 1, lerpVal);
				cardGlows[card.ID].alpha = 0.3 + Math.sin(breathingEffect * 2) * 0.1;
			}
			else
			{
				card.scale.set(FlxMath.lerp(card.scale.x, 0.9, lerpVal), FlxMath.lerp(card.scale.y, 0.9, lerpVal));
				card.alpha = FlxMath.lerp(card.alpha, 0.4, lerpVal);
				cardGlows[card.ID].alpha = 0;
			}

			card.x = FlxMath.lerp(card.x, targetX, lerpVal);
			card.y = FlxMath.lerp(card.y, targetY, lerpVal);
		});
	}

	function updateParallax(elapsed:Float, lerpVal:Float)
	{
		var mouseOffsetX = (FlxG.mouse.screenX - FlxG.width / 2) / FlxG.width;
		var mouseOffsetY = (FlxG.mouse.screenY - FlxG.height / 2) / FlxG.height;
		bgLayer1.x = FlxMath.lerp(bgLayer1.x, -100 - mouseOffsetX * 30, lerpVal);
		bgLayer1.y = FlxMath.lerp(bgLayer1.y, -100 - mouseOffsetY * 30, lerpVal);
		bgLayer2.x = FlxMath.lerp(bgLayer2.x, -50  - mouseOffsetX * 60, lerpVal);
		bgLayer2.y = FlxMath.lerp(bgLayer2.y, -50  - mouseOffsetY * 60, lerpVal);
	}

	function updateParticles(elapsed:Float)
	{
		for (p in particles)
		{
			if (p.y < -10)
			{
				p.y = FlxG.height + 10;
				p.x = FlxG.random.float(0, FlxG.width);
			}
			p.alpha = 0.1 + Math.sin(ambientPulse + p.x * 0.01) * 0.1;
		}
	}

	function updateNews(elapsed:Float)
	{
		newsTimer += elapsed;
		if (newsTimer > 5)
		{
			newsTimer = 0;
			newsIndex = (newsIndex + 1) % newsItems.length;
			FlxTween.tween(newsText, {alpha: 0}, 0.3, {
				onComplete: function(twn:FlxTween) {
					newsText.text = newsItems[newsIndex];
					FlxTween.tween(newsText, {alpha: 1}, 0.3);
				}
			});
		}
	}

	function updateFloatingOrbs(elapsed:Float)
	{
		for (i in 0...floatingOrbs.length)
		{
			var orb = floatingOrbs[i];
			orb.y += Math.sin(ambientPulse + i) * 0.5;
			orb.x += Math.cos(ambientPulse * 0.5 + i) * 0.3;
			orb.alpha = 0.05 + Math.sin(ambientPulse + i * 0.5) * 0.05;
			if (orb.x < -100) orb.x = FlxG.width + 100;
			if (orb.x > FlxG.width + 100) orb.x = -100;
			if (orb.y < -100) orb.y = FlxG.height + 100;
			if (orb.y > FlxG.height + 100) orb.y = -100;
		}
	}

	function changeItem(change:Int = 0)
	{
		curSelected += change;
		if (curSelected >= optionShit.length) curSelected = 0;
		if (curSelected < 0) curSelected = optionShit.length - 1;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var choice:String    = optionShit[curSelected];
		var newColor:FlxColor = menuColorMap.exists(choice) ? menuColorMap.get(choice) : 0xFF333333;

		currentTheme = newColor;
		if (!ClientPrefs.data.menuVideo)
			FlxTween.color(bgLayer2, 0.5, bgLayer2.color, newColor);
		FlxTween.color(topBarLine,       0.3, topBarLine.color,       newColor);
		FlxTween.color(topBarGlow,       0.3, topBarGlow.color,       newColor);
		FlxTween.color(bottomLine,       0.3, bottomLine.color,       newColor);
		FlxTween.color(descriptionTitle, 0.3, descriptionTitle.color, newColor);

		descriptionTitle.text = menuTitles.get(choice);
		descriptionText.text  = menuDescriptions.get(choice);

		descriptionText.alpha = 0;
		descriptionText.y     = 170;
		FlxTween.tween(descriptionText, {alpha: 1, y: 160}, 0.3, {ease: FlxEase.quadOut});

		camFollow.x = FlxG.width / 2 + (curSelected - (optionShit.length / 2)) * 50;
	}

	function selectEntry()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		if (optionShit[curSelected] == 'changelog')
		{
			openChangelog();
			return;
		}

		menuCards.forEach(function(card:FlxSpriteGroup)
		{
			if (curSelected != card.ID)
			{
				FlxTween.tween(card, {alpha: 0, y: FlxG.height + 200}, 0.6, {ease: FlxEase.backIn});
			}
			else
			{
				FlxFlicker.flicker(card, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					var daChoice:String = optionShit[curSelected];
					switch (daChoice)
					{
						case 'story_mode':   ThemeManager.switchToStoryMenu();
						case 'freeplay':     ThemeManager.switchToFreeplay();
						case 'achievements': ThemeManager.switchToAchievements();
						case 'credits':      ThemeManager.switchToCredits();
						case 'settings':     ThemeManager.switchToOptions();
						#if MODS_ALLOWED
						case 'mods':         ThemeManager.switchToMods();
						#end
					}
				});
			}
		});

		// ==========================================
		//  ÇIKIŞ ANİMASYONLARI - ProfileBox dahil
		// ==========================================
		FlxTween.tween(topBar,          {y: -100},              0.5, {ease: FlxEase.backIn});
		FlxTween.tween(bottomBar,       {y: FlxG.height + 100}, 0.5, {ease: FlxEase.backIn});

		// ProfileBox varsa animasyon ile kaldır
		if (profileBox != null)
			FlxTween.tween(profileBox,  {x: -300}, 0.5, {ease: FlxEase.backIn});

		FlxTween.tween(statsPanel,      {x: -300},              0.5, {ease: FlxEase.backIn, startDelay: 0.05});
		FlxTween.tween(lastPlayedPanel, {x: -300},              0.5, {ease: FlxEase.backIn, startDelay: 0.1});
		FlxTween.tween(newsPanel,       {y: FlxG.height + 100}, 0.5, {ease: FlxEase.backIn});
	}

	function handleCheats(elapsed:Float)
	{
		var upNow    = controls.UI_UP_P;
		var rightNow = controls.UI_RIGHT_P;
		var leftNow  = controls.UI_LEFT_P;

		if (upNow    && !prevUp)    { cheatSequence.push(0); cheatLastInputTime = 0; }
		if (rightNow && !prevRight) { cheatSequence.push(3); cheatLastInputTime = 0; }
		if (leftNow  && !prevLeft)  { cheatSequence.push(2); cheatLastInputTime = 0; }

		prevUp = upNow; prevRight = rightNow; prevLeft = leftNow;
		cheatLastInputTime += elapsed;
		if (cheatLastInputTime > cheatTimeout) cheatSequence = [];

		if (cheatSequence.length > cheatPattern.length) cheatSequence.shift();
		if (cheatSequence.toString() == cheatPattern.toString()) {
			selectedSomethin = true;
			FlxG.sound.play(Paths.sound('secret'));
			MusicBeatState.switchState(new CodeMenuState());
		}
	}

	override function destroy()
	{
		if (WorkspaceSwitcher.isOpen)
		{
			WorkspaceSwitcher.forceClose();
		}

		#if VIDEOS_ALLOWED
		if (menuVideoBG != null)
		{
			menuVideoBG.videoSprite.bitmap.stop();
			menuVideoBG.destroy();
			menuVideoBG = null;
		}
		#end
		super.destroy();
	}
}