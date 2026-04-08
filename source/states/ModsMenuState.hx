package states;

import backend.WeekData;
import backend.Mods;

import flixel.FlxBasic;
import flixel.graphics.FlxGraphic;
import flash.geom.Rectangle;
import haxe.Json;

import flixel.util.FlxSpriteUtil;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxMath;

import objects.AttachedSprite;
import objects.Alphabet;
import options.ModSettingsSubState;

import openfl.display.BitmapData;
import lime.utils.Assets;

import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class ModsMenuState extends MusicBeatState
{
	// ═══════════════════════════════════════════════════════
	// 🎮 ORİJİNAL SİSTEM DEĞİŞKENLERİ
	// ═══════════════════════════════════════════════════════
	var bg:FlxSprite;
	var icon:FlxSprite;
	var modName:Alphabet;
	var modDesc:FlxText;
	var modRestartText:FlxText;
	var modsList:ModsList = null;

	var buttonReload:MenuButton;
	var buttonEnableAll:MenuButton;
	var buttonDisableAll:MenuButton;
	var buttons:Array<MenuButton> = [];
	var settingsButton:MenuButton;
	var bgButtons:FlxSprite;

	var modsGroup:FlxTypedGroup<ModItem>;
	var curSelectedMod:Int = 0;

	var hoveringOnMods:Bool = true;
	var curSelectedButton:Int = 0;

	var noModsSine:Float = 0;
	var noModsTxt:FlxText;

	var _lastControllerMode:Bool = false;
	var startMod:String = null;
	var iconTargetY:Float = 0;
	var waitingToRestart:Bool = false;
	var centerMod:Int = 3;

	var nextAttempt:Float = 1;
	var holdingMod:Bool = false;
	var mouseOffsets:FlxPoint = new FlxPoint();
	var holdingElapsed:Float = 0;
	var gottaClickAgain:Bool = false;
	var holdTime:Float = 0;
	var exiting:Bool = false;

	// ═══════════════════════════════════════════════════════
	// 🌌 MODERN UI — ARKA PLAN
	// ═══════════════════════════════════════════════════════
	var bgBase:FlxSprite;
	var bgGradient:FlxSprite;
	var bgGradientDynamic:FlxSprite;
	var gridBG:FlxBackdrop;
	var bgOrbs:Array<FlxSprite> = [];
	var floatingShapes:Array<FlxSprite> = [];
	var bgVignette:FlxSprite;

	// ═══════════════════════════════════════════════════════
	// 🔝 HEADER
	// ═══════════════════════════════════════════════════════
	var headerPanel:FlxSprite;
	var headerGlow:FlxSprite;
	var headerTitle:FlxText;
	var headerSubtitle:FlxText;
	var headerBreadcrumb:FlxText;

	// ═══════════════════════════════════════════════════════
	// 🎭 SOL VİTRİN PANELİ
	// ═══════════════════════════════════════════════════════
	var showcasePanel:FlxSprite;
	var showcasePanelGlow:FlxSprite;
	var showcasePanelBorder:FlxSprite;
	var iconGlowSprite:FlxSprite;
	var modNamePanel:FlxSprite;
	var descPanel:FlxSprite;
	var descPanelGlow:FlxSprite;
	var enabledBadge:FlxSprite;
	var enabledBadgeText:FlxText;
	var disabledBadge:FlxSprite;
	var disabledBadgeText:FlxText;
	var restartBadge:FlxSprite;
	var restartBadgeText:FlxText;
	var modCountText:FlxText;

	// ═══════════════════════════════════════════════════════
	// 📋 SAĞ PANEL — MOD LİSTESİ
	// ═══════════════════════════════════════════════════════
	var rightPanel:FlxSprite;
	var rightPanelGlow:FlxSprite;
	var rightPanelBorder:FlxSprite;
	var listLabel:FlxText;
	var listLabelLine:FlxSprite;
	var selectionBar:FlxSprite;
	var selectionBarGlow:FlxSprite;

	// ═══════════════════════════════════════════════════════
	// 🎮 KONTROL İPUÇLARI
	// ═══════════════════════════════════════════════════════
	var controlHintsPanel:FlxSprite;
	var controlHintsText:FlxText;

	// ═══════════════════════════════════════════════════════
	// 🎨 ANİMASYON TİMERLARI
	// ═══════════════════════════════════════════════════════
	var animTimer:Float  = 0;
	var pulseTimer:Float = 0;
	var waveTimer:Float  = 0;
	var floatTimer:Float = 0;
	var glowTimer:Float  = 0;

	var currentAccentColor:FlxColor = 0xFF665AFF;

	// Layout sabitleri
	static inline var HEADER_H:Int    = 100;
	static inline var RIGHT_W:Int     = 420;
	static inline var ITEM_H:Int      = 82;
	static inline var ITEM_GAP:Int    = 6;
	static inline var DOCK_H:Int      = 90;
	static inline var LIST_TOP:Int    = HEADER_H + 48;

	// Mobil için dock yüksekliği — touchpad altta yer kaplayacağından biraz daha yüksek
	var effectiveDockH(get, never):Int;
	function get_effectiveDockH():Int return controls.mobileC ? DOCK_H + 80 : DOCK_H;

	// Manuel liste scroll
	var listScrollOffset:Float  = 0;
	var listScrollTarget:Float  = 0;

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}

	// ═══════════════════════════════════════════════════════
	// 🏗️ CREATE
	// ═══════════════════════════════════════════════════════
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;
		modsList = Mods.parseList();
		Mods.loadTopMod();

		// Mobil çıkış butonu etiketi
		var daButton:String = controls.mobileC ? 'B' : 'BACKSPACE';

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Mod Merkezi", null);
		#end

		// ── Arka Plan ────────────────────────────────────────
		createBackground();

		// ── Header ───────────────────────────────────────────
		createHeader();

		// ── Vitrin (Sol) ─────────────────────────────────────
		createShowcasePanel();

		// ── Mod Listesi (Sağ) ─────────────────────────────────
		createRightPanel();

		// ── Üst Aksiyon Butonları ─────────────────────────────
		createTopButtons();

		// ── Dock Butonları ────────────────────────────────────
		createDockButtons();

		// ── Kontrol İpuçları ─────────────────────────────────
		createControlHints(daButton);

		// ── Mod Grubu Yükle ───────────────────────────────────
		modsGroup = new FlxTypedGroup<ModItem>();
		for (i => mod in modsList.all)
		{
			if (startMod == mod) curSelectedMod = i;
			var modItem:ModItem = new ModItem(mod);
			if (modsList.disabled.contains(mod))
			{
				modItem.icon.color  = 0xFFFF6666;
				modItem.text.color  = 0xFF888888;
			}
			modsGroup.add(modItem);
		}
		centerMod = curSelectedMod;
		add(modsGroup);

		// ── Mod yok durumu ────────────────────────────────────
		if (modsList.all.length < 1)
		{
			buttonDisableAll.visible = buttonDisableAll.enabled = false;
			buttonEnableAll.visible  = true;
			noModsTxt = new FlxText(0, 0, FlxG.width - RIGHT_W,
				Language.getPhrase('no_mods_installed', 'MOD YÜKLENMEDİ\nÇIKMAK İÇİN {1} TUŞUNA BASIN', [daButton]), 32);
			noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noModsTxt.screenCenter();
			noModsTxt.x = (FlxG.width - RIGHT_W) / 2 - noModsTxt.width / 2;
			add(noModsTxt);
			FlxG.autoPause = false;
			changeSelectedMod();
			playEntranceAnimation();
			_lastControllerMode = controls.controllerMode;
			// Mobil: sadece geri butonu yeterli (mod yok ekranında)
			addTouchPad('NONE', 'B');
			return super.create();
		}

		// ── Icon showcase ─────────────────────────────────────
		icon = new FlxSprite(0, 0);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		modName = new Alphabet(0, 0, "", true);
		add(modName);

		modDesc = new FlxText(30, 0, FlxG.width - RIGHT_W - 60, "", 18);
		modDesc.setFormat(Paths.font("vcr.ttf"), 18, 0xFFCCCCCC, LEFT);
		add(modDesc);

		modRestartText = new FlxText(30, 0, FlxG.width - RIGHT_W - 60, "⚠ YENİDEN BAŞLATMA GEREKLİ", 14);
		modRestartText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFF9944, LEFT);
		add(modRestartText);

		_lastControllerMode = controls.controllerMode;
		checkToggleButtons();
		changeSelectedMod();
		playEntranceAnimation();

		// ── Mobil TouchPad ────────────────────────────────────
		// UP_DOWN: mod listesinde gezinme; B: geri
		// TouchPad'i listenin üstüne değil, ekranın altına sabitliyoruz.
		// Sağ panelin dışına sığsın diye x offseti ayarlıyoruz.
		addTouchPad('UP_DOWN', 'B');
		if (controls.mobileC)
		{
			mobileManager.mobilePad.alpha = 0.35;
			// Touchpad'i sol panel (vitrin) alanında ortala, alta yapıştır
			var padW:Float = FlxG.width - RIGHT_W;
			mobileManager.mobilePad.x = (padW - mobileManager.mobilePad.width) / 2;
			mobileManager.mobilePad.y = FlxG.height - mobileManager.mobilePad.height - 4;
		}

		super.create();
	}

	// ═══════════════════════════════════════════════════════
	// 🌌 ARKA PLAN
	// ═══════════════════════════════════════════════════════
	function createBackground()
	{
		bgBase = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF080812);
		bgBase.scrollFactor.set(0, 0);
		add(bgBase);

		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0xFF1a1a2e, 0xFF12122a, 0xFF0a0a1a, 0xFF080812],
			1, 135
		);
		bgGradient.scrollFactor.set(0, 0);
		bgGradient.alpha = 0.95;
		add(bgGradient);

		bgGradientDynamic = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[currentAccentColor, 0x00000000],
			1, 135
		);
		bgGradientDynamic.scrollFactor.set(0, 0);
		bgGradientDynamic.alpha = 0.14;
		bgGradientDynamic.blend = ADD;
		add(bgGradientDynamic);

		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(40, 40, 80, 80, true, 0x0AFFFFFF, 0x0));
		gridBG.velocity.set(7, 5);
		gridBG.alpha = 0.1;
		gridBG.scrollFactor.set(0, 0);
		add(gridBG);

		for (i in 0...7)
		{
			var orb = new FlxSprite(
				FlxG.random.float(0, FlxG.width - RIGHT_W),
				FlxG.random.float(HEADER_H, FlxG.height - 60)
			);
			orb.makeGraphic(
				Std.int(70 + FlxG.random.float(0, 90)),
				Std.int(70 + FlxG.random.float(0, 90)),
				currentAccentColor
			);
			orb.blend = ADD;
			orb.alpha = 0.04 + FlxG.random.float(0, 0.04);
			orb.scrollFactor.set(0, 0);
			orb.ID = i;
			add(orb);
			bgOrbs.push(orb);
		}

		for (i in 0...10)
		{
			var shape = new FlxSprite(
				FlxG.random.float(0, FlxG.width - RIGHT_W),
				FlxG.random.float(HEADER_H, FlxG.height)
			);
			shape.makeGraphic(
				Std.int(12 + FlxG.random.float(0, 20)),
				Std.int(12 + FlxG.random.float(0, 20)),
				FlxColor.WHITE
			);
			shape.blend = ADD;
			shape.alpha = 0.04 + FlxG.random.float(0, 0.05);
			shape.scrollFactor.set(0, 0);
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

	// ═══════════════════════════════════════════════════════
	// 🔝 HEADER
	// ═══════════════════════════════════════════════════════
	function createHeader()
	{
		headerPanel = new FlxSprite(0, -HEADER_H).makeGraphic(FlxG.width, HEADER_H, 0xEE000000);
		headerPanel.scrollFactor.set(0, 0);
		add(headerPanel);

		headerGlow = new FlxSprite(0, HEADER_H - 4).makeGraphic(FlxG.width, 4, currentAccentColor);
		headerGlow.blend = ADD;
		headerGlow.alpha = 0.7;
		headerGlow.scrollFactor.set(0, 0);
		add(headerGlow);

		var titleIcon = new FlxText(30, 16, 50, "📦", 38);
		titleIcon.scrollFactor.set(0, 0);
		add(titleIcon);

		headerTitle = new FlxText(82, 16, FlxG.width - RIGHT_W - 100, "MOD MERKEZİ", 40);
		headerTitle.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF1A0040);
		headerTitle.borderSize = 3;
		headerTitle.scrollFactor.set(0, 0);
		headerTitle.alpha = 0;
		add(headerTitle);

		headerSubtitle = new FlxText(82, 60, FlxG.width - RIGHT_W - 100, "Modlarını yönet, etkinleştir ve sırala!", 17);
		headerSubtitle.setFormat(Paths.font("vcr.ttf"), 17, 0xFFBBBBBB, LEFT);
		headerSubtitle.scrollFactor.set(0, 0);
		headerSubtitle.alpha = 0;
		add(headerSubtitle);

		headerBreadcrumb = new FlxText(82, 82, FlxG.width - RIGHT_W - 100, "Ana Menü > Mod Merkezi", 12);
		headerBreadcrumb.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		headerBreadcrumb.scrollFactor.set(0, 0);
		headerBreadcrumb.alpha = 0;
		add(headerBreadcrumb);

		modCountText = new FlxText(FlxG.width - RIGHT_W - 200, 28, 180, "", 22);
		modCountText.setFormat(Paths.font("vcr.ttf"), 22, currentAccentColor, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modCountText.borderSize = 1.5;
		modCountText.scrollFactor.set(0, 0);
		add(modCountText);
	}

	// ═══════════════════════════════════════════════════════
	// 🎭 VİTRİN PANELİ (Sol)
	// ═══════════════════════════════════════════════════════
	function createShowcasePanel()
	{
		var panelW:Float = FlxG.width - RIGHT_W;

		showcasePanelGlow = new FlxSprite(0, HEADER_H).makeGraphic(Std.int(panelW), FlxG.height - HEADER_H, currentAccentColor);
		showcasePanelGlow.alpha = 0.05;
		showcasePanelGlow.blend = ADD;
		showcasePanelGlow.scrollFactor.set(0, 0);
		add(showcasePanelGlow);

		iconGlowSprite = new FlxSprite(panelW / 2 - 120, HEADER_H + 80);
		iconGlowSprite.makeGraphic(240, 240, currentAccentColor);
		iconGlowSprite.blend = ADD;
		iconGlowSprite.alpha = 0.08;
		iconGlowSprite.scrollFactor.set(0, 0);
		add(iconGlowSprite);

		var namePanelY:Float = FlxG.height - 210;
		modNamePanel = new FlxSprite(0, namePanelY).makeGraphic(Std.int(panelW), 75, 0xAA000000);
		modNamePanel.scrollFactor.set(0, 0);
		add(modNamePanel);

		var namePanelBorder = new FlxSprite(0, namePanelY).makeGraphic(Std.int(panelW), 3, currentAccentColor);
		namePanelBorder.alpha = 0.5;
		namePanelBorder.scrollFactor.set(0, 0);
		add(namePanelBorder);

		descPanelGlow = new FlxSprite(0, FlxG.height - 135).makeGraphic(Std.int(panelW), 107, currentAccentColor);
		descPanelGlow.alpha = 0.06;
		descPanelGlow.scrollFactor.set(0, 0);
		add(descPanelGlow);

		descPanel = new FlxSprite(0, FlxG.height - 135).makeGraphic(Std.int(panelW), 107, 0xBB000000);
		descPanel.scrollFactor.set(0, 0);
		add(descPanel);

		var descBorder = new FlxSprite(0, FlxG.height - 135).makeGraphic(Std.int(panelW), 3, currentAccentColor);
		descBorder.alpha = 0.4;
		descBorder.scrollFactor.set(0, 0);
		add(descBorder);

		// Rozetler
		enabledBadge = new FlxSprite(14, HEADER_H + 14).makeGraphic(110, 26, 0xFF10B981);
		enabledBadge.alpha = 0.9;
		enabledBadge.scrollFactor.set(0, 0);
		add(enabledBadge);
		enabledBadgeText = new FlxText(15, HEADER_H + 17, 108, "✓ ETKİN", 14);
		enabledBadgeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		enabledBadgeText.scrollFactor.set(0, 0);
		add(enabledBadgeText);

		disabledBadge = new FlxSprite(14, HEADER_H + 14).makeGraphic(130, 26, 0xFFFF5555);
		disabledBadge.alpha = 0;
		disabledBadge.scrollFactor.set(0, 0);
		add(disabledBadge);
		disabledBadgeText = new FlxText(15, HEADER_H + 17, 128, "✗ DEVRE DIŞI", 14);
		disabledBadgeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		disabledBadgeText.alpha = 0;
		disabledBadgeText.scrollFactor.set(0, 0);
		add(disabledBadgeText);

		restartBadge = new FlxSprite(134, HEADER_H + 14).makeGraphic(170, 26, 0xFFFF9944);
		restartBadge.alpha = 0;
		restartBadge.scrollFactor.set(0, 0);
		add(restartBadge);
		restartBadgeText = new FlxText(135, HEADER_H + 17, 168, "⚠ RESTART GEREKLİ", 14);
		restartBadgeText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		restartBadgeText.alpha = 0;
		restartBadgeText.scrollFactor.set(0, 0);
		add(restartBadgeText);

		showcasePanelBorder = new FlxSprite(Std.int(panelW) - 3, HEADER_H).makeGraphic(3, FlxG.height - HEADER_H, currentAccentColor);
		showcasePanelBorder.alpha = 0.5;
		showcasePanelBorder.scrollFactor.set(0, 0);
		add(showcasePanelBorder);
	}

	// ═══════════════════════════════════════════════════════
	// 📋 SAĞ PANEL — MOD LİSTESİ
	// ═══════════════════════════════════════════════════════
	function createRightPanel()
	{
		var rx:Float = FlxG.width - RIGHT_W;

		rightPanelGlow = new FlxSprite(rx - 2, HEADER_H - 2).makeGraphic(RIGHT_W + 2, FlxG.height - HEADER_H + 2, currentAccentColor);
		rightPanelGlow.alpha = 0.06;
		rightPanelGlow.scrollFactor.set(0, 0);
		add(rightPanelGlow);

		rightPanel = FlxGradient.createGradientFlxSprite(
			RIGHT_W, FlxG.height - HEADER_H,
			[0xDD0a0a12, 0xEE050508, 0xFF020204],
			1, 0
		);
		rightPanel.x = rx;
		rightPanel.y = HEADER_H;
		rightPanel.scrollFactor.set(0, 0);
		add(rightPanel);

		rightPanelBorder = new FlxSprite(rx, HEADER_H).makeGraphic(3, FlxG.height - HEADER_H, currentAccentColor);
		rightPanelBorder.alpha = 0.5;
		rightPanelBorder.scrollFactor.set(0, 0);
		add(rightPanelBorder);

		listLabel = new FlxText(rx + 12, HEADER_H + 10, RIGHT_W - 24, "MODLAR", 14);
		listLabel.setFormat(Paths.font("vcr.ttf"), 14, currentAccentColor, LEFT);
		listLabel.scrollFactor.set(0, 0);
		add(listLabel);

		listLabelLine = new FlxSprite(rx + 12, HEADER_H + 28).makeGraphic(RIGHT_W - 24, 2, currentAccentColor);
		listLabelLine.alpha = 0.3;
		listLabelLine.scrollFactor.set(0, 0);
		add(listLabelLine);

		selectionBarGlow = new FlxSprite(rx, LIST_TOP).makeGraphic(RIGHT_W, ITEM_H + ITEM_GAP, currentAccentColor);
		selectionBarGlow.alpha = 0.08;
		selectionBarGlow.scrollFactor.set(0, 0);
		add(selectionBarGlow);

		selectionBar = new FlxSprite(rx, LIST_TOP).makeGraphic(4, ITEM_H - 4, currentAccentColor);
		selectionBar.scrollFactor.set(0, 0);
		add(selectionBar);
	}

	// ═══════════════════════════════════════════════════════
	// 🔘 ÜST AKSİYON BUTONLARI
	// ═══════════════════════════════════════════════════════
	function createTopButtons()
	{
		var rx:Float = FlxG.width - RIGHT_W;
		var btnW:Int = 130;
		var btnH:Int = 34;
		var btnY:Float = HEADER_H + 36;

		buttonReload = new MenuButton(rx + 10, btnY, btnW, btnH, "🔄 YENİLE", reload);
		buttonReload.scrollFactor.set(0, 0);
		add(buttonReload);

		buttonEnableAll = new MenuButton(rx + RIGHT_W - btnW - 10, btnY, btnW, btnH, "✓ HEPSINI AÇ", function() {
			for (mod in modsGroup.members)
			{
				if (modsList.disabled.contains(mod.folder))
				{
					modsList.disabled.remove(mod.folder);
					modsList.enabled.push(mod.folder);
					mod.icon.color = FlxColor.WHITE;
					mod.text.color = FlxColor.WHITE;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonEnableAll.scrollFactor.set(0, 0);
		add(buttonEnableAll);

		buttonDisableAll = new MenuButton(rx + RIGHT_W - btnW - 10, btnY, btnW, btnH, "✗ HEPSINI KAPA", function() {
			for (mod in modsGroup.members)
			{
				if (modsList.enabled.contains(mod.folder))
				{
					modsList.enabled.remove(mod.folder);
					modsList.disabled.push(mod.folder);
					mod.icon.color = 0xFFFF6666;
					mod.text.color = 0xFF888888;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonDisableAll.scrollFactor.set(0, 0);
		add(buttonDisableAll);

		checkToggleButtons();
	}

	// ═══════════════════════════════════════════════════════
	// 🎛️ DOCK BUTONLARI (Alt)
	// ═══════════════════════════════════════════════════════
	function createDockButtons()
	{
		var rx:Float = FlxG.width - RIGHT_W;
		var dockY:Float = FlxG.height - DOCK_H;

		bgButtons = FlxGradient.createGradientFlxSprite(
			RIGHT_W, DOCK_H,
			[0xAA000000, 0xCC000000],
			1, 90
		);
		bgButtons.x = rx;
		bgButtons.y = dockY;
		bgButtons.scrollFactor.set(0, 0);
		add(bgButtons);

		var dockBorder = new FlxSprite(rx, dockY).makeGraphic(RIGHT_W, 3, currentAccentColor);
		dockBorder.alpha = 0.4;
		dockBorder.scrollFactor.set(0, 0);
		add(dockBorder);

		var btnSize:Int  = 60;
		var gap:Int      = 10;
		var totalW:Int   = 5 * btnSize + 4 * gap;
		var startX:Float = rx + (RIGHT_W - totalW) / 2;
		var btnY:Float   = dockY + (DOCK_H - btnSize) / 2;

		// En Üste Taşı
		var b = new MenuButton(startX, btnY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() moveModToPosition(0), 54, 54);
		b.icon.animation.add('icon', [0]); b.icon.animation.play('icon', true);
		b.scrollFactor.set(0, 0); add(b); buttons.push(b);

		// Yukarı Taşı
		b = new MenuButton(startX + (btnSize + gap), btnY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod - 1), 54, 54);
		b.icon.animation.add('icon', [1]); b.icon.animation.play('icon', true);
		b.scrollFactor.set(0, 0); add(b); buttons.push(b);

		// Aşağı Taşı
		b = new MenuButton(startX + (btnSize + gap) * 2, btnY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod + 1), 54, 54);
		b.icon.animation.add('icon', [2]); b.icon.animation.play('icon', true);
		b.scrollFactor.set(0, 0); add(b); buttons.push(b);

		// Ayarlar
		settingsButton = new MenuButton(startX + (btnSize + gap) * 3, btnY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() {
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if (curMod != null && curMod.settings != null && curMod.settings.length > 0)
				openSubState(new ModSettingsSubState(curMod.settings, curMod.folder, curMod.name));
		}, 54, 54);
		settingsButton.icon.animation.add('icon', [3]); settingsButton.icon.animation.play('icon', true);
		settingsButton.scrollFactor.set(0, 0); add(settingsButton); buttons.push(settingsButton);

		// Aç / Kapat
		var toggleBtn = new MenuButton(startX + (btnSize + gap) * 4, btnY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() {
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			var mod:String = curMod.folder;
			if (!modsList.disabled.contains(mod)) { modsList.enabled.remove(mod); modsList.disabled.push(mod); }
			else                                  { modsList.disabled.remove(mod); modsList.enabled.push(mod); }
			curMod.icon.color = modsList.disabled.contains(mod) ? 0xFFFF6666 : FlxColor.WHITE;
			curMod.text.color = modsList.disabled.contains(mod) ? 0xFF888888 : FlxColor.WHITE;
			if (curMod.mustRestart) waitingToRestart = true;
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}, 54, 54);
		toggleBtn.icon.animation.add('icon', [4]); toggleBtn.icon.animation.play('icon', true);
		toggleBtn.scrollFactor.set(0, 0);
		toggleBtn.focusChangeCallback = function(focus:Bool) {
			if (!focus && modsGroup != null && modsGroup.members[curSelectedMod] != null)
				toggleBtn.bg.color = modsList.enabled.contains(modsGroup.members[curSelectedMod].folder) ? 0xFF10B981 : 0xFFFF5555;
		};
		add(toggleBtn); buttons.push(toggleBtn);

		if (modsList.all.length < 2) { buttons[0].enabled = false; buttons[1].enabled = false; buttons[2].enabled = false; }
		if (modsList.all.length < 1) { for (btn in buttons) btn.enabled = false; toggleBtn.focusChangeCallback = null; }
	}

	// ═══════════════════════════════════════════════════════
	// 🎮 KONTROL İPUÇLARI
	// ═══════════════════════════════════════════════════════
	function createControlHints(daButton:String)
	{
		controlHintsPanel = new FlxSprite(0, FlxG.height - 28).makeGraphic(FlxG.width - RIGHT_W, 28, 0xAA000000);
		controlHintsPanel.scrollFactor.set(0, 0);
		add(controlHintsPanel);

		var hintTxt:String = controls.mobileC
			? '↑↓: Seç  |  Butonlara Dokun  |  {1}: Geri'.replace('{1}', daButton)
			: '↑↓: Seç  |  ►: Butonlar  |  ESC: Geri  |  HOME/END: İlk/Son';

		controlHintsText = new FlxText(0, FlxG.height - 22, FlxG.width - RIGHT_W, hintTxt, 11);
		controlHintsText.setFormat(Paths.font("vcr.ttf"), 11, 0xFF888888, CENTER);
		controlHintsText.scrollFactor.set(0, 0);
		add(controlHintsText);
	}

	// ═══════════════════════════════════════════════════════
	// 🎬 GİRİŞ ANİMASYONU
	// ═══════════════════════════════════════════════════════
	function playEntranceAnimation()
	{
		FlxTween.tween(headerPanel, {y: 0}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.05});
		FlxTween.tween(headerGlow, {y: HEADER_H - 4}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.05});
		FlxTween.tween(headerTitle, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3});
		FlxTween.tween(headerSubtitle, {alpha: 0.85}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.4});
		FlxTween.tween(headerBreadcrumb, {alpha: 0.7}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.5});

		rightPanel.x  = FlxG.width;
		rightPanelGlow.x = FlxG.width;
		rightPanelBorder.x = FlxG.width;
		var rx:Float = FlxG.width - RIGHT_W;
		FlxTween.tween(rightPanel, {x: rx}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.15});
		FlxTween.tween(rightPanelGlow, {x: rx - 2}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.15});
		FlxTween.tween(rightPanelBorder, {x: rx}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.2});

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
	}

	// ═══════════════════════════════════════════════════════
	// 🔄 UPDATE
	// ═══════════════════════════════════════════════════════
	override function update(elapsed:Float)
	{
		// ── ESC / Geri ────────────────────────────────────────
		if (controls.BACK && hoveringOnMods && !exiting)
		{
			exiting = true;
			saveTxt();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (waitingToRestart)
			{
				TitleState.initialized = false;
				TitleState.closedState = false;
				FlxG.sound.music.fadeOut(0.3);
				if (FreeplayState.vocals != null) { FreeplayState.vocals.fadeOut(0.3); FreeplayState.vocals = null; }
				FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
			}
			else
			{
				FlxTween.tween(headerPanel, {y: -HEADER_H}, 0.4, {ease: FlxEase.backIn});
				FlxTween.tween(rightPanel,  {x: FlxG.width + 50}, 0.4, {ease: FlxEase.backIn, startDelay: 0.04});
				new flixel.util.FlxTimer().start(0.45, function(_) {
					MusicBeatState.switchState(new MainMenuState());
				});
			}
			persistentUpdate = false;
			FlxG.autoPause = ClientPrefs.data.autoPause;
			FlxG.mouse.visible = false;
			return;
		}

		// ── Mouse takibi (sadece mobil olmayan cihazda) ───────
		if (!controls.mobileC)
		{
			if (Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10)
			{
				controls.controllerMode = false;
				if (!FlxG.mouse.visible) FlxG.mouse.visible = true;
			}
			if (controls.controllerMode != _lastControllerMode)
			{
				if (controls.controllerMode) FlxG.mouse.visible = false;
				_lastControllerMode = controls.controllerMode;
			}
		}

		// ── Animasyon timerları ───────────────────────────────
		animTimer  += elapsed;
		pulseTimer += elapsed;
		waveTimer  += elapsed * 2;
		floatTimer += elapsed * 1.5;
		glowTimer  += elapsed * 3;

		// ── Orb animasyonları ─────────────────────────────────
		for (i in 0...bgOrbs.length)
		{
			var orb = bgOrbs[i];
			orb.x += Math.sin(animTimer * 0.5 + i * 0.8) * 0.4;
			orb.y += Math.cos(animTimer * 0.4 + i * 0.8) * 0.3;
			orb.alpha = 0.04 + Math.sin(animTimer * 2 + i) * 0.02;
			orb.angle += elapsed * (3 + i * 2);
		}

		// ── Floating shapes ───────────────────────────────────
		for (i in 0...floatingShapes.length)
		{
			var shape = floatingShapes[i];
			shape.y += Math.sin(floatTimer * 0.8 + i * 0.5) * 0.25;
			shape.x += Math.cos(floatTimer * 0.6 + i * 0.5) * 0.18;
			shape.alpha = 0.04 + Math.sin(floatTimer * 2 + i) * 0.025;
			shape.angle += elapsed * (6 + i);
		}

		// ── Glow pulse ────────────────────────────────────────
		if (headerGlow != null)       headerGlow.alpha       = 0.5 + Math.sin(waveTimer) * 0.2;
		if (selectionBarGlow != null) selectionBarGlow.alpha = 0.06 + Math.sin(glowTimer) * 0.03;
		if (iconGlowSprite != null)   iconGlowSprite.alpha   = 0.06 + Math.sin(pulseTimer * 1.5) * 0.03;

		// ── Mod listesi scroll ────────────────────────────────
		updateListScroll(elapsed);

		// ── Input sistemi ─────────────────────────────────────
		if (controls.UI_DOWN_R || controls.UI_UP_R) holdTime = 0;

		if (modsList.all.length > 0)
		{
			if (controls.controllerMode && holdingMod) { holdingMod = false; holdingElapsed = 0; updateItemPositions(); }

			var lastMode = hoveringOnMods;
			if (modsList.all.length > 1)
			{
				// ── Mobil: dokunmatik scroll ──────────────────
				if (controls.mobileC && hoveringOnMods)
				{
					var shiftMult:Int = 1;
					if (controls.UI_DOWN_P)     changeSelectedMod(shiftMult);
					else if (controls.UI_UP_P)  changeSelectedMod(-shiftMult);
					else if (controls.UI_UP || controls.UI_DOWN)
					{
						var lastHoldTime:Float = holdTime;
						holdTime += elapsed;
						if (holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8))
							changeSelectedMod(shiftMult * (controls.UI_UP ? -1 : 1));
					}
				}

				// ── PC/Konsol: mouse + klavye ─────────────────
				if (!controls.mobileC && FlxG.mouse.justPressed)
				{
					for (i in centerMod-4...centerMod+5)
					{
						if (i < 0 || i >= modsGroup.members.length) continue;
						var mod = modsGroup.members[i];
						if (mod != null && mod.visible && FlxG.mouse.overlaps(mod))
						{
							hoveringOnMods = true;
							var button = getButton(); button.ignoreCheck = button.onFocus = false;
							mouseOffsets.x = FlxG.mouse.x - mod.x;
							mouseOffsets.y = FlxG.mouse.y - mod.y;
							var direction = (i > curSelectedMod) ? 1 : -1;
							curSelectedMod = i;
							changeSelectedMod(direction);
							break;
						}
					}
					hoveringOnMods  = true;
					var button = getButton(); button.ignoreCheck = button.onFocus = false;
					gottaClickAgain = false;
				}

				if (!controls.mobileC && hoveringOnMods)
				{
					var shiftMult:Int = (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER) || FlxG.gamepads.anyPressed(RIGHT_SHOULDER)) ? 4 : 1;
					if (controls.UI_DOWN_P) changeSelectedMod(shiftMult);
					else if (controls.UI_UP_P) changeSelectedMod(-shiftMult);
					else if (FlxG.mouse.wheel != 0) changeSelectedMod(-FlxG.mouse.wheel * shiftMult, true);
					else if (FlxG.keys.justPressed.HOME || FlxG.keys.justPressed.END)
					{
						if (FlxG.keys.justPressed.END) curSelectedMod = modsList.all.length - 1;
						else curSelectedMod = 0;
						changeSelectedMod();
					}
					else if (controls.UI_UP || controls.UI_DOWN)
					{
						var lastHoldTime:Float = holdTime;
						holdTime += elapsed;
						if (holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8))
							changeSelectedMod(shiftMult * (controls.UI_UP ? -1 : 1));
					}
					else if (FlxG.mouse.pressed && !gottaClickAgain)
					{
						var curMod:ModItem = modsGroup.members[curSelectedMod];
						if (curMod != null)
						{
							if (!holdingMod && FlxG.mouse.justMoved && FlxG.mouse.overlaps(curMod)) holdingMod = true;
							if (holdingMod)
							{
								var moved:Bool = false;
								for (i in centerMod-4...centerMod+5)
								{
									if (i < 0 || i >= modsGroup.members.length) continue;
									var mod = modsGroup.members[i];
									if (mod != null && mod.visible && FlxG.mouse.overlaps(mod) && curSelectedMod != i)
									{
										moveModToPosition(i); moved = true; break;
									}
								}
								if (!moved)
								{
									var topLimit:Float = 100; var botLimit:Float = FlxG.height - 100;
									var factor:Float = -1;
									if (FlxG.mouse.y < topLimit) factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (topLimit - FlxG.mouse.y) / 100)));
									else if (FlxG.mouse.y > botLimit) factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (FlxG.mouse.y - botLimit) / 100)));
									if (factor >= 0)
									{
										holdingElapsed += elapsed;
										if (holdingElapsed >= factor)
										{
											holdingElapsed = 0;
											var newPos = curSelectedMod;
											if (FlxG.mouse.y < topLimit) newPos--;
											else newPos++;
											moveModToPosition(Std.int(Math.max(0, Math.min(modsGroup.length - 1, newPos))));
										}
									}
								}
								curMod.x = FlxG.mouse.x - mouseOffsets.x;
								curMod.y = FlxG.mouse.y - mouseOffsets.y;
							}
						}
					}
					else if (FlxG.mouse.justReleased && holdingMod) { holdingMod = false; holdingElapsed = 0; updateItemPositions(); }
				}
			}

			if (lastMode == hoveringOnMods)
			{
				if (hoveringOnMods)
				{
					// Sağa geç: sadece PC/Konsol modunda (mobilde butonlara dokunarak erişilir)
					if (!controls.mobileC && controls.UI_RIGHT_P)
					{
						hoveringOnMods = false;
						var button = getButton(); button.ignoreCheck = button.onFocus = false;
						curSelectedButton = 0;
						changeSelectedButton();
					}
				}
				else
				{
					if (controls.BACK) { hoveringOnMods = true; var button = getButton(); button.ignoreCheck = button.onFocus = false; changeSelectedMod(); }
					else if (controls.ACCEPT) { var button = getButton(); if (button.onClick != null) button.onClick(); }
					else if (curSelectedButton < 0)
					{
						if (controls.UI_UP_P)
						{
							switch(curSelectedButton)
							{
								case -2: curSelectedMod = 0; hoveringOnMods = true; var button = getButton(); button.ignoreCheck = button.onFocus = false; changeSelectedMod();
								case -1: changeSelectedButton(-1);
							}
						}
						else if (controls.UI_DOWN_P)
						{
							switch(curSelectedButton)
							{
								case -2: changeSelectedButton(1);
								case -1: curSelectedMod = 0; hoveringOnMods = true; var button = getButton(); button.ignoreCheck = button.onFocus = false; changeSelectedMod();
							}
						}
						else if (controls.UI_RIGHT_P) { var button = getButton(); button.ignoreCheck = button.onFocus = false; curSelectedButton = 0; changeSelectedButton(); }
					}
					else if (controls.UI_LEFT_P) changeSelectedButton(-1);
					else if (controls.UI_RIGHT_P) changeSelectedButton(1);
				}
			}
		}
		else
		{
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
			nextAttempt -= elapsed;
			if (nextAttempt < 0)
			{
				nextAttempt = 1;
				@:privateAccess Mods.updateModList();
				modsList = Mods.parseList();
				if (modsList.all.length > 0) reload();
			}
		}

		super.update(elapsed);
	}

	// ═══════════════════════════════════════════════════════
	// 📜 LİSTE SCROLL
	// ═══════════════════════════════════════════════════════
	function updateListScroll(elapsed:Float)
	{
		if (modsGroup == null || modsGroup.members.length == 0) return;

		var visibleStart:Float = LIST_TOP;
		var visibleEnd:Float   = FlxG.height - effectiveDockH - 4;
		var visibleH:Float     = visibleEnd - visibleStart;

		var cardBaseY:Float = LIST_TOP + curSelectedMod * (ITEM_H + ITEM_GAP);
		var desired:Float   = cardBaseY - visibleStart - (visibleH / 2) + ITEM_H / 2;
		var maxOffset:Float = Math.max(0, modsList.all.length * (ITEM_H + ITEM_GAP) - visibleH);

		listScrollTarget = Math.max(0, Math.min(desired, maxOffset));
		listScrollOffset = FlxMath.lerp(listScrollTarget, listScrollOffset, Math.exp(-elapsed * 12));
		if (Math.abs(listScrollOffset - listScrollTarget) < 0.5) listScrollOffset = listScrollTarget;

		updateItemPositions();

		var rx:Float = FlxG.width - RIGHT_W;
		var selBaseY:Float = LIST_TOP + curSelectedMod * (ITEM_H + ITEM_GAP) - listScrollOffset;
		selectionBar.y     = selBaseY + 2;
		selectionBarGlow.y = selBaseY - 2;
	}

	// ═══════════════════════════════════════════════════════
	// 🔄 ITEM POZİSYONLARI
	// ═══════════════════════════════════════════════════════
	function updateItemPositions()
	{
		var rx:Float = FlxG.width - RIGHT_W;
		var visibleStart:Float = LIST_TOP;
		var visibleEnd:Float   = FlxG.height - effectiveDockH - 4;

		for (i in 0...modsGroup.members.length)
		{
			var mod = modsGroup.members[i];
			if (mod == null) continue;

			var baseY:Float = LIST_TOP + i * (ITEM_H + ITEM_GAP) - listScrollOffset;
			mod.x = rx + 8;
			mod.y = baseY;

			mod.visible = (baseY + ITEM_H > visibleStart) && (baseY < visibleEnd);

			var isSelected:Bool = (i == curSelectedMod);
			mod.alpha = isSelected ? 1 : 0.55;
			if (isSelected) mod.x += 6;

			mod.selectBg.visible = (isSelected && hoveringOnMods);
		}
	}

	// ═══════════════════════════════════════════════════════
	// 🎨 TEMA RENGİ GÜNCELLEMESİ
	// ═══════════════════════════════════════════════════════
	function updateAccentColor(newColor:FlxColor)
	{
		currentAccentColor = newColor;

		var newGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height, [newColor, 0x00000000], 1, 135
		);
		newGradient.scrollFactor.set(0, 0);
		newGradient.blend = ADD;
		newGradient.alpha = 0;

		var oldGradient = bgGradientDynamic;
		insert(members.indexOf(bgGradientDynamic), newGradient);
		FlxTween.tween(oldGradient, {alpha: 0}, 0.5, {onComplete: function(_) { remove(oldGradient); }});
		FlxTween.tween(newGradient, {alpha: 0.14}, 0.5);
		bgGradientDynamic = newGradient;

		for (orb in bgOrbs) orb.color = newColor;
		if (headerGlow != null) FlxTween.color(headerGlow, 0.4, headerGlow.color, newColor);
		if (iconGlowSprite != null) FlxTween.color(iconGlowSprite, 0.4, iconGlowSprite.color, newColor);
		if (selectionBar != null) FlxTween.color(selectionBar, 0.3, selectionBar.color, newColor);
	}

	// ═══════════════════════════════════════════════════════
	// ORİJİNAL FONKSİYONLAR
	// ═══════════════════════════════════════════════════════
	function changeSelectedButton(add:Int = 0)
	{
		var max = buttons.length - 1;
		var button = getButton(); button.ignoreCheck = button.onFocus = false;
		curSelectedButton += add;
		if (curSelectedButton < -2) curSelectedButton = -2;
		else if (curSelectedButton > max) curSelectedButton = max;
		var button = getButton(); button.ignoreCheck = button.onFocus = true;
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if (curMod != null) curMod.selectBg.visible = false;
		if (curSelectedButton < 0) bgButtons.alpha = 0.5; else bgButtons.alpha = 0.85;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function getButton()
	{
		switch(curSelectedButton)
		{
			case -2: return buttonReload;
			case -1: return buttonEnableAll.enabled ? buttonEnableAll : buttonDisableAll;
		}
		if (modsList.all.length < 1) return buttonReload;
		return buttons[Std.int(Math.max(0, Math.min(buttons.length - 1, curSelectedButton)))];
	}

	function changeSelectedMod(add:Int = 0, isMouseWheel:Bool = false)
	{
		var max = modsList.all.length - 1;
		if (max < 0) return;

		if (hoveringOnMods) { var button = getButton(); button.ignoreCheck = button.onFocus = false; }

		curSelectedMod += add;
		if (curSelectedMod < 0)        curSelectedMod = 0;
		else if (curSelectedMod > max) curSelectedMod = max;

		holdingMod = false; holdingElapsed = 0; gottaClickAgain = true;
		updateModDisplayData();

		if (add != 0)
		{
			FlxTween.cancelTweensOf(icon);
			var startOffsetY = (add > 0) ? 40 : -40;
			icon.y = iconTargetY + startOffsetY;
			icon.alpha = 0;
			FlxTween.tween(icon, {y: iconTargetY, alpha: 1}, 0.3, {ease: FlxEase.quartOut});
		}
		else { icon.y = iconTargetY; icon.alpha = 1; }

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		if (hoveringOnMods) { var curMod:ModItem = modsGroup.members[curSelectedMod]; if (curMod != null) curMod.selectBg.visible = true; }
	}

	function updateModDisplayData()
	{
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if (curMod == null) return;

		updateAccentColor(curMod.bgColor);

		if (Math.abs(centerMod - curSelectedMod) > 2)
		{
			if (centerMod < curSelectedMod) centerMod = curSelectedMod - 2;
			else centerMod = curSelectedMod + 2;
		}

		icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
		icon.antialiasing = curMod.icon.antialiasing;
		if (curMod.totalFrames > 0)
		{
			icon.animation.add("icon", [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
			icon.animation.play("icon");
			icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
		}
		icon.scale.set(2, 2);
		icon.updateHitbox();

		var showcaseW:Float = FlxG.width - RIGHT_W;
		iconTargetY = HEADER_H + 60 + (showcaseW / 2 - icon.height) * 0.5;
		icon.x = showcaseW / 2 - icon.width / 2;
		if (holdingMod) icon.y = iconTargetY;

		if (iconGlowSprite != null)
		{
			iconGlowSprite.x = showcaseW / 2 - iconGlowSprite.width / 2;
			iconGlowSprite.y = iconTargetY - 20;
		}

		var isEnabled = !modsList.disabled.contains(curMod.folder);
		enabledBadge.alpha      = isEnabled ? 0.9 : 0;
		enabledBadgeText.alpha  = isEnabled ? 1   : 0;
		disabledBadge.alpha     = isEnabled ? 0   : 0.9;
		disabledBadgeText.alpha = isEnabled ? 0   : 1;
		restartBadge.alpha      = curMod.mustRestart ? 0.9 : 0;
		restartBadgeText.alpha  = curMod.mustRestart ? 1   : 0;

		if (modName != null)
		{
			modName.text = curMod.name;
			modName.x = 20;
			modName.y = FlxG.height - 205;
			if (modName.width > showcaseW - 40) modName.scaleX = (showcaseW - 40) / modName.width;
			else modName.scaleX = 1;
		}

		if (modDesc != null)
		{
			modDesc.fieldWidth = Std.int(showcaseW - 40);
			modDesc.x = 20;
			modDesc.y = FlxG.height - 125;
			modDesc.text = curMod.desc;
		}
		if (modRestartText != null)
		{
			modRestartText.visible = curMod.mustRestart;
			modRestartText.x = 20;
			modRestartText.y = FlxG.height - 38;
		}

		if (modCountText != null)
			modCountText.text = '${curSelectedMod + 1} / ${modsList.all.length} MOD';

		for (button in buttons) if (button.focusChangeCallback != null) button.focusChangeCallback(button.onFocus);
		settingsButton.enabled = (curMod.settings != null && curMod.settings.length > 0);
	}

	function moveModToPosition(?mod:String = null, position:Int = 0)
	{
		if (mod == null) mod = modsList.all[curSelectedMod];
		if (position >= modsList.all.length) position = 0;
		else if (position < 0) position = modsList.all.length - 1;

		var id:Int = modsList.all.indexOf(mod);
		if (position == id) return;

		var curMod:ModItem = modsGroup.members[id];
		if (curMod == null) return;

		if (curMod.mustRestart || modsGroup.members[position].mustRestart) waitingToRestart = true;

		modsGroup.remove(curMod, true);
		modsList.all.remove(mod);
		modsGroup.insert(position, curMod);
		modsList.all.insert(position, mod);

		curSelectedMod = position;
		centerMod = curSelectedMod;
		updateModDisplayData();

		if (!hoveringOnMods) { var cMod:ModItem = modsGroup.members[curSelectedMod]; if (cMod != null) cMod.selectBg.visible = false; }
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function checkToggleButtons()
	{
		buttonEnableAll.visible  = buttonEnableAll.enabled  = (modsList.disabled.length > 0);
		buttonDisableAll.visible = buttonDisableAll.enabled = !buttonEnableAll.visible;
		buttonEnableAll.alpha    = buttonEnableAll.visible  ? 1 : 0;
		buttonDisableAll.alpha   = buttonDisableAll.visible ? 1 : 0;
	}

	function reload()
	{
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		MusicBeatState.switchState(new ModsMenuState(curMod != null ? curMod.folder : null));
	}

	function saveTxt()
	{
		var fileStr:String = '';
		for (mod in modsList.all)
		{
			if (mod.trim().length < 1) continue;
			if (fileStr.length > 0) fileStr += '\n';
			fileStr += '$mod|${modsList.disabled.contains(mod) ? "0" : "1"}';
		}
		// Android için StorageUtil, diğer platformlar için normal yol
		var path:String = #if android StorageUtil.getExternalStorageDirectory() + #else Sys.getCwd() + #end 'modsList.txt';
		File.saveContent(path, fileStr);
		Mods.parseList();
		Mods.loadTopMod();
	}
}

// ═══════════════════════════════════════════════════════════
// 📦 MOD LİSTE ÖĞESİ
// ═══════════════════════════════════════════════════════════
class ModItem extends FlxSpriteGroup
{
	public var selectBg:FlxSprite;
	public var accentBar:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var subText:FlxText;
	public var totalFrames:Int = 0;

	public var name:String      = 'Unknown Mod';
	public var desc:String      = 'No description provided.';
	public var iconFps:Int      = 10;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var pack:Dynamic     = null;
	public var folder:String    = 'unknownMod';
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;

	public function new(folder:String)
	{
		super();
		this.folder = folder;
		pack = Mods.getPack(folder);

		var path:String = Paths.mods('$folder/data/settings.json');
		if (FileSystem.exists(path))
		{
			try { settings = tjson.TJSON.parse(File.getContent(path)); } catch(e:Dynamic) {}
		}

		// Seçim arka planı
		selectBg = FlxGradient.createGradientFlxSprite(400, 78, [0x33FFFFFF, 0x11FFFFFF], 1, 0);
		selectBg.alpha = 0.18;
		selectBg.visible = false;
		add(selectBg);

		// Sol kenar vurgu
		accentBar = new FlxSprite(0, 4).makeGraphic(4, 70, FlxColor.WHITE);
		accentBar.alpha = 0;
		add(accentBar);

		// Alt border
		var bottomLine = new FlxSprite(4, 78).makeGraphic(396, 2, 0x22FFFFFF);
		add(bottomLine);

		icon = new FlxSprite(10, 10);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		text = new FlxText(78, 18, 300, "", 18);
		text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 1.5;
		add(text);

		subText = new FlxText(78, 48, 300, "", 13);
		subText.setFormat(Paths.font("vcr.ttf"), 13, 0xFF888888, LEFT);
		add(subText);

		var isPixel = false;
		var file:String = Paths.mods('$folder/pack.png');
		if (!FileSystem.exists(file)) { file = Paths.mods('$folder/pack-pixel.png'); isPixel = true; }

		var bmp:BitmapData = null;
		if (FileSystem.exists(file)) bmp = BitmapData.fromFile(file);
		else isPixel = false;

		if (FileSystem.exists(file))
		{
			icon.loadGraphic(Paths.cacheBitmap(file, bmp), true, 150, 150);
			if (isPixel) icon.antialiasing = false;
		}
		else icon.loadGraphic(Paths.image('unknownMod'), true, 150, 150);

		icon.scale.set(0.42, 0.42);
		icon.updateHitbox();

		this.name = folder;
		if (pack != null)
		{
			if (pack.name         != null) this.name = pack.name;
			if (pack.description  != null) this.desc = pack.description;
			if (pack.iconFramerate != null) this.iconFps = pack.iconFramerate;
			if (pack.color != null)
			{
				this.bgColor = FlxColor.fromRGB(
					pack.color[0] != null ? pack.color[0] : 102,
					pack.color[1] != null ? pack.color[1] : 90,
					pack.color[2] != null ? pack.color[2] : 255
				);
			}
			this.mustRestart = (pack.restart == true);
		}
		text.text    = this.name;
		subText.text = mustRestart ? "⚠ Restart gerekli" : folder;

		if (bmp != null)
		{
			totalFrames = Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150);
			icon.animation.add("icon", [for (i in 0...totalFrames) i], iconFps);
			icon.animation.play("icon");
		}

		icon.y = (78 - icon.height) / 2;
	}
}

// ═══════════════════════════════════════════════════════════
// 🔘 MENÜ BUTONU
// ═══════════════════════════════════════════════════════════
class MenuButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var textOn:Alphabet;
	public var textOff:Alphabet;
	public var icon:FlxSprite;
	public var onClick:Void->Void = null;
	public var enabled(default, set):Bool = true;

	public function new(x:Float, y:Float, width:Int, height:Int, ?text:String = null, ?img:FlxGraphic = null, onClick:Void->Void = null, animWidth:Int = 0, animHeight:Int = 0)
	{
		super(x, y);
		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT), 0, 0, width, height, 20, 20, FlxColor.WHITE);
		bg.color = FlxColor.BLACK;
		add(bg);

		if (text != null)
		{
			textOn = new Alphabet(0, 0, "", false);
			textOn.setScale(0.35);
			textOn.text = text;
			textOn.alpha = 0.8;
			textOn.visible = false;
			textOn.x = (width - textOn.width) / 2;
			textOn.y = (height - textOn.height) / 2;
			add(textOn);

			textOff = new Alphabet(0, 0, "", true);
			textOff.setScale(0.3);
			textOff.text = text;
			textOff.alpha = 0.6;
			textOff.x = (width - textOff.width) / 2;
			textOff.y = (height - textOff.height) / 2;
			add(textOff);
		}
		else if (img != null)
		{
			icon = new FlxSprite();
			if (animWidth > 0 || animHeight > 0) icon.loadGraphic(img, true, animWidth, animHeight);
			else icon.loadGraphic(img);
			icon.x = (width  - icon.width)  / 2;
			icon.y = (height - icon.height) / 2;
			add(icon);
		}

		this.onClick = onClick;
		setButtonVisibility(false);
	}

	public var focusChangeCallback:Bool->Void = null;
	public var onFocus(default, set):Bool = false;
	public var ignoreCheck:Bool = false;
	private var _needACheck:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!enabled) { onFocus = false; return; }

		// ── Mobil: dokunmatik ─────────────────────────────────
		if (Controls.instance.mobileC)
		{
			if (!ignoreCheck)
				onFocus = ScreenUtil.touch.overlaps(this);

			if (onFocus && ScreenUtil.touch.justReleased)
				onFocus = false;

			if (onFocus && onClick != null && ScreenUtil.touch.justPressed)
				onClick();

			if (_needACheck) { _needACheck = false; setButtonVisibility(ScreenUtil.touch.overlaps(this)); }
		}
		// ── PC/Konsol: mouse ──────────────────────────────────
		else
		{
			if (!ignoreCheck && !Controls.instance.controllerMode && (FlxG.mouse.justPressed || FlxG.mouse.justMoved) && FlxG.mouse.visible)
				onFocus = FlxG.mouse.overlaps(this);

			if (onFocus && onClick != null && FlxG.mouse.justPressed)
				onClick();

			if (_needACheck) { _needACheck = false; if (!Controls.instance.controllerMode) setButtonVisibility(FlxG.mouse.overlaps(this)); }
		}
	}

	function set_onFocus(newValue:Bool)
	{
		var lastFocus:Bool = onFocus;
		onFocus = newValue;
		if (onFocus != lastFocus && enabled) setButtonVisibility(onFocus);
		return newValue;
	}

	function set_enabled(newValue:Bool)
	{
		enabled = newValue;
		setButtonVisibility(false);
		alpha = enabled ? 1 : 0.4;
		_needACheck = enabled;
		return newValue;
	}

	public function setButtonVisibility(focusVal:Bool)
	{
		alpha = 1;
		bg.color = focusVal ? FlxColor.WHITE : FlxColor.BLACK;
		bg.alpha = focusVal ? 0.9 : 0.65;
		var focusAlpha = focusVal ? 1 : 0.6;
		if (textOn != null && textOff != null)
		{
			textOn.alpha = textOff.alpha = focusAlpha;
			textOn.visible  = focusVal;
			textOff.visible = !focusVal;
		}
		else if (icon != null)
		{
			icon.alpha = focusAlpha;
			icon.color = focusVal ? FlxColor.BLACK : FlxColor.WHITE;
		}
		if (!enabled) alpha = 0.4;
		if (focusChangeCallback != null) focusChangeCallback(focusVal);
	}
}
