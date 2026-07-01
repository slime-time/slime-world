extends Node

var current_track : Resource
var level_theme_playback_position : float

var songs : PackedStringArray
var sfx : PackedStringArray
var music_stream : AudioStreamPlayer
var continuous_sfx_streams : Node
var oneshot_sfx_streams : Node

var audio_config = ConfigFile.new()

const DEFAULT_MUSIC_VOLUME: float = 0

# Note that despite their similar name, this works differently than the
# DEFAULT_MUSIC_VOLUME value
var sfx_volume_multiplier: float = 0.5

# Frame when the last split happened, to prevent energized slimes causing loud splitting noises
var last_split_frame: int

# Store the filepath to the last song played, to avoid interrupting a song with itself
var prev_song: String = ""

signal song_changed


func _ready() -> void:
	var audio_error = audio_config.load("res://settings.cfg")
	if(audio_error != OK):
		printerr("Could not load audio configuration")
	set_process_mode(PROCESS_MODE_ALWAYS)
	var song_directory = DirAccess.open("res://assets/music")
	var sfx_directory = DirAccess.open("res://assets/sfx")
	songs = PackedStringArray()
	for filename in song_directory.get_files():
		if filename.ends_with(".import"):
			songs.append(filename.replace(".import", ""))
	sfx = sfx_directory.get_files()
	music_stream = AudioStreamPlayer.new()
	music_stream.set_volume_linear(audio_config.get_value("audio_settings", "music_volume", DEFAULT_MUSIC_VOLUME))
	music_stream.set_bus("ActiveMusic")
	continuous_sfx_streams = Node.new()
	oneshot_sfx_streams =  Node.new()

	song_changed.connect(change_track_playback)
	#looping behavior
	music_stream.finished.connect(func():
		print("ended")
		music_stream.play)
	var tree = get_tree()
	tree.root.add_child.call_deferred(music_stream)
	tree.root.add_child.call_deferred(continuous_sfx_streams)
	tree.root.add_child.call_deferred(oneshot_sfx_streams)
	call_deferred("set_current_track", "sgsw_pause_theme")
	#can refactor to change theme based on level later
	GameManager.level_changed.connect(on_scene_change)

func set_current_track(songName : String):
	var any_found = false
	for song in songs:
		if(song.contains(songName) and song != prev_song):
			prev_song = song
			current_track = load("res://assets/music/" + song)
			song_changed.emit(current_track)
			any_found = true
			break
	if not any_found:
		print_debug("no song found with name ", songName)


func on_scene_change():
	#ensure active scene is always the newly loaded one
	var tree = get_tree()
	await tree.scene_changed
	print_debug("triggered")
	if(GameManager.current_state.cur_level != 0):
		set_current_track("sgsw_theme1")
	else:
		set_current_track("sgsw_pause_theme")

func play_sfx(sfxName : String, mode : int, volume : float = 0.0, pitch : float = 1.0, start: float = 0.0):
	var streams
	var busName
	#(mode = 1) -> oneshot (mode = 0) -> continuous
	if mode:
		streams = oneshot_sfx_streams.get_children()
		busName = "OneShotSFX"
	else:
		streams = continuous_sfx_streams.get_children()
		busName = "ContinuousSFX"

	
	var newStream = AudioStreamPlayer.new()
	newStream.name = sfxName
	newStream.bus = busName
	var sound = load("res://assets/sfx/" + sfxName +".wav")
	newStream.set_stream(sound)

	for stream in streams:
		#make sure we dont have sound effects from the same source cutting themself off
		if stream.name == sfxName and !stream.playing:
			stream.play(start)

	if mode:
		newStream.finished.connect(newStream.queue_free)
		#when the audio is done playing deallocate player for it
		oneshot_sfx_streams.add_child(newStream)

	else:
		newStream.finished.connect(newStream.play)
		#looping
		continuous_sfx_streams.add_child(newStream)

	newStream.set_volume_linear(volume)
	newStream.pitch_scale = pitch
	newStream.play(start)

	return

# Set up the local_audio player by making it play the sound effect specified by "track_name"
# with appropriate volume on appropriate bus, and possibly looping
# If fixed_stream is set to false, the caller is responsible for setting up the track instead of this function
func setupLocalAudioPlayer(local_audio_player: AudioStreamPlayer2D, loop: bool, volume: float, fixed_stream: bool = false, track_name: String = ""):
	if(loop):
		local_audio_player.finished.connect(local_audio_player.play)
		local_audio_player.bus = "ContinuousSFX"
	else:
		local_audio_player.bus = "OneShotSFX"
	
	local_audio_player.set_volume_linear(volume * sfx_volume_multiplier)
	if fixed_stream:
		var sound = load("res://assets/sfx/" + track_name + ".wav")
		local_audio_player.set_stream(sound)

func change_track_playback(song):

	music_stream.stop()

	if(song.resource_name.contains("sgsw_pause_theme.wav")):
		level_theme_playback_position = music_stream.get_playback_position()
	else:
		level_theme_playback_position = 0.0

	music_stream.set_stream(song)
	if(song.resource_name.contains("sgsw_pause_theme.wav")):
		music_stream.play()
	else:
		music_stream.play(level_theme_playback_position)
