extends Control

var inventory = [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}]
var selected_item = {}
var selected_hotbar_slot = 0
var hud
@export var player: CharacterBody2D

func _ready() -> void:
	hud = get_parent().get_node("HUD")
	for i in 36:
		if i < 9:
			hud.get_node("Hotbar/Slots").get_child(i).gui_input.connect(slot_clicked.bind(i))
		else:
			$Inventory/Slots.get_child(i - 9).gui_input.connect(slot_clicked.bind(i))
	give_item("wooden_pickaxe")
	give_item("wooden_sword")
	give_item("dirt", 256)

func _process(_delta: float) -> void:
	hotbar_scroll()
	hud.get_node("Selected_Item").position = get_local_mouse_position() - Vector2(32, 32)
	if Input.is_action_just_pressed("Inventory"):
		if !$PauseMenu.visible:
			$Inventory.visible = !$Inventory.visible
			player.can_move = !$Inventory.visible
	if Input.is_action_just_pressed("Pause"):
		if $Inventory.visible:
			$Inventory.visible = false
			player.can_move = true
		elif $PauseMenu.visible:
			LocalData.paused = false
		else:
			LocalData.paused = true
			
	if LocalData.paused:
		$PauseMenu.visible = true
		player.can_move = false
		AudioServer.set_bus_bypass_effects(AudioServer.get_bus_index("Effect_Paused"), false)
	else:
		$PauseMenu.visible = false
		player.can_move = true
		AudioServer.set_bus_bypass_effects(AudioServer.get_bus_index("Effect_Paused"), true)
		
func hotbar_scroll():
	if not Input.is_action_pressed("Zoom"):
		if Input.is_action_just_released("Scroll_Up"):
			selected_hotbar_slot -= 1
			if selected_hotbar_slot < 0: selected_hotbar_slot = 8
			hud.get_node("Selected_Hotbar_Slot").position.x = -272 + (selected_hotbar_slot * 68)
			update_slot(selected_hotbar_slot)
		if Input.is_action_just_released("Scroll_Down"):
			selected_hotbar_slot += 1
			if selected_hotbar_slot > 8: selected_hotbar_slot = 0
			hud.get_node("Selected_Hotbar_Slot").position.x = -272 + (selected_hotbar_slot * 68)
			update_slot(selected_hotbar_slot)
	for i in range(1, 10):
		if Input.is_action_pressed("Number_" + str(i)):
			selected_hotbar_slot = i - 1
			hud.get_node("Selected_Hotbar_Slot").position.x = -272 + (selected_hotbar_slot * 68)
			update_slot(selected_hotbar_slot)
	get_parent().get_node("HUD/Selected_Hotbar_Slot")
		
func update_slot(slot):
	if slot < 9:
		var hotbar_slot = hud.get_node("Hotbar/Slots").get_children()[slot]
		if inventory[slot].has("key") and inventory[slot].amount > 0:
			if AssetManager.cache.has(inventory[slot]["key"]):
				hotbar_slot.get_node("Item").texture = AssetManager.cache[inventory[slot]["key"]]
			else: hotbar_slot.get_node("Item").texture = AssetManager.cache["null"]
			hotbar_slot.get_node("Amount").text = str(inventory[slot]["amount"])
		else:
			hotbar_slot.get_node("Item").texture = null
			hotbar_slot.get_node("Amount").text = ""
			inventory[slot].clear()
		if slot == selected_hotbar_slot and inventory[selected_hotbar_slot].has("key") and AssetManager.cache.has(inventory[slot]["key"]):
			player.get_node("Texture/Held_Item").texture = AssetManager.cache[inventory[slot]["key"]]
		elif !inventory[selected_hotbar_slot].has("key"): player.get_node("Texture/Held_Item").texture = null
		elif inventory[slot].has("key") and inventory[selected_hotbar_slot].has("key") and !AssetManager.cache.has(inventory[slot]["key"]): player.get_node("Texture/Held_Item").texture = AssetManager.cache["null"]
	else:
		var inventory_slot = get_node("Inventory/Slots").get_children()[slot - 9]
		if inventory[slot].has("key") and inventory[slot].amount > 0:
			if AssetManager.cache.has(inventory[slot]["key"]):
				inventory_slot.get_node("Item").texture = AssetManager.cache[inventory[slot]["key"]]
			else: inventory_slot.get_node("Item").texture = AssetManager.cache["null.png"]
			inventory_slot.get_node("Amount").text = str(inventory[slot]["amount"])
		else:
			inventory_slot.get_node("Item").texture = null
			inventory_slot.get_node("Amount").text = ""
			inventory[slot].clear()
	
