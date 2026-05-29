package backend.ui;

import flixel.FlxObject;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;
import flash.events.KeyboardEvent;
import lime.system.Clipboard;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

enum abstract AccentCode(Int) from Int from UInt to Int to UInt {
	var NONE = -1;
	var GRAVE = 0;
	var ACUTE = 1;
	var CIRCUMFLEX = 2;
	var TILDE = 3;
}

enum abstract FilterMode(Int) from Int from UInt to Int to UInt {
	var NO_FILTER:Int = 0;
	var ONLY_ALPHA:Int = 1;
	var ONLY_NUMERIC:Int = 2;
	var ONLY_ALPHANUMERIC:Int = 3;
	var ONLY_HEXADECIMAL:Int = 4;
	var CUSTOM_FILTER:Int = 5;
}

enum abstract CaseMode(Int) from Int from UInt to Int to UInt {
	var ALL_CASES:Int = 0;
	var UPPER_CASE:Int = 1;
	var LOWER_CASE:Int = 2;
}

enum abstract InputType(Int) from Int to Int {
	var TEXT = 0;
	var EMAIL = 1;
	var NUMERIC = 2;
	var PASSWORD = 3;
}

enum abstract ValidationState(Int) from Int to Int {
	var NEUTRAL = 0;
	var VALID = 1;
	var INVALID = 2;
}

class PsychUIInputText extends FlxSpriteGroup {
	public static final CHANGE_EVENT = "inputtext_change";

	static final KEY_TILDE = 126;
	static final KEY_ACUTE = 180;

	// ══════════════════════════════════
	//  RENKLER
	// ══════════════════════════════════
	static inline final COL_BG = 0xFF080818;
	static inline final COL_BG_FOCUS = 0xFF0e0e24;
	static inline final COL_BORDER = 0xFF1a1a3a;
	static inline final COL_BORDER_FOCUS = 0xFFC084FC;
	static inline final COL_BORDER_VALID = 0xFF34D399;
	static inline final COL_BORDER_INVALID = 0xFFFF5252;
	static inline final COL_TEXT = 0xFFd4d4f0;
	static inline final COL_PLACEHOLDER = 0xFF4a4a70;
	static inline final COL_CARET = 0xFFC084FC;
	static inline final COL_SELECTION = 0xFF3d2d6b;
	static inline final COL_COUNTER = 0xFF4a4a70;
	static inline final COL_COUNTER_WARN = 0xFFFFD740;
	static inline final COL_COUNTER_FULL = 0xFFFF5252;
	static inline final COL_CLEAR_BTN = 0xFF4a4a70;
	static inline final COL_EYE_BTN = 0xFF4a4a70;

	public static var focusOn(default, set):PsychUIInputText = null;

	public var name:String;
	public var bg:FlxSprite;
	public var behindText:FlxSprite;
	public var selection:FlxSprite;
	public var textObj:FlxText;
	public var caret:FlxSprite;
	public var onChange:String->String->Void;

	// ══════════════════════════════════
	//  YENİ: Placeholder
	// ══════════════════════════════════
	public var placeholderObj:FlxText;
	public var placeholder(default, set):String = '';

	// ══════════════════════════════════
	//  YENİ: Focus ring / border
	// ══════════════════════════════════
	var borderTop:FlxSprite;
	var borderBottom:FlxSprite;
	var borderLeft:FlxSprite;
	var borderRight:FlxSprite;
	var accentLeft:FlxSprite;
	var _isFocused:Bool = false;
	var _focusGlow:Float = 0;

	// ══════════════════════════════════
	//  YENİ: Clear button (X)
	// ══════════════════════════════════
	public var showClearButton:Bool = true;
	var clearBtn:FlxText;

	// ══════════════════════════════════
	//  YENİ: Password toggle (göz)
	// ══════════════════════════════════
	public var showPasswordToggle:Bool = false;
	var eyeBtn:FlxText;
	var _passwordVisible:Bool = false;

	// ══════════════════════════════════
	//  YENİ: Validation
	// ══════════════════════════════════
	public var validationState(default, set):ValidationState = NEUTRAL;
	var validationIcon:FlxText;

	// ══════════════════════════════════
	//  YENİ: Character counter
	// ══════════════════════════════════
	public var showCharCounter:Bool = false;
	var charCounter:FlxText;

