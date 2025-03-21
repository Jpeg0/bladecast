extends CharacterBody2D

const JumpStrength = 128
var block_pos
var player_reach = 128
var foreground_blocks
var background_blocks
var root: Node2D
var soft_collision_velocity = Vector2()
var zoom
var selected_block_colliding = false
var prev_pos = Vector2i()
var chunk_size
var current_pos
var prev_zoom
var gui

func _ready() -> void:
	set_multiplayer_authority(multiplayer.get_unique_id())
	root = get_tree().get_current_scene()
	foreground_blocks = root.get_node("Blocks/Foreground_Blocks")
	background_blocks = root.get_node("Blocks/Background_Blocks")
	gui = $Camera/GUI
	root.get_node("Blocks").viewport_size = get_viewport().get_visible_rect().size / $Camera.zoom / 2
	root.get_node("Blocks").cpos = $Camera.position + position
	root.get_node("Blocks").generate()
	chunk_size = root.get_node("Blocks").chunk_size * 16
	
func player_movement(delta):
	velocity.x = Input.get_axis("A", "D") * 128
	if is_on_floor():
		velocity.y = 0
		if Input.is_action_pressed("Jump"):
			velocity.y = -232
		return
	velocity.y += delta * 680
	
func block_clicked():
	var mouse_pos: Vector2 = get_global_mouse_position()
	var offset_pos = mouse_pos - position
	if offset_pos.length() > player_reach: mouse_pos = position + offset_pos.normalized() * player_reach
	
	$Selected_Block.position = (mouse_pos / 32).floor() * 32
	
	if not get_viewport().gui_get_hovered_control():
		var mapped_pos = foreground_blocks.local_to_map(mouse_pos)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			for block in Items.items.values():
				if block.has("block") and block["block"]["atlas"] == foreground_blocks.get_cell_atlas_coords(mapped_pos):
					$Camera/GUI.give_item(block["key"], 1, null)
			NetworkManager.send_block_update(1, true, mapped_pos, null)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if foreground_blocks.get_cell_source_id(mapped_pos) == -1 and gui.inventory[gui.selected_hotbar_slot].has("key") and Items.items[gui.inventory[gui.selected_hotbar_slot].key].has("block"):
				gui.inventory[gui.selected_hotbar_slot].amount -= 1
				NetworkManager.send_block_update(1, false, mapped_pos, Items.items[gui.inventory[gui.selected_hotbar_slot].key].block.atlas)
				gui.update_slot(gui.selected_hotbar_slot)
		
func camera_zoom() -> void:
	if Input.is_action_just_released("Scroll_Up"): zoom_in()
	elif Input.is_action_just_released("Scroll_Down"): zoom_out()
	
func zoom_in():
	zoom = $Camera.zoom
	zoom += zoom / 10
	if zoom > Vector2(10, 10): zoom = Vector2(10, 10)
	$Camera.zoom = zoom
	$Camera.scale = Vector2(1, 1) / $Camera.zoom
		
func zoom_out():
	zoom = $Camera.zoom
	zoom -= zoom / 10
	if zoom < Vector2(0.1, 0.1): zoom = Vector2(0.1, 0.1)
	$Camera.zoom = zoom
	$Camera.scale = Vector2(1, 1) / $Camera.zoom
		
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
	current_pos = Vector2i(position / chunk_size) * chunk_size
	prev_zoom = zoom
	if Input.is_action_pressed("Zoom"): camera_zoom()
	if current_pos != prev_pos or zoom != prev_zoom:
		root.get_node("Blocks").viewport_size = get_viewport().get_visible_rect().size / $Camera.zoom / 2
		root.get_node("Blocks").cpos = $Camera.position + position
		root.get_node("Blocks").generate()
	prev_pos = current_pos
	velocity += soft_collision_velocity
	move_and_slide()
