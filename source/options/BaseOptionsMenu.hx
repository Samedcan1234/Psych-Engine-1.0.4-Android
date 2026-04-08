package options;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import objects.CheckboxThingie;
import objects.FileSelector;
import objects.AttachedText;
import options.Option;
import backend.InputFormatter;

class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var fileSelectorGroup:FlxTypedGroup<FileSelector>;
	private var grpTexts:FlxTypedGroup<AttachedText>;
	private var optionCards:FlxTypedGroup<FlxSprite>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;
	public var bg:FlxSprite;
	
	var bgGradient:FlxSprite;
	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var sidePanel:FlxSprite;
	var titleText:FlxText;
	var categoryIcon:FlxSprite;
	var scrollIndicator:FlxSprite;
	var particleEmitter:FlxEmitter;
	var glowEffect:FlxSprite;
	var bgDarken:FlxSprite;
	
	var cPressed:Bool = false;
	
	var animTimer:Float = 0;
	var pulseTimer:Float = 0;
	
	var categoryColors:Map<String, Array<Int>> = [
		'Note Colors' => [0xFF666666, 0xFF888888],
		'Controls' => [0xFFE0A32A, 0xFFFF9900],
		'Delay & Combo' => [0xFFAA0044, 0xFFFF0066],
		'Graphics & Performance' => [0xFF31B0D1, 0xFF00CCFF],
		'Interface & Visuals' => [0xFF8D58FD, 0xFFAA77FF],
		'Gameplay' => [0xFF58FD69, 0xFF77FF88],
		'Language' => [0xFFFFD700, 0xFFFFEE00]
	];
	
	static inline var LOCKED_COLOR:Int   = 0xFF888888;
	static inline var UNLOCKED_COLOR:Int = 0xFFFFFFFF;

	public function new()
	{
		super();

		if(title == null) title = Language.getPhrase('base_options_title', 'Settings');
		if(rpcTitle == null) rpcTitle = 'Settings Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.3));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.4;
		bg.scrollFactor.set(0.05, 0.05);
		add(bg);
		
		var colors = categoryColors.exists(title) ? categoryColors.get(title) : [0xFF1a1a2e, 0xFF16213e];
		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width,
			FlxG.height,
			colors.concat([0xFF0a0a0a]),
			1, 90
		);
		bgGradient.alpha = 0;
		bgGradient.scrollFactor.set();
		add(bgGradient);
		
		bgDarken = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bgDarken.alpha = 0;
		bgDarken.scrollFactor.set();
		add(bgDarken);
		
		FlxTween.tween(bgDarken, {alpha: 0.4}, 0.6, {ease: FlxEase.quartOut});
		
		createParticleSystem();
		
		glowEffect = new FlxSprite(FlxG.width / 2 - 400, FlxG.height / 2 - 400);
		glowEffect.makeGraphic(800, 800, FlxColor.WHITE);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		glowEffect.scrollFactor.set();
		add(glowEffect);
		
		FlxTween.tween(glowEffect, {alpha: 0.06}, 0.8, {ease: FlxEase.quartOut});

		topBar = new FlxSprite(0, -150).makeGraphic(FlxG.width, 130, 0xDD000000);
		topBar.scrollFactor.set();
		add(topBar);
		
		FlxTween.tween(topBar, {y: 0}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.1});
		
		titleText = new FlxText(60, 35, FlxG.width - 120, title, 52);
		titleText.setFormat(Paths.font("vcr.ttf"), 52, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, colors[0]);
		titleText.borderSize = 3;
		titleText.scrollFactor.set();
		titleText.alpha = 0;
		add(titleText);
		
		FlxTween.tween(titleText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.3});
		
		var subtitleText:FlxText = new FlxText(60, 90, FlxG.width - 120,
			Language.getPhrase('base_options_hint',
				'Up / Down = Navigate  |  ENTER = Select  |  R = Reset  |  ESC = Back'), 22);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFCCCCCC, LEFT);
		subtitleText.scrollFactor.set();
		subtitleText.alpha = 0;
		add(subtitleText);
		
		FlxTween.tween(subtitleText, {alpha: 0.7}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.5});

		sidePanel = FlxGradient.createGradientFlxSprite(
			350,
			FlxG.height,
			[0x66000000, 0x00000000],
			1, 0
		);
		sidePanel.x = -350;
		sidePanel.scrollFactor.set();
		add(sidePanel);
		
		FlxTween.tween(sidePanel, {x: 0}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.2});
		
		var decorLine:FlxSprite = new FlxSprite(40, 130).makeGraphic(4, FlxG.height - 260, FlxColor.WHITE);
		decorLine.alpha = 0.2;
		decorLine.scrollFactor.set();
		add(decorLine);

		optionCards = new FlxTypedGroup<FlxSprite>();
		add(optionCards);
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);
		
		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);
		
		fileSelectorGroup = new FlxTypedGroup<FileSelector>();
		add(fileSelectorGroup);

		bottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 160, 0xDD000000);
		bottomBar.scrollFactor.set();
		add(bottomBar);
		
		FlxTween.tween(bottomBar, {y: FlxG.height - 160}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.3});
		
		descBox = new FlxSprite(30, FlxG.height - 140).makeGraphic(FlxG.width - 60, 120, 0x88000000);
		descBox.scrollFactor.set();
		descBox.alpha = 0;
		add(descBox);
		
		FlxTween.tween(descBox, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.8});

		descText = new FlxText(50, FlxG.height - 130, FlxG.width - 100, "", 26);
		descText.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2;
		descText.alpha = 0;
		add(descText);
		
		FlxTween.tween(descText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 1});

		scrollIndicator = new FlxSprite(FlxG.width - 40, FlxG.height / 2 - 50).makeGraphic(30, 100, FlxColor.WHITE);
		scrollIndicator.alpha = 0.3;
		scrollIndicator.scrollFactor.set();
		add(scrollIndicator);

		for (i in 0...optionsArray.length)
		{
			var card:FlxSprite = new FlxSprite(0, 0).makeGraphic(800, 100, 0x66000000);
			card.ID = i;
			card.alpha = 0;
			card.scrollFactor.set();
			optionCards.add(card);
			
			var optionText:Alphabet = new Alphabet(90, 180, optionsArray[i].name, false);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.alpha = 0;
			optionText.scrollFactor.set();
			grpOptions.add(optionText);

			if(optionsArray[i].type == BOOL)
			{
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, Std.string(optionsArray[i].getValue()) == 'true');
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkbox.alpha = 0;
				checkbox.scrollFactor.set();
				checkboxGroup.add(checkbox);
			}
			else if(optionsArray[i].type == FILE)
			{
				var fileSelector:FileSelector = new FileSelector(optionText.x - 105, optionText.y, Std.string(optionsArray[i].getValue()));
				fileSelector.sprTracker = optionText;
				fileSelector.optionID = i;
				fileSelector.alpha = 0;
				fileSelector.scrollFactor.set();
				fileSelectorGroup.add(fileSelector);
			}
			else
			{
				optionText.x -= 80;
				optionText.startPosition.x -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 80);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				valueText.alpha = 0;
				valueText.scrollFactor.set();
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			
			updateTextFrom(optionsArray[i]);
			
			FlxTween.tween(card, {alpha: 0.7}, 0.4, {
				ease: FlxEase.quartOut,
				startDelay: 0.6 + (i * 0.05)
			});
			FlxTween.tween(optionText, {alpha: 1}, 0.4, {
				ease: FlxEase.quartOut,
				startDelay: 0.65 + (i * 0.05)
			});
		}

		changeSelection();
		reloadCheckboxes();
		
		addTouchPad('LEFT_FULL', 'A_B_C');
	}
	
	function createParticleSystem()
	{
		particleEmitter = new FlxEmitter(FlxG.width / 2, 100, 40);
		particleEmitter.width = FlxG.width;
		
		for (i in 0...40)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(3, 3, FlxColor.WHITE);
			particle.exists = false;
			particleEmitter.add(particle);
		}
		
		particleEmitter.launchMode = FlxEmitterMode.SQUARE;
		particleEmitter.velocity.set(-30, 80, 30, 200);
		particleEmitter.lifespan.set(3, 6);
		particleEmitter.alpha.set(0.2, 0.4, 0, 0);
		particleEmitter.scale.set(1, 1.5, 0.5, 0.5);
		particleEmitter.start(false, 0.08);
		
		add(particleEmitter);
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		animTimer += elapsed;
		pulseTimer += elapsed;
		
		if (bg != null) {
			bg.angle = Math.sin(animTimer * 0.3) * 2;
		}
		
		if (glowEffect != null) {
			glowEffect.alpha = 0.06 + Math.sin(pulseTimer * 2) * 0.03;
			glowEffect.angle += elapsed * 15;
		}
		
		if (scrollIndicator != null && optionsArray.length > 0)
		{
			var progress:Float = curSelected / (optionsArray.length - 1);
			var indicatorY:Float = 180 + (progress * (FlxG.height - 420));
			scrollIndicator.y = FlxMath.lerp(scrollIndicator.y, indicatorY, elapsed * 10);
		}

		var startY:Float = 200;
		var spacing:Float = 105;
		var centerX:Float = (FlxG.width - 800) / 2;

		for (num => item in grpOptions.members)
		{
			var targetY:Float = startY + ((num - curSelected) * spacing);
			item.y = FlxMath.lerp(item.y, targetY, elapsed * 10);
			item.x = FlxMath.lerp(item.x, centerX + 110, elapsed * 10);
		
			var card = optionCards.members[num];
			if (card != null)
			{
				card.x = item.x - 40;
				card.y = item.y + 25;
				card.scale.x = item.scale.x;
				card.scale.y = item.scale.y;
			
				if (num == curSelected)
				{
					card.alpha = FlxMath.lerp(card.alpha, 1, elapsed * 10);
				}
				else
				{
					card.alpha = FlxMath.lerp(card.alpha, 0.5, elapsed * 10);
				}
			}
		}

		if(bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxTween.tween(bgGradient, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(bgDarken, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(topBar, {y: -150}, 0.3, {ease: FlxEase.backIn});
			FlxTween.tween(bottomBar, {y: FlxG.height}, 0.3, {ease: FlxEase.backIn});
			
			for (card in optionCards)
			{
				FlxTween.tween(card, {alpha: 0}, 0.2, {ease: FlxEase.quartIn});
			}
			
			new FlxTimer().start(0.3, function(tmr:FlxTimer) {
				close();
			});
			
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept <= 0)
		{
			switch(curOption.type)
			{
				case BOOL:
					if(controls.ACCEPT)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						curOption.setValue((curOption.getValue() == true) ? false : true);
						curOption.change();
						reloadCheckboxes();
						
						var item = grpOptions.members[curSelected];
						if (item != null)
						{
							FlxTween.cancelTweensOf(item.scale);
							item.scale.set(1.1, 1.1);
							FlxTween.tween(item.scale, {x: 1.05, y: 1.05}, 0.3, {ease: FlxEase.elasticOut});
						}
					}

				case KEYBIND:
					if(controls.ACCEPT)
					{
						bindingBlack = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
						bindingBlack.alpha = 0;
						bindingBlack.scrollFactor.set();
						FlxTween.tween(bindingBlack, {alpha: 0.8}, 0.35, {ease: FlxEase.quartOut});
						add(bindingBlack);
						
						bindingText = new Alphabet(FlxG.width / 2, 200,
							Language.getPhrase('base_options_binding', 'ASSIGNING KEY...'), false);
						bindingText.alignment = CENTERED;
						bindingText.alpha = 0;
						bindingText.scrollFactor.set();
						add(bindingText);
						FlxTween.tween(bindingText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.1});
						
						final escape:String = (controls.mobileC) ? "B" : "ESC";
						final backspace:String = (controls.mobileC) ? "C" : "Backspace";
						
						bindingText2 = new Alphabet(FlxG.width / 2, 380,
							curOption.name
							+ "\n\n" + Language.getPhrase('base_options_binding_cancel', 'ESC - Cancel')
							+ "\n"   + Language.getPhrase('base_options_binding_delete', 'BACKSPACE - Delete'), true);
						bindingText2.alignment = CENTERED;
						bindingText2.alpha = 0;
						bindingText2.scrollFactor.set();
						add(bindingText2);
						FlxTween.tween(bindingText2, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.2});

						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

				case FILE:
					if(controls.ACCEPT)
					{
						lime.app.Application.current.window.alert(
							Language.getPhrase('base_options_file_selected', 'FILE selected: ') + curOption.name, 'DEBUG');
						openFileSelector(curOption);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

				default:
					if (curOption.dependsOn != null && isOptionLocked(curOption))
					{
						if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
						{
							FlxG.sound.play(Paths.sound('cancelMenu'));

							var parentName:String = curOption.dependsOn;
							for (parentOpt in optionsArray)
							{
								if (parentOpt.variable == curOption.dependsOn)
								{
									parentName = parentOpt.name;
									break;
								}
							}

							var msg:String = Language.getPhrase(
								'opt_locked_msg',
								'"{1}" ayarını değiştirebilmek için önce "{2}" seçeneğini açmanız gerekiyor.'
							).replace('{1}', curOption.name).replace('{2}', parentName);

							AlertMsg.show(
								Language.getPhrase('opt_locked_title', 'Ayar Kilitli'),
								msg,
								4,
								AlertMsg.COLOR_WARNING
							);
						}
					}
					else
					{
						if(controls.UI_LEFT || controls.UI_RIGHT)
						{
							var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
							if(holdTime > 0.5 || pressed)
							{
								if(pressed)
								{
									var add:Dynamic = null;
									if(curOption.type != STRING)
										add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;

									switch(curOption.type)
									{
										case INT, FLOAT, PERCENT:
											holdValue = curOption.getValue() + add;
											if(holdValue < curOption.minValue) holdValue = curOption.minValue;
											else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
					
											if(curOption.type == INT)
											{
												holdValue = Math.round(holdValue);
												curOption.setValue(holdValue);
											}
											else
											{
												holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
												curOption.setValue(holdValue);
											}
					
										case STRING:
											var num:Int = curOption.curOption;
											if(controls.UI_LEFT_P) --num;
											else num++;
					
											if(num < 0)
												num = curOption.options.length - 1;
											else if(num >= curOption.options.length)
												num = 0;
					
											curOption.curOption = num;
											curOption.setValue(curOption.options[num]);

										default:
									}
									updateTextFrom(curOption);
									curOption.change();
									FlxG.sound.play(Paths.sound('scrollMenu'));
								}
								else if(curOption.type != STRING)
								{
									holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
					
									switch(curOption.type)
									{
										case INT:
											curOption.setValue(Math.round(holdValue));
										
										case PERCENT:
											curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));

										default:
									}
									updateTextFrom(curOption);
									curOption.change();
								}
							}
			
							if(curOption.type != STRING)
								holdTime += elapsed;
						}
						else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
						{
							if(holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
							holdTime = 0;
						}
					}
			}
			
			var cPressed:Bool = false;
			if (mobileManager.mobilePad != null && getMobilePadButton("buttonC") != null && mobilePadJustPressed("C")) {
				cPressed = true;
			}

			if(controls.RESET || cPressed)
			{
				var leOption:Option = optionsArray[curSelected];
				if(leOption.type != KEYBIND)
				{
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != BOOL)
					{
						if(leOption.type == STRING) leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!Controls.instance.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
				
				FlxG.camera.flash(FlxColor.WHITE, 0.2);
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function isOptionLocked(option:Option):Bool
	{
		if (option.dependsOn == null) return false;
		for (parentOpt in optionsArray)
		{
			if (parentOpt.variable == option.dependsOn)
				return Std.string(parentOpt.getValue()) != 'true';
		}
		return false;
	}

	function updateDependencyVisuals()
	{
		for (i in 0...optionsArray.length)
		{
			var opt = optionsArray[i];
			if (opt.dependsOn == null) continue;

			var locked:Bool = isOptionLocked(opt);
			var targetColor:Int = locked ? LOCKED_COLOR : UNLOCKED_COLOR;

			var optText = grpOptions.members[i];
			if (optText != null)
				optText.color = targetColor;

			if (opt.type == BOOL)
			{
				for (checkbox in checkboxGroup)
				{
					if (checkbox.ID == i)
					{
						checkbox.color = targetColor;
						break;
					}
				}
			}
			else
			{
				for (txt in grpTexts)
				{
					if (txt.ID == i)
					{
						txt.color = targetColor;
						break;
					}
				}
			}
		}
	}

	function bindingKeyUpdate(elapsed:Float)
	{
		if(mobilePadPressed("B") || FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (mobilePadPressed("C") || FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				if (!controls.controllerMode) curOption.keys.keyboard = NONE;
				else curOption.keys.gamepad = NONE;
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if(!controls.controllerMode)
			{
				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);
					if(keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if(keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
					keyPressed = LEFT_TRIGGER;
				else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					keyPressed = RIGHT_TRIGGER;
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if(gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if(keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if(keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if(keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if(changed)
			{
				var key:String = null;
				if(!controls.controllerMode)
				{
					if(curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if(curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	final MAX_KEYBIND_WIDTH = 320;
	function updateBind(?text:String = null, ?option:Option = null)
	{
		if(option == null) option = curOption;
		if(text == null)
		{
			text = option.getValue();
			if(text == null) text = 'NONE';

			if(!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		var bind:AttachedText = cast option.child;
		var attach:AttachedText = new AttachedText(text, bind.offsetX);
		attach.sprTracker = bind.sprTracker;
		attach.copyAlpha = true;
		attach.ID = bind.ID;
		attach.scrollFactor.set();
		playstationCheck(attach);
		attach.scaleX = Math.min(1, MAX_KEYBIND_WIDTH / attach.width);
		attach.x = bind.x;
		attach.y = bind.y;

		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(!controls.controllerMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		
		if(model == PS4 && alpha.letters != null && alpha.letters.length > 0)
		{
			var letter = alpha.letters[0];
			if(letter != null)
			{
				switch(alpha.text)
				{
					case '[', ']':
						letter.image = 'alphabet_playstation';
						letter.updateHitbox();
						
						letter.offset.x += 4;
						letter.offset.y -= 5;
				}
			}
		}
	}

	function closeBinding()
	{
		bindingKey = false;
		
		FlxTween.tween(bindingBlack, {alpha: 0}, 0.3, {
			onComplete: function(twn:FlxTween) {
				bindingBlack.destroy();
				remove(bindingBlack);
			}
		});
		
		FlxTween.tween(bindingText, {alpha: 0}, 0.3, {
			onComplete: function(twn:FlxTween) {
				bindingText.destroy();
				remove(bindingText);
			}
		});
		
		FlxTween.tween(bindingText2, {alpha: 0}, 0.3, {
			onComplete: function(twn:FlxTween) {
				bindingText2.destroy();
				remove(bindingText2);
			}
		});
		
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option) {
		if(option.type == KEYBIND)
		{
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);

		descText.text = optionsArray[curSelected].description;
		
		FlxTween.cancelTweensOf(descText);
		descText.alpha = 0;
		FlxTween.tween(descText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
				FlxTween.cancelTweensOf(item.scale);
				item.scale.set(1, 1);
				FlxTween.tween(item.scale, {x: 1.05, y: 1.05}, 0.2, {ease: FlxEase.backOut});
			}
			else
			{
				if (item.scale.x > 0.85)
				{
					FlxTween.cancelTweensOf(item.scale);
					FlxTween.tween(item.scale, {x: 0.85, y: 0.85}, 0.2, {ease: FlxEase.quartOut});
				}
				else {
					item.scale.set(0.85, 0.85);
				}
			}
		}
		
		for (text in grpTexts)
		{
			text.alpha = 0.6;
			if(text.ID == curSelected) text.alpha = 1;
		}

		curOption = optionsArray[curSelected];
		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateDependencyVisuals();
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
			checkbox.daValue = Std.string(optionsArray[checkbox.ID].getValue()) == 'true';

		updateDependencyVisuals();
	}

	function openFileSelector(option:Option)
	{
		var fileExtension:String = '';
		if(option.options != null && option.options.length > 0)
			fileExtension = option.options[0];

		StorageUtil.openFilePicker(fileExtension, function(result:String)
		{
			option.setValue(result);
			for (fs in fileSelectorGroup)
			{
				if (fs.optionID == curSelected)
				{
					fs.selectedPath = result;
					break;
				}
			}
			option.change();
			FlxG.sound.play(Paths.sound('confirmMenu'));
		});
	}

	function openFileSelectorWindows(option:Option, initialDir:String, fileExtension:String)
	{
		#if sys
		try
		{
			var psPath:String = null;
			var candidates:Array<String> = [
				'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
				'C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe',
				'C:\\Program Files\\PowerShell\\7\\pwsh.exe',
				'C:\\Program Files (x86)\\PowerShell\\7\\pwsh.exe'
			];
			for (c in candidates)
			{
				if (sys.FileSystem.exists(c)) { psPath = c; break; }
			}
			if (psPath == null)
			{
				CoolUtil.showPopUp(
					Language.getPhrase('base_options_ps_not_found', 'PowerShell not found!\nPlease enter the path manually.'),
					Language.getPhrase('base_options_error', 'ERROR'));

				return;
			}
			var filterStr:String = fileExtension != ''
				? 'Video (*' + fileExtension + ')|*' + fileExtension + '|Tum Dosyalar (*.*)|*.*'
				: 'Tum Dosyalar (*.*)|*.*';

			var script:String =
				'[void][System.Reflection.Assembly]::LoadWithPartialName(\'System.windows.forms\');' +
				'$$f = New-Object System.Windows.Forms.OpenFileDialog;' +
				'$$f.Title = \'Video Dosyasi Sec\';' +
				(fileExtension != '' ? '$$f.Filter = \'' + filterStr + '\';' : '') +
				'$$form = New-Object System.Windows.Forms.Form;' +
				'$$form.TopMost = $$true;' +
				'if ($$f.ShowDialog($$form) -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $$f.FileName } else { Write-Output \'\' }';

			var process = new sys.io.Process(psPath, ['-NoProfile', '-NonInteractive', '-Command', script]);
			var result:String = process.stdout.readAll().toString().trim();
			var exitCode:Int = process.exitCode();
			process.close();

			if (result != null && result.length > 0 && result != '0')
			{
				option.setValue(result);
				for (fs in fileSelectorGroup)
				{
					if (fs.optionID == curSelected)
					{
						fs.selectedPath = result;
						break;
					}
				}
				option.change();
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		catch (e:Dynamic)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		#end
	}

	function openFileSelectorAndroid(option:Option, fileExtension:String)
	{
		#if android
		var browser = new objects.AndroidFileBrowser(fileExtension);

		browser.onFileSelected = function(path:String)
		{
			option.setValue(path);

			for (fs in fileSelectorGroup)
			{
				if (fs.optionID == curSelected)
				{
					fs.selectedPath = path;
					break;
				}
			}

			option.change();
			FlxG.sound.play(Paths.sound('confirmMenu'));
		};

		browser.onCancel = function()
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
		};

		openSubState(browser);
		#end
	}

	#if android
	function findFileInDirectory(path:String, extension:String):String
	{
		#if sys
		try
		{
			if(!sys.FileSystem.exists(path))
				return '';
			
			var files = sys.FileSystem.readDirectory(path);
			for(file in files)
			{
				if(file.endsWith(extension))
					return path + '/' + file;
			}
		}
		catch(e:Dynamic)
		{
			trace('Klasor okuma hatasi ($path): $e');
		}
		#end
		return '';
	}
	#end

	function openFileSelectorLinux(option:Option, initialDir:String, fileExtension:String)
	{
		#if sys
		var process:sys.io.Process = null;
		try
		{
			var cmd = 'zenity';
			var args = ['--file-selection', '--title=Dosya Sec'];
			
			if(fileExtension != '')
				args.push('--file-filter=Dosya (*' + fileExtension + ')|*' + fileExtension);
			
			process = new sys.io.Process(cmd, args);
			var result:String = process.stdout.readAll().toString().trim();
			
			if(result != '' && result != '0')
			{
				option.setValue(result);
				if(option.type == FILE)
				{
					var fileSelector:FileSelector = null;
					for(fs in fileSelectorGroup)
					{
						if(fs.optionID == curSelected)
						{
							fileSelector = fs;
							break;
						}
					}
					if(fileSelector != null)
						fileSelector.selectedPath = result;
				}
				option.change();
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		catch(e:Dynamic)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			trace('Linux dosya secici hatasi: $e');
		}
		#end
	}

	function openFileSelectorMac(option:Option, initialDir:String, fileExtension:String)
	{
		#if sys
		var process:sys.io.Process = null;
		try
		{
			var filterStr = '';
			if(fileExtension != '')
				filterStr = ' of type {"' + fileExtension.replace('.', '') + '"}';
			
			var script = 'choose file' + filterStr;
			process = new sys.io.Process('osascript', ['-e', 'tell application "System Events" to activate', '-e', script]);
			var result:String = process.stdout.readAll().toString().trim();
			
			if(result != '' && result != '0')
			{
				option.setValue(result);
				if(option.type == FILE)
				{
					var fileSelector:FileSelector = null;
					for(fs in fileSelectorGroup)
					{
						if(fs.optionID == curSelected)
						{
							fileSelector = fs;
							break;
						}
					}
					if(fileSelector != null)
						fileSelector.selectedPath = result;
				}
				option.change();
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		catch(e:Dynamic)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			trace('macOS dosya secici hatasi: $e');
		}
		#end
	}
}
