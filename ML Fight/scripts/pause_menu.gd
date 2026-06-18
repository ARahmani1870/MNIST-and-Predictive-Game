extends CanvasLayer

@onready var resume_btn: Button = $PanelContainer/VBoxContainer/ResumeBtn

@onready var info_label: Label = $PanelContainer/VBoxContainer/InfoLabel
@onready var toggle_log_btn: Button = $PanelContainer/VBoxContainer/ToggleLogBtn
@onready var sfx_slider: HSlider = $PanelContainer/VBoxContainer/SFXSlider
@onready var bgm_slider: HSlider = $PanelContainer/VBoxContainer/BGMSlider

var is_paused: bool = false
var data_logger_node: Node

func _ready() -> void:
	visible = false
	
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var bgm_idx = AudioServer.get_bus_index("BGM")
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))
	bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_idx))
	
	update_log_btn_text()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	visible = is_paused
	if is_paused:
		info_label.text = ""
		data_logger_node = get_node_or_null("/root/Root/DataLogger")
		
		resume_btn.grab_focus()

func update_log_btn_text() -> void:
	toggle_log_btn.text = "TOGGLE ML LOGGING: " + ("ON" if GameState.logging_enabled else "OFF")

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:
	toggle_pause()
	get_tree().reload_current_scene()

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	GameState.save_settings()

func _on_bgm_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(value))
	GameState.save_settings()

func _on_controls_pressed() -> void:
	info_label.text = "CONTROLS:\n- WASD - Movement\n- LMB - Light Attack\n- MMB - Heavy Attack\n- RMB - Block\n- Space - Jump\n- Shift - Run\n- Attacks dealt while running and/or jumping do more damage.\n- Attacks hitting the head do more damage.\n- Ground hits on blocking opponent stun attacker.\n- Jump hits on blocking opponent stuns blocker."

func _on_credits_pressed() -> void:
	info_label.text = "CREDITS:\nThe game logic and neural network implementation are my own.\n\nThe audiovisual assets used have been taken from various creators.\nSee CREDITS.md on the GitHub repository for details."

func _on_toggle_log_pressed() -> void:
	GameState.logging_enabled = !GameState.logging_enabled
	update_log_btn_text()
	GameState.save_settings()

func _on_reset_log_pressed() -> void:
	if data_logger_node and data_logger_node.has_method("reset_data"):
		data_logger_node.reset_data()
		info_label.text = "ML DATA DELETED."
	else:
		info_label.text = "ERROR: DataLogger not found."

func _on_quit_pressed() -> void:
	get_tree().quit()
