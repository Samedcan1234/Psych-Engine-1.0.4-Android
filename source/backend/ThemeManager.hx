package backend;

import states.ultramenus.turkey.*;
import states.ultramenus.original.*;
import states.ultramenus.v1.*;
import states.*;
import flixel.FlxState;

class ThemeManager
{
    // ==========================================
    //  TEMA MAPPING - Options'daki sıraya göre!
    // ==========================================
    
    // Options'daki array: ['V3', 'Türkiye', 'Original', 'V1']
    // Bu mapping'ler Options'daki değerlerle eşleşmeli
    
    private static var themeAliases:Map<String, String> = [
        // Lowercase versiyonlar
        "v3" => "V3",
        "türkiye" => "TÜRKIYE",
        "turkiye" => "TÜRKIYE",
        "turkey" => "TÜRKIYE",
        "tr" => "TÜRKIYE",
        "original" => "ORIGINAL",
        "psych" => "ORIGINAL",
        "classic" => "ORIGINAL",
        "v1" => "V1",
        "legacy" => "V1",
        
        // Uppercase versiyonlar (zaten doğru)
        "V3" => "V3",
        "TÜRKIYE" => "TÜRKIYE",
        "TURKIYE" => "TÜRKIYE",
        "TURKEY" => "TÜRKIYE",
        "ORIGINAL" => "ORIGINAL",
        "V1" => "V1"
    ];

    // ==========================================
    //  ANA FONKSİYONLAR
    // ==========================================

