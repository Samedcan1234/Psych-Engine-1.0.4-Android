package states.multiplayer.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.multiplayer.data.ModTypes;

class DownloadSubstate extends MusicBeatSubstate
{
    var downloadInfo:ModDownloadInfo;
    var fileRows:FlxTypedGroup<FlxSpriteGroup>;
    var curSelected:Int = 0;
    var titleText:FlxText;

    public function new(info:ModDownloadInfo)
    {
        super();
        downloadInfo = info;
    }

    override function create():Void
    {
        super.create();

        var bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
        add(bg);

        titleText = new FlxText(0, 25, FlxG.width, 'Download: ${downloadInfo.name}');
        titleText.setFormat("VCR OSD Mono", 26, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(titleText);

        var tip = new FlxText(0, FlxG.height - 35, FlxG.width,
            "↑↓: Select   ENTER: Download   ESC: Cancel");
        tip.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        tip.alpha = 0.7;
        add(tip);

        fileRows = new FlxTypedGroup<FlxSpriteGroup>();
        add(fileRows);

        buildFileRows();
        updateSelection();
    }

    function buildFileRows():Void
    {
        var rowH  = 75;
        var rowW  = 700;
        var startY = 90;

        for (i in 0...downloadInfo.files.length) {
            var file = downloadInfo.files[i];
            var yPos = startY + i * (rowH + 5);

            var group = new FlxSpriteGroup();

            var rowBg = new FlxSprite();
            rowBg.makeGraphic(rowW, rowH, 0xFF1E1E2E);
            rowBg.x = (FlxG.width - rowW) / 2;
            rowBg.y = yPos;
            group.add(rowBg);

            var nameLabel = new FlxText(rowBg.x + 12, yPos + 8, rowW - 24, file.filename);
            nameLabel.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT,
                FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            group.add(nameLabel);

            var sizeStr = "Size: Unknown";
            if (file.fileSize != null) {
                var mb = file.fileSize / 1024 / 1024;
                sizeStr = 'Size: ${Math.round(mb * 10) / 10} MB';
            }
            var sizeLabel = new FlxText(rowBg.x + 12, yPos + 32, rowW - 24, sizeStr);
            sizeLabel.setFormat("VCR OSD Mono", 14, 0xFFAAAAAA, LEFT);
            group.add(sizeLabel);

            if (file.description != null && file.description != "") {
                var descLabel = new FlxText(rowBg.x + 12, yPos + 52, rowW - 24, file.description);
                descLabel.setFormat("VCR OSD Mono", 12, 0xFF888888, LEFT);
                group.add(descLabel);
            }

            group.ID = i;
            fileRows.add(group);
        }
    }

    function updateSelection():Void
    {
        fileRows.forEach((row:FlxSpriteGroup) -> {
            var bg = cast(row.members[0], FlxSprite);
            bg.color = (row.ID == curSelected) ? 0xFF0D5577 : 0xFF1E1E2E;
        });
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (controls.UI_UP_P) {
            curSelected = (curSelected - 1 + downloadInfo.files.length) % downloadInfo.files.length;
            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.UI_DOWN_P) {
            curSelected = (curSelected + 1) % downloadInfo.files.length;
            updateSelection();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.ACCEPT) {
            startDownload();
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
        }

        if (FlxG.mouse.justPressed) {
            fileRows.forEach((row:FlxSpriteGroup) -> {
                var bg = cast(row.members[0], FlxSprite);
                if (FlxG.mouse.overlaps(bg)) {
                    if (curSelected == row.ID) {
                        startDownload(); 

                    } else {
                        curSelected = row.ID;
                        updateSelection();
                    }
                }
            });
        }
    }

    function startDownload():Void
    {
        var file = downloadInfo.files[curSelected];
        trace('Downloading: ${file.filename} from ${file.downloadURL}');

        FlxG.sound.play(Paths.sound('confirmMenu'));
        close();
    }
}