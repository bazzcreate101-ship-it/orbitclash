extends Node2D

@onready var fallback_label: Label = $FallbackLabel
var game_scene := "res://Main.tscn"
var step := 0
var packed_scene: PackedScene

func _ready() -> void:
    fallback_label.text = "ORBIT CLASH\nDIAGNOSTIC BOOT\nTAP SCREEN"

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _next_step()
    elif event is InputEventMouseButton and event.pressed:
        _next_step()

func _next_step() -> void:
    step += 1
    if step == 1:
        fallback_label.text = "STEP 1\nABOUT TO SYNC LOAD MAIN\nTAP AGAIN"
        return
    if step == 2:
        fallback_label.text = "STEP 2\nSYNC LOADING MAIN..."
        packed_scene = load(game_scene)
        fallback_label.text = "STEP 2 DONE\nLOAD OK: %s\nTAP AGAIN" % str(packed_scene != null)
        return
    if step == 3:
        fallback_label.text = "STEP 3\nABOUT TO INSTANTIATE\nTAP AGAIN"
        return
    if step == 4:
        fallback_label.text = "STEP 4\nINSTANTIATING..."
        if packed_scene == null:
            fallback_label.text = "STEP 4 FAILED\nPACKED SCENE NULL"
            return
        var game := packed_scene.instantiate()
        fallback_label.text = "STEP 4 DONE\nINSTANCE OK\nTAP AGAIN"
        game.name = "MainRuntime"
        add_child(game)
        return
    fallback_label.text = "STEP %d\nBOOTSTRAP STILL ALIVE" % step

func report_boot(message: String) -> void:
    fallback_label.text = "ORBIT CLASH\n" + message
