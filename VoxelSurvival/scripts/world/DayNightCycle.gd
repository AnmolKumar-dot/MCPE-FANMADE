class_name DayNightCycle
extends Node

## Manages day/night cycle with sky and lighting changes

signal time_changed(time_of_day: float)
signal day_changed(day: int)

# Configurable settings
@export var day_length_seconds: float = 1200.0  # 20 minutes for full day
@export var sunrise_time: float = 0.25  # 6 AM (0-1 scale)
@export var sunset_time: float = 0.75  # 6 PM (0-1 scale)

# Current state
var time_of_day: float = 0.0  # 0-1, where 0 = midnight
var day: int = 0
var is_night: bool = false

# References
var sun_light: DirectionalLight3D = null
var sky_material: SkyMaterial = null

func _ready():
	set_process(true)

func _process(delta):
	# Advance time
	var time_delta = delta / day_length_seconds
	time_of_day += time_delta
	
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
		day_changed.emit(day)
	
	# Update sun position and lighting
	update_sun()
	update_sky()
	
	# Check if it's night
	is_night = time_of_day < sunrise_time or time_of_day > sunset_time
	
	time_changed.emit(time_of_day)

func set_sun_light(light: DirectionalLight3D):
	sun_light = light

func set_sky_material(material: SkyMaterial):
	sky_material = material

func update_sun():
	if sun_light == null:
		return
	
	# Calculate sun rotation based on time
	# 0 = midnight (below horizon), 0.25 = sunrise (east), 0.5 = noon (overhead), 0.75 = sunset (west)
	var sun_angle = (time_of_day - 0.25) * 360.0
	sun_light.rotation_degrees = Vector3(sun_angle, -45, 0)
	
	# Adjust light intensity based on sun height
	var intensity = get_sun_intensity()
	sun_light.light_energy = intensity

func update_sky():
	if sky_material == null:
		return
	
	# Get sky color based on time
	var sky_color = get_sky_color()
	sky_material.sky_top_color = sky_color
	sky_material.sky_horizon_color = sky_color.lerp(Color(0.5, 0.5, 0.8), 0.3)

func get_sun_intensity() -> float:
	# Sun is brightest at noon (0.5), dimmest at midnight
	var angle_from_noon = abs(time_of_day - 0.5) * 2.0  # 0 at noon, 1 at midnight
	
	if angle_from_noon < 0.25:
		# Day time - full brightness
		return 1.0
	elif angle_from_noon < 0.35:
		# Sunrise/sunset transition
		var t = (angle_from_noon - 0.25) / 0.10
		return lerp(1.0, 0.3, t)
	else:
		# Night - minimal light
		return 0.05

func get_sky_color() -> Color:
	var angle_from_noon = abs(time_of_day - 0.5) * 2.0
	
	if angle_from_noon < 0.2:
		# Midday - bright blue
		return Color(0.4, 0.6, 1.0)
	elif angle_from_noon < 0.3:
		# Morning/evening - lighter blue
		return Color(0.5, 0.7, 1.0).lerp(Color(0.9, 0.5, 0.3), (angle_from_noon - 0.2) / 0.1)
	else:
		# Night - dark blue/black
		return Color(0.05, 0.05, 0.15).lerp(Color(0.4, 0.6, 1.0), (1.0 - angle_from_noon) / 0.7)

func get_ambient_light() -> float:
	if is_night:
		return 0.15
	else:
		return 0.6

func set_time(hours: float):
	# Set time to specific hour (0-24)
	time_of_day = hours / 24.0

func skip_to_day():
	time_of_day = sunrise_time

func skip_to_night():
	time_of_day = (sunset_time + sunrise_time) / 2.0

func serialize() -> Dictionary:
	return {
		"time": time_of_day,
		"day": day
	}

func deserialize(data: Dictionary):
	if data.has("time"):
		time_of_day = data.time
	if data.has("day"):
		day = data.day
