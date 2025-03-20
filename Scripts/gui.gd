extends Control

var inventory = [{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}]

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		$Inventory.visible = !$Inventory.visible
	if Input.is_action_just_pressed("Pause"):
		$Inventory.visible = false
		
func update_inventory(slot):
	if slot <=8:
		get_parent().get_node("HUD/Hotbar/Slots").get_children()[slot].get_node("Item").texture = load("res://Textures/Blocks/" + inventory[slot]["key"] + ".png")
		get_parent().get_node("HUD/Hotbar/Slots").get_children()[slot].get_node("Amount").text = str(inventory[slot].amount)
	else:
		get_node("Inventory/Slots").get_children()[slot - 9].get_node("Item").texture = load("res://Textures/Blocks/" + inventory[slot]["key"] + ".png")
		get_node("Inventory/Slots").get_children()[slot - 9].get_node("Amount").text = str(inventory[slot].amount)
	
func give_item(item, amount):
	for i in range(inventory.size()):
		var slot = inventory[i]
		if !slot.has("key"):
			inventory[i] = {"key": Items.items[item].key, "amount": amount}
			update_inventory(i)
			return
		elif slot.key == Items.items[item].key and slot.amount < Items.items[item].max_stack_size:
			slot["amount"] += amount
			update_inventory(i)
			return
