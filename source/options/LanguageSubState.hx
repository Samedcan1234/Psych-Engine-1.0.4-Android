package options;

import flixel.addons.display.FlxBackdrop;

class LanguageSubState extends MusicBeatSubstate
{
    #if TRANSLATIONS_ALLOWED

    var langKeys:Array<String> = [];
    var curSelected:Int        = 0;
    var changedLanguage:Bool   = false;

    static final LOCKED_LANGS:Array<String> = ["mexico", "french", "azerbaycan"];

    var scrollOffset:Float     = 0;
    var targetScrollOffset:Float = 0;

    static final ITEM_H:Float    = 72;
    static final ITEM_GAP:Float  = 5;
    static final LIST_X:Float    = 24;
    static final LIST_Y:Float    = 86;
    static final LIST_W:Float    = 400;
    static final DIVIDER_X:Float = 448;
    static final PREVIEW_CX:Float = 640; 

    var listItems:Array<LangItem> = [];
    var listGroup:FlxTypedGroup<LangItem>;

    var bg:FlxSprite;
    var bgTint:FlxSprite;
    var scanlines:FlxBackdrop;
    var glowOrb1:FlxSprite;
    var glowOrb2:FlxSprite;
    var ambientTimer:Float = 0;

    var topBar:FlxSprite;
    var topBarLine:FlxSprite;
    var topBarGlow:FlxSprite;
    var titleText:FlxText;
    var badgeBG:FlxSprite;
    var badgeText:FlxText;
    var backBtn:FlxSprite;
    var backBtnBorder:FlxSprite;
    var backBtnText:FlxText;

    var activeBar:FlxSprite;
    var activeGlow:FlxSprite;

    var previewPanel:FlxSprite;
    var previewPanelGlow:FlxSprite;
    var previewDivider:FlxSprite;
    var previewFlag:FlxSprite;
    var previewFlagGlow:FlxSprite;
    var previewFlagFrame:FlxSprite;
    var previewLangName:FlxText;
    var previewNativeName:FlxText;
    var previewTagBG:FlxSprite;
    var previewTagText:FlxText;

    var confirmBG:FlxSprite;
    var confirmBGGlow:FlxSprite;
    var confirmBorder:FlxSprite;
    var confirmText:FlxText;
    var confirmKeyHint:FlxText;

    var hintBar:FlxSprite;
    var hintText:FlxText;

    var entranceTimer:Float = 0;
    var ready:Bool = false;

    static final COL_ACCENT:FlxColor  = 0xFF6333FF;
    static final COL_ACCENT2:FlxColor = 0xFF00C8FF;
    static final COL_BG:FlxColor      = 0xFF060612;
    static final COL_PANEL:FlxColor   = 0xFF0D0D22;
    static final COL_ITEM:FlxColor    = 0xFF111130;
    static final COL_ITEM_ACT:FlxColor= 0xFF1E1250;
    static final COL_TEXT:FlxColor    = 0xFFFFFFFF;
    static final COL_MUTED:FlxColor   = 0xFF7070AA;

    public function new()
    {
        super();

        Language.registerLanguages();

        for (key in Language.registeredLanguages.keys())
            langKeys.push(key);

        langKeys.sort(function(a, b) {
            var na = Language.getLangDisplayName(a).toLowerCase();
            var nb = Language.getLangDisplayName(b).toLowerCase();
            return na < nb ? -1 : na > nb ? 1 : 0;
        });

        curSelected = langKeys.indexOf(ClientPrefs.data.language.toLowerCase());
        if (curSelected < 0) curSelected = 0;

        buildBackground();
        buildTopBar();
        buildDivider();
        buildPreviewPanel();
        buildListGroup();
        buildConfirmButton();
        buildHintBar();

        updateAllItems();
        updatePreview(false);
        snapScroll();

        entranceSlideIn();

        try {
            addTouchPad('LEFT_FULL', 'A_B');
        } catch(e:Dynamic) {
            addTouchPad('LEFT_RIGHT', 'A_B_E');
        }

        FlxG.camera.fade(COL_BG, 0.25, true);
    }

