package options;

class MainMenuSettingsState extends CategoryOptionsMenu
{
	override function create()
	{
		title    = Language.getPhrase('menu_settings_title', 'Ana Menü Ayarları');
		rpcTitle = 'Ana Menü Ayarları';

		var catSidePanel = new OptionCategory(
			Language.getPhrase('menu_cat_side_panel',      'Sol Panel Ayarları'),
			Language.getPhrase('menu_cat_side_panel_desc', 'Ana menünün sol tarafındaki profil, istatistik ve son oynanan panelleri.')
		);

		catSidePanel.addOption(new Option(
			Language.getPhrase('menu_opt_profile',      'Profil Paneli'),
			Language.getPhrase('menu_opt_profile_desc', 'Sol üstteki isim, ikon, seviye ve XP barını gösterir.'),
			'showProfilePanel', BOOL));

		catSidePanel.addOption(new Option(
			Language.getPhrase('menu_opt_stats',      'İstatistik Paneli'),
			Language.getPhrase('menu_opt_stats_desc', 'Toplam skor, oynanan şarkı sayısı ve doğruluk oranını gösterir.'),
			'showStatsPanel', BOOL));

		catSidePanel.addOption(new Option(
			Language.getPhrase('menu_opt_last_played',      'Son Oynanan Paneli'),
			Language.getPhrase('menu_opt_last_played_desc', 'En son oynanan şarkıyı ve skorunu gösterir.'),
			'showLastPlayedPanel', BOOL));

		addCategory(catSidePanel);

		var catTopBar = new OptionCategory(
			Language.getPhrase('menu_cat_top_bar',      'Üst Bar Ayarları'),
			Language.getPhrase('menu_cat_top_bar_desc', 'Ekranın üstündeki saat, tarih ve selamlama yazılarını özelleştir.')
		);

		catTopBar.addOption(new Option(
			Language.getPhrase('menu_opt_clock',      'Saat & Tarih'),
			Language.getPhrase('menu_opt_clock_desc', 'Üst sağdaki saat ve tarih göstergesini açar/kapatır.'),
			'showClock', BOOL));

		catTopBar.addOption(new Option(
			Language.getPhrase('menu_opt_greeting',      'Selamlama Yazısı'),
			Language.getPhrase('menu_opt_greeting_desc', '"Günaydın, Oyuncu!" gibi karşılama metnini gösterir.'),
			'showGreeting', BOOL));

		addCategory(catTopBar);

		var catBottomBar = new OptionCategory(
			Language.getPhrase('menu_cat_bottom_bar',      'Alt Bar Ayarları'),
			Language.getPhrase('menu_cat_bottom_bar_desc', 'Ekranın altındaki duyuru şeridini ve sürüm yazısını yönet.')
		);

		catBottomBar.addOption(new Option(
			Language.getPhrase('menu_opt_news',      'Duyuru Şeridi'),
			Language.getPhrase('menu_opt_news_desc', 'Altta kayan duyuru/haber metnini gösterir.'),
			'showNewsBar', BOOL));

		catBottomBar.addOption(new Option(
			Language.getPhrase('menu_opt_version',      'Sürüm Yazısı'),
			Language.getPhrase('menu_opt_version_desc', 'Sağ alttaki sürüm numarasını gösterir.'),
			'showVersionText', BOOL));

		addCategory(catBottomBar);

		var catBG = new OptionCategory(
			Language.getPhrase('menu_cat_bg',      'Arka Plan Efektleri'),
			Language.getPhrase('menu_cat_bg_desc', 'Parçacıklar, yüzen küreler ve grid arka planı gibi görsel efektler.')
		);

		catBG.addOption(new Option(
			Language.getPhrase('menu_opt_particles',      'Parçacık Efekti'),
			Language.getPhrase('menu_opt_particles_desc', 'Arka planda yükselen küçük parçacıkları gösterir.'),
			'showParticles', BOOL));

		catBG.addOption(new Option(
			Language.getPhrase('menu_opt_orbs',      'Yüzen Küreler'),
			Language.getPhrase('menu_opt_orbs_desc', 'Arka planda yavaşça hareket eden parlak küreleri gösterir.'),
			'showFloatingOrbs', BOOL));

		catBG.addOption(new Option(
			Language.getPhrase('menu_opt_grid',      'Grid Arka Planı'),
			Language.getPhrase('menu_opt_grid_desc', 'Arka plandaki hareketli grid desenini gösterir.'),
			'showGridBG', BOOL));

		catBG.addOption(new Option(
			Language.getPhrase('menu_opt_scanlines',      'Tarama Çizgileri'),
			Language.getPhrase('menu_opt_scanlines_desc', 'Ekranda hareket eden ince yatay tarama çizgilerini gösterir.'),
			'showScanlines', BOOL));

		catBG.addOption(new Option(
			Language.getPhrase('menu_opt_parallax',      'Paralaks Efekti'),
			Language.getPhrase('menu_opt_parallax_desc', 'Fareyle arka planın hafifçe hareket etmesini sağlar.'),
			'showParallax', BOOL));

		addCategory(catBG);

		var catVideo = new OptionCategory(
			Language.getPhrase('menu_cat_video',      'Menü Videosu'),
			Language.getPhrase('menu_cat_video_desc', 'Ana menü arka planı yerine özel bir video oynat.')
		);

		catVideo.addOption(new Option(
			Language.getPhrase('menu_opt_menu_video',      'Menü Videosu'),
			Language.getPhrase('menu_opt_menu_video_desc', 'Açık olduğunda arka plan resmi yerine video oynatılır.'),
			'menuVideo', BOOL));

		var optMenuVideoPath = new Option(
			Language.getPhrase('menu_opt_video_path',      'Video Konumu'),
			Language.getPhrase('menu_opt_video_path_desc', 'Oynatılacak video dosyasının yolu. (.mp4 önerilir)'),
			'menuVideoPath', FILE);
		optMenuVideoPath.options   = ['.mp4'];
		optMenuVideoPath.dependsOn = 'menuVideo';
		catVideo.addOption(optMenuVideoPath);

		addCategory(catVideo);

		buildMenu();
		super.create();
	}
}