package states.ultramenus.v1;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import backend.ThemeManager;
import backend.WorkspaceSwitcher;
import backend.MusicPlayer;
import backend.widgets.WidgetBase;
import backend.widgets.WidgetManager;
import backend.widgets.WidgetShop;
class MainMenuV1 extends MusicBeatState
{
    public static var psychEngineVersion:String = '1.0.4';
    public static var curRow:Int = 0;
    public static var curCol:Int = 0;
    var allowMouse:Bool = true;
    var menuItems:FlxTypedGroup<FlxSprite>;
    var menuGrid:Array<Array<String>> = [
        ['story_mode', 'freeplay'],
        #if MODS_ALLOWED
        ['mods', 'credits'],
        #else
        ['credits', 'credits'], 
        #end
        #if ACHIEVEMENTS_ALLOWED
        ['achievements', 'options']
        #else
        ['options', 'options'] 
        #end
    ];
    var bg:FlxSprite;
    var magenta:FlxSprite;
    var camFollow:FlxObject;
    var widgetManager:WidgetManager;
    var widgetContainer:FlxSpriteGroup;
    var widgetShop:WidgetShop;
    var musicPlayer:MusicPlayer;
    var selectedSomethin:Bool = false;
    var timeNotMoving:Float = 0;
    var breathe:Float = 0;
    var gridPositions:Map<String, {x:Float, y:Float, scale:Float}> = [];
    var leftX:Float = 0;
    var rightX:Float = 0;
    var row1Y:Float = 0;
    var row2Y:Float = 0;
    var row3Y:Float = 0;
    static var showOutdatedWarning:Bool = true;
    override function create()
    {
        super.create();
        #if MODS_ALLOWED
        Mods.pushGlobalMods();
        #end
        Mods.loadTopMod();
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("In the Menus", null);
        #end
        persistentUpdate = persistentDraw = true;
        WorkspaceSwitcher.init();
        calculateGridPositions();
        bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, 0.12);
        bg.setGraphicSize(Std.int(bg.width * 1.2));
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);
        magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
        magenta.antialiasing = ClientPrefs.data.antialiasing;
        magenta.scrollFactor.set(0, 0.12);
        magenta.setGraphicSize(Std.int(magenta.width * 1.2));
        magenta.updateHitbox();
        magenta.screenCenter();
        magenta.visible = false;
        magenta.color = 0xFFfd719b;
        add(magenta);
        var topVignette = new FlxSprite().makeGraphic(FlxG.width, 100, 0xFF000000);
        topVignette.alpha = 0.5;
        topVignette.scrollFactor.set();
        add(topVignette);
        var bottomVignette = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 70, 0xFF000000);
        bottomVignette.alpha = 0.5;
        bottomVignette.scrollFactor.set();
        add(bottomVignette);
        var titleText = new FlxText(0, 20, FlxG.width, "FRIDAY NIGHT FUNKIN'", 38);
        titleText.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        titleText.borderSize = 3;
        titleText.scrollFactor.set();
        add(titleText);
        var subtitleText = new FlxText(0, 62, FlxG.width, "PSYCH ENGINE ULTRA", 16);
        subtitleText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF8B5CF6, CENTER);
        subtitleText.scrollFactor.set();
        add(subtitleText);
        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);
        var createdOptions:Array<String> = [];
        for (row in 0...menuGrid.length)
        {
            for (col in 0...menuGrid[row].length)
            {
                var option = menuGrid[row][col];
                if (createdOptions.contains(option))
                    continue;
                createdOptions.push(option);
                var pos = gridPositions.get(option);
                if (pos == null) continue;
                var item = createMenuItem(option, pos.x, pos.y, pos.scale);
                if (item != null)
                {
                    menuItems.add(item);
                }
            }
        }
        var psychVer = new FlxText(20, FlxG.height - 48, 0, "Psych Engine v" + psychEngineVersion, 16);
        psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        psychVer.scrollFactor.set();
        add(psychVer);
        var fnfVer = new FlxText(20, FlxG.height - 26, 0, "FNF v" + Application.current.meta.get('version'), 14);
        fnfVer.setFormat(Paths.font("vcr.ttf"), 14, 0xFF888888, LEFT);
        fnfVer.scrollFactor.set();
        add(fnfVer);
        var controlHint = new FlxText(0, FlxG.height - 35, FlxG.width - 20, "← → ↑ ↓ NAVIGATE   ENTER SELECT   SHIFT WORKSPACE", 13);
        controlHint.setFormat(Paths.font("vcr.ttf"), 13, 0xFF555555, RIGHT);
        controlHint.scrollFactor.set();
        add(controlHint);
        camFollow = new FlxObject(FlxG.width / 2, FlxG.height / 2, 1, 1);
        add(camFollow);
        FlxG.camera.follow(camFollow, null, 0.08);
        var widgetCam = new FlxCamera();
        widgetCam.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(widgetCam, false);
        widgetContainer = new FlxSpriteGroup();
        widgetContainer.cameras = [widgetCam];
        add(widgetContainer);
        widgetManager = new WidgetManager(widgetContainer);
        widgetManager.initializeWidgets();
        musicPlayer = new MusicPlayer();
        add(musicPlayer);
        widgetShop = new WidgetShop();
        add(widgetShop);
        changeSelection();
        playEntranceAnimations();
        #if ACHIEVEMENTS_ALLOWED
        var leDate = Date.now();
        if (leDate.getDay() == 5 && leDate.getHours() >= 18)
            Achievements.unlock('friday_night_play');
        #if MODS_ALLOWED
        Achievements.reloadList();
        #end
        #end
        #if CHECK_FOR_UPDATES
        if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion)
        {
            persistentUpdate = false;
            showOutdatedWarning = false;
            openSubState(new substates.OutdatedSubState());
        }
        #end
    }
    function calculateGridPositions():Void
    {
        leftX = FlxG.width * 0.28;
        rightX = FlxG.width * 0.72;
        row1Y = 160;  
        row2Y = 320;  
        row3Y = 480;  
        var mainScale:Float = 0.75;
        var smallScale:Float = 0.55;
        gridPositions = [
            'story_mode' => {x: leftX, y: row1Y, scale: mainScale},
            'freeplay' => {x: rightX, y: row1Y, scale: mainScale},
            'mods' => {x: leftX, y: row2Y, scale: mainScale},
            'credits' => {x: rightX, y: row2Y, scale: mainScale},
            'achievements' => {x: leftX, y: row3Y, scale: smallScale},
            'options' => {x: rightX, y: row3Y, scale: smallScale}
        ];
    }
    function createMenuItem(option:String, x:Float, y:Float, scale:Float):FlxSprite
    {
        var item = new FlxSprite();
        try {
            item.frames = Paths.getSparrowAtlas('mainmenu/menu_' + option);
            item.animation.addByPrefix('idle', option + ' idle', 24, true);
            item.animation.addByPrefix('selected', option + ' selected', 24, true);
            item.animation.play('idle');
        } catch(e:Dynamic) {
            trace('[MainMenuV1] Could not load sprite for: ' + option);
            return null;
        }
        item.antialiasing = ClientPrefs.data.antialiasing;
        item.scrollFactor.set();
        item.scale.set(scale, scale);
        item.updateHitbox();
        item.x = x - (item.width / 2);
        item.y = y - (item.height / 2);
        item.ID = getOptionIndex(option);
        return item;
    }
    function getOptionIndex(option:String):Int
    {
        var allOptions = ['story_mode', 'freeplay', 'mods', 'credits', 'achievements', 'options'];
        return allOptions.indexOf(option);
    }
    function getOptionFromIndex(index:Int):String
    {
        var allOptions = ['story_mode', 'freeplay', 'mods', 'credits', 'achievements', 'options'];
        if (index >= 0 && index < allOptions.length)
            return allOptions[index];
        return 'story_mode';
    }
    function getCurrentOption():String
    {
        if (curRow >= 0 && curRow < menuGrid.length)
        {
            var row = menuGrid[curRow];
            if (curCol >= 0 && curCol < row.length)
                return row[curCol];
        }
        return 'story_mode';
    }
    function getItemByOption(option:String):FlxSprite
    {
        var index = getOptionIndex(option);
        for (item in menuItems)
        {
            if (item != null && item.ID == index)
                return item;
        }
        return null;
    }
    function playEntranceAnimations():Void
    {
        for (item in menuItems)
        {
            if (item == null) continue;
            var targetY = item.y;
            var targetAlpha = 1.0;
            item.y = targetY + 100;
            item.alpha = 0;
            var delay = 0.1 + (item.ID * 0.08);
            FlxTween.tween(item, {y: targetY, alpha: targetAlpha}, 0.5, {
                ease: FlxEase.backOut,
                startDelay: delay
            });
        }
    }
    override function update(elapsed:Float)
    {
        breathe += elapsed;
        if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
            FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);
        if (WidgetShop.isOpen)
        {
            if (FlxG.keys.justPressed.ESCAPE)
                widgetShop.close();
            super.update(elapsed);
            return;
        }
        if (FlxG.keys.justPressed.P && !WorkspaceSwitcher.isOpen && !selectedSomethin)
        {
            widgetShop.open();
            super.update(elapsed);
            return;
        }
        if (!selectedSomethin)
            WorkspaceSwitcher.handleInput(elapsed);
        if (WorkspaceSwitcher.isOpen)
        {
            super.update(elapsed);
            return;
        }
        if (!selectedSomethin)
        {
            var moved = false;
            if (controls.UI_LEFT_P)
            {
                curCol = (curCol - 1 + 2) % 2;
                moved = true;
            }
            if (controls.UI_RIGHT_P)
            {
                curCol = (curCol + 1) % 2;
                moved = true;
            }
            if (controls.UI_UP_P)
            {
                curRow = (curRow - 1 + menuGrid.length) % menuGrid.length;
                moved = true;
            }
            if (controls.UI_DOWN_P)
            {
                curRow = (curRow + 1) % menuGrid.length;
                moved = true;
            }
            if (moved)
                changeSelection();
            if (allowMouse && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed))
            {
                FlxG.mouse.visible = true;
                timeNotMoving = 0;
                for (item in menuItems)
                {
                    if (item != null && FlxG.mouse.overlaps(item))
                    {
                        var option = getOptionFromIndex(item.ID);
                        var newPos = findGridPosition(option);
                        if (newPos != null && (newPos.row != curRow || newPos.col != curCol))
                        {
                            curRow = newPos.row;
                            curCol = newPos.col;
                            changeSelection();
                        }
                        if (FlxG.mouse.justPressed)
                            selectItem();
                        break;
                    }
                }
            }
            else
            {
                timeNotMoving += elapsed;
                if (timeNotMoving > 2)
                    FlxG.mouse.visible = false;
            }
            if (controls.BACK)
            {
                selectedSomethin = true;
                FlxG.mouse.visible = false;
                FlxG.sound.play(Paths.sound('cancelMenu'));
                ThemeManager.switchToTitle();
            }
            if (controls.ACCEPT)
                selectItem();
            #if desktop
            if (controls.justPressed('debug_1'))
            {
                selectedSomethin = true;
                FlxG.mouse.visible = false;
                MusicBeatState.switchState(new MasterEditorMenu());
            }
            #end
        }
        updateItemAnimations(elapsed);
        super.update(elapsed);
    }
    function findGridPosition(option:String):{row:Int, col:Int}
    {
        for (row in 0...menuGrid.length)
        {
            for (col in 0...menuGrid[row].length)
            {
                if (menuGrid[row][col] == option)
                    return {row: row, col: col};
            }
        }
        return null;
    }
    function updateItemAnimations(elapsed:Float):Void
    {
        var currentOption = getCurrentOption();
        for (item in menuItems)
        {
            if (item == null) continue;
            var option = getOptionFromIndex(item.ID);
            var pos = gridPositions.get(option);
            if (pos == null) continue;
            var isSelected = (option == currentOption);
            var targetScale = isSelected ? pos.scale * 1.15 : pos.scale * 0.9;
            var targetAlpha = isSelected ? 1.0 : 0.5;
            item.scale.x = FlxMath.lerp(item.scale.x, targetScale, elapsed * 12);
            item.scale.y = FlxMath.lerp(item.scale.y, targetScale, elapsed * 12);
            item.alpha = FlxMath.lerp(item.alpha, targetAlpha, elapsed * 10);
            item.updateHitbox();
            var targetX = pos.x - (item.width / 2);
            var targetY = pos.y - (item.height / 2);
            if (isSelected && !selectedSomethin)
            {
                var breatheOffset = Math.sin(breathe * 3) * 5;
                targetY += breatheOffset - 10; 
            }
            item.x = FlxMath.lerp(item.x, targetX, elapsed * 10);
            item.y = FlxMath.lerp(item.y, targetY, elapsed * 10);
        }
        var selectedItem = getItemByOption(currentOption);
        if (selectedItem != null)
        {
            var targetCamY = FlxG.height / 2 + (curRow - 1) * 30;
            camFollow.y = FlxMath.lerp(camFollow.y, targetCamY, elapsed * 5);
        }
    }
    function changeSelection()
    {
        for (item in menuItems)
        {
            if (item != null)
                item.animation.play('idle');
        }
        FlxG.sound.play(Paths.sound('scrollMenu'));
        var currentOption = getCurrentOption();
        var selectedItem = getItemByOption(currentOption);
        if (selectedItem != null)
            selectedItem.animation.play('selected');
    }
    function selectItem()
    {
        var currentOption = getCurrentOption();
        var selectedItem = getItemByOption(currentOption);
        if (selectedItem == null) return;
        FlxG.sound.play(Paths.sound('confirmMenu'));
        selectedSomethin = true;
        FlxG.mouse.visible = false;
        if (ClientPrefs.data.flashing)
            FlxFlicker.flicker(magenta, 1.1, 0.15, false);
        FlxFlicker.flicker(selectedItem, 1, 0.06, false, false, function(flick:FlxFlicker)
        {
            goToState(currentOption);
        });
        for (item in menuItems)
        {
            if (item != selectedItem && item != null)
            {
                FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
            }
        }
    }
    function goToState(option:String):Void
    {
        switch (option)
        {
            case 'story_mode':
                MusicBeatState.switchState(new StoryMenuState());
            case 'freeplay':
                MusicBeatState.switchState(new FreeplayState());
            #if MODS_ALLOWED
            case 'mods':
                MusicBeatState.switchState(new ModsMenuState());
            #end
            #if ACHIEVEMENTS_ALLOWED
            case 'achievements':
                MusicBeatState.switchState(new AchievementsMenuState());
            #end
            case 'credits':
                MusicBeatState.switchState(new CreditsState());
            case 'options':
                OptionsState.onPlayState = false;
                MusicBeatState.switchState(new OptionsState());
                if (PlayState.SONG != null)
                {
                    PlayState.SONG.arrowSkin = null;
                    PlayState.SONG.splashSkin = null;
                    PlayState.stageUI = 'normal';
                }
        }
    }
    override function destroy()
    {
        if (WorkspaceSwitcher.isOpen)
            WorkspaceSwitcher.forceClose();
        if (WidgetShop.isOpen)
            widgetShop.close();
        if (widgetManager != null)
            widgetManager.destroy();
        WidgetBase.resetDragState();
        super.destroy();
    }
}