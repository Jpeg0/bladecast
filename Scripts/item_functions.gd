extends Node

var item_max_cooldown = 0.2
var item_cooldown = 0

func item_function(item, _button):
	if item_cooldown == 0:
		if item.key == "wooden_sword":
			item_cooldown = item_max_cooldown
			swing_sword(0.0, 0.0, 0.0)
			await get_tree().create_timer(item_max_cooldown).timeout
			item_cooldown = 0

func swing_sword(impact_frame_time: float, camerashake_time: float, hitstop_time: float):
	get_parent().get_parent().get_node("AnimationPlayer").play("Swing")
	Sounds.play_sound("Swing", 1.0, 0.1)
	for body in get_parent().get_node("CollisionArea").get_overlapping_bodies():
		Sounds.play_sound("HitFlesh", 1.0, 0.1)
		NetworkManager.send_entity_update(body.get_parent().name + "/" + body.name, "Component", ["Health", "apply_damage", [1, "melee"]])
		if impact_frame_time != 0.0: impact_frame(impact_frame_time, body)
		if camerashake_time != 0.0: get_parent().get_parent().get_node("Camera").camera_shake(camerashake_time)
		if hitstop_time != 0.0: hitstop(hitstop_time, body)
		
func impact_frame(impact_frame_time, body):
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
		
func hitstop(hitstop_time, body):
	get_parent().get_parent().get_node("AnimationPlayer").pause()
	body.can_move = false
	get_parent().get_parent().can_move = false
	await get_tree().create_timer(hitstop_time).timeout 
	get_parent().get_parent().get_node("AnimationPlayer").play()
	body.can_move = true
	get_parent().get_parent().can_move = true
