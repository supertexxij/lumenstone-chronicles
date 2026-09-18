extends Node
## Lightweight procedural SFX + soft ambient loop. Respects GameState.muted.

signal mute_changed(muted: bool)

var _players: Dictionary = {}  # kind -> AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _music: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _drip: AudioStreamPlayer
var _rain_wanted: bool = false
var _indoor_drip_wanted: bool = false
var _day_birds: AudioStreamPlayer
var _night_hush: AudioStreamPlayer
var _dusk_owl: AudioStreamPlayer  # Wave 49: soft dusk owl hoot outdoors
var _campfire: AudioStreamPlayer
var _day_audio_wanted: bool = true
var _day_phase_cache: float = 0.25  # Wave 44: dawn bird swell
var _birds_base_db: float = -26.0
var _last_day_audio: int = -1  # -1 unset, 0 night, 1 day
var _campfire_wanted: bool = false  # Wave 33: plaza campfire crackle when near
var _ember_pop_cd: float = 0.0  # Wave 55: soft campfire ember pop cooldown
var _wind: AudioStreamPlayer
var _wind_wanted: bool = false  # Wave 34: soft outdoor wind whoosh
var _hall_reverb: AudioStreamPlayer
var _hall_reverb_wanted: bool = false  # Wave 37: soft indoor hall reverb cue
var _hall_chatter: AudioStreamPlayer
var _hall_chatter_wanted: bool = false  # Wave 42: soft guild-hall ambient chatter
var _leaf_rustle: AudioStreamPlayer
var _leaf_rustle_wanted: bool = false  # Wave 37: leaf rustle near trees
var _brook_murmur: AudioStreamPlayer
var _brook_murmur_wanted: bool = false  # Wave 38: soft brook murmur near water
var _wind_chime: AudioStreamPlayer
var _wind_chime_wanted: bool = false  # Wave 52: soft wind chime near halls
var _talk_duck: bool = false  # Wave 32: soft music duck while talking
var _music_base_db: float = -18.0
var _ambient_base_db: float = -24.0
var _streams: Dictionary = {}
var _foot_cooldown: float = 0.0
var _ready_ok: bool = false

func _ready() -> void:
	_build_streams()
	for kind in ["ui", "hit", "miss", "foot", "quest", "quest_near_miss", "swing", "door", "ember_pop", "ready_chime", "fountain_rest_chime"]:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%s" % kind
		p.bus = "Master"
		p.volume_db = -8.0
		add_child(p)
		_players[kind] = p
	_ambient = _make_loop_player("Ambient", -24.0, "ambient")
	_music = _make_loop_player("Music", -18.0, "music")
	_rain = _make_loop_player("Rain", -34.0, "rain")
	_rain.volume_db = -34.0  # Wave 33: softer rain mix
	_drip = _make_loop_player("IndoorDrip", -22.0, "drip")
	_day_birds = _make_loop_player("DayBirds", _birds_base_db, "day_birds")
	_night_hush = _make_loop_player("NightHush", -27.0, "night_hush")
	_dusk_owl = _make_loop_player("DuskOwlHoot", -29.0, "dusk_owl")
	_campfire = _make_loop_player("CampfireCrackle", -30.0, "campfire")
	_wind = _make_loop_player("WindWhoosh", -32.0, "wind")
	_hall_reverb = _make_loop_player("HallReverb", -30.0, "hall_reverb")
	_hall_chatter = _make_loop_player("HallChatter", -28.0, "hall_chatter")
	_leaf_rustle = _make_loop_player("LeafRustle", -31.0, "leaf_rustle")
	_brook_murmur = _make_loop_player("BrookMurmur", -26.5, "brook_murmur")  # Wave 73: soft brook murmur polish
	_wind_chime = _make_loop_player("HallWindChime", -31.0, "wind_chime")
	_ready_ok = true
	_apply_mute()
	if not GameState.state_changed.is_connected(_on_state):
		GameState.state_changed.connect(_on_state)


