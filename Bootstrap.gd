extends Node2D

@onready var fallback_label: Label = $FallbackLabel

func _ready() -> void:
    fallback_label.text = "ORBIT CLASH\nLOADING ARENA..."
    call_deferred("_load_game")

func _load_game() -> void:
    await get_tree().process_frame
    var packed := load("res://Main.tscn")
    if packed == null:
        fallback_label.text = "ORBIT CLASH\nMAIN SCENE FAILED TO LOAD"
        return
    var game := packed.instantiate()
    add_child(game)
