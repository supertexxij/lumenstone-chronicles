extends Control

signal new_game_pressed
signal continue_pressed

@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var new_btn: Button = $Panel/VBox/NewBtn
@onready var subtitle: Label = $Panel/VBox/Subtitle

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	new_btn.pressed.connect(func(): new_game_pressed.emit())
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	subtitle.text = "Christian · Creationist · Grade 3 Homeschool RPG"

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and is_node_ready():
		continue_btn.disabled = not GameState.has_save()
