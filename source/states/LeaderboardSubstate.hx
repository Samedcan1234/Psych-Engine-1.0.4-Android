package states;

import backend.SupabaseClient;
import backend.AuthManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxStringUtil;
import sys.thread.Thread;

class LeaderboardSubstate extends MusicBeatSubstate {

    var onClose:Void -> Void;

    var bg:FlxSprite;
    var panel:FlxSprite;
    var title:FlxText;
    var loadingText:FlxText;
    var entriesGroup:FlxSpriteGroup;
    var scrollOffset:Float = 0;
    var maxScroll:Float = 0;
    var entries:Array<Dynamic> = [];

    static final COL_BG      = 0xFF08080F;
    static final COL_PANEL   = 0xFF0D0D1A;
    static final COL_BORDER  = 0xFF1E1E3A;
    static final COL_PURPLE  = 0xFFC084FC;
    static final COL_MUTED   = 0xFF8888AA;
    static final COL_GOLD    = 0xFFFBBF24;
    static final COL_SILVER  = 0xFF94A3B8;
    static final COL_BRONZE  = 0xFFCD7C3A;
    static final COL_GREEN   = 0xFF34D399;
    static final COL_RED     = 0xFFF87171;

    static final PANEL_W = 820;
    static final PANEL_H = 520;
    static final ROW_H   = 44;

    public function new(?onClose:Void -> Void) {
        super();
        this.onClose = onClose ?? function() {};
    }