    public static function switchToMainMenu():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                MusicBeatState.switchState(new states.ultramenus.turkey.MainMenuTurkey());
            case 'ORIGINAL':
                MusicBeatState.switchState(new states.ultramenus.original.MainMenuOriginal());
            case 'V1':
                MusicBeatState.switchState(new states.ultramenus.v1.MainMenuV1());
            default: // V3
                MusicBeatState.switchState(new states.MainMenuState());
        }
    }

    public static function loadAndSwitchToPlay():Void
    {
        states.LoadingState.loadAndSwitchState(new states.PlayState());
    }

    public static function loadAndSwitchToStoryMenu():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                states.LoadingState.loadAndSwitchState(new states.ultramenus.turkey.StoryMenuTurkey());
            case 'ORIGINAL':
                states.LoadingState.loadAndSwitchState(new states.ultramenus.original.StoryMenuOriginal());
            case 'V1':
                states.LoadingState.loadAndSwitchState(new states.ultramenus.v1.StoryMenuV1());
            default:
                states.LoadingState.loadAndSwitchState(new states.StoryMenuState());
        }
    }

    public static function loadAndSwitchToFreeplay():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                states.LoadingState.loadAndSwitchState(new states.ultramenus.turkey.FreeplayTurkey());
            case 'ORIGINAL':
                states.LoadingState.loadAndSwitchState(new states.ultramenus.original.FreeplayOriginal());
            case 'V1':
                states.LoadingState.loadAndSwitchState(new states.ultramenus.v1.FreeplayV1());
            default:
                states.LoadingState.loadAndSwitchState(new states.FreeplayState());
        }
    }

    public static function switchToTitle():Void
    {
        MusicBeatState.switchState(new states.TitleState());
    }

    public static function switchToFreeplay():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                MusicBeatState.switchState(new states.ultramenus.turkey.FreeplayTurkey());
            case 'ORIGINAL':
                MusicBeatState.switchState(new states.ultramenus.original.FreeplayOriginal());
            case 'V1':
                MusicBeatState.switchState(new states.ultramenus.v1.FreeplayV1());
            default:
                MusicBeatState.switchState(new states.FreeplayState());
        }
    }

    public static function switchToStoryMenu():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                MusicBeatState.switchState(new states.ultramenus.turkey.StoryMenuTurkey());
            case 'ORIGINAL':
                MusicBeatState.switchState(new states.ultramenus.original.StoryMenuOriginal());
            case 'V1':
                MusicBeatState.switchState(new states.ultramenus.v1.StoryMenuV1());
            default:
                MusicBeatState.switchState(new states.StoryMenuState());
        }
    }

    public static function switchToAchievements():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                MusicBeatState.switchState(new states.ultramenus.turkey.AchievementsTurkey());
            case 'ORIGINAL':
                MusicBeatState.switchState(new states.ultramenus.original.AchievementsOriginal());
            case 'V1':
                MusicBeatState.switchState(new states.ultramenus.v1.AchievementsV1());
            default:
                MusicBeatState.switchState(new states.AchievementsMenuState());
        }
    }

    public static function switchToCredits():Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                MusicBeatState.switchState(new states.ultramenus.turkey.CreditsTurkey());
            case 'ORIGINAL':
                MusicBeatState.switchState(new states.ultramenus.original.CreditsOriginal());
            case 'V1':
                MusicBeatState.switchState(new states.ultramenus.v1.CreditsV1());
            default:
                MusicBeatState.switchState(new states.CreditsState());
        }
    }

    #if MODS_ALLOWED
    public static function switchToMods(?modFolder:String):Void
    {
        switch (getThemeID())
        {
            case 'TÜRKIYE':
                MusicBeatState.switchState(new states.ultramenus.turkey.ModsMenuTurkey(modFolder));
            case 'ORIGINAL':
                MusicBeatState.switchState(new states.ultramenus.original.ModsMenuOriginal(modFolder));
            case 'V1':
                MusicBeatState.switchState(new states.ultramenus.v1.ModsMenuV1(modFolder));
            default:
                MusicBeatState.switchState(new states.ModsMenuState(modFolder));
        }
    }
    #end

    public static function switchToOptions(?onPlayState:Bool = false):Void
    {
        options.OptionsState.onPlayState = onPlayState;
        MusicBeatState.switchState(new options.OptionsState());
    }

    // ==========================================
    //  TEMA ALGILAMA - NORMALIZE EDİLMİŞ
    // ==========================================

    /**
     * ClientPrefs'ten tema değerini al ve normalize et
     * Options'dan gelen değer: "Türkiye", "V3", "Original", "V1"
     * Internal ID döndürür: "TÜRKIYE", "V3", "ORIGINAL", "V1"
     */
    public static function getThemeID():String
    {
        var theme:String = ClientPrefs.data.menuTheme;
        if (theme == null || theme.length == 0) 
            return 'V3';
        
        // Alias mapping ile normalize et
        var normalized = normalizeTheme(theme);
        return normalized;
    }
    
    /**
     * Tema değerini normalize et (büyük/küçük harf, Türkçe karakter vs.)
     */
    private static function normalizeTheme(theme:String):String
    {
        if (theme == null) return "V3";
        
        // Önce alias map'te ara
        if (themeAliases.exists(theme))
            return themeAliases.get(theme);
        
        // Lowercase olarak da dene
        var lower = theme.toLowerCase();
        if (themeAliases.exists(lower))
            return themeAliases.get(lower);
        
        // Türkçe karakter düzeltmeleri
        var cleaned = theme;
        cleaned = StringTools.replace(cleaned, "ü", "u");
        cleaned = StringTools.replace(cleaned, "Ü", "U");
        cleaned = StringTools.replace(cleaned, "ı", "i");
        cleaned = StringTools.replace(cleaned, "İ", "I");
        cleaned = StringTools.replace(cleaned, "ş", "s");
        cleaned = StringTools.replace(cleaned, "Ş", "S");
        cleaned = StringTools.replace(cleaned, "ğ", "g");
        cleaned = StringTools.replace(cleaned, "Ğ", "G");
        cleaned = StringTools.replace(cleaned, "ç", "c");
        cleaned = StringTools.replace(cleaned, "Ç", "C");
        cleaned = StringTools.replace(cleaned, "ö", "o");
        cleaned = StringTools.replace(cleaned, "Ö", "O");
        
        // Cleaned versiyonu da dene
        if (themeAliases.exists(cleaned))
            return themeAliases.get(cleaned);
        if (themeAliases.exists(cleaned.toLowerCase()))
            return themeAliases.get(cleaned.toLowerCase());
        if (themeAliases.exists(cleaned.toUpperCase()))
            return themeAliases.get(cleaned.toUpperCase());
        
        // Hiçbiri eşleşmezse uppercase döndür
        return theme.toUpperCase();
    }

    /**
     * Eski API uyumluluğu için - getTheme() hala çalışsın
     */
    public static function getTheme():String
    {
        return getThemeID();
    }

    public static function saveSettings():Void
    {
        ClientPrefs.saveSettings();
    }

    public static function getThemeIndex():Int
    {
        var theme:String = getThemeID();
        // Options sırası: ['V3', 'Türkiye', 'Original', 'V1']
        // Internal: ['V3', 'TÜRKIYE', 'ORIGINAL', 'V1']
        return switch(theme) {
            case 'V3': 0;
            case 'TÜRKIYE': 1;
            case 'ORIGINAL': 2;
            case 'V1': 3;
            default: 0;
        };
    }

    // ==========================================
    //  QUICK CHECKS
    // ==========================================

    public static function isTurkey():Bool
    {
        return getThemeID() == 'TÜRKIYE';
    }

    public static function isV3():Bool
    {
        return getThemeID() == 'V3';
    }

    public static function isOriginal():Bool
    {
        return getThemeID() == 'ORIGINAL';
    }

    public static function isV1():Bool
    {
        return getThemeID() == 'V1';
    }
    
    // ==========================================
    //  DEBUG
    // ==========================================
    
    public static function debugTheme():Void
    {
        var raw = ClientPrefs.data.menuTheme;
        var normalized = getThemeID();
        trace('[ThemeManager] Raw value: "$raw" -> Normalized: "$normalized"');
        trace('[ThemeManager] isTurkey: ${isTurkey()}, isV3: ${isV3()}, isOriginal: ${isOriginal()}, isV1: ${isV1()}');
    }
}