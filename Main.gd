extends Node2D

const W := 720.0
const H := 1280.0
const ARENA := Rect2(30, 208, 660, 825)
const RADIUS := 31.0
const MAX_TRAIL := 14
const SIM_STEP := 1.0 / 120.0
const MAX_SIM_STEPS := 32

var rng := RandomNumberGenerator.new()
var state := "menu"
var elapsed := 0.0
var countdown := 0.0
var battle_over := false
var paused_battle := false
var sim_speed := 1.0
var simulation_accumulator := 0.0
var fighters: Array = []
var projectiles: Array = []
var zones: Array = []
var gates: Array = []
var hazards: Array = []
var sparks: Array = []
var floating_texts: Array = []
var trails: Array = [[], []]
var shockwaves: Array = []
var shake := 0.0
var flash := 0.0

var title_label: Label
var subtitle_label: Label
var center_label: Label
var footer_label: Label
var menu_panel: VBoxContainer
var left_pick: OptionButton
var right_pick: OptionButton
var matchup_label: Label
var rematch_button: Button
var menu_button: Button
var pause_button: Button
var speed_button: Button
var sound_button: Button
var sound_on := true
var audio_players := {}
var mobile_build := false

var roster := [
    {"id":"staffmaster", "name":"STAFFMASTER", "color":Color("f1be45"), "weapon":Color("ffe59a"), "skill":"Echo Staff", "desc":"Hits grow the staff. Every 5 hits creates another orbiting echo weapon."},
    {"id":"shade", "name":"SHADE", "color":Color("a86ce8"), "weapon":Color("edc6ff"), "skill":"Rising Crit", "desc":"Crit chance rises after every hit. A full surge meter launches a burst dash."},
    {"id":"heartweaver", "name":"HEARTWEAVER", "color":Color("ef88b8"), "weapon":Color("ffd0e5"), "skill":"Heartbreak Finale", "desc":"Attack speed climbs on hits. A full meter releases expanding heart shockwaves."},
    {"id":"vindicator", "name":"VINDICATOR", "color":Color("67a8d8"), "weapon":Color("bfe4ff"), "skill":"Deprivation Zone", "desc":"Taking damage increases retaliation power. Full meter creates a damaging suppression zone."},
    {"id":"lancer", "name":"LANCER", "color":Color("6f60d8"), "weapon":Color("c3b9ff"), "skill":"Dragon Arsenal", "desc":"Hard hits increase damage. Full meter summons a radial volley of spectral lances."},
    {"id":"tyrant", "name":"TYRANT", "color":Color("d4a03e"), "weapon":Color("ffe39b"), "skill":"Imperial Gates", "desc":"Builds persistent gates over time. Gates periodically fire blades across the arena."},
    {"id":"ember", "name":"EMBER", "color":Color("ef7055"), "weapon":Color("ffc09e"), "skill":"Heat Burst", "desc":"Heat grows over time and on contact. Full heat detonates and boosts spin speed."},
    {"id":"frost", "name":"FROST", "color":Color("63bce8"), "weapon":Color("c4efff"), "skill":"Deep Chill", "desc":"Every hit slows. The freeze meter can briefly lock enemy movement."}
]
var selected_left := 0
var selected_right := 1

func _ready() -> void:
    rng.randomize()
    mobile_build = OS.has_feature("mobile")
    if not mobile_build:
        _make_audio()
    _make_ui()
    _show_menu()
    queue_redraw()

func _process(delta: float) -> void:
    var d := delta * sim_speed
    if state == "countdown":
        countdown -= delta
        center_label.text = str(maxi(1, int(ceil(countdown))))
        if countdown <= 0.0:
            state = "battle"
            center_label.text = "FIGHT!"
            _play("start")
            get_tree().create_timer(0.42).timeout.connect(func():
                if state == "battle": center_label.text = ""
            )
    elif state == "battle" and not battle_over and not paused_battle:
        simulation_accumulator += minf(d, 0.4)
        var steps := 0
        while simulation_accumulator >= SIM_STEP and steps < MAX_SIM_STEPS:
            _simulate_battle(SIM_STEP)
            simulation_accumulator -= SIM_STEP
            steps += 1
            if battle_over:
                simulation_accumulator = 0.0
                break
        if steps == MAX_SIM_STEPS:
            simulation_accumulator = 0.0

    _update_fx(delta)
    shake = maxf(0.0, shake - delta * 32.0)
    flash = maxf(0.0, flash - delta * 4.2)
    queue_redraw()

func _simulate_battle(delta: float) -> void:
    elapsed += delta
    for i in fighters.size():
        _update_fighter(fighters[i], delta, i)
    _update_projectiles(delta)
    _update_zones(delta)
    _update_gates(delta)
    _resolve_body_collision()
    _resolve_weapon_hits(fighters[0], fighters[1])
    _resolve_weapon_hits(fighters[1], fighters[0])
    _update_ui()

func _show_menu() -> void:
    state = "menu"
    battle_over = false
    paused_battle = false
    simulation_accumulator = 0.0
    fighters.clear()
    projectiles.clear()
    zones.clear()
    gates.clear()
    hazards.clear()
    sparks.clear()
    floating_texts.clear()
    shockwaves.clear()
    trails = [[], []]
    center_label.text = ""
    footer_label.text = "Pick a matchup • each fighter bends the arena rules"
    menu_panel.visible = true
    rematch_button.visible = false
    menu_button.visible = false
    pause_button.visible = false
    speed_button.visible = false
    sound_button.visible = true
    subtitle_label.text = "PHYSICS AUTO-BATTLE"
    _sync_menu_text()

