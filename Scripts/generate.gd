extends Node2D

var terrain_noise = FastNoiseLite.new()
var biome_temperature_noise = FastNoiseLite.new()
var coal_ore_noise = FastNoiseLite.new()
var iron_ore_noise = FastNoiseLite.new()
var generated_chunks = {}
var updated_blocks = {}
var erase
var erase_background
var block_id
var background_block_id
var block_ids = {}
var player
var world_seed
var spawnpoint
var coal_ore_thresh: float = -0.9
var coal_ore_rarity: int = 25
var iron_ore_thresh: float = -0.95
var iron_ore_rarity: int = 50
var initialised = false
var rng = RandomNumberGenerator.new()
var camera: Camera2D
var chunk_size = 32
var viewport_size: Vector2
var cpos

func reload():
	if multiplayer.is_server():
		world_seed = randi()
		terrain_noise.seed = world_seed
		spawnpoint = Vector2(8, terrain_noise.get_noise_1d(0) * 16)
	initialised = false
	generated_chunks = {}
	updated_blocks = {}
	$Foreground_Blocks.clear()
	$Background_Blocks.clear()
	$Collision.clear()

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
	
	rng.seed = coal_ore_noise.seed
	
	biome_temperature_noise.seed = rng.randi()
	
	for block in Blocks.blocks.values():
		block_ids[block.key] = block.id
	
	camera = player.get_node("Camera")
	initialised = true
	player.get_node("Camera/OffsetNegator/HUD/Debug_Menu/Left/Seed").text = "seed: " + str(world_seed)
	generate()
	await get_tree().create_timer(0.1).timeout
	player.position = spawnpoint + Vector2(0, -32)

func gen_surface_terrain(x: int, y: int, biome: Array) -> void:
	var terrain_height = terrain_noise.get_noise_1d(x) * 16
	var biome_top_layer_block_id = block_ids["grass"]
	var biome_subsurface_block_id = block_ids["dirt"]
	var biome_stone_block_id = block_ids["stone"]

	match biome[0]:
		"Desert":
			biome_top_layer_block_id = block_ids["sand"]
		"Jungle":
			biome_top_layer_block_id = block_ids["moss"]
		"Plains":
			pass
		"Taiga":
			biome_top_layer_block_id = block_ids["snow"]
		"Mountains":
			biome_top_layer_block_id = block_ids["ice"]
			terrain_height = lerp(terrain_noise.get_noise_1d(x) * 16, terrain_noise.get_noise_1d(x) * 16 ** 2, biome[1])

			
	erase = false
	erase_background = false
	if y > terrain_height: block_id = biome_subsurface_block_id
	if y >= terrain_height + 8 and block_id == biome_subsurface_block_id: block_id = biome_stone_block_id
	if y - 1 < terrain_height and block_id == biome_subsurface_block_id: block_id = biome_top_layer_block_id
	if y <= terrain_height: erase = true
	if erase: erase_background = true
	else: background_block_id = block_id
	if background_block_id == biome_top_layer_block_id: background_block_id = biome_subsurface_block_id

func gen_ores(x: int, y: int) -> void:
	coal_ore_noise.frequency = 1.0 / coal_ore_rarity
	iron_ore_noise.frequency = 1.0 / iron_ore_rarity
	
	if coal_ore_noise.get_noise_2d(x, y) < coal_ore_thresh: block_id = block_ids["coal_ore"]
	elif iron_ore_noise.get_noise_2d(x, y) < iron_ore_thresh: block_id = block_ids["iron_ore"]
	
func gen_caves(x: int, y: int) -> void:
	terrain_noise.frequency = 0.004
	if terrain_noise.get_noise_2d(x * 4, y * 4) > 0.4: erase = true
	
func get_biome(x, _y):
	var surface_temperature_noise = biome_temperature_noise.get_noise_1d(x / 10)
	
	if surface_temperature_noise <= 1 and surface_temperature_noise > 0.6:
		
		return ["Desert", surface_temperature_noise]
		
	elif surface_temperature_noise <= 0.6 and surface_temperature_noise > 0.2:
		
		return ["Jungle", surface_temperature_noise]
		
	elif surface_temperature_noise <= 0.2 and surface_temperature_noise > -0.2:
		
		return ["Plains", surface_temperature_noise]
		
	elif surface_temperature_noise <= -0.2 and surface_temperature_noise > -0.6:
		
		return ["Taiga", surface_temperature_noise]
		
	else:
		
		return ["Mountains", 1.66666666666666666 * -0.6 + 1]
		
	
func force_generate(block, x, y):
	var biome = get_biome(x, y)
	terrain_noise.frequency = 0.01
	gen_surface_terrain(x, y, biome)
	if block_id == block_ids["stone"]: gen_ores(x, y)
	gen_caves(x, y)
	
	if erase: $Foreground_Blocks.erase_cell(block)
	else:
		$Foreground_Blocks.set_cell(block, block_id, Vector2i())
		$Collision.set_cell(block, 0, Vector2i())
	if erase_background: $Background_Blocks.erase_cell(block)
	else: $Background_Blocks.set_cell(block, background_block_id, Vector2i())
		
func generate() -> void:
	if initialised:
		for cx in range(floor((cpos.x - viewport_size.x) / chunk_size / 32) - 1, ceil((cpos.x + viewport_size.x) / chunk_size / 32) + 1):
			for cy in range(floor((cpos.y - viewport_size.y) / chunk_size / 32) - 1, ceil((cpos.y + viewport_size.y) / chunk_size / 32) + 1):
				var chunk = Vector2i(cx, cy)
				if !generated_chunks.has(chunk):
					generated_chunks[chunk] = chunk
					await get_tree().process_frame
					for x in range(chunk.x * chunk_size, (chunk.x + 1) * chunk_size):
						for y in range(chunk.y * chunk_size, (chunk.y + 1) * chunk_size):
							var block = Vector2i(x, y)
							if !updated_blocks.has(block):
								force_generate(block, x, y)
					
func _process(_delta: float) -> void:
	if not world_seed and NetworkManager.Ncache.has("world_seed"): world_seed = NetworkManager.Ncache["world_seed"]
	if world_seed and player and not initialised: initialise()
