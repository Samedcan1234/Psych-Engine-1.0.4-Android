package options;

import states.MainMenuState;
import backend.StageData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxObject;
import flixel.util.FlxGradient;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.util.FlxTimer;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [];

	private var categoryCards:FlxTypedGroup<FlxSprite>;
	private var cardGlows:FlxTypedGroup<FlxSprite>;
	private var cardBorders:FlxTypedGroup<FlxSprite>;
	private var cardIcons:FlxTypedGroup<FlxSprite>;
	private var cardTitleTexts:FlxTypedGroup<FlxText>;
	private var cardDescTexts:FlxTypedGroup<FlxText>;
	private var cardBadges:FlxTypedGroup<FlxSprite>;
	
	private static var curSelected:Int = 0;
	private var curRow:Int = 0;
	private var curCol:Int = 0;
	private var gridCols:Int = 3;
	
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var secretCode:Array<FlxKey> = [FlxKey.X, FlxKey.Q, FlxKey.B, FlxKey.O, FlxKey.K, FlxKey.Y, FlxKey.E];
	var secretIndex:Int = 0;
	var secretUnlocked:Bool = false;

	var bg:FlxSprite;
	var bgPattern:FlxBackdrop;
	var bgDarken:FlxSprite;
	var bgVignette:FlxSprite;
	var bgOrbs:FlxTypedGroup<FlxSprite>;
	
	var gradientGroup:FlxTypedGroup<FlxSprite>; 
	
	var headerPanel:FlxSprite;
	var headerGlow:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var breadcrumbText:FlxText;
	var versionText:FlxText;
	
	var profilePanel:FlxSprite;
	var profileIcon:FlxSprite;
	var profileName:FlxText;
	var profileStats:FlxText;
	
	var descPanel:FlxSprite;
	var descPanelGlow:FlxSprite;
	var descIcon:FlxSprite;
	var descTitle:FlxText;
	var descText:FlxText;
	var descStats:FlxText;
	
	var particleEmitter:FlxEmitter;
	var secondaryParticles:FlxEmitter;
	var glowEffect:FlxSprite;
	var selectionGlow:FlxSprite;
	var scanlines:FlxSprite;
	var floatingShapes:FlxTypedGroup<FlxSprite>;
	
	var controlHintsPanel:FlxSprite;
	var controlHintsText:FlxText;
	
	var targetScrollY:Float = 0;
	
	var animTimer:Float = 0;
	var pulseTimer:Float = 0;
	var waveTimer:Float = 0;
	var floatTimer:Float = 0;
	var glowTimer:Float = 0;
	var orbTimer:Float = 0;
	
	var cardWidth:Int = 340;
	var cardHeight:Int = 140;
	var cardSpacingX:Int = 20;
	var cardSpacingY:Int = 15;
	var gridStartX:Float = 70;
	var gridStartY:Float = 135;

	var optionsColor:Map<String, Array<Int>> = [];
	var optionsIconPaths:Map<String, String> = [];
	var optionsDesc:Map<String, String> = [];
	var optionsStats:Map<String, String> = [];

	override function create()
	{
		FlxG.camera.scroll.y = 0;
		_buildLanguageData();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Settings Menu", null);
		#end

		createBackgroundSystem();
		createParticleSystems();
		createFloatingShapes();
		createCardGrid();
		createHeader();
		createProfilePanel();
		createDescriptionPanel();
		createControlHints();
		playEntranceAnimation();
		
		updateGridSelection();
		changeSelection();
		ClientPrefs.saveSettings();

		addTouchPad('LEFT_FULL', 'A_B_C');
		addTouchPadCamera();

		super.create();
	}
	
	function _buildLanguageData():Void
	{
		options = [
			Language.getPhrase('opt_note_colors',   'Note Colors'),
			Language.getPhrase('opt_controls',      'Controls'),
			Language.getPhrase('opt_delay_combo',   'Delay & Combo'),
			Language.getPhrase('opt_graphics',      'Graphics & Performance'),
			Language.getPhrase('opt_interface',     'Interface & Visuals'),
			Language.getPhrase('opt_gameplay',      'Gameplay'),
			Language.getPhrase('opt_peu',           'P.E.U Settings'),
			Language.getPhrase('opt_menu_settings', 'Menu Settings')
		];
		#if TRANSLATIONS_ALLOWED
		options.push(Language.getPhrase('opt_language', 'Language'));
		#end
		#if mobile
		options.push(Language.getPhrase('opt_mobile', 'Mobile Settings'));
		#end

		optionsDesc = [
			Language.getPhrase('opt_note_colors',   'Note Colors')             => Language.getPhrase('opt_desc_note_colors',   'Customize the colors and appearance of the notes however you like.'),
			Language.getPhrase('opt_controls',      'Controls')                => Language.getPhrase('opt_desc_controls',      'Configure keyboard and gamepad button assignments.'),
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')           => Language.getPhrase('opt_desc_delay_combo',   'Adjust the audio and video settings. Change the combo display style.'),
			Language.getPhrase('opt_graphics',      'Graphics & Performance')  => Language.getPhrase('opt_desc_graphics',      'Optimize graphics quality, FPS limit, and performance settings.'),
			Language.getPhrase('opt_interface',     'Interface & Visuals')     => Language.getPhrase('opt_desc_interface',     'Customize the menu design and in-game visuals.'),
			Language.getPhrase('opt_gameplay',      'Gameplay')                => Language.getPhrase('opt_desc_gameplay',      'Customize Your Game Settings to Suit Your Style!'),
			Language.getPhrase('opt_language',      'Language')                => Language.getPhrase('opt_desc_language',      'Change the game language and view the localization options.'),
			Language.getPhrase('opt_peu',           'P.E.U Settings')          => Language.getPhrase('opt_desc_peu',           'Customize Psych Engine Ultra Settings.'),
			Language.getPhrase('opt_menu_settings', 'Menu Settings')           => Language.getPhrase('opt_desc_menu_settings', 'Customize the main menu appearance.')
		];

		optionsStats = [
			Language.getPhrase('opt_note_colors',   'Note Colors')             => Language.getPhrase('opt_stat_note_colors',   'Adjust Note Colors Using Colors.'),
			Language.getPhrase('opt_controls',      'Controls')                => Language.getPhrase('opt_stat_controls',      'Default: W-A-S-D'),
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')           => Language.getPhrase('opt_stat_delay_combo',   'Default ms: 0'),
			Language.getPhrase('opt_graphics',      'Graphics & Performance')  => Language.getPhrase('opt_stat_graphics',      'Manage Your Gaming Performance'),
			Language.getPhrase('opt_interface',     'Interface & Visuals')     => Language.getPhrase('opt_stat_interface',     'Select your Note Skins.'),
			Language.getPhrase('opt_gameplay',      'Gameplay')                => Language.getPhrase('opt_stat_gameplay',      'Manage Gameplay Settings'),
			Language.getPhrase('opt_language',      'Language')                => Language.getPhrase('opt_stat_language',      'Select Your Language Here!'),
			Language.getPhrase('opt_peu',           'P.E.U Settings')          => Language.getPhrase('opt_stat_peu',           'Customize P.E.U'),
			Language.getPhrase('opt_menu_settings', 'Menu Settings')           => Language.getPhrase('opt_stat_menu_settings', 'Customize Main Menu')
		];

		optionsColor = [
			Language.getPhrase('opt_note_colors',   'Note Colors')             => [0xFF9B59B6, 0xFF8E44AD, 0xFF6C3483],
			Language.getPhrase('opt_controls',      'Controls')                => [0xFFE67E22, 0xFFD35400, 0xFFA04000],
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')           => [0xFFE74C3C, 0xFFC0392B, 0xFF922B21],
			Language.getPhrase('opt_graphics',      'Graphics & Performance')  => [0xFF3498DB, 0xFF2980B9, 0xFF1F618D],
			Language.getPhrase('opt_interface',     'Interface & Visuals')     => [0xFF9B59B6, 0xFF8E44AD, 0xFF6C3483],
			Language.getPhrase('opt_gameplay',      'Gameplay')                => [0xFF2ECC71, 0xFF27AE60, 0xFF1E8449],
			Language.getPhrase('opt_language', 'Language')                   => [0xFF7F8C8D, 0xFF707B7C, 0xFF212F3D],
			Language.getPhrase('opt_peu', 'P.E.U Settings')                  => [0xFF8E44AD, 0xFF7D3C98, 0xFF4A235A],
			Language.getPhrase('opt_menu_settings', 'Menu Settings')         => [0xFFF39C12, 0xFFD68910, 0xFF7E5109],
		];

		optionsIconPaths = [
			Language.getPhrase('opt_note_colors',   'Note Colors')             => 'note_colors',
			Language.getPhrase('opt_controls',      'Controls')                => 'controls',
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')           => 'delay_and_combo',
			Language.getPhrase('opt_graphics',      'Graphics & Performance')  => 'graphics_and_performance',
			Language.getPhrase('opt_interface',     'Interface & Visuals')     => 'interface_and_visuals',
			Language.getPhrase('opt_gameplay',      'Gameplay')                => 'gameplay',
			Language.getPhrase('opt_language',      'Language')                => 'language',
			Language.getPhrase('opt_peu',           'P.E.U Settings')          => 'peu',
			Language.getPhrase('opt_menu_settings', 'Menu Settings')           => 'menu_settings'
		];
	}

	function openSelectedSubstate(label:String)
	{
		if (label != Language.getPhrase('opt_delay_combo', 'Delay & Combo'))
		{
			removeTouchPad();
			persistentUpdate = false;
		}

		playExitAnimation(function() {
			if      (label == Language.getPhrase('opt_note_colors',   'Note Colors'))            openSubState(new options.NotesColorSubState());
			else if (label == Language.getPhrase('opt_controls',      'Controls'))               openSubState(new options.ControlsSubState());
			else if (label == Language.getPhrase('opt_graphics',      'Graphics & Performance')) openSubState(new options.GraphicsSettingsSubState());
			else if (label == Language.getPhrase('opt_interface',     'Interface & Visuals'))    openSubState(new options.VisualsSettingsSubState());
			else if (label == Language.getPhrase('opt_gameplay',      'Gameplay'))               openSubState(new options.GameplaySettingsSubState());
			else if (label == Language.getPhrase('opt_delay_combo',   'Delay & Combo'))          MusicBeatState.switchState(new options.NoteOffsetState());
			else if (label == Language.getPhrase('opt_language',      'Language'))               openSubState(new options.LanguageSubState());
			else if (label == Language.getPhrase('opt_peu',           'P.E.U Settings'))         openSubState(new options.PEUSettingsState());
			else if (label == Language.getPhrase('opt_menu_settings', 'Menu Settings'))          openSubState(new options.MainMenuSettingsState());
			#if mobile
			else if (label == Language.getPhrase('opt_mobile', 'Mobile Settings'))              openSubState(new mobile.options.MobileOptionsSubState());
			#end
		});
	}
	
	function openSecretMenu()
	{
		playExitAnimation(function() {
			openSubState(new options.XqOptionsState());
		});
	}

	function createBackgroundSystem()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.5));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.25;
		bg.scrollFactor.set(0.02, 0.02);
		add(bg);
		
		bgPattern = new FlxBackdrop(null, XY, 0, 0);
		bgPattern.makeGraphic(120, 120, FlxColor.TRANSPARENT, true);
		drawGridPattern(bgPattern);
		bgPattern.velocity.set(15, 10);
		bgPattern.alpha = 0;
		bgPattern.scrollFactor.set(0, 0);
		add(bgPattern);
		
		gradientGroup = new FlxTypedGroup<FlxSprite>();
		add(gradientGroup);
		
		for (i in 0...options.length)
		{
			var opt = options[i];
			var colors = optionsColor.exists(opt) ? optionsColor.get(opt) : [0xFF444444, 0xFF333333, 0xFF222222];
			var grad = FlxGradient.createGradientFlxSprite(
				FlxG.width, FlxG.height,
				[colors[0], colors[1], colors[2], 0xFF0a0a15],
				1, 135
			);
			grad.alpha = 0;
			grad.scrollFactor.set(0, 0);
			grad.ID = i;
			gradientGroup.add(grad);
		}
		
		bgOrbs = new FlxTypedGroup<FlxSprite>();
		add(bgOrbs);
		
		for (i in 0...8)
		{
			var orb = new FlxSprite(Math.random() * FlxG.width, Math.random() * FlxG.height);
			orb.makeGraphic(Std.int(80 + Math.random() * 120), Std.int(80 + Math.random() * 120), FlxColor.WHITE);
			orb.blend = ADD;
			orb.alpha = 0;
			orb.scrollFactor.set(0.05, 0.05);
			orb.ID = i;
			bgOrbs.add(orb);
		}
		
		bgVignette = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0x00000000, 0x00000000, 0x66000000],
			1, 0, true
		);
		bgVignette.scrollFactor.set(0, 0);
		add(bgVignette);
		
		bgDarken = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bgDarken.alpha = 0;
		bgDarken.scrollFactor.set(0, 0);
		add(bgDarken);
		
		glowEffect = new FlxSprite(FlxG.width / 2 - 600, FlxG.height / 2 - 600);
		glowEffect.makeGraphic(1200, 1200, FlxColor.WHITE);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		glowEffect.scrollFactor.set(0, 0);
		add(glowEffect);
		
		selectionGlow = new FlxSprite();
		selectionGlow.makeGraphic(cardWidth + 40, cardHeight + 40, FlxColor.WHITE);
		selectionGlow.blend = ADD;
		selectionGlow.alpha = 0;
		selectionGlow.scrollFactor.set(1, 1);
		add(selectionGlow);
		
		scanlines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true);
		drawScanlines(scanlines);
		scanlines.alpha = 0.03;
		scanlines.scrollFactor.set(0, 0);
		add(scanlines);
	}
	
	function drawGridPattern(sprite:FlxSprite)
	{
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		for (i in 0...Std.int(sprite.width / 20))
			g.fillRect(new flash.geom.Rectangle(i * 20, 0, 1, sprite.height), 0x11FFFFFF);
		for (i in 0...Std.int(sprite.height / 20))
			g.fillRect(new flash.geom.Rectangle(0, i * 20, sprite.width, 1), 0x11FFFFFF);
		for (i in 0...Std.int(sprite.width / 20))
			for (j in 0...Std.int(sprite.height / 20))
				g.fillRect(new flash.geom.Rectangle(i * 20 - 1, j * 20 - 1, 3, 3), 0x22FFFFFF);
	}
	
	function drawScanlines(sprite:FlxSprite)
	{
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		for (i in 0...Std.int(FlxG.height / 3))
			g.fillRect(new flash.geom.Rectangle(0, i * 3, FlxG.width, 1), 0x08000000);
	}
	
	function createParticleSystems()
	{
		particleEmitter = new FlxEmitter(FlxG.width / 2, 50, 80);
		particleEmitter.width = FlxG.width;
		for (i in 0...80)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(3, 3, FlxColor.WHITE);
			particle.blend = ADD;
			particle.scrollFactor.set(0, 0);
			particle.exists = false;
			particleEmitter.add(particle);
		}
		particleEmitter.launchMode = FlxEmitterMode.SQUARE;
		particleEmitter.velocity.set(-30, 40, 30, 150);
		particleEmitter.lifespan.set(4, 8);
		particleEmitter.alpha.set(0.2, 0.5, 0, 0);
		particleEmitter.scale.set(1, 2, 0.3, 0.3);
		particleEmitter.start(false, 0.05);
		add(particleEmitter);
		
		secondaryParticles = new FlxEmitter(FlxG.width / 2, FlxG.height / 2, 40);
		secondaryParticles.width  = FlxG.width;
		secondaryParticles.height = FlxG.height;
		for (i in 0...40)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(5, 5, FlxColor.WHITE);
			particle.alpha  = 0.15;
			particle.scrollFactor.set(0, 0);
			particle.exists = false;
			secondaryParticles.add(particle);
		}
		secondaryParticles.launchMode = FlxEmitterMode.SQUARE;
		secondaryParticles.velocity.set(-15, -15, 15, 15);
		secondaryParticles.lifespan.set(6, 12);
		secondaryParticles.alpha.set(0.08, 0.15, 0, 0);
		secondaryParticles.start(false, 0.2);
		add(secondaryParticles);
	}
	
	function createFloatingShapes()
	{
		floatingShapes = new FlxTypedGroup<FlxSprite>();
		add(floatingShapes);
		for (i in 0...15)
		{
			var shape = new FlxSprite(Math.random() * FlxG.width, Math.random() * FlxG.height);
			shape.makeGraphic(30, 30, FlxColor.WHITE);
			shape.blend = ADD;
			shape.alpha = 0;
			shape.scrollFactor.set(0.05 + Math.random() * 0.1, 0.05 + Math.random() * 0.1);
			shape.ID = i;
			floatingShapes.add(shape);
		}
	}
	
	function createHeader()
	{
		headerPanel = new FlxSprite(0, -110).makeGraphic(FlxG.width, 110, 0xEE000000);
		headerPanel.scrollFactor.set(0, 0);
		add(headerPanel);
		
		headerGlow = new FlxSprite(0, -110).makeGraphic(FlxG.width, 4, FlxColor.WHITE);
		headerGlow.blend = ADD;
		headerGlow.alpha = 0.5;
		headerGlow.scrollFactor.set(0, 0);
		add(headerGlow);
		
		titleText = new FlxText(40, 15, FlxG.width - 280, Language.getPhrase('settings_title', 'Settings'), 44);
		titleText.setFormat(Paths.font("vcr.ttf"), 44, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF8D58FD);
		titleText.borderSize = 4;
		titleText.scrollFactor.set(0, 0);
		titleText.alpha = 0;
		add(titleText);
		
		subtitleText = new FlxText(40, 62, FlxG.width - 280, Language.getPhrase('settings_subtitle', 'Customize your gaming experience!'), 18);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFBBBBBB, LEFT);
		subtitleText.scrollFactor.set(0, 0);
		subtitleText.alpha = 0;
		add(subtitleText);
		
		breadcrumbText = new FlxText(40, 86, FlxG.width - 280, Language.getPhrase('settings_breadcrumb', 'Main Menu > Settings'), 12);
		breadcrumbText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		breadcrumbText.scrollFactor.set(0, 0);
		breadcrumbText.alpha = 0;
		add(breadcrumbText);
	}
	
	function createProfilePanel()
	{
		profilePanel = new FlxSprite(FlxG.width - 200, 12).makeGraphic(185, 85, 0x88000000);
		profilePanel.scrollFactor.set(0, 0);
		profilePanel.alpha = 0;
		add(profilePanel);
		
		profileIcon = new FlxSprite(FlxG.width - 190, 20);
		if (Paths.image('ultra/settings/images/player') != null)
		{
			profileIcon.loadGraphic(Paths.image('ultra/settings/images/player'));
			profileIcon.setGraphicSize(65, 65);
			profileIcon.updateHitbox();
		}
		else
			profileIcon.makeGraphic(65, 65, 0x66FFFFFF);
		profileIcon.scrollFactor.set(0, 0);
		profileIcon.antialiasing = ClientPrefs.data.antialiasing;
		profileIcon.alpha = 0;
		add(profileIcon);
		
		profileName = new FlxText(FlxG.width - 115, 28, 100, Language.getPhrase('profile_name', 'Oyuncu'), 18);
		profileName.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		profileName.borderSize = 2;
		profileName.scrollFactor.set(0, 0);
		profileName.alpha = 0;
		add(profileName);
		
		profileStats = new FlxText(FlxG.width - 115, 52, 100, "Lv. 1", 13);
		profileStats.setFormat(Paths.font("vcr.ttf"), 13, 0xFFFFD700, LEFT);
		profileStats.scrollFactor.set(0, 0);
		profileStats.alpha = 0;
		add(profileStats);
	}
	
	function createCardGrid()
	{
		categoryCards    = new FlxTypedGroup<FlxSprite>();  add(categoryCards);
		cardGlows        = new FlxTypedGroup<FlxSprite>();  add(cardGlows);
		cardBorders      = new FlxTypedGroup<FlxSprite>();  add(cardBorders);
		cardIcons        = new FlxTypedGroup<FlxSprite>();  add(cardIcons);
		cardTitleTexts   = new FlxTypedGroup<FlxText>();    add(cardTitleTexts);
		cardDescTexts    = new FlxTypedGroup<FlxText>();    add(cardDescTexts);
		cardBadges       = new FlxTypedGroup<FlxSprite>();  add(cardBadges);

		for (num => option in options)
		{
			var row   = Std.int(num / gridCols);
			var col   = num % gridCols;
			var cardX = gridStartX + (col * (cardWidth  + cardSpacingX));
			var cardY = gridStartY + (row * (cardHeight + cardSpacingY));
			
			var colors = optionsColor.exists(option) ? optionsColor.get(option) : [0xFF444444, 0xFF333333, 0xFF222222];
			var glow:FlxSprite = FlxGradient.createGradientFlxSprite(
				cardWidth + 20, cardHeight + 20, [colors[0], 0x00000000], 1, 0, true);
			glow.x = cardX - 10; glow.y = cardY - 10;
			glow.blend = ADD; glow.alpha = 0;
			glow.scrollFactor.set(1, 1); glow.ID = num;
			cardGlows.add(glow);
			
			var card:FlxSprite = FlxGradient.createGradientFlxSprite(cardWidth, cardHeight, colors, 1, 135);
			card.x = cardX; card.y = cardY;
			card.alpha = 0; card.scrollFactor.set(1, 1); card.ID = num;
			categoryCards.add(card);
			
			var border:FlxSprite = new FlxSprite(cardX, cardY + cardHeight - 4).makeGraphic(cardWidth, 4, FlxColor.WHITE);
			border.alpha = 0; border.scrollFactor.set(1, 1); border.ID = num;
			cardBorders.add(border);
			
			var iconPath = optionsIconPaths.exists(option) ? optionsIconPaths.get(option) : 'pet';
			var icon:FlxSprite = new FlxSprite(cardX + 12, cardY + 12);
			if (Paths.image('ultra/settings/images/' + iconPath) != null)
			{
				icon.loadGraphic(Paths.image('ultra/settings/images/' + iconPath));
				icon.setGraphicSize(70, 70); icon.updateHitbox();
			}
			else icon.makeGraphic(70, 70, 0x66FFFFFF);
			icon.alpha = 0; icon.scrollFactor.set(1, 1); icon.ID = num;
			icon.antialiasing = ClientPrefs.data.antialiasing;
			cardIcons.add(icon);
			
			var titleTxt:FlxText = new FlxText(cardX + 95, cardY + 20, cardWidth - 110, option, 22);
			titleTxt.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			titleTxt.borderSize = 2; titleTxt.alpha = 0;
			titleTxt.scrollFactor.set(1, 1); titleTxt.ID = num;
			cardTitleTexts.add(titleTxt);
			
			var stats = optionsStats.exists(option) ? optionsStats.get(option) : 'Settings';
			var cardDesc:FlxText = new FlxText(cardX + 95, cardY + 52, cardWidth - 110, stats, 12);
			cardDesc.setFormat(Paths.font("vcr.ttf"), 12, 0xFFCCCCCC, LEFT);
			cardDesc.alpha = 0; cardDesc.scrollFactor.set(1, 1); cardDesc.ID = num;
			cardDescTexts.add(cardDesc);
		}
	}
	
	function createDescriptionPanel()
	{
		descPanel = new FlxSprite(25, FlxG.height).makeGraphic(FlxG.width - 50, 85, 0xDD000000);
		descPanel.scrollFactor.set(0, 0); add(descPanel);
		
		descPanelGlow = new FlxSprite(25, FlxG.height).makeGraphic(FlxG.width - 50, 3, FlxColor.WHITE);
		descPanelGlow.blend = ADD; descPanelGlow.alpha = 0.4;
		descPanelGlow.scrollFactor.set(0, 0); add(descPanelGlow);
		
		descIcon = new FlxSprite(40, FlxG.height + 12);
		descIcon.makeGraphic(55, 55, 0x66FFFFFF);
		descIcon.scrollFactor.set(0, 0);
		descIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(descIcon);
		
		descTitle = new FlxText(110, FlxG.height + 10, FlxG.width - 160, "", 20);
		descTitle.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFD700, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descTitle.borderSize = 2; descTitle.scrollFactor.set(0, 0); add(descTitle);
		
		descText = new FlxText(110, FlxG.height + 38, FlxG.width - 160, "", 14);
		descText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		descText.scrollFactor.set(0, 0); add(descText);
		
		descStats = new FlxText(FlxG.width - 200, FlxG.height + 15, 170, "", 11);
		descStats.setFormat(Paths.font("vcr.ttf"), 11, 0xFF888888, RIGHT);
		descStats.scrollFactor.set(0, 0); add(descStats);
	}
	
	function createControlHints()
	{
		controlHintsPanel = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 28, 0xAA000000);
		controlHintsPanel.scrollFactor.set(0, 0); add(controlHintsPanel);

		var hintStr:String = controls.mobileC
			? Language.getPhrase('settings_hint_mobile',  'D-PAD: Gezin  |  A: Sec  |  B: Geri  |  C: Mobil Kontroller')
			: Language.getPhrase('settings_hint_desktop', 'YUKARI/ASAGI/SOL/SAG: Gezin   |   ENTER: Sec   |   ESC: Geri');
		
		controlHintsText = new FlxText(0, FlxG.height + 6, FlxG.width, hintStr, 12);
		controlHintsText.setFormat(Paths.font("vcr.ttf"), 12, 0xFFAAAAAA, CENTER);
		controlHintsText.scrollFactor.set(0, 0);
		controlHintsText.alpha = 0;
		add(controlHintsText);
	}
	
	function playEntranceAnimation()
	{
		FlxTween.tween(bgDarken,   {alpha: 0.6},  0.8, {ease: FlxEase.quartOut});
		FlxTween.tween(bgPattern,  {alpha: 0.06}, 1.2, {ease: FlxEase.quartOut, startDelay: 0.2});
		FlxTween.tween(glowEffect, {alpha: 0.1},  1,   {ease: FlxEase.quartOut, startDelay: 0.3});
		
		for (grad in gradientGroup.members)
		{
			if (grad != null && grad.ID == curSelected)
			{
				FlxTween.tween(grad, {alpha: 0.85}, 1, {ease: FlxEase.quartOut, startDelay: 0.1});
			}
		}
		
		for (orb in bgOrbs)
			FlxTween.tween(orb, {alpha: 0.08 + Math.random() * 0.08}, 1.5,
				{ease: FlxEase.quartOut, startDelay: 0.5 + Math.random() * 0.5});
		
		for (shape in floatingShapes)
			FlxTween.tween(shape, {alpha: 0.1 + Math.random() * 0.15}, 1.5,
				{ease: FlxEase.quartOut, startDelay: 0.6 + Math.random() * 0.6});
		
		FlxTween.tween(headerPanel,   {y: 0},   0.8, {ease: FlxEase.expoOut,  startDelay: 0.1});
		FlxTween.tween(headerGlow,    {y: 106}, 0.8, {ease: FlxEase.expoOut,  startDelay: 0.1});
		FlxTween.tween(titleText,     {alpha: 1}, 0.7, {ease: FlxEase.quartOut, startDelay: 0.3});
		FlxTween.tween(subtitleText,  {alpha: 0.8}, 0.7, {ease: FlxEase.quartOut, startDelay: 0.4});
		FlxTween.tween(breadcrumbText,{alpha: 0.7}, 0.7, {ease: FlxEase.quartOut, startDelay: 0.5});
		
		FlxTween.tween(profilePanel, {alpha: 0.9}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.4});
		FlxTween.tween(profileIcon,  {alpha: 1},   0.6, {ease: FlxEase.quartOut, startDelay: 0.45});
		FlxTween.tween(profileName,  {alpha: 1},   0.6, {ease: FlxEase.quartOut, startDelay: 0.5});
		FlxTween.tween(profileStats, {alpha: 1},   0.6, {ease: FlxEase.quartOut, startDelay: 0.55});
		
		FlxTween.tween(descPanel,     {y: FlxG.height - 113}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.3});
		FlxTween.tween(descPanelGlow, {y: FlxG.height - 113}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.3});
		FlxTween.tween(descIcon,  {y: FlxG.height - 101}, 0.8, {ease: FlxEase.expoOut,  startDelay: 0.4});
		FlxTween.tween(descTitle, {y: FlxG.height - 103}, 0.8, {ease: FlxEase.expoOut,  startDelay: 0.45});
		FlxTween.tween(descText,  {y: FlxG.height - 75},  0.8, {ease: FlxEase.expoOut,  startDelay: 0.5});
		FlxTween.tween(descStats, {y: FlxG.height - 98},  0.8, {ease: FlxEase.expoOut,  startDelay: 0.55});
		
		FlxTween.tween(controlHintsPanel, {y: FlxG.height - 28}, 0.8, {ease: FlxEase.expoOut,  startDelay: 0.35});
		FlxTween.tween(controlHintsText,  {alpha: 1, y: FlxG.height - 22}, 0.6,
			{ease: FlxEase.quartOut, startDelay: 0.5});
		
		for (num in 0...categoryCards.length)
		{
			var row = Std.int(num / gridCols);
			var col = num % gridCols;
			var delay = 0.4 + (row * 0.1) + (col * 0.05);
			
			FlxTween.tween(categoryCards.members[num], {alpha: 0.95}, 0.6, {ease: FlxEase.backOut,  startDelay: delay});
			FlxTween.tween(cardBorders.members[num],   {alpha: 0.6},  0.6, {ease: FlxEase.quartOut, startDelay: delay + 0.05});
			FlxTween.tween(cardIcons.members[num],     {alpha: 1},    0.6, {ease: FlxEase.quartOut, startDelay: delay + 0.08});
			FlxTween.tween(cardTitleTexts.members[num],{alpha: 1},    0.6, {ease: FlxEase.quartOut, startDelay: delay + 0.1});
			FlxTween.tween(cardDescTexts.members[num], {alpha: 0.8},  0.6, {ease: FlxEase.quartOut, startDelay: delay + 0.12});
		}
		
		for (badge in cardBadges)
			FlxTween.tween(badge, {alpha: 1}, 0.5, {ease: FlxEase.elasticOut, startDelay: 1.0});
	}
	
	function playExitAnimation(callback:Void->Void)
	{
		FlxTween.tween(bgDarken,   {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		FlxTween.tween(bgPattern,  {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		FlxTween.tween(glowEffect, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		
		for (grad in gradientGroup.members)
		{
			if (grad != null && grad.alpha > 0)
				FlxTween.tween(grad, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		}
		
		FlxTween.tween(headerPanel, {y: -150}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(headerGlow,  {y: -150}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(titleText,   {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		
		FlxTween.tween(profilePanel, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		FlxTween.tween(profileIcon,  {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		FlxTween.tween(profileName,  {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		
		FlxTween.tween(descPanel,     {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(descPanelGlow, {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(controlHintsPanel, {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});
		
		for (i in 0...categoryCards.length)
		{
			var card     = categoryCards.members[i];
			var glow     = cardGlows.members[i];
			var titleTxt = cardTitleTexts.members[i];
			FlxTween.tween(card,     {alpha: 0, y: card.y - 40}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.02});
			if (glow != null) FlxTween.tween(glow, {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.02});
			FlxTween.tween(titleTxt, {alpha: 0}, 0.3, {ease: FlxEase.quartIn, startDelay: i * 0.02});
		}
		
		new FlxTimer().start(0.45, function(tmr:FlxTimer) { callback(); });
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		secretIndex = 0;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Settings Menu", null);
		#end

		controls.isInSubstate = false;

		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C');
		persistentUpdate = true;

		_buildLanguageData();
		playEntranceAnimation();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, targetScrollY, Math.max(0, Math.min(1, elapsed * 10)));
		
		if (FlxG.keys.justPressed.ANY)
		{
			var pressedKey:FlxKey = FlxG.keys.firstJustPressed();
			if (pressedKey != FlxKey.UP    && pressedKey != FlxKey.DOWN  &&
				pressedKey != FlxKey.LEFT  && pressedKey != FlxKey.RIGHT &&
				pressedKey != FlxKey.ENTER && pressedKey != FlxKey.ESCAPE &&
				pressedKey != FlxKey.W     && pressedKey != FlxKey.A     &&
				pressedKey != FlxKey.S     && pressedKey != FlxKey.D)
			{
				if (pressedKey == secretCode[secretIndex])
				{
					secretIndex++;
					if (secretIndex >= secretCode.length)
					{
						secretIndex = 0;
						secretUnlocked = true;
						FlxG.sound.play(Paths.sound('confirmMenu'));
						FlxG.camera.flash(0x66FF00FF, 0.5);
						FlxG.camera.shake(0.01, 0.3);
						new FlxTimer().start(0.3, function(tmr:FlxTimer) { openSecretMenu(); });
					}
				}
				else secretIndex = 0;
			}
		}
		
		animTimer  += elapsed;
		pulseTimer += elapsed;
		waveTimer  += elapsed * 2;
		floatTimer += elapsed * 1.5;
		glowTimer  += elapsed * 3;
		orbTimer   += elapsed * 0.5;
		
		if (bg != null)
		{
			bg.angle = Math.sin(animTimer * 0.3) * 3;
			bg.scale.set(1.5 + Math.sin(floatTimer * 0.3) * 0.02,
						 1.5 + Math.cos(floatTimer * 0.3) * 0.02);
		}
		
		if (glowEffect != null)
		{
			glowEffect.alpha = 0.1 + Math.sin(pulseTimer * 1.5) * 0.05;
			glowEffect.angle += elapsed * 8;
			glowEffect.scale.set(1 + Math.sin(floatTimer * 0.5) * 0.15,
								 1 + Math.cos(floatTimer * 0.5) * 0.15);
		}
		
		if (selectionGlow != null && curSelected < categoryCards.length)
		{
			var targetCard = categoryCards.members[curSelected];
			if (targetCard != null)
			{
				selectionGlow.x = FlxMath.lerp(selectionGlow.x, targetCard.x - 20, elapsed * 12);
				selectionGlow.y = FlxMath.lerp(selectionGlow.y, targetCard.y - 20, elapsed * 12);
				selectionGlow.alpha = 0.15 + Math.sin(glowTimer) * 0.08;
			}
		}
		
		for (orb in bgOrbs)
		{
			orb.x += Math.sin(orbTimer + orb.ID * 0.8) * 0.5;
			orb.y += Math.cos(orbTimer + orb.ID * 0.8) * 0.3;
			orb.alpha = 0.08 + Math.sin(orbTimer * 2 + orb.ID) * 0.04;
			orb.angle += elapsed * (5 + orb.ID * 2);
		}
		
		for (shape in floatingShapes)
		{
			shape.y += Math.sin(floatTimer * 0.8 + shape.ID * 0.5) * 0.3;
			shape.x += Math.cos(floatTimer * 0.6 + shape.ID * 0.5) * 0.2;
			shape.alpha = 0.1 + Math.sin(floatTimer * 2 + shape.ID) * 0.05;
			shape.angle += elapsed * (10 + shape.ID);
		}
		
		if (headerGlow != null)
			headerGlow.alpha = 0.5 + Math.sin(waveTimer) * 0.2;

		for (num in 0...categoryCards.length)
		{
			var row  = Std.int(num / gridCols);
			var col  = num % gridCols;
			var targetX = gridStartX + (col * (cardWidth  + cardSpacingX));
			var targetY = gridStartY + (row * (cardHeight + cardSpacingY));
			
			var card     = categoryCards.members[num];
			var glow     = cardGlows.members[num];
			var border   = cardBorders.members[num];
			var icon     = cardIcons.members[num];
			var titleTxt = cardTitleTexts.members[num];
			var desc     = cardDescTexts.members[num];
			
			if (card == null) continue;
			
			card.x = FlxMath.lerp(card.x, targetX, elapsed * 10);
			card.y = FlxMath.lerp(card.y, targetY, elapsed * 10);
			
			if (glow   != null) { glow.x   = card.x - 10; glow.y   = card.y - 10; }
			if (border != null) { border.x = card.x;       border.y = card.y + cardHeight - 4; }
			if (icon   != null) { icon.x   = card.x + 12;  icon.y   = card.y + 12; }
			if (titleTxt != null) { titleTxt.x = card.x + 95; titleTxt.y = card.y + 20; }
			if (desc   != null) { desc.x   = card.x + 95;  desc.y   = card.y + 52; }
			
			if (num == curSelected)
			{
				card.scale.set(FlxMath.lerp(card.scale.x, 1.04, elapsed * 8),
							   FlxMath.lerp(card.scale.y, 1.04, elapsed * 8));
				if (glow != null)
					glow.alpha = FlxMath.lerp(glow.alpha, 0.4 + Math.sin(glowTimer) * 0.15, elapsed * 8);
				if (border != null)
				{
					border.alpha = FlxMath.lerp(border.alpha, 1, elapsed * 10);
					border.color = FlxColor.fromRGB(255,
						Std.int(215 + Math.sin(animTimer * 3) * 40), 0);
				}
				if (icon     != null) icon.scale.set(1 + Math.sin(pulseTimer * 3) * 0.08,
													  1 + Math.sin(pulseTimer * 3) * 0.08);
				if (titleTxt != null) titleTxt.alpha = 1;
				if (desc     != null) desc.alpha = 1;
			}
			else
			{
				card.scale.set(FlxMath.lerp(card.scale.x, 1, elapsed * 8),
							   FlxMath.lerp(card.scale.y, 1, elapsed * 8));
				if (glow   != null) glow.alpha   = FlxMath.lerp(glow.alpha,   0, elapsed * 8);
				if (border != null) { border.alpha = FlxMath.lerp(border.alpha, 0.3, elapsed * 10); border.color = FlxColor.WHITE; }
				if (icon   != null) icon.scale.set(1, 1);
				if (titleTxt != null) titleTxt.alpha = 0.6;
				if (desc   != null) desc.alpha = 0.5;
			}
		}

		if (controls.UI_LEFT_P)  changeGridSelection(-1, 0);
		if (controls.UI_RIGHT_P) changeGridSelection( 1, 0);
		if (controls.UI_UP_P)    changeGridSelection( 0,-1);
		if (controls.UI_DOWN_P)  changeGridSelection( 0, 1);

		var cPressedState:Bool = false;
		if (mobileManager.mobilePad != null && getMobilePadButton("buttonC") != null && mobilePadJustPressed("C"))
			cPressedState = true;

		if (cPressedState || (FlxG.keys.justPressed.CONTROL && controls.mobileC))
		{
			persistentUpdate = false;
			removeTouchPad();
			openSubState(new mobile.substates.MobileExtraControl());
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			playExitAnimation(function() {
				if (onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else MusicBeatState.switchState(new MainMenuState());
			});
		}
		else if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			var selectedCard = categoryCards.members[curSelected];
			if (selectedCard != null)
			{
				FlxTween.cancelTweensOf(selectedCard.scale);
				selectedCard.scale.set(1.12, 1.12);
				FlxTween.tween(selectedCard.scale, {x: 1.04, y: 1.04}, 0.5, {ease: FlxEase.elasticOut});
				FlxG.camera.shake(0.003, 0.15);
				FlxG.camera.flash(0x33FFFFFF, 0.2);
			}
			openSelectedSubstate(options[curSelected]);
		}
	}

	function changeGridSelection(dx:Int, dy:Int)
	{
		curCol += dx;
		curRow += dy;
		
		var maxCols = Std.int(Math.min(gridCols, options.length));
		if (curCol < 0) curCol = maxCols - 1;
		if (curCol >= maxCols) curCol = 0;
		
		var maxRows = Std.int(Math.ceil(options.length / gridCols));
		if (curRow < 0) curRow = maxRows - 1;
		if (curRow >= maxRows) curRow = 0;
		
		var newSelected = curRow * gridCols + curCol;
		if (newSelected >= options.length)
		{
			if (dy != 0) { curRow = 0; newSelected = curCol; }
			else { curCol = options.length - 1 - (curRow * gridCols); newSelected = options.length - 1; }
		}
		
		if (newSelected != curSelected)
		{
			curSelected = newSelected;
			updateGridSelection();
			changeSelection();
		}
	}
	
	function updateGridSelection()
	{
		curRow = Std.int(curSelected / gridCols);
		curCol = curSelected % gridCols;
	}
	
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		var selectedOption = options[curSelected];
		
		descTitle.text = selectedOption;
		if (optionsDesc.exists(selectedOption))  descText.text  = optionsDesc.get(selectedOption);
		if (optionsStats.exists(selectedOption)) descStats.text = optionsStats.get(selectedOption);
		
		var iconPath = optionsIconPaths.exists(selectedOption) ? optionsIconPaths.get(selectedOption) : 'pet';
		if (Paths.image('ultra/settings/images/' + iconPath) != null)
		{
			descIcon.loadGraphic(Paths.image('ultra/settings/images/' + iconPath));
			descIcon.setGraphicSize(55, 55);
			descIcon.updateHitbox();
		}
		
		FlxTween.cancelTweensOf(descTitle);
		FlxTween.cancelTweensOf(descText);
		descTitle.alpha = 0; descText.alpha = 0;
		FlxTween.tween(descTitle, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});
		FlxTween.tween(descText,  {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.1});
		
		var targetCard = categoryCards.members[curSelected];
		if (targetCard != null) {
			var row = Std.int(curSelected / gridCols);
			if (row < 2) {
				targetScrollY = 0;
			} else {
				targetScrollY = (row - 1) * (cardHeight + cardSpacingY);
			}
		}
		
		for (grad in gradientGroup.members) {
			if (grad == null) continue;
			FlxTween.cancelTweensOf(grad);
			if (grad.ID == curSelected) {
				FlxTween.tween(grad, {alpha: 0.85}, 0.5);
				if (optionsColor.exists(selectedOption)) {
					selectionGlow.color = optionsColor.get(selectedOption)[0];
				}
			} else if (grad.alpha > 0) {
				FlxTween.tween(grad, {alpha: 0}, 0.5);
			}
		}
		
		FlxG.camera.shake(0.001, 0.06);
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
