class_name PauseMenu
extends Control

## Pause menu with resume, settings, and quit options

signal resume_pressed
signal settings_pressed
signal quit_pressed

@onready var resume_button: Button = $MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready():
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	var gm = GameManager.get_instance()
	if gm:
		gm.resume_game()

func _on_settings_pressed():
	# Open settings menu (placeholder)
	pass

func _on_quit_pressed():
	var gm = GameManager.get_instance()
	if gm:
		gm.quit_to_menu()

func show_menu():
	visible = true

func hide_menu():
	visible = false