func _start_battle() -> void:
    selected_left = left_pick.selected
    selected_right = right_pick.selected
    if selected_right == selected_left:
        selected_right = (selected_left + 1) % roster.size()
        right_pick.select(selected_right)
    menu_panel.visible = false
    rematch_button.visible = false
    menu_button.visible = false
    pause_button.visible = true
    speed_button.visible = true
    sound_button.visible = true
    elapsed = 0.0
    battle_over = false
    paused_battle = false
    simulation_accumulator = 0.0
    sim_speed = 1.0
    speed_button.text = "1×"
    pause_button.text = "Ⅱ"
    projectiles.clear()
    zones.clear()
    gates.clear()
    hazards.clear()
    sparks.clear()
    floating_texts.clear()
    shockwaves.clear()
    trails = [[], []]
    fighters = [
        _make_fighter(roster[selected_left], Vector2(190, 465), Vector2(205, 248).rotated(rng.randf_range(-0.28, 0.28)), 0),
        _make_fighter(roster[selected_right], Vector2(530, 770), Vector2(-228, -205).rotated(rng.randf_range(-0.28, 0.28)), 1)
    ]
    state = "countdown"
    countdown = 3.0
    center_label.text = "3"
    footer_label.text = "Auto battle • abilities scale • last orb standing wins"
    _update_ui()

func _make_fighter(data: Dictionary, pos: Vector2, vel: Vector2, side: int) -> Dictionary:
    var f := {
        "id": data.id, "name": data.name, "pos": pos, "vel": vel,
        "hp": 100.0, "max_hp": 100.0, "body_color": data.color, "weapon_color": data.weapon,
        "skill": data.skill, "angle": PI if side == 1 else 0.0,
        "spin": -3.3 if side == 1 else 3.3, "base_spin": -3.3 if side == 1 else 3.3,
        "weapon_len": 84.0, "weapon_width": 10.0, "damage": 5.0,
        "cooldown": 0.0, "hit_count": 0, "size_mult": 1.0, "crit": 0.08,
        "clones": 0, "clone_angles": [], "dash_meter": 0.0, "heat": 0.0,
        "slow_timer": 0.0, "freeze_timer": 0.0, "side": side, "pulse": 0.0,
        "ability_flash": 0.0, "meter": 0.0, "meter2": 0.0, "retaliation": 0.0,
        "attack_scale": 1.0, "gate_count": 0, "gate_timer": 0.0, "arsenal": 0,
        "invuln": 0.0, "last_hit_by": -1
    }
    match data.id:
        "staffmaster":
            f.weapon_len = 94.0; f.damage = 4.7
        "shade":
            f.weapon_len = 73.0; f.damage = 4.25
        "heartweaver":
            f.weapon_len = 78.0; f.damage = 4.3; f.base_spin = 3.05 if side == 0 else -3.05; f.spin = f.base_spin
        "vindicator":
            f.weapon_len = 88.0; f.damage = 2.8; f.base_spin = 2.65 if side == 0 else -2.65; f.spin = f.base_spin
        "lancer":
            f.weapon_len = 102.0; f.damage = 9.2; f.weapon_width = 8.0; f.base_spin = 2.35 if side == 0 else -2.35; f.spin = f.base_spin
        "tyrant":
            f.weapon_len = 80.0; f.damage = 4.0; f.base_spin = 2.75 if side == 0 else -2.75; f.spin = f.base_spin
        "ember":
            f.weapon_len = 80.0; f.damage = 5.15; f.base_spin = 3.45 if side == 0 else -3.45; f.spin = f.base_spin
        "frost":
            f.weapon_len = 90.0; f.damage = 4.4; f.base_spin = 2.8 if side == 0 else -2.8; f.spin = f.base_spin
    return f

func _update_fighter(f: Dictionary, delta: float, index: int) -> void:
    f.cooldown = maxf(0.0, f.cooldown - delta)
    f.slow_timer = maxf(0.0, f.slow_timer - delta)
    f.freeze_timer = maxf(0.0, f.freeze_timer - delta)
    f.invuln = maxf(0.0, f.invuln - delta)
    f.pulse = maxf(0.0, f.pulse - delta * 2.6)
    f.ability_flash = maxf(0.0, f.ability_flash - delta * 2.0)
    if f.freeze_timer > 0.0:
        return
    var slow_mult := 0.52 if f.slow_timer > 0.0 else 1.0
    f.angle += f.spin * delta * slow_mult

    match f.id:
        "staffmaster":
            f.spin = f.base_spin * (1.0 + (1.0 - f.hp / f.max_hp) * 0.82)
            for i in range(f.clone_angles.size()): f.clone_angles[i] += (2.0 + i * 0.18) * delta
        "shade":
            f.dash_meter += delta / 2.55
            if f.dash_meter >= 1.0:
                f.dash_meter = 0.0; f.vel *= 1.42; f.ability_flash = 1.0
                _spawn_ring(f.pos, f.body_color, 12); _float_text(f.pos + Vector2(0,-48), "SURGE", f.body_color); _play("ability")
        "heartweaver":
            f.spin = f.base_spin * f.attack_scale
            f.meter = minf(1.0, f.meter + delta * 0.035)
            if f.meter >= 1.0: _heartbreak(f)
        "vindicator":
            f.meter = minf(1.0, f.meter + delta * 0.018)
            if f.meter >= 1.0: _deprivation(f)
        "lancer":
            f.meter = minf(1.0, f.meter + delta * 0.028)
            if f.meter >= 1.0: _dragon_arsenal(f)
        "tyrant":
            f.gate_timer += delta
            if f.gate_timer >= 2.15 and f.gate_count < 12:
                f.gate_timer = 0.0; _spawn_gate(f)
        "ember":
            f.heat = minf(1.0, f.heat + delta * 0.075); f.spin = f.base_spin * (1.0 + f.heat * 0.78)
            if f.heat >= 1.0: _overheat(f)
        "frost":
            f.meter = maxf(0.0, f.meter - delta * 0.02)

    f.pos += f.vel * delta * slow_mult
    _bounce_arena(f)
    var max_speed := 400.0
    if f.id == "shade": max_speed = 460.0
    if f.vel.length() > max_speed: f.vel = f.vel.normalized() * max_speed
    if index < trails.size():
        var tr: Array = trails[index]; tr.push_front(f.pos)
        if tr.size() > MAX_TRAIL: tr.pop_back()

