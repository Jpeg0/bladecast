extends Node

var audio_player

const sounds = {
	"Swing": {
		"key": "Swing",
		"node_path": "SoundEffects/Swing",
		"path": "Sounds/SoundEffects/Swing.wav",
		"bus": "SFX",
	},
	"HitFlesh": {
		"key": "HitFlesh",
		"node_path": "SoundEffects/HitFlesh",
		"path": "Sounds/SoundEffects/HitFlesh.wav",
		"bus": "SFX",
	},
	"Impact": {
		"key": "Impact",
		"node_path": "SoundEffects/Impact",
		"path": "Sounds/SoundEffects/Impact.wav",
		"bus": "SFX",
	},
	"FirstLight-Full": {
		"key": "FirstLight-Full",
		"node_path": "Music/FirstLight-Full",
		"path": "Sounds/Music/FirstLight-Full.wav",
		"bus": "Music",
	},
	"NoTimeToBleed-Full": {
		"key": "NoTimeToBleed-Full",
		"node_path": "Music/NoTimeToBleed-Full",
		"path": "Sounds/Music/NoTimeToBleed-Full.wav",
		"bus": "Music",
	},
}

const sound_pools = {
	"Ambient_Default": [
		"NoTimeToBleed-Full",
		"FirstLight-Full",
	]
}

func _ready() -> void:
	if audio_player:
		for sound in sounds.values():
			var parent_node : Node2D
			if audio_player.has_node(sound["path"].split("/")[1]):
				parent_node = audio_player.get_node(sound["path"].split("/")[1])
			else:
				parent_node = Node2D.new()
				parent_node.name = sound["path"].split("/")[1]
				audio_player.add_child(parent_node)

			var sound_player = AudioStreamPlayer2D.new()
			var stream
			if ResourceLoader.exists(sound["path"]): stream = load(sound["path"])
			else: return
			
			if sound["key"] in sound_pools["Ambient_Default"]: sound_player.connect("finished", Callable(self, "play_ambient_default"))
			
			sound_player.bus = sound["bus"]
			sound_player.max_polyphony = 4
			sound_player.max_distance = 2048
			sound_player.panning_strength = 4.0
			sound_player.stream = stream
			sound_player.name = sound["key"]
			parent_node.add_child(sound_player)
			
		play_ambient_default()
	else:
		await get_tree().process_frame
		_ready()
		
func play_ambient_default(): play_sound(sound_pools["Ambient_Default"][randi_range(0, sound_pools["Ambient_Default"].size() - 1)], 1.0, 0.0)
		
func play_sound(Sound: String, BasePitch: float = 1.0, PitchVariation: float = 0.1) -> void:
	var sound_player = audio_player.get_node(sounds[Sound].node_path)
	sound_player.pitch_scale = BasePitch + randf_range(-PitchVariation, PitchVariation)
	sound_player.play()
