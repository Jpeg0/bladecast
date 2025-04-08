extends Node2D

var terrain_noise = FastNoiseLite.new()
var biome_temperature_noise = FastNoiseLite.new()
var coal_ore_noise = FastNoiseLite.new()
var iron_ore_noise = FastNoiseLite.new()
var generated_chunks = {}
var updated_blocks = {}
var completed_chunks = {}
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
var root
var foreground_blocks
var background_blocks
var collision_blocks
var shadow_size = 2
var min_x
var max_x
var min_y
var max_y

func reload():
	if multiplayer.is_server():
		world_seed = randi()
		terrain_noise.seed = world_seed
		spawnpoint = Vector2(8, terrain_noise.get_noise_1d(0) * 16 - 32)
	initialised = false
	generated_chunks = {}
	updated_blocks = {}
	foreground_blocks.clear()
	background_blocks.clear()
	collision_blocks.clear()

func _ready() -> void:
	foreground_blocks = $Foreground_Blocks
	background_blocks = $Background_Blocks
	collision_blocks = $Collision_Blocks
	collision_blocks.set_process(false)
	root = get_parent()
	if multiplayer.is_server():
		world_seed = randi()
		terrain_noise.seed = world_seed
		
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
	
	for _block in AssetManager.blocks.values():
		block_ids[_block.key] = _block.id
	
	player = root.player
	camera = player.get_node("Camera")
	initialised = true
	player.get_node("Camera/OffsetNegator/HUD/Debug_Menu/Left/Seed").text = "seed: " + str(world_seed)
	generate()
	await get_tree().create_timer(0.1).timeout
	spawnpoint = Vector2(8, terrain_noise.get_noise_1d(0) * 16 - 32)
	player.position = spawnpoint

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
		
		return ["Mountains", 1.666 * -0.6 + 1]
		
	
func force_generate(_block, x, y):
	var biome = get_biome(x, y)
	terrain_noise.frequency = 0.01
	gen_surface_terrain(x, y, biome)
	if block_id == block_ids["stone"]: gen_ores(x, y)
	gen_caves(x, y)
	
	if erase: foreground_blocks.erase_cell(_block)
	else:
		foreground_blocks.set_cell(_block, block_id, Vector2i())
		collision_blocks.set_cell(_block, 0, Vector2i())
	if erase_background: background_blocks.erase_cell(_block)
	else: background_blocks.set_cell(_block, background_block_id, Vector2i())
		
func generate() -> void:
	if initialised:
		min_x = floor((cpos.x - viewport_size.x) / chunk_size / 32) - 1
		max_x = ceil((cpos.x + viewport_size.x) / chunk_size / 32) + 1
		min_y = floor((cpos.y - viewport_size.y) / chunk_size / 32) - 1
		max_y = ceil((cpos.y + viewport_size.y) / chunk_size / 32) + 1
	
		for cx in range(min_x, max_x):
			for cy in range(min_y, max_y):
				if !generated_chunks.has(Vector2i(cx, cy)):
					var chunk = Vector2i(cx, cy)
					generated_chunks[chunk] = chunk
					await get_tree().process_frame
					for x in range(cx * chunk_size, (cx + 1) * chunk_size):
						for y in range(cy * chunk_size, (cy + 1) * chunk_size):
							var block = Vector2i(x, y)
							if !updated_blocks.has(block):
								force_generate(block, x, y)

								
		for generated_chunk in generated_chunks.values():
			if !(generated_chunk.x >= min_x - shadow_size and generated_chunk.x <= max_x + shadow_size and generated_chunk.y >= min_y - shadow_size and generated_chunk.y <= max_y + shadow_size):
				generated_chunks.erase(generated_chunk)
				await get_tree().process_frame
				for x in range(generated_chunk.x * chunk_size, (generated_chunk.x + 1) * chunk_size):
					for y in range(generated_chunk.y * chunk_size, (generated_chunk.y + 1) * chunk_size):
						foreground_blocks.erase_cell(Vector2i(x, y))
						background_blocks.erase_cell(Vector2i(x, y))
						collision_blocks.erase_cell(Vector2i(x, y))
						
		$Collision_Blocks.update_internals()
					
func _process(_delta: float) -> void:
	if not world_seed and NetworkManager.Ncache.has("world_seed"): world_seed = NetworkManager.Ncache["world_seed"]
	if world_seed and not initialised: initialise()