func _bounce_arena(f: Dictionary) -> void:
    var left := ARENA.position.x + RADIUS; var right := ARENA.end.x - RADIUS
    var top := ARENA.position.y + RADIUS; var bottom := ARENA.end.y - RADIUS
    var bounced := false
    if f.pos.x < left: f.pos.x = left; f.vel.x = absf(f.vel.x); bounced = true
    elif f.pos.x > right: f.pos.x = right; f.vel.x = -absf(f.vel.x); bounced = true
    if f.pos.y < top: f.pos.y = top; f.vel.y = absf(f.vel.y); bounced = true
    elif f.pos.y > bottom: f.pos.y = bottom; f.vel.y = -absf(f.vel.y); bounced = true
    if bounced:
        f.vel = f.vel.rotated(rng.randf_range(-0.08, 0.08)); _spawn_wall_spark(f.pos, f.body_color); _play("wall")

func _resolve_body_collision() -> void:
    if fighters.size() < 2: return
    var a: Dictionary = fighters[0]; var b: Dictionary = fighters[1]
    var d: Vector2 = b.pos - a.pos
    if d.length() <= 0.001: return
    var min_dist := RADIUS * 2.0
    if d.length() < min_dist:
        var n := d.normalized(); var overlap := min_dist - d.length()
        a.pos -= n * overlap * 0.5; b.pos += n * overlap * 0.5
        a.vel = a.vel.bounce(n) - n * 28.0; b.vel = b.vel.bounce(-n) + n * 28.0

func _weapon_segments(f: Dictionary) -> Array:
    var segs: Array = []
    var l: float = f.weapon_len * f.size_mult
    segs.append([f.pos, f.pos + Vector2.RIGHT.rotated(f.angle) * l, f.weapon_width, false])
    if f.id == "staffmaster":
        for ca in f.clone_angles:
            segs.append([f.pos, f.pos + Vector2.RIGHT.rotated(ca) * l * 0.86, maxf(7.0, f.weapon_width - 2.0), true])
    return segs

func _distance_point_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
    var ab := b - a
    if ab.length_squared() <= 0.001: return p.distance_to(a)
    var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
    return p.distance_to(a + ab * t)

func _resolve_weapon_hits(attacker: Dictionary, target: Dictionary) -> void:
    if attacker.cooldown > 0.0 or battle_over: return
    for seg in _weapon_segments(attacker):
        if _distance_point_segment(target.pos, seg[0], seg[1]) <= RADIUS + float(seg[2]) * 0.6:
            var dmg: float = attacker.damage * attacker.attack_scale
            var crit_hit := false
            match attacker.id:
                "staffmaster":
                    attacker.hit_count += 1; attacker.size_mult = minf(2.18, attacker.size_mult + 0.045); attacker.pulse = 1.0
                    if attacker.hit_count % 5 == 0 and attacker.clones < 4:
                        attacker.clones += 1; attacker.clone_angles.append(attacker.angle + TAU * float(attacker.clones) / 5.0)
                        attacker.ability_flash = 1.0; _float_text(attacker.pos + Vector2(0,-52), "+ ECHO", attacker.body_color); _spawn_ring(attacker.pos, attacker.body_color, 14); _play("ability")
                "shade":
                    crit_hit = rng.randf() < attacker.crit
                    if crit_hit: dmg *= 2.35; attacker.vel *= 1.1; attacker.ability_flash = 1.0
                    attacker.crit = minf(0.70, attacker.crit + 0.016)
                "heartweaver":
                    attacker.attack_scale = minf(2.45, attacker.attack_scale + 0.045); attacker.meter = minf(1.0, attacker.meter + 0.14)
                "vindicator":
                    attacker.meter = minf(1.0, attacker.meter + 0.08)
                "lancer":
                    attacker.hit_count += 1; attacker.damage = minf(14.0, attacker.damage + 0.22); attacker.meter = minf(1.0, attacker.meter + 0.10)
                "tyrant":
                    attacker.meter = minf(1.0, attacker.meter + 0.06)
                "ember":
                    attacker.heat = minf(1.0, attacker.heat + 0.13); dmg *= 1.0 + attacker.heat * 0.52
                "frost":
                    target.slow_timer = maxf(target.slow_timer, 0.85); attacker.meter = minf(1.0, attacker.meter + 0.18)
                    if attacker.meter >= 1.0:
                        attacker.meter = 0.0; target.freeze_timer = 1.0; _float_text(target.pos + Vector2(0,-52), "FROZEN", attacker.body_color); _play("freeze")
            _apply_damage(attacker, target, dmg, target.pos.lerp(seg[1], 0.35), crit_hit)
            attacker.cooldown = 0.145
            return