func give_item(item, amount = 1, slot_index = null):
	var repeat = false
	var true_amount = amount
	amount = clampi(amount, 1, Items.items[item].max_stack_size)
	true_amount -= amount
	if true_amount > 0: repeat = true
	
	if not slot_index:
		for i in range(inventory.size()):
			var slot = inventory[i]
			if slot.has("key") and slot.key == Items.items[item].key and slot.amount < Items.items[item].max_stack_size:
				slot["amount"] += amount
				update_slot(i)
				
				if repeat:
					return give_item(item, true_amount)
				else:
					return
					
		for i in range(inventory.size()):
			var slot = inventory[i]
			if !slot.has("key"):
				inventory[i] = {"key": Items.items[item].key, "amount": amount}
				update_slot(i)
				
				if repeat:
					return give_item(item, true_amount)
				else:
					return
					
	else:
		var slot = inventory[slot_index]
		if !slot.has("key"):
			inventory[slot_index] = {"key": Items.items[item].key, "amount": amount}
			update_slot(slot_index)
				
			if repeat:
				return give_item(item, true_amount)
			else:
				return
					
		elif slot.key == Items.items[item].key and slot.amount < Items.items[item].max_stack_size:
			slot["amount"] += amount
			update_slot(slot_index)
				
			if repeat:
				return give_item(item, true_amount)
			else:
				return

func slot_clicked(event: InputEvent, slot: int):
	var pressed = false
	var rmb = false
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				pressed = true
			MOUSE_BUTTON_RIGHT:
				pressed = true
				rmb = true
			MOUSE_BUTTON_MIDDLE:
				pressed = true
	if pressed:
		if inventory[slot].has("key") and selected_item.has("key"):
			if inventory[slot].key == selected_item.key:
				if !rmb:
					var add_amount = min(selected_item.amount, Items.items[inventory[slot].key].max_stack_size - inventory[slot].amount)
					
					inventory[slot].amount += add_amount
					selected_item.amount -= add_amount
					
					if selected_item.amount > 0:
						hud.get_node("Selected_Item").texture = AssetManager.cache[selected_item.key]
						hud.get_node("Selected_Item/Amount").text = str(selected_item.amount)
					else:
						hud.get_node("Selected_Item").texture = null
						hud.get_node("Selected_Item/Amount").text = ""
						selected_item.clear()
				else:
					inventory[slot].amount += 1
					selected_item.amount -= 1
					hud.get_node("Selected_Item/Amount").text = str(selected_item.amount)
			else:
				var temp = inventory[slot].duplicate()
				inventory[slot] = selected_item.duplicate()
				selected_item = temp
				hud.get_node("Selected_Item").texture = AssetManager.cache[selected_item.key]
				hud.get_node("Selected_Item/Amount").text = str(selected_item["amount"])
		elif inventory[slot].has("key"):
			if !rmb:
				selected_item = inventory[slot].duplicate()
				hud.get_node("Selected_Item").texture = AssetManager.cache[selected_item.key]
				hud.get_node("Selected_Item/Amount").text = str(selected_item["amount"])
				inventory[slot].clear()
			else:
				selected_item = inventory[slot].duplicate()
				selected_item.amount = int(ceil(float(selected_item.amount) / 2))
				inventory[slot].amount -= selected_item.amount
				hud.get_node("Selected_Item").texture = AssetManager.cache[selected_item.key]
				hud.get_node("Selected_Item/Amount").text = str(selected_item["amount"])
		elif selected_item.has("key"):
			inventory[slot] = selected_item.duplicate()
			if !rmb:
				hud.get_node("Selected_Item").texture = null
				hud.get_node("Selected_Item/Amount").text = ""
				selected_item.clear()
			else:
				inventory[slot].amount = 1
				selected_item.amount -= 1
				hud.get_node("Selected_Item/Amount").text = str(selected_item.amount)
		
		if selected_item.has("amount") and selected_item.amount < 1:
			hud.get_node("Selected_Item").texture = null
			hud.get_node("Selected_Item/Amount").text = ""
			selected_item.clear()
		update_slot(slot)


func resume_pressed() -> void:
	LocalData.paused = false


func options_pressed() -> void:
	pass

func quit_pressed() -> void:
	get_tree().quit()
