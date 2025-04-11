extends Node

var audio_player
var audio_ray = preload("res://Scenes/audio_raycast.tscn")

func _ready() -> void:
	if audio_player: play_sound(AssetManager.sound_pools["Ambient_Default"][randi_range(0, AssetManager.sound_pools["Ambient_Default"].size() - 1)], 1.0, 0.0)
	else: await get_tree().process_frame; _ready()
		
func play_sound(Sound: String, BasePitch: float = 1.0, PitchVariation: float = 0.1, Position: Vector2 = Vector2.ZERO) -> void:
	var bus_index = AudioServer.bus_count
	var bus_name = Sound + str(randi())
	var audio_stream_player = AudioStreamPlayer2D.new()
	audio_player.add_child(audio_stream_player)
	if AssetManager.sound_cache.has(Sound): audio_stream_player.stream = AssetManager.sound_cache[Sound]
	audio_stream_player.pitch_scale = BasePitch + randf_range(-PitchVariation, PitchVariation)
	audio_stream_player.name = Sound
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, AssetManager.sounds[Sound]["bus"])
	
	if AssetManager.sounds[Sound]["raytraced_audio"] == true:
		audio_stream_player.position = Position
		audio_stream_player.top_level = true
		audio_stream_player.max_distance = 2048
		audio_stream_player.panning_strength = 2
		var reverb = AudioEffectReverb.new()
		var lowpass = AudioEffectLowPassFilter.new()
		var delay = AudioEffectDelay.new()
		
		var total_hits = 0.0
		var total_los_rays = 0.0
		var average_los_ray_length = 0.0
		var audio_rays = 64
		var bounces = 8
		
		for i in range(audio_rays):
			var new_ray = audio_ray.instantiate()
			new_ray.position = LocalData.player.position
			new_ray.target_position = Vector2(cos(i * TAU / audio_rays), sin(i * TAU / audio_rays)) * 2048.0
			audio_stream_player.add_child(new_ray)
			
			for bounce in range(bounces):
				new_ray.force_raycast_update()
				if new_ray.is_colliding():
					total_los_rays += 1
					var los = new_ray.get_node("LineOfSight")
					los.position = new_ray.get_collision_point()
					los.target_position = Position - los.position
					los.enabled = true
					
					los.force_raycast_update()
					if !los.is_colliding():
						total_hits += 1
						average_los_ray_length += los.target_position.length()
					los.enabled = false
					
					new_ray.position = new_ray.get_collision_point() + Vector2(randf_range(-1, 1), randf_range(-1, 1))
					new_ray.target_position = new_ray.target_position.bounce(new_ray.get_collision_normal())
					
			new_ray.queue_free()
		
		var muffle_amount = 0
		
		for i in range(int(LocalData.player.position.distance_to(Position) / 32) + 1): if LocalData.collision_blocks.get_cell_source_id(LocalData.collision_blocks.local_to_map(LocalData.collision_blocks.to_local(LocalData.player.position + (Position - LocalData.player.position).normalized() * (i * 32)))) != -1: muffle_amount += 1
		
		lowpass.cutoff_hz = 6000 * 0.6**(muffle_amount - 2)
		delay.tap1_delay_ms = clamp((average_los_ray_length / total_los_rays) / (512.0 / total_los_rays), 0, 128)
		delay.tap2_delay_ms = delay.tap1_delay_ms * 2
		delay.tap1_level_db = ((delay.tap1_delay_ms / 3.0) + (total_hits / (audio_rays * 1.5))) / 2 - 52
		delay.tap2_level_db = delay.tap1_level_db - 8
		reverb.room_size = clamp((average_los_ray_length / total_los_rays) / (4096.0 / total_los_rays) / 128.0, 0.0, 0.8)
		reverb.wet = reverb.room_size
		reverb.predelay_feedback = clamp(reverb.room_size * 4, 0, 0.5)
					
		AudioServer.add_bus_effect(bus_index, reverb, 0)
		AudioServer.add_bus_effect(bus_index, lowpass, 1)
		AudioServer.add_bus_effect(bus_index, delay, 2)
		
	audio_stream_player.bus = AudioServer.get_bus_name(bus_index)
	audio_stream_player.play()
	
	audio_stream_player.finished.connect(func() -> void:
		if AssetManager.sound_pools.Ambient_Default.has(Sound):
			play_sound(AssetManager.sound_pools["Ambient_Default"][randi_range(0, AssetManager.sound_pools["Ambient_Default"].size() - 1)], 1.0, 0.0)
		await get_tree().create_timer(5).timeout
		AudioServer.remove_bus(AudioServer.get_bus_index(bus_name))
		audio_stream_player.queue_free()
	)
