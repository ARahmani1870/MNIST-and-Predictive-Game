extends Node

const FILE_NAME = "model_weights.json"
var internal_path = "res://" + FILE_NAME
var external_path = ""

var weights_data = null

func _ready():
	var exe_dir = OS.get_executable_path().get_base_dir()
	
	if OS.has_feature("editor"):
		external_path = internal_path
	else:
		external_path = exe_dir.path_join(FILE_NAME)
		
	weights_data = load_model_weights()

func load_model_weights():
	var target_file = ""

	if FileAccess.file_exists(external_path):
		target_file = external_path
	else:
		target_file = internal_path
		create_external_template()

	var file = FileAccess.open(target_file, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		
		return json.data
			
	return null

func create_external_template():
	if not OS.has_feature("editor"):
		var dir = DirAccess.open("res://")
		if dir:
			dir.copy(internal_path, external_path)