    function isLangLocked(key:String):Bool
    {
        return LOCKED_LANGS.contains(key.toLowerCase());
    }

    function buildBackground():Void
    {
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = COL_BG;
        bg.alpha = 1.0;
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.screenCenter();
        add(bg);

        bgTint = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bgTint.alpha = 0.82;
        add(bgTint);

        glowOrb1 = new FlxSprite(-120, -80).makeGraphic(500, 400, 0x00000000);
        glowOrb1.makeGraphic(500, 400, 0x00000000);
        _drawRadialGlow(glowOrb1, 500, 400, 0.18, COL_ACCENT);
        glowOrb1.alpha = 0.7;
        add(glowOrb1);

        glowOrb2 = new FlxSprite(FlxG.width - 300, FlxG.height - 350).makeGraphic(400, 400, 0x00000000);
        _drawRadialGlow(glowOrb2, 400, 400, 0.14, COL_ACCENT2);
        glowOrb2.alpha = 0.5;
        add(glowOrb2);

        scanlines = new FlxBackdrop(null, Y, 0, 3);
        scanlines.makeGraphic(FlxG.width, 2, 0x08FFFFFF);
        scanlines.velocity.y = 0;
        scanlines.alpha = 0.15;
        add(scanlines);
    }

    function _drawRadialGlow(spr:FlxSprite, w:Int, h:Int, intensity:Float, col:FlxColor):Void
    {
        var bmp = new openfl.display.BitmapData(w, h, true, 0x00000000);
        var cx  = w * 0.5;
        var cy  = h * 0.5;
        var r   = Math.min(cx, cy);
        for (px in 0...w)
        for (py in 0...h)
        {
            var dx = px - cx;
            var dy = py - cy;
            var dist = Math.sqrt(dx * dx + dy * dy);
            if (dist >= r) continue;
            var t = 1 - dist / r;
            t = t * t; 

            var a = Std.int(t * intensity * 255);
            if (a <= 0) continue;
            bmp.setPixel32(px, py, (a << 24) | (col.rgb));
        }
        spr.pixels = bmp;
    }

    function buildTopBar():Void
    {
        topBarGlow = new FlxSprite(0, 0).makeGraphic(FlxG.width, 82, COL_ACCENT);
        topBarGlow.alpha = 0.05;
        add(topBarGlow);

        topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 78, COL_PANEL);
        topBar.alpha = 0.97;
        add(topBar);

        topBarLine = new FlxSprite(0, 76).makeGraphic(FlxG.width, 2, COL_ACCENT);
        topBarLine.alpha = 0.4;
        add(topBarLine);

        backBtnBorder = new FlxSprite(LIST_X, 22).makeGraphic(36, 36, COL_ACCENT);
        backBtnBorder.alpha = 0.25;
        add(backBtnBorder);

        backBtn = new FlxSprite(LIST_X + 1, 23).makeGraphic(34, 34, COL_ITEM);
        add(backBtn);

        backBtnText = new FlxText(LIST_X + 1, 23, 36, "←", 18);
        backBtnText.setFormat(Paths.font("vcr.ttf"), 18, COL_MUTED, CENTER);
        add(backBtnText);

		titleText = new FlxText(LIST_X + 52, 16, 260, "D İ L   S E Ç İ M İ", 13);
        titleText.setFormat(Paths.font("vcr.ttf"), 13, COL_MUTED, LEFT);
        add(titleText);

        var subTitle = new FlxText(LIST_X + 52, 36, 260, "Language / Sprache / Langue", 11);
        subTitle.setFormat(Paths.font("vcr.ttf"), 11, 0xFF444466, LEFT);
        add(subTitle);

        var badgeW = 90;
        badgeBG = new FlxSprite(FlxG.width - badgeW - 24, 26).makeGraphic(badgeW, 26, COL_ACCENT);
        badgeBG.alpha = 0.15;
        add(badgeBG);

        var badgeBorder = new FlxSprite(FlxG.width - badgeW - 24, 26).makeGraphic(badgeW, 1, COL_ACCENT);
        badgeBorder.alpha = 0.35;
        add(badgeBorder);

