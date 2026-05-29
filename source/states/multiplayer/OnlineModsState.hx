package states.multiplayer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import backend.ui.PsychUIInputText;
import states.multiplayer.api.GameBananaAPI;
import states.multiplayer.data.ModTypes;
import states.multiplayer.ui.ModCard;
import states.multiplayer.ui.DownloadSubstate;

#if DISCORD_ALLOWED
import backend.Discord.DiscordClient;
#end

class OnlineModsState extends MusicBeatState
{

    public static var hoveredCardID:Int = -1;

    static inline final COLS:Int            = 5;
    static inline final CARD_SPACING_X:Int  = 232;
    static inline final CARD_SPACING_Y:Int  = 188;
    static inline final HEADER_H:Int        = 95;
    static inline final FOOTER_H:Int        = 48;

    var gridStartY:Int = HEADER_H + 68;

    var bgBase:FlxSprite;
    var bgGradient:FlxSprite;
    var bgGradientDynamic:FlxSprite;
    var gridBG:FlxBackdrop;
    var bgOrbs:Array<FlxSprite>       = [];
    var floatingShapes:Array<FlxSprite> = [];
    var bgVignette:FlxSprite;

    var headerPanel:FlxSprite;
    var headerGlow:FlxSprite;
    var headerTitle:FlxText;
    var headerSubtitle:FlxText;
    var headerBreadcrumb:FlxText;

    var searchBarBg:FlxSprite;
    var searchBarGlow:FlxSprite;
    var searchInput:PsychUIInputText;
    var searchPlaceholder:FlxText;

    var sortButtons:Array<SortButton>  = [];
    var curSortIndex:Int               = 0;
    static final SORT_OPTIONS = [
        {label: "🕒 En Yeni",   value: "new"},
        {label: "🔥 Popüler",  value: "popular"},
        {label: "📥 İndirilenler",value: "downloads"},
        {label: "♥ Beğenilenler",    value: "liked"},
    ];

    var cardGroup:FlxTypedGroup<ModCard>;

    var footerPanel:FlxSprite;
    var footerGlow:FlxSprite;
    var pageInfoText:FlxText;
    var resultCountText:FlxText;
    var controlHintsText:FlxText;

    var loadingOverlay:FlxSprite;
    var loadingSpinner:FlxSprite;
    var loadingLabel:FlxText;
    var spinnerAngle:Float = 0;

    var errorPanel:FlxSprite;
    var errorText:FlxText;
    var errorTimer:Float  = 0;

    var currentPage:Int            = 1;
    var isLoading:Bool             = false;
    var curSelected:Int            = 0;
    var loadedMods:Array<ModEntry> = [];
    var _isDestroyed:Bool          = false;

    var searchQuery:Null<String>   = null;
    var sortOrder:Null<String>     = "new";
    var collectionID:Null<String>  = null;
    var initQuery:String           = "";

    var animTimer:Float  = 0;
    var waveTimer:Float  = 0;
    var glowTimer:Float  = 0;
    var floatTimer:Float = 0;

    var currentAccentColor:FlxColor = 0xFF0D9488;

    public function new(?query:String = "")
    {
        super();
        initQuery = query;
    }

    override function create():Void
    {
        curSelected   = 0;
        hoveredCardID = -1;
        _isDestroyed  = false;

        super.create();
        FlxG.mouse.visible = true;

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Online Mod Tarayıcısı", null, null, false);
        #end

        buildBackground();
        buildHeader();
        buildSearchAndSort();

        cardGroup = new FlxTypedGroup<ModCard>();
        add(cardGroup);

        buildFooter();
        buildLoadingOverlay();
        buildErrorPanel();

        playEntranceAnimation();

        if (FlxG.sound.music != null)
            FlxG.sound.music.fadeIn(1, 1, 0.5);

        if (initQuery != "")
            searchInput.text = initQuery;

        fetchPage(true);
    }

    override function destroy():Void
    {
        _isDestroyed = true;
        if (PsychUIInputText.focusOn == searchInput)
            PsychUIInputText.focusOn = null;
        GameBananaAPI.clearImageCache();
        super.destroy();
    }

    function buildBackground():Void
    {

        bgBase = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF080812);
        bgBase.scrollFactor.set(0, 0);
        add(bgBase);

