extends Control

func _ready() -> void:
		$Right/Cpu.text = "cpu: " + OS.get_processor_name().to_lower()
		$Right/Gpu.text = "gpu: " + RenderingServer.get_rendering_device().get_device_name().to_lower()
		$Right/ScreenResolution.text = "screen resolution: " + str(DisplayServer.screen_get_size(0))
		$Right/RefreshRate.text = "refresh rate: " + str(round(DisplayServer.screen_get_refresh_rate(0)))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Debug Menu"): visible = !visible
	if visible:
		$Left/Fps.text = "fps: " + str(Engine.get_frames_per_second())
		$Left/Position.text = "position: " + str(Vector2i(get_parent().get_parent().get_parent().get_parent().position * 100) / 3200)
		$Left/Velocity.text = "velocity: " + str(Vector2i(get_parent().get_parent().get_parent().get_parent().velocity))
		$Left/Zoom.text = "zoom: " + str(round(get_parent().get_parent().get_parent().scale.x * 1000) / 1000)
		$Left/Lod.text = "lod: " + str(AssetManager.current_lod)
		
		$Right/MemoryUsage.text = "memory usage: " + str(int(OS.get_static_memory_usage() / 1048576.0)) + "mb"
		$Right/GameResolution.text = "game resolution: " + str(get_viewport().get_size())
		
