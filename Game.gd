extends Node2D

const W := 720.0
const H := 1280.0
const ARENA := Rect2(36, 250, 648, 650)
const BALL_R := 34.0
const WEAPON_LEN := 112.0
const WALL := Color("161616")
const BG := Color("d7d1d7")
const PAPER := Color("fbfbfb")

var rng := RandomNumberGenerator.new()
var roster := [
	{"name":"Outlaw", "color":Color("b8794a"), "weapon":"revolver", "tag":"HIGH NOON", "left_stat":"Damage: 4.70", "right_stat":"Ammo: 1/6", "hp":67.0, "damage":4.7, "speed":1.0, "spin":1.4, "ammo":6, "luck":0.24},
	{"name":"Stasis", "color":Color("ececec"), "weapon":"ice_daggers", "tag":"WORLD STOP", "left_stat":"Attack Speed: 2.40", "right_stat":"Freeze: 0.80", "hp":100.0, "damage":2.3, "speed":1.05, "spin":1.75, "freeze":0.7, "luck":0.12},
	{"name":"Retaliator", "color":Color("6f9dc1"), "weapon":"sword_shield", "tag":"BLADE RETURN", "left_stat":"Damage: 2.00", "right_stat":"Counter: 45%", "hp":100.0, "damage":2.0, "speed":0.95, "spin":1.25, "counter":0.45, "luck":0.08},
	{"name":"Rogue", "color":Color("d8d33e"), "weapon":"dagger", "tag":"BACKSTAB", "left_stat":"Crit %: 0.00", "right_stat":"Crit Spike", "hp":100.0, "damage":2.15, "speed":1.55, "spin":2.4, "crit":0.38, "luck":0.32},
	{"name":"Sword Saint", "color":Color("263b48"), "weapon":"katana", "tag":"PERFECT CUT", "left_stat":"Damage: 3.00", "right_stat":"Attack Speed: 1.60", "hp":100.0, "damage":3.0, "speed":1.08, "spin":1.9, "true_cut":0.18, "luck":0.16},
	{"name":"Judge", "color":Color("eeeeee"), "weapon":"gavel", "tag":"KARMA VERDICT", "left_stat":"Karma: 0.00", "right_stat":"Recovery Rate: 20.00", "hp":1.0, "damage":1.2, "speed":0.82, "spin":1.0, "karma":1.0, "luck":0.22},
	{"name":"Monkey King", "color":Color("d1ad2b"), "weapon":"staff", "tag":"CLONES", "left_stat":"Weapon Size: 4.00", "right_stat":"Clones: 0.00", "hp":100.0, "damage":2.2, "speed":1.05, "spin":1.6, "clone":0.22, "luck":0.2},
	{"name":"Dragoon", "color":Color("3b2e70"), "weapon":"lance", "tag":"JUMP", "left_stat":"Damage: 10.00", "right_stat":"Pierce", "hp":100.0, "damage":10.0, "speed":0.86, "spin":1.1, "pierce":0.3, "luck":0.12},
	{"name":"Tyrant", "color":Color("d5bd2f"), "weapon":"gate", "tag":"GATES", "left_stat":"Gates: 2.00", "right_stat":"Heavy Hit", "hp":100.0, "damage":3.6, "speed":0.72, "spin":0.95, "gates":2, "luck":0.18},
	{"name":"Magia", "color":Color("df88b4"), "weapon":"wand", "tag":"SPELL BLOOM", "left_stat":"Attack Speed: 1.00", "right_stat":"Magic Orb", "hp":100.0, "damage":2.4, "speed":1.0, "spin":1.55, "orb":0.3, "luck":0.24}
]

var left_idx := 7
var right_idx := 8
var fighters := []
var sparks := []
var shots := []
var state := "battle"
var elapsed := 0.0
var hit_cooldown := 0.0
var speed_scale := 1.0

var title_label: Label
var subtitle_label: Label
var left_name: Label
var right_name: Label
var left_hp: Label
var right_hp: Label
var left_skill: Label
var right_skill: Label
var left_stat: Label
var right_stat: Label
var footer_label: Label
var watermark_label: Label

