package options;

class PEUSettingsState extends BaseOptionsMenu
{
	public function new()
	{
		title    = Language.getPhrase('peu_title',     'P.E.U Settings');
		rpcTitle = Language.getPhrase('peu_rpc_title', 'P.E.U Settings Menu');

		var option:Option = new Option(
			Language.getPhrase('peu_watermark',      'P.E.U Watermark'),
			Language.getPhrase('peu_watermark_desc', 'When enabled, activates the Psych Engine Ultra watermark on the top left.'),
			'peuwatermark',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			Language.getPhrase('peu_loading_screen',      'P.E.U Loading Screen'),
			Language.getPhrase('peu_loading_screen_desc', 'When enabled, uses P.E.U loading screens instead of the original.'),
			'peuloadingscreen',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			Language.getPhrase('peu_logo_style',      'P.E.U Logo Style:'),
			Language.getPhrase('peu_logo_style_desc', 'Select the logo displayed on the watermark.'),
			'peuwatermarklogo',
			STRING,
			['V1', 'V2', 'V2U', 'V2UP', 'V3', 'ONLINE', 'UNL', 'ULTRA']
		);
		option.dependsOn = 'peuwatermark';
		addOption(option);

		option = new Option(
			Language.getPhrase('peu_loading_style',      'P.E.U Loading Screen Style:'),
			Language.getPhrase('peu_loading_style_desc', 'Select the loading screen style P.E.U will use.'),
			'peuloadingscreenimage',
			STRING,
			['V1', 'V2', 'V2U', 'ONLINE']
		);
		option.dependsOn = 'peuloadingscreen';
		addOption(option);

		option = new Option(
			Language.getPhrase('peu_disable_intro',      'Disable Intro'),
			Language.getPhrase('peu_disable_intro_desc', 'When enabled, disables the intro video played at game startup.'),
			'disableIntroVideo',
			'BOOL'
		);
		addOption(option);

		option = new Option(
			Language.getPhrase('peu_menu_theme',      'Menu Theme:'),
			Language.getPhrase('peu_menu_theme_desc', 'Select the theme for the menus.'),
			'menuTheme',
			STRING,
			['V3', Language.getPhrase('peu_theme_turkey', 'Türkiye'), Language.getPhrase('peu_theme_original', 'Original'), 'V1']
		);
		addOption(option);
		
		option = new Option(
			Language.getPhrase('peu_ultramodsystem',      'Ultra Mod System'),
			Language.getPhrase('peu_ultramodsystem_desc', 'if enabled, the Ultra Mode system is used and becomes more compatible with the Psych Engine Ultra'),
			'ultraModSystem',
			'BOOL'
		);
		addOption(option);
		
		option = new Option(
			Language.getPhrase('peu_menu_theme',      'Recording Quality:'),
			Language.getPhrase('peu_menu_theme_desc', 'Kayıt kalitesini seçin.'),
			'menuTheme',
			STRING,
			["More Performance", "Balanced", "Highest Quality"]
		);
		addOption(option);

		super();
	}
}