func _apply_damage(attacker: Dictionary, target: Dictionary, dmg: float, hit_pos: Vector2, crit_hit: bool = false) -> void:
    if battle_over or target.invuln > 0.0: return
    target.hp = maxf(0.0, target.hp - dmg)
    target.last_hit_by = attacker.side
    if target.id == "vindicator":
        target.retaliation = minf(2.3, target.retaliation + dmg * 0.012)
        target.damage = 2.8 + target.retaliation
        target.meter = minf(1.0, target.meter + dmg * 0.022)
    var push: Vector2 = (target.pos - attacker.pos).normalized()
    if push.length_squared() < 0.1: push = Vector2.RIGHT.rotated(attacker.angle)
    target.vel += push * (72.0 + dmg * 3.0)
    shake = minf(14.0, shake + (8.5 if crit_hit else 4.2)); flash = minf(0.35, flash + (0.22 if crit_hit else 0.08))
    _spawn_hit_fx(hit_pos, attacker.body_color, 15 if crit_hit else 9); _spawn_shockwave(hit_pos, attacker.body_color, 0.58 if crit_hit else 0.35)
    _float_text(target.pos + Vector2(0,-44), ("CRIT %.0f" if crit_hit else "-%.1f") % dmg, Color.WHITE)
    _play("crit" if crit_hit else "hit")
    if target.hp <= 0.0: _finish_battle(attacker)

func _heartbreak(f: Dictionary) -> void:
    f.meter = 0.0; f.ability_flash = 1.0
    _float_text(f.pos + Vector2(0,-60), "HEARTBREAK", f.body_color); _spawn_ring(f.pos, f.body_color, 24); _play("ability")
    zones.append({"type":"heart", "owner":f.side, "pos":f.pos, "life":1.25, "max":1.25, "tick":0.0, "radius":18.0, "color":f.body_color})

func _deprivation(f: Dictionary) -> void:
    f.meter = 0.0; f.ability_flash = 1.0
    _float_text(f.pos + Vector2(0,-60), "DEPRIVATION", f.body_color); _play("ability")
    zones.append({"type":"deprivation", "owner":f.side, "pos":f.pos, "life":2.3, "max":2.3, "tick":0.0, "radius":150.0, "color":f.body_color})

func _dragon_arsenal(f: Dictionary) -> void:
    f.meter = 0.0; f.ability_flash = 1.0; f.arsenal += 1
    _float_text(f.pos + Vector2(0,-60), "ARSENAL", f.body_color); _spawn_ring(f.pos, f.body_color, 26); _play("ability")
    for i in 10:
        var ang := TAU * float(i) / 10.0 + rng.randf_range(-0.08,0.08)
        _spawn_projectile(f.side, f.pos + Vector2.RIGHT.rotated(ang)*36.0, Vector2.RIGHT.rotated(ang)*rng.randf_range(260,350), 5.2, 3.0, f.weapon_color, "lance")

func _spawn_gate(f: Dictionary) -> void:
    f.gate_count += 1
    var edge := rng.randi_range(0,3); var p := Vector2.ZERO; var a := 0.0
    if edge == 0: p = Vector2(rng.randf_range(70,650), ARENA.position.y+34); a = PI/2
    elif edge == 1: p = Vector2(ARENA.end.x-34, rng.randf_range(260,980)); a = PI
    elif edge == 2: p = Vector2(rng.randf_range(70,650), ARENA.end.y-34); a = -PI/2
    else: p = Vector2(ARENA.position.x+34, rng.randf_range(260,980)); a = 0.0
    gates.append({"owner":f.side,"pos":p,"angle":a,"life":14.0,"fire":rng.randf_range(0.4,1.2),"color":f.body_color})
    _float_text(f.pos + Vector2(0,-50), "GATE %d" % f.gate_count, f.body_color); _play("gate")

func _overheat(f: Dictionary) -> void:
    f.heat = 0.24; f.ability_flash = 1.0
    _spawn_ring(f.pos, f.body_color, 22); _spawn_shockwave(f.pos, f.body_color, 0.9); _float_text(f.pos + Vector2(0,-50), "OVERHEAT", f.body_color); _play("ability")
    zones.append({"type":"blast", "owner":f.side, "pos":f.pos, "life":0.45, "max":0.45, "tick":0.0, "radius":20.0, "color":f.body_color})

func _spawn_projectile(owner: int, pos: Vector2, vel: Vector2, dmg: float, life: float, color: Color, kind: String) -> void:
    projectiles.append({"owner":owner,"pos":pos,"vel":vel,"damage":dmg,"life":life,"color":color,"kind":kind,"radius":7.0})

