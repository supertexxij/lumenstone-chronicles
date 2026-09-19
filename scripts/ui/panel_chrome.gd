class_name PanelChrome
extends Object
## Shared overlay chrome so Inventory / Journal / Travel / NPC / Parent / Title
## read as one family of panels (RuneScape-chunky parchment, wholesome).

const BG := Color(0.12, 0.11, 0.09, 0.97)
const BORDER := Color(0.84, 0.72, 0.40, 0.95)
const TITLE_COL := Color(0.99, 0.94, 0.78, 1.0)
const BODY_COL := Color(0.92, 0.88, 0.78, 1.0)
const MUTED_COL := Color(0.78, 0.74, 0.64, 1.0)
const BTN_BG := Color(0.22, 0.20, 0.16, 0.95)
const BTN_BORDER := Color(0.70, 0.62, 0.42, 0.9)
const BTN_PRIMARY_BG := Color(0.36, 0.28, 0.14, 0.98)
const BTN_PRIMARY_BORDER := Color(0.92, 0.78, 0.38, 0.98)
const CARD_BG := Color(0.16, 0.15, 0.12, 0.94)
const CARD_BORDER := Color(0.72, 0.64, 0.40, 0.85)


static func apply_panel(panel: PanelContainer, extra_pad: int = 14) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = extra_pad
	style.content_margin_right = extra_pad
	style.content_margin_top = extra_pad - 2
	style.content_margin_bottom = extra_pad - 2
	style.shadow_color = Color(0.04, 0.03, 0.02, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)


static func apply_card(panel: PanelContainer) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = CARD_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if panel:
		panel.add_theme_stylebox_override("panel", style)
	return style


static func style_title(lbl: Label, size: int = 22) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", TITLE_COL)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func style_body(lbl: Label, size: int = 14) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", BODY_COL)


static func style_muted(lbl: Label, size: int = 13) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", MUTED_COL)


static func button_style(primary: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BTN_PRIMARY_BG if primary else BTN_BG
	style.border_color = BTN_PRIMARY_BORDER if primary else BTN_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


static func style_button(btn: Button, primary: bool = false) -> void:
	if btn == null:
		return
	var style := button_style(primary)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = style.bg_color.darkened(0.08)
	btn.add_theme_stylebox_override("pressed", pressed)
	if primary:
		btn.add_theme_color_override("font_color", TITLE_COL)


static func pad_vbox(vbox: VBoxContainer, sep: int = 10) -> void:
	if vbox == null:
		return
	vbox.add_theme_constant_override("separation", sep)


static func apply_overlay(root: Control) -> void:
	## Style the first PanelContainer under a dimmed overlay Control.
	if root == null:
		return
	var panel: PanelContainer = root.get_node_or_null("Panel")
	if panel:
		apply_panel(panel)
	var vbox: VBoxContainer = root.get_node_or_null("Panel/VBox")
	if vbox == null:
		vbox = root.get_node_or_null("Panel/RootHBox/VBox")
	if vbox:
		pad_vbox(vbox, 10)
	var title: Label = root.get_node_or_null("Panel/VBox/Title")
	if title == null:
		title = root.get_node_or_null("Panel/RootHBox/VBox/Title")
	if title:
		style_title(title)
