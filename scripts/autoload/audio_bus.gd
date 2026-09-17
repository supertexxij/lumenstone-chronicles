extends Node
## Lightweight procedural SFX + soft ambient loop. Respects GameState.muted.

signal mute_changed(muted: bool)

var _players: Dictionary = {}  # kind -> AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _music: AudioStreamPlayer
var _streams: Dictionary = {}
var _foot_cooldown: float = 0.0
var _ready_ok: bool = false

func _ready() -> void:
	_build_streams()
	for kind in ["ui", "hit", "miss", "foot", "quest", "swing"]:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%s" % kind
		p.bus = "Master"
		p.volume_db = -8.0
		add_child(p)
		_players[kind] = p
	_ambient = AudioStreamPlayer.new()
	_ambient.name = "Ambient"
	_ambient.bus = "Master"
	_ambient.volume_db = -24.0
	_ambient.stream = _streams.get("ambient")
	add_child(_ambient)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.bus = "Master"
	_music.volume_db = -18.0
	_music.stream = _streams.get("music")
	add_child(_music)
	_ready_ok = true
	_apply_mute()
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)

func _process(delta: float) -> void:
	if _foot_cooldown > 0.0:
		_foot_cooldown -= delta

func _on_state() -> void:
	_apply_mute()

func set_muted(v: bool) -> void:
	GameState.muted = v
	GameState.save_game()
	_apply_mute()
	mute_changed.emit(v)
	GameState.state_changed.emit()

func toggle_mute() -> void:
	set_muted(not GameState.muted)

func is_muted() -> bool:
	return GameState.muted

func _apply_mute() -> void:
	if not _ready_ok:
		return
	var muted: bool = GameState.muted
	AudioServer.set_bus_mute(0, muted)
	if muted:
		if _ambient and _ambient.playing:
			_ambient.stop()
		if _music and _music.playing:
			_music.stop()
	else:
		if GameState.in_world:
			if _ambient and not _ambient.playing and _ambient.stream:
				_ambient.play()
			if _music and not _music.playing and _music.stream:
				_music.play()

func start_ambient() -> void:
	_apply_mute()
	if not GameState.muted:
		if _ambient and _ambient.stream and not _ambient.playing:
			_ambient.play()
		if _music and _music.stream and not _music.playing:
			_music.play()

func stop_ambient() -> void:
	if _ambient and _ambient.playing:
		_ambient.stop()
	if _music and _music.playing:
		_music.stop()

func play_ui() -> void:
	_play("ui", -10.0)

func play_hit() -> void:
	_play("hit", -6.0)

func play_miss() -> void:
	_play("miss", -12.0)

func play_swing() -> void:
	_play("swing", -10.0)

func play_quest_complete() -> void:
	_play("quest", -4.0)

func play_footstep() -> void:
	if _foot_cooldown > 0.0:
		return
	_foot_cooldown = 0.32
	_play("foot", -16.0)

func _play(kind: String, vol_db: float) -> void:
	if GameState.muted:
		return
	var p: AudioStreamPlayer = _players.get(kind)
	if p == null:
		return
	p.stream = _streams.get(kind)
	p.volume_db = vol_db
	p.pitch_scale = randf_range(0.94, 1.06)
	p.play()

func _build_streams() -> void:
	_streams["ui"] = _tone_blip(880.0, 0.06, 0.25)
	_streams["hit"] = _noise_thump(0.09, 0.35)
	_streams["miss"] = _tone_blip(220.0, 0.05, 0.15)
	_streams["foot"] = _noise_thump(0.04, 0.18)
	_streams["swing"] = _whoosh(0.12, 0.22)
	_streams["quest"] = _arpeggio([523.25, 659.25, 783.99], 0.12, 0.28)
	_streams["ambient"] = _soft_drone(8.0, 0.07)
	_streams["music"] = _village_tune(12.0, 0.11)

func _make_wav(samples: PackedFloat32Array, mix_rate: int = 22050) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var s: float = clampf(samples[i], -1.0, 1.0)
		var v: int = int(s * 32767.0)
		bytes.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _tone_blip(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / float(rate)
		var env := 1.0 - t / dur
		samples[i] = sin(TAU * freq * t) * amp * env * env
	return _make_wav(samples, rate)

func _noise_thump(dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-t * 28.0)
		phase += 90.0 * TAU / float(rate) * (1.0 - t / dur)
		var tone := sin(phase) * 0.6
		var noise := (randf() * 2.0 - 1.0) * 0.4
		samples[i] = (tone + noise) * amp * env
	return _make_wav(samples, rate)

func _whoosh(dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / float(rate)
		var env := sin(PI * t / dur)
		var noise := (randf() * 2.0 - 1.0)
		# Soft band-limit feel via averaging
		samples[i] = noise * amp * env * 0.55
	return _make_wav(samples, rate)

func _arpeggio(freqs: Array, note_dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var total := note_dur * float(freqs.size())
	var n := int(total * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / float(rate)
		var idx := mini(freqs.size() - 1, int(t / note_dur))
		var local_t := t - float(idx) * note_dur
		var env := 1.0 - local_t / note_dur
		samples[i] = sin(TAU * float(freqs[idx]) * local_t) * amp * env * env
	return _make_wav(samples, rate)

func _soft_drone(dur: float, amp: float) -> AudioStreamWAV:
	## Short loopable pad — gentle major fifth drone (no melodies / no copyrighted tunes).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / float(rate)
		var a := sin(TAU * 110.0 * t) * 0.45
		var b := sin(TAU * 164.81 * t) * 0.28
		var c := sin(TAU * 220.0 * t) * 0.18
		var breathe := 0.65 + 0.35 * sin(TAU * 0.15 * t)
		samples[i] = (a + b + c) * amp * breathe
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _village_tune(dur: float, amp: float) -> AudioStreamWAV:
	## Short original loop — soft major-pentatonic plucks + pad. Not based on any copyrighted melody.
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	# C major pentatonic-ish (Hz): C4 D4 E4 G4 A4 C5
	var scale := [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]
	var pattern := [0, 2, 4, 2, 3, 1, 0, 4, 3, 2, 4, 5, 4, 2, 0, 1]
	var note_len := dur / float(pattern.size())
	for i in n:
		var t := float(i) / float(rate)
		var idx := mini(pattern.size() - 1, int(t / note_len))
		var local_t := t - float(idx) * note_len
		var freq: float = float(scale[pattern[idx]])
		var env := exp(-local_t * 3.2) * (1.0 - local_t / note_len * 0.15)
		var pluck := sin(TAU * freq * local_t) * 0.55
		pluck += sin(TAU * freq * 2.0 * local_t) * 0.12 * env
		# Soft bed
		var bed := sin(TAU * 130.81 * t) * 0.12 + sin(TAU * 196.00 * t) * 0.08
		var breathe := 0.75 + 0.25 * sin(TAU * 0.12 * t)
		samples[i] = (pluck * env + bed) * amp * breathe
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream
