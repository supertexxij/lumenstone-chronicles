extends CharacterBody3D
const HitsplatUtil = preload("res://scripts/combat/hitsplat.gd")
## Click-to-move + WASD player with elevated camera follow
## Humanoid mesh: head/torso/arms/legs + equip visuals + walk / attack poses

signal clicked_ground(pos: Vector3)

const SPEED := 6.5
const ACCEL := 18.0
const CAM_BASE := Vector3(0, 14, 12)
const CAM_ZOOM_MIN := 0.55
const CAM_ZOOM_MAX := 1.55

@onready var mesh_root: Node3D = $MeshRoot
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var parts: Dictionary = {}
var target_pos: Vector3 = Vector3.ZERO
var has_click_target: bool = false
var cam_yaw: float = 0.0
var cam_zoom: float = 1.0
var ui_blocking: bool = false
var _walk_phase: float = 0.0
var _attack_t: float = 0.0
var _attacking: bool = false
var _last_foot_phase: float = 0.0
var _weapon_mesh_style: String = ""
var _stuck_timer: float = 0.0
var _assist_side: int = 1
var _nav_ready: bool = false
var _nav_agent: NavigationAgent3D
var _path_idx: int = 0
var _assist_waypoints: Array = []
var _manual_move: bool = false
var _was_manual: bool = false
var _desired_vel: Vector3 = Vector3.ZERO
var _click_marker: MeshInstance3D = null
var _click_marker_t: float = -1.0
var _click_marker_mat: StandardMaterial3D = null
var _foot_dust: CPUParticles3D = null

func _ready() -> void:
	add_to_group("player")
	parts = HumanoidBuilder.build(mesh_root)
	GameState.state_changed.connect(_on_state_changed)
	GameState.soft_defeated.connect(soft_respawn)
	GameState.combat_target_changed.connect(_on_combat_target)
	if GameState.has_signal("heal_tick") and not GameState.heal_tick.is_connected(_on_heal_tick):
		GameState.heal_tick.connect(_on_heal_tick)
	_ensure_nav_agent()
	_apply_appearance()
	_apply_camera_zoom()
	global_position = Vector3(GameState.position_xz.x, 0, GameState.position_xz.y)
	target_pos = global_position

func _ensure_nav_agent() -> void:
	_nav_agent = get_node_or_null("NavigationAgent3D")
	if _nav_agent == null:
		_nav_agent = NavigationAgent3D.new()
		_nav_agent.name = "NavigationAgent3D"
		add_child(_nav_agent)
	_nav_agent.path_desired_distance = 0.55
	_nav_agent.target_desired_distance = 0.45
	# Light RVO avoidance vs other agents / NavigationObstacle3D (NPCs, foes)
	_nav_agent.avoidance_enabled = true
	_nav_agent.radius = 0.42
	_nav_agent.height = 1.6
	_nav_agent.max_speed = SPEED
	_nav_agent.neighbor_distance = 2.8
	_nav_agent.max_neighbors = 6
	_nav_agent.time_horizon_agents = 0.7
	_nav_agent.time_horizon_obstacles = 0.35
	_nav_agent.avoidance_priority = 1.0
	if not _nav_agent.velocity_computed.is_connected(_on_nav_velocity_computed):
		_nav_agent.velocity_computed.connect(_on_nav_velocity_computed)

func set_navigation_ready(ok: bool) -> void:
	_nav_ready = ok
	_ensure_nav_agent()

func _on_state_changed() -> void:
	_apply_appearance()

func _on_combat_target(_e: Node) -> void:
	pass

func soft_respawn() -> void:
	global_position = Vector3(0, 0, 10)
	target_pos = global_position
	has_click_target = false
	_manual_move = false
	_desired_vel = Vector3.ZERO
	velocity = Vector3.ZERO
	if _nav_agent:
		_nav_agent.set_velocity_forced(Vector3.ZERO)

func _on_heal_tick(amount: int) -> void:
	if amount > 0:
		HitsplatUtil.spawn_heal(self, amount, 2.05)

func _on_nav_velocity_computed(safe_velocity: Vector3) -> void:
	## Apply RVO-safe velocity. WASD prefers player intent so avoidance does not fight the stick.
	if _manual_move:
		velocity.x = lerpf(safe_velocity.x, _desired_vel.x, 0.78)
		velocity.z = lerpf(safe_velocity.z, _desired_vel.z, 0.78)
	else:
		velocity.x = safe_velocity.x
		velocity.z = safe_velocity.z

func _apply_appearance() -> void:
	if parts.is_empty():
		return
	var skin: Color = Color(str(GameState.SKIN_HEX.get(GameState.appearance.get("skin", "medium"), "#c68642")))
	var hair: Color = Color(str(GameState.HAIR_HEX.get(GameState.appearance.get("hair", "brown"), "#5c4033")))
	var outfit: Color = Color(str(GameState.OUTFIT_HEX.get(GameState.appearance.get("outfit", "cream"), "#f4e4bc")))
	var cape_col: Color = Color(str(GameState.CAPE_HEX.get(GameState.appearance.get("cape_color", "crimson"), "#c1121f")))
	HumanoidBuilder.apply_human_colors(parts, skin, hair, outfit, cape_col)

	var cape_id = GameState.equipped.get("cape")
	if cape_id != null:
		var citem: Dictionary = ItemDB.get_item(str(cape_id))
		if not citem.is_empty():
			HumanoidBuilder.style_cloak(parts, citem)
			HumanoidBuilder.style_armor(parts, citem)
		else:
			var cape_mesh: MeshInstance3D = parts.get("cape")
			if cape_mesh:
				cape_mesh.visible = true
	else:
		var cape_mesh: MeshInstance3D = parts.get("cape")
		if cape_mesh:
			cape_mesh.visible = true
		HumanoidBuilder.style_armor(parts, {})

	var weapon_root: Node3D = parts.get("weapon")
	var wid = GameState.equipped.get("weapon")
	if weapon_root:
		weapon_root.visible = wid != null
		if wid != null:
			var witem: Dictionary = ItemDB.get_item(str(wid))
			var style: String = str(witem.get("mesh", "sword"))
			if style != _weapon_mesh_style or parts.get("blade") == null:
				HumanoidBuilder.style_weapon(parts, witem)
				_weapon_mesh_style = style
			else:
				var wcol := Color(witem.get("color", "#a67c52"))
				HumanoidBuilder.set_color(parts.get("blade"), wcol)
				HumanoidBuilder.set_color(parts.get("hilt"), wcol.darkened(0.25))
				HumanoidBuilder.set_color(parts.get("pommel"), wcol.lightened(0.15))
		else:
			_weapon_mesh_style = ""

	var hat_root: Node3D = parts.get("hat")
	var hid = GameState.equipped.get("head")
	if hat_root:
		if hid != null:
			var hitem: Dictionary = ItemDB.get_item(str(hid))
			HumanoidBuilder.style_hat(parts, hitem)
		else:
			hat_root.visible = false
			var jewel: MeshInstance3D = parts.get("hat_jewel")
			if jewel:
				jewel.visible = false

	var belt_mesh: MeshInstance3D = parts.get("belt")
	var bid = GameState.equipped.get("belt")
	if belt_mesh:
		belt_mesh.visible = bid != null
		if bid != null:
			var bitem: Dictionary = ItemDB.get_item(str(bid))
			HumanoidBuilder.set_color(belt_mesh, Color(bitem.get("color", "#d4a017")))

	# Accessory 3D attach
	var acc_root: Node3D = parts.get("accessory")
	var aid = GameState.equipped.get("accessory")
	if acc_root:
		acc_root.visible = aid != null
		if aid != null:
			var aitem: Dictionary = ItemDB.get_item(str(aid))
			HumanoidBuilder.style_accessory(parts, aitem)

func _unhandled_input(event: InputEvent) -> void:
	if ui_blocking:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-0.08)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(0.08)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		cam_yaw -= event.relative.x * 0.005
	if event.is_action_pressed("zoom_in"):
		_adjust_zoom(-0.12)
	if event.is_action_pressed("zoom_out"):
		_adjust_zoom(0.12)

func _adjust_zoom(delta_z: float) -> void:
	cam_zoom = clampf(cam_zoom + delta_z, CAM_ZOOM_MIN, CAM_ZOOM_MAX)
	_apply_camera_zoom()

func _apply_camera_zoom() -> void:
	if camera == null:
		return
	camera.position = CAM_BASE * cam_zoom

func _handle_click() -> void:
	var mouse := get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse)
	var dir: Vector3 = camera.project_ray_normal(mouse)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	# Pass 1 — entities only (NPC layer 3 / bit 4, enemy layer 4 / bit 8).
	# Dense props & halls no longer steal clicks from foes / mentors / ground.
	var q_ent: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from + dir * 220.0)
	q_ent.collision_mask = 4 | 8
	q_ent.collide_with_areas = true
	q_ent.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(q_ent)
	if not hit.is_empty():
		var collider = hit.collider
		if collider and collider.is_in_group("enemies"):
			if collider.has_method("is_alive") and not collider.is_alive():
				pass
			else:
				GameState.set_combat_target(collider)
				GameState.mark_combat_tutorial()
				_set_move_target(collider.global_position)
				return
		if collider and collider.is_in_group("npcs"):
			var dist: float = global_position.distance_to(collider.global_position)
			if dist <= 4.0:
				collider.request_talk()
			else:
				_set_move_target(collider.global_position)
				set_meta("pending_npc", collider)
			return
	# Pass 2 — ground plane move (ignore static prop bodies)
	if abs(dir.y) > 0.01:
		var t := -from.y / dir.y
		if t > 0:
			_set_move_target(from + dir * t)

func _set_move_target(pos: Vector3) -> void:
	target_pos = Vector3(pos.x, 0, pos.z)
	has_click_target = true
	_stuck_timer = 0.0
	_assist_waypoints.clear()
	_path_idx = 0
	_show_click_marker(target_pos)
	# Prefer NavigationAgent when navmesh is ready (outdoor + indoor hall regions)
	if _nav_ready and _nav_agent:
		_nav_agent.target_position = target_pos
		# Raycast assist as backup if agent has no path yet
		if _nav_agent.is_navigation_finished() or not _nav_agent.is_target_reachable():
			_build_assist_waypoints(target_pos)
	else:
		_build_assist_waypoints(target_pos)
	if GameState.combat_target and is_instance_valid(GameState.combat_target):
		if target_pos.distance_to(GameState.combat_target.global_position) > float(EnemyDB.base_combat.get("escape_range", 8)):
			GameState.set_combat_target(null)

func _build_assist_waypoints(goal: Vector3) -> void:
	## Raycast lookahead around props when no navmesh path is available.
	_assist_waypoints.clear()
	var space := get_world_3d().direct_space_state if get_world_3d() else null
	if space == null:
		return
	var from := global_position
	var to := goal
	var dir := to - from
	dir.y = 0
	var dist := dir.length()
	if dist < 0.5:
		return
	dir = dir.normalized()
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 0.6, 0), from + dir * minf(dist, 14.0) + Vector3(0, 0.6, 0))
	q.collision_mask = 1
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	# Bias left then right around the blocker
	for side in [1.0, -1.0, 2.0, -2.0]:
		var side_dir: Vector3 = Vector3(-dir.z, 0, dir.x) * side
		var via: Vector3 = hit.position + side_dir * 1.35
		via.y = 0.0
		var q2 := PhysicsRayQueryParameters3D.create(from + Vector3(0, 0.6, 0), via + Vector3(0, 0.6, 0))
		q2.collision_mask = 1
		q2.exclude = [self]
		if space.intersect_ray(q2).is_empty():
			_assist_waypoints.append(via)
			_assist_waypoints.append(goal)
			return

func _repath_around_blocker() -> void:
	## Called when click-move is jammed against a prop — refresh nav + side waypoints.
	if not has_click_target:
		return
	_assist_waypoints.clear()
	_path_idx = 0
	if _nav_ready and _nav_agent:
		_nav_agent.target_position = target_pos
	_build_assist_waypoints(target_pos)

func play_attack_swing() -> void:
	_attacking = true
	_attack_t = 0.0
	AudioBus.play_swing()
	# Weapon is parented to the right arm, so the swing pose carries it.

func _physics_process(delta: float) -> void:
	if ui_blocking:
		velocity = Vector3.ZERO
		_animate_walk(false, delta)
		_animate_attack(delta)
		move_and_slide()
		return

	if Input.is_action_pressed("cam_left"):
		cam_yaw += 1.5 * delta
	if Input.is_action_pressed("cam_right"):
		cam_yaw -= 1.5 * delta
	camera_pivot.rotation.y = cam_yaw

	# Arrive near pending NPC → talk
	if has_meta("pending_npc"):
		var npc = get_meta("pending_npc")
		if is_instance_valid(npc) and global_position.distance_to(npc.global_position) < 3.2:
			remove_meta("pending_npc")
			has_click_target = false
			velocity = Vector3.ZERO
			npc.request_talk()

	var input_dir: Vector2 = Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var moving := false
	_manual_move = input_dir.length() > 0.1
	if _manual_move:
		has_click_target = false
		if has_meta("pending_npc"):
			remove_meta("pending_npc")
		# On WASD press, cancel click-nav so RVO does not keep steering to an old goal
		if (not _was_manual) and _nav_agent and _nav_ready:
			_nav_agent.target_position = global_position
		var forward: Vector3 = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
		var right: Vector3 = Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
		var wish: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized()
		# Soft mentor/foe sidestep only — do not let nav RVO yank WASD
		wish = _soft_avoid_entities(wish)
		velocity.x = move_toward(velocity.x, wish.x * SPEED, ACCEL * delta)
		velocity.z = move_toward(velocity.z, wish.z * SPEED, ACCEL * delta)
		mesh_root.rotation.y = atan2(wish.x, wish.z)
		moving = true
	elif has_click_target:
		var steer_pos: Vector3 = target_pos
		var using_nav := false
		if _nav_ready and _nav_agent and not _nav_agent.is_navigation_finished():
			var next_pos: Vector3 = _nav_agent.get_next_path_position()
			if next_pos.distance_to(global_position) > 0.05:
				steer_pos = next_pos
				using_nav = true
		elif _path_idx < _assist_waypoints.size():
			steer_pos = _assist_waypoints[_path_idx]
			if global_position.distance_to(Vector3(steer_pos.x, 0, steer_pos.z)) < 0.55:
				_path_idx += 1
				if _path_idx < _assist_waypoints.size():
					steer_pos = _assist_waypoints[_path_idx]
				else:
					steer_pos = target_pos
		var to: Vector3 = steer_pos - global_position
		to.y = 0
		var goal_dist: float = Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z).length()
		if goal_dist < 0.4:
			has_click_target = false
			velocity.x = 0
			velocity.z = 0
			_stuck_timer = 0.0
			_assist_waypoints.clear()
		elif to.length() > 0.05:
			var wish: Vector3 = to.normalized()
			# Soft path assist: if recently stuck on a prop, bias around it
			if (not using_nav) and _stuck_timer > 0.25:
				var side := Vector3(-wish.z, 0, wish.x) * float(_assist_side)
				wish = (wish + side * 0.85).normalized()
			wish = _soft_avoid_entities(wish)
			velocity.x = move_toward(velocity.x, wish.x * SPEED, ACCEL * delta)
			velocity.z = move_toward(velocity.z, wish.z * SPEED, ACCEL * delta)
			mesh_root.rotation.y = atan2(wish.x, wish.z)
			moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, ACCEL * delta)
		velocity.z = move_toward(velocity.z, 0, ACCEL * delta)
		_stuck_timer = 0.0

	_was_manual = _manual_move
	velocity.y = 0
	_desired_vel = Vector3(velocity.x, 0.0, velocity.z)
	# Feed desired velocity into avoidance. WASD uses forced velocity so RVO does not fight keys.
	if _nav_agent and _nav_agent.avoidance_enabled:
		if _manual_move:
			_nav_agent.set_velocity_forced(_desired_vel)
		else:
			_nav_agent.set_velocity(_desired_vel)
	var pre_pos := global_position
	move_and_slide()
	# Slide-along + stuck detection for click-to-move against barrels/trees/fences
	if has_click_target:
		var moved_xz := Vector2(global_position.x - pre_pos.x, global_position.z - pre_pos.z).length()
		if get_slide_collision_count() > 0 and moved_xz < 0.02:
			_stuck_timer += delta
			var col := get_slide_collision(0)
			var n: Vector3 = col.get_normal()
			n.y = 0.0
			if n.length() > 0.01:
				n = n.normalized()
				var to2: Vector3 = target_pos - global_position
				to2.y = 0
				var slide_dir: Vector3 = to2.slide(n)
				if slide_dir.length() > 0.05:
					global_position += slide_dir.normalized() * SPEED * delta * 0.65
					mesh_root.rotation.y = atan2(slide_dir.x, slide_dir.z)
			if _stuck_timer > 0.55:
				_assist_side *= -1
				_stuck_timer = 0.15
				# Obstacle awareness: re-path mid-walk (nav + assist)
				_repath_around_blocker()
		else:
			_stuck_timer = maxf(0.0, _stuck_timer - delta * 1.5)
	# Village + wilds clamp (incl. Mill Bridge SW) — skip guild-hall interiors (x >= 100)
	if global_position.x < 90.0:
		global_position.x = clampf(global_position.x, -54.0, 52.0)
		global_position.z = clampf(global_position.z, -62.0, 52.0)
	global_position.y = 0
	GameState.position_xz = Vector2(global_position.x, global_position.z)

	var is_moving := moving or Vector2(velocity.x, velocity.z).length() > 0.4
	_animate_walk(is_moving and not _attacking, delta)
	_animate_attack(delta)
	_tick_click_marker(delta)

	if GameState.combat_target and is_instance_valid(GameState.combat_target):
		var dist: float = global_position.distance_to(GameState.combat_target.global_position)
		if dist > float(EnemyDB.base_combat.get("escape_range", 9.5)):
			GameState.set_combat_target(null)
		elif dist > float(EnemyDB.base_combat.get("attack_range", 3.2)):
			_set_move_target(GameState.combat_target.global_position)
		else:
			# Face the foe while in range
			var to_e: Vector3 = GameState.combat_target.global_position - global_position
			mesh_root.rotation.y = atan2(to_e.x, to_e.z)




func _ensure_foot_dust() -> void:
	if HeadlessGuard.is_headless():
		return
	if _foot_dust != null and is_instance_valid(_foot_dust):
		return
	_foot_dust = CPUParticles3D.new()
	_foot_dust.name = "FootDust"
	_foot_dust.emitting = false
	_foot_dust.one_shot = true
	_foot_dust.explosiveness = 0.92
	# Wave 27: slightly chunkier wholesome footstep dust (still soft, not muddy)
	_foot_dust.amount = 7
	_foot_dust.lifetime = 0.38
	_foot_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_foot_dust.emission_sphere_radius = 0.12
	_foot_dust.direction = Vector3(0, 1, 0)
	_foot_dust.spread = 75.0
	_foot_dust.initial_velocity_min = 0.4
	_foot_dust.initial_velocity_max = 1.1
	_foot_dust.gravity = Vector3(0, -4.2, 0)
	_foot_dust.scale_amount_min = 0.85
	_foot_dust.scale_amount_max = 1.35
	var dm := BoxMesh.new()
	dm.size = Vector3(0.08, 0.045, 0.08)
	_foot_dust.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.albedo_color = Color(0.78, 0.66, 0.44, 0.52)
	_foot_dust.material_override = dmat
	_foot_dust.position = Vector3(0, 0.04, 0)
	add_child(_foot_dust)
	HeadlessGuard.guard_particles(_foot_dust)

func _puff_foot_dust() -> void:
	## Subtle ground puff on each footfall — soft RuneScape-adjacent dust.
	if HeadlessGuard.is_headless():
		return
	_ensure_foot_dust()
	if _foot_dust == null:
		return
	_foot_dust.restart()
	_foot_dust.emitting = true

func _ensure_click_marker() -> void:
	if _click_marker != null and is_instance_valid(_click_marker):
		return
	_click_marker = MeshInstance3D.new()
	_click_marker.name = "ClickMarker"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.55
	cyl.height = 0.05
	_click_marker.mesh = cyl
	_click_marker_mat = StandardMaterial3D.new()
	_click_marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_click_marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_click_marker_mat.albedo_color = Color(0.95, 0.82, 0.15, 0.8)
	_click_marker.material_override = _click_marker_mat
	_click_marker.visible = false
	# World-space ring (sibling under world root when possible)
	var host: Node = get_parent() if get_parent() else self
	host.add_child(_click_marker)
	HeadlessGuard.guard_mesh(_click_marker)

func _show_click_marker(pos: Vector3) -> void:
	if HeadlessGuard.is_headless():
		return
	_ensure_click_marker()
	if _click_marker == null:
		return
	_click_marker.global_position = Vector3(pos.x, 0.05, pos.z)
	_click_marker.scale = Vector3(0.35, 1.0, 0.35)
	if _click_marker_mat:
		_click_marker_mat.albedo_color = Color(0.95, 0.82, 0.15, 0.85)
	_click_marker.visible = true
	_click_marker_t = 0.0

