extends Node2D

@onready var fallback_label: Label = $FallbackLabel

func _ready() -> void:
    fallback_label.text = "ORBIT CLASH\nLOADING ARENA..."
    var err := get_tree().change_scene_to_file("res://Main.tscn")
    if err != OK:
        fallback_label.text = "ORBIT CLASH\nFAILED TO START\nERR %d" % err
