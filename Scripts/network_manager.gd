extends Node

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
	
func send_block_update(layer, erase, block, atlas):
	update_block(layer, erase, block, atlas)
	rpc("update_block", layer, erase, block, atlas)
	
@rpc("any_peer")
func update_block(layer, erase, block, atlas):
	get_tree().get_current_scene().get_node("Blocks").updated_blocks[block] = true
	if layer == 1:
		if erase:
			get_tree().get_current_scene().get_node("Blocks/Foreground_Blocks").erase_cell(block)
		else:
			get_tree().get_current_scene().get_node("Blocks/Foreground_Blocks").set_cell(block, 0, atlas)
	elif layer == 0:
		if erase:
			get_tree().get_current_scene().get_node("Blocks/Background_Blocks").erase_cell(block)
		else:
			get_tree().get_current_scene().get_node("Blocks/Background_Blocks").set_cell(block, 0, atlas)
			
@rpc("any_peer")
func receive_data(variable, data):
	if player:
		Ncache[variable] = data
