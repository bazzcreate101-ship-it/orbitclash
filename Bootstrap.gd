extends Node2D

@onready var fallback_label: Label = $FallbackLabel
var load_started := false
var game_scene := "res://Main.tscn"

func _ready() -> void:
    fallback_label.text = "ORBIT CLASH\nBOOTING..."
    ResourceLoader.load_threaded_request(game_scene)
    load_started = true

func _process(_delta: float) -> void:
    if not load_started:
        return
    var progress := []
    var status := ResourceLoader.load_threaded_get_status(game_scene, progress)
    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            var pct := 0.0
            if progress.size() > 0:
                pct = progress[0] * 100.0
            fallback_label.text = "ORBIT CLASH\nLOADING ARENA...\n%0.0f%%" % pct
        ResourceLoader.THREAD_LOAD_LOADED:
            load_started = false
            var packed := ResourceLoader.load_threaded_get(game_scene)
            if packed == null:
                fallback_label.text = "ORBIT CLASH\nFAILED TO LOAD MAIN SCENE"
                return
            fallback_label.text = "ORBIT CLASH\nSTARTING..."
            var game := packed.instantiate()
            add_child(game)
        ResourceLoader.THREAD_LOAD_FAILED:
            load_started = false
            fallback_label.text = "ORBIT CLASH\nFAILED TO LOAD MAIN SCENE"

func report_boot(message: String) -> void:
    fallback_label.text = "ORBIT CLASH\n" + message