func _update_projectiles(delta: float) -> void:
    for i in range(projectiles.size()-1,-1,-1):
        var p: Dictionary = projectiles[i]; p.life -= delta; p.pos += p.vel * delta
        if p.pos.x < ARENA.position.x+8 or p.pos.x > ARENA.end.x-8: p.vel.x *= -1.0
        if p.pos.y < ARENA.position.y+8 or p.pos.y > ARENA.end.y-8: p.vel.y *= -1.0
        if p.life <= 0.0: projectiles.remove_at(i); continue
        if p.owner < 0 or p.owner >= fighters.size(): continue
        var target: Dictionary = fighters[1-p.owner]
        if p.pos.distance_to(target.pos) <= RADIUS + p.radius:
            _apply_damage(fighters[p.owner], target, p.damage, p.pos, false)
            projectiles.remove_at(i)

func _update_zones(delta: float) -> void:
    for i in range(zones.size()-1,-1,-1):
        var z: Dictionary = zones[i]; z.life -= delta; z.tick -= delta
        var prog: float = 1.0 - z.life / z.max
        if z.type == "heart": z.radius = 22.0 + prog * 230.0
        elif z.type == "blast": z.radius = 20.0 + prog * 190.0
        if z.owner >= 0 and z.owner < fighters.size():
            if z.type == "deprivation": z.pos = fighters[z.owner].pos
            var target: Dictionary = fighters[1-z.owner]
            if z.tick <= 0.0 and target.pos.distance_to(z.pos) <= z.radius + RADIUS:
                z.tick = 0.28 if z.type == "deprivation" else 0.18
                var dmg := 2.1
                if z.type == "heart": dmg = 3.4
                elif z.type == "blast": dmg = 4.8
                _apply_damage(fighters[z.owner], target, dmg, target.pos, false)
                if z.type == "deprivation": target.slow_timer = maxf(target.slow_timer, 0.4)
        if z.life <= 0.0: zones.remove_at(i)

func _update_gates(delta: float) -> void:
    for i in range(gates.size()-1,-1,-1):
        var g: Dictionary = gates[i]; g.life -= delta; g.fire -= delta
        if g.life <= 0.0: gates.remove_at(i); continue
        if g.fire <= 0.0:
            g.fire = rng.randf_range(1.15,1.65)
            var dir := Vector2.RIGHT.rotated(g.angle).rotated(rng.randf_range(-0.12,0.12))
            _spawn_projectile(g.owner, g.pos, dir*320.0, 4.0, 3.6, g.color, "gate_blade"); _play("shoot")

func _finish_battle(winner: Dictionary) -> void:
    battle_over = true; state = "result"; paused_battle = false
    center_label.text = "%s WINS!" % winner.name
    footer_label.text = "Battle %.1fs • REMATCH generates another outcome" % elapsed
    rematch_button.visible = true; menu_button.visible = true; pause_button.visible = false; speed_button.visible = false
    _spawn_ring(winner.pos, winner.body_color, 32); _spawn_shockwave(winner.pos, winner.body_color, 1.0); _play("win")

func _spawn_hit_fx(pos: Vector2, color: Color, count: int) -> void:
    for i in count: sparks.append({"pos":pos,"vel":Vector2(rng.randf_range(75,210),0).rotated(rng.randf_range(0,TAU)),"life":rng.randf_range(0.28,0.58),"max":0.58,"color":color,"r":rng.randf_range(2.5,6.5)})
func _spawn_wall_spark(pos: Vector2, color: Color) -> void:
    for i in 4: sparks.append({"pos":pos,"vel":Vector2(rng.randf_range(35,90),0).rotated(rng.randf_range(0,TAU)),"life":0.22,"max":0.22,"color":color,"r":2.5})
func _spawn_ring(pos: Vector2, color: Color, count: int) -> void:
    for i in count:
        var ang := TAU * float(i) / float(count); sparks.append({"pos":pos,"vel":Vector2.RIGHT.rotated(ang)*rng.randf_range(95,195),"life":0.58,"max":0.58,"color":color,"r":3.8})
func _spawn_shockwave(pos: Vector2, color: Color, strength: float = 0.5) -> void:
    shockwaves.append({"pos":pos,"life":0.42,"max":0.42,"color":color,"strength":strength})
func _float_text(pos: Vector2, txt: String, color: Color) -> void:
    floating_texts.append({"pos":pos,"text":txt,"life":0.78,"max":0.78,"color":color})
func _update_fx(delta: float) -> void:
    for i in range(sparks.size()-1,-1,-1):
        var p: Dictionary = sparks[i]; p.life -= delta; p.pos += p.vel * delta; p.vel *= 0.90
        if p.life <= 0.0: sparks.remove_at(i)
    for i in range(floating_texts.size()-1,-1,-1):
        var t: Dictionary = floating_texts[i]; t.life -= delta; t.pos.y -= 44.0*delta
        if t.life <= 0.0: floating_texts.remove_at(i)
    for i in range(shockwaves.size()-1,-1,-1):
        var s: Dictionary = shockwaves[i]; s.life -= delta
        if s.life <= 0.0: shockwaves.remove_at(i)

func _make_audio() -> void:
    for key in ["hit","crit","wall","ability","freeze","gate","shoot","start","win"]:
        var p := AudioStreamPlayer.new(); p.stream = load("res://audio/%s.wav" % key); p.volume_db = -5.0 if key != "wall" else -12.0; add_child(p); audio_players[key] = p
func _play(key: String) -> void:
    if not sound_on or not audio_players.has(key): return
    var p: AudioStreamPlayer = audio_players[key]
    p.pitch_scale = rng.randf_range(0.93,1.07) if key in ["hit","wall","shoot"] else 1.0
    p.play()