	// ══════════════════════════════════
	//  YENİ: Input type
	// ══════════════════════════════════
	public var inputType(default, set):InputType = TEXT;

	// ══════════════════════════════════
	//  YENİ: Undo/Redo
	// ══════════════════════════════════
	var _undoStack:Array<String> = [];
	var _redoStack:Array<String> = [];
	static inline final MAX_UNDO = 50;

	// ══════════════════════════════════
	//  YENİ: Tab order
	// ══════════════════════════════════
	public var tabNext:PsychUIInputText = null;
	public var tabPrev:PsychUIInputText = null;

	// ══════════════════════════════════
	//  YENİ: Callbacks
	// ══════════════════════════════════
	public var onFocusGained:Void->Void = null;
	public var onFocusLost:Void->Void = null;
	public var onValidate:String->ValidationState = null;

	// Mevcut alanlar
	public var fieldWidth(default, set):Int = 0;
	public var maxLength(default, set):Int = 0;
	public var passwordMask(default, set):Bool = false;
	public var text(default, set):String = null;
	public var forceCase(default, set):CaseMode = ALL_CASES;
	public var filterMode(default, set):FilterMode = NO_FILTER;
	public var customFilterPattern(default, set):EReg;
	public var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.WHITE);

	public function new(x:Float = 0, y:Float = 0, wid:Int = 100, ?text:String = '', size:Int = 8) {
		super(x, y);

		var h:Int = Std.int(size * 2.8);
		if (h < 24)
			h = 24;

		// ── Background ──
		this.bg = new FlxSprite().makeGraphic(wid + 2, h, COL_BG);
		add(this.bg);

		// ── Borders ──
		borderTop = new FlxSprite(0, 0).makeGraphic(wid + 2, 1, COL_BORDER);
		borderBottom = new FlxSprite(0, h - 1).makeGraphic(wid + 2, 1, COL_BORDER);
		borderLeft = new FlxSprite(0, 0).makeGraphic(1, h, COL_BORDER);
		borderRight = new FlxSprite(wid + 1, 0).makeGraphic(1, h, COL_BORDER);
		add(borderTop);
		add(borderBottom);
		add(borderLeft);
		add(borderRight);

		// ── Left accent ──
		accentLeft = new FlxSprite(0, 0).makeGraphic(2, h, COL_BORDER_FOCUS);
		accentLeft.alpha = 0;
		add(accentLeft);

		// ── Behind text (clickable area) ──
		this.behindText = new FlxSprite(1, 1).makeGraphic(wid, h - 2, FlxColor.TRANSPARENT);
		add(this.behindText);

		// ── Selection ──
		this.selection = new FlxSprite().makeGraphic(1, 1, COL_SELECTION);
		this.selection.alpha = 0.5;
		add(this.selection);

		// ── Text ──
		this.textObj = new FlxText(8, Std.int((h - size - 4) / 2), Math.max(1, wid - 16), '', size);
		this.textObj.color = COL_TEXT;
		this.textObj.textField.selectable = false;
		this.textObj.textField.wordWrap = false;
		this.textObj.textField.multiline = false;
		add(this.textObj);

		// ── Placeholder ──
		placeholderObj = new FlxText(8, Std.int((h - size - 4) / 2), Math.max(1, wid - 16), '', size);
		placeholderObj.color = COL_PLACEHOLDER;
		placeholderObj.alpha = 0.6;
		add(placeholderObj);

		// ── Caret ──
		this.caret = new FlxSprite().makeGraphic(2, Std.int(size + 4), COL_CARET);
		add(this.caret);

		// ── Clear button ──
		clearBtn = new FlxText(wid - 18, Std.int((h - size - 2) / 2), 20, "✕", size);
		clearBtn.color = COL_CLEAR_BTN;
		clearBtn.visible = false;
		add(clearBtn);

		// ── Password eye toggle ──
		eyeBtn = new FlxText(wid - 20, Std.int((h - size - 2) / 2), 20, "👁", Std.int(size * 0.9));
		eyeBtn.color = COL_EYE_BTN;
		eyeBtn.visible = false;
		add(eyeBtn);

		// ── Validation icon ──
		validationIcon = new FlxText(wid - 18, Std.int((h - size - 2) / 2), 20, "", size);
		validationIcon.visible = false;
		add(validationIcon);

		// ── Character counter ──
		charCounter = new FlxText(0, h + 2, wid + 2, "", Std.int(Math.max(8, size - 2)));
		charCounter.alignment = RIGHT;
		charCounter.color = COL_COUNTER;
		charCounter.visible = false;
		add(charCounter);

		@:bypassAccessor fieldWidth = wid;
		this.text = text;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	// ══════════════════════════════════
	//  PLACEHOLDER
	// ══════════════════════════════════
	function set_placeholder(v:String):String {
		placeholder = v;
		if (placeholderObj != null)
			placeholderObj.text = v;
		updatePlaceholder();
		return v;
	}

	function updatePlaceholder():Void {
		if (placeholderObj == null)
			return;
		placeholderObj.visible = (text == null || text.length == 0) && placeholder.length > 0;
	}

	// ══════════════════════════════════
	//  INPUT TYPE
	// ══════════════════════════════════
	function set_inputType(v:InputType):InputType {
		inputType = v;
		switch (v) {
			case EMAIL:
				placeholder = 'ornek@email.com';
				filterMode = NO_FILTER;
				showPasswordToggle = false;
			case NUMERIC:
				filterMode = ONLY_NUMERIC;
				showPasswordToggle = false;
			case PASSWORD:
				passwordMask = true;
				showPasswordToggle = true;
				showClearButton = false;
			default:
				showPasswordToggle = false;
		}
		return v;
	}

	// ══════════════════════════════════
	//  VALIDATION
	// ══════════════════════════════════
	function set_validationState(v:ValidationState):ValidationState {
		validationState = v;
		updateBorderColor();

		if (validationIcon != null) {
			switch (v) {
				case VALID:
					validationIcon.text = "✓";
					validationIcon.color = COL_BORDER_VALID;
					validationIcon.visible = true;
				case INVALID:
					validationIcon.text = "✗";
					validationIcon.color = COL_BORDER_INVALID;
					validationIcon.visible = true;
				default:
					validationIcon.visible = false;
			}
		}

		return v;
	}

	function autoValidate():Void {
		if (onValidate != null) {
			validationState = onValidate(text);
		} else if (inputType == EMAIL && text.length > 0) {
			// Basit email doğrulaması
			validationState = (text.indexOf('@') > 0 && text.indexOf('.') > text.indexOf('@')) ? VALID : INVALID;
		}
	}

	// ══════════════════════════════════
	//  BORDER / FOCUS
	// ══════════════════════════════════
	function updateBorderColor():Void {
		var color:Int = COL_BORDER;

		if (validationState == VALID)
			color = COL_BORDER_VALID;
		else if (validationState == INVALID)
			color = COL_BORDER_INVALID;
		else if (_isFocused)
			color = COL_BORDER_FOCUS;

		if (borderTop != null)
			borderTop.color = color;
		if (borderBottom != null)
			borderBottom.color = color;
		if (borderLeft != null)
			borderLeft.color = color;
		if (borderRight != null)
			borderRight.color = color;

		// Left accent glow
		if (accentLeft != null) {
			accentLeft.color = color;
			accentLeft.alpha = _isFocused ? 0.8 : 0;
		}

		// Background
		if (bg != null)
			bg.color = _isFocused ? COL_BG_FOCUS : COL_BG;
	}

	// ══════════════════════════════════
	//  CHARACTER COUNTER
	// ══════════════════════════════════
	function updateCharCounter():Void {
		if (charCounter == null || !showCharCounter || maxLength == 0)
			return;

		charCounter.visible = _isFocused;
		var len = text != null ? text.length : 0;
		charCounter.text = '$len/$maxLength';

		var ratio:Float = maxLength > 0 ? len / maxLength : 0;
		if (ratio >= 1.0)
			charCounter.color = COL_COUNTER_FULL;
		else if (ratio >= 0.8)
			charCounter.color = COL_COUNTER_WARN;
		else
			charCounter.color = COL_COUNTER;
	}

	// ══════════════════════════════════
	//  UNDO / REDO
	// ══════════════════════════════════
	function pushUndo(oldText:String):Void {
		_undoStack.push(oldText);
		if (_undoStack.length > MAX_UNDO)
			_undoStack.shift();
		_redoStack = []; // redo stack temizle
	}

	function undo():Void {
		if (_undoStack.length == 0)
			return;
		_redoStack.push(text);
		var prev = _undoStack.pop();
		var lastText = text;
		text = prev;
		caretIndex = text.length;
		if (onChange != null)
			onChange(lastText, text);
		if (broadcastInputTextEvent)
			PsychUIEventHandler.event(CHANGE_EVENT, this);
	}

	function redo():Void {
		if (_redoStack.length == 0)
			return;
		_undoStack.push(text);
		var next = _redoStack.pop();
		var lastText = text;
		text = next;
		caretIndex = text.length;
		if (onChange != null)
			onChange(lastText, text);
		if (broadcastInputTextEvent)
			PsychUIEventHandler.event(CHANGE_EVENT, this);
	}

	// ══════════════════════════════════
	//  CLEAR BUTTON
	// ══════════════════════════════════
	function updateClearButton():Void {
		if (clearBtn == null)
			return;

		var showClear = showClearButton && _isFocused && text != null && text.length > 0 && !showPasswordToggle;
		clearBtn.visible = showClear;
	}

	function updateEyeButton():Void {
		if (eyeBtn == null)
			return;

		eyeBtn.visible = showPasswordToggle && _isFocused;
		eyeBtn.text = _passwordVisible ? "👁" : "🔒";
	}

	// ══════════════════════════════════
	//  MEVCUT ALANLAR + GELİŞTİRMELER
	// ══════════════════════════════════
	public var selectIndex:Int = -1;
	public var caretIndex(default, set):Int = -1;
	var _caretTime:Float = 0;

	var _nextAccent:AccentCode = NONE;
	public var inInsertMode:Bool = false;

	function onKeyDown(e:KeyboardEvent) {
		if (focusOn != this)
			return;

		var keyCode:Int = e.keyCode;
		var charCode:Int = e.charCode;
		var flxKey:FlxKey = cast keyCode;

		// Fix missing cedilla
		switch (keyCode) {
			case 231:
				charCode = e.shiftKey ? 0xC7 : 0xE7;
		}

		// Control key actions
		if (e.controlKey) {
			switch (flxKey) {
				case A:
					selectIndex = Std.int(Math.min(0, text.length - 1));
					caretIndex = text.length;

				case X, C:
					if (caretIndex >= 0 && selectIndex != 0 && caretIndex != selectIndex) {
						Clipboard.text = text.substring(caretIndex, selectIndex);
						if (flxKey == X) {
							pushUndo(text);
							deleteSelection();
						}
					}

				case V:
					if (Clipboard.text == null)
						return;
					pushUndo(text);
					if (selectIndex > -1 && selectIndex != caretIndex)
						deleteSelection();
					var lastText = text;
					text = text.substring(0, caretIndex) + Clipboard.text + text.substring(caretIndex);
					caretIndex += Clipboard.text.length;
					if (onChange != null)
						onChange(lastText, text);
					if (broadcastInputTextEvent)
						PsychUIEventHandler.event(CHANGE_EVENT, this);

				case Z: // Undo
					undo();

				case Y: // Redo
					redo();

				case BACKSPACE:
					pushUndo(text);
					if (selectIndex < 0 || selectIndex == caretIndex) {
						var lastText = text;
						var deletedText:String = text.substr(0, Std.int(Math.max(0, caretIndex - 1)));
						var space:Int = deletedText.lastIndexOf(' ');
						if (space > -1 && space != caretIndex - 1) {
							var start:String = deletedText.substring(0, space + 1);
							var end:String = text.substring(caretIndex);
							caretIndex -= Std.int(Math.max(0, text.length - (start.length + end.length)));
							text = start + end;
						} else {
							text = text.substring(caretIndex);
							caretIndex = 0;
						}
						selectIndex = -1;
						if (onChange != null)
							onChange(lastText, text);
						if (broadcastInputTextEvent)
							PsychUIEventHandler.event(CHANGE_EVENT, this);
					} else {
						pushUndo(text);
						deleteSelection();
					}

				case DELETE:
					pushUndo(text);
					if (selectIndex < 0 || selectIndex == caretIndex) {
						var deletedText:String = text.substring(caretIndex);
						var spc:Int = 0;
						var space:Int = deletedText.indexOf(' ');
						while (deletedText.substr(spc, 1) == ' ') {
							spc++;
							space = deletedText.substr(spc).indexOf(' ');
						}
						var lastText = text;
						if (space > -1)
							text = text.substr(0, caretIndex) + text.substring(caretIndex + space + spc);
						else
							text = text.substr(0, caretIndex);
						if (onChange != null)
							onChange(lastText, text);
						if (broadcastInputTextEvent)
							PsychUIEventHandler.event(CHANGE_EVENT, this);
					} else {
						pushUndo(text);
						deleteSelection();
					}

				case LEFT:
					if (caretIndex > 0) {
						do {
							caretIndex--;
							var a:String = text.substr(caretIndex - 1, 1);
							var b:String = text.substr(caretIndex, 1);
							if (a == ' ' && b != ' ')
								break;
						} while (caretIndex > 0);
					}

				case RIGHT:
					if (caretIndex < text.length) {
						do {
							caretIndex++;
							var a:String = text.substr(caretIndex - 1, 1);
							var b:String = text.substr(caretIndex, 1);
							if (a != ' ' && b == ' ')
								break;
						} while (caretIndex < text.length);
					}

				default:
			}
			updateCaret();
			return;
		}

		static final ignored:Array<FlxKey> = [SHIFT, CONTROL, ESCAPE];
		if (ignored.contains(flxKey))
			return;

		var lastAccent = _nextAccent;
		switch (keyCode) {
			case KEY_TILDE:
				_nextAccent = !e.shiftKey ? TILDE : CIRCUMFLEX;
				if (lastAccent == NONE)
					return;
			case KEY_ACUTE:
				_nextAccent = !e.shiftKey ? ACUTE : GRAVE;
				if (lastAccent == NONE)
					return;
			default:
				lastAccent = NONE;
		}

		switch (flxKey) {
			case LEFT:
				if (!FlxG.keys.pressed.SHIFT)
					selectIndex = -1;
				else if (selectIndex == -1)
					selectIndex = caretIndex;
				caretIndex = Std.int(Math.max(0, caretIndex - 1));

			case RIGHT:
				if (!FlxG.keys.pressed.SHIFT)
					selectIndex = -1;
				else if (selectIndex == -1)
					selectIndex = caretIndex;
				caretIndex = Std.int(Math.min(text.length, caretIndex + 1));

			case HOME:
				if (!FlxG.keys.pressed.SHIFT)
					selectIndex = -1;
				else if (selectIndex == -1)
					selectIndex = caretIndex;
				caretIndex = 0;

			case END:
				if (!FlxG.keys.pressed.SHIFT)
					selectIndex = -1;
				else if (selectIndex == -1)
					selectIndex = caretIndex;
				caretIndex = text.length;

			case INSERT:
				inInsertMode = !inInsertMode;

			case TAB:
				// Tab ile sonraki input'a geç
				if (tabNext != null) {
					focusOn = tabNext;
					FlxG.stage.window.textInputEnabled = true;
				} else if (FlxG.keys.pressed.SHIFT && tabPrev != null) {
					focusOn = tabPrev;
					FlxG.stage.window.textInputEnabled = true;
				}

			case BACKSPACE:
				if (caretIndex <= 0)
					return;
				if (selectIndex > -1 && selectIndex != caretIndex) {
					pushUndo(text);
					deleteSelection();
				} else {
					pushUndo(text);
					var lastText = text;
					text = text.substring(0, caretIndex - 1) + text.substring(caretIndex);
					caretIndex--;
					if (onChange != null)
						onChange(lastText, text);
					if (broadcastInputTextEvent)
						PsychUIEventHandler.event(CHANGE_EVENT, this);
				}
				_nextAccent = NONE;

			case DELETE:
				if (selectIndex > -1 && selectIndex != caretIndex) {
					pushUndo(text);
					deleteSelection();
					updateCaret();
					return;
				}
				if (caretIndex >= text.length)
					return;
				pushUndo(text);
				var lastText = text;
				if (caretIndex < 1)
					text = text.substr(1);
				else
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
				if (caretIndex >= text.length)
					caretIndex = text.length;
				if (onChange != null)
					onChange(lastText, text);
				if (broadcastInputTextEvent)
					PsychUIEventHandler.event(CHANGE_EVENT, this);

			case SPACE:
				if (_nextAccent != NONE)
					_typeLetter(getAccentCharCode(_nextAccent));
				else
					_typeLetter(charCode);
				_nextAccent = NONE;

			case A, O:
				var grave:Int = 0x0;
				var capital:Int = 0x0;
				switch (flxKey) {
					case A:
						grave = 0xC0;
						capital = 0x41;
					case O:
						grave = 0xD2;
						capital = 0x4f;
					default:
				}
				if (_nextAccent != NONE)
					charCode += grave - capital + _nextAccent;
				_typeLetter(charCode);
				_nextAccent = NONE;

			case E, I, U:
				var grave:Int = 0x0;
				var capital:Int = 0x0;
				switch (flxKey) {
					case E:
						grave = 0xC8;
						capital = 0x45;
					case I:
						grave = 0xCC;
						capital = 0x49;
					case U:
						grave = 0xD9;
						capital = 0x55;
					default:
				}
				if (_nextAccent == GRAVE || _nextAccent == ACUTE || _nextAccent == CIRCUMFLEX)
					charCode += grave - capital + _nextAccent;
				else if (_nextAccent == TILDE)
					_typeLetter(getAccentCharCode(_nextAccent));
				_typeLetter(charCode);
				_nextAccent = NONE;

			case N:
				if (_nextAccent == TILDE)
					charCode += 0xD1 - 0x4E;
				else
					_typeLetter(getAccentCharCode(_nextAccent));
				_typeLetter(charCode);
				_nextAccent = NONE;

			case ESCAPE:
				focusOn = null;

			case ENTER:
				onPressEnter(e);

			default:
				if (charCode < 1)
					if ((charCode = getAccentCharCode(_nextAccent)) < 1)
						return;
				if (lastAccent != NONE)
					_typeLetter(getAccentCharCode(lastAccent));
				else if (_nextAccent != NONE)
					_typeLetter(getAccentCharCode(_nextAccent));
				_typeLetter(charCode);
				_nextAccent = NONE;
		}
		updateCaret();
	}

	public dynamic function onPressEnter(e:KeyboardEvent) {
		FlxG.stage.window.textInputEnabled = false;
		focusOn = null;
	}

	public var unfocus:Void->Void;

	public static function set_focusOn(v:PsychUIInputText) {
		if (focusOn != null && focusOn != v && focusOn.exists) {
			focusOn._isFocused = false;
			focusOn.updateBorderColor();
			focusOn.updateClearButton();
			focusOn.updateEyeButton();
			focusOn.updateCharCounter();
			if (focusOn.unfocus != null)
				focusOn.unfocus();
			if (focusOn.onFocusLost != null)
				focusOn.onFocusLost();
			focusOn.autoValidate();
			focusOn.resetCaret();
		}

		focusOn = v;

		if (v != null && v.exists) {
			v._isFocused = true;
			v.updateBorderColor();
			v.updateClearButton();
			v.updateEyeButton();
			v.updateCharCounter();
			if (v.onFocusGained != null)
				v.onFocusGained();
		}

		return v;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Focus glow pulse
		if (_isFocused) {
			_focusGlow += elapsed;
			if (accentLeft != null)
				accentLeft.alpha = 0.5 + Math.sin(_focusGlow * 3) * 0.3;
		}

		if (FlxG.mouse.justPressed) {
			if (FlxG.mouse.overlaps(behindText, camera)) {
				if (!FlxG.keys.pressed.SHIFT)
					selectIndex = -1;
				else if (selectIndex == -1)
					selectIndex = caretIndex;
				focusOn = this;
				FlxG.stage.window.textInputEnabled = true;
				caretIndex = 0;
				var lastBound:Float = 0;
				var textObjX:Float = textObj.getScreenPosition(camera).x;
				var mousePosX:Float = FlxG.mouse.getScreenPosition(camera).x;
				var txtX:Float = textObjX - textObj.textField.scrollH;

				for (i => bound in _boundaries) {
					if (mousePosX >= txtX + (bound - lastBound) / 2) {
						caretIndex = i + 1;
						txtX += bound - lastBound;
						lastBound = bound;
					} else
						break;
				}
				updateCaret();
			}
			// Clear button tıklama
			else if (clearBtn != null && clearBtn.visible && FlxG.mouse.overlaps(clearBtn, camera)) {
				pushUndo(text);
				var lastText = text;
				text = '';
				caretIndex = 0;
				selectIndex = -1;
				if (onChange != null)
					onChange(lastText, text);
				if (broadcastInputTextEvent)
					PsychUIEventHandler.event(CHANGE_EVENT, this);
			}
			// Eye toggle tıklama
			else if (eyeBtn != null && eyeBtn.visible && FlxG.mouse.overlaps(eyeBtn, camera)) {
				_passwordVisible = !_passwordVisible;
				passwordMask = !_passwordVisible;
				updateEyeButton();
			} else if (focusOn == this)
				focusOn = null;
		}

		if (focusOn == this) {
			_caretTime = (_caretTime + elapsed) % 1;
			if (textObj != null && textObj.exists) {
				var drewSelection:Bool = false;
				if (selection != null && selection.exists) {
					if (selectIndex != -1 && selectIndex != caretIndex) {
						selection.visible = true;
						drewSelection = true;
					} else
						selection.visible = false;
				}

				if (caret != null && caret.exists) {
					if (!drewSelection && _caretTime < 0.5 && caret.x >= textObj.x) {
						caret.visible = true;
						caret.color = COL_CARET;
					} else
						caret.visible = false;
				}
			}
		} else {
			_caretTime = 0;
			inInsertMode = false;
			if (selection != null && selection.exists)
				selection.visible = false;
			if (caret != null && caret.exists)
				caret.visible = false;
		}
	}

	public function resetCaret() {
		selectIndex = -1;
		caretIndex = 0;
		updateCaret();
	}

	public function updateCaret() {
		if (textObj == null || !textObj.exists)
			return;

		var textField = textObj.textField;
		textField.setSelection(caretIndex, caretIndex);
		_caretTime = 0;
		if (caret != null && caret.exists) {
			caret.y = textObj.y + 2;
			caret.x = textObj.x + 1 - textObj.textField.scrollH;
			if (caretIndex > 0)
				caret.x += _boundaries[Std.int(Math.max(0, Math.min(_boundaries.length - 1, caretIndex - 1)))];
		}

		if (selection != null && selection.exists) {
			selection.y = textObj.y + 2;
			selection.x = textObj.x + 1 - textObj.textField.scrollH;
			if (selectIndex > 0)
				selection.x += _boundaries[Std.int(Math.max(0, Math.min(_boundaries.length - 1, selectIndex - 1)))];

			selection.scale.y = textField.textHeight;
			selection.scale.x = caret.x - selection.x;
			if (selection.scale.x < 0) {
				selection.scale.x = Math.abs(selection.scale.x);
				selection.x -= selection.scale.x;
			}

			if (selection.x < textObj.x) {
				var diff:Float = textObj.x - selection.x;
				selection.x += diff;
				selection.scale.x -= diff;
			}
			if (selection.x + selection.scale.x > textObj.x + textObj.width)
				selection.scale.x += (textObj.x + textObj.width - selection.x - selection.scale.x);

			selection.updateHitbox();

			if (text.length > 0) {
				textObj.removeFormat(selectedFormat);
				if (selectIndex != -1 && selectIndex != caretIndex) {
					textObj.addFormat(selectedFormat, caretIndex < selectIndex ? caretIndex : selectIndex,
						caretIndex < selectIndex ? selectIndex : caretIndex);
				}
			}
		} else if (text.length > 0)
			textObj.removeFormat(selectedFormat);

		// UI güncellemeleri
		updatePlaceholder();
		updateClearButton();
		updateCharCounter();
	}

	function deleteSelection() {
		var lastText:String = text;
		if (selectIndex > caretIndex)
			text = text.substring(0, caretIndex) + text.substring(selectIndex);
		else {
			text = text.substring(0, selectIndex) + text.substring(caretIndex);
			caretIndex = selectIndex;
		}
		selectIndex = -1;
		if (onChange != null)
			onChange(lastText, text);
		if (broadcastInputTextEvent)
			PsychUIEventHandler.event(CHANGE_EVENT, this);
	}

	override public function destroy() {
		_boundaries = null;
		_undoStack = null;
		_redoStack = null;
		if (focusOn == this)
			focusOn = null;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}

	function set_caretIndex(v:Int) {
		caretIndex = v;
		updateCaret();
		return v;
	}

	override public function setGraphicSize(width:Float = 0, height:Float = 0) {
		super.setGraphicSize(width, height);
		bg.setGraphicSize(width, height);
		behindText.setGraphicSize(width - 2, height - 2);
		if (textObj != null && textObj.exists) {
			textObj.scale.x = 1;
			textObj.scale.y = 1;
			if (caret != null && caret.exists)
				caret.setGraphicSize(2, textObj.height - 4);
		}
	}

	override public function updateHitbox() {
		super.updateHitbox();
		bg.updateHitbox();
		behindText.updateHitbox();
		if (textObj != null && textObj.exists) {
			textObj.updateHitbox();
			if (caret != null && caret.exists)
				caret.updateHitbox();
		}
	}

	function set_fieldWidth(v:Int) {
		textObj.fieldWidth = Math.max(1, v - 16);
		textObj.textField.selectable = false;
		textObj.textField.wordWrap = false;
		textObj.textField.multiline = false;
		return (fieldWidth = v);
	}

	function set_maxLength(v:Int) {
		var lastText = text;
		v = Std.int(Math.max(0, v));
		if (v > 0 && text.length > v)
			text = text.substr(0, v);
		if (onChange != null)
			onChange(lastText, text);
		if (broadcastInputTextEvent)
			PsychUIEventHandler.event(CHANGE_EVENT, this);
		return (maxLength = v);
	}

	function set_passwordMask(v:Bool) {
		passwordMask = v;
		text = text;
		return passwordMask;
	}

	var _boundaries:Array<Float> = [];

	function set_text(v:String) {
		for (i in 0..._boundaries.length)
			_boundaries.pop();
		v = filter(v);

		textObj.text = '';
		if (v != null && v.length > 0) {
			if (v.length > 1) {
				for (i in 0...v.length) {
					var toPrint:String = v.substr(i, 1);
					if (toPrint == '\n')
						toPrint = ' ';
					textObj.textField.appendText(!passwordMask ? toPrint : '•'); // bullet yerine dot
					_boundaries.push(textObj.textField.textWidth);
				}
			} else {
				textObj.text = !passwordMask ? v : '•';
				_boundaries.push(textObj.textField.textWidth);
			}
		}
		text = v;
		updateCaret();
		updatePlaceholder();
		updateClearButton();
		updateCharCounter();
		return v;
	}

	public static function getAccentCharCode(accent:AccentCode) {
		switch (accent) {
			case TILDE:
				return 0x7E;
			case CIRCUMFLEX:
				return 0x5E;
			case ACUTE:
				return 0xB4;
			case GRAVE:
				return 0x60;
			default:
				return 0x0;
		}
	}

	public var broadcastInputTextEvent:Bool = true;

	function _typeLetter(charCode:Int) {
		if (charCode < 1)
			return;

		if (selectIndex > -1 && selectIndex != caretIndex) {
			pushUndo(text);
			deleteSelection();
		}

		var letter:String = String.fromCharCode(charCode);
		letter = filter(letter);
		if (letter.length > 0 && (maxLength == 0 || (text.length + letter.length) <= maxLength)) {
			pushUndo(text);
			var lastText = text;
			if (!inInsertMode)
				text = text.substring(0, caretIndex) + letter + text.substring(caretIndex);
			else
				text = text.substring(0, caretIndex) + letter + text.substring(caretIndex + 1);

			caretIndex += letter.length;
			if (onChange != null)
				onChange(lastText, text);
			if (broadcastInputTextEvent)
				PsychUIEventHandler.event(CHANGE_EVENT, this);
		}
		_caretTime = 0;
	}

	function set_forceCase(v:CaseMode) {
		forceCase = v;
		text = filter(text);
		return forceCase;
	}

	function set_filterMode(v:FilterMode) {
		filterMode = v;
		text = filter(text);
		return filterMode;
	}

	function set_customFilterPattern(cfp:EReg) {
		customFilterPattern = cfp;
		filterMode = CUSTOM_FILTER;
		return customFilterPattern;
	}

	private function filter(text:String):String {
		switch (forceCase) {
			case UPPER_CASE:
				text = text.toUpperCase();
			case LOWER_CASE:
				text = text.toLowerCase();
			default:
		}

		if (filterMode != NO_FILTER) {
			var pattern:EReg;
			switch (filterMode) {
				case ONLY_ALPHA:
					pattern = ~/[^a-zA-Z]*/g;
				case ONLY_NUMERIC:
					pattern = ~/[^0-9]*/g;
				case ONLY_ALPHANUMERIC:
					pattern = ~/[^a-zA-Z0-9]*/g;
				case ONLY_HEXADECIMAL:
					pattern = ~/[^a-fA-F0-9]*/g;
				case CUSTOM_FILTER:
					pattern = customFilterPattern;
				default:
					throw new flash.errors.Error("FlxInputText: Unknown filterMode (" + filterMode + ")");
			}
			text = pattern.replace(text, "");
		}
		return text;
	}
}