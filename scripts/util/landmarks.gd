extends Object
class_name LandmarkCatalog
## Shared landmark names, short labels, and travel positions.
## HUD / Travel / world all read this so the three copies cannot drift.

const SHORT_NAMES := {
	"Fountain": "Fountain",
	"Village Fountain": "Fountain",
	"Lantern Glade": "Glade",
	"Pine Ridge": "Ridge",
	"Prayer Garden": "Garden",
	"Lookout Rock": "Lookout",
	"Mill Bridge": "Mill",
	"Cedar Hollow": "Hollow",
	"Willow Bend": "Willow",
	"Reed Pool": "Reed",
	"Quiet Cross": "Cross",
	"Stone Arch": "Arch",
	"Amber Knoll": "Knoll",
	"Birch Rest": "Birch",
	"Fern Dell": "Fern",
	"Heather Heath": "Heath",
	"Thistle Rise": "Thistle",
	"Maple Copse": "Maple",
	"Lantern Glade center": "Glade",
	"Pine Ridge stand": "Ridge",
	"Builder's Hall (door)": "Builder",
	"Scribe's Hall (door)": "Scribe",
	"Creation Hall (door)": "Creation",
	"Chronicle Hall (door)": "Chronicle",
	"Worship Hall (door)": "Worship",
}

const POSITIONS := {
	"Village Fountain": Vector3(0, 0, 12),
	"Fountain": Vector3(0, 0, 12),
	"Lantern Glade": Vector3(0.5, 0, -46),
	"Pine Ridge": Vector3(-20, 0, -50),
	"Prayer Garden": Vector3(30, 0, 18),
	"Lookout Rock": Vector3(40, 0, 34),
	"Mill Bridge": Vector3(-36, 0, 30),
	"Cedar Hollow": Vector3(38, 0, -36),
	"Willow Bend": Vector3(-38, 0, -34),
	"Reed Pool": Vector3(-20, 0, 48),
	"Quiet Cross": Vector3(48, 0, 8),
	"Stone Arch": Vector3(-48, 0, 8),
	"Amber Knoll": Vector3(48, 0, -22),
	"Birch Rest": Vector3(-42, 0, -20),
	"Fern Dell": Vector3(22, 0, 48),
	"Heather Heath": Vector3(-48, 0, 42),
	"Thistle Rise": Vector3(48, 0, 42),
	"Maple Copse": Vector3(-48, 0, -48),
	"Lantern Glade center": Vector3(0.5, 0, -48),
	"Pine Ridge stand": Vector3(-24, 0, -54),
	"Builder's Hall (door)": Vector3(22, 0, 2.5),
	"Scribe's Hall (door)": Vector3(-22, 0, 2.5),
	"Creation Hall (door)": Vector3(0, 0, -18),
	"Chronicle Hall (door)": Vector3(0, 0, 28),
	"Worship Hall (door)": Vector3(0, 0, -2),
}

const DISPLAY_BY_ID := {
	"glade": "Lantern Glade",
	"ridge": "Pine Ridge",
	"garden": "Prayer Garden",
	"lookout": "Lookout Rock",
	"mill": "Mill Bridge",
	"hollow": "Cedar Hollow",
	"willow": "Willow Bend",
	"reed": "Reed Pool",
	"cross": "Quiet Cross",
	"arch": "Stone Arch",
	"knoll": "Amber Knoll",
	"birch": "Birch Rest",
	"fern": "Fern Dell",
	"heather": "Heather Heath",
	"thistle": "Thistle Rise",
	"maple": "Maple Copse",
}

static func short_name(full: String) -> String:
	var n := full.strip_edges()
	if n in SHORT_NAMES:
		return str(SHORT_NAMES[n])
	var parts := n.split(" ")
	if parts.size() >= 2:
		return str(parts[-1]).replace("(door)", "").strip_edges()
	return n

static func position_for(label: String) -> Vector3:
	var lab := label.strip_edges()
	if lab in POSITIONS:
		return POSITIONS[lab]
	return Vector3(1.0e30, 1.0e30, 1.0e30)

static func display_name(lid: String) -> String:
	return str(DISPLAY_BY_ID.get(lid, lid.capitalize()))