func _make_ui() -> void:
    title_label = Label.new(); title_label.text = "ORBIT CLASH"; title_label.position = Vector2(0,26); title_label.size = Vector2(W,55); title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.add_theme_font_size_override("font_size",39); add_child(title_label)
    subtitle_label = Label.new(); subtitle_label.position = Vector2(0,79); subtitle_label.size = Vector2(W,28); subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; subtitle_label.modulate = Color(0.72,0.74,0.82); subtitle_label.add_theme_font_size_override("font_size",16); add_child(subtitle_label)
    center_label = Label.new(); center_label.position = Vector2(58,500); center_label.size = Vector2(604,165); center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; center_label.add_theme_font_size_override("font_size",44); add_child(center_label)
    footer_label = Label.new(); footer_label.position = Vector2(20,1240); footer_label.size = Vector2(W-40,26); footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; footer_label.modulate = Color(0.70,0.73,0.80); footer_label.add_theme_font_size_override("font_size",14); add_child(footer_label)
    menu_panel = VBoxContainer.new(); menu_panel.position = Vector2(88,150); menu_panel.size = Vector2(544,930); menu_panel.add_theme_constant_override("separation",13); add_child(menu_panel)
    var h := Label.new(); h.text = "BUILD A MATCHUP"; h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; h.add_theme_font_size_override("font_size",28); menu_panel.add_child(h)
    var intro := Label.new(); intro.text = "8 original fighters • physics-driven combat\npassives scale until the arena turns chaotic"; intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; intro.custom_minimum_size = Vector2(0,58); intro.modulate = Color(0.72,0.74,0.82); menu_panel.add_child(intro)
    var l1 := Label.new(); l1.text = "LEFT FIGHTER"; l1.add_theme_font_size_override("font_size",16); menu_panel.add_child(l1)
    left_pick = OptionButton.new(); left_pick.custom_minimum_size = Vector2(0,54); menu_panel.add_child(left_pick)
    var l2 := Label.new(); l2.text = "RIGHT FIGHTER"; l2.add_theme_font_size_override("font_size",16); menu_panel.add_child(l2)
    right_pick = OptionButton.new(); right_pick.custom_minimum_size = Vector2(0,54); menu_panel.add_child(right_pick)
    for item in roster:
        left_pick.add_item(item.name + "  •  " + item.skill); right_pick.add_item(item.name + "  •  " + item.skill)
    left_pick.select(selected_left); right_pick.select(selected_right); left_pick.item_selected.connect(func(_i): _sync_menu_text()); right_pick.item_selected.connect(func(_i): _sync_menu_text())
    matchup_label = Label.new(); matchup_label.custom_minimum_size = Vector2(0,230); matchup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; matchup_label.add_theme_font_size_override("font_size",16); menu_panel.add_child(matchup_label)
    var random_btn := Button.new(); random_btn.text = "RANDOM MATCHUP"; random_btn.custom_minimum_size = Vector2(0,52); random_btn.pressed.connect(_randomize_matchup); menu_panel.add_child(random_btn)
    var start := Button.new(); start.text = "START BATTLE"; start.custom_minimum_size = Vector2(0,68); start.add_theme_font_size_override("font_size",22); start.pressed.connect(_start_battle); menu_panel.add_child(start)
    rematch_button = Button.new(); rematch_button.text = "REMATCH"; rematch_button.position = Vector2(175,940); rematch_button.size = Vector2(170,60); rematch_button.visible = false; rematch_button.pressed.connect(_start_battle); add_child(rematch_button)
    menu_button = Button.new(); menu_button.text = "ROSTER"; menu_button.position = Vector2(375,940); menu_button.size = Vector2(170,60); menu_button.visible = false; menu_button.pressed.connect(_show_menu); add_child(menu_button)
    pause_button = Button.new(); pause_button.text = "Ⅱ"; pause_button.position = Vector2(530,118); pause_button.size = Vector2(54,48); pause_button.visible = false; pause_button.pressed.connect(_toggle_pause); add_child(pause_button)
    speed_button = Button.new(); speed_button.text = "1×"; speed_button.position = Vector2(590,118); speed_button.size = Vector2(54,48); speed_button.visible = false; speed_button.pressed.connect(_cycle_speed); add_child(speed_button)
    sound_button = Button.new(); sound_button.text = "SFX"; sound_button.position = Vector2(650,118); sound_button.size = Vector2(54,48); sound_button.pressed.connect(_toggle_sound); add_child(sound_button)

func _sync_menu_text() -> void:
    if left_pick == null or right_pick == null: return
    selected_left = left_pick.selected; selected_right = right_pick.selected
    var a: Dictionary = roster[selected_left]; var b: Dictionary = roster[selected_right]
    matchup_label.text = "%s — %s\n%s\n\nVS\n\n%s — %s\n%s" % [a.name,a.skill,a.desc,b.name,b.skill,b.desc]
func _randomize_matchup() -> void:
    selected_left = rng.randi_range(0,roster.size()-1); selected_right = rng.randi_range(0,roster.size()-1)
    while selected_right == selected_left: selected_right = rng.randi_range(0,roster.size()-1)
    left_pick.select(selected_left); right_pick.select(selected_right); _sync_menu_text(); _play("start")
