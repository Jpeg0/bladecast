extends Node

var blocks = {}

func _ready() -> void:
	var i = 0
	for item in Items.items.values():
		if item.has("block"):
			blocks[item.key] = {"key": item.key, "id": i}
			i += 1
