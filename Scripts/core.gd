extends Node2D

var spawnpoint
var player
var cam
var peer

func _ready() -> void:
	spawn_player()
	cam = player.get_node("Camera")
	
@rpc("any_peer")
func sync_position(id, player_position):
	$Players.get_node(str(id)).position = player_position
	
func spawn_player():
	player = $Players.get_child(0)
	player.name = str(multiplayer.get_unique_id())
	set_multiplayer_authority(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	NetworkManager.player = player
	$Blocks.player = player
	
func _on_peer_connected(id):
	peer = load("res://Scenes/Entities/Client/PlayerClient.tscn").instantiate()
	peer.name = str(id)
	$Players.add_child(peer)
	if multiplayer.is_server():
		NetworkManager.send_data(id, "world_seed", $Blocks.world_seed)
		
func _on_peer_disconnected(id):
	$Players.get_node(str(id)).queue_free()
	
func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority(): rpc("sync_position", multiplayer.get_unique_id(), $Players.get_node(str(multiplayer.get_unique_id())).position)
