package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import backend.ClientPrefs;

class LanguageSelectState extends MusicBeatState {

    static final LANGUAGES = [
        { id: "english", name: "English",  flag: "english"  },
        { id: "turkish", name: "Türkçe",   flag: "turkish"  },
    ];

    var selectedIndex:Int = 0;
    var flagSprites:Array<FlxSprite> = [];
    var nameTxts:Array<FlxText>      = [];

    override function create() {
        super.create();

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF08080f);
        add(bg);

        var accent = new FlxSprite(0, FlxG.height / 2 - 60).makeGraphic(4, 120, 0xFFc084fc);
        add(accent);

        var title = new FlxText(0, 80, FlxG.width, "SELECT YOUR LANGUAGE", 32);
        title.font = Paths.font("vcr.ttf");
        title.alignment = CENTER;
        title.color = 0xFFc084fc;
        add(title);

        var sub = new FlxText(0, 125, FlxG.width, "Dilinizi seçin", 15);
        sub.font = Paths.font("vcr.ttf");
        sub.alignment = CENTER;
        sub.color = 0xFF5a5a7a;
        add(sub);

        var upTxt = new FlxText(0, FlxG.height / 2 - 130, FlxG.width, "▲", 28);
        upTxt.font = Paths.font("vcr.ttf");
        upTxt.alignment = CENTER;
        upTxt.color = 0xFFc084fc;
        add(upTxt);

        var downTxt = new FlxText(0, FlxG.height / 2 + 90, FlxG.width, "▼", 28);
        downTxt.font = Paths.font("vcr.ttf");
        downTxt.alignment = CENTER;
        downTxt.color = 0xFFc084fc;
        add(downTxt);

        for (i in 0...LANGUAGES.length) {
            var flag = new FlxSprite(FlxG.width / 2 - 75, FlxG.height / 2 - 55);
            try {
                flag.loadGraphic(Paths.image('ultra/languages/' + LANGUAGES[i].flag));
                flag.setGraphicSize(150, 100);
                flag.updateHitbox();
            } catch(e) {

                flag.makeGraphic(150, 100, 0xFF1e1e3a);
                var ph = new FlxText(FlxG.width / 2 - 75, FlxG.height / 2 - 20, 150, LANGUAGES[i].name.substr(0, 2), 28);
                ph.font = Paths.font("vcr.ttf");
                ph.alignment = CENTER;
                ph.color = 0xFFc084fc;
                ph.visible = (i == 0);
                flagSprites.push(flag); 

                add(flag); add(ph);
                continue;
            }
            flag.visible = (i == 0);
            flagSprites.push(flag);
            add(flag);

            var nameTxt = new FlxText(0, FlxG.height / 2 + 55, FlxG.width, LANGUAGES[i].name, 22);
            nameTxt.font = Paths.font("vcr.ttf");
            nameTxt.alignment = CENTER;
            nameTxt.color = 0xFFffffff;
            nameTxt.visible = (i == 0);
            nameTxts.push(nameTxt);
            add(nameTxt);
        }

        var confirmBg = new FlxSprite(FlxG.width / 2 - 150, FlxG.height / 2 + 150).makeGraphic(300, 44, 0xFFc084fc);
        add(confirmBg);
        var confirmTxt = new FlxText(FlxG.width / 2 - 150, FlxG.height / 2 + 162, 300, "ONAYLA / CONFIRM", 14);
        confirmTxt.font = Paths.font("vcr.ttf");
        confirmTxt.alignment = CENTER;
        confirmTxt.color = 0xFFffffff;
        add(confirmTxt);

        for (i in 0...LANGUAGES.length)
            if (LANGUAGES[i].id == ClientPrefs.data.language) { selectedIndex = i; break; }

        updateDisplay();
    }

    function updateDisplay() {
        for (i in 0...flagSprites.length) flagSprites[i].visible = (i == selectedIndex);
        for (i in 0...nameTxts.length)   nameTxts[i].visible   = (i == selectedIndex);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.UI_UP_P || controls.UI_DOWN_P) {
            var dir = controls.UI_UP_P ? -1 : 1;
            selectedIndex = (selectedIndex + dir + LANGUAGES.length) % LANGUAGES.length;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            updateDisplay();
        }

        if (controls.ACCEPT) confirm();

        if (FlxG.mouse.justPressed) {
            var my = FlxG.mouse.y;
            if (my < FlxG.height / 2 - 60) {
                selectedIndex = (selectedIndex - 1 + LANGUAGES.length) % LANGUAGES.length;
                updateDisplay();
            } else if (my > FlxG.height / 2 + 90 && my < FlxG.height / 2 + 148) {
                selectedIndex = (selectedIndex + 1) % LANGUAGES.length;
                updateDisplay();
            } else if (my >= FlxG.height / 2 + 148) {
                confirm();
            }
        }
    }

    function confirm() {
        ClientPrefs.data.language         = LANGUAGES[selectedIndex].id;
        ClientPrefs.data.languageSelected = true;
        ClientPrefs.saveSettings();
        FlxG.sound.play(Paths.sound('confirmMenu'));
        FlxG.switchState(new AuthState());
    }
}