func _toggle_pause() -> void:
    if state != "battle": return
    paused_battle = not paused_battle; pause_button.text = "▶" if paused_battle else "Ⅱ"; center_label.text = "PAUSED" if paused_battle else ""
func _cycle_speed() -> void:
    if sim_speed < 1.5: sim_speed = 2.0
    elif sim_speed < 3.0: sim_speed = 4.0
    else: sim_speed = 1.0
    speed_button.text = "%g×" % sim_speed
func _toggle_sound() -> void:
    sound_on = not sound_on; sound_button.text = "SFX" if sound_on else "MUTE"
func _update_ui() -> void: pass

func _fighter_stat_line(f: Dictionary) -> String:
    match f.id:
        "staffmaster": return "STAFF %.2f×   ECHO %d" % [f.size_mult,f.clones]
        "shade": return "CRIT %d%%   SURGE %d%%" % [int(f.crit*100.0),int(f.dash_meter*100.0)]
        "heartweaver": return "ATK SPD %.2f×   FINALE %d%%" % [f.attack_scale,int(f.meter*100.0)]
        "vindicator": return "DMG %.2f   ZONE %d%%" % [f.damage,int(f.meter*100.0)]
        "lancer": return "DMG %.2f   ARSENAL %d" % [f.damage,f.arsenal]
        "tyrant": return "GATES %d   NEXT %d%%" % [f.gate_count,int(clampf(f.gate_timer/2.15,0,1)*100)]
        "ember": return "HEAT %d%%   SPIN %.2f" % [int(f.heat*100.0),absf(f.spin)]
        "frost": return "FREEZE %d%%   SPIN %.2f" % [int(f.meter*100.0),absf(f.spin)]
    return ""
func _ability_ratio(f: Dictionary) -> float:
    match f.id:
        "staffmaster": return float(f.hit_count % 5)/5.0
        "shade": return f.dash_meter
        "heartweaver","vindicator","lancer","frost": return f.meter
        "tyrant": return clampf(f.gate_timer/2.15,0.0,1.0)
        "ember": return f.heat
    return 0.0

func _draw() -> void:
    if ThemeDB.fallback_font == null:
        return
    var off := Vector2.ZERO
    if shake > 0.0: off = Vector2(rng.randf_range(-shake,shake),rng.randf_range(-shake,shake))
    draw_rect(Rect2(0,0,W,H),Color("0d1016"),true); _draw_background_grid()
    if state != "menu":
        _draw_top_match_ui(); _draw_arena(off)
        if fighters.size() == 2:
            _draw_trails(off); _draw_gates(off); _draw_zones(off); _draw_projectiles(off); _draw_fighter(fighters[0],off); _draw_fighter(fighters[1],off); _draw_bottom_stats()
    for s in shockwaves:
        var prog: float = 1.0-s.life/s.max; draw_arc(s.pos+off,8.0+prog*(72.0+42.0*s.strength),0,TAU,44,Color(s.color,(1.0-prog)*0.55),3.0)
    for p in sparks: draw_circle(p.pos+off,p.r,Color(p.color,clampf(p.life/p.max,0,1)))
    for t in floating_texts: draw_string(ThemeDB.fallback_font,t.pos+off,t.text,HORIZONTAL_ALIGNMENT_CENTER,-1,18,Color(t.color,clampf(t.life/t.max,0,1)))
    if flash > 0.0: draw_rect(Rect2(0,0,W,H),Color(1,1,1,flash),true)

func _draw_background_grid() -> void:
    for y in range(0,14):
        var yy := 120.0+y*82.0; draw_line(Vector2(0,yy),Vector2(W,yy),Color(1,1,1,0.018),1.0)
    for x in range(0,9):
        var xx := x*90.0; draw_line(Vector2(xx,110),Vector2(xx,H),Color(1,1,1,0.014),1.0)
func _draw_top_match_ui() -> void:
    if fighters.size()<2:return
    var a:Dictionary=fighters[0];var b:Dictionary=fighters[1]
    draw_string(ThemeDB.fallback_font,Vector2(34,142),a.name,HORIZONTAL_ALIGNMENT_LEFT,290,18,a.body_color); draw_string(ThemeDB.fallback_font,Vector2(396,142),b.name,HORIZONTAL_ALIGNMENT_RIGHT,290,18,b.body_color); draw_string(ThemeDB.fallback_font,Vector2(325,143),"VS",HORIZONTAL_ALIGNMENT_CENTER,70,17,Color("c7ccd8"))
    _draw_hp_meter(Vector2(34,154),286,a.hp/a.max_hp,a.body_color,false); _draw_hp_meter(Vector2(400,154),286,b.hp/b.max_hp,b.body_color,true)
func _draw_hp_meter(pos:Vector2,width:float,ratio:float,color:Color,reverse:bool)->void:
    draw_rect(Rect2(pos,Vector2(width,12)),Color("252b36"),true);var w:=width*clampf(ratio,0,1);var x:=pos.x+width-w if reverse else pos.x;draw_rect(Rect2(Vector2(x,pos.y),Vector2(w,12)),color,true);draw_rect(Rect2(pos,Vector2(width,12)),Color(1,1,1,0.16),false,1.0)
