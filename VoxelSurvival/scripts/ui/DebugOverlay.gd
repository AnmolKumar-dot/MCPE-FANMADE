class_name DebugOverlay
extends Control

## Debug information overlay

@onready var fps_label: Label = $MarginContainer/VBoxContainer/FPSLabel
@onready var pos_label: Label = $MarginContainer/VBoxContainer/PosLabel
@onready var chunk_label: Label = $MarginContainer/VBoxContainer/ChunkLabel
@onready var chunks_label: Label = $MarginContainer/VBoxContainer/ChunksLabel
@onready var biome_label: Label = $MarginContainer/VBoxContainer/BiomeLabel

var is_visible_now: bool = false

func _ready():
	visible = false

func toggle():
	is_visible_now = not is_visible_now
	visible = is_visible_now

func update_info(info: Dictionary):
	if not visible:
		return
	
	if info.has("fps") and fps_label:
		fps_label.text = "FPS: %d" % info.fps
	
	if info.has("player_pos") and pos_label:
		var pos: Vector3 = info.player_pos
		pos_label.text = "Position: %.1f, %.1f, %.1f" % [pos.x, pos.y, pos.z]
	
	if info.has("chunk") and chunk_label:
		var chunk: Vector3i = info.chunk
		chunk_label.text = "Chunk: %d, %d, %d" % [chunk.x, chunk.y, chunk.z]
	
	if info.has("loaded_chunks") and chunks_label:
		chunks_label.text = "Loaded Chunks: %d" % info.loaded_chunks
	
	if info.has("biome") and biome_label:
		biome_label.text = "Biome: %s" % info.biome
