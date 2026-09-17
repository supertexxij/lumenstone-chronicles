extends CharacterBody3D
## Click-to-move + WASD player with elevated camera follow
## Humanoid mesh: head/torso/arms/legs + equip visuals + simple walk bob

signal clicked_ground(pos: Vector3)

const SPEED := 6.5
const ACCEL := 18.0

@onready var mesh_root: Node3D = $MeshRoot
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var parts: Dictionary = {}
var target_pos: Vector3 = Vector3.ZERO
var has_click_target: bool = false
var cam_yaw: float = 0.0
var ui_blocking: bool = false
var _walk_phase: float = 0.0

func _ready() -> void:
	add_to_group("player")
	parts = HumanoidBuilder.build(mesh_root)
	GameState.state_changed.connect(_on_state_changed)
	GameState.soft_defeated.connect(soft_respawn)
	_apply_appearance()
	global_position = Vector3(GameState.position_xz.x, 0, GameState.position_xz.y)
	target_pos = global_position

func _on_state_changed() -> void:
	_apply_appearance()
	if GameState.hp > 0 and GameState.combat_target == null:
		var fountain: Vector3 = Vector3(0, 0, 10)
		if global_position.distance_to(fountain) > 50:
			pass
		if GameState.hp == GameState.max_hp and GameState.position_xz == Vector2(0, 10) and global_position.distance_to(Vector3(0,0,10)) > 2.0 and GameState.combat_target == null:
			pass

func soft_respawn() -> void:
	global_position = Vector3(0, 0, 10)
	target_pos = global_position
	has_click_target = false
	velocity = Vector3.ZERO

func _apply_appearance() -> void:
	if parts.is_empty():
		return
	var skin: Color = Color(str(GameState.SKIN_HEX.get(GameState.appearance.get("skin", "medium"), "#c68642")))
	var hair: Color = Color(str(GameState.HAIR_HEX.get(GameState.appearance.get("hair", "brown"), "#5c4033")))
	var outfit: Color = Color(str(GameState.OUTFIT_HEX.get(GameState.appearance.get("outfit", "cream"), "#f4e4bc")))
	var cape_col: Color = Color(str(GameState.CAPE_HEX.get(GameState.appearance.get("cape_color", "crimson"), "#c1121f")))
	HumanoidBuilder.apply_human_colors(parts, skin, hair, outfit, cape_col)

	# Equipped cape color override
	var cape_id = GameState.equipped.get("cape")
	var cape_mesh: MeshInstance3D = parts.get("cape")
	if cape_id != null:
		var item: Dictionary = ItemDB.get_item(str(cape_id))
		if not item.is_empty() and item.get("color", "") != "":
			HumanoidBuilder.set_color(cape_mesh, Color(item["color"]))
		if cape_mesh:
			cape_mesh.visible = true
	elif cape_mesh:
		cape_mesh.visible = true  # appearance cape always shown

	# Weapon at side
	var weapon_root: Node3D = parts.get("weapon")
	var wid = GameState.equipped.get("weapon")
	if weapon_root:
		weapon_root.visible = wid != null
		if wid != null:
			var witem: Dictionary = ItemDB.get_item(str(wid))
			var wcol := Color(witem.get("color", "#a67c52"))
			HumanoidBuilder.set_color(parts.get("blade"), wcol)
			HumanoidBuilder.set_color(parts.get("hilt"), wcol.darkened(0.25))
			HumanoidBuilder.set_color(parts.get("pommel"), wcol.lightened(0.15))

	# Hat on head (hides hair volume slightly via hat visibility)
	var hat_root: Node3D = parts.get("hat")
	var hid = GameState.equipped.get("head")
	if hat_root:
		hat_root.visible = hid != null
		if hid != null:
			var hitem: Dictionary = ItemDB.get_item(str(hid))
			var hcol := Color(hitem.get("color", "#5c4033"))
			HumanoidBuilder.set_color(parts.get("hat_crown"), hcol)
			HumanoidBuilder.set_color(parts.get("hat_brim"), hcol.darkened(0.15))

	# Belt
	var belt_mesh: MeshInstance3D = parts.get("belt")
	var bid = GameState.equipped.get("belt")
	if belt_mesh:
		belt_mesh.visible = bid != null
		if bid != null:
			var bitem: Dictionary = ItemDB.get_item(str(bid))
			HumanoidBuilder.set_color(belt_mesh, Color(bitem.get("color", "#d4a017")))

func _unhandled_input(event: InputEvent) -> void:
	if ui_blocking:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		cam_yaw -= event.relative.x * 0.005

