package states.multiplayer.ui;

import states.multiplayer.api.GameBananaAPI;
import states.multiplayer.data.ModTypes;
import states.multiplayer.OnlineModsState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

class ModCard extends FlxSpriteGroup
{

    public static inline final CARD_W:Int        = 215;
    public static inline final CARD_H:Int        = 175;
    public static inline final THUMB_W:Int       = 215;
    public static inline final THUMB_H:Int       = 122;
    public static inline final PREVIEW_DELAY:Float = 2.0;

    public var modData:ModEntry;
    public var isSelected:Bool = false;

    public  var cardBg:FlxSprite;
    public  var downloadBg:FlxSprite;
    public  var linkBg:FlxSprite;
    private var cardGlow:FlxSprite;
    private var thumbnail:FlxSprite;
    private var thumbOverlay:FlxSprite;
    private var downloadIcon:FlxSprite;
    private var linkIcon:FlxSprite;
    private var nameLabel:FlxText;
    private var likesLabel:FlxText;
    private var categoryBadgeBg:FlxSprite;
    private var categoryLabel:FlxText;
    private var selectionBorder:FlxSprite;
    private var accentLine:FlxSprite;

    private var currentPreviewIndex:Int  = -1;
    private var previewTimer:Float       = 0.0;
    private var isLoadingPreview:Bool    = false;
    private var wasSelected:Bool         = false;
    private var hoverScale:Float         = 1.0;

    public function new(modData:ModEntry)
    {
        super();
        this.modData = modData;
        buildUI();
        loadThumbnail(0);
    }

    function buildUI():Void
    {

        cardGlow = new FlxSprite(-3, -3);
        cardGlow.makeGraphic(CARD_W + 6, CARD_H + 6, 0xFF0D9488);
        cardGlow.blend = ADD;
        cardGlow.alpha = 0;
        add(cardGlow);

        cardBg = FlxGradient.createGradientFlxSprite(
            CARD_W, CARD_H,
            [0xFF141E2E, 0xFF0D1520, 0xFF080F18],
            1, 90
        );
        cardBg.alpha = 0.92;
        add(cardBg);

        thumbnail = new FlxSprite();
        thumbnail.makeGraphic(THUMB_W, THUMB_H, 0xFF1A2535);
        thumbnail.clipRect = new FlxRect(0, 0, THUMB_W, THUMB_H);
        add(thumbnail);

        thumbOverlay = FlxGradient.createGradientFlxSprite(
            THUMB_W, 40,
            [0x00000000, 0xCC000000],
            1, 90
        );
        thumbOverlay.y = THUMB_H - 40;
        add(thumbOverlay);

        nameLabel = new FlxText(4, THUMB_H + 4, CARD_W - 8, modData.name);
        nameLabel.setFormat(
            Paths.font("vcr.ttf"), 13,
            FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK
        );
        nameLabel.borderSize = 1.2;
        nameLabel.wordWrap   = false;
        add(nameLabel);

        var likesStr = "♥ " + Std.string(modData.likes == null ? 0 : Std.int(modData.likes));
        var likesBg  = new FlxSprite();
        likesBg.makeGraphic(1, 1, 0xFF0D1520);
        likesBg.alpha = 0.85;

        likesLabel = new FlxText(0, 0, 0, likesStr);
        likesLabel.setFormat(
            Paths.font("vcr.ttf"), 12,
            0xFFFF6B9D, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK
        );

        likesBg.scale.set(likesLabel.width + 8, likesLabel.height + 4);
        likesBg.updateHitbox();
        likesBg.x = CARD_W - likesBg.width - 3;
        likesBg.y = THUMB_H - likesBg.height - 3;
        add(likesBg);

        likesLabel.x = likesBg.x + 4;
        likesLabel.y = likesBg.y + 2;
        add(likesLabel);

        buildCategoryBadge();

        accentLine = new FlxSprite(0, CARD_H - 2).makeGraphic(CARD_W, 2, 0xFF0D9488);
        accentLine.alpha = 0;
        add(accentLine);

        buildActionButtons();

        buildSelectionBorder();

        setActionButtonsVisible(false);
    }

