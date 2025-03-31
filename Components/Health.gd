class_name Health
extends Node2D

var max_health: float = 100.0
var health: float = max_health
var player = false

var blood_particle_scene = preload("res://Scenes/Particles/BloodParticleEmitter.tscn")

var damage_multiplier: Dictionary = {
	"null" = 1.0,
	"all" = 1.0,
	"melee" = 1.0,
	"velocity" = 1.0,
}

func apply_damage(damage: float, damage_type: String = "null") -> void:
	damage = damage * damage_multiplier.get(damage_type) * damage_multiplier.all
	health = clampf(health - damage, 0, max_health)
	if player:
		get_parent().get_parent().get_node("Camera/OffsetNegator/HUD/Healthbar/Health").size.x = health / (max_health / 616.0)
		if health == 0:
			health = 100
			get_tree().current_scene.get_node("Blocks").reload()
	else:
		var blood_particle_emitter = blood_particle_scene.instantiate()

		get_parent().get_parent().add_child(blood_particle_emitter)
		blood_particle_emitter.global_position = global_position
		blood_particle_emitter.emitting = true

		await get_tree().create_timer(4).timeout
		blood_particle_emitter.queue_free()
		
		get_parent().get_parent().get_node("Healthbar/Healthbar_Foreground").size.x = health / (max_health / 42.0)
		if health == 0: get_parent().get_parent().queue_free()
