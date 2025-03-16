extends Control

@export var ip: String = "127.0.0.1"
@export var port: int = 2048
var player: ENetMultiplayerPeer

func play_button_pressed() -> void:
	player = ENetMultiplayerPeer.new()
	if player.create_server(port, 32) != OK: return
	multiplayer.set_multiplayer_peer(player)
	get_tree().change_scene_to_file("res://Scenes/World.tscn")

func join_button_pressed() -> void:
	player = ENetMultiplayerPeer.new()
	player.create_client(ip, port)
	multiplayer.set_multiplayer_peer(player)
	get_tree().change_scene_to_file("res://Scenes/World.tscn")