    function buildCategoryBadge():Void
    {
        if (modData.category == null) return;

        categoryLabel = new FlxText(5, 4, 0, modData.category);
        categoryLabel.setFormat(
            Paths.font("vcr.ttf"), 10,
            FlxColor.WHITE, LEFT
        );

        categoryBadgeBg = new FlxSprite(3, 3);
        categoryBadgeBg.makeGraphic(1, 1, 0xFF0D9488);
        categoryBadgeBg.alpha = 0.8;
        categoryBadgeBg.scale.set(categoryLabel.width + 8, categoryLabel.height + 4);
        categoryBadgeBg.updateHitbox();
        add(categoryBadgeBg);
        add(categoryLabel);
    }

    function buildActionButtons():Void
    {
        var btnH  = 28;
        var btnY  = CARD_H - btnH - 3;
        var btnW1 = 90;
        var btnW2 = 75;

        downloadBg = new FlxSprite(4, btnY);
        downloadBg.makeGraphic(btnW1, btnH, 0xFF0D9488);
        downloadBg.alpha = 0.9;
        add(downloadBg);

        downloadIcon = new FlxText(4, btnY, btnW1, "⬇ İndir");
        cast(downloadIcon, FlxText).setFormat(
            Paths.font("vcr.ttf"), 12,
            FlxColor.WHITE, CENTER
        );
        cast(downloadIcon, FlxText).y += (btnH - cast(downloadIcon, FlxText).height) / 2;
        add(downloadIcon);

        linkBg = new FlxSprite(btnW1 + 8, btnY);
        linkBg.makeGraphic(btnW2, btnH, 0xFF1A3A5C);
        linkBg.alpha = 0.9;
        add(linkBg);

        linkIcon = new FlxText(btnW1 + 8, btnY, btnW2, "Linke Git");
        cast(linkIcon, FlxText).setFormat(
            Paths.font("vcr.ttf"), 12,
            FlxColor.WHITE, CENTER
        );
        cast(linkIcon, FlxText).y += (btnH - cast(linkIcon, FlxText).height) / 2;
        add(linkIcon);
    }

    function buildSelectionBorder():Void
    {
        selectionBorder = new FlxSprite(-2, -2);
        selectionBorder.makeGraphic(CARD_W + 4, CARD_H + 4, FlxColor.TRANSPARENT);
        selectionBorder.visible = false;

        var col = 0xFF0D9488;
        for (bx in 0...CARD_W + 4) {
            selectionBorder.pixels.setPixel32(bx, 0,          col);
            selectionBorder.pixels.setPixel32(bx, CARD_H + 3, col);
        }
        for (by in 0...CARD_H + 4) {
            selectionBorder.pixels.setPixel32(0,          by, col);
            selectionBorder.pixels.setPixel32(CARD_W + 3, by, col);
        }
        selectionBorder.dirty = true;
        add(selectionBorder);
    }

