extends Node2D

var terrain_noise = FastNoiseLite.new()
var coal_ore_noise = FastNoiseLite.new()
var iron_ore_noise = FastNoiseLite.new()
var generated_chunks = {}
var updated_blocks = {}
var erase
var erase_background
var atlas
var atlas_background
var coal_ore_atlas = Vector2i(0, 0)
var dirt_atlas = Vector2i(1, 0)
var grass_atlas = Vector2i(2, 0)
var iron_ore_atlas = Vector2i(3, 0)
var stone_atlas = Vector2i(4, 0)
var player
var world_seed
var spawnpoint
var coal_ore_thresh: float = -0.91
var coal_ore_rarity: int = 25
var iron_ore_thresh: float = -0.95
var iron_ore_rarity: int = 50
var initialised = false
var rng = RandomNumberGenerator.new()
var camera: Camera2D
var chunk_size = 32
var viewport_size: Vector2
var cpos

func _ready() -> void:
	if multiplayer.is_server():
		world_seed = randi()
		terrain_noise.seed = world_seed
		spawnpoint = Vector2(8, terrain_noise.get_noise_1d(0) * 16)
		
func initialise():
	terrain_noise.seed = world_seed
	rng.seed = world_seed
	
	coal_ore_noise.seed = rng.randi()
	coal_ore_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	coal_ore_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	coal_ore_noise.domain_warp_enabled = true
	coal_ore_noise.domain_warp_amplitude = 15
	
	rng.seed = coal_ore_noise.seed
	
	iron_ore_noise.seed = rng.randi()
	iron_ore_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	iron_ore_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	iron_ore_noise.domain_warp_enabled = true
	iron_ore_noise.domain_warp_amplitude = 15
	camera = player.get_node("Camera")
	initialised = true
	player.get_node("Camera/HUD/Debug_Menu/Left/Seed").text = "seed: " + str(world_seed)
	generate()

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

func gen_ores(x: int, y: int) -> void:
	coal_ore_noise.frequency = 1.0 / coal_ore_rarity
	iron_ore_noise.frequency = 1.0 / iron_ore_rarity
	
	if coal_ore_noise.get_noise_2d(x, y) < coal_ore_thresh: atlas = coal_ore_atlas
	elif iron_ore_noise.get_noise_2d(x, y) < iron_ore_thresh: atlas = iron_ore_atlas
	
func gen_caves(x: int, y: int) -> void:
	terrain_noise.frequency = 0.004
	if terrain_noise.get_noise_2d(x * 4, y * 4) > 0.4: erase = true
	
func force_generate(layer, block, x, y):
	terrain_noise.frequency = 0.01
	gen_surface_terrain(x, y)
	if atlas == stone_atlas: gen_ores(x, y)
	gen_caves(x, y)
	if layer == "all":
		if erase: $Foreground_Blocks.erase_cell(block)
		else: $Foreground_Blocks.set_cell(block, 0, atlas)
		if erase_background: $Background_Blocks.erase_cell(block)
		else: $Background_Blocks.set_cell(block, 0, atlas_background)
	elif layer == "foreground":
		if erase: $Foreground_Blocks.erase_cell(block)
		else: $Foreground_Blocks.set_cell(block, 0, atlas)
	elif layer == "background":
		if erase_background: $Background_Blocks.erase_cell(block)
		else: $Background_Blocks.set_cell(block, 0, atlas_background)
		
func generate() -> void:
	if initialised:
		for cx in range(floor((cpos.x - viewport_size.x) / chunk_size / 32) - 1, ceil((cpos.x + viewport_size.x) / chunk_size / 32) + 1):
			for cy in range(floor((cpos.y - viewport_size.y) / chunk_size / 32) - 1, ceil((cpos.y + viewport_size.y) / chunk_size / 32) + 1):
				var chunk = Vector2i(cx, cy)
				if !generated_chunks.has(chunk):
					generated_chunks[chunk] = true
					for x in range(chunk.x * chunk_size, (chunk.x + 1) * chunk_size):
						for y in range(chunk.y * chunk_size, (chunk.y + 1) * chunk_size):
							var block = Vector2i(x, y)
							if !updated_blocks.has(block):
								force_generate("all", block, x, y)

					
func _process(_delta: float) -> void:
	if not world_seed and NetworkManager.Ncache.has("world_seed"): world_seed = NetworkManager.Ncache["world_seed"]
	if world_seed and player and not initialised: initialise()