        bgGradient = FlxGradient.createGradientFlxSprite(
            FlxG.width, FlxG.height,
            [0xFF0d1117, 0xFF0a0e1a, 0xFF070b14, 0xFF050810],
            1, 120
        );
        bgGradient.scrollFactor.set(0, 0);
        bgGradient.alpha = 0.97;
        add(bgGradient);

        bgGradientDynamic = FlxGradient.createGradientFlxSprite(
            FlxG.width, FlxG.height,
            [currentAccentColor, 0x00000000],
            1, 135
        );
        bgGradientDynamic.scrollFactor.set(0, 0);
        bgGradientDynamic.alpha = 0.12;
        bgGradientDynamic.blend = ADD;
        add(bgGradientDynamic);

        gridBG = new FlxBackdrop(
            FlxGridOverlay.createGrid(36, 36, 72, 72, true, 0x08FFFFFF, 0x00000000)
        );
        gridBG.velocity.set(6, 4);
        gridBG.alpha    = 0.08;
        gridBG.scrollFactor.set(0, 0);
        add(gridBG);

        var orbColors = [
            0xFF0D9488, 0xFF7C3AED, 0xFF0EA5E9,
            0xFF059669, 0xFF8B5CF6, 0xFF06B6D4
        ];
        for (i in 0...6) {
            var orb = new FlxSprite(
                FlxG.random.float(0, FlxG.width),
                FlxG.random.float(HEADER_H, FlxG.height - FOOTER_H)
            );
            orb.makeGraphic(
                Std.int(60 + FlxG.random.float(0, 100)),
                Std.int(60 + FlxG.random.float(0, 100)),
                orbColors[i % orbColors.length]
            );
            orb.blend       = ADD;
            orb.alpha       = 0.03 + FlxG.random.float(0, 0.035);
            orb.scrollFactor.set(0, 0);
            orb.ID          = i;
            add(orb);
            bgOrbs.push(orb);
        }

        for (i in 0...12) {
            var shape = new FlxSprite(
                FlxG.random.float(0, FlxG.width),
                FlxG.random.float(HEADER_H, FlxG.height)
            );
            shape.makeGraphic(
                Std.int(8 + FlxG.random.float(0, 18)),
                Std.int(8 + FlxG.random.float(0, 18)),
                FlxColor.WHITE
            );
            shape.blend       = ADD;
            shape.alpha       = 0.03 + FlxG.random.float(0, 0.04);
            shape.scrollFactor.set(0, 0);
            shape.ID          = i;
            add(shape);
            floatingShapes.push(shape);
        }