	function loadThumbnail(previewIndex:Int):Void
	{
		if (currentPreviewIndex == previewIndex) return;

		currentPreviewIndex = previewIndex;
		isLoadingPreview    = true;
		previewTimer        = 0.0;

		var url:String;
		if (previewIndex == 0) {
			url = modData.thumbnail.url;
		} else {
			var pIdx = previewIndex - 1;
			url = pIdx < modData.previews.length
				? modData.previews[pIdx].url
				: modData.thumbnail.url;
		}

		if (url == null || url.trim() == "") {
			trace("[ModCard] Empty URL for: " + modData.name);
			isLoadingPreview = false;
			return;
		}

		trace("[ModCard] Requesting image: " + url);

		GameBananaAPI.fetchImage(url, (bytes, err) -> {
			trace("[ModCard] fetchImage callback! exists=" + exists + " bytes=" + (bytes != null ? bytes.length : -1) + " err=" + err);

			if (!exists) {
				isLoadingPreview = false;
				return;
			}

			if (err != null || bytes == null) {
				trace("[ModCard] Image error: " + err);
				isLoadingPreview = false;
				return;
			}

			trace("[ModCard] Applying thumbnail for: " + modData.name);

			try {
				var bmp     = openfl.display.BitmapData.fromBytes(bytes);
				var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, null, false);

				thumbnail.loadGraphic(graphic);
				thumbnail.antialiasing = ClientPrefs.data.antialiasing;

				if (previewIndex == 0) {
					thumbnail.clipRect = new flixel.math.FlxRect(0, 0, THUMB_W, THUMB_H);
					var tw = modData.thumbnail.width;
					var th = modData.thumbnail.height;
					thumbnail.setGraphicSize(
						Std.int(tw),
						th < THUMB_H ? THUMB_H : Std.int(th)
					);
				} else {
					thumbnail.clipRect = null;
					thumbnail.setGraphicSize(THUMB_W, THUMB_H);
				}

				thumbnail.updateHitbox();
				trace("[ModCard] Thumbnail applied successfully!");
			}
			catch (e:Dynamic) {
				trace("[ModCard] BitmapData error: " + Std.string(e));
			}

			isLoadingPreview = false;
		});
	}

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        handleMouseHover();
        handlePreviewCycle(elapsed);
        updateVisuals(elapsed);
    }

    function handleMouseHover():Void
    {
        if (FlxG.mouse.overlaps(cardBg))
            states.multiplayer.OnlineModsState.hoveredCardID = ID;
    }

    function handlePreviewCycle(elapsed:Float):Void
    {
        if (!ClientPrefs.data.lowQuality && isSelected && !isLoadingPreview) {
            previewTimer += elapsed;
            if (previewTimer >= PREVIEW_DELAY) {
                var nextIdx = currentPreviewIndex + 1;
                if (nextIdx > modData.previews.length) nextIdx = 0;
                loadThumbnail(nextIdx);
            }
        }
    }

    function updateVisuals(elapsed:Float):Void
    {

        if (wasSelected != isSelected) {
            wasSelected = isSelected;
            setActionButtonsVisible(isSelected);
            selectionBorder.visible = isSelected;

            FlxTween.cancelTweensOf(accentLine);
            FlxTween.tween(accentLine, {alpha: isSelected ? 0.85 : 0}, 0.2);

            FlxTween.cancelTweensOf(cardGlow);
            FlxTween.tween(cardGlow, {alpha: isSelected ? 0.06 : 0}, 0.25);

            if (!isSelected && !ClientPrefs.data.lowQuality)
                loadThumbnail(0);
        }

        if (isSelected && !ClientPrefs.data.lowQuality) {
            var targetW = FlxG.mouse.overlaps(downloadBg) ? 1.03 : 1.0;
            downloadBg.scale.x = FlxMath.lerp(downloadBg.scale.x, targetW, elapsed * 12);
            downloadBg.scale.y = FlxMath.lerp(downloadBg.scale.y, targetW, elapsed * 12);

            var targetL = FlxG.mouse.overlaps(linkBg) ? 1.03 : 1.0;
            linkBg.scale.x = FlxMath.lerp(linkBg.scale.x, targetL, elapsed * 12);
            linkBg.scale.y = FlxMath.lerp(linkBg.scale.y, targetL, elapsed * 12);
        }

        cardBg.alpha = isSelected ? 0.97 : 0.88;
    }

    function setActionButtonsVisible(visible:Bool):Void
    {
        downloadBg.visible   = visible;
        downloadIcon.visible = visible;
        linkBg.visible       = visible;
        linkIcon.visible     = visible;
    }
}