    override function create() {
        super.create();

        bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
        add(bg);

        panel = new FlxSprite((FlxG.width - PANEL_W) / 2, (FlxG.height - PANEL_H) / 2);
        panel.makeGraphic(PANEL_W, PANEL_H, COL_PANEL);
        add(panel);

        var border = new FlxSprite(panel.x - 1, panel.y - 1);
        border.makeGraphic(PANEL_W + 2, PANEL_H + 2, COL_BORDER);
        border.alpha = 0.8;
        insert(members.indexOf(panel), border);

        var headerBg = new FlxSprite(panel.x, panel.y);
        headerBg.makeGraphic(PANEL_W, 60, 0xFF0A0A18);
        add(headerBg);

        title = new FlxText(panel.x + 24, panel.y + 14, 0, "🏆  GLOBAL RANKING");
        title.setFormat("VCR OSD Mono", 22, COL_PURPLE, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(title);

        var closeBtn = new FlxText(panel.x + PANEL_W - 50, panel.y + 14, 0, "✕");
        closeBtn.setFormat("VCR OSD Mono", 22, COL_MUTED, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        closeBtn.ID = 9999;
        add(closeBtn);

        var colY = panel.y + 68;
        var colBg = new FlxSprite(panel.x, colY);
        colBg.makeGraphic(PANEL_W, 28, 0xFF090915);
        add(colBg);

        var cols = [
            {text:"#",            x:panel.x + 16},
            {text:"OYUNCU",       x:panel.x + 70},
            {text:"ÜLKE",         x:panel.x + 340},
            {text:"SEVİYE",       x:panel.x + 420},
            {text:"ULTRA PTS",    x:panel.x + 530},
            {text:"DOĞRULUK",     x:panel.x + 660},
            {text:"ŞARKI",        x:panel.x + 750},
        ];
        for (col in cols) {
            var t = new FlxText(col.x, colY + 6, 0, col.text);
            t.setFormat("VCR OSD Mono", 10, COL_MUTED, LEFT);
            add(t);
        }

        loadingText = new FlxText(panel.x, panel.y + 200, PANEL_W, "YÜKLENİYOR...");
        loadingText.setFormat("VCR OSD Mono", 18, COL_MUTED, CENTER,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(loadingText);

        entriesGroup = new FlxSpriteGroup(panel.x, panel.y + 96);
        add(entriesGroup);

        panel.y    += 30; panel.alpha = 0;
        headerBg.y += 30; headerBg.alpha = 0;
        FlxTween.tween(panel,    {y: panel.y - 30, alpha: 1}, 0.35, {ease: FlxEase.quartOut});
        FlxTween.tween(headerBg, {y: headerBg.y - 30, alpha: 1}, 0.35, {ease: FlxEase.quartOut});

        fetchLeaderboard();

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    }

	function fetchLeaderboard() {
		var token:String = SupabaseClient.getToken() ?? ""; 
		var endpoint:String = "/rest/v1/global_leaderboard?select=*"; 

		sys.thread.Thread.create(() -> {
			SupabaseClient.getAsync(endpoint, token, (statusCode, responseData) -> {

				new flixel.util.FlxTimer().start(0.1, function(tmr:flixel.util.FlxTimer) {
					loadingText.visible = false;

					if (responseData == null || statusCode >= 400) {
						loadingText.text = "BAĞLANTI HATASI (" + statusCode + ")";
						loadingText.color = COL_RED;
						loadingText.visible = true;
						return;
					}

					try {
						entries = haxe.Json.parse(responseData);
						buildRows();
					} catch(e) {
						loadingText.text = "VERİ HATASI";
						loadingText.color = COL_RED;
						loadingText.visible = true;
					}
				});
			});
		});
	}

    function buildRows() {
        entriesGroup.clear();
        var y = 0.0;

        for (i in 0...entries.length) {
            final p    = entries[i];
            final pos  = i + 1;
            final isMe = AuthManager.isLoggedIn &&
                         Std.string(p.username) == AuthManager.currentUsername;

            var rowBg = new FlxSprite(0, y);
            rowBg.makeGraphic(PANEL_W, ROW_H - 2,
                isMe ? 0xFF1A1A35 : (i % 2 == 0 ? COL_PANEL : 0xFF0F0F20));
            entriesGroup.add(rowBg);

            if (isMe) {
                var accent = new FlxSprite(0, y);
                accent.makeGraphic(3, ROW_H - 2, COL_PURPLE);
                entriesGroup.add(accent);
            }

            var rankColor = switch(pos) {
                case 1: COL_GOLD;
                case 2: COL_SILVER;
                case 3: COL_BRONZE;
                default:
                    if (Std.string(p.role) == 'founder') COL_GOLD
                    else if (Std.string(p.role) == 'admin') COL_PURPLE
                    else COL_MUTED;
            }
            var rankTxt = new FlxText(16, y + (ROW_H - 16) / 2, 0, Std.string(pos));
            rankTxt.setFormat("VCR OSD Mono", 14, rankColor, LEFT);
            entriesGroup.add(rankTxt);

            var nameColor = isMe ? COL_PURPLE : FlxColor.WHITE;
            var nameTxt = new FlxText(70, y + (ROW_H - 16) / 2, 240, Std.string(p.username ?? "?"));
            nameTxt.setFormat("VCR OSD Mono", 14, nameColor, LEFT,
                FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            entriesGroup.add(nameTxt);

            if (p.badge != null && Std.string(p.role) != 'player') {
                var badgeColor = switch(Std.string(p.role)) {
                    case 'founder': COL_GOLD;
                    case 'admin':   COL_PURPLE;
                    case 'moderator': COL_GREEN;
                    default: COL_MUTED;
                }
                var badgeTxt = new FlxText(70, y + (ROW_H - 14) / 2 + 14, 0,
                    Std.string(p.badge));
                badgeTxt.setFormat("VCR OSD Mono", 9, badgeColor, LEFT);
                entriesGroup.add(badgeTxt);
                nameTxt.y -= 6;
            }

            var flags:Map<String, String> = [
                "Turkey" => "🇹🇷", "United States" => "🇺🇸",
                "United Kingdom" => "🇬🇧", "Germany" => "🇩🇪",
                "France" => "🇫🇷", "Japan" => "🇯🇵",
                "Brazil" => "🇧🇷", "Russia" => "🇷🇺", "Other" => "🌍"
            ];
            var flag = flags.get(Std.string(p.country ?? "Other")) ?? "🌍";
            var flagTxt = new FlxText(340, y + (ROW_H - 16) / 2, 0, flag);
            flagTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT);
            entriesGroup.add(flagTxt);

            var lvlBg = new FlxSprite(420, y + (ROW_H - 20) / 2);
            lvlBg.makeGraphic(70, 20, 0xFF1A1A35);
            entriesGroup.add(lvlBg);
            var lvlTxt = new FlxText(420, y + (ROW_H - 16) / 2, 70,
                "Lv." + Std.string(p.level ?? 1));
            lvlTxt.setFormat("VCR OSD Mono", 11, COL_PURPLE, CENTER);
            entriesGroup.add(lvlTxt);

            var up = Math.round((p.ultra_points ?? 0.0) * 10) / 10;
            var upTxt = new FlxText(530, y + (ROW_H - 16) / 2, 120,
                up + " UP");
            upTxt.setFormat("VCR OSD Mono", 13, 0xFFA78BFA, LEFT);
            entriesGroup.add(upTxt);

            var acc:Float = p.best_accuracy ?? 0;
            var accColor = acc >= 99 ? 0xFFA78BFA
                         : acc >= 95 ? 0xFF60A5FA
                         : acc >= 85 ? COL_GREEN
                         : acc >= 70 ? COL_GOLD
                         : COL_MUTED;
            var accTxt = new FlxText(660, y + (ROW_H - 16) / 2, 80,
                FlxMath.roundDecimal(acc, 1) + "%");
            accTxt.setFormat("VCR OSD Mono", 13, accColor, LEFT);
            entriesGroup.add(accTxt);

            var songsTxt = new FlxText(750, y + (ROW_H - 16) / 2, 60,
                Std.string(p.songs_played ?? 0));
            songsTxt.setFormat("VCR OSD Mono", 13, COL_MUTED, LEFT);
            entriesGroup.add(songsTxt);

            y += ROW_H;
        }

        maxScroll = Math.max(0, y - (PANEL_H - 96 - 10));
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.mouse.wheel != 0) {
            scrollOffset = FlxMath.bound(
                scrollOffset - FlxG.mouse.wheel * ROW_H,
                0, maxScroll
            );
            entriesGroup.y = panel.y + 96 - scrollOffset;
        }

        if (controls.BACK || (FlxG.keys.justPressed.ESCAPE)) {
            close();
        }

        entriesGroup.y = panel.y + 96 - scrollOffset;
    }

    override function close() {
        onClose();
        super.close();
    }
}

