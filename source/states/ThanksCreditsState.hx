package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.addons.display.FlxBackdrop;

class ThanksCreditsState extends MusicBeatState
{
	var creditsData:Array<Array<String>> = [];
	var creditItems:FlxTypedGroup<CreditItem>;
	var scrollSpeed:Float = 50; // Kaydırma hızı (piksel/saniye)
	
	var blackBG:FlxSprite;
	var endImage:FlxSprite; // Sonda gösterilecek resim
	var endImageShown:Bool = false;
	
	var skipText:FlxText;
	var canSkip:Bool = true;

	override function create()
	{
		super.create();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits Akışını İzliyor", null);
		#end

		// Siyah Arka Plan
		blackBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackBG);

		creditItems = new FlxTypedGroup<CreditItem>();
		add(creditItems);

		// Credits verilerini yükle
		loadCreditsData();
		
		// Credits öğelerini oluştur
		createCreditItems();

		// Skip Metni
		skipText = new FlxText(0, FlxG.height - 40, FlxG.width, "ESC ile çık | ENTER ile hızlandır", 20);
		skipText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		skipText.scrollFactor.set();
		skipText.alpha = 0.7;
		add(skipText);

		// YENİ: Son resmi SADECE RESİM OLARAK hazırla
		endImage = new FlxSprite();
		var endImagePath = 'pet/peulogo'; // assets/images/credits/thanks.png
		
		if(Paths.fileExists('images/$endImagePath.png', IMAGE))
		{
			endImage.loadGraphic(Paths.image(endImagePath));
		}
		else
		{
			// Eğer resim yoksa varsayılan placeholder oluştur
			trace("WARNING: credits/thanks.png bulunamadı! Lütfen ekleyin.");
			endImage.makeGraphic(1000, 600, 0xFF1a1a1a);

			var warningText = new FlxText(0, 0, 1000, "LÜTFEN\nassets/images/credits/thanks.png\nEKLEYİN", 48);
			warningText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			warningText.borderSize = 3;
			warningText.screenCenter();
			warningText.scrollFactor.set();
			warningText.alpha = 0;
			add(warningText);
			
			// Uyarı metnini de fade in yap
			FlxTween.tween(warningText, {alpha: 1}, 1.5, {ease: FlxEase.quartInOut, startDelay: 1});
		}
		
		// Aspect ratio koruyarak boyutlandır
		var maxWidth = FlxG.width * 0.85;
		var maxHeight = FlxG.height * 0.7;
		
		if(endImage.width > maxWidth || endImage.height > maxHeight)
		{
			var scaleX = maxWidth / endImage.width;
			var scaleY = maxHeight / endImage.height;
			var finalScale = Math.min(scaleX, scaleY);
			
			endImage.scale.set(finalScale, finalScale);
			endImage.updateHitbox();
		}
		