func _handle_click() -> void:
	var from: Vector3 = camera.project_ray_origin(get_viewport().get_mouse_position())
	var dir: Vector3 = camera.project_ray_normal(get_viewport().get_mouse_position())
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from + dir * 200.0)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		if abs(dir.y) > 0.01:
			var t := -from.y / dir.y
			if t > 0:
				var p := from + dir * t
				_set_move_target(p)
		return
	var collider = hit.collider
	if collider and collider.is_in_group("enemies"):
		GameState.set_combat_target(collider)
		_set_move_target(collider.global_position)
		return
	if collider and collider.is_in_group("npcs"):
		collider.request_talk()
		return
	_set_move_target(hit.position)

func _set_move_target(pos: Vector3) -> void:
	target_pos = Vector3(pos.x, 0, pos.z)
	has_click_target = true
	if GameState.combat_target and target_pos.distance_to(GameState.combat_target.global_position) > float(EnemyDB.base_combat.get("escape_range", 8)):
		GameState.set_combat_target(null)

func _physics_process(delta: float) -> void:
	if ui_blocking:
		velocity = Vector3.ZERO
		_animate_walk(false, delta)
		move_and_slide()
		return

	if Input.is_action_pressed("cam_left"):
		cam_yaw += 1.5 * delta
	if Input.is_action_pressed("cam_right"):
		cam_yaw -= 1.5 * delta
	camera_pivot.rotation.y = cam_yaw

	var input_dir: Vector2 = Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var moving := false
	if input_dir.length() > 0.1:
		has_click_target = false
		var forward: Vector3 = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
		var right: Vector3 = Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
		var wish: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized()
		velocity.x = move_toward(velocity.x, wish.x * SPEED, ACCEL * delta)
		velocity.z = move_toward(velocity.z, wish.z * SPEED, ACCEL * delta)
		mesh_root.rotation.y = atan2(wish.x, wish.z)
		moving = true
	elif has_click_target:
		var to: Vector3 = target_pos - global_position
		to.y = 0
		if to.length() < 0.35:
			has_click_target = false
			velocity.x = 0
			velocity.z = 0
		else:
			var wish: Vector3 = to.normalized()
			velocity.x = move_toward(velocity.x, wish.x * SPEED, ACCEL * delta)
			velocity.z = move_toward(velocity.z, wish.z * SPEED, ACCEL * delta)
			mesh_root.rotation.y = atan2(wish.x, wish.z)
			moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, ACCEL * delta)
		velocity.z = move_toward(velocity.z, 0, ACCEL * delta)

	velocity.y = 0
	move_and_slide()
	var b: float = 42.0
	global_position.x = clampf(global_position.x, -b, b)
	global_position.z = clampf(global_position.z, -b, b)
	global_position.y = 0
	GameState.position_xz = Vector2(global_position.x, global_position.z)

	_animate_walk(moving or Vector2(velocity.x, velocity.z).length() > 0.4, delta)

	if GameState.combat_target and is_instance_valid(GameState.combat_target):
		var dist: float = global_position.distance_to(GameState.combat_target.global_position)
		if dist > float(EnemyDB.base_combat.get("escape_range", 8)):
			GameState.set_combat_target(null)
		elif dist > float(EnemyDB.base_combat.get("attack_range", 3.2)):
			_set_move_target(GameState.combat_target.global_position)

func _animate_walk(moving: bool, delta: float) -> void:
	var bob: Node3D = parts.get("bob")
	var l_arm: Node3D = parts.get("l_arm")
	var r_arm: Node3D = parts.get("r_arm")
	var l_leg: Node3D = parts.get("l_leg")
	var r_leg: Node3D = parts.get("r_leg")
	if bob == null:
		return
	if moving:
		_walk_phase += delta * 9.0
		var swing := sin(_walk_phase) * 0.45
		if l_arm:
			l_arm.rotation.x = swing
		if r_arm:
			r_arm.rotation.x = -swing
		if l_leg:
			l_leg.rotation.x = -swing * 0.7
		if r_leg:
			r_leg.rotation.x = swing * 0.7
		bob.position.y = abs(sin(_walk_phase * 2.0)) * 0.04
	else:
		_walk_phase = move_toward(_walk_phase, 0.0, delta * 6.0)
		if l_arm:
			l_arm.rotation.x = move_toward(l_arm.rotation.x, 0.0, delta * 6.0)
		if r_arm:
			r_arm.rotation.x = move_toward(r_arm.rotation.x, 0.0, delta * 6.0)
		if l_leg:
			l_leg.rotation.x = move_toward(l_leg.rotation.x, 0.0, delta * 6.0)
		if r_leg:
			r_leg.rotation.x = move_toward(r_leg.rotation.x, 0.0, delta * 6.0)
		bob.position.y = move_toward(bob.position.y, 0.0, delta * 0.2)
		# Gentle idle breath
		bob.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.015

func set_ui_blocking(v: bool) -> void:
	ui_blocking = v
