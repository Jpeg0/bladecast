extends Node2D

var Ncache = {}
var player

@rpc("authority", "call_local")
func send_data(id, variable, data):
	if str(id) == "all":
		if multiplayer.is_server() and multiplayer.has_multiplayer_peer():
			rpc("receive_data", variable, data)
	else:
		if multiplayer.is_server() and multiplayer.has_multiplayer_peer():
			rpc_id(int(id), "receive_data", variable, data)
	
func send_block_update(layer, erase, block, block_id):
	update_block(layer, erase, block, block_id)
	rpc("update_block", layer, erase, block, block_id)
	
func send_entity_update(entity, update_type, data):
	update_entity(entity, update_type, data)
	rpc("update_entity", entity, update_type, data)
		
@rpc("any_peer")
func update_entity(entity, update_type, data):
	if update_type == "Component":
		get_tree().get_current_scene().get_node("Entities/" + entity).get_node("Components/" + data[0]).callv(data[1], data[2])
	
@rpc("any_peer")
func update_block(layer, erase, block, block_id):
	get_tree().get_current_scene().get_node("Blocks").updated_blocks[block] = true
	if layer == 1:
		if erase:
			get_tree().get_current_scene().get_node("Blocks/Foreground_Blocks").erase_cell(block)
			get_tree().get_current_scene().get_node("Blocks/Collision").erase_cell(block)
		else:
			get_tree().get_current_scene().get_node("Blocks/Foreground_Blocks").set_cell(block, block_id, Vector2i())
			get_tree().get_current_scene().get_node("Blocks/Collision").set_cell(block, 0, Vector2i())
	elif layer == 0:
		if erase:
			get_tree().get_current_scene().get_node("Blocks/Background_Blocks").erase_cell(block)
		else:
			get_tree().get_current_scene().get_node("Blocks/Background_Blocks").set_cell(block, block_id, Vector2i())
			
@rpc("any_peer")
func receive_data(variable, data):
	if player:
		Ncache[variable] = data
