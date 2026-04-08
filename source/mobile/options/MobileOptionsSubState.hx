package mobile.options;

import mobile.backend.MobileScaleMode;
import mobile.backend.StorageUtil;
import flixel.input.keyboard.FlxKey;
import options.BaseOptionsMenu;
import options.Option;

class MobileOptionsSubState extends BaseOptionsMenu
{
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	var option:Option;

	// Mod yolu göstermek için STRING option referansı
	var modPathOption:Option;

	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu';
		var HitboxTypes:Array<String> = Mods.mergeAllTextsNamed('mobile/Hitbox/HitboxModes/hitboxModeList.txt');

		var option:Option = new Option('Extra Controls', 'Select how many extra buttons you prefer to have?\nThey can be used for mechanics with LUA or HScript.',
			 'extraButtons', INT);
		option.scrollSpeed = 1;
		option.minValue = 0;
		option.maxValue = 4;
		option.changeValue = 1;
		option.decimals = 0;
		addOption(option);

		option = new Option('Mobile Controls Opacity',
			'Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons).',
			'controlsAlpha', PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			mobileManager.mobilePad.alpha = curOption.getValue();
			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		#if mobile
		option = new Option('Allow Phone Screensaver',
			'If checked, the phone will sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)',
			'screensaver', BOOL);
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);

		option = new Option('Wide Screen Mode',
			'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
			'wideScreen', BOOL);
		option.onChange = () -> FlxG.scaleMode = new MobileScaleMode();
		addOption(option);
		#end

		option = new Option('Hitbox Mode', 'Choose your Hitbox Style!', 'hitboxMode', STRING, HitboxTypes);
		addOption(option);

		option = new Option('Hitbox Design', 'Choose how your hitbox should look like.', 'hitboxType', STRING, hintOptions);
		addOption(option);

		option = new Option('Hitbox Position',
			'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
			'hitboxPos', BOOL);
		addOption(option);

		option = new Option('Dynamic Controls Color',
			'If checked, the mobile controls color will be set to the notes color in your settings.\n(have effect during gameplay only)',
			'dynamicColors', BOOL);
		addOption(option);

		// ── Mod Yeri ────────────────────────────────────────────────────────
		modPathOption = new Option('Mod Yeri',
			'Modlarının bulunduğu klasörü seç.\nONAY\'a bas → dosya yöneticisi açılır → klasörü seç.\nDeğişiklik oyunu yeniden başlatınca geçerli olur.',
			'modsPath', STRING, [_getShortModPath()]);
		modPathOption.onChange = () -> _refreshModPathDisplay();
		addOption(modPathOption);

		var resetOption:Option = new Option('Mod Yerini Sıfırla',
			'Mod klasörünü varsayılana (mods/) sıfırlar.',
			'_resetModPath', BOOL);
		resetOption.onChange = () ->
		{
			StorageUtil.resetModsDirectory();
			_refreshModPathDisplay();
			ClientPrefs.data._resetModPath = false;
			CoolUtil.showPopUp('Mod klasörü varsayılana sıfırlandı.\nDeğişiklik için oyunu yeniden başlatın.', 'Sıfırlandı');
		};
		addOption(resetOption);
		// ────────────────────────────────────────────────────────────────────

		super();
	}

	override function update(elapsed:Float)
	{
		#if (android || ios || windows || mac || linux)
		if (modPathOption != null && curOption == modPathOption && controls.ACCEPT)
		{
			_openModPathPicker();
			return;
		}
		#end

		super.update(elapsed);
	}

	#if (android || ios || windows || mac || linux)
	function _openModPathPicker():Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		StorageUtil.onModPathSelected = function(selectedPath:String)
		{
			_refreshModPathDisplay();
			CoolUtil.showPopUp(
				'Mod klasörü değiştirildi!\n' + selectedPath + '\n\nDeğişikliğin geçerli olması için oyunu yeniden başlatın.',
				'Mod Yeri Değiştirildi'
			);
		};

		StorageUtil.openFolderPicker();
	}

	function _refreshModPathDisplay():Void
	{
		if (modPathOption == null) return;
		modPathOption.options = [_getShortModPath()];
		modPathOption.curOption = 0;
		modPathOption.setValue(_getShortModPath());
		updateTextFrom(modPathOption);
	}

	static function _getShortModPath():String
	{
		var path:String = ClientPrefs.data.modsPath;
		if (path == null || path.trim().length == 0)
			return 'Varsayılan';

		var sep:String = #if windows '\\' #else '/' #end;
		var parts:Array<String> = path.split(sep);
		parts = parts.filter(p -> p.length > 0);
		if (parts.length >= 2)
			return '.../' + parts[parts.length - 2] + '/' + parts[parts.length - 1];
		return path;
	}
	#end
}