        badgeText = new FlxText(FlxG.width - badgeW - 24, 29, badgeW, langKeys.length + " DİL", 11);
        badgeText.setFormat(Paths.font("vcr.ttf"), 11, COL_ACCENT, CENTER);
        add(badgeText);
    }

    function buildDivider():Void
    {

        var leftBG = new FlxSprite(0, 78).makeGraphic(Std.int(DIVIDER_X), Std.int(FlxG.height - 78), COL_PANEL);
        leftBG.alpha = 0.5;
        add(leftBG);

        previewDivider = new FlxSprite(DIVIDER_X - 1, 78).makeGraphic(2, Std.int(FlxG.height - 112), COL_ACCENT);
        previewDivider.alpha = 0.18;
        add(previewDivider);

        activeBar = new FlxSprite(LIST_X - 2, LIST_Y).makeGraphic(3, Std.int(ITEM_H - 10), COL_ACCENT);
        activeBar.alpha = 0.9;
        add(activeBar);

        activeGlow = new FlxSprite(LIST_X - 2, LIST_Y).makeGraphic(18, Std.int(ITEM_H - 10), COL_ACCENT);
        activeGlow.alpha = 0.08;
        add(activeGlow);
    }

    function buildPreviewPanel():Void
    {
        var panelX = Std.int(DIVIDER_X + 1);
        var panelW = Std.int(FlxG.width - DIVIDER_X - 1);
        var panelH = Std.int(FlxG.height - 112);

        previewPanel = new FlxSprite(panelX, 78).makeGraphic(panelW, panelH, 0xFF080818);
        previewPanel.alpha = 0.75;
        add(previewPanel);

        previewFlagGlow = new FlxSprite(panelX + 20, 110).makeGraphic(panelW - 40, 180, COL_ACCENT);
        _drawRadialGlow(previewFlagGlow, panelW - 40, 180, 0.25, COL_ACCENT);
        previewFlagGlow.alpha = 0.6;
        add(previewFlagGlow);

        previewFlag = new FlxSprite(0, 0);
        previewFlag.antialiasing = ClientPrefs.data.antialiasing;
        previewFlag.makeGraphic(200, 130, COL_ITEM);
        add(previewFlag);

        previewFlagFrame = new FlxSprite(0, 0).makeGraphic(200, 2, COL_ACCENT);
        previewFlagFrame.alpha = 0.5;
        add(previewFlagFrame);

        var nameY = Std.int(FlxG.height * 0.58);
        previewLangName = new FlxText(panelX, nameY, panelW, "", 30);
        previewLangName.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, 0xFF000000);
        previewLangName.borderSize = 2;
        add(previewLangName);

        previewNativeName = new FlxText(panelX, nameY + 36, panelW, "", 13);
        previewNativeName.setFormat(Paths.font("vcr.ttf"), 13, COL_MUTED, CENTER);
        add(previewNativeName);

        var tagW = 80;
        var tagX = Std.int(panelX + (panelW - tagW) * 0.5);
        previewTagBG = new FlxSprite(tagX, nameY + 64).makeGraphic(tagW, 20, COL_ACCENT);
        previewTagBG.alpha = 0.15;
        add(previewTagBG);

        var tagBorder = new FlxSprite(tagX, nameY + 64).makeGraphic(tagW, 1, COL_ACCENT);
        tagBorder.alpha = 0.3;
        add(tagBorder);

        previewTagText = new FlxText(tagX, nameY + 66, tagW, "LTR", 10);
        previewTagText.setFormat(Paths.font("vcr.ttf"), 10, COL_ACCENT, CENTER);
        add(previewTagText);
    }

    function buildListGroup():Void
    {
        listGroup = new FlxTypedGroup<LangItem>();
        add(listGroup);

        for (i in 0...langKeys.length)
        {
            var key = langKeys[i];
            var isLocked = isLangLocked(key);

            var item = new LangItem(
                LIST_X + 8,
                LIST_Y + i * (ITEM_H + ITEM_GAP),
                key,
                Language.getLangDisplayName(key),
                Std.int(LIST_W),
                isLocked
            );
            listItems.push(item);
            listGroup.add(item);
        }
    }

    function buildConfirmButton():Void
    {
        var panelX  = Std.int(DIVIDER_X + 1);
        var panelW  = Std.int(FlxG.width - DIVIDER_X - 1);
        var btnW    = panelW - 40;
        var btnH    = 42;
        var btnX    = Std.int(panelX + 20);
        var btnY    = Std.int(FlxG.height - 90);

        confirmBGGlow = new FlxSprite(btnX - 2, btnY - 2).makeGraphic(btnW + 4, btnH + 4, COL_ACCENT);
        confirmBGGlow.alpha = 0.2;
        add(confirmBGGlow);

        confirmBG = new FlxSprite(btnX, btnY).makeGraphic(btnW, btnH, COL_ACCENT);
        confirmBG.alpha = 0.85;
        add(confirmBG);

        confirmBorder = new FlxSprite(btnX, btnY).makeGraphic(btnW, 2, FlxColor.WHITE);
        confirmBorder.alpha = 0.15;
        add(confirmBorder);

        confirmText = new FlxText(btnX, btnY + 8, btnW, "SEÇ", 18);
        confirmText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, 0xFF000000);
        confirmText.borderSize = 1;
        add(confirmText);

        confirmKeyHint = new FlxText(btnX, btnY + 28, btnW, "ENTER", 10);
        confirmKeyHint.setFormat(Paths.font("vcr.ttf"), 10, 0xFF9999CC, CENTER);
        add(confirmKeyHint);
    }

    function buildHintBar():Void
    {
        hintBar = new FlxSprite(0, FlxG.height - 34).makeGraphic(FlxG.width, 34, COL_PANEL);
        hintBar.alpha = 0.95;
        add(hintBar);

        var hintBorder = new FlxSprite(0, FlxG.height - 34).makeGraphic(FlxG.width, 1, COL_ACCENT);
        hintBorder.alpha = 0.2;
        add(hintBorder);

        var hintStr = controls.mobileC
            ? "A: Seç    B: Geri    ↑↓: Gezin"
            : "ENTER: Seç    ESC: Geri    ↑↓: Gezin    SHIFT+↑↓: Hızlı";

        hintText = new FlxText(0, FlxG.height - 26, FlxG.width, hintStr, 11);
        hintText.setFormat(Paths.font("vcr.ttf"), 11, COL_MUTED, CENTER);
        add(hintText);
    }

    function entranceSlideIn():Void
    {

        for (item in listItems)
        {
            item.x = -LIST_W - 50;
            FlxTween.tween(item, {x: LIST_X + 8},
                0.45 + listItems.indexOf(item) * 0.03,
                {ease: FlxEase.quartOut, startDelay: 0.05});
        }

        topBar.y = -82;
        topBarGlow.y = -82;
        topBarLine.y = topBar.y + 76;
        FlxTween.tween(topBar, {y: 0}, 0.4, {ease: FlxEase.backOut});
        FlxTween.tween(topBarGlow, {y: 0}, 0.4, {ease: FlxEase.backOut});
        FlxTween.tween(topBarLine, {y: 76}, 0.4, {ease: FlxEase.backOut});

        var rightElements = [previewPanel, previewFlag, previewFlagGlow,
            previewFlagFrame, previewLangName, previewNativeName,
            previewTagBG, previewTagText, confirmBG, confirmBGGlow,
            confirmBorder, confirmText, confirmKeyHint];

        for (el in rightElements)
        {
            var origX = el.x;
            el.x = FlxG.width + 50;
            FlxTween.tween(el, {x: origX}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.15});
        }

        new FlxTimer().start(0.5, function(_) ready = true);
    }

    function updatePreview(animate:Bool = true):Void
    {
        var key = langKeys[curSelected];
        var displayName = Language.getLangDisplayName(key);
        var locked = isLangLocked(key);

        var flagPath = 'ultra/language/$key';
        try {
            previewFlag.loadGraphic(Paths.image(flagPath));
        } catch(e:Dynamic) {
            previewFlag.makeGraphic(200, 130, COL_ITEM_ACT);
        }

        if (locked) {
            previewFlag.alpha = 0.4;
        } else {
            previewFlag.alpha = 1.0;
        }

        var maxW:Float = Std.int(FlxG.width - DIVIDER_X - 42);
        var maxH:Float = 145.0;
        var scaleW = maxW / previewFlag.frameWidth;
        var scaleH = maxH / previewFlag.frameHeight;
        var sc = Math.min(scaleW, scaleH);
        previewFlag.setGraphicSize(
            Std.int(previewFlag.frameWidth * sc),
            Std.int(previewFlag.frameHeight * sc)
        );
        previewFlag.updateHitbox();

        var panelCX = DIVIDER_X + (FlxG.width - DIVIDER_X) * 0.5;
        previewFlag.x = panelCX - previewFlag.width * 0.5;
        previewFlag.y = 105;

        previewFlagFrame.x = previewFlag.x;
        previewFlagFrame.y = previewFlag.y + previewFlag.height;
        previewFlagFrame.makeGraphic(Std.int(previewFlag.width), 2, COL_ACCENT);

        previewFlagGlow.x = panelCX - (FlxG.width - DIVIDER_X - 40) * 0.5;
        previewFlagGlow.y = 95;

        previewLangName.text = locked ? "🔒 " + displayName.toUpperCase() : displayName.toUpperCase();
        previewNativeName.text = key.toUpperCase() + "  ·  " + displayName;

        var rtlLangs = ["arabic", "hebrew", "persian", "urdu"];
        var isRTL = rtlLangs.contains(key.toLowerCase());
        previewTagText.text = locked ? "LOCKED" : (isRTL ? "RTL" : "LTR");
        previewTagText.color = locked ? 0xFFFF4444 : (isRTL ? 0xFFFFAA33 : COL_ACCENT);
        previewTagBG.color   = locked ? 0xFFFF4444 : (isRTL ? 0xFFFFAA33 : COL_ACCENT);

        if (animate)
        {
            previewFlag.alpha = locked ? 0 : 0;
            previewLangName.alpha = 0;
            previewNativeName.alpha = 0;
            FlxTween.cancelTweensOf(previewFlag);
            FlxTween.cancelTweensOf(previewLangName);
            FlxTween.cancelTweensOf(previewNativeName);
            FlxTween.tween(previewFlag, {alpha: locked ? 0.4 : 1}, 0.2, {ease: FlxEase.quadOut});
            FlxTween.tween(previewLangName, {alpha: 1}, 0.25, {ease: FlxEase.quadOut, startDelay: 0.05});
            FlxTween.tween(previewNativeName, {alpha: 1}, 0.25, {ease: FlxEase.quadOut, startDelay: 0.1});
        }
        else
        {
            previewFlag.alpha = locked ? 0.4 : 1;
            previewLangName.alpha = 1;
            previewNativeName.alpha = 1;
        }
    }

    function updateAllItems():Void
    {
        for (i in 0...listItems.length)
            listItems[i].setSelected(i == curSelected);
    }

    function snapScroll():Void
    {

        var visibleH = FlxG.height - 112 - 34;
        targetScrollOffset = curSelected * (ITEM_H + ITEM_GAP)
            - visibleH * 0.5 + ITEM_H * 0.5;

        var maxScroll = Math.max(0, langKeys.length * (ITEM_H + ITEM_GAP) - visibleH);
        targetScrollOffset = Math.max(0, Math.min(targetScrollOffset, maxScroll));
        scrollOffset = targetScrollOffset;

        applyScroll();
    }

    function applyScroll():Void
    {
        for (i in 0...listItems.length)
        {
            var item = listItems[i];
            var targetY = LIST_Y + i * (ITEM_H + ITEM_GAP) - scrollOffset;
            item.y = targetY;

            item.visible = (targetY + ITEM_H > LIST_Y - 10) && (targetY < FlxG.height - 34);
            item.alpha = item.visible ? 1 : 0;
        }

        if (curSelected < listItems.length)
        {
            var activeItem = listItems[curSelected];
            activeBar.y  = activeItem.y + 5;
            activeGlow.y = activeItem.y + 5;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        ambientTimer += elapsed;

        glowOrb1.alpha = 0.6 + Math.sin(ambientTimer * 0.7) * 0.15;
        glowOrb2.alpha = 0.4 + Math.sin(ambientTimer * 0.9 + 1) * 0.1;
        topBarGlow.alpha = 0.04 + Math.sin(ambientTimer * 1.2) * 0.015;

        confirmBGGlow.alpha = 0.15 + Math.sin(ambientTimer * 2) * 0.08;

        activeBar.alpha  = 0.8 + Math.sin(ambientTimer * 3) * 0.2;
        activeGlow.alpha = 0.06 + Math.sin(ambientTimer * 2) * 0.03;

        scrollOffset = FlxMath.lerp(targetScrollOffset, scrollOffset, Math.exp(-elapsed * 12));
        if (Math.abs(scrollOffset - targetScrollOffset) < 0.5)
            scrollOffset = targetScrollOffset;
        applyScroll();

        if (!ready) return;

        var mult:Int = FlxG.keys.pressed.SHIFT ? 5 : 1;

        if (controls.UI_UP_P)   changeSelected(-1 * mult);
        if (controls.UI_DOWN_P) changeSelected(1  * mult);

        if (FlxG.mouse.wheel != 0)
            changeSelected(-FlxG.mouse.wheel * 2);

        if (FlxG.mouse.justPressed)
        {
            for (i in 0...listItems.length)
            {
                if (listItems[i].visible && FlxG.mouse.overlaps(listItems[i]))
                {
                    if (i == curSelected)
                        confirmSelection();
                    else
                    {
                        curSelected = i;
                        updateAllItems();
                        smoothScroll();
                        updatePreview(true);
                        FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
                    }
                    break;
                }
            }
        }

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            slideOut(function() {
                if (changedLanguage)
                {
                    FlxTransitionableState.skipNextTransIn  = true;
                    FlxTransitionableState.skipNextTransOut = true;
                    MusicBeatState.resetState();
                }
                else close();
            });
        }

        if (controls.ACCEPT) confirmSelection();
    }

    function changeSelected(change:Int):Void
    {
        if (langKeys.length == 0) return;
        curSelected = FlxMath.wrap(curSelected + change, 0, langKeys.length - 1);
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
        updateAllItems();
        smoothScroll();
        updatePreview(true);
    }

    function smoothScroll():Void
    {
        var visibleH = FlxG.height - 112 - 34;
        targetScrollOffset = curSelected * (ITEM_H + ITEM_GAP)
            - visibleH * 0.5 + ITEM_H * 0.5;

        var maxScroll = Math.max(0, langKeys.length * (ITEM_H + ITEM_GAP) - visibleH);
        targetScrollOffset = Math.max(0, Math.min(targetScrollOffset, maxScroll));
    }

	function confirmSelection():Void
	{	
		var key = langKeys[curSelected];

		if (isLangLocked(key))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			AlertMsg.show(
				Language.getPhrase('language_locked_title', 'Dil Kilitli!'),
				Language.getPhrase('language_locked_msg', 'Bu dil şu anda kullanılamıyor.'),
				3,
				AlertMsg.COLOR_ERROR
			);
			return;
		}

		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

		ClientPrefs.data.language = key;
		ClientPrefs.saveSettings();
		Language.reloadPhrases();

		AlertMsg.show(
			Language.getPhrase('language_changed_title', 'Dil Değiştirildi!'),
			Language.getPhrase('language_changed_msg', 'Diliniz değiştirildi.'),
			4,
			AlertMsg.COLOR_SUCCESS
		);

		FlxTween.cancelTweensOf(confirmBG);
		confirmBG.alpha = 1.0;
		FlxTween.tween(confirmBG, {alpha: 0.85}, 0.3);

		var item = listItems[curSelected];
		FlxTween.cancelTweensOf(item);
		item.alpha = 0.4;
		FlxTween.tween(item, {alpha: 1.0}, 0.25);

		changedLanguage = true;
		hintText.text = '✓  ' + Language.getLangDisplayName(key).toUpperCase() + '  —  DİL DEĞİŞTİRİLDİ';
		hintText.color = 0xFF00FF99;
	}

    function slideOut(callback:Void->Void):Void
    {
        ready = false;
        FlxG.camera.fade(COL_BG, 0.25, false, callback);
    }

    #end 

}

