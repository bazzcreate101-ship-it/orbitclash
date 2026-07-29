extends Node2D

@onready var fallback_label: Label = $FallbackLabel
@onready var fallback_bg: ColorRect = $FallbackBg
var game_scene := "res://Main.tscn"

func _ready() -> void:
    fallback_label.text = "ORBIT CLASH\nLOADING ARENA..."
    call_deferred("_start_game")

func _start_game() -> void:
    var packed_scene: PackedScene = load(game_scene)
    if packed_scene == null:
        fallback_label.text = "ORBIT CLASH\nFAILED TO LOAD MAIN"
        return
    var game := packed_scene.instantiate()
    game.name = "MainRuntime"
    add_child(game)

func report_boot(message: String) -> void:
    if fallback_label.visible:
        fallback_label.text = "ORBIT CLASH\n" + message
    if message.ends_with("complete"):
        fallback_bg.visible = false
        fallback_label.visible = false
