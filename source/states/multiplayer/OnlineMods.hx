package states.multiplayer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.multiplayer.data.ModTypes;

class OnlineMods extends MusicBeatSubstate
{
    var downloadInfo:ModDownloadInfo;
    var fileItems:FlxTypedGroup<FlxSpriteGroup>;
    var curSelected:Int = 0;
    var bg:FlxSprite;
    var titleText:FlxText;

    public function new(info:ModDownloadInfo)
    {
        super();
        downloadInfo = info;
    }

    override function create():Void
    {
        super.create();

        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
        add(bg);

        titleText = new FlxText(0, 30, FlxG.width,
            'Download: ${downloadInfo.name}');
        titleText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(titleText);

        var tip = new FlxText(0, FlxG.height - 40, FlxG.width,
            "ENTER: Download  |  ESC: Cancel  |  UP/DOWN: Navigate");
        tip.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        tip.alpha = 0.7;
        add(tip);

        buildFileList();
    }

    function buildFileList():Void
    {
        fileItems = new FlxTypedGroup<FlxSpriteGroup>();
        add(fileItems);

        var startY:Float = 100;

        for (i in 0...downloadInfo.files.length) {
            var file = downloadInfo.files[i];
            var row  = buildFileRow(file, i, startY + i * 80);
            fileItems.add(row);
        }

        updateSelection();
    }

    function buildFileRow(file:ModDownloadFile, index:Int, yPos:Float):FlxSpriteGroup
    {
        var group = new FlxSpriteGroup(0, yPos);

        var rowBg = new FlxSprite();
        rowBg.makeGraphic(700, 70, 0xFF1E1E2E);
        rowBg.screenCenter(X);
        rowBg.alpha = 0.9;
        group.add(rowBg);

        var fileName = new FlxText(rowBg.x + 10, yPos + 8, 500, file.filename);
        fileName.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT);

        var sizeText = "";
        if (file.fileSize != null) {
            var sizeMB = file.fileSize / (1024 * 1024);
            sizeText = '${FlxMath.roundDecimal(sizeMB, 1)} MB';
        }

        var fileSizeLabel = new FlxText(rowBg.x + 10, yPos + 30, 500,
            sizeText != "" ? sizeText : "Size unknown");
        fileSizeLabel.setFormat("VCR OSD Mono", 13, FlxColor.GRAY, LEFT);

        group.add(fileName);
        group.add(fileSizeLabel);

        return group;
    }

    function updateSelection():Void
    {
        for (i in 0...fileItems.length) {
            var item = fileItems.members[i];
            if (item == null) continue;

            var rowBg = cast(item.members[0], FlxSprite);
            rowBg.color = (i == curSelected) ? 0xFF0D7377 : 0xFF1E1E2E;
        }
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
            startDownload(downloadInfo.files[curSelected]);
        }

        if (controls.BACK) {
            close();
        }
    }

    function startDownload(file:ModDownloadFile):Void
    {
        OnlineMods.downloadMod(file.downloadURL, false);
        close();
    }
}