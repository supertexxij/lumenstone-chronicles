extends Node
## Root flow: title → customize → world (+ overlays)

@onready var title_screen: Control = $UI/TitleScreen
@onready var customize_screen: Control = $UI/CustomizeScreen
@onready var world_host: Node3D = $WorldHost
@onready var hud: Control = $UI/HUD
@onready var inventory_panel: Control = $UI/InventoryPanel
@onready var quest_panel: Control = $UI/QuestPanel
@onready var npc_panel: Control = $UI/NpcPanel
@onready var parent_panel: Control = $UI/ParentPanel
@onready var journal_panel: Control = $UI/JournalPanel
@onready var travel_panel: Control = $UI/TravelPanel
@onready var toast_label: Label = $UI/Toast

var world_scene: Node3D = null
var toast_timer: float = 0.0
var _pending_new_slot: int = 0
var _travel_dests: Array = []

func _ready() -> void:
	GameState.toast.connect(_on_toast)
	GameState.ui_open_requested.connect(_on_ui_open)
	title_screen.visible = true
	customize_screen.visible = false
	hud.visible = false
	inventory_panel.visible = false
	quest_panel.visible = false
	npc_panel.visible = false
	parent_panel.visible = false
	journal_panel.visible = false
	if travel_panel:
		travel_panel.visible = false
	title_screen.new_game_pressed.connect(_on_new_game)
	title_screen.continue_pressed.connect(_on_continue)
	if title_screen.has_signal("clear_slot_pressed"):
		title_screen.clear_slot_pressed.connect(_on_clear_slot)
	customize_screen.confirmed.connect(_on_customize_done)
	hud.inventory_pressed.connect(func(): _toggle(inventory_panel))
	hud.wardrobe_pressed.connect(func():
		customize_screen.open_wardrobe()
		customize_screen.visible = true
		_set_player_ui_block(true)
	)
	hud.journal_pressed.connect(_open_journal)
	hud.mute_pressed.connect(func(): AudioBus.toggle_mute())
	hud.weather_pressed.connect(_cycle_weather)
	if hud.has_signal("travel_pressed"):
		hud.travel_pressed.connect(_open_travel)
	hud.parent_pressed.connect(func():
		parent_panel.open()
		parent_panel.visible = true
		_set_player_ui_block(true)
	)
	inventory_panel.closed.connect(func(): inventory_panel.visible = false; _set_player_ui_block(false))
	quest_panel.closed.connect(func(): quest_panel.visible = false; _set_player_ui_block(false))
	npc_panel.closed.connect(func(): npc_panel.visible = false; _set_player_ui_block(false))
	npc_panel.quest_chosen.connect(_on_quest_chosen)
	parent_panel.closed.connect(func(): parent_panel.visible = false; _set_player_ui_block(false))
	journal_panel.closed.connect(func(): journal_panel.visible = false; _set_player_ui_block(false))
	customize_screen.cancelled.connect(func():
		customize_screen.visible = false
		_set_player_ui_block(false)
		if not GameState.in_world:
			title_screen.visible = true
			title_screen.refresh_slots()
	)
	_setup_travel_panel()

func _setup_travel_panel() -> void:
	if travel_panel == null:
		return
	var go: Button = travel_panel.get_node_or_null("Panel/VBox/GoBtn")
	var close: Button = travel_panel.get_node_or_null("Panel/VBox/CloseBtn")
	var list: ItemList = travel_panel.get_node_or_null("Panel/VBox/DestList")
	if go:
		go.pressed.connect(_travel_go_selected)
	if close:
		close.pressed.connect(func():
			travel_panel.visible = false
			_set_player_ui_block(false)
		)
	if list:
		list.item_activated.connect(func(_i): _travel_go_selected())

