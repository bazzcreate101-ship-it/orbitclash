extends Node2D

const W := 720.0
const H := 1280.0
const ARENA := Rect2(34, 210, 652, 720)
const R := 32.0

var rng := RandomNumberGenerator.new()
var roster := [
    {"name":"OUTLAW", "color":Color("d79b5f"), "skill":"Heat Burst", "power":1.05, "speed":1.12},
    {"name":"STASIS", "color":Color("77c7f2"), "skill":"Freeze", "power":0.92, "speed":0.92},
    {"name":"RETALIATOR", "color":Color("7d8cff"), "skill":"Counter", "power":0.82, "speed":0.88},
    {"name":"ROGUE", "color":Color("b47ef5"), "skill":"Crit Dash", "power":0.9, "speed":1.28},
    {"name":"SWORD SAINT", "color":Color("6fd0b5"), "skill":"Perfect Cut", "power":1.0, "speed":1.05},
    {"name":"JUDGE", "color":Color("d7a44a"), "skill":"Verdict", "power":1.0, "speed":0.96},
    {"name":"MONKEY KING", "color":Color("e7c34f"), "skill":"Echo Staff", "power":0.9, "speed":1.08},
    {"name":"DRAGOON", "color":Color("6c5ce7"), "skill":"Lance Volley", "power":1.32, "speed":0.82},
    {"name":"TYRANT", "color":Color("c18a2f"), "skill":"Gates", "power":1.1, "speed":0.78},
    {"name":"MAGIA", "color":Color("ef7fb0"), "skill":"Spell Bloom", "power":0.96, "speed":1.0}
]

var left_idx := 0
var right_idx := 1
var fighters := []
var projectiles := []
var state := "battle"
var elapsed := 0.0

var title_label: Label
var left_label: Label
var right_label: Label
var status_label: Label
var left_hp_label: Label
var right_hp_label: Label

func _ready() -> void:
    rng.randomize()
    _make_ui()
    _random_matchup()
    _start_battle()
    queue_redraw()

func _make_ui() -> void:
    title_label = _label("ORBIT CLASH DIRECT", Vector2(0, 34), Vector2(W, 48), 34, HORIZONTAL_ALIGNMENT_CENTER)
    status_label = _label("AUTO BATTLE", Vector2(0, 82), Vector2(W, 32), 18, HORIZONTAL_ALIGNMENT_CENTER)
    left_label = _label("", Vector2(30, 132), Vector2(310, 56), 18, HORIZONTAL_ALIGNMENT_LEFT)
    right_label = _label("", Vector2(380, 132), Vector2(310, 56), 18, HORIZONTAL_ALIGNMENT_RIGHT)
    left_hp_label = _label("", Vector2(36, 950), Vector2(310, 42), 22, HORIZONTAL_ALIGNMENT_LEFT)
    right_hp_label = _label("", Vector2(374, 950), Vector2(310, 42), 22, HORIZONTAL_ALIGNMENT_RIGHT)

    _button("< LEFT", Vector2(30, 1030), Vector2(140, 58), _left_prev)
    _button("LEFT >", Vector2(178, 1030), Vector2(140, 58), _left_next)
    _button("< RIGHT", Vector2(30, 1098), Vector2(140, 58), _right_prev)
    _button("RIGHT >", Vector2(178, 1098), Vector2(140, 58), _right_next)
    _button("RANDOM", Vector2(390, 1030), Vector2(140, 58), _random_button)
    _button("REMATCH", Vector2(538, 1030), Vector2(140, 58), _rematch_button)

func _label(text: String, pos: Vector2, size: Vector2, font_size: int, align) -> Label:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.size = size
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    add_child(l)
    return l

