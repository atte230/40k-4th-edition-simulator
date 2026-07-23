extends Node

# SFXLoader.gd
# Downloads a remote SFX file and attempts to load it as an AudioStream resource.
# Emits `sfx_ready` with the loaded AudioStream (or null on failure).

signal sfx_ready(audio_stream)

var http: HTTPRequest

func _ready() -> void:
	http = HTTPRequest.new()
	http.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_request_completed"))

func download(url:String, filename:String = "retro_blip.mp3") -> void:
	# Ensure user://sfx exists
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("sfx"):
		dir.make_dir("sfx")
	# Start HTTP request
	var err = http.request(url)
	if err != OK:
		print("SFXLoader: HTTP request failed to start: %s" % str(err))

func _on_request_completed(result:int, response_code:int, headers:Array, body:PoolByteArray) -> void:
	if result != OK or response_code >= 400:
		print("SFXLoader: download failed result=%d code=%d" % [result, response_code])
		emit_signal("sfx_ready", null)
		return
	# Write to user://sfx/retro_blip.mp3
	var path = "user://sfx/retro_blip.mp3"
	var f = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if f:
		f.store_buffer(body)
		f.close()
		print("SFXLoader: saved to %s" % path)
		# Attempt to load resource
		var res = ResourceLoader.load(path)
		if res == null:
			# try AudioStreamSample load (Godot may not support MP3 in ResourceLoader)
			print("SFXLoader: ResourceLoader failed to load %s" % path)
			emit_signal("sfx_ready", null)
			return
		emit_signal("sfx_ready", res)
	else:
		print("SFXLoader: failed to open file for writing")
		emit_signal("sfx_ready", null)