func _process(delta: float) -> void:
	if toast_timer > 0:
		toast_timer -= delta
		if toast_timer <= 0:
			toast_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.in_world:
		return
	if event.is_action_pressed("inventory"):
		_toggle(inventory_panel)
	if event.is_action_pressed("wardrobe"):
		customize_screen.open_wardrobe()
		customize_screen.visible = true
		_set_player_ui_block(true)
	if event.is_action_pressed("journal"):
		_open_journal()
	if event.is_action_pressed("mute_toggle"):
		AudioBus.toggle_mute()
	if event.is_action_pressed("weather_cycle"):
		_cycle_weather()
	if event.is_action_pressed("interact"):
		_try_nearby_npc()
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
		match code:
			KEY_T:
				_open_travel()
			KEY_H:
				_goto_landmark(Vector3(0, 0, 12), "Village Fountain")
			KEY_N:
				_goto_landmark(Vector3(0.5, 0, -30), "Lantern Glade path")
			KEY_B:
				_goto_landmark(Vector3(-12, 0, -45.5), "Pine Ridge ford")
			KEY_G:
				_goto_landmark(Vector3(30, 0, 18), "Prayer Garden")
			KEY_1:
				_goto_landmark(Vector3(22, 0, 2.5), "Builder's Hall")
			KEY_2:
				_goto_landmark(Vector3(-22, 0, 2.5), "Scribe's Hall")
			KEY_3:
				_goto_landmark(Vector3(0, 0, -18), "Creation Hall")
			KEY_4:
				_goto_landmark(Vector3(0, 0, 28), "Chronicle Hall")
			KEY_5:
				_goto_landmark(Vector3(0, 0, -2), "Worship Hall")

func _travel_destinations() -> Array:
	return [
		{"label": "Village Fountain", "pos": Vector3(0, 0, 12), "key": "H"},
		{"label": "Lantern Glade path", "pos": Vector3(0.5, 0, -30), "key": "N"},
		{"label": "Pine Ridge ford", "pos": Vector3(-12, 0, -45.5), "key": "B"},
		{"label": "Prayer Garden", "pos": Vector3(30, 0, 18), "key": "G"},
		{"label": "Builder's Hall (door)", "pos": Vector3(22, 0, 2.5), "key": "1"},
		{"label": "Scribe's Hall (door)", "pos": Vector3(-22, 0, 2.5), "key": "2"},
		{"label": "Creation Hall (door)", "pos": Vector3(0, 0, -18), "key": "3"},
		{"label": "Chronicle Hall (door)", "pos": Vector3(0, 0, 28), "key": "4"},
		{"label": "Worship Hall (door)", "pos": Vector3(0, 0, -2), "key": "5"},
		{"label": "Lantern Glade center", "pos": Vector3(0.5, 0, -48), "key": ""},
		{"label": "Pine Ridge stand", "pos": Vector3(-24, 0, -54), "key": ""},
	]

func _open_travel() -> void:
	if travel_panel == null:
		return
	if world_scene and world_scene.player and world_scene.player.get("ui_blocking"):
		# Allow opening travel only if no other panel owns the block — if travel already open, ignore
		pass
	_travel_dests = _travel_destinations()
	var list: ItemList = travel_panel.get_node_or_null("Panel/VBox/DestList")
	if list:
		list.clear()
		for d in _travel_dests:
			var key_s: String = (" [%s]" % d["key"]) if str(d.get("key", "")) != "" else ""
			list.add_item("%s%s" % [d["label"], key_s])
		if list.item_count > 0:
			list.select(0)
	travel_panel.visible = true
	_set_player_ui_block(true)
	AudioBus.play_ui()

func _travel_go_selected() -> void:
	var list: ItemList = travel_panel.get_node_or_null("Panel/VBox/DestList")
	if list == null or not list.is_anything_selected():
		return
	var idx: int = list.get_selected_items()[0]
	if idx < 0 or idx >= _travel_dests.size():
		return
	var d: Dictionary = _travel_dests[idx]
	travel_panel.visible = false
	_set_player_ui_block(false)
	_goto_landmark(d["pos"], d["label"])

func _goto_landmark(pos: Vector3, label: String) -> void:
	if not world_scene or not world_scene.player:
		return
	if world_scene.player.get("ui_blocking"):
		return
	# Soft travel only outdoors (not from hall interiors)
	if world_scene.player.global_position.x >= 90.0:
		GameState.toast.emit("Exit the hall first, then travel to %s." % label)
		return
	world_scene.player.global_position = pos
	if "has_click_target" in world_scene.player:
		world_scene.player.has_click_target = false
	GameState.position_xz = Vector2(pos.x, pos.z)
	GameState.toast.emit("Traveled to %s." % label)
	AudioBus.play_ui()