func _tick_click_marker(delta: float) -> void:
	if _click_marker_t < 0.0 or _click_marker == null:
		return
	_click_marker_t += delta
	var u: float = clampf(_click_marker_t / 0.7, 0.0, 1.0)
	var s: float = lerpf(0.4, 1.2, 1.0 - pow(1.0 - u, 2.0))
	_click_marker.scale = Vector3(s, 1.0, s)
	if _click_marker_mat:
		var c: Color = _click_marker_mat.albedo_color
		c.a = lerpf(0.85, 0.0, u)
		_click_marker_mat.albedo_color = c
	if u >= 1.0:
		_click_marker.visible = false
		_click_marker_t = -1.0

func _soft_avoid_entities(wish: Vector3) -> Vector3:
	## Light sidestep around mentors / foes so click-move feels RuneScape-aware.
	if wish.length() < 0.01:
		return wish
	var push := Vector3.ZERO
	for n in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(n):
			continue
		var d: float = global_position.distance_to(n.global_position)
		if d < 1.55 and d > 0.05:
			var away: Vector3 = global_position - n.global_position
			away.y = 0.0
			if away.length() > 0.01:
				push += away.normalized() * ((1.55 - d) / 1.55) * 1.15
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.has_method("is_alive") and not e.is_alive():
			continue
		var d2: float = global_position.distance_to(e.global_position)
		if d2 < 1.25 and d2 > 0.05:
			var away2: Vector3 = global_position - e.global_position
			away2.y = 0.0
			if away2.length() > 0.01:
				push += away2.normalized() * ((1.25 - d2) / 1.25) * 0.55
	if push.length() > 0.01:
		wish = (wish + push * 1.05).normalized()
	return wish

func _animate_walk(moving: bool, delta: float) -> void:
	var bob: Node3D = parts.get("bob")
	var l_arm: Node3D = parts.get("l_arm")
	var r_arm: Node3D = parts.get("r_arm")
	var l_leg: Node3D = parts.get("l_leg")
	var r_leg: Node3D = parts.get("r_leg")
	var cape: MeshInstance3D = parts.get("cape")
	var weapon: Node3D = parts.get("weapon")
	if bob == null:
		return
	var armed: bool = weapon != null and weapon.visible
	if moving:
		_walk_phase += delta * 10.0
		# Chunky RS walk: bigger arm/leg arcs; armed right arm keeps a ready cant so the held weapon reads clearly.
		var swing := sin(_walk_phase) * (0.62 if armed else 0.55)
		var swing2 := cos(_walk_phase) * 0.18
		if l_arm:
			l_arm.rotation.x = swing
			l_arm.rotation.z = deg_to_rad(-8) + swing2 * 0.22
		if r_arm:
			var ready := -0.22 if armed else 0.0
			r_arm.rotation.x = ready - swing * (0.72 if armed else 1.0)
			r_arm.rotation.z = deg_to_rad(10 if armed else 8) - swing2 * 0.22
		if l_leg:
			l_leg.rotation.x = -swing * 0.92
		if r_leg:
			r_leg.rotation.x = swing * 0.92
		bob.position.y = abs(sin(_walk_phase * 2.0)) * 0.06
		bob.rotation.z = sin(_walk_phase) * 0.03
		# Soft cape sway + weapon tip bob so equipped gear is obvious while walking.
		if cape and cape.visible:
			cape.rotation.y = sin(_walk_phase) * 0.12
			cape.rotation.x = deg_to_rad(-4) + cos(_walk_phase) * 0.05
		if armed and not _attacking:
			weapon.rotation_degrees.x = float(weapon.get_meta("rest_rx", weapon.rotation_degrees.x)) + sin(_walk_phase) * 6.0
			weapon.rotation_degrees.z = float(weapon.get_meta("rest_rz", weapon.rotation_degrees.z)) + cos(_walk_phase) * 4.0
		# Footstep on phase crossings
		var foot_gate := sin(_walk_phase)
		if _last_foot_phase <= 0.0 and foot_gate > 0.0:
			AudioBus.play_footstep()
			_puff_foot_dust()
		_last_foot_phase = foot_gate
	else:
		_walk_phase = move_toward(_walk_phase, 0.0, delta * 6.0)
		if not _attacking:
			if l_arm:
				l_arm.rotation.x = move_toward(l_arm.rotation.x, 0.0, delta * 6.0)
				l_arm.rotation.z = move_toward(l_arm.rotation.z, deg_to_rad(-6), delta * 6.0)
			if r_arm:
				var idle_x := -0.18 if armed else 0.0
				r_arm.rotation.x = move_toward(r_arm.rotation.x, idle_x, delta * 6.0)
				r_arm.rotation.z = move_toward(r_arm.rotation.z, deg_to_rad(8 if armed else 6), delta * 6.0)
			if cape and cape.visible:
				cape.rotation.y = move_toward(cape.rotation.y, 0.0, delta * 4.0)
				cape.rotation.x = move_toward(cape.rotation.x, deg_to_rad(-4), delta * 4.0)
			if armed:
				var rx := float(weapon.get_meta("rest_rx", weapon.rotation_degrees.x))
				var rz := float(weapon.get_meta("rest_rz", weapon.rotation_degrees.z))
				weapon.rotation_degrees.x = move_toward(weapon.rotation_degrees.x, rx, delta * 40.0)
				weapon.rotation_degrees.z = move_toward(weapon.rotation_degrees.z, rz, delta * 40.0)
		if l_leg:
			l_leg.rotation.x = move_toward(l_leg.rotation.x, 0.0, delta * 6.0)
		if r_leg:
			r_leg.rotation.x = move_toward(r_leg.rotation.x, 0.0, delta * 6.0)
		bob.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.015
		bob.rotation.z = move_toward(bob.rotation.z, 0.0, delta * 4.0)

