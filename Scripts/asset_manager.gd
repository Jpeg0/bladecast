extends Node

var tileset = TileSet.new()
var tileset_updated = true
var cache = {}

func _ready():
	update_cache()
	update_tileset()
	
func update_cache():
	cache["null"] = load("res://Textures/Items/null.png")
	for item in Items.items.values():
		var file_path = "res://Textures/Items/" + item.key + ".png"
		if ResourceLoader.exists(file_path): cache[item.key] = load(file_path)
	
func update_tileset():
	tileset.tile_size = Vector2i(32, 32)
	for item in Items.items.values():
		if item.has("block"):
			var tile_source = TileSetAtlasSource.new()
			tile_source.texture_region_size = Vector2i(32, 32)
			if cache.has(item.key): tile_source.texture = cache[item.key]
			else: tile_source.texture = cache["null"]
			tile_source.create_tile(Vector2i())
			tileset.add_source(tile_source)
	tileset_updated = false
	
func _process(_delta: float) -> void:
	if !tileset_updated:
		if get_tree().current_scene and get_tree().current_scene.name == "World":
			get_tree().current_scene.get_node("Blocks/Foreground_Blocks").tile_set = tileset
			get_tree().current_scene.get_node("Blocks/Background_Blocks").tile_set = tileset
			tileset_updated = true
