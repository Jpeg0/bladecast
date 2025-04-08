extends CharacterBody2D

var players_folder
var closest_player
var min_distance: float
var entities
var deloaded: bool = false
var tilemap
var follow_range = 2048
var can_move = true
var knockback_velocity = Vector2(0, 0)
var movespeed = 96
var friction = 2048
var acceleration = 256
var in_loaded_chunk = false
var timer
var navigation_ticks: float = 16.0
var soft_collision_velocity = Vector2()

func _ready() -> void:
	entities = get_tree().get_current_scene().get_node("Entities")
	players_folder = entities.get_node("Players")
	tilemap = get_tree().get_current_scene().get_node("Blocks/Foreground_Blocks")

func _process(_delta: float) -> void:
	if not deloaded and not LocalData.paused and can_move and in_loaded_chunk:
		move_and_slide()

func soft_collision(delta):
	for entity_type in entities.get_children():
		for entity in entity_type.get_children():
			if (entity.position - position).length() < 56 and abs(entity.position.x - position.x) < 24: soft_collision_velocity.x += -sign(entity.position.x - position.x) * 16.0 * delta
			if abs(soft_collision_velocity.x) >= 1:
				soft_collision_velocity.x = clamp(soft_collision_velocity.x, -64, 64)
				soft_collision_velocity.x *= 12.0 * delta
			else: soft_collision_velocity.x = 0
			
func navigation() -> void:
	if not deloaded and not LocalData.paused and can_move and in_loaded_chunk:
		var delta: float = 1.0 / navigation_ticks
		
		if not is_on_floor():
			velocity.y += 680 * delta
		else:
			velocity.y = 0
		if velocity.y > 2048: velocity.y = 2048
		
		min_distance = INF
		for player in players_folder.get_children():
			var distance: float = (player.global_position - position).length()
			if distance < min_distance:
				closest_player = player
				min_distance = distance
				
		if min_distance < follow_range and (abs(closest_player.position.x - position.x) > 28 or (min_distance > 64 and abs(closest_player.position.x - position.x) > 4)):
			var dir: int = sign(closest_player.position.x - position.x)
			if dir != 0: velocity.x = velocity.move_toward(Vector2(movespeed * dir, velocity.y), acceleration * delta).x
			
			velocity.x = clamp(velocity.x, -movespeed, movespeed)
			
			$BlockCheck.target_position = Vector2(dir * 56, 0)
			$BlockCheck2.target_position = Vector2(dir * 56, 0)
			$BlockCheck3.target_position = Vector2(dir * 56, 0)
			
			if $BlockCheck.is_colliding() and is_on_floor():
				var block1_dist: int = $BlockCheck.global_position.distance_to($BlockCheck.get_collision_point())
				var block2_dist: int = $BlockCheck2.global_position.distance_to($BlockCheck2.get_collision_point())
				var block3_dist: int = $BlockCheck3.global_position.distance_to($BlockCheck3.get_collision_point())
				
				if $BlockCheck2.is_colliding():
					if $BlockCheck3.is_colliding() and block1_dist < block2_dist and block2_dist <= block3_dist: velocity.y = -232
					if not $BlockCheck3.is_colliding() and block1_dist < block2_dist: velocity.y = -232
				elif not $BlockCheck3.is_colliding() or block3_dist > block1_dist: velocity.y = -232
					
		else: velocity.x = velocity.move_toward(Vector2.ZERO, friction * delta).x
		
		knockback_velocity *= 0.95
		
		soft_collision(delta)
		
		velocity += knockback_velocity
		velocity += soft_collision_velocity
		
		move_and_slide()
		
		if is_on_wall() and not is_on_floor(): velocity.x = 0
	else: velocity = Vector2.ZERO
