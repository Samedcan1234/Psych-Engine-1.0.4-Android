package backend;

typedef VoiceNoteMapping = {
	var left:Int;
	var down:Int;
	var up:Int;
	var right:Int;
}

typedef VoiceSampleMapping = {
	@:optional var left:String;
	@:optional var down:String;
	@:optional var up:String;
	@:optional var right:String;
}

typedef VoicePresetData = {
	var name:String;
	var displayName:String;
	var type:String;
	var file:String;
	var bank:Int;
	var preset:Int;
	var transpose:Int;
	var volume:Float;
	var pan:Float;
	var noteMapping:VoiceNoteMapping;
	var sustainMode:String;
	var retriggerRate:Float;
	var enabled:Bool;
	var description:String;
	@:optional var samples:VoiceSampleMapping;
	@:optional var sourcePath:String;
}

class VoicePreset {
	public static function getDefault():VoicePresetData {
		return {
			name: "default",
			displayName: "Default Vocals (OGG)",
			type: "ogg",
			file: "vocals.ogg",
			bank: 0,
			preset: 0,
			transpose: 0,
			volume: 1.0,
			pan: 0.0,
			noteMapping: {
				left: 60,
				down: 62,
				up: 64,
				right: 65
			},
			sustainMode: "retrigger",
			retriggerRate: 0.08,
			enabled: true,
			description: "Default OGG vocal track"
		};
	}
}