func _open_journal() -> void:
	journal_panel.open()
	journal_panel.visible = true
	_set_player_ui_block(true)

func _cycle_weather() -> void:
	if world_scene and world_scene.has_method("toggle_weather_auto"):
		world_scene.toggle_weather_auto()

func _try_nearby_npc() -> void:
	if not world_scene:
		return
	var player = world_scene.player
	if not player:
		return
	if player.has_meta("nearby_guild_desk") and world_scene.has_method("_open_guild_npc"):
		world_scene._open_guild_npc(str(player.get_meta("nearby_guild_desk")))
		return
	var best = null
	var best_d := 4.0
	for npc in get_tree().get_nodes_in_group("npcs"):
		var d: float = player.global_position.distance_to(npc.global_position)
		if d < best_d:
			best_d = d
			best = npc
	if best:
		_open_npc(best)

func _toggle(panel: Control) -> void:
	panel.visible = not panel.visible
	_set_player_ui_block(panel.visible)
	if panel == inventory_panel and panel.visible:
		inventory_panel.refresh()

func _set_player_ui_block(v: bool) -> void:
	if world_scene and world_scene.player:
		world_scene.player.set_ui_blocking(v)

func _on_new_game(slot: int = 0) -> void:
	AudioBus.play_ui()
	_pending_new_slot = clampi(slot, 0, GameState.SLOT_COUNT - 1)
	if GameState.has_save(_pending_new_slot):
		# Soft confirm via toast — overwrite on Begin
		GameState.toast.emit("Slot %d has a save — Begin will start fresh there." % (_pending_new_slot + 1))
	title_screen.visible = false
	customize_screen.open_new()
	customize_screen.visible = true

func _on_continue(slot: int = 0) -> void:
	AudioBus.play_ui()
	if GameState.load_game(slot):
		title_screen.visible = false
		_enter_world()
	else:
		_on_toast("No save in that slot.")
		title_screen.refresh_slots()

func _on_clear_slot(slot: int) -> void:
	GameState.clear_slot(slot)
	title_screen.refresh_slots()
	_on_toast("Cleared save slot %d." % (slot + 1))

func _on_customize_done(p_name: String, appearance: Dictionary) -> void:
	customize_screen.visible = false
	if not GameState.in_world:
		GameState.new_game(p_name, appearance, _pending_new_slot)
		_enter_world()
	else:
		GameState.child_name = p_name if p_name != "" else GameState.child_name
		GameState.appearance = appearance
		GameState.save_game()
		GameState.state_changed.emit()
		_set_player_ui_block(false)

func _enter_world() -> void:
	if world_scene:
		world_scene.queue_free()
	world_scene = load("res://scenes/world/world.tscn").instantiate()
	world_host.add_child(world_scene)
	world_scene.npc_talk.connect(_open_npc)
	hud.visible = true
	hud.set_world(world_scene)
	hud.refresh()
	if not GameState.state_changed.is_connected(hud.refresh):
		GameState.state_changed.connect(hud.refresh)
	if not GameState.hp_changed.is_connected(hud.set_hp):
		GameState.hp_changed.connect(hud.set_hp)
	AudioBus.start_ambient()

func _open_npc(npc: Node) -> void:
	npc_panel.open(npc)
	npc_panel.visible = true
	_set_player_ui_block(true)

func _on_quest_chosen(quest_id: String) -> void:
	AudioBus.play_ui()
	npc_panel.visible = false
	quest_panel.open(quest_id)
	quest_panel.visible = true
	_set_player_ui_block(true)

func _on_ui_open(panel: String) -> void:
	if panel.begins_with("npc:"):
		var id: String = panel.substr(4)
		for npc in get_tree().get_nodes_in_group("npcs"):
			if npc.npc_id == id:
				_open_npc(npc)
				return

func _on_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_timer = 5.0 if msg.length() > 60 else 3.5
