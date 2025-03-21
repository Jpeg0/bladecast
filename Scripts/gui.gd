extends Control

var inventory = [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}]
var selected_item = {}
var selected_hotbar_slot = 0
var hud

func _ready() -> void:
	hud = get_parent().get_node("HUD")
	for i in 36:
		if i < 9:
			hud.get_node("Hotbar/Slots").get_child(i).gui_input.connect(slot_clicked.bind(i))
		else:
			$Inventory/Slots.get_child(i - 9).gui_input.connect(slot_clicked.bind(i))

func _process(_delta: float) -> void:
	hotbar_scroll()
	hud.get_node("Selected_Item").position = get_local_mouse_position() - Vector2(32, 32)
	if Input.is_action_just_pressed("Inventory"):
		$Inventory.visible = !$Inventory.visible
	if Input.is_action_just_pressed("Pause"):
		$Inventory.visible = false
		
func hotbar_scroll():
	if not Input.is_action_pressed("Zoom"):
		if Input.is_action_just_released("Scroll_Up"):
			selected_hotbar_slot -= 1
			if selected_hotbar_slot > 8: selected_hotbar_slot = 0
			hud.get_node("Selected_Hotbar_Slot").position.x = -272 + (selected_hotbar_slot * 68)
		if Input.is_action_just_released("Scroll_Down"):
			selected_hotbar_slot += 1
			if selected_hotbar_slot < 0: selected_hotbar_slot = 8
			hud.get_node("Selected_Hotbar_Slot").position.x = -272 + (selected_hotbar_slot * 68)
	get_parent().get_node("HUD/Selected_Hotbar_Slot")
		
func update_slot(slot):
	if slot < 9:
		var hotbar_slot = hud.get_node("Hotbar/Slots").get_children()[slot]
		if inventory[slot].has("key") and inventory[slot].amount > 0:
			hotbar_slot.get_node("Item").texture = load("res://Textures/Blocks/" + inventory[slot]["key"] + ".png")
			hotbar_slot.get_node("Amount").text = str(inventory[slot]["amount"])
		else:
			hotbar_slot.get_node("Item").texture = null
			hotbar_slot.get_node("Amount").text = ""
			inventory[slot].clear()
	else:
		var inventory_slot = get_node("Inventory/Slots").get_children()[slot - 9]
		if inventory[slot].has("key") and inventory[slot].amount > 0:
			inventory_slot.get_node("Item").texture = load("res://Textures/Blocks/" + inventory[slot]["key"] + ".png")
			inventory_slot.get_node("Amount").text = str(inventory[slot]["amount"])
		else:
			inventory_slot.get_node("Item").texture = null
			inventory_slot.get_node("Amount").text = ""
			inventory[slot].clear()
	
func give_item(item, amount, slot_index):
	if not slot_index:
		for i in range(inventory.size()):
			var slot = inventory[i]
			if !slot.has("key"):
				inventory[i] = {"key": Items.items[item].key, "amount": amount}
				update_slot(i)
				return
			elif slot.key == Items.items[item].key and slot.amount < Items.items[item].max_stack_size:
				slot["amount"] += amount
				update_slot(i)
				return
	else:
		var slot = inventory[slot_index]
		if !slot.has("key"):
			inventory[slot_index] = {"key": Items.items[item].key, "amount": amount}
			update_slot(slot_index)
			return
		elif slot.key == Items.items[item].key and slot.amount < Items.items[item].max_stack_size:
			slot["amount"] += amount
			update_slot(slot_index)
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
				inventory[slot].amount += selected_item.amount
				hud.get_node("Selected_Item").texture = null
				hud.get_node("Selected_Item/Amount").text = ""
				selected_item.clear()
			else:
				var temp = inventory[slot].duplicate()
				inventory[slot] = selected_item.duplicate()
				selected_item = temp
				hud.get_node("Selected_Item").texture = load("res://Textures/Items/" + selected_item["key"] + ".png")
				hud.get_node("Selected_Item/Amount").text = str(selected_item["amount"])
		elif inventory[slot].has("key"):
			if !rmb:
				selected_item = inventory[slot].duplicate()
				hud.get_node("Selected_Item").texture = load("res://Textures/Items/" + selected_item["key"] + ".png")
				hud.get_node("Selected_Item/Amount").text = str(selected_item["amount"])
				inventory[slot].clear()
			else:
				selected_item = inventory[slot].duplicate()
				print(selected_item.amount)
				selected_item.amount = int(ceil(float(selected_item.amount) / 2))
				print(selected_item.amount)
				inventory[slot].amount -= selected_item.amount
				hud.get_node("Selected_Item").texture = load("res://Textures/Items/" + selected_item["key"] + ".png")
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