func _button(text: String, pos: Vector2, size: Vector2, target: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.pressed.connect(target)
    add_child(b)

func _random_matchup() -> void:
    left_idx = rng.randi_range(0, roster.size() - 1)
    right_idx = rng.randi_range(0, roster.size() - 1)
    while right_idx == left_idx:
        right_idx = rng.randi_range(0, roster.size() - 1)

func _start_battle() -> void:
    var a: Dictionary = roster[left_idx]
    var b: Dictionary = roster[right_idx]
    fighters = [
        _fighter(a, Vector2(190, 420), Vector2(210, 230) * float(a.speed), 0),
        _fighter(b, Vector2(530, 720), Vector2(-220, -210) * float(b.speed), 1)
    ]
    projectiles.clear()
    elapsed = 0.0
    state = "battle"
    _sync_text()

func _fighter(data: Dictionary, pos: Vector2, vel: Vector2, side: int) -> Dictionary:
    return {
        "name": data.name,
        "skill": data.skill,
        "color": data.color,
        "power": float(data.power),
        "pos": pos,
        "vel": vel.rotated(rng.randf_range(-0.25, 0.25)),
        "angle": 0.0 if side == 0 else PI,
        "spin": (3.2 if side == 0 else -3.2) * float(data.speed),
        "hp": 100.0,
        "meter": 0.0,
        "side": side
    }

func _process(delta: float) -> void:
    if state == "battle" and fighters.size() == 2:
        elapsed += delta
        _update_fighter(fighters[0], delta, fighters[1])
        _update_fighter(fighters[1], delta, fighters[0])
        _resolve_hit(fighters[0], fighters[1])
        _resolve_hit(fighters[1], fighters[0])
        _update_projectiles(delta)
        if fighters[0].hp <= 0.0 or fighters[1].hp <= 0.0:
            state = "result"
            var winner: Dictionary = fighters[0] if fighters[0].hp > fighters[1].hp else fighters[1]
            status_label.text = "%s WINS - tap REMATCH" % winner.name
        _sync_text()
    queue_redraw()

func _update_fighter(f: Dictionary, delta: float, enemy: Dictionary) -> void:
    f.angle += f.spin * delta
    f.pos += f.vel * delta
    if f.pos.x < ARENA.position.x + R or f.pos.x > ARENA.end.x - R:
        f.vel.x *= -1.0
        f.pos.x = clampf(f.pos.x, ARENA.position.x + R, ARENA.end.x - R)
    if f.pos.y < ARENA.position.y + R or f.pos.y > ARENA.end.y - R:
        f.vel.y *= -1.0
        f.pos.y = clampf(f.pos.y, ARENA.position.y + R, ARENA.end.y - R)
    f.meter = minf(1.0, f.meter + delta * 0.12)
    if f.meter >= 1.0:
        f.meter = 0.0
        _cast_skill(f, enemy)

func _resolve_hit(a: Dictionary, b: Dictionary) -> void:
    var tip := a.pos + Vector2.RIGHT.rotated(a.angle) * 86.0
    if tip.distance_to(b.pos) <= R + 12.0:
        var dmg := 2.8 + 4.2 * float(a.power)
        if a.skill == "Crit Dash" and rng.randf() < 0.28:
            dmg *= 2.0
            a.vel *= 1.12
        if b.skill == "Counter":
            a.hp -= dmg * 0.24
        b.hp = maxf(0.0, b.hp - dmg)
        b.vel += (b.pos - a.pos).normalized() * 32.0

func _cast_skill(f: Dictionary, enemy: Dictionary) -> void:
    match f.skill:
        "Freeze":
            enemy.vel *= 0.76
        "Lance Volley", "Verdict", "Gates", "Spell Bloom":
            projectiles.append({"pos":f.pos, "vel":(enemy.pos - f.pos).normalized() * 360.0, "owner":f.side, "color":f.color, "damage":8.0 * float(f.power), "life":1.2})
        "Echo Staff":
            f.spin *= 1.08
        "Heat Burst", "Perfect Cut":
            enemy.hp = maxf(0.0, enemy.hp - 7.0 * float(f.power))

func _update_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        var p: Dictionary = projectiles[i]
        p.life -= delta
        p.pos += p.vel * delta
        var target: Dictionary = fighters[1 - int(p.owner)]
        if p.pos.distance_to(target.pos) <= R + 8.0:
            target.hp = maxf(0.0, target.hp - float(p.damage))
            projectiles.remove_at(i)
            continue
        if p.life <= 0.0:
            projectiles.remove_at(i)

func _sync_text() -> void:
    if fighters.size() != 2:
        return
    left_label.text = "%s\n%s" % [fighters[0].name, fighters[0].skill]
    right_label.text = "%s\n%s" % [fighters[1].name, fighters[1].skill]
    left_hp_label.text = "HP %d" % int(ceil(fighters[0].hp))
    right_hp_label.text = "HP %d" % int(ceil(fighters[1].hp))
    if state == "battle":
        status_label.text = "WATCHING MATCHUP %.1fs" % elapsed

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("f4f2ef"), true)
    draw_rect(ARENA, Color("fafafa"), true)
    for i in range(8):
        var y := ARENA.position.y + 80.0 * i
        draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color(0, 0, 0, 0.05), 1.0)
    draw_rect(ARENA, Color("252525"), false, 4.0)
    if fighters.size() == 2:
        _draw_fighter(fighters[0])
        _draw_fighter(fighters[1])
    for p in projectiles:
        draw_circle(p.pos, 9.0, p.color)

func _draw_fighter(f: Dictionary) -> void:
    var tip := f.pos + Vector2.RIGHT.rotated(f.angle) * 86.0
    draw_line(f.pos, tip, Color("111111"), 13.0, true)
    draw_line(f.pos, tip, Color(f.color), 8.0, true)
    draw_circle(f.pos, R + 5.0, Color("111111"))
    draw_circle(f.pos, R, f.color)

func _left_prev() -> void:
    left_idx = posmod(left_idx - 1, roster.size())
    if left_idx == right_idx:
        right_idx = posmod(right_idx + 1, roster.size())
    _start_battle()

func _left_next() -> void:
    left_idx = posmod(left_idx + 1, roster.size())
    if left_idx == right_idx:
        right_idx = posmod(right_idx + 1, roster.size())
    _start_battle()

func _right_prev() -> void:
    right_idx = posmod(right_idx - 1, roster.size())
    if right_idx == left_idx:
        left_idx = posmod(left_idx + 1, roster.size())
    _start_battle()

func _right_next() -> void:
    right_idx = posmod(right_idx + 1, roster.size())
    if right_idx == left_idx:
        left_idx = posmod(left_idx + 1, roster.size())
    _start_battle()

func _random_button() -> void:
    _random_matchup()
    _start_battle()

func _rematch_button() -> void:
    _start_battle()
