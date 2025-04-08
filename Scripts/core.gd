extends Node2D

var cam
var peer
var players
var player
var blocks
var connected = false
var player_client = preload("res://Scenes/Entities/Client/PlayerClient.tscn")

func _physics_process(_delta: float) -> void:
	if connected and is_multiplayer_authority(): rpc("sync_position", multiplayer.get_unique_id(), player.position)
	
func _ready() -> void:
	players = $Entities/Players
	blocks = $Blocks
	spawn_player()
	cam = player.get_node("Camera")
	
func spawn_player():
	player = players.get_child(0)
	player.name = str(multiplayer.get_unique_id())
	set_multiplayer_authority(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	NetworkManager.player = player
	await get_tree().create_timer(1).timeout
	connected = true
	
func _on_peer_connected(id):
	peer = player_client.instantiate()
	peer.name = str(id)
	players.add_child(peer)
	if multiplayer.is_server():
		NetworkManager.send_data(id, "world_seed", blocks.world_seed)
		
func _on_peer_disconnected(id):
	players.get_node(str(id)).queue_free()
	
@rpc("any_peer")
func sync_position(id, player_position):
	$Entities/Players.get_node(str(id)).position = player_position