func _ready() -> void:
	rng.randomize()
	_make_ui()
	_start_battle()
	queue_redraw()

func _make_ui() -> void:
	title_label = _label("Orbit Clash Sim", Vector2(0, 34), Vector2(W, 48), 36, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle_label = _label("pick two fighters, then watch the random physics battle", Vector2(0, 82), Vector2(W, 34), 17, HORIZONTAL_ALIGNMENT_CENTER)
	left_name = _label("", Vector2(36, 185), Vector2(300, 54), 34, HORIZONTAL_ALIGNMENT_LEFT)
	right_name = _label("", Vector2(384, 185), Vector2(300, 54), 34, HORIZONTAL_ALIGNMENT_RIGHT)
	left_hp = _label("", Vector2(0, 0), Vector2(72, 54), 24, HORIZONTAL_ALIGNMENT_CENTER)
	right_hp = _label("", Vector2(0, 0), Vector2(72, 54), 24, HORIZONTAL_ALIGNMENT_CENTER)
	left_skill = _label("", Vector2(36, 920), Vector2(316, 38), 17, HORIZONTAL_ALIGNMENT_LEFT)
	right_skill = _label("", Vector2(368, 920), Vector2(316, 38), 17, HORIZONTAL_ALIGNMENT_RIGHT)
	left_stat = _label("", Vector2(36, 972), Vector2(316, 70), 24, HORIZONTAL_ALIGNMENT_LEFT)
	right_stat = _label("", Vector2(368, 972), Vector2(316, 70), 24, HORIZONTAL_ALIGNMENT_RIGHT)
	watermark_label = _label("@ballthingsim inspired", Vector2(0, 858), Vector2(W, 34), 18, HORIZONTAL_ALIGNMENT_CENTER)
	watermark_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.18))
	footer_label = _label("tap RANDOM for a new question: who wins this matchup?", Vector2(28, 1138), Vector2(664, 36), 16, HORIZONTAL_ALIGNMENT_CENTER)
	_button("< LEFT", Vector2(36, 1060), Vector2(140, 58), _left_prev)
	_button("LEFT >", Vector2(184, 1060), Vector2(140, 58), _left_next)
	_button("< RIGHT", Vector2(396, 1060), Vector2(140, 58), _right_prev)
	_button("RIGHT >", Vector2(544, 1060), Vector2(140, 58), _right_next)
	_button("RANDOM", Vector2(102, 1190), Vector2(220, 58), _random_button)
	_button("REMATCH", Vector2(398, 1190), Vector2(220, 58), _rematch_button)

func _label(text: String, pos: Vector2, size: Vector2, font_size: int, align) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("121212"))
	l.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	add_child(l)
	return l

func _button(text: String, pos: Vector2, size: Vector2, target: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("111111"))
	b.pressed.connect(target)
	add_child(b)

func _random_matchup() -> void:
	left_idx = rng.randi_range(0, roster.size() - 1)
	right_idx = rng.randi_range(0, roster.size() - 1)
	while right_idx == left_idx:
		right_idx = rng.randi_range(0, roster.size() - 1)

func _start_battle() -> void:
	var left_data: Dictionary = roster[left_idx]
	var right_data: Dictionary = roster[right_idx]
	fighters = [
		_make_fighter(left_data, Vector2(176, 555), Vector2(165, -125), 0),
		_make_fighter(right_data, Vector2(544, 555), Vector2(-165, 125), 1)
	]
	sparks.clear()
	shots.clear()
	elapsed = 0.0
	hit_cooldown = 0.0
	state = "battle"
	_sync_ui()

func _make_fighter(data: Dictionary, pos: Vector2, base_vel: Vector2, side: int) -> Dictionary:
	var v: Vector2 = base_vel.rotated(rng.randf_range(-0.7, 0.7)) * float(data["speed"])
	return {
		"name": str(data["name"]),
		"color": data["color"],
		"weapon": str(data["weapon"]),
		"tag": str(data["tag"]),
		"left_stat": str(data["left_stat"]),
		"right_stat": str(data["right_stat"]),
		"max_hp": float(data["hp"]),
		"hp": float(data["hp"]),
		"damage": float(data["damage"]),
		"speed": float(data["speed"]),
		"spin": (float(data["spin"]) if side == 0 else -float(data["spin"])) * rng.randf_range(0.9, 1.15),
		"angle": rng.randf_range(-PI, PI),
		"pos": pos,
		"vel": v,
		"side": side,
		"meter": rng.randf_range(0.0, 0.65),
		"data": data
	}

