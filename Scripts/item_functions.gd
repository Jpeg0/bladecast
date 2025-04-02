extends Node

var item_max_cooldown = 0.2
var item_cooldown = 0
var impact_frame_time = 0
var camerashake_time = 0
var hitstop_time = 0
var detect_bodies_enabled = false
var detected_bodies = []

func item_function(item, _button):
	if item_cooldown == 0:
		if item.key == "wooden_sword":
			item_cooldown = item_max_cooldown
			
			impact_frame_time = 0.2
			camerashake_time = 0.2
			hitstop_time = 0.2
			detect_bodies_enabled = true
			
			get_parent().get_parent().get_node("AnimationPlayer").play("Swing")
			Sounds.play_sound("Swing", 1.0, 0.1)
			
			await get_tree().create_timer(item_max_cooldown).timeout
			detect_bodies_enabled = false
			detected_bodies = []
			item_cooldown = 0

	
func detect_bodies():
	for body in $CollisionArea.get_overlapping_bodies():
		if !body in detected_bodies:
			detected_bodies.append(body)
			Sounds.play_sound("HitFlesh", 1.0, 0.1)
			var knockback = Vector2(sign(body.position.x - get_parent().get_parent().position.x) * 64, 0.0)
			NetworkManager.send_entity_update(body.get_parent().name + "/" + body.name, "Component", ["Health", "apply_damage", [1, "melee"]])
			NetworkManager.send_entity_update(body.get_parent().name + "/" + body.name, "Property", ["knockback_velocity", knockback])
			if impact_frame_time != 0.0: impact_frame(body)
			if camerashake_time != 0.0: get_parent().get_parent().get_node("Camera").camera_shake()
			if hitstop_time != 0.0: hitstop(body)
		
func _process(_delta: float) -> void: if detect_bodies_enabled: detect_bodies()
		
func impact_frame(body):
	if body:
		Sounds.play_sound("Impact", 1.0, 0.1)
		get_parent().use_parent_material = false
		get_parent().z_index = 16
		body.get_node("Texture").use_parent_material = false
		body.get_node("Texture").z_index = 16
		get_parent().get_parent().get_node("Camera/OffsetNegator/Effects/Impact").show()
		await get_tree().create_timer(impact_frame_time).timeout 
	if body:
		get_parent().use_parent_material = true
		get_parent().z_index = 0
		body.get_node("Texture").use_parent_material = true
		body.get_node("Texture").z_index = 0
		get_parent().get_parent().get_node("Camera/OffsetNegator/Effects/Impact").hide()
		
func hitstop(body):
	get_parent().get_parent().get_node("AnimationPlayer").pause()
	body.can_move = false
	get_parent().get_parent().can_move = false
	await get_tree().create_timer(hitstop_time).timeout 
	get_parent().get_parent().get_node("AnimationPlayer").play()
	body.can_move = true
	get_parent().get_parent().can_move = true