func _draw_arena(off:Vector2)->void:
    var ar:=Rect2(ARENA.position+off,ARENA.size);draw_rect(ar,Color("151a22"),true)
    for y in range(0,9):
        var yy:=ar.position.y+46.0+y*91.0;draw_line(Vector2(ar.position.x+8,yy),Vector2(ar.end.x-8,yy),Color(1,1,1,0.027),1.0)
    for x in range(0,7):
        var xx:=ar.position.x+55.0+x*92.0;draw_line(Vector2(xx,ar.position.y+8),Vector2(xx,ar.end.y-8),Color(1,1,1,0.018),1.0)
    draw_rect(ar,Color("9ca7b9"),false,4.0);draw_rect(Rect2(ar.position+Vector2(8,8),ar.size-Vector2(16,16)),Color(1,1,1,0.07),false,1.0)
func _draw_trails(off:Vector2)->void:
    for i in min(2,trails.size()):
        if i>=fighters.size():continue
        var tr:Array=trails[i];var c:Color=fighters[i].body_color
        for j in range(1,tr.size()):
            var alpha:=0.14*(1.0-float(j)/float(MAX_TRAIL));draw_line(tr[j-1]+off,tr[j]+off,Color(c,alpha),maxf(1.0,5.0-float(j)*0.25),true)
func _draw_gates(off:Vector2)->void:
    for g in gates:
        draw_arc(g.pos+off,22,0,TAU,28,Color(g.color,0.72),5.0);draw_arc(g.pos+off,13,0,TAU,20,Color(1,1,1,0.28),2.0);draw_line(g.pos+off,g.pos+off+Vector2.RIGHT.rotated(g.angle)*30.0,Color(g.color,0.7),3.0)
func _draw_zones(off:Vector2)->void:
    for z in zones:
        var alpha:=clampf(z.life/z.max,0,1)*0.30;draw_circle(z.pos+off,z.radius,Color(z.color,alpha));draw_arc(z.pos+off,z.radius,0,TAU,48,Color(z.color,0.72),3.0)
func _draw_projectiles(off:Vector2)->void:
    for p in projectiles:
        var dir:Vector2=p.vel.normalized();var tail:Vector2=p.pos-dir*18.0;draw_line(tail+off,p.pos+off,Color(p.color,0.85),5.0,true);draw_circle(p.pos+off,p.radius,p.color)
func _draw_fighter(f:Dictionary,off:Vector2)->void:
    var l:float=f.weapon_len*f.size_mult
    if f.ability_flash>0.0:draw_circle(f.pos+off,RADIUS+14.0+f.ability_flash*7.0,Color(f.body_color,0.12*f.ability_flash))
    _draw_weapon(f.pos+off,f.angle,l,f.weapon_width,f.weapon_color,false)
    if f.id=="staffmaster":
        for ca in f.clone_angles:_draw_weapon(f.pos+off,ca,l*0.86,maxf(7.0,f.weapon_width-2.0),Color(f.weapon_color,0.66),true)
    draw_circle(f.pos+off,RADIUS+6.0,Color("06080d"));draw_circle(f.pos+off,RADIUS,f.body_color);draw_circle(f.pos+off,RADIUS-8.0,Color(f.body_color.lightened(0.08),0.72));draw_string(ThemeDB.fallback_font,f.pos+off+Vector2(-18,6),str(int(ceil(f.hp))),HORIZONTAL_ALIGNMENT_CENTER,36,15,Color("11141b"))
func _draw_weapon(origin:Vector2,angle:float,length:float,width:float,color:Color,ghost:bool)->void:
    var dir:=Vector2.RIGHT.rotated(angle);var tip:=origin+dir*length;var handle_end:=origin+dir*minf(29.0,length*0.32);var alpha:=0.72 if ghost else 1.0;draw_line(origin,tip,Color(0.02,0.025,0.04,alpha),width+6.0,true);draw_line(origin,handle_end,Color("6e7480",alpha),width+1.0,true);draw_line(handle_end,tip,Color(color,alpha),width,true);draw_circle(tip,width*0.72,Color(color,alpha))
func _draw_bottom_stats()->void:
    if fighters.size()<2:return
    _draw_stat_card(Rect2(32,1060,316,145),fighters[0],false);_draw_stat_card(Rect2(372,1060,316,145),fighters[1],true)
func _draw_stat_card(rect:Rect2,f:Dictionary,right_align:bool)->void:
    draw_rect(rect,Color("151a22"),true);draw_rect(rect,Color(1,1,1,0.10),false,1.0);var x:=rect.position.x+14;var align:=HORIZONTAL_ALIGNMENT_RIGHT if right_align else HORIZONTAL_ALIGNMENT_LEFT;draw_string(ThemeDB.fallback_font,Vector2(x,rect.position.y+27),f.name,align,rect.size.x-28,18,f.body_color);draw_string(ThemeDB.fallback_font,Vector2(x,rect.position.y+53),_fighter_stat_line(f),align,rect.size.x-28,15,Color("d7dbe5"));draw_string(ThemeDB.fallback_font,Vector2(x,rect.position.y+80),f.skill,align,rect.size.x-28,14,Color("9098aa"));var bar:=Rect2(rect.position+Vector2(14,96),Vector2(rect.size.x-28,13));draw_rect(bar,Color("292f3a"),true);draw_rect(Rect2(bar.position,Vector2(bar.size.x*_ability_ratio(f),bar.size.y)),f.body_color,true);draw_string(ThemeDB.fallback_font,Vector2(x,rect.position.y+132),"HP %d / %d"%[int(ceil(f.hp)),int(f.max_hp)],align,rect.size.x-28,14,Color("bfc5d1"))