func _animate_attack(delta: float) -> void:
	if not _attacking:
		return
	_attack_t += delta
	var bob: Node3D = parts.get("bob")
	var l_arm: Node3D = parts.get("l_arm")
	var r_arm: Node3D = parts.get("r_arm")
	var weapon: Node3D = parts.get("weapon")
	# Wind-up → strike → recover (~0.50s) with wrist flick + torso lean (Wave 22)
	var t := _attack_t
	var rest_rx := 8.0
	var rest_rz := -12.0
	if weapon:
		rest_rx = float(weapon.get_meta("rest_rx", weapon.rotation_degrees.x))
		rest_rz = float(weapon.get_meta("rest_rz", weapon.rotation_degrees.z))
	if r_arm:
		if t < 0.12:
			var u := t / 0.12
			r_arm.rotation.x = lerp(-0.15, -1.35, u)
			r_arm.rotation.z = lerp(deg_to_rad(8), deg_to_rad(32), u)
			if weapon:
				weapon.rotation_degrees.x = lerp(rest_rx, rest_rx - 28.0, u)
				weapon.rotation_degrees.z = lerp(rest_rz, rest_rz - 18.0, u)
			if l_arm:
				l_arm.rotation.x = lerp(0.0, 0.35, u)
			if bob:
				bob.rotation.x = lerp(0.0, -0.08, u)
		elif t < 0.30:
			var u := (t - 0.12) / 0.18
			r_arm.rotation.x = lerp(-1.35, 1.05, u)
			r_arm.rotation.z = lerp(deg_to_rad(32), deg_to_rad(-18), u)
			if weapon:
				weapon.rotation_degrees.x = lerp(rest_rx - 28.0, rest_rx + 42.0, u)
				weapon.rotation_degrees.z = lerp(rest_rz - 18.0, rest_rz + 22.0, u)
			if l_arm:
				l_arm.rotation.x = lerp(0.35, -0.55, u)
			if bob:
				bob.rotation.x = lerp(-0.08, 0.12, u)
		else:
			var u := clampf((t - 0.30) / 0.22, 0.0, 1.0)
			r_arm.rotation.x = lerp(1.05, -0.15, u)
			r_arm.rotation.z = lerp(deg_to_rad(-18), deg_to_rad(8), u)
			if weapon:
				weapon.rotation_degrees.x = lerp(rest_rx + 42.0, rest_rx, u)
				weapon.rotation_degrees.z = lerp(rest_rz + 22.0, rest_rz, u)
			if l_arm:
				l_arm.rotation.x = lerp(-0.55, 0.0, u)
			if bob:
				bob.rotation.x = lerp(0.12, 0.0, u)
	if t >= 0.52:
		_attacking = false
		_attack_t = 0.0
		if bob:
			bob.rotation.x = 0.0
		# Rest weapon — re-apply mesh style pose
		if weapon and weapon.visible:
			var wid = GameState.equipped.get("weapon")
			if wid != null:
				HumanoidBuilder.style_weapon(parts, ItemDB.get_item(str(wid)))

func set_ui_blocking(v: bool) -> void:
	ui_blocking = v
