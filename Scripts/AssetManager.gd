extends Node

var tileset_updated = true
var current_lod = 16
var texture_cache = {}
var sound_cache = {}
var mipmaps = {
	"32": [TileSet.new(), 32],
	"24": [TileSet.new(), 24],
	"16": [TileSet.new(), 16]
}

var blocks = {}

const items = {
	
	"ice": {
		"key": "ice",
		"name": "Ice",
		"max_stack_size": 256,
		"block": true
	},
	
	"snow": {
		"key": "snow",
		"name": "Snow",
		"max_stack_size": 256,
		"block": true
	},
	
	"moss": {
		"key": "moss",
		"name": "Moss",
		"max_stack_size": 256,
		"block": true
	},
	
	"sand": {
		"key": "sand",
		"name": "Sand",
		"max_stack_size": 256,
		"block": true
	},
	
	"coal_ore": {
		"key": "coal_ore",
		"name": "Coal Ore",
		"max_stack_size": 256,
		"block": true
	},
	
	"dirt": {
		"key": "dirt",
		"name": "Dirt",
		"max_stack_size": 256,
		"block": true
	},
	
	"grass": {
		"key": "grass",
		"name": "Grass",
		"max_stack_size": 256,
		"block": true
	},
	
	"iron_ore": {
		"key": "iron_ore",
		"name": "Iron Ore",
		"max_stack_size": 256,
		"block": true
	},
	
	"stone": {
		"key": "stone",
		"name": "Stone",
		"max_stack_size": 256,
		"block": true
	},
	
	"wooden_pickaxe": {
		"key": "wooden_pickaxe",
		"name": "Wooden Pickaxe",
		"max_stack_size": 256,
		"pickaxe":
		{
		}
	},
	
	"wooden_sword": {
		"key": "wooden_sword",
		"name": "Wooden Sword",
		"max_stack_size": 256,
		"weapon":
		{
		}
	},
}

const sounds = {
	"Swing": {
		"key": "Swing",
		"path": "Sounds/SoundEffects/Swing.wav",
		"bus": "SFX",
		"raytraced_audio": true,
	},
	"HitFlesh": {
		"key": "HitFlesh",
		"path": "Sounds/SoundEffects/HitFlesh.wav",
		"bus": "SFX",
		"raytraced_audio": true,
	},
	"Impact": {
		"key": "Impact",
		"path": "Sounds/SoundEffects/Impact.wav",
		"bus": "SFX",
		"raytraced_audio": true,
	},
	"FirstLight-Full": {
		"key": "FirstLight-Full",
		"path": "Sounds/Music/FirstLight-Full.wav",
		"bus": "Music",
		"raytraced_audio": false,
	},
	"NoTimeToBleed-Full": {
		"key": "NoTimeToBleed-Full",
		"path": "Sounds/Music/NoTimeToBleed-Full.wav",
		"bus": "Music",
		"raytraced_audio": false,
	},
}

const sound_pools = {
	"Ambient_Default": [
		"NoTimeToBleed-Full",
		"FirstLight-Full",
	]
}

func _ready():
	var i = 0
	for item in items.values():
		if item.has("block"):
			blocks[item.key] = {"key": item.key, "id": i}
			i += 1
			
	update_texture_cache()
	update_sound_cache()
	update_tileset()
	
func update_texture_cache():
	texture_cache["null"] = load("res://Textures/Items/null.png")
	for item in items.values():
		var file_path = "res://Textures/Items/" + item.key + ".png"
		if ResourceLoader.exists(file_path):
			var texture = load(file_path)
			texture_cache[item.key] = {
				"32": texture,
				"24": generate_mipmap(texture, 24),
				"16": generate_mipmap(texture, 16)
			}
			
func update_sound_cache(): for sound in sounds: sound_cache[sound] = load(sounds[sound].path)
			
func generate_mipmap(texture, scale):
	var img = texture.get_image()
	img.resize(scale, scale, Image.INTERPOLATE_LANCZOS)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func set_lod(lod):
	if current_lod != lod:
		current_lod = lod
		get_tree().current_scene.get_node("Blocks/Foreground_Blocks").tile_set = mipmaps[str(lod)][0]
		get_tree().current_scene.get_node("Blocks/Background_Blocks").tile_set = mipmaps[str(lod)][0]
	
func update_tileset():
	for mipmap in mipmaps.values():
		mipmap[0].tile_size = Vector2i(32, 32)
		for item in items.values():
			if item.has("block"):
				var tile_source = TileSetAtlasSource.new()
				tile_source.texture_region_size = Vector2i(32, 32)
				if texture_cache.has(item.key): tile_source.texture = texture_cache[item.key][str(mipmap[1])]
				else: tile_source.texture = texture_cache["null"]
				tile_source.create_tile(Vector2i())
				mipmap[0].add_source(tile_source)
		tileset_updated = false
	
func _process(_delta: float) -> void:
	if !tileset_updated:
		if get_tree().current_scene and get_tree().current_scene.name == "World":
			get_tree().current_scene.get_node("Blocks/Foreground_Blocks").tile_set = mipmaps["16"][0]
			get_tree().current_scene.get_node("Blocks/Background_Blocks").tile_set = mipmaps["16"][0]
			tileset_updated = true
