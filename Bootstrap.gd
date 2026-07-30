extends Node2D

@onready var fallback_label: Label = $FallbackLabel
@onready var fallback_bg: ColorRect = $FallbackBg
var game_scene := "res://Main.tscn"
var game_node: Node = null

func _ready() -> void:
    fallback_label.text = "ORBIT CLASH\nLOADING ARENA..."
    call_deferred("_start_game")

func _start_game() -> void:
    var packed_scene: PackedScene = load(game_scene)
    if packed_scene == null:
        fallback_label.text = "ORBIT CLASH\nFAILED TO LOAD MAIN"
        return
    game_node = packed_scene.instantiate()
    game_node.name = "MainRuntime"
    fallback_label.text = "ORBIT CLASH\nMAIN INSTANTIATED"
    add_child(game_node)
    _inspect_game()

func _inspect_game() -> void:
    if game_node == null:
        fallback_label.text = "ORBIT CLASH\nGAME NODE NULL"
        return
    var script_path := "<none>"
    var scr := game_node.get_script()
    if scr != null and scr is Script:
        script_path = scr.resource_path
    var has_boot_report := game_node.has_method("_boot_report")
    var has_ready := game_node.has_method("_ready")
    fallback_label.text = "ORBIT CLASH\nSCRIPT:%s\nBOOT:%s READY:%s" % [script_path, str(has_boot_report), str(has_ready)]
    if has_boot_report:
        game_node.call_deferred("_boot_report", "MAIN PING FROM BOOTSTRAP")

func report_boot(message: String) -> void:
    if fallback_label.visible:
        fallback_label.text = "ORBIT CLASH\n" + message
    if message.ends_with("complete"):
        fallback_bg.visible = false
        fallback_label.visible = false
