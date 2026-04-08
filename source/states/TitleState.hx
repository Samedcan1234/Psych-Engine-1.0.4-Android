package states;

import backend.WeekData;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

#if VIDEOS_ALLOWED
import objects.VideoSprite;
#end

import shaders.ColorSwap;

import states.StoryMenuState;
import states.MainMenuState;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

typedef TitleData =
{
	var titlex:Float;
	var titley:Float;
	var startx:Float;
	var starty:Float;
	var gfx:Float;
	var gfy:Float;
	var backgroundSprite:String;
	var bpm:Float;
	
	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Bool;
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	// P.E.T INTRO
	public static var inGame:Bool = false;
	var skipVideoText:FlxText;
	
	public static var initialized:Bool = false;

	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var extraSprites:Array<FlxSprite> = [];

	var blackScreen:FlxSprite;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;
	
	#if VIDEOS_ALLOWED
	var currentVideo:VideoSprite = null;
	#end

	var logoTweenFinished:Bool = false;

	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = [
		'SHADOW', 'RIVEREN', 'BBPANZU', 'PESSY'
	];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		if(!initialized)
		{
			ClientPrefs.loadPrefs();
			Language.reloadPhrases();
			MobileConfig.init('MobileControls', CoolUtil.getSavePath(), 'assets/shared/mobile/',
				[
					['MobilePad/DPadModes', ButtonModes.DPAD],
					['MobilePad/ActionModes', ButtonModes.ACTION],
					['Hitbox/HitboxModes', ButtonModes.HITBOX]
				]
			);
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
			startCutscenesIn();
		#end
	}
	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
	
	function startCutscenesIn()
	{
		trace("=== startCutscenesIn called ===");
		trace("inGame: " + inGame);
		trace("initialized: " + initialized);
		#if VIDEOS_ALLOWED
		trace("VIDEOS_ALLOWED is defined");
		if (ClientPrefs.data.disableIntroVideo) {
			trace("disableIntroVideo is TRUE, skipping video");
			startIntro();
			return;
		}
		trace("Starting video...");
		startVideo('pet');
		#else
		trace("VIDEOS_ALLOWED is NOT defined");
		startIntro();
		#end
	}

	function startCutscenesOut()
	{
		inGame = true;
		startIntro();
	}
	
	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		trace("========== VIDEO START ==========");
		trace("Video name: " + name);
		trace("Video path: " + Paths.video(name));
		trace("File exists: " + openfl.Assets.exists(Paths.video(name)));
		trace("inGame: " + inGame);
		trace("initialized: " + initialized);
		trace("ClientPrefs.data.disableIntroVideo: " + ClientPrefs.data.disableIntroVideo);

		var videoPath = Paths.video(name);
		if(videoPath == null || videoPath.length == 0) {
			trace("ERROR: Video path is null or empty!");
			startIntro();
			return;
		}

		if(!openfl.Assets.exists(videoPath) && !sys.FileSystem.exists(videoPath)) {
			trace("ERROR: Video file does not exist at path: " + videoPath);
			startIntro();
			return;
		}

		trace("Creating VideoSprite...");
		currentVideo = new VideoSprite(videoPath, false, true);
		trace("VideoSprite created: " + currentVideo);

		currentVideo.finishCallback = function() {
			trace("Video bitti! finishCallback çalıştı.");
			videoEnd();
		};

		trace("Adding VideoSprite to scene...");
		add(currentVideo);

		trace("Playing video...");
		currentVideo.play();
		trace("========== VIDEO SETUP COMPLETE ==========");
		#else
		trace("VIDEOS_ALLOWED not defined, skipping to startIntro");
		startIntro();
		#end
	}

	public function videoEnd()
	{
		trace("videoEnd() called!");

		if(currentVideo != null) {
			currentVideo.finishCallback = null;
			currentVideo.destroy();
			currentVideo = null;
		}

		startCutscenesOut();
	}

	function startIntro()
	{
		persistentUpdate = true;
		if (!initialized && FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		loadJsonData();
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end
		Conductor.bpm = musicBPM;
		
		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');

		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		logoBl.alpha = 0;
		logoBl.scale.set(0.1, 0.1);

		gfDance = new FlxSprite(gfPosition.x, gfPosition.y);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;
		
		if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}
		
		gfDance.frames = Paths.getSparrowAtlas(characterImage);
		if(!useIdle)
		{
			gfDance.animation.addByIndices('danceLeft', animationName, danceLeftFrames, "", 24, false);
			gfDance.animation.addByIndices('danceRight', animationName, danceRightFrames, "", 24, false);
			gfDance.animation.play('danceRight');
		}
		else
		{
			gfDance.animation.addByPrefix('idle', animationName, 24, false);
			gfDance.animation.play('idle');
		}

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();

		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		add(gfDance);
		add(logoBl);
		add(titleText);
		add(credGroup);
		add(ngSpr);

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	var characterImage:String = 'gfDanceTitle';
	var animationName:String = 'gfDance';

	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	
	var useIdle:Bool = false;
	var musicBPM:Float = 102;
	var danceLeftFrames:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var danceRightFrames:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

	function loadJsonData()
	{
		if(Paths.fileExists('images/gfDanceTitle.json', TEXT))
		{
			var titleRaw:String = Paths.getTextFromFile('images/gfDanceTitle.json');
			if(titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);
					gfPosition.set(titleJSON.gfx, titleJSON.gfy);
					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					musicBPM = titleJSON.bpm;
					
					if(titleJSON.animation != null && titleJSON.animation.length > 0) animationName = titleJSON.animation;
					if(titleJSON.dance_left != null && titleJSON.dance_left.length > 0) danceLeftFrames = titleJSON.dance_left;
					if(titleJSON.dance_right != null && titleJSON.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
					useIdle = (titleJSON.idle == true);
	
					if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0)
					{
						var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));
						bg.antialiasing = ClientPrefs.data.antialiasing;
						add(bg);
					}
				}
				catch(e:haxe.Exception)
				{
					trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
				}
			}
		}
	}

	function easterEggData()
	{
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = '';
		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		switch(easterEgg.toUpperCase())
		{
			case 'SHADOW':
				characterImage = 'ShadowBump';
				animationName = 'Shadow Title Bump';
				gfPosition.x += 210;
				gfPosition.y += 40;
				useIdle = true;
			case 'RIVEREN':
				characterImage = 'ZRiverBump';
				animationName = 'River Title Bump';
				gfPosition.x += 180;
				gfPosition.y += 40;
				useIdle = true;
			case 'BBPANZU':
				characterImage = 'BBBump';
				animationName = 'BB Title Bump';
				danceLeftFrames = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];
				danceRightFrames = [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
				gfPosition.x += 45;
				gfPosition.y += 100;
			case 'PESSY':
				characterImage = 'PessyBump';
				animationName = 'Pessy Title Bump';
				gfPosition.x += 165;
				gfPosition.y += 60;
				danceLeftFrames = [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
				danceRightFrames = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28];
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				pressedEnter = true;
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					ThemeManager.switchToMainMenu();
					closedState = true;
				});
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase();
						if (easterEggKeysBuffer.contains(word))
						{
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('secret'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
							black.scale.set(FlxG.width, FlxG.height);
							black.updateHitbox();
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});
							FlxG.sound.music.fadeOut();
							if(FreeplayState.vocals != null)
							{
								FreeplayState.vocals.fadeOut();
							}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			
			var targetY = (i * 60) + 200 + offset;
			money.y = targetY + 50; 
			money.alpha = 0;        
			
			if(credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}

			FlxTween.tween(money, {y: targetY, alpha: 1}, 0.5, {ease: FlxEase.expoOut});
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			
			var targetY = (textGroup.length * 60) + 200 + offset;
			coolText.y = targetY + 50; 
			coolText.alpha = 0;        
			
			credGroup.add(coolText);
			textGroup.add(coolText);

			FlxTween.tween(coolText, {y: targetY, alpha: 1}, 0.5, {ease: FlxEase.expoOut});
		}
	}

	function addIconToText(imagePath:String, isOnLeft:Bool = true, ?offsetY:Float = 0)
	{
		if (textGroup.length == 0) return;
		
		var targetText:Alphabet = cast textGroup.members[textGroup.length - 1];
		var icon:FlxSprite = new FlxSprite().loadGraphic(Paths.image(imagePath));
		icon.antialiasing = ClientPrefs.data.antialiasing;
		
		icon.setGraphicSize(Std.int(icon.width * 0.8));
		icon.updateHitbox();

		var targetX:Float = 0;
		if (isOnLeft)
			targetX = targetText.x - icon.width - 20;
		else
			targetX = targetText.x + targetText.width + 20;

		var targetY:Float = targetText.y + (targetText.height / 2) - (icon.height / 2) + offsetY;

		icon.x = targetX;
		icon.y = targetY + 50;
		icon.alpha = 0;

		credGroup.add(icon);
		extraSprites.push(icon);

		FlxTween.tween(icon, {y: targetY, alpha: 1}, 0.5, {ease: FlxEase.expoOut});
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}

		while(extraSprites.length > 0)
		{
			var spr:FlxSprite = extraSprites.shift();
			FlxTween.cancelTweensOf(spr); 
			credGroup.remove(spr, true);
			spr.destroy();
		}
	}

	private var sickBeats:Int = 0;
	public static var closedState:Bool = false;
	
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null && skippedIntro && logoTweenFinished)
		{
			logoBl.scale.set(1.05, 1.05); 
			
			FlxTween.cancelTweensOf(logoBl.scale);
			FlxTween.tween(logoBl.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
		}

		if(gfDance != null)
		{
			danceLeft = !danceLeft;
			if(!useIdle)
			{
				if (danceLeft)
					gfDance.animation.play('danceRight');
				else
					gfDance.animation.play('danceLeft');
			}
			else if(curBeat % 2 == 0) gfDance.animation.play('idle', true);
		}

		if(!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Psych Engine'], 40);
				case 4:
					addMoreText('Shadow Mario Tarafından', 40);
					addIconToText('credits/shadowmario', true); 
					addMoreText('Riveren', 40);
				case 5:
					deleteCoolText();
				case 6:
					ngSpr.visible = true;
					ngSpr.screenCenter(X);
					ngSpr.y = 20;
					ngSpr.alpha = 0;
					ngSpr.y += 80;
					FlxTween.tween(ngSpr, {y: 20, alpha: 1}, 2.5, {ease: FlxEase.expoOut});

				case 7:
					createCoolText(['Newgrounds', 'ile'], 140);

				case 8:
					addMoreText('AlakasI Yoktur', 160);

				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					var peuLogo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('pet/peulogo'));
					peuLogo.antialiasing = ClientPrefs.data.antialiasing;
					peuLogo.setGraphicSize(Std.int(FlxG.width * 0.25));
					peuLogo.updateHitbox();
					peuLogo.screenCenter(X);
					peuLogo.y = 20;
					peuLogo.alpha = 0;
					peuLogo.y += 80;
					credGroup.add(peuLogo);
					extraSprites.push(peuLogo);
					FlxTween.tween(peuLogo, {y: peuLogo.y - 10, alpha: 1}, 2.5, {ease: FlxEase.expoOut});

				case 15:
					createCoolText(['Psych Engine Ultra'], 250);

				case 16:
					addMoreText('SametGkTe TarafIndan', 280);
					addIconToText('credits/gkte', true, -40);

				case 17:
					deleteCoolText();
				case 18:
					addMoreText('Friday');
				case 19:
					addMoreText('Night');
				case 20:
					addMoreText('Funkin');
				case 21:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			#if TITLE_SCREEN_EASTER_EGG
			if (playJingle)
			{
				playJingle = false;
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVEREN':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));
					case 'PESSY':
						sound = FlxG.sound.play(Paths.sound('JinglePessy'));

					default:
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						
						startLogoTween();

						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 1.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						startLogoTween();
						transitioning = false;
					});
				}
				else
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					startLogoTween();
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
						#if ACHIEVEMENTS_ALLOWED
						if(easteregg == 'PESSY') Achievements.unlock('pessy_easter_egg');
						#end
					};
				}
			}
			else #end
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				startLogoTween();

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					FlxG.sound.music.fadeOut();
					if(FreeplayState.vocals != null)
					{
						FreeplayState.vocals.fadeOut();
					}
				}
				#end
			}
			skippedIntro = true;
		}
	}

	function startLogoTween()
	{
		if (logoBl != null)
		{
			logoBl.alpha = 0;
			logoBl.scale.set(0.1, 0.1);
			logoTweenFinished = false;

			FlxTween.tween(logoBl, {alpha: 1}, 1.2, {ease: FlxEase.quadOut});
			FlxTween.tween(logoBl.scale, {x: 1, y: 1}, 1.5, {
				ease: FlxEase.elasticOut,
				onComplete: function(twn:FlxTween) {
					logoTweenFinished = true; 
				}
			});
		}
	}

	override function destroy()
	{
		#if TOUCH_CONTROLS_ALLOWED
		removeTouchControls();
		#end
		
		super.destroy();
	}
}