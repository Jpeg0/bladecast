extends Camera2D

@export var random_strength: float = 10.0
@export var camera_shake_fade: float = 5.0
var rng = RandomNumberGenerator.new()
var camera_shake_strength: float = 0.0

func camera_shake(camera_shake_time):
	camera_shake_strength = random_strength

func _process(delta: float) -> void:
	if camera_shake_strength > 0: camera_shake_strength = lerpf(camera_shake_strength, 0, camera_shake_fade * delta)
	offset = Vector2(rng.randf_range(-camera_shake_strength, camera_shake_strength), rng.randf_range(-camera_shake_strength, camera_shake_strength))
	$OffsetNegator.position = offset
