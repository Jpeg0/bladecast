extends Node2D

var prev_pos = Vector2()
var next_pos = Vector2()
var weight = 0

func _process(delta: float) -> void:
	weight += delta
	position = lerp(prev_pos, next_pos, weight)
	if weight >= 1:
		weight = 0
		prev_pos = position