		endImage.screenCenter();
		endImage.alpha = 0;
		endImage.scrollFactor.set();
		endImage.antialiasing = ClientPrefs.data.antialiasing;
		add(endImage);

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
	}

	function loadCreditsData()
	{
		// CreditsState'deki aynı veriyi kullan
		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled)
		{
			var creditsFile:String = Paths.mods(mod + '/data/credits.txt');
			#if TRANSLATIONS_ALLOWED
			var translatedCredits:String = Paths.mods(mod + '/data/credits-${ClientPrefs.data.language}.txt');
			#end

			if (#if TRANSLATIONS_ALLOWED (sys.FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end sys.FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = sys.io.File.getContent(creditsFile).split('\n');
				for(i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if(arr.length >= 5)
					{
						creditsData.push(arr);
					}
				}
			}
		}
		#end

		if(creditsData.length == 0)
		{
			// Varsayılan credits
			pushDefaultCreditsData();
		}
	}

	function pushDefaultCreditsData()
	{
		creditsData.push(['SametGkTe', 'gkte', Language.getPhrase('credits_role_samet', 'Header Of And Creator Of Psych Engine Ultra'), 'https://tiktok.com/@gktegameplay', 'FFE7C0']);
		creditsData.push(['Nexus', 'nex', Language.getPhrase('credits_role_nexus', 'Translator Of Psych Engine Ultra'), 'https://tiktok.com/@skynexus.0.03', 'FFE7C0']);
		creditsData.push(['ArkoseLabs', 'arkoselabs', Language.getPhrase('credits_role_arkose', 'Mobile Porter & Co-Owner of Psych Ultra'), 'https://youtube.com/@arkoselabsofficial', 'FFE7C0']);
		creditsData.push(['emi3', 'puta', Language.getPhrase('credits_role_emi3', 'Spanish Ratings, İmages etc.'), 'https://gamebanana.com/members/1709917', '6FA8DC']);
		creditsData.push(['Shadow Mario', 'shadowmario', Language.getPhrase('credits_role_shadow', 'Main Programmer and Head of Psych Engine'), 'https://ko-fi.com/shadowmario', '444444']);
		creditsData.push(['Riveren', 'riveren', Language.getPhrase('credits_role_riveren', 'Main Artist/Animator of Psych Engine'), 'https://x.com/riverennn', '14967B']);
		creditsData.push(['bb-panzu', 'bb', Language.getPhrase('credits_role_bb', 'Ex-Programmer of Psych Engine'), 'https://x.com/bbsub3', '3E813A']);
		creditsData.push(['crowplexus', 'crowplexus', Language.getPhrase('credits_role_crow', 'Linux Support, HScript Iris, Input System v3, and Other PRs'), 'https://twitter.com/IamMorwen', 'CFCFCF']);
		creditsData.push(['Kamizeta', 'kamizeta', Language.getPhrase('credits_role_kami', 'Creator of Pessy, Psych Engine\'s mascot.'), 'https://www.instagram.com/cewweey/', 'D21C11']);
		creditsData.push(['MaxNeton', 'maxneton', Language.getPhrase('credits_role_maxneton', 'Loading Screen Easter Egg Artist/Animator.'), 'https://bsky.app/profile/maxneton.bsky.social', '3C2E4E']);
		creditsData.push(['Keoiki', 'keoiki', Language.getPhrase('credits_role_keoiki', 'Note Splash Animations and Latin Alphabet'), 'https://x.com/Keoiki_', 'D2D2D2']);
		creditsData.push(['SqirraRNG', 'sqirra', Language.getPhrase('credits_role_sqirra', 'Crash Handler and Base code for\nChart Editor\'s Waveform'), 'https://x.com/gedehari', 'E1843A']);
		creditsData.push(['EliteMasterEric', 'mastereric', Language.getPhrase('credits_role_eric', 'Runtime Shaders support and Other PRs'), 'https://x.com/EliteMasterEric', 'FFBD40']);
		creditsData.push(['MAJigsaw77', 'majigsaw', Language.getPhrase('credits_role_maj', '.MP4 Video Loader Library (hxvlc)'), 'https://x.com/MAJigsaw77', '5F5F5F']);
		creditsData.push(['iFlicky', 'flicky', Language.getPhrase('credits_role_flicky', 'Composer of Psync and Tea Time\nAnd some sound effects'), 'https://x.com/flicky_i', '9E29CF']);
		creditsData.push(['KadeDev', 'kade', Language.getPhrase('credits_role_kade', 'Fixed some issues on Chart Editor and Other PRs'), 'https://x.com/kade0912', '64A250']);
		creditsData.push(['superpowers04', 'superpowers04', Language.getPhrase('credits_role_super', 'LUA JIT Fork'), 'https://x.com/superpowers04', 'B957ED']);
		creditsData.push(['CheemsAndFriends', 'cheems', Language.getPhrase('credits_role_cheems', 'Creator of FlxAnimate'), 'https://x.com/CheemsnFriendos', 'E1E1E1']);
		creditsData.push(['ninjamuffin99', 'ninjamuffin99', Language.getPhrase('credits_role_ninja', "Programmer of Friday Night Funkin'"), 'https://x.com/ninja_muffin99', 'CF2D2D']);
		creditsData.push(['PhantomArcade', 'phantomarcade', Language.getPhrase('credits_role_phantom', "Animator of Friday Night Funkin'"), 'https://x.com/PhantomArcade3K', 'FADC45']);
		creditsData.push(['evilsk8r', 'evilsk8r', Language.getPhrase('credits_role_evil', "Artist of Friday Night Funkin'"), 'https://x.com/evilsk8r', '5ABD4B']);
		creditsData.push(['kawaisprite', 'kawaisprite', Language.getPhrase('credits_role_kawai', "Composer of Friday Night Funkin'"), 'https://x.com/kawaisprite', '378FC7']);
		creditsData.push([Language.getPhrase('credits_role_discord', 'Join the Psych Ward!'), 'discord', '', 'https://discord.gg/2ka77eMXDv', '5165F6']);
	}

	function createCreditItems()
	{
		var startY:Float = FlxG.height + 150; // Ekranın daha altından başla
		var spacing:Float = 400; // YENİ: Çok daha geniş boşluk (280'den 400'e)

		for(i in 0...creditsData.length)
		{
			var data = creditsData[i];
			
			// Header kontrolü
			if(data.length <= 1) continue;

			var item = new CreditItem(data[0], data[1], data[2]);
			item.y = startY + (i * spacing);
			item.screenCenter(X);
			creditItems.add(item);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var speed = scrollSpeed;
		
		// ENTER basılı tutulursa hızlan
		if(FlxG.keys.pressed.ENTER)
		{
			speed *= 3;
			skipText.text = "⚡ HIZLANDIRILIYOR! ⚡";
		}
		else
		{
			skipText.text = "ESC ile çık | ENTER ile hızlandır";
		}

		// Credits'leri yukarı kaydır
		if(!endImageShown)
		{
			creditItems.forEach(function(item:CreditItem) {
				item.y -= speed * elapsed;
				
				// YENİ: Ekran merkezine yakınlığa göre renk fade efekti
				updateCreditItemColor(item);
			});

			// En son öğe ekranın üstünden çıktıysa end image göster
			if(creditItems.length > 0)
			{
				var lastItem = creditItems.members[creditItems.members.length - 1];
				if(lastItem != null && lastItem.y + lastItem.height < -150)
				{
					showEndImage();
				}
			}
		}

		// ESC ile çık
		if(FlxG.keys.justPressed.ESCAPE && canSkip)
		{
			exitCredits();
		}
	}

	// YENİ: Credits öğelerinin rengini ekran pozisyonuna göre ayarla
	function updateCreditItemColor(item:CreditItem)
	{
		var centerY = FlxG.height / 2;
		var itemCenterY = item.y + (item.height / 2);
		
		// Ekran merkezinden uzaklık
		var distance = Math.abs(itemCenterY - centerY);
		var maxDistance = FlxG.height * 0.6; // Fade mesafesi
		
		// Alpha hesaplama (merkeze yaklaştıkça 1, uzaklaştıkça 0)
		var alpha = 1 - (distance / maxDistance);
		if(alpha < 0) alpha = 0;
		if(alpha > 1) alpha = 1;
		
		// Yumuşak geçiş için ease
		alpha = FlxEase.quadInOut(alpha);
		
		// Tüm öğelere alpha uygula
		item.alpha = alpha;
	}

	function showEndImage()
	{
		if(endImageShown) return;
		
		endImageShown = true;
		
		// Fade in efekti
		FlxTween.tween(endImage, {alpha: 1}, 2.0, { // 1.5'ten 2.0'a (daha yavaş)
			ease: FlxEase.quartInOut,
			onComplete: function(twn:FlxTween) {
				// 5 saniye bekle, sonra ana menüye dön
				new FlxTimer().start(5, function(tmr:FlxTimer) {
					exitCredits();
				});
			}
		});
	}

	function exitCredits()
	{
		canSkip = false;
		FlxG.camera.fade(FlxColor.BLACK, 0.8, false, function() {
			MusicBeatState.switchState(new MainMenuState());
		});
	}
}