        bgVignette = FlxGradient.createGradientFlxSprite(
            FlxG.width, FlxG.height,
            [0x00000000, 0x00000000, 0x66000000],
            1, 0, true
        );
        bgVignette.scrollFactor.set(0, 0);
        add(bgVignette);
    }

    function buildHeader():Void
    {

        headerPanel = new FlxSprite(0, -HEADER_H)
            .makeGraphic(FlxG.width, HEADER_H, 0xEE000000);
        headerPanel.scrollFactor.set(0, 0);
        add(headerPanel);

        headerGlow = new FlxSprite(0, HEADER_H - 3)
            .makeGraphic(FlxG.width, 3, currentAccentColor);
        headerGlow.blend = ADD;
        headerGlow.alpha = 0.8;
        headerGlow.scrollFactor.set(0, 0);
        add(headerGlow);

        var titleIcon = new FlxText(28, 14, 0, "🌐", 42);
        titleIcon.scrollFactor.set(0, 0);
        add(titleIcon);

        headerTitle = new FlxText(82, 12, 0, "Online Mod Yükleyici", 38);
        headerTitle.setFormat(
            Paths.font("vcr.ttf"), 38,
            FlxColor.WHITE, LEFT,
            FlxTextBorderStyle.OUTLINE, 0xFF001A1A
        );
        headerTitle.borderSize = 3;
        headerTitle.scrollFactor.set(0, 0);
        headerTitle.alpha = 0;
        add(headerTitle);

        headerSubtitle = new FlxText(82, 56, 0, "GameBanana'dan FNF modlarını keşfet ve indir!", 17);
        headerSubtitle.setFormat(
            Paths.font("vcr.ttf"), 17,
            0xFFAABBBB, LEFT
        );
        headerSubtitle.scrollFactor.set(0, 0);
        headerSubtitle.alpha = 0;
        add(headerSubtitle);

        headerBreadcrumb = new FlxText(82, 78, 0, "Ana Menü  >  Mod Merkezi  >  Online Modlar", 12);
        headerBreadcrumb.setFormat(
            Paths.font("vcr.ttf"), 12,
            0xFF607070, LEFT
        );
        headerBreadcrumb.scrollFactor.set(0, 0);
        headerBreadcrumb.alpha = 0;
        add(headerBreadcrumb);
    }

    function buildSearchAndSort():Void
    {

        var searchW = 580;
        searchBarBg = new FlxSprite();
        searchBarBg.makeGraphic(searchW, 42, 0xFF0A1628);
        searchBarBg.x = 20;
        searchBarBg.y = HEADER_H + 12;
        searchBarBg.alpha = 0.92;
        searchBarBg.scrollFactor.set(0, 0);
        add(searchBarBg);

        searchBarGlow = new FlxSprite(searchBarBg.x - 1, searchBarBg.y - 1);
        searchBarGlow.makeGraphic(searchW + 2, 44, currentAccentColor);
        searchBarGlow.alpha = 0.35;
        searchBarGlow.blend = ADD;
        searchBarGlow.scrollFactor.set(0, 0);

        insert(members.indexOf(searchBarBg), searchBarGlow);

        var searchIcon = new FlxText(
            searchBarBg.x + 10,
            searchBarBg.y + 10,
            0, "🔍", 20
        );
        searchIcon.scrollFactor.set(0, 0);
        add(searchIcon);

        searchPlaceholder = new FlxText(
            searchBarBg.x + 38,
            searchBarBg.y + 12,
            searchW - 48,
            "Mod ara... veya GameBanana URL yapıştır (Enter)"
        );
        searchPlaceholder.setFormat(
            Paths.font("vcr.ttf"), 15,
            0xFF445566, LEFT
        );
        searchPlaceholder.scrollFactor.set(0, 0);
        add(searchPlaceholder);

        searchInput = new PsychUIInputText(
            Std.int(searchBarBg.x + 36),
            Std.int(searchBarBg.y + 10),
            searchW - 46,
            "", 15
        );
        searchInput.textObj.color = FlxColor.WHITE;
        searchInput.scrollFactor.set(0, 0);

        searchInput.onChange = function(old:String, nw:String):Void {};

        searchInput.onPressEnter = function(e:flash.events.KeyboardEvent):Void {
            PsychUIInputText.focusOn = null;
            onSearchSubmit(searchInput.text);
        };

        if (initQuery != "") searchInput.text = initQuery;
        add(searchInput);

        buildSortButtons();
    }

    function buildSortButtons():Void
    {
        var btnW   = 110;
        var btnH   = 32;
        var startX = FlxG.width - (SORT_OPTIONS.length * (btnW + 6)) - 20;
        var btnY   = HEADER_H + 18;

        for (i in 0...SORT_OPTIONS.length) {
            var opt = SORT_OPTIONS[i];
            var btn = new SortButton(
                startX + i * (btnW + 6),
                btnY, btnW, btnH,
                opt.label,
                i == curSortIndex,
                currentAccentColor
            );
            btn.scrollFactor.set(0, 0);
            btn.ID = i;
            add(btn);
            sortButtons.push(btn);
        }
    }

    function buildFooter():Void
    {

        footerPanel = new FlxSprite(0, FlxG.height - FOOTER_H)
            .makeGraphic(FlxG.width, FOOTER_H, 0xDD000000);
        footerPanel.scrollFactor.set(0, 0);
        add(footerPanel);

        footerGlow = new FlxSprite(0, FlxG.height - FOOTER_H)
            .makeGraphic(FlxG.width, 2, currentAccentColor);
        footerGlow.alpha = 0.6;
        footerGlow.scrollFactor.set(0, 0);
        add(footerGlow);

        pageInfoText = new FlxText(0, FlxG.height - FOOTER_H + 8, FlxG.width, "< Page 1 >");
        pageInfoText.setFormat(
            Paths.font("vcr.ttf"), 22,
            FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK
        );
        pageInfoText.scrollFactor.set(0, 0);
        add(pageInfoText);

        resultCountText = new FlxText(20, FlxG.height - FOOTER_H + 14, 0, "");
        resultCountText.setFormat(
            Paths.font("vcr.ttf"), 14,
            0xFF607070, LEFT
        );
        resultCountText.scrollFactor.set(0, 0);
        add(resultCountText);

        controlHintsText = new FlxText(
            0, FlxG.height - FOOTER_H + 8,
            FlxG.width - 20,
            "Q ◄  Arrows: Navigate  ► E   |   Enter: Download   |   ESC: Back"
        );
        controlHintsText.setFormat(
            Paths.font("vcr.ttf"), 13,
            0xFF445566, RIGHT
        );
        controlHintsText.scrollFactor.set(0, 0);
        add(controlHintsText);
    }

    function buildLoadingOverlay():Void
    {
        loadingOverlay = new FlxSprite()
            .makeGraphic(FlxG.width, FlxG.height, 0xAA000000);
        loadingOverlay.scrollFactor.set(0, 0);
        loadingOverlay.visible = false;
        add(loadingOverlay);

        loadingSpinner = new FlxSprite();
        loadingSpinner.makeGraphic(40, 40, FlxColor.TRANSPARENT);

        for (bx in 0...40) {
            loadingSpinner.pixels.setPixel32(bx, 0,  currentAccentColor);
            loadingSpinner.pixels.setPixel32(bx, 39, currentAccentColor);
        }
        for (by in 0...40) {
            loadingSpinner.pixels.setPixel32(0,  by, currentAccentColor);
            loadingSpinner.pixels.setPixel32(39, by, currentAccentColor);
        }
        loadingSpinner.dirty = true;
        loadingSpinner.screenCenter();
        loadingSpinner.y -= 20;
        loadingSpinner.scrollFactor.set(0, 0);
        loadingSpinner.visible = false;
        add(loadingSpinner);

        loadingLabel = new FlxText(0, 0, FlxG.width, "Yükleniyor...");
        loadingLabel.setFormat(
            Paths.font("vcr.ttf"), 22,
            currentAccentColor, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK
        );
        loadingLabel.screenCenter(Y);
        loadingLabel.y += 30;
        loadingLabel.scrollFactor.set(0, 0);
        loadingLabel.visible = false;
        add(loadingLabel);
    }

    function buildErrorPanel():Void
    {
        errorPanel = new FlxSprite();
        errorPanel.makeGraphic(500, 60, 0xFF3D0000);
        errorPanel.screenCenter(X);
        errorPanel.y = HEADER_H + 8;
        errorPanel.alpha = 0;
        errorPanel.scrollFactor.set(0, 0);
        add(errorPanel);

        errorText = new FlxText(
            errorPanel.x + 10,
            errorPanel.y + 10,
            480, ""
        );
        errorText.setFormat(
            Paths.font("vcr.ttf"), 18,
            0xFFFF6666, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK
        );
        errorText.alpha = 0;
        errorText.scrollFactor.set(0, 0);
        add(errorText);
    }

    function playEntranceAnimation():Void
    {

        headerPanel.y = -HEADER_H;
        FlxTween.tween(headerPanel, {y: 0}, 0.65, {ease: FlxEase.expoOut, startDelay: 0.05});
        FlxTween.tween(headerGlow,  {y: HEADER_H - 3}, 0.65, {ease: FlxEase.expoOut, startDelay: 0.05});

        FlxTween.tween(headerTitle,      {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.3});
        FlxTween.tween(headerSubtitle,   {alpha: 0.9}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.42});
        FlxTween.tween(headerBreadcrumb, {alpha: 0.7}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.52});

        footerPanel.y = FlxG.height;
        footerGlow.y  = FlxG.height;
        FlxTween.tween(footerPanel, {y: FlxG.height - FOOTER_H}, 0.6,
            {ease: FlxEase.expoOut, startDelay: 0.1});
        FlxTween.tween(footerGlow,  {y: FlxG.height - FOOTER_H}, 0.6,
            {ease: FlxEase.expoOut, startDelay: 0.1});

        FlxG.camera.fade(FlxColor.BLACK, 0.45, true);
    }

    function onSearchSubmit(text:String):Void
    {
        if (StringTools.startsWith(text, "https://"))
        {
            handleDirectURL(text);
            return;
        }
        parseSearchText(text);
        fetchPage(true);
    }

    function parseSearchText(text:String):Void
    {
        searchQuery  = null;
        collectionID = null;

        var words:Array<String> = [];
        for (word in text.split(" ")) {
            var w = StringTools.trim(word);
            if (w == "") continue;
            if (w.startsWith("collection:"))
                collectionID = w.substr("collection:".length);
            else
                words.push(w);
        }

        var joined = words.join(" ").trim();
        searchQuery = (joined == "") ? null : joined;
    }

    function handleDirectURL(url:String):Void
    {
        var gbPrefix = "https://gamebanana.com/mods/";
        if (StringTools.startsWith(url, gbPrefix)) {
            var idStr = url.substr(gbPrefix.length);
            var qPos  = idStr.indexOf("?");
            if (qPos > -1) idStr = idStr.substr(0, qPos);
            var hPos  = idStr.indexOf("#");
            if (hPos > -1) idStr = idStr.substr(0, hPos);

            var modID = Std.parseFloat(idStr);
            if (!Math.isNaN(modID)) {
                openDownloadDialog(modID);
                searchInput.text = "";
                return;
            }
        }
        showError("Geçersiz URL!");
        searchInput.text = "";
    }

    function fetchPage(?newSearch:Bool = false):Void
    {
        if (isLoading) return;

        isLoading = true;
        setLoading(true, newSearch ? "Aranıyor..." : "Yükleniyor...");

        if (newSearch) currentPage = 1;

        var options:SearchOptions = {
            query:        searchQuery,
            sortOrder:    sortOrder,
            collectionID: collectionID,
            page:         currentPage
        };

        if (collectionID != null)
            GameBananaAPI.fetchCollection(collectionID, currentPage, onModsReceived);
        else
            GameBananaAPI.searchMods(options, onModsReceived);
    }

	function onModsReceived(mods:Array<ModEntry>, error:Null<String>):Void
	{
		isLoading = false;
		setLoading(false);

		if (_isDestroyed) return;

		if (error != null) {
			showError("Hata: " + error);
			return;
		}

		if (mods == null || mods.length == 0) {
			pageInfoText.text = "Mod bulunamadı!";
			return;
		}

		trace("[State] Mods received: " + mods.length);
		trace("[State] cardGroup null? " + (cardGroup == null));
		trace("[State] _isDestroyed: " + _isDestroyed);

		loadedMods = mods;
		pageInfoText.text    = '◄  Sayfa $currentPage  ►';
		resultCountText.text = '${mods.length} mod gösteriliyor';

		populateGrid();
	}

	function populateGrid():Void
	{
		trace("[State] populateGrid called, mods: " + loadedMods.length);

		cardGroup.clear();
		curSelected   = 0;
		hoveredCardID = -1;

		var totalW = COLS * CARD_SPACING_X - (CARD_SPACING_X - ModCard.CARD_W);
		var startX = (FlxG.width - totalW) / 2;

		trace("[State] COLS: " + COLS + " CARD_SPACING_X: " + CARD_SPACING_X);
		trace("[State] ModCard.CARD_W: " + ModCard.CARD_W);
		trace("[State] totalW: " + totalW + " startX: " + startX);
		trace("[State] gridStartY: " + gridStartY);
		trace("[State] FlxG.width: " + FlxG.width + " FlxG.height: " + FlxG.height);

		for (i in 0...loadedMods.length) {
			var col  = i % COLS;
			var row  = Math.floor(i / COLS);
			var card = new ModCard(loadedMods[i]);

			card.x  = startX + col * CARD_SPACING_X;
			card.y  = gridStartY + row * CARD_SPACING_Y;
			card.ID = i;

			trace('[State] Card $i pos: (${card.x}, ${card.y}) name: ${loadedMods[i].name}');

			card.alpha = 1;
			cardGroup.add(card);
		}

		trace("[State] cardGroup.length after populate: " + cardGroup.length);
		trace("[State] cardGroup members in FlxGroup: " + members.length);

		refreshCardSelection();
	}

    function refreshCardSelection():Void
    {
        cardGroup.forEach((card:ModCard) -> {
            card.isSelected = (card.ID == curSelected);
        });
    }

    function changeSelection(delta:Int):Void
    {
        if (loadedMods.length == 0) return;
        var newSel = curSelected + delta;
        newSel = Std.int(Math.max(0, Math.min(loadedMods.length - 1, newSel)));
        if (newSel != curSelected) {
            curSelected = newSel;
            refreshCardSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }

    function changePage(delta:Int):Void
    {
        if (isLoading) return;
        var newPage = currentPage + delta;
        if (newPage < 1) return;
        currentPage = newPage;
        fetchPage(false);
    }

    function changeSortOption(index:Int):Void
    {
        if (index == curSortIndex) return;

        sortButtons[curSortIndex].setActive(false);

        curSortIndex = index;
        sortOrder    = SORT_OPTIONS[index].value;

        sortButtons[curSortIndex].setActive(true);

        FlxG.sound.play(Paths.sound('scrollMenu'));

        fetchPage(true);
    }

    function openDownloadDialog(modID:Float):Void
    {
        if (isLoading) return;
        isLoading = true;
        setLoading(true, "İndirme bilgisi alınıyor...");

        GameBananaAPI.fetchModDownloads(modID, (info, err) -> {
            isLoading = false;
            setLoading(false);

            if (_isDestroyed) return;

            if (err != null)            { showError("İndirme hatası: " + err); return; }
            if (info == null)           { showError("Mod bilgisi alınamadı!"); return; }
            if (info.isTrashed || info.isWithheld) {
                showError("Bu mod GameBanana'dan kaldırılmış!");
                return;
            }

            openSubState(new DownloadSubstate(info));
        });
    }

    function setLoading(active:Bool, ?label:String = "Yükleniyor..."):Void
    {
        loadingOverlay.visible = active;
        loadingSpinner.visible = active;
        loadingLabel.visible   = active;
        loadingLabel.text      = label;
    }

    function showError(msg:String, ?duration:Float = 3.0):Void
    {
        errorText.text  = "⚠ " + msg;
        errorTimer      = duration;

        FlxTween.cancelTweensOf(errorPanel);
        FlxTween.cancelTweensOf(errorText);

        errorPanel.alpha = 0.9;
        errorText.alpha  = 1.0;

        trace('[OnlineModsState] ERROR: $msg');
    }

    inline function isSearchFocused():Bool
    {
        return PsychUIInputText.focusOn == searchInput;
    }

    override function update(elapsed:Float):Void
    {
        GameBananaAPI.processPendingCallbacks();

        animTimer  += elapsed;
        waveTimer  += elapsed * 2.2;
        glowTimer  += elapsed * 3.0;
        floatTimer += elapsed * 1.4;

        updateBackground(elapsed);
        updateHeader(elapsed);
        updateSearchBar();
        updateSortButtons(elapsed);
        updateErrorPanel(elapsed);

        if (isLoading) {
            spinnerAngle = (spinnerAngle + elapsed * 180) % 360;
            loadingSpinner.angle = spinnerAngle;
        }

        if (hoveredCardID >= 0 && hoveredCardID != curSelected && !isLoading) {
            curSelected = hoveredCardID;
            refreshCardSelection();
        }

        if (!isSearchFocused()) handleKeyInput();
        handleMouseInput();

        super.update(elapsed);
    }

    function updateBackground(elapsed:Float):Void
    {

        for (i in 0...bgOrbs.length) {
            var orb = bgOrbs[i];
            orb.x    += Math.sin(animTimer * 0.45 + i * 0.9) * 0.35;
            orb.y    += Math.cos(animTimer * 0.38 + i * 0.9) * 0.28;
            orb.alpha = 0.03 + Math.sin(animTimer * 1.8 + i) * 0.018;
            orb.angle += elapsed * (2.5 + i * 1.8);
        }

        for (i in 0...floatingShapes.length) {
            var s = floatingShapes[i];
            s.y    += Math.sin(floatTimer * 0.75 + i * 0.55) * 0.22;
            s.x    += Math.cos(floatTimer * 0.58 + i * 0.55) * 0.16;
            s.alpha = 0.03 + Math.sin(floatTimer * 1.9 + i) * 0.022;
            s.angle += elapsed * (5 + i * 0.9);
        }
    }

    function updateHeader(elapsed:Float):Void
    {
        if (headerGlow != null)
            headerGlow.alpha = 0.55 + Math.sin(waveTimer) * 0.22;
    }

    function updateSearchBar():Void
    {
        searchPlaceholder.visible = (searchInput.text.length == 0);

        var targetAlpha = isSearchFocused() ? 0.7 : 0.35;
        searchBarGlow.alpha = FlxMath.lerp(searchBarGlow.alpha, targetAlpha, FlxG.elapsed * 8);
    }

    function updateSortButtons(elapsed:Float):Void
    {
        for (btn in sortButtons) {
            if (FlxG.mouse.overlaps(btn) && FlxG.mouse.justPressed) {
                changeSortOption(btn.ID);
            }
        }
    }

    function updateErrorPanel(elapsed:Float):Void
    {
        if (errorTimer > 0) {
            errorTimer -= elapsed;
            if (errorTimer <= 0) {
                FlxTween.tween(errorPanel, {alpha: 0}, 0.4);
                FlxTween.tween(errorText,  {alpha: 0}, 0.4);
            }
        }
    }

    function handleKeyInput():Void
    {
        if (controls.BACK) {
            if (FlxG.sound.music != null) FlxG.sound.music.volume = 1;
            FlxG.sound.play(Paths.sound('cancelMenu'));

            FlxTween.tween(headerPanel, {y: -HEADER_H}, 0.35, {ease: FlxEase.backIn});
            FlxTween.tween(footerPanel, {y: FlxG.height}, 0.35, {ease: FlxEase.backIn});
            FlxG.camera.fade(FlxColor.BLACK, 0.4, false, () -> {
                FlxG.switchState(() -> new ModsMenuState());
            });
            return;
        }

        if (isLoading) return;

        if (FlxG.mouse.wheel > 0 || FlxG.keys.justPressed.Q) changePage(-1);
        if (FlxG.mouse.wheel < 0 || FlxG.keys.justPressed.E) changePage(1);

        if (controls.UI_LEFT_P)  changeSelection(-1);
        if (controls.UI_RIGHT_P) changeSelection(1);
        if (controls.UI_UP_P)    changeSelection(-COLS);
        if (controls.UI_DOWN_P)  changeSelection(COLS);

        if (controls.ACCEPT && loadedMods.length > 0)
            openDownloadDialog(loadedMods[curSelected].id);

        if (FlxG.keys.justPressed.TAB)
            changeSortOption((curSortIndex + 1) % SORT_OPTIONS.length);
    }

    function handleMouseInput():Void
    {
        if (!FlxG.mouse.justPressed) return;

        if (FlxG.mouse.overlaps(searchBarBg)) {
            PsychUIInputText.focusOn = searchInput;
            return;
        }

        if (isLoading) return;

        cardGroup.forEach((card:ModCard) -> {
            if (!FlxG.mouse.overlaps(card.cardBg)) return;

            curSelected = card.ID;
            refreshCardSelection();

            if (FlxG.mouse.overlaps(card.downloadBg))
                openDownloadDialog(loadedMods[curSelected].id);
            else if (FlxG.mouse.overlaps(card.linkBg))
                FlxG.openURL(loadedMods[curSelected].url);
        });
    }
}