func _make_loop_player(p_name: String, vol_db: float, stream_key: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = p_name
	p.bus = "Master"
	p.volume_db = vol_db
	p.stream = _streams.get(stream_key)
	add_child(p)
	return p


func _stop_if_playing(p: AudioStreamPlayer) -> void:
	if p and p.playing:
		p.stop()

func _process(delta: float) -> void:
	if _foot_cooldown > 0.0:
		_foot_cooldown -= delta
	# Wave 55: occasional soft ember pop when near plaza campfire (respects mute)
	if _ember_pop_cd > 0.0:
		_ember_pop_cd -= delta
	elif _campfire_wanted and _ready_ok and (not GameState.muted) and GameState.in_world:
		if randf() < 0.018:  # soft sparse pops while near hearth
			play_ember_pop()
			_ember_pop_cd = randf_range(1.6, 3.8)

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

func _apply_mute() -> void:
	if not _ready_ok:
		return
	var muted: bool = GameState.muted
	AudioServer.set_bus_mute(0, muted)
	if muted:
		_stop_if_playing(_ambient)
		_stop_if_playing(_music)
		_stop_if_playing(_rain)
		_stop_if_playing(_drip)
		_stop_if_playing(_day_birds)
		_stop_if_playing(_night_hush)
		_stop_if_playing(_dusk_owl)
		_stop_if_playing(_campfire)
		_stop_if_playing(_wind)
		_stop_if_playing(_hall_reverb)
		_stop_if_playing(_hall_chatter)
		_stop_if_playing(_leaf_rustle)
		_stop_if_playing(_brook_murmur)
		_stop_if_playing(_wind_chime)
	else:
		if GameState.in_world:
			if _ambient and not _ambient.playing and _ambient.stream:
				_ambient.play()
			if _music and not _music.playing and _music.stream:
				_music.play()
			_apply_talk_duck()
			_sync_rain_audio()
			_sync_day_night_audio()
			_sync_campfire_audio()
			_sync_wind_audio()
			_sync_hall_reverb_audio()
			_sync_hall_chatter_audio()
			_sync_leaf_rustle_audio()
			_sync_brook_murmur_audio()
			_sync_wind_chime_audio()

func start_ambient() -> void:
	_apply_mute()
	if not GameState.muted:
		if _ambient and _ambient.stream and not _ambient.playing:
			_ambient.play()
		if _music and _music.stream and not _music.playing:
			_music.play()

func stop_ambient() -> void:
	_stop_if_playing(_ambient)
	_stop_if_playing(_music)
	set_rain_audio(false)
	set_indoor_drip(false)
	_stop_if_playing(_day_birds)
	_stop_if_playing(_night_hush)
	_stop_if_playing(_dusk_owl)
	set_campfire_audio(false)
	set_wind_audio(false)
	set_hall_reverb(false)
	set_hall_chatter(false)
	set_leaf_rustle(false)
	set_brook_murmur(false)
	set_wind_chime(false)

func play_ui() -> void:
	_play("ui", -10.0)

func play_hit() -> void:
	_play("hit", -6.0)

func play_miss() -> void:
	_play("miss", -12.0)

func play_swing() -> void:
	# Wave 36: chunkier combat swing whoosh with soft pitch variety (RuneScape-feel)
	_play_swing_varied(-9.0)

func play_door_whoosh() -> void:
	## Wave 47: soft hall door open whoosh (RuneScape-chunky, wholesome; respects mute).
	if GameState.muted:
		return
	var p: AudioStreamPlayer = _players.get("door")
	if p == null:
		return
	p.stream = _streams.get("door")
	p.volume_db = -10.0
	p.pitch_scale = randf_range(0.92, 1.08)
	p.play()

func _play_swing_varied(vol_db: float) -> void:
	if GameState.muted:
		return
	var p: AudioStreamPlayer = _players.get("swing")
	if p == null:
		return
	p.stream = _streams.get("swing")
	p.volume_db = vol_db
	p.pitch_scale = randf_range(0.86, 1.12)
	p.play()

func play_quest_complete() -> void:
	# Wave 38: clearer wholesome quest-complete chime (soft rising sparkle, no combat cheese)
	_play("quest", -3.0)

func play_quest_near_miss() -> void:
	## Wave 54: softer near-miss chime than mastery — quieter, fewer notes, lower pitch (wholesome, no combat cheese).
	_play("quest_near_miss", -9.0)

func play_ember_pop() -> void:
	## Wave 55: soft campfire ember pop — brief warm crackle tick (RuneScape-chunky, wholesome).
	_play("ember_pop", -11.0)

func play_ready_chime() -> void:
	## Wave 65: tiny pantry Ready chime — soft high blip when food cooldown ends (RuneScape-chunky, wholesome; respects mute).
	_play("ready_chime", -12.0)

func play_fountain_rest_chime() -> void:
	## Wave 68: soft fountain-rest chime — warm low-high blip when resting at the fountain (RuneScape-chunky, wholesome; respects mute).
	_play("fountain_rest_chime", -11.0)


func play_footstep() -> void:
	if _foot_cooldown > 0.0:
		return
	_foot_cooldown = 0.32
	# Wave 35: soft footstep pitch variety — gentle left/right feel, not a single thud
	_play_foot_varied(-16.0)

func _play_foot_varied(vol_db: float) -> void:
	if GameState.muted:
		return
	var p: AudioStreamPlayer = _players.get("foot")
	if p == null:
		return
	p.stream = _streams.get("foot")
	p.volume_db = vol_db
	# Wider wholesome pitch band than generic SFX (still soft)
	p.pitch_scale = randf_range(0.88, 1.14)
	p.play()

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
	_streams["swing"] = _whoosh(0.16, 0.28)  # Wave 36: clearer chunky swing whoosh
	_streams["door"] = _door_whoosh(0.32, 0.22)  # Wave 47: soft hall door open whoosh
	_streams["quest"] = _quest_chime()  # Wave 38: clearer quest-complete chime
	_streams["quest_near_miss"] = _quest_near_miss_chime()  # Wave 54: softer near-miss than mastery
	_streams["ambient"] = _soft_drone(8.0, 0.07)
	_streams["music"] = _village_tune(12.0, 0.11)
	_streams["rain"] = _soft_rain(6.0, 0.065)  # Wave 33: softer rain mix
	_streams["drip"] = _indoor_drip(5.0, 0.14)
	_streams["day_birds"] = _day_birds_loop(7.0, 0.07)
	_streams["night_hush"] = _night_cricket_hush(8.0, 0.062)  # Wave 43/76: soft night cricket hush outdoors (Wave 76 polish)
	_streams["dusk_owl"] = _dusk_owl_hoot(9.0, 0.06)  # Wave 49: soft dusk owl hoot outdoors
	_streams["campfire"] = _campfire_crackle(5.5, 0.08)
	_streams["ember_pop"] = _ember_pop_sfx()  # Wave 55: soft campfire ember pop
	_streams["ready_chime"] = _tone_blip(990.0, 0.07, 0.18)  # Wave 65: tiny pantry Ready chime
	_streams["wind"] = _soft_wind(7.0, 0.07)  # Wave 34: soft outdoor wind whoosh
	_streams["hall_reverb"] = _soft_hall_reverb(6.5, 0.06)  # Wave 37: soft indoor hall reverb
	_streams["hall_chatter"] = _soft_hall_chatter(7.0, 0.055)  # Wave 42: soft guild-hall ambient chatter
	_streams["leaf_rustle"] = _soft_leaf_rustle(5.5, 0.07)  # Wave 37: leaf rustle near trees
	_streams["brook_murmur"] = _soft_brook_murmur(6.0, 0.09)  # Wave 73: soft brook murmur polish (richer hush)
	_streams["wind_chime"] = _soft_wind_chime(8.0, 0.055)  # Wave 52: soft wind chime near halls


func set_rain_audio(on: bool) -> void:
	## Quiet rain loop while weather is rain outdoors; always respects mute.
	_rain_wanted = on
	if on:
		_indoor_drip_wanted = false
	_sync_rain_audio()

func set_indoor_drip(on: bool) -> void:
	## Soft roof-drip loop when raining + indoors + unmuted.
	_indoor_drip_wanted = on
	if on:
		_rain_wanted = false
	_sync_rain_audio()


func set_campfire_audio(on: bool) -> void:
	## Wave 33: soft plaza campfire crackle when near hearth (respects mute).
	_campfire_wanted = on
	_sync_campfire_audio()


func set_wind_audio(on: bool) -> void:
	## Wave 34: soft outdoor wind whoosh when outdoors (respects mute).
	_wind_wanted = on
	_sync_wind_audio()


func set_hall_reverb(on: bool) -> void:
	## Wave 37: soft indoor hall reverb cue when inside guild halls (respects mute).
	_hall_reverb_wanted = on
	_sync_hall_reverb_audio()


func set_hall_chatter(on: bool) -> void:
	## Wave 42: soft guild-hall ambient chatter when indoors (respects mute; RuneScape-chunky, wholesome).
	_hall_chatter_wanted = on
	_sync_hall_chatter_audio()

func set_leaf_rustle(on: bool) -> void:
	## Wave 37: soft leaf rustle when near trees outdoors (respects mute).
	_leaf_rustle_wanted = on
	_sync_leaf_rustle_audio()


func set_brook_murmur(on: bool) -> void:
	## Wave 38: soft brook murmur when near water landmarks outdoors (respects mute).
	_brook_murmur_wanted = on
	_sync_brook_murmur_audio()


func set_wind_chime(on: bool) -> void:
	## Wave 52: soft wind chime when outdoors near guild halls (respects mute; RuneScape-chunky, wholesome).
	_wind_chime_wanted = on
	_sync_wind_chime_audio()


func set_day_night_audio(dayness: float, day_phase: float = -1.0) -> void:
	## Wave 26/43/44: soft day bird chirps vs night cricket hush outdoors (respects mute). Hysteresis avoids flicker.
	## Wave 44: soft morning bird swell at dawn (phase ~0.2–0.38).
	if day_phase >= 0.0:
		_day_phase_cache = day_phase
	var want_day: bool = dayness >= 0.48
	var mode: int = 1 if want_day else 0
	if mode != _last_day_audio:
		_last_day_audio = mode
		_day_audio_wanted = want_day
		_sync_day_night_audio()
	else:
		_day_audio_wanted = want_day
	_apply_dawn_bird_swell()
	_apply_dusk_owl_hoot()

func set_talk_duck(on: bool) -> void:
	## Wave 32: soft music/ambient duck while mentor talk panel is open (wholesome, no mute).
	_talk_duck = on
	_apply_talk_duck()


func _apply_talk_duck() -> void:
	if not _ready_ok:
		return
	if GameState.muted:
		return
	var music_db: float = _music_base_db - (10.0 if _talk_duck else 0.0)
	var amb_db: float = _ambient_base_db - (6.0 if _talk_duck else 0.0)
	if _music:
		_music.volume_db = music_db
	if _ambient:
		_ambient.volume_db = amb_db


func _sync_day_night_audio() -> void:
	if not _ready_ok:
		return
	var can: bool = (not GameState.muted) and GameState.in_world
	if _day_birds:
		var on: bool = can and _day_audio_wanted
		if on:
			if _day_birds.stream == null:
				_day_birds.stream = _streams.get("day_birds")
			if not _day_birds.playing and _day_birds.stream:
				_day_birds.play()
			_apply_dawn_bird_swell()
		elif _day_birds.playing:
			_day_birds.stop()
	if _night_hush:
		var on_n: bool = can and (not _day_audio_wanted)
		if on_n:
			if _night_hush.stream == null:
				_night_hush.stream = _streams.get("night_hush")
			if not _night_hush.playing and _night_hush.stream:
				_night_hush.play()
		elif _night_hush.playing:
			_night_hush.stop()
	_apply_dusk_owl_hoot()


func _apply_dawn_bird_swell() -> void:
	## Wave 44: soft morning bird swell at dawn — birds lift gently then settle (RuneScape-chunky, wholesome).
	if _day_birds == null or not _ready_ok:
		return
	if GameState.muted or not GameState.in_world or not _day_audio_wanted:
		return
	if not _day_birds.playing:
		return
	var phase: float = _day_phase_cache
	var swell: float = 0.0
	# Dawn window matches HUD Dawn (phase 0.2–0.35), with a soft shoulder
	if phase >= 0.18 and phase < 0.40:
		var u: float = (phase - 0.18) / 0.22
		swell = sin(clampf(u, 0.0, 1.0) * PI)  # rise and fall
	_day_birds.volume_db = _birds_base_db + swell * 7.5


func _apply_dusk_owl_hoot() -> void:
	## Wave 49: soft dusk owl hoot outdoors — gentle low who-who at dusk (RuneScape-chunky, wholesome).
	if _dusk_owl == null or not _ready_ok:
		return
	var can: bool = (not GameState.muted) and GameState.in_world
	# Outdoor dusk: night pad on (not day birds) + dusk/early-night phase window
	var phase: float = _day_phase_cache
	var dusk: bool = (phase >= 0.58 and phase <= 0.90)
	var on: bool = can and (not _day_audio_wanted) and dusk
	if on:
		if _dusk_owl.stream == null:
			_dusk_owl.stream = _streams.get("dusk_owl")
		if not _dusk_owl.playing and _dusk_owl.stream:
			_dusk_owl.play()
		# Soft swell through dusk heart
		var u: float = (phase - 0.58) / 0.32
		var swell: float = sin(clampf(u, 0.0, 1.0) * PI)
		_dusk_owl.volume_db = -30.5 + swell * 5.5
	elif _dusk_owl.playing:
		_dusk_owl.stop()

func _sync_loop(player: AudioStreamPlayer, wanted: bool, stream_key: String) -> void:
	if not _ready_ok or player == null:
		return
	var can: bool = (not GameState.muted) and GameState.in_world
	var should: bool = wanted and can
	if should:
		if player.stream == null:
			player.stream = _streams.get(stream_key)
		if not player.playing and player.stream:
			player.play()
	elif player.playing:
		player.stop()


func _sync_rain_audio() -> void:
	if not _ready_ok:
		return
	var can: bool = not GameState.muted and GameState.in_world
	# Outdoor rain
	if _rain:
		var should_rain: bool = _rain_wanted and can and not _indoor_drip_wanted
		if should_rain:
			if _rain.stream == null:
				_rain.stream = _streams.get("rain")
			if not _rain.playing and _rain.stream:
				_rain.play()
		elif _rain.playing:
			_rain.stop()
	# Indoor drips
	if _drip:
		var should_drip: bool = _indoor_drip_wanted and can
		if should_drip:
			if _drip.stream == null:
				_drip.stream = _streams.get("drip")
			if not _drip.playing and _drip.stream:
				_drip.play()
		elif _drip.playing:
			_drip.stop()

func _sync_campfire_audio() -> void:
	_sync_loop(_campfire, _campfire_wanted, "campfire")

func _sync_wind_audio() -> void:
	_sync_loop(_wind, _wind_wanted, "wind")

func _sync_hall_reverb_audio() -> void:
	_sync_loop(_hall_reverb, _hall_reverb_wanted, "hall_reverb")

func _sync_hall_chatter_audio() -> void:
	_sync_loop(_hall_chatter, _hall_chatter_wanted, "hall_chatter")

func _sync_leaf_rustle_audio() -> void:
	_sync_loop(_leaf_rustle, _leaf_rustle_wanted, "leaf_rustle")

func _sync_brook_murmur_audio() -> void:
	_sync_loop(_brook_murmur, _brook_murmur_wanted, "brook_murmur")

func _sync_wind_chime_audio() -> void:
	_sync_loop(_wind_chime, _wind_chime_wanted, "wind_chime")

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
	## Wave 36: clearer combat swing whoosh — soft rising band-sweep (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var env := sin(PI * tt / dur)
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.72 + noise * 0.28
		# Soft rising hush so the swing reads as a whoosh, not a click
		var sweep := 0.65 + 0.35 * (tt / maxf(dur, 0.001))
		samples[i] = prev * amp * env * sweep
	return _make_wav(samples, rate)

func _door_whoosh(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 47: soft hall door open whoosh — longer hush with a gentle wood-settle tip (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var env := sin(PI * tt / dur)
		# Soft low wood tip near the start
		var tip := 0.0
		if tt < 0.06:
			tip = sin(TAU * 180.0 * tt) * (1.0 - tt / 0.06) * 0.35
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.78 + noise * 0.22
		var sweep := 0.55 + 0.45 * (tt / maxf(dur, 0.001))
		samples[i] = (prev * amp * env * sweep) + tip * amp
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


func _soft_rain(dur: float, amp: float) -> AudioStreamWAV:
	## Soft loopable rain — filtered noise, intentionally quiet and non-startling.
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		# Wave 33: softer low-pass hush (less hiss, gentler drip pops)
		prev = prev * 0.90 + noise * 0.10
		var breathe := 0.88 + 0.12 * sin(TAU * 0.06 * t)
		var drip := 0.0
		if int(t * 9.0) % 19 == 0:
			drip = sin(TAU * 720.0 * fmod(t, 0.1)) * exp(-fmod(t, 0.1) * 36.0) * 0.05
		samples[i] = (prev * 0.65 + drip) * amp * breathe
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _campfire_crackle(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 33: soft plaza hearth crackle — sparse pops over warm hush (wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	var pops := [0.35, 0.9, 1.55, 2.2, 2.95, 3.7, 4.4, 5.05]
	for i in n:
		var t := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.92 + noise * 0.08
		var bed := prev * 0.35
		var pop := 0.0
		for pt in pops:
			var u := t - float(pt)
			if u >= 0.0 and u < 0.08:
				pop += (randf() * 2.0 - 1.0) * exp(-u * 48.0) * 0.55
				pop += sin(TAU * 180.0 * u) * exp(-u * 28.0) * 0.2
		var breathe := 0.9 + 0.1 * sin(TAU * 0.11 * t)
		samples[i] = (bed + pop) * amp * breathe
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream



func _soft_wind(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 34: soft outdoor wind whoosh — gentle filtered hush (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	var prev2 := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		prev2 = prev2 * 0.88 + noise * 0.12
		prev = prev * 0.94 + prev2 * 0.06
		var swell := 0.75 + 0.25 * sin(TAU * 0.07 * tt) + 0.08 * sin(TAU * 0.19 * tt)
		samples[i] = prev * amp * swell
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _soft_hall_reverb(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 37: soft indoor hall reverb — warm mid hush with gentle echoes (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.96 + noise * 0.04
		var warm := sin(TAU * 110.0 * tt) * 0.12 + sin(TAU * 165.0 * tt) * 0.08
		var echo := sin(TAU * 220.0 * tt) * 0.05 * (0.5 + 0.5 * sin(TAU * 0.35 * tt))
		var breathe := 0.85 + 0.15 * sin(TAU * 0.09 * tt)
		samples[i] = (prev * 0.55 + warm + echo) * amp * breathe
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _soft_hall_chatter(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 42: soft guild-hall ambient chatter — warm murmur of quiet voices & paper rustle (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.92 + noise * 0.08
		# Soft formant-ish murmur (not intelligible words)
		var mur1 := sin(TAU * 180.0 * tt + sin(TAU * 2.1 * tt) * 0.8) * 0.14
		var mur2 := sin(TAU * 240.0 * tt + sin(TAU * 1.4 * tt) * 1.1) * 0.10
		var mur3 := sin(TAU * 320.0 * tt) * 0.05 * (0.5 + 0.5 * sin(TAU * 0.37 * tt))
		var paper: float = prev * 0.25 * (0.4 + 0.6 * absf(sin(TAU * 0.55 * tt)))
		var breathe := 0.8 + 0.2 * sin(TAU * 0.11 * tt)
		var burst := 1.0
		if fmod(tt * 0.47, 1.0) < 0.08:
			burst = 1.15  # soft chatter swell
		samples[i] = (prev * 0.35 + mur1 + mur2 + mur3 + paper) * amp * breathe * burst
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _soft_leaf_rustle(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 37: soft leaf rustle near trees — light high-band crackle hush (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	var prev2 := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		# High-pass-ish: keep more of the bright rustle
		prev2 = prev2 * 0.55 + noise * 0.45
		prev = prev * 0.7 + prev2 * 0.3
		var bright := prev - prev * 0.35
		var gust := 0.7 + 0.3 * sin(TAU * 0.22 * tt) + 0.1 * sin(TAU * 0.51 * tt)
		samples[i] = bright * amp * gust
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

func _soft_brook_murmur(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 38: soft brook murmur near water — gentle low gurgle hush (RuneScape-chunky, wholesome).
	## Wave 73: soft brook murmur polish — warmer gurgle + soft bubble hush (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var prev := 0.0
	for i in n:
		var tt := float(i) / float(rate)
		var noise := randf() * 2.0 - 1.0
		prev = prev * 0.92 + noise * 0.08
		var gurgle := sin(TAU * 88.0 * tt) * 0.16 + sin(TAU * 136.0 * tt + 0.7) * 0.11
		var bubble := sin(TAU * 210.0 * tt) * 0.055 * (0.5 + 0.5 * sin(TAU * 0.26 * tt))
		var flow := 0.82 + 0.18 * sin(TAU * 0.10 * tt)
		samples[i] = (prev * 0.5 + gurgle + bubble) * amp * flow
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _quest_chime() -> AudioStreamWAV:
	## Wave 38: clearer quest-complete chime — soft rising four-note sparkle (wholesome, no combat cheese).
	var rate := 22050
	var freqs := [523.25, 659.25, 783.99, 1046.5]
	var note_dur := 0.11
	var total := note_dur * float(freqs.size()) + 0.18
	var n := int(total * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var tsec := float(i) / float(rate)
		var s := 0.0
		for fi in freqs.size():
			var start := float(fi) * note_dur
			var u := tsec - start
			if u >= 0.0 and u < note_dur + 0.08:
				var env := exp(-u * 7.5)
				s += sin(TAU * float(freqs[fi]) * u) * env * 0.32
				# Soft octave sparkle on the last two notes
				if fi >= 2:
					s += sin(TAU * float(freqs[fi]) * 2.0 * u) * env * 0.08
		samples[i] = clampf(s, -1.0, 1.0)
	return _make_wav(samples, rate)


func _quest_near_miss_chime() -> AudioStreamWAV:
	## Wave 54: softer near-miss than mastery — two gentle lower notes, quieter decay (wholesome).
	var rate := 22050
	var freqs := [392.0, 440.0]  # G4 → A4, softer than mastery C-E-G-C
	var note_dur := 0.13
	var total := note_dur * float(freqs.size()) + 0.22
	var n := int(total * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var tsec := float(i) / float(rate)
		var s := 0.0
		for fi in freqs.size():
			var start := float(fi) * note_dur
			var u := tsec - start
			if u >= 0.0 and u < note_dur + 0.10:
				var env := exp(-u * 9.0)
				s += sin(TAU * float(freqs[fi]) * u) * env * 0.20
		samples[i] = clampf(s, -1.0, 1.0)
	return _make_wav(samples, rate)



func _ember_pop_sfx() -> AudioStreamWAV:
	## Wave 55: soft campfire ember pop — brief warm noise tick + soft tone (wholesome).
	var rate := 22050
	var dur := 0.14
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var u := float(i) / float(rate)
		var env := exp(-u * 36.0)
		var noise := (randf() * 2.0 - 1.0) * 0.45
		var tone := sin(TAU * 210.0 * u) * 0.22 + sin(TAU * 140.0 * u) * 0.12
		samples[i] = clampf((noise + tone) * env * 0.55, -1.0, 1.0)
	return _make_wav(samples, rate)


func _indoor_drip(dur: float, amp: float) -> AudioStreamWAV:
	## Sparse roof drips for indoor rain — quiet, non-startling, loopable.
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var drip_times := [0.4, 1.1, 1.85, 2.6, 3.35, 4.2]
	for i in n:
		var t := float(i) / float(rate)
		var s := 0.0
		for dt in drip_times:
			var u := t - float(dt)
			if u >= 0.0 and u < 0.12:
				s += sin(TAU * 780.0 * u) * exp(-u * 36.0) * 0.55
				s += sin(TAU * 420.0 * u) * exp(-u * 22.0) * 0.25
		var hush := (randf() * 2.0 - 1.0) * 0.02
		samples[i] = (s + hush) * amp
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

func _day_birds_loop(dur: float, amp: float) -> AudioStreamWAV:
	## Soft sparse daytime chirps — wholesome, non-startling, loopable.
	## Wave 44 pairs with dawn volume swell in _apply_dawn_bird_swell.
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var chirps := [0.55, 1.7, 2.35, 3.6, 4.85, 5.9]
	for i in n:
		var tsec := float(i) / float(rate)
		var s := 0.0
		for c in chirps:
			var u := tsec - float(c)
			if u >= 0.0 and u < 0.09:
				var env := exp(-u * 40.0)
				s += sin(TAU * (1800.0 + 400.0 * sin(u * 90.0)) * u) * env * 0.55
				s += sin(TAU * 2400.0 * u) * exp(-u * 55.0) * 0.2
		var hush := (randf() * 2.0 - 1.0) * 0.015
		samples[i] = (s + hush) * amp
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream


func _night_cricket_hush(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 43/76: soft night cricket hush outdoors — warmer low bed + slightly richer sparse cricket chirps (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var tsec := float(i) / float(rate)
		# Wave 76 soft night cricket hush polish — warmer bed layers
		var bed := sin(TAU * 68.0 * tsec) * 0.30 + sin(TAU * 92.0 * tsec) * 0.20 + sin(TAU * 54.0 * tsec) * 0.08
		var breathe := 0.70 + 0.30 * sin(TAU * 0.065 * tsec)
		# Soft cricket chirp bursts — high, brief, spaced (not harsh); Wave 76: slightly denser gentle pairs
		var chirp := 0.0
		var chirp_slot := int(tsec * 2.5)
		if chirp_slot % 5 == 0 or chirp_slot % 7 == 3 or chirp_slot % 11 == 2:
			var u := fmod(tsec * 2.5, 1.0)
			if u < 0.20:
				var pulse := sin(TAU * (3150.0 + 420.0 * sin(TAU * 17.0 * tsec)) * u)
				var env := exp(-u * 13.5) * (0.55 + 0.45 * sin(TAU * 52.0 * u))
				chirp = pulse * env * 0.092
		# Very soft secondary hush tick
		var tick := 0.0
		if int(tsec * 5.0) % 13 == 0:
			var v := fmod(tsec, 0.1)
			tick = sin(TAU * 1080.0 * v) * exp(-v * 42.0) * 0.038
		samples[i] = (bed * breathe + chirp + tick) * amp
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

func _dusk_owl_hoot(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 49: soft dusk owl hoot — warm low who-who pairs, sparse and gentle (respects mute via player).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	# Soft hoot pair starts (seconds into loop)
	var hoots := [1.1, 1.45, 4.2, 4.55, 7.0, 7.35]
	for i in n:
		var tsec := float(i) / float(rate)
		var s := 0.0
		# Warm low bed so silence between hoots is soft, not empty
		var bed := sin(TAU * 55.0 * tsec) * 0.12 + sin(TAU * 78.0 * tsec) * 0.08
		var breathe := 0.75 + 0.25 * sin(TAU * 0.05 * tsec)
		for h in hoots:
			var u := tsec - float(h)
			if u >= 0.0 and u < 0.28:
				var env := sin(clampf(u / 0.28, 0.0, 1.0) * PI) * exp(-u * 3.2)
				# Soft who-gliss — low then slightly lower
				var freq := 268.0 - 28.0 * (u / 0.28)
				s += sin(TAU * freq * u) * env * 0.7
				s += sin(TAU * (freq * 0.5) * u) * env * 0.25
		samples[i] = (s + bed * breathe * 0.35) * amp
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

func _soft_wind_chime(dur: float, amp: float) -> AudioStreamWAV:
	## Wave 52: soft wind chime near halls — sparse glass/metal tones (RuneScape-chunky, wholesome).
	var rate := 22050
	var n := int(dur * rate)
	var samples := PackedFloat32Array()
	samples.resize(n)
	# Soft chime strikes (seconds into loop)
	var strikes := [0.4, 1.6, 2.9, 4.1, 5.5, 6.8]
	var freqs := [784.0, 988.0, 1174.0, 880.0, 1046.0, 1318.0]
	for i in n:
		var tsec := float(i) / float(rate)
		var s := 0.0
		# Quiet air bed
		var bed := sin(TAU * 48.0 * tsec) * 0.06 + sin(TAU * 72.0 * tsec) * 0.04
		var breathe := 0.8 + 0.2 * sin(TAU * 0.07 * tsec)
		for k in range(strikes.size()):
			var u := tsec - float(strikes[k])
			if u >= 0.0 and u < 1.4:
				var env := exp(-u * 2.4)
				var f := float(freqs[k])
				s += sin(TAU * f * u) * env * 0.55
				s += sin(TAU * (f * 2.01) * u) * env * 0.12
		samples[i] = (s + bed * breathe) * amp
	var stream := _make_wav(samples, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	return stream

