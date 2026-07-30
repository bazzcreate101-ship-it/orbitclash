extends Node2D

@onready var fallback_label: Label = $FallbackLabel
@onready var fallback_bg: ColorRect = $FallbackBg
var game_scene := "res://Main.tscn"
var game_node: Node = null
var boot_state := "starting"

func _ready() -> void:
    boot_state = "loading"
    fallback_label.text = "ORBIT CLASH\nLOADING ARENA..."
    call_deferred("_start_game")

func _process(_delta: float) -> void:
    if game_node != null:
        var stage := "<none>"
        if game_node.has_method("get"):
            stage = str(game_node.get("startup_stage"))
        var inside_tree := str(game_node.is_inside_tree())
        var script_path := "<none>"
        var scr := game_node.get_script()
        if scr != null and scr is Script:
            script_path = scr.resource_path
        fallback_label.text = "ORBIT CLASH\nSTATE:%s\nTREE:%s\nSCRIPT:%s" % [stage, inside_tree, script_path]
        if stage == "READY complete":
            fallback_bg.visible = false
            fallback_label.visible = false

func _start_game() -> void:
    boot_state = "load_main"
    var packed_scene: PackedScene = load(game_scene)
    if packed_scene == null:
        fallback_label.text = "ORBIT CLASH\nFAILED TO LOAD MAIN"
        return
    boot_state = "instantiate_main"
    game_node = packed_scene.instantiate()
    game_node.name = "MainRuntime"
    fallback_label.text = "ORBIT CLASH\nMAIN INSTANTIATED"
    add_child(game_node)

func report_boot(message: String) -> void:
    if fallback_label.visible:
        fallback_label.text = "ORBIT CLASH\n" + message
