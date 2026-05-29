package options;

class UltraSettingsState extends CategoryOptionsMenu
{
	override function create()
	{
		title    = 'Ultra Ayarlar';
		rpcTitle = 'Ultra Ayarlar Menüsü';

		var catMainMenu = new OptionCategory(
			'Ana Menü Ayarları',
			'Ana menü görünümü ve davranışıyla ilgili ayarlar.'
		);

		var optInfoBox = new Option(
			'Bilgi Kutucuğu',
			'Ana menüde bilgi kutucuğunu gösterir.',
			'mainMenuInfoBox',
			BOOL
		);
		catMainMenu.addOption(optInfoBox);

		var optBgAnim = new Option(
			'Arka Plan Animasyonu',
			'Ana menü arka plan animasyonunu etkinleştirir.',
			'mainMenuBgAnim',
			BOOL
		);
		catMainMenu.addOption(optBgAnim);

		var optBgSpeed = new Option(
			'Animasyon Hızı',
			'Arka plan animasyonunun hızını ayarlar.',
			'mainMenuBgSpeed',
			FLOAT
		);
		optBgSpeed.minValue    = 0.1;
		optBgSpeed.maxValue    = 5.0;
		optBgSpeed.changeValue = 0.1;
		optBgSpeed.decimals    = 1;
		optBgSpeed.displayFormat = '%v x';
		optBgSpeed.dependsOn   = 'mainMenuBgAnim'; 

		catMainMenu.addOption(optBgSpeed);

		addCategory(catMainMenu);

		var catModMenu = new OptionCategory(
			'Mod Menüsü Ayarları',
			'Mod menüsü görünümü ve sıralama seçenekleri.'
		);

		var optModSort = new Option(
			'Sıralama',
			'Modların listelenme sırasını belirler.',
			'modMenuSort',
			STRING,
			['A-Z', 'Z-A', 'Son Eklenen']
		);
		catModMenu.addOption(optModSort);

		var optModIcons = new Option(
			'Mod İkonları',
			'Mod listesinde ikon gösterir.',
			'modMenuIcons',
			BOOL
		);
		catModMenu.addOption(optModIcons);

		addCategory(catModMenu);

		var catFreeplay = new OptionCategory(
			'Serbest Oyun Menüsü Ayarları',
			'Serbest oyun menüsüne ait görsel ve davranış ayarları.'
		);

		var optFreeplayPreview = new Option(
			'Şarkı Önizleme',
			'Serbest oyun menüsünde şarkı önizlemesini oynatır.',
			'freeplayPreview',
			BOOL
		);
		catFreeplay.addOption(optFreeplayPreview);

		var optFreeplayVolume = new Option(
			'Önizleme Sesi',
			'Önizleme sesinin seviyesi.',
			'freeplayPreviewVolume',
			PERCENT
		);
		optFreeplayVolume.dependsOn = 'freeplayPreview'; 

		catFreeplay.addOption(optFreeplayVolume);

		addCategory(catFreeplay);

		buildMenu();

		super.create();
	}
}