package backend;

import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;

	public function new()
	{
		mobileManager = new MobileControlManager(this);
		instance = this;
		controls.isInSubstate = true;
		super();
	}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	public var mobileManager:MobileControlManager;
	public function getMobilePadButton(name:String) {
		return mobileManager?.mobilePad?.getButton(name);
	}
	public function mobilePadJustPressed(buttons:Dynamic):Bool {
		return mobileManager?.mobilePad?.justPressed(buttons);
	}
	public function mobilePadPressed(buttons:Dynamic):Bool {
		return mobileManager?.mobilePad?.pressed(buttons);
	}
	public function mobilePadJustReleased(buttons:Dynamic):Bool {
		return mobileManager?.mobilePad?.justReleased(buttons);
	}
	public function mobilePadReleased(buttons:Dynamic):Bool {
		return mobileManager?.mobilePad?.released(buttons);
	}

	public function addTouchPad(DPad:String, Action:String)
	{
		mobileManager.addMobilePad(DPad, Action);
	}

	public function removeTouchPad()
	{
		mobileManager.removeMobilePad();
	}

	public function addHitbox(?mode:String, ?hints:Bool):Void
	{
		mobileManager.addHitbox(mode, hints);
	}

	public function removeHitbox()
	{
		mobileManager.removeHitbox();
	}

	public function addHitboxCamera(defaultDrawTarget:Bool = false):Void
	{
		mobileManager.addHitboxCamera(defaultDrawTarget);
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		mobileManager.addMobilePadCamera(defaultDrawTarget);
	}

	override function destroy()
	{
		controls.isInSubstate = false;
		if (mobileManager != null) mobileManager.destroy();
		
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
	
	public function sectionHit():Void
	{
		//yep, you guessed it, nothing again, dumbass
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
