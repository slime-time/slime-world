extends Node

var current_track : String

var songs : PackedStringArray
var sfx : PackedStringArray
var music_stream : AudioStreamPlayer
var sfx_stream : AudioStreamPlayer2D

signal song_changed
signal sfx_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var song_directory = DirAccess.open("res://assets/music")
	var sfx_directory = DirAccess.open("res://assets/sfx")
	
	songs = song_directory.get_files()
	sfx = sfx_directory.get_files()
	music_stream = get_node("MusicStream")
	sfx_stream = get_node("SfxStream")
	
	song_changed.connect(change_track_playback)
	#looping behavior
	music_stream.finished.connect(music_stream.play)
	sfx_changed.connect(sfx_stream.play)
	

func set_current_track(name : String):
	for song in songs:
		if(song.contains(name)):
			current_track = song
			song_changed.emit(current_track)
			

func play_sfx(name : String):
	#allow for overlapping playback for sfx
	if sfx_stream.playing:
		sfx_stream.max_polyphony += 1
	else: 
		sfx_stream.max_polyphony -= 1
	for sound in sfx:
		if(sound.contains(name)):
			sfx_stream.stream.load(name)
			sfx_changed.emit()
			

func change_track_playback(song : String):
	music_stream.stop()
	music_stream.load(song)
	music_stream.play()
