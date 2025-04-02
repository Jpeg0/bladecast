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

func _ready() -> void:
	entities = get_tree().get_current_scene().get_node("Entities")
	players_folder = get_tree().get_current_scene().get_node("Players")
	tilemap = get_tree().get_current_scene().get_node("Blocks/Foreground_Blocks")
	
func _physics_process(delta: float) -> void:
	if not deloaded and not LocalData.paused and can_move:
		
		if not is_on_floor(): velocity.y += 680 * delta
		else: velocity.y = 0
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
		
		velocity += knockback_velocity
		
		if is_on_wall() and not is_on_floor(): velocity.x = 0
	else: velocity = Vector2.ZERO
	
	move_and_slide()