func _process(delta: float) -> void:
	var dt := delta * speed_scale
	elapsed += dt
	if hit_cooldown > 0.0:
		hit_cooldown -= dt
	if state == "battle" and fighters.size() == 2:
		_update_fighter(fighters[0], dt, fighters[1])
		_update_fighter(fighters[1], dt, fighters[0])
		_resolve_weapons(fighters[0], fighters[1])
		_resolve_weapons(fighters[1], fighters[0])
		_update_shots(dt)
		_update_sparks(dt)
		if float(fighters[0]["hp"]) <= 0.0 or float(fighters[1]["hp"]) <= 0.0 or elapsed > 42.0:
			_finish_battle()
	_sync_ui()
	queue_redraw()

func _update_fighter(f: Dictionary, dt: float, enemy: Dictionary) -> void:
	f["angle"] = float(f["angle"]) + float(f["spin"]) * dt
	var pos: Vector2 = f["pos"]
	var vel: Vector2 = f["vel"]
	pos += vel * dt
	if pos.x < ARENA.position.x + BALL_R or pos.x > ARENA.end.x - BALL_R:
		vel.x *= -1.0
		pos.x = clampf(pos.x, ARENA.position.x + BALL_R, ARENA.end.x - BALL_R)
	if pos.y < ARENA.position.y + BALL_R or pos.y > ARENA.end.y - BALL_R:
		vel.y *= -1.0
		pos.y = clampf(pos.y, ARENA.position.y + BALL_R, ARENA.end.y - BALL_R)
	var to_enemy: Vector2 = (enemy["pos"] - pos)
	if to_enemy.length() > 1.0:
		vel += to_enemy.normalized() * 5.5 * dt
	vel = vel.limit_length(255.0 * float(f["speed"]) + 35.0)
	f["pos"] = pos
	f["vel"] = vel
	f["meter"] = float(f["meter"]) + dt * (0.22 + 0.05 * float(f["speed"]))
	if float(f["meter"]) >= 1.0:
		f["meter"] = 0.0
		_cast_signature(f, enemy)

func _weapon_tip(f: Dictionary) -> Vector2:
	return f["pos"] + Vector2.RIGHT.rotated(float(f["angle"])) * _weapon_reach(f)

func _weapon_reach(f: Dictionary) -> float:
	match str(f["weapon"]):
		"staff":
			return 150.0
		"lance":
			return 148.0
		"gate":
			return 102.0
		"ice_daggers":
			return 116.0
		_:
			return WEAPON_LEN

func _resolve_weapons(a: Dictionary, b: Dictionary) -> void:
	var tip := _weapon_tip(a)
	var target: Vector2 = b["pos"]
	if hit_cooldown <= 0.0 and tip.distance_to(target) <= BALL_R + 20.0:
		_apply_damage(a, b, 1.0, tip)
		hit_cooldown = 0.11

func _apply_damage(attacker: Dictionary, target: Dictionary, mult: float, point: Vector2) -> void:
	var damage := float(attacker["damage"]) * mult * rng.randf_range(0.78, 1.28)
	var ad: Dictionary = attacker["data"]
	var td: Dictionary = target["data"]
	if ad.has("crit") and rng.randf() < float(ad["crit"]):
		damage *= 2.6
		attacker["vel"] = attacker["vel"] * 1.18
	if ad.has("true_cut") and rng.randf() < float(ad["true_cut"]):
		damage += 9.0
	if ad.has("pierce") and rng.randf() < float(ad["pierce"]):
		damage *= 1.65
	if td.has("counter") and rng.randf() < float(td["counter"]):
		attacker["hp"] = maxf(0.0, float(attacker["hp"]) - damage * 0.48)
		_spawn_spark(attacker["pos"], Color("6f9dc1"), 10)
	if td.has("karma"):
		damage *= rng.randf_range(0.55, 1.55)
	target["hp"] = maxf(0.0, float(target["hp"]) - damage)
	target["vel"] = target["vel"] + (target["pos"] - attacker["pos"]).normalized() * (32.0 + damage * 2.0)
	_spawn_spark(point, attacker["color"], 8)

