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
@onready var toast_label: Label = $UI/Toast

var world_scene: Node3D = null
var toast_timer: float = 0.0

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
	title_screen.new_game_pressed.connect(_on_new_game)
	title_screen.continue_pressed.connect(_on_continue)
	customize_screen.confirmed.connect(_on_customize_done)
	hud.inventory_pressed.connect(func(): _toggle(inventory_panel))
	hud.wardrobe_pressed.connect(func():
		customize_screen.open_wardrobe()
		customize_screen.visible = true
		_set_player_ui_block(true)
	)
	hud.journal_pressed.connect(_open_journal)
	hud.mute_pressed.connect(func(): AudioBus.toggle_mute())
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
	)

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
	if event.is_action_pressed("interact"):
		_try_nearby_npc()

func _open_journal() -> void:
	journal_panel.open()
	journal_panel.visible = true
	_set_player_ui_block(true)

func _try_nearby_npc() -> void:
	if not world_scene:
		return
	var player = world_scene.player
	if not player:
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

func _on_new_game() -> void:
	AudioBus.play_ui()
	title_screen.visible = false
	customize_screen.open_new()
	customize_screen.visible = true

func _on_continue() -> void:
	AudioBus.play_ui()
	if GameState.load_game():
		title_screen.visible = false
		_enter_world()
	else:
		_on_toast("No save found.")

func _on_customize_done(p_name: String, appearance: Dictionary) -> void:
	customize_screen.visible = false
	if not GameState.in_world:
		GameState.new_game(p_name, appearance)
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
	toast_timer = 3.5