#if TRANSLATIONS_ALLOWED
class LangItem extends FlxSpriteGroup
{
    var bg:FlxSprite;
    var bgBorder:FlxSprite;
    var selectedLine:FlxSprite;
    var icon:FlxSprite;
    var lockIcon:FlxSprite;
    var label:FlxText;
    var nativeLabel:FlxText;

    static final W:Int = 390;
    static final H:Int = 66;

    public var langKey:String;
    public var isLocked:Bool = false;

    public function new(x:Float, y:Float, key:String, displayName:String, w:Int, locked:Bool = false)
    {
        super(x, y);
        langKey = key;
        isLocked = locked;

        bg = new FlxSprite().makeGraphic(W, H, 0xFF111128);
        bg.alpha = locked ? 0.5 : 0.8;
        add(bg);

        bgBorder = new FlxSprite(0, 0).makeGraphic(W, 1, 0xFF3333AA);
        bgBorder.alpha = 0.2;
        add(bgBorder);

        selectedLine = new FlxSprite(0, 8).makeGraphic(3, H - 16, 0xFF6333FF);
        selectedLine.alpha = 0;
        add(selectedLine);

        icon = new FlxSprite(14, (H - 42) * 0.5);
        var iconPath = 'ultra/language/${key}_icon';
        try {
            icon.loadGraphic(Paths.image(iconPath));
            icon.setGraphicSize(42, 28);
            icon.updateHitbox();
        } catch(e:Dynamic) {
            icon.makeGraphic(42, 28, 0xFF222244);
        }
        icon.antialiasing = ClientPrefs.data.antialiasing;

        if (locked) {
            icon.alpha = 0.4;
        }
        add(icon);

        if (locked)
        {
            lockIcon = new FlxSprite(14 + 42 - 14, (H - 42) * 0.5 + 28 - 14);
            try {
                lockIcon.loadGraphic(Paths.image('ultra/language/lock'));
                lockIcon.setGraphicSize(16, 16);
                lockIcon.updateHitbox();
            } catch(e:Dynamic) {
                lockIcon.makeGraphic(16, 16, 0xFFFF4444);
            }
            lockIcon.antialiasing = ClientPrefs.data.antialiasing;
            add(lockIcon);
        }

        label = new FlxText(70, 12, W - 80, displayName, 18);
        label.setFormat(Paths.font("vcr.ttf"), 18, locked ? 0xFF666677 : 0xFFCCCCEE, LEFT,
            FlxTextBorderStyle.NONE);
        add(label);

        nativeLabel = new FlxText(70, 35, W - 80, key.toLowerCase(), 11);
        nativeLabel.setFormat(Paths.font("vcr.ttf"), 11, locked ? 0xFF444455 : 0xFF555577, LEFT);
        add(nativeLabel);
    }

    public function setSelected(sel:Bool):Void
    {
        FlxTween.cancelTweensOf(bg);
        FlxTween.cancelTweensOf(selectedLine);
        FlxTween.cancelTweensOf(label);

        if (sel)
        {
            if (!isLocked) {
                FlxTween.color(bg, 0.2, bg.color, 0xFF1E1250);
                bg.alpha = 1.0;
            } else {
                FlxTween.color(bg, 0.2, bg.color, 0xFF2A1520);
                bg.alpha = 0.6;
            }
            FlxTween.tween(selectedLine, {alpha: isLocked ? 0.3 : 1.0}, 0.2);
            label.color = isLocked ? 0xFF888899 : FlxColor.WHITE;
            label.size = 19;
        }
        else
        {
            FlxTween.color(bg, 0.2, bg.color, 0xFF111128);
            bg.alpha = isLocked ? 0.4 : 0.75;
            FlxTween.tween(selectedLine, {alpha: 0.0}, 0.2);
            label.color = isLocked ? 0xFF555566 : 0xFF9090BB;
            label.size = 17;
        }
        label.y = sel ? 10 : 12;
    }
}
#end