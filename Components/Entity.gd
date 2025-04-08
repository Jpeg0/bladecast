class_name Entity
extends Node2D

@onready var entity = get_parent().get_parent()

static var entity_amount = 0

func _ready() -> void: entity_amount += 1

func _process(_delta: float) -> void:
	if entity.get_node_or_null("NavigationTimer"):
		var NavTPS = clamp(2048.0 / float(entity_amount), 8, 16)
		entity.navigation_ticks = NavTPS
		entity.get_node("NavigationTimer").wait_time = 1.0 / NavTPS

func _physics_process(_delta: float) -> void: entity.in_loaded_chunk = get_tree().current_scene.get_node("Blocks").generated_chunks.has(Vector2i(get_parent().get_parent().position / 1024))
