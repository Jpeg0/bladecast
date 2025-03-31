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
var dir = 0
var can_move = true
var block_health

func _ready() -> void:
	Sounds.audio_player = $Audioplayer
	set_multiplayer_authority(multiplayer.get_unique_id())
	root = get_tree().get_current_scene()
	foreground_blocks = root.get_node("Blocks/Foreground_Blocks")
	background_blocks = root.get_node("Blocks/Background_Blocks")
	gui = $Camera/OffsetNegator/GUI
	root.get_node("Blocks").viewport_size = get_viewport().get_visible_rect().size / $Camera.zoom / 2
	root.get_node("Blocks").cpos = $Camera.position + position
	chunk_size = root.get_node("Blocks").chunk_size * 32
	var cscale = get_window().size.x / 1920.0
	$Camera.scale = Vector2(cscale, cscale) / $Camera.zoom
	$Components/Health.player = true
	
func player_movement(delta):
	if gamemode == "Survival":
		var direction = Input.get_axis("A", "D")
		if direction == -1:
			dir = -1
			$Texture.scale.x = -1
		elif direction == 1:
			dir = 1
			$Texture.scale.x = 1
		velocity.x = direction * 512
		
		if is_on_floor():
			if velocity.y > 512:
				$Components/Health.apply_damage((velocity.y - 512) / 8)
			velocity.y = 0
			if Input.is_action_pressed("Jump"):
				velocity.y = -232
		else:
			velocity.y += delta * 680
			if velocity.y > 2048: velocity.y = 2048
			
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
		if Items.items[gui.inventory[gui.selected_hotbar_slot].key].has("pickaxe") or Items.items[gui.inventory[gui.selected_hotbar_slot].key].has("block"):
			$Selected_Block.show()
			$Selected_Block.position = (mouse_pos / 32).floor() * 32
		else:
			$Selected_Block.hide()
	
	if not get_viewport().gui_get_hovered_control() and gui.inventory[gui.selected_hotbar_slot].has("key"):
		var mapped_pos = foreground_blocks.local_to_map(mouse_pos)
		if Items.items[gui.inventory[gui.selected_hotbar_slot].key].has("pickaxe"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				
				#if block_health <= 0:
					var i = 0
					for block in Blocks.blocks.values():
						if i == foreground_blocks.get_cell_source_id(mapped_pos):
							$Camera/OffsetNegator/GUI.give_item(block["key"], 1, null)
						i += 1
					NetworkManager.send_block_update(1, true, mapped_pos, null)
		elif Items.items[gui.inventory[gui.selected_hotbar_slot].key].has("block"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				if foreground_blocks.get_cell_source_id(mapped_pos) == -1 and gui.inventory[gui.selected_hotbar_slot].has("key") and Blocks.blocks[gui.inventory[gui.selected_hotbar_slot].key]:
					gui.inventory[gui.selected_hotbar_slot].amount -= 1
					NetworkManager.send_block_update(1, false, mapped_pos, Blocks.blocks[gui.inventory[gui.selected_hotbar_slot].key].id)
					gui.update_slot(gui.selected_hotbar_slot)
		elif Items.items[gui.inventory[gui.selected_hotbar_slot].key].has("weapon"):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				$Texture/Held_Item.item_function(Items.items[gui.inventory[gui.selected_hotbar_slot].key], "LMB")
			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				$Texture/Held_Item.item_function(Items.items[gui.inventory[gui.selected_hotbar_slot].key], "RMB")
		
func camera_zoom() -> void:
	if Input.is_action_just_released("Scroll_Up"): zoom_in()
	elif Input.is_action_just_released("Scroll_Down"): zoom_out()
	
func zoom_in():
	zoom = $Camera.zoom
	zoom += zoom / 10
	if zoom > Vector2(10, 10): zoom = Vector2(10, 10)
	$Camera.zoom = zoom
	var cscale = get_viewport().get_visible_rect().size.x / 1920
	$Camera.scale = Vector2(cscale, cscale) / $Camera.zoom
	root.get_node("Blocks").queue_redraw()
		
func zoom_out():
	zoom = $Camera.zoom
	zoom -= zoom / 10
	if zoom < Vector2(0.1, 0.1): zoom = Vector2(0.1, 0.1)
	$Camera.zoom = zoom
	var cscale = get_viewport().get_visible_rect().size.x / 1920
	$Camera.scale = Vector2(cscale, cscale) / $Camera.zoom
	root.get_node("Blocks").queue_redraw()
		
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Reload"): root.get_node("Blocks").reload()
	current_pos = Vector2i(position / chunk_size) * chunk_size
	prev_zoom = zoom
	if Input.is_action_pressed("Zoom"): camera_zoom()
	if current_pos != prev_pos or zoom != prev_zoom:
		root.get_node("Blocks").viewport_size = get_viewport().get_visible_rect().size / $Camera.zoom / 2
		root.get_node("Blocks").cpos = $Camera.position + position
		root.get_node("Blocks").generate()
	prev_pos = current_pos
	if root.get_node("Blocks").initialised and can_move:
		player_movement(delta)
		clicked()
		var v = velocity.y
		move_and_slide()
		velocity.y = v
