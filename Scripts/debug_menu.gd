extends Control

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Debug Menu"): visible = !visible
	if visible:
		$Left/Fps.text = "fps: " + str(Engine.get_frames_per_second())
		$Left/Position.text = "position: " + str(Vector2i(get_parent().get_parent().get_parent().position * 100) / 100)
