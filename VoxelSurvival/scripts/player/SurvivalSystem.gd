class_name SurvivalSystem
extends Node

## Manages player survival mechanics: health, hunger, damage

signal health_changed(new_health: float)
signal hunger_changed(new_hunger: float)
signal player_died
signal player_respawned

# Configurable values
@export var max_health: float = 20.0
@export var max_hunger: float = 20.0
@export var hunger_rate: float = 0.5  # Hunger points per minute
@export var regeneration_threshold: float = 18.0  # Minimum hunger for health regen
@export var regeneration_rate: float = 1.0  # Health points per second when regenerating
@export var fall_damage_threshold: float = 3.0  # Blocks fallen before taking damage

var current_health: float = 20.0
var current_hunger: float = 20.0
var is_invincible: bool = false
var hunger_timer: float = 0.0

func _ready():
	set_process(true)

func _process(delta):
	update_hunger(delta)
	update_regeneration(delta)

func update_hunger(delta):
	hunger_timer += delta
	var hunger_interval = 60.0 / hunger_rate  # Seconds per hunger point
	
	if hunger_timer >= hunger_interval:
		hunger_timer -= hunger_interval
		if current_hunger > 0:
			current_hunger = max(0, current_hunger - 1)
			hunger_changed.emit(current_hunger)

func update_regeneration(delta):
	if current_hunger >= regeneration_threshold and current_health < max_health:
		current_health = min(max_health, current_health + regeneration_rate * delta)
		health_changed.emit(current_health)

func take_damage(amount: float):
	if is_invincible:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func eat(amount: float):
	current_hunger = min(max_hunger, current_hunger + amount)
	hunger_changed.emit(current_hunger)

func apply_fall_damage(fall_distance: float):
	if fall_distance > fall_damage_threshold:
		var damage = (fall_distance - fall_damage_threshold) * 2.0
		take_damage(damage)

func die():
	if is_invincible:
		return
	
	player_died.emit()

func respawn():
	current_health = max_health
	current_hunger = max_hunger
	is_invincible = true
	
	# Brief invincibility after respawn
	await get_tree().create_timer(2.0).timeout
	is_invincible = false
	
	player_respawned.emit()

func set_invincible(value: bool):
	is_invincible = value

func serialize() -> Dictionary:
	return {
		"health": current_health,
		"hunger": current_hunger
	}

func deserialize(data: Dictionary):
	if data.has("health"):
		current_health = data.health
	if data.has("hunger"):
		current_hunger = data.hunger
	
	health_changed.emit(current_health)
	hunger_changed.emit(current_hunger)