func _cast_signature(f: Dictionary, enemy: Dictionary) -> void:
	var data: Dictionary = f["data"]
	if data.has("freeze"):
		enemy["vel"] = enemy["vel"] * float(data["freeze"])
		_spawn_spark(enemy["pos"], Color("9ceeff"), 14)
	if data.has("ammo"):
		for i in range(6):
			_spawn_shot(f, enemy, i * 0.22 - 0.55, 3.6)
	if data.has("orb"):
		for i in range(3):
			_spawn_shot(f, enemy, i * 0.42 - 0.42, 4.8)
	if data.has("gates"):
		for i in range(2):
			_spawn_shot(f, enemy, -0.35 + i * 0.7, 5.5)
	if data.has("clone"):
		_apply_damage(f, enemy, 0.65, enemy["pos"])
		_spawn_spark(f["pos"] + Vector2(rng.randf_range(-70, 70), rng.randf_range(-70, 70)), f["color"], 12)
	if data.has("karma"):
		f["hp"] = minf(float(f["max_hp"]), float(f["hp"]) + 8.0)

func _spawn_shot(f: Dictionary, enemy: Dictionary, spread: float, damage: float) -> void:
	var dir: Vector2 = (enemy["pos"] - f["pos"]).normalized().rotated(spread)
	shots.append({"pos": f["pos"], "vel": dir * 430.0, "life": 1.15, "damage": damage + float(f["damage"]) * 0.35, "owner": int(f["side"]), "color": f["color"]})

func _update_shots(dt: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		s["life"] = float(s["life"]) - dt
		s["pos"] = s["pos"] + s["vel"] * dt
		var target: Dictionary = fighters[1 - int(s["owner"])]
		if s["pos"].distance_to(target["pos"]) <= BALL_R + 12.0:
			var attacker: Dictionary = fighters[int(s["owner"])]
			_apply_damage(attacker, target, float(s["damage"]) / maxf(1.0, float(attacker["damage"])), s["pos"])
			shots.remove_at(i)
		elif float(s["life"]) <= 0.0 or not ARENA.has_point(s["pos"]):
			shots.remove_at(i)

func _spawn_spark(pos: Vector2, color: Color, amount: int) -> void:
	for i in range(amount):
		sparks.append({"pos": pos, "vel": Vector2.RIGHT.rotated(rng.randf_range(-PI, PI)) * rng.randf_range(50, 180), "life": rng.randf_range(0.25, 0.55), "color": color})

func _update_sparks(dt: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var sp: Dictionary = sparks[i]
		sp["life"] = float(sp["life"]) - dt
		sp["pos"] = sp["pos"] + sp["vel"] * dt
		if float(sp["life"]) <= 0.0:
			sparks.remove_at(i)

func _finish_battle() -> void:
	state = "result"
	var a: Dictionary = fighters[0]
	var b: Dictionary = fighters[1]
	if absf(float(a["hp"]) - float(b["hp"])) < 0.1:
		subtitle_label.text = "DRAW - tap REMATCH"
	else:
		var winner: Dictionary = a if float(a["hp"]) > float(b["hp"]) else b
		subtitle_label.text = "%s WINS - tap REMATCH or RANDOM" % str(winner["name"])

func _sync_ui() -> void:
	if fighters.size() != 2:
		return
	var a: Dictionary = fighters[0]
	var b: Dictionary = fighters[1]
	left_name.text = str(a["name"])
	right_name.text = str(b["name"])
	left_name.add_theme_color_override("font_color", a["color"])
	right_name.add_theme_color_override("font_color", b["color"])
	left_skill.text = str(a["tag"])
	right_skill.text = str(b["tag"])
	left_stat.text = "%s\n%s" % [str(a["left_stat"]), str(a["right_stat"])]
	right_stat.text = "%s\n%s" % [str(b["left_stat"]), str(b["right_stat"])]
	left_hp.text = "%d" % int(ceil(float(a["hp"])))
	right_hp.text = "%d" % int(ceil(float(b["hp"])))
	left_hp.position = a["pos"] - Vector2(36, 27)
	right_hp.position = b["pos"] - Vector2(36, 27)
	if state == "battle":
		subtitle_label.text = "watching %s vs %s  %.1fs" % [str(a["name"]), str(b["name"]), elapsed]

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), BG, true)
	draw_rect(ARENA, PAPER, true)
	draw_rect(ARENA, WALL, false, 4.0)
	for i in range(7):
		var y := ARENA.position.y + 82.0 * float(i + 1)
		draw_line(Vector2(ARENA.position.x + 4, y), Vector2(ARENA.end.x - 4, y), Color(0, 0, 0, 0.035), 1.0)
	draw_rect(Rect2(36, 912, 316, 40), Color("eeeef0"), true)
	draw_rect(Rect2(368, 912, 316, 40), Color("eeeef0"), true)
	draw_rect(Rect2(36, 912, 316, 40), WALL, false, 3.0)
	draw_rect(Rect2(368, 912, 316, 40), WALL, false, 3.0)
	draw_rect(Rect2(36, 960, 316, 86), Color("f5f3f5"), true)
	draw_rect(Rect2(368, 960, 316, 86), Color("f5f3f5"), true)
	draw_rect(Rect2(36, 960, 316, 86), WALL, false, 3.0)
	draw_rect(Rect2(368, 960, 316, 86), WALL, false, 3.0)
	if fighters.size() == 2:
		_draw_fighter(fighters[0])
		_draw_fighter(fighters[1])
	for s in shots:
		_draw_shot(s)
	for sp in sparks:
		var c: Color = sp["color"]
		c.a = clampf(float(sp["life"]) * 2.0, 0.0, 1.0)
		draw_circle(sp["pos"], 4.0, c)

