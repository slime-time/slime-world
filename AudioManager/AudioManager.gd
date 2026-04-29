extends Node

var current_track : Resource

var songs : PackedStringArray
var sfx : PackedStringArray
var music_stream : AudioStreamPlayer
var continuous_sfx_streams : Node
var oneshot_sfx_streams : Node

signal song_changed


func _ready() -> void:
	set_process_mode(PROCESS_MODE_ALWAYS)
	var song_directory = DirAccess.open("res://assets/music")
	var sfx_directory = DirAccess.open("res://assets/sfx")
	songs = song_directory.get_files()
	sfx = sfx_directory.get_files()
	music_stream = AudioStreamPlayer.new()
	music_stream.set_bus("ActiveMusic")
	continuous_sfx_streams = Node.new()
	oneshot_sfx_streams =  Node.new()
	
	song_changed.connect(change_track_playback)
	#looping behavior
	music_stream.finished.connect(music_stream.play)
	var tree = get_tree()
	tree.root.add_child.call_deferred(music_stream)
	tree.root.add_child.call_deferred(continuous_sfx_streams)
	tree.root.add_child.call_deferred(oneshot_sfx_streams)
	
	tree.scene_changed.connect(func(node: Node) : 
		for child in node.get_children():
			if (child is FluidFlow) or (child is FluidVolume):
				play_sfx("looping_waterfall", 0)
		)
	
	#can refactor to change theme based on level later
	GameManager.level_changed.connect(func() : set_current_track("sgsw_theme1"))

func set_current_track(songName : String):
	for song in songs:
		if(song.contains(songName) and !song.contains(".import")):
			current_track = load("res://assets/music/" + song)
			song_changed.emit(current_track)
		else:
			print_debug("no song found with that name")
			

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
		newStream.stream.load("res://assets/sfx/" + sfxName +".wav")
		
		if mode: 
			newStream.finished.connect(newStream.queue_free)
			#when the audio is done playing deallocate player for it
			oneshot_sfx_streams.add_child(newStream)
			
		else: 
			newStream.finished.connect(newStream.play)
			continuous_sfx_streams.add_child(newStream)
		newStream.play()
		
		
	for stream in streams:
		if stream.name == sfxName:
			stream.play()
	
	return
			

func change_track_playback(song):
	music_stream.stop()
	music_stream.set_stream(song)
	music_stream.play()
