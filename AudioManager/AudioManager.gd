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
	finished.connect(music_stream.play)
	sfx_changed.connect(sfx_stream.play)
	

func set_current_track(name : String):
	for song in songs:
		if(song.contains(name)):
			current_track = song
			song_changed.emit(current_track)
			

func set_current_sfx(name : String):
	for sound in sfx:
		if(sound.contains(name)):
			sfx_stream.load
			sfx_changed.emit()
			

func change_track_playback():
	music_stream.stop()
