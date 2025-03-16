extends CharacterBody2D

const JumpStrength = 128
var block_pos
var player_reach = 128
var foreground_blocks
var background_blocks
var root: Node2D
var soft_collision_velocity = Vector2()

func _ready() -> void:
	set_multiplayer_authority(multiplayer.get_unique_id())
	root = get_tree().get_current_scene()
	foreground_blocks = root.get_node("Blocks/Foreground_Blocks")
	background_blocks = root.get_node("Blocks/Background_Blocks")
	
func player_movement(delta):
	velocity.x = Input.get_axis("A", "D") * 128
	if Input.is_action_pressed("Jump") and is_on_floor(): velocity.y = -256
	if not is_on_floor(): velocity.y += delta * 640
	
func block_clicked():
	var mouse_pos: Vector2 = get_global_mouse_position()
	if (mouse_pos - position).length() > player_reach: mouse_pos = position + (mouse_pos - position).normalized() * player_reach
	$Selected_Block.position = round((mouse_pos - Vector2(16, 16)) / 32) * 32
	block_pos = foreground_blocks.local_to_map(mouse_pos)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		NetworkManager.send_block_update(1, true, block_pos, null)
		
func soft_collision():
	for entity in root.get_node("Entities").get_children() + root.get_node("Players").get_children():
		if (entity.position - position).length() < 56 and abs(entity.position.x - position.x) < 24: soft_collision_velocity.x += -sign(entity.position.x - position.x) * 16
		if abs(soft_collision_velocity.x) >= 1:
			soft_collision_velocity.x = clamp(soft_collision_velocity.x, -64, 64)
			soft_collision_velocity.x *= 0.75
		else: soft_collision_velocity.x = 0
		
func _process(delta: float) -> void:
	player_movement(delta)
	block_clicked()
	soft_collision()
	velocity += soft_collision_velocity
	move_and_slide()
