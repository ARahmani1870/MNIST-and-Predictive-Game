extends Node

var player_wins: int = 0
var enemy_wins: int = 0
var logging_enabled: bool = false 

const SETTINGS_FILE = "user://settings.cfg"

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		logging_enabled = config.get_value("Data", "logging_enabled", false)
		
		var sfx_db = config.get_value("Audio", "sfx_db", 0.0)
		var bgm_db = config.get_value("Audio", "bgm_db", 0.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_db)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), bgm_db)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("Data", "logging_enabled", logging_enabled)
	config.set_value("Audio", "sfx_db", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	config.set_value("Audio", "bgm_db", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")))
	config.save(SETTINGS_FILE)
