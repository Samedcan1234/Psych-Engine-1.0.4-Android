package objects;

import backend.AuthManager;
import backend.SupabaseClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class ProfileBox extends FlxSpriteGroup {

    static inline final COL_BG          = 0xCC0D0D1A;
    static inline final COL_ACCENT      = 0xFFC084FC;  

    static inline final COL_GREEN       = 0xFF34D399;
    static inline final COL_MUTED       = 0xFF8888AA;
    static inline final COL_GOLD        = 0xFFFBBF24;
    static inline final COL_CYAN        = 0xFF22D3EE;
    static inline final COL_PINK        = 0xFFF472B6;

    static inline final BOX_W = 260;
    static inline final BOX_H = 75;
    static inline final AVATAR_SIZE = 45;
    static inline final XP_BAR_H = 5;

    static inline final CACHE_FILE = "profile_cache.json";

    var bg:FlxSprite;
    var accentBar:FlxSprite;
    var avatarBg:FlxSprite;
    var avatarLetter:FlxText;
    var onlineDot:FlxSprite;
    var usernameText:FlxText;
    var levelText:FlxText;
    var rankText:FlxText;
    var xpBarBg:FlxSprite;
    var xpBarFill:FlxSprite;

    var _pulseTime:Float = 0;
    var _built:Bool = false;

    public static var instance:ProfileBox = null;

    public function new(?xPos:Float = 0, ?yPos:Float = 0) {
        super(xPos, yPos);

        if (!AuthManager.isLoggedIn) {
            _built = false;
            visible = false;
            return;
        }

        instance = this;
        build();
    }

    public static function create(?x:Float = 0, ?y:Float = 0):Null<ProfileBox> {
        if (!AuthManager.isLoggedIn) {
            trace('[ProfileBox] User not logged in - skipping creation');
            return null;
        }
        return new ProfileBox(x, y);
    }

    function build():Void {
        if (!AuthManager.isLoggedIn) return;

        _built = true;

        bg = new FlxSprite(0, 0);
        bg.makeGraphic(BOX_W, BOX_H, COL_BG);
        bg.alpha = 0.92;
        add(bg);

        accentBar = new FlxSprite(0, 0);
        accentBar.makeGraphic(4, BOX_H, COL_ACCENT);
        add(accentBar);

        onlineDot = new FlxSprite(BOX_W - 14, 8);
        onlineDot.makeGraphic(8, 8, COL_GREEN);
        add(onlineDot);

        avatarBg = new FlxSprite(12, 10);
        avatarBg.makeGraphic(AVATAR_SIZE, AVATAR_SIZE, 0xFF2A2A4A);
        add(avatarBg);

        var username = AuthManager.currentUsername ?? "P";
        avatarLetter = new FlxText(12, 18, AVATAR_SIZE, username.charAt(0).toUpperCase());
        avatarLetter.setFormat("VCR OSD Mono", 22, COL_ACCENT, CENTER);
        add(avatarLetter);

        var textX = 12 + AVATAR_SIZE + 10;
        var textW = BOX_W - textX - 15;

        usernameText = new FlxText(textX, 8, textW, AuthManager.currentUsername ?? "Player");
        usernameText.setFormat("VCR OSD Mono", 13, FlxColor.WHITE, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(usernameText);

        var level = AuthManager.currentLevel ?? 1;
        var score = AuthManager.currentScore ?? 0;
        var up = AuthManager.currentUltraPoints ?? 0.0;

        levelText = new FlxText(textX, 24, textW, 'Lv.${level} • ${formatNumber(up)} UP');
        levelText.setFormat("VCR OSD Mono", 9, COL_MUTED, LEFT);
        add(levelText);

        var rank = getRankFromUP(up);
        rankText = new FlxText(textX, 38, textW, getRankTitle(rank));
        rankText.setFormat("VCR OSD Mono", 8, getRankColor(rank), LEFT);
        add(rankText);

        var xp = getXPProgress();
        var xpBarY = BOX_H - XP_BAR_H - 6;

        xpBarBg = new FlxSprite(textX, xpBarY);
        xpBarBg.makeGraphic(Std.int(textW), XP_BAR_H, 0xFF1A1A2E);
        add(xpBarBg);

        var fillWidth = Std.int(Math.max(2, textW * xp));
        xpBarFill = new FlxSprite(textX, xpBarY);
        xpBarFill.makeGraphic(fillWidth, XP_BAR_H, COL_ACCENT);
        add(xpBarFill);

        alpha = 0;
        var startX = x;
        x += 25;
        FlxTween.tween(this, {alpha: 1, x: startX}, 0.4, {
            ease: FlxEase.backOut,
            startDelay: 0.15
        });

        saveCache();
    }

    override function update(elapsed:Float):Void {
        if (!_built) return;

        super.update(elapsed);

        _pulseTime += elapsed;
        if (onlineDot != null) {
            onlineDot.alpha = 0.7 + Math.sin(_pulseTime * 3) * 0.3;
        }

        var hovered = FlxG.mouse.overlaps(this);
        if (bg != null) {
            bg.alpha = hovered ? 1.0 : 0.92;
        }
        if (accentBar != null) {
            accentBar.scale.x = hovered ? 1.5 : 1.0;
        }

        if (hovered && FlxG.mouse.justPressed) {
            onClick();
        }
    }

    function onClick():Void {

        FlxTween.tween(scale, {x: 0.95, y: 0.95}, 0.08, {
            ease: FlxEase.sineOut,
            onComplete: function(_) {
                FlxTween.tween(scale, {x: 1, y: 1}, 0.12, {ease: FlxEase.backOut});
            }
        });

        FlxG.switchState(function() { return new states.MultiplayerState(); });
    }

    public function refresh():Void {
        if (!AuthManager.isLoggedIn) {

            visible = false;
            _built = false;
            return;
        }

        if (usernameText != null) {
            usernameText.text = AuthManager.currentUsername ?? "Player";
        }

        if (avatarLetter != null) {
            var username = AuthManager.currentUsername ?? "P";
            avatarLetter.text = username.charAt(0).toUpperCase();
        }

        if (levelText != null) {
            var level = AuthManager.currentLevel ?? 1;
            var up = AuthManager.currentUltraPoints ?? 0.0;
            levelText.text = 'Lv.${level} • ${formatNumber(up)} UP';
        }

        if (rankText != null) {
            var up = AuthManager.currentUltraPoints ?? 0.0;
            var rank = getRankFromUP(up);
            rankText.text = getRankTitle(rank);
            rankText.color = getRankColor(rank);
        }

        updateXPBar();

        saveCache();
    }

    function updateXPBar():Void {
        if (xpBarFill == null || xpBarBg == null) return;

        var xp = getXPProgress();
        var fillWidth = Std.int(Math.max(2, xpBarBg.width * xp));
        xpBarFill.makeGraphic(fillWidth, XP_BAR_H, COL_ACCENT);
    }

    function getRankFromUP(up:Float):String {
        if (up >= 100000) return "legend";
        if (up >= 50000) return "grandmaster";
        if (up >= 25000) return "master";
        if (up >= 10000) return "diamond";
        if (up >= 5000) return "platinum";
        if (up >= 2000) return "gold";
        if (up >= 500) return "silver";
        return "bronze";
    }

    function getRankTitle(rank:String):String {
        return switch(rank.toLowerCase()) {
            case "bronze": "🥉 Bronze";
            case "silver": "🥈 Silver";
            case "gold": "🥇 Gold";
            case "platinum": "💎 Platinum";
            case "diamond": "💠 Diamond";
            case "master": "👑 Master";
            case "grandmaster": "⭐ Grandmaster";
            case "legend": "🔥 LEGEND";
            default: "• " + rank;
        };
    }

    function getRankColor(rank:String):FlxColor {
        return switch(rank.toLowerCase()) {
            case "bronze": 0xFFCD7F32;
            case "silver": 0xFFC0C0C0;
            case "gold": COL_GOLD;
            case "platinum": 0xFFE5E4E2;
            case "diamond": COL_CYAN;
            case "master": COL_ACCENT;
            case "grandmaster": COL_PINK;
            case "legend": 0xFFFF6B6B;
            default: COL_MUTED;
        };
    }

    function getXPProgress():Float {
        var level = AuthManager.currentLevel ?? 1;
        var score = AuthManager.currentScore ?? 0;

        var xpForCurrentLevel = getXPForLevel(level);
        var xpForNextLevel = getXPForLevel(level + 1);
        var xpNeeded = xpForNextLevel - xpForCurrentLevel;
        var xpProgress = score - xpForCurrentLevel;

        if (xpNeeded <= 0) return 1.0;
        return Math.max(0, Math.min(1, xpProgress / xpNeeded));
    }

    function getXPForLevel(level:Int):Int {

        return Std.int(100 * Math.pow(1.15, level - 1));
    }

    function formatNumber(num:Float):String {
        if (num >= 1000000) return Std.string(FlxMath.roundDecimal(num / 1000000, 1)) + "M";
        if (num >= 1000) return Std.string(FlxMath.roundDecimal(num / 1000, 1)) + "K";
        return Std.string(Std.int(num));
    }

    function saveCache():Void {
        #if sys
        try {
            var data = {
                username: AuthManager.currentUsername,
                level: AuthManager.currentLevel,
                score: AuthManager.currentScore,
                ultraPoints: AuthManager.currentUltraPoints,
                country: AuthManager.currentCountry,
                timestamp: Date.now().toString()
            };

            var json = haxe.Json.stringify(data);
            File.saveContent(getCachePath(), json);
        } catch(e:Dynamic) {
            trace('[ProfileBox] Cache save failed: $e');
        }
        #end
    }

    public static function loadCache():Bool {
        #if sys
        try {
            var path = getCachePath();
            if (!FileSystem.exists(path)) return false;

            var content = File.getContent(path);
            var data:Dynamic = haxe.Json.parse(content);

            AuthManager.currentUsername = data.username ?? "Player";
            AuthManager.currentLevel = data.level ?? 1;
            AuthManager.currentScore = data.score ?? 0;
            AuthManager.currentUltraPoints = data.ultraPoints ?? 0.0;
            AuthManager.currentCountry = data.country ?? "";

            trace('[ProfileBox] Cache loaded: ${data.username}');
            return true;
        } catch(e:Dynamic) {
            trace('[ProfileBox] Cache load failed: $e');
        }
        #end
        return false;
    }

    public static function clearCache():Void {
        #if sys
        try {
            var path = getCachePath();
            if (FileSystem.exists(path)) {
                FileSystem.deleteFile(path);
            }
        } catch(e:Dynamic) {}
        #end
    }

    static function getCachePath():String {
        #if android
        return StorageUtil.getExternalStorageDirectory() + CACHE_FILE;
        #elseif sys
        return Sys.getCwd() + CACHE_FILE;
        #else
        return CACHE_FILE;
        #end
    }

    public static function onSongComplete(accuracy:Float, score:Int, combo:Int, difficulty:Int):Void {
        if (!AuthManager.isLoggedIn) return;

        var xpGained = calculateXP(accuracy, difficulty, combo);
        var upGained = calculateUP(score, accuracy);

        AuthManager.currentScore += score;
        AuthManager.currentUltraPoints += upGained;

        checkLevelUp();

        if (instance != null) {
            instance.refresh();
        }

        syncToServer(score, xpGained, upGained);

        trace('[ProfileBox] Song complete: +${xpGained} XP, +${upGained} UP');
    }

    static function calculateXP(accuracy:Float, difficulty:Int, combo:Int):Int {
        var base = 50 + (difficulty * 25);
        var accBonus = Std.int(accuracy * 100);
        var comboBonus = Std.int(Math.min(500, combo * 0.5));
        return base + accBonus + comboBonus;
    }

    static function calculateUP(score:Int, accuracy:Float):Float {
        return (score / 10000.0) * accuracy;
    }

    static function checkLevelUp():Void {
        var currentLevel = AuthManager.currentLevel ?? 1;
        var score = AuthManager.currentScore ?? 0;
        var newLevel = calculateLevelFromScore(score);

        if (newLevel > currentLevel) {
            AuthManager.currentLevel = newLevel;
            trace('[ProfileBox] 🎉 LEVEL UP! ${currentLevel} -> ${newLevel}');

            #if NOTIFICATIONS_ENABLED
            NotificationManager.show("Level Up!", 'You reached level ${newLevel}!', SUCCESS);
            #end
        }
    }
	
	public function updateStats(totalScore:Int, songsPlayed:Int, avgAcc:Float, fcCount:Int):Void
	{
		if (!_built) return;
		
		// Level hesapla
		var level = Math.floor(totalScore / 50000) + 1;
		var xpProgress = (totalScore % 50000) / 50000;
		
		// AuthManager'ı güncelle
		AuthManager.currentLevel = level;
		AuthManager.currentScore = totalScore;
		
		// UI güncelle
		if (levelText != null)
		{
			var up = AuthManager.currentUltraPoints ?? 0.0;
			levelText.text = 'Lv.${level} • ${formatNumber(up)} UP';
		}
		
		// XP bar güncelle
		if (xpBarFill != null && xpBarBg != null)
		{
			var fillWidth = Std.int(Math.max(2, xpBarBg.width * xpProgress));
			xpBarFill.makeGraphic(fillWidth, XP_BAR_H, COL_ACCENT);
		}
		
		// Rank güncelle
		if (rankText != null)
		{
			var rank = getRankFromUP(AuthManager.currentUltraPoints ?? 0.0);
			rankText.text = getRankTitle(rank);
			rankText.color = getRankColor(rank);
		}
		
		// Cache kaydet
		saveCache();
	}

    static function calculateLevelFromScore(score:Int):Int {
        var level = 1;
        var required = 100;
        var total = 0;

        while (total + required <= score) {
            total += required;
            level++;
            required = Std.int(100 * Math.pow(1.15, level - 1));
        }

        return level;
    }
	
	public static function syncFromAuth():Void {
		if (!AuthManager.isLoggedIn) return;
		
		// save() değil, saveCache() kullanmalıyız
		// Ama saveCache() instance method, static değil
		// Bu yüzden static bir helper yazalım:
		
		#if sys
		try {
			var data = {
				username: AuthManager.currentUsername,
				level: AuthManager.currentLevel,
				score: AuthManager.currentScore,
				ultraPoints: AuthManager.currentUltraPoints,
				country: AuthManager.currentCountry,
				timestamp: Date.now().toString()
			};
			
			var json = haxe.Json.stringify(data);
			sys.io.File.saveContent(getStaticCachePath(), json);
		} catch(e:Dynamic) {
			trace('[ProfileBox] syncFromAuth failed: $e');
		}
		#end
	}
	
	private static function getStaticCachePath():String
	{
		#if android
		return StorageUtil.getExternalStorageDirectory() + "profile_cache.json";
		#elseif sys
		return Sys.getCwd() + "profile_cache.json";
		#else
		return "profile_cache.json";
		#end
	}

	public static function getCachedProfile():Dynamic
	{
		#if sys
		try {
			var path = getStaticCachePath();
			if (!sys.FileSystem.exists(path)) return null;
			
			var content = sys.io.File.getContent(path);
			return haxe.Json.parse(content);
		} catch(e:Dynamic) {
			trace('[ProfileBox] getCachedProfile failed: $e');
		}
		#end
		return null;
	}

    static function syncToServer(score:Int, xp:Int, up:Float):Void {
        if (!AuthManager.isLoggedIn) return;

        var userId = AuthManager.currentUserId;
        if (userId == null || userId.length == 0) return;

        var body = {
            total_score: AuthManager.currentScore,
            ultra_points: AuthManager.currentUltraPoints,
            level: AuthManager.currentLevel
        };

        SupabaseClient.postAsync(
            '/rest/v1/profiles?id=eq.${userId}',
            body,
            SupabaseClient.getToken(),
            function(status:Int, data:String) {
                if (status == 200 || status == 204) {
                    trace('[ProfileBox] Server sync OK');
                } else {
                    trace('[ProfileBox] Server sync failed: $status');
                }
            }
        );
    }

    public static function onLogin():Void {

        if (instance != null) {
            instance.saveCache();
            instance.refresh();
        }
    }

    public static function onLogout():Void {
        clearCache();
        if (instance != null) {
            instance.visible = false;
            instance._built = false;
        }
    }

    override function destroy():Void {
        if (instance == this) {
            instance = null;
        }
        super.destroy();
    }
}