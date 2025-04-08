extends CharacterBody2D

const JumpStrength = 128
var block_pos
var player_reach = 128
var foreground_blocks
var background_blocks
var root: Node2D
var zoom
var selected_block_colliding = false
var prev_pos = Vector2i()
var chunk_size
var current_pos
var prev_zoom
var gui
var gamemode = "Survival"
var can_move = true
var block_health
var movespeed = 256
var friction = 2048
var acceleration = 2048
var use_friction = false
var blocks
var camera
var selected_block
var texture
var in_loaded_chunk = false

func _ready() -> void:
	LocalData.player = self
	texture = $Texture
	camera = $Camera
	AudioManager.audio_player = $AudioStreamPlayers
	selected_block = $Selected_Block
	set_multiplayer_authority(multiplayer.get_unique_id())
	root = get_tree().get_current_scene()
	blocks = root.get_node("Blocks")
	foreground_blocks = root.get_node("Blocks/Foreground_Blocks")
	background_blocks = root.get_node("Blocks/Background_Blocks")
	gui = camera.get_node("OffsetNegator/GUI")
	blocks.viewport_size = get_viewport().get_visible_rect().size / camera.zoom / 2
	blocks.cpos = camera.position + position
	chunk_size = blocks.chunk_size * 32
	var cscale = get_window().size.x / 1920.0
	camera.scale = Vector2(cscale, cscale) / camera.zoom
	$Components/Health.player = true
	zoom_out()
	
func player_movement(delta):
	if gamemode == "Survival":
		var dir = Input.get_axis("A", "D")
		if dir != 0: $Texture.scale.x = dir
			
		if use_friction:
			if dir != 0: velocity.x = velocity.move_toward(Vector2(movespeed * dir, velocity.y), acceleration * delta).x
			else: velocity.x = velocity.move_toward(Vector2.ZERO, friction * delta).x
		else:
			velocity.x = dir * movespeed
			
		velocity.x = clamp(velocity.x, -movespeed, movespeed)
		
		if is_on_floor():
			velocity.y = 0
			if Input.is_action_pressed("Jump"):
				velocity.y = -232
		else:
			velocity.y += delta * 680
			if velocity.y > 2048: velocity.y = 2048
			
		if is_on_wall():
			for collision in range(get_slide_collision_count()):
				if get_slide_collision(collision).get_normal().x == -dir:
					velocity.x = 0
			
	elif gamemode == "Creative":
		velocity.x = Input.get_axis("A", "D") * 512
		var negative = float(Input.is_action_pressed("Up") or Input.is_action_pressed("Jump"))
		var positive = float(Input.is_action_pressed("Down"))
		velocity.y = (positive - negative) * 512
	
func clicked():
	var mouse_pos: Vector2 = get_global_mouse_position()
	var offset_pos = mouse_pos - position
	if offset_pos.length() > player_reach: mouse_pos = position + offset_pos.normalized() * player_reach
	
	if gui.inventory[gui.selected_hotbar_slot].has("key"):
		if AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key].has("pickaxe") or AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key].has("block"):
			selected_block.show()
			selected_block.position = (mouse_pos / 32).floor() * 32
		else:
			selected_block.hide()
	else:
		selected_block.hide()
	
	if not get_viewport().gui_get_hovered_control() and gui.inventory[gui.selected_hotbar_slot].has("key"):
		var mapped_pos = foreground_blocks.local_to_map(mouse_pos)
		var mapped_pos_source_id = foreground_blocks.get_cell_source_id(mapped_pos)
		if AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key].has("pickaxe"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var i = 0
				for block in AssetManager.blocks.values():
					if i == mapped_pos_source_id:
						gui.give_item(block["key"], 1, null)
					i += 1
					NetworkManager.send_block_update(1, true, mapped_pos, null)
		elif AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key].has("block"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				if foreground_blocks.get_cell_source_id(mapped_pos) == -1 and gui.inventory[gui.selected_hotbar_slot].has("key") and AssetManager.blocks[gui.inventory[gui.selected_hotbar_slot].key]:
					gui.inventory[gui.selected_hotbar_slot].amount -= 1
					NetworkManager.send_block_update(1, false, mapped_pos, AssetManager.blocks[gui.inventory[gui.selected_hotbar_slot].key].id)
					gui.update_slot(gui.selected_hotbar_slot)
		elif AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key].has("weapon"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				$Texture/Held_Item.item_function(AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key], "LMB")
			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				$Texture/Held_Item.item_function(AssetManager.items[gui.inventory[gui.selected_hotbar_slot].key], "RMB")
		
func camera_zoom() -> void:
	if Input.is_action_just_released("Scroll_Up"): zoom_in()
	elif Input.is_action_just_released("Scroll_Down"): zoom_out()
	
func zoom_in():
	zoom = camera.zoom
	zoom += zoom / 10
	if zoom > Vector2(8, 8): zoom = Vector2(8, 8)
	camera.zoom = zoom
	var cscale = get_viewport().get_visible_rect().size.x / 1920
	camera.scale = Vector2(cscale, cscale) / camera.zoom
	blocks.queue_redraw()
		
func zoom_out():
	zoom = camera.zoom
	zoom -= zoom / 10
	if zoom < Vector2(0.25, 0.25): zoom = Vector2(0.25, 0.25)
	camera.zoom = zoom
	var cscale = get_viewport().get_visible_rect().size.x / 1920
	camera.scale = Vector2(cscale, cscale) / camera.zoom
	blocks.queue_redraw()
		
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Reload"): blocks.reload()
	current_pos = Vector2i(position / chunk_size) * chunk_size
	prev_zoom = zoom
	if Input.is_action_pressed("Zoom"): camera_zoom()
	if current_pos != prev_pos or zoom != prev_zoom:
		blocks.viewport_size = get_viewport().get_visible_rect().size / camera.zoom / 2
		blocks.cpos = camera.position + position
		blocks.generate()
		
		if camera.scale.x >= 2: AssetManager.set_lod(16)
		elif camera.scale.x >= 1: AssetManager.set_lod(24)
		else: AssetManager.set_lod(32)
		
	prev_pos = current_pos
	if can_move and in_loaded_chunk:
		player_movement(delta)
		clicked()
		var v = velocity.y
		move_and_slide()
		velocity.y = v
