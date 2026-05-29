package states;

import backend.AuthManager;
import backend.SupabaseClient;
import flixel.FlxG;
import flixel.FlxSprite;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.ProfileBox;
import objects.AlertMgr;
import states.TitleState;

class MultiplayerState extends MusicBeatState {

    static final ITEMS:Array<String> = [
        "Liderlik Tablosu",
        "Yerel Oynama",
    ];

    static final DESCS:Array<String> = [
        "Tüm Zamanların En İyi Oyuncuları!",
        "Aynı Cihazda Arkadaşınla Oyna",
    ];

    var items:FlxTypedSpriteGroup<FlxText>;
    var itemDesc:FlxText;
    var descBox:FlxSprite;
    var selectLine:FlxSprite;
    var profileBox:ProfileBox;

    static var curSelected:Int = 0;
    var disableInput:Bool = false;

    var lbSubstate:LeaderboardSubstate;

    override function create() {
        super.create();

        if (FlxG.sound.music == null || !FlxG.sound.music.playing)
            states.TitleState.playFreakyMusic();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Multiplayer Menüsü", "Multiplayer");
        #end

        var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = 0xff1a1a2e;
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

        var title = new FlxText(0, 30, 0, "MULTIPLAYER");
        title.setFormat("VCR OSD Mono", 48, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        title.screenCenter(X);
        title.alpha = 0;
        add(title);
        FlxTween.tween(title, {alpha: 1, y: 40}, 0.5, {ease: FlxEase.quartOut});

        var subtitle = new FlxText(0, 88, 0, "v ULTRA");
        subtitle.setFormat("VCR OSD Mono", 18, 0xFFC084FC, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        subtitle.screenCenter(X);
        subtitle.alpha = 0;
        add(subtitle);
        FlxTween.tween(subtitle, {alpha: 0.7}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.1});

        selectLine = new FlxSprite();
        selectLine.makeGraphic(1, 1, FlxColor.fromRGB(192, 132, 252));
        selectLine.alpha = 0.15;
        add(selectLine);

        descBox = new FlxSprite(0, FlxG.height - 110);
        descBox.makeGraphic(1, 1, FlxColor.BLACK);
        descBox.alpha = 0.45;
        add(descBox);

        items = new FlxTypedSpriteGroup<FlxText>();
        for (i in 0...ITEMS.length) {
            var text = new FlxText(0, 0, 0, ITEMS[i]);
            text.setFormat("VCR OSD Mono", 38, FlxColor.WHITE, CENTER,
                FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            text.ID = i;
            text.alpha = 0.75;
            items.add(text);

            FlxTween.tween(text, {alpha: text.alpha}, 0.4,
                {startDelay: 0.05 * i, ease: FlxEase.quartOut});
        }
        repositionItems();
        items.screenCenter(Y);
        add(items);

        itemDesc = new FlxText(0, FlxG.height - 95, 0, "");
        itemDesc.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        itemDesc.screenCenter(X);
        add(itemDesc);

        profileBox = new ProfileBox();
        profileBox.setPosition(FlxG.width - profileBox.width - 20, 20);
        add(profileBox);

        changeSelection(0);

        FlxG.mouse.visible = true;

        #if mobile
        mobileManager.addMobilePad('NONE', 'B');
        #end
    }

    function repositionItems() {
        var totalH = 0.0;
        for (item in items) totalH += item.height + 12;
        var startY = (FlxG.height - totalH) / 2;
        var y = startY;
        for (item in items) {
            item.y = y;
            item.screenCenter(X);
            y += item.height + 12;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (disableInput) return;

        for (item in items) {
            final isSel = item.ID == curSelected;
            item.text = isSel ? "> " + ITEMS[item.ID] + " <" : ITEMS[item.ID];
            item.alpha = isSel ? 1.0 : 0.65;
            item.screenCenter(X);
        }

        if (FlxG.mouse.justMoved) {
            for (item in items) {
                if (FlxG.mouse.overlaps(item)) {
                    if (item.ID != curSelected)
                        changeSelection(item.ID - curSelected);
                }
            }
        }

        if (controls.UI_UP_P)   changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        if (controls.ACCEPT || (FlxG.mouse.justPressed && mouseOverItems())) {
            selectItem();
        }

        if (controls.BACK) {
            disableInput = true;
            FlxG.mouse.visible = false;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            FlxG.switchState(() -> new MainMenuState());
        }
    }

    function mouseOverItems():Bool {
        for (item in items)
            if (FlxG.mouse.overlaps(item)) return true;
        return false;
    }

    function selectItem() {
        FlxG.sound.play(Paths.sound('confirmMenu'));
        switch (curSelected) {
            case 0: 

                disableInput = true;
                openSubState(new LeaderboardSubstate(function() {
                    disableInput = false;
                }));

            case 1: 

			AlertMsg.show(
				Language.getPhrase('language_changed_title', 'Daha gelmedi!'),
				Language.getPhrase('language_changed_msg', 'yok.'),
				4,
				AlertMsg.COLOR_ERROR
			);
        }
    }

    function changeSelection(diff:Int) {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        curSelected = (curSelected + diff + ITEMS.length) % ITEMS.length;

        itemDesc.text = DESCS[curSelected];
        itemDesc.screenCenter(X);

        descBox.scale.set(FlxG.width - 400,
            (itemDesc.text.split("\n").length + 2) * itemDesc.size);
        descBox.y = itemDesc.y + descBox.scale.y * 0.5 - itemDesc.size;
        descBox.screenCenter(X);
        descBox.updateHitbox();

        selectLine.scale.set(FlxG.width, items.members[curSelected].height + 16);
        selectLine.y = items.members[curSelected].y - 8;
        selectLine.screenCenter(X);
        selectLine.updateHitbox();
    }

    override function destroy() {
        FlxG.mouse.visible = false;
        super.destroy();
    }
}