// Credits öğesi sınıfı (İYİLEŞTİRİLMİŞ)
class CreditItem extends FlxSpriteGroup
{
	var icon:FlxSprite;
	var nameText:FlxText;
	var roleText:FlxText;

	public function new(name:String, iconName:String, role:String)
	{
		super();

		// İkon
		icon = new FlxSprite();
		var iconPath = 'credits/' + iconName;
		if(!Paths.fileExists('images/$iconPath.png', IMAGE)) 
			iconPath = 'credits/missing_icon';
		
		icon.loadGraphic(Paths.image(iconPath));
		
		// Aspect ratio koruyarak boyutlandırma
		var targetSize = 200; // 180'den 200'e (biraz daha büyük)
		var scale:Float = 1.0;
		
		// En büyük kenarı bul
		if(icon.width > icon.height)
		{
			scale = targetSize / icon.width;
		}
		else
		{
			scale = targetSize / icon.height;
		}
		
		icon.scale.set(scale, scale);
		icon.updateHitbox();
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		// İsim
		nameText = new FlxText(0, icon.y + icon.height + 30, FlxG.width, name, 56); // Font 52'den 56'ya
		nameText.setFormat(Paths.font("vcr.ttf"), 56, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 4;
		add(nameText);

		// Rol
		roleText = new FlxText(0, nameText.y + 70, FlxG.width, role, 36); // Font 34'ten 36'ya
		roleText.setFormat(Paths.font("vcr.ttf"), 36, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		roleText.borderSize = 2.8;
		add(roleText);

		// İkonu merkeze al
		icon.x = (FlxG.width / 2) - (icon.width / 2);
	}
}