class SortButton extends FlxSpriteGroup
{
    var bg:FlxSprite;
    var label:FlxText;
    var glowLine:FlxSprite;
    var isActive:Bool;
    var accentColor:FlxColor;

    public function new(
        x:Float, y:Float,
        w:Int, h:Int,
        text:String,
        active:Bool,
        accent:FlxColor
    ) {
        super(x, y);
        accentColor = accent;
        isActive    = active;

        bg = new FlxSprite().makeGraphic(w, h, 0xFF0A1628);
        bg.alpha = active ? 0.95 : 0.6;
        add(bg);

        glowLine = new FlxSprite(0, h - 2).makeGraphic(w, 2, accent);
        glowLine.alpha = active ? 0.9 : 0.0;
        add(glowLine);

        label = new FlxText(0, 0, w, text);
        label.setFormat(
            Paths.font("vcr.ttf"), 13,
            active ? FlxColor.WHITE : 0xFF667788,
            CENTER
        );
        label.y = (h - label.height) / 2;
        add(label);
    }

    public function setActive(active:Bool):Void
    {
        isActive    = active;
        bg.alpha    = active ? 0.95 : 0.6;
        glowLine.alpha = active ? 0.9 : 0.0;
        label.color = active ? FlxColor.WHITE : 0xFF667788;
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!isActive) {
            if (FlxG.mouse.overlaps(bg)) {
                bg.alpha    = FlxMath.lerp(bg.alpha, 0.85, elapsed * 10);
                label.color = FlxColor.fromRGB(
                    Std.int(FlxMath.lerp(0x66, 0xFF, elapsed * 10)),
                    Std.int(FlxMath.lerp(0x77, 0xFF, elapsed * 10)),
                    Std.int(FlxMath.lerp(0x88, 0xFF, elapsed * 10))
                );
                glowLine.alpha = FlxMath.lerp(glowLine.alpha, 0.4, elapsed * 10);
            } else {
                bg.alpha       = FlxMath.lerp(bg.alpha, 0.6, elapsed * 10);
                glowLine.alpha = FlxMath.lerp(glowLine.alpha, 0.0, elapsed * 10);
            }
        }
    }
}