func _draw_fighter(f: Dictionary) -> void:
	var pos: Vector2 = f["pos"]
	var color: Color = f["color"]
	_draw_weapon(f)
	draw_circle(pos + Vector2(4, 5), BALL_R + 3.0, Color(0, 0, 0, 0.20))
	draw_circle(pos, BALL_R + 4.0, Color("494949"))
	draw_circle(pos, BALL_R, color)
	draw_arc(pos, BALL_R + 6.0, 0.0, TAU * clampf(float(f["hp"]) / maxf(1.0, float(f["max_hp"])), 0.0, 1.0), 48, Color("ffffff"), 4.0)

func _draw_weapon(f: Dictionary) -> void:
	var pos: Vector2 = f["pos"]
	var angle := float(f["angle"])
	var color: Color = f["color"]
	match str(f["weapon"]):
		"lance":
			_draw_lance(pos, angle, color)
		"gate":
			_draw_gate(pos, angle, color)
		"staff":
			_draw_staff(pos, angle, color)
		"dagger":
			_draw_dagger(pos, angle, color)
		"katana":
			_draw_katana(pos, angle, color)
		"sword_shield":
			_draw_katana(pos, angle, color)
			draw_circle(pos + Vector2.RIGHT.rotated(angle + PI * 0.7) * 46.0, 20.0, Color("a9d1ee"))
			draw_circle(pos + Vector2.RIGHT.rotated(angle + PI * 0.7) * 46.0, 20.0, WALL, false, 3.0)
		"revolver":
			_draw_revolver(pos, angle, color)
		"ice_daggers":
			for i in range(4):
				_draw_dagger(pos, angle + i * 0.45 - 0.68, Color("bffcff"))
		"gavel":
			_draw_gavel(pos, angle, color)
		"wand":
			_draw_wand(pos, angle, color)

func _draw_lance(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var n := dir.orthogonal()
	var tip := pos + dir * 148.0
	var base := pos + dir * 24.0
	draw_line(base, tip, Color("151515"), 16.0, true)
	draw_line(base, tip, color, 10.0, true)
	draw_polygon([tip, tip - dir * 34.0 + n * 16.0, tip - dir * 24.0, tip - dir * 34.0 - n * 16.0], [Color("f1f1f1"), Color("cfd5ff"), Color("ffffff"), Color("cfd5ff")])
	draw_polyline([tip, tip - dir * 34.0 + n * 16.0, tip - dir * 24.0, tip - dir * 34.0 - n * 16.0, tip], WALL, 3.0)

func _draw_gate(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var n := dir.orthogonal()
	var c := pos + dir * 78.0
	var points := [c - dir * 34.0 - n * 20.0, c + dir * 28.0 - n * 20.0, c + dir * 42.0, c + dir * 28.0 + n * 20.0, c - dir * 34.0 + n * 20.0]
	draw_polygon(points, [color, color, Color("fff27e"), color, color])
	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], WALL, 4.0, true)
	draw_line(pos, c, WALL, 8.0, true)

func _draw_staff(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var a := pos - dir * 20.0
	var b := pos + dir * 150.0
	draw_line(a, b, WALL, 18.0, true)
	draw_line(a, b, Color("c82323"), 12.0, true)
	for t in [0.22, 0.44, 0.66, 0.88]:
		draw_circle(a.lerp(b, t), 8.0, Color("e4bc39"))

func _draw_dagger(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var n := dir.orthogonal()
	var h := pos + dir * 46.0
	var tip := pos + dir * 116.0
	draw_line(pos + dir * 14.0, h, WALL, 12.0, true)
	draw_polygon([h - n * 12.0, tip, h + n * 12.0, h + dir * 16.0], [Color("efffff"), Color("ffffff"), Color("b9f8ff"), Color("e7ffff")])
	draw_polyline([h - n * 12.0, tip, h + n * 12.0, h - n * 12.0], WALL, 3.0)
	draw_line(pos + dir * 14.0, h, color, 7.0, true)

func _draw_katana(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var n := dir.orthogonal()
	var h := pos + dir * 36.0
	var tip := pos + dir * 122.0
	draw_line(pos + dir * 14.0 - n * 14.0, pos + dir * 14.0 + n * 14.0, WALL, 5.0, true)
	draw_line(pos + dir * 12.0, h, color, 10.0, true)
	draw_line(h, tip, WALL, 12.0, true)
	draw_line(h, tip, Color("dff7ff"), 7.0, true)
	draw_circle(tip, 5.0, Color("ffffff"))

func _draw_revolver(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var n := dir.orthogonal()
	var grip := pos + dir * 34.0
	var barrel := pos + dir * 112.0
	draw_line(grip, barrel, WALL, 18.0, true)
	draw_line(grip, barrel, Color("474f5b"), 10.0, true)
	draw_line(grip, grip - n * 34.0, WALL, 13.0, true)
	draw_line(grip, grip - n * 34.0, color, 8.0, true)
	draw_circle(pos + dir * 56.0, 15.0, Color("2d3340"))
	draw_circle(pos + dir * 56.0, 15.0, WALL, false, 3.0)

func _draw_gavel(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var n := dir.orthogonal()
	var head := pos + dir * 96.0
	draw_line(pos + dir * 20.0, head, WALL, 12.0, true)
	draw_line(pos + dir * 20.0, head, color, 7.0, true)
	draw_rect(Rect2(head - dir * 18.0 - n * 34.0, Vector2(36, 68)), WALL, true)
	draw_circle(head, 20.0, Color("f7f7f7"))

func _draw_wand(pos: Vector2, angle: float, color: Color) -> void:
	var dir := Vector2.RIGHT.rotated(angle)
	var tip := pos + dir * 118.0
	draw_line(pos + dir * 18.0, tip, WALL, 12.0, true)
	draw_line(pos + dir * 18.0, tip, color, 7.0, true)
	for i in range(5):
		draw_circle(tip + Vector2.RIGHT.rotated(angle + TAU * float(i) / 5.0) * 18.0, 5.0, Color("ffd6f0"))

func _draw_shot(s: Dictionary) -> void:
	var pos: Vector2 = s["pos"]
	var vel: Vector2 = s["vel"]
	var dir := vel.normalized()
	draw_line(pos - dir * 18.0, pos + dir * 12.0, WALL, 9.0, true)
	draw_line(pos - dir * 18.0, pos + dir * 12.0, s["color"], 5.0, true)

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
