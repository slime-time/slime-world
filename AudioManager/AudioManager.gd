extends Node

var current_track : String

var songs : PackedStringArray
var sfx : PackedStringArray
var music_stream : AudioStreamPlayer
var continuous_sfx_streams : Control
var oneshot_sfx_streams : Control

signal song_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var song_directory = DirAccess.open("res://assets/music")
	var sfx_directory = DirAccess.open("res://assets/sfx")
	print_debug(self.get_children())
	songs = song_directory.get_files()
	sfx = sfx_directory.get_files()
	music_stream = get_node("MusicStream")
	continuous_sfx_streams = get_node("ContinuousSfxStreams")
	oneshot_sfx_streams = get_node("OneShotSfxStreams")
	
	song_changed.connect(change_track_playback)
	#looping behavior
	music_stream.finished.connect(music_stream.play)
	

func set_current_track(songName : String):
	for song in songs:
		if(song.contains(songName)):
			current_track = song
			song_changed.emit(current_track)
			

func play_sfx(sfxName : String, mode : int):
	var streams
	var busName
	#(mode = 1) -> oneshot (mode = 0) -> continuous
	if mode: 
		streams = oneshot_sfx_streams.get_children()
		busName = "OneShotSFX"
	else: 
		streams = continuous_sfx_streams.get_children()
		busName = "ContinuousSFX"
	
	if streams.is_empty():
		var newStream = AudioStreamPlayer.new()
		newStream.name = sfxName
		newStream.bus = busName
		newStream.stream.load("res://assets/sfx/" + sfxName)
		
		if mode: oneshot_sfx_streams.add_child(newStream)
		else: continuous_sfx_streams.add_child(newStream)
		newStream.play()
		
		
	for stream in streams:
		if stream.name == name:
			stream.play()
	
	return
			

func change_track_playback(song : String):
	music_stream.stop()
	music_stream.load(song)
	music_stream.play()
