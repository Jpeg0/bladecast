extends Node2D

var terrain_noise = FastNoiseLite.new()
var generated_blocks = {}
var updated_blocks = {}
var erase
var erase_background
var atlas
var atlas_background
var dirt_atlas = Vector2i(1, 0)
var grass_atlas = Vector2i(2, 0)
var stone_atlas = Vector2i(4, 0)
var player
var world_seed
var spawnpoint

func _ready() -> void:
	if multiplayer.is_server():
		world_seed = randi()
		terrain_noise.seed = world_seed
		spawnpoint = Vector2(8, terrain_noise.get_noise_1d(0) * 16)

func gen_surface_terrain(x: int, y: int) -> void:
	var terrain_height: float = terrain_noise.get_noise_1d(x) * 16
	erase = false
	erase_background = false
	if y > terrain_height: atlas = dirt_atlas
	if y >= terrain_height + 16 and atlas == dirt_atlas: atlas = stone_atlas
	if y - 1 < terrain_height and atlas == dirt_atlas: atlas = grass_atlas
	if y <= terrain_height: erase = true
	if erase: erase_background = true
	else: atlas_background = atlas
	if atlas_background == grass_atlas: atlas_background = dirt_atlas
	
func generate() -> void:
		var camera: Camera2D = player.get_node("Camera")
		var viewport_size: Vector2 = (get_viewport().get_visible_rect().size / camera.zoom) / 2
		var cpos: Vector2 = camera.position + player.position
		var generate_area_min: Vector2 = (cpos - viewport_size) / 16
		var generate_area_max:Vector2 = (cpos + viewport_size) / 16
		var block: Vector2i = Vector2i()
		for x in range(generate_area_min.x - 2, generate_area_max.x + 2):
			block.x = x
			for y in range(generate_area_min.y - 2, generate_area_max.y + 2):
				block.y = y
				if !generated_blocks.has(block):
					generated_blocks[block] = true
					if !updated_blocks.has(block):
						terrain_noise.frequency = 0.01
						gen_surface_terrain(x, y)
						if erase: $Foreground_Blocks.erase_cell(block)
						else: $Foreground_Blocks.set_cell(block, 0, atlas)
					
func _process(_delta: float) -> void:
	if NetworkManager.Ncache.has("world_seed"): world_seed = NetworkManager.Ncache["world_seed"]
	if world_seed and player:
		terrain_noise.seed = world_seed
		generate()
