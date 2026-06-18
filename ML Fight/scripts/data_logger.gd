extends Node

@export var player: CharacterBody2D
@export var enemy: CharacterBody2D

var file: FileAccess
var frames_logged: int = 0
var file_path: String = "res://combat_data.txt"

func _ready() -> void:
	if GameState.logging_enabled:
		open_file()

func open_file() -> void:
	if FileAccess.file_exists(file_path):
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		file.seek_end()
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_line("dist_x,dist_y,p_vel_y,p_moving_toward,p_combo,p_hp,e_hp,e_state,e_atk,e_def,p_action_label")

func reset_data() -> void:
	if file:
		file.close()
		file = null
		
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		
	frames_logged = 0

func _physics_process(delta: float) -> void:
	if not GameState.logging_enabled or not is_instance_valid(player) or not is_instance_valid(enemy):
		return

	if file == null:
		open_file()

	var dist_x: float = abs(player.global_position.x - enemy.global_position.x)
	var dist_y: float = player.global_position.y - enemy.global_position.y
	var p_vel_y: float = player.velocity.y
	
	var dir_to_enemy: float = sign(enemy.global_position.x - player.global_position.x)
	var p_input_dir: float = player.controller.get_movement_direction() if player.controller else 0.0
	var p_moving_toward: float = p_input_dir * dir_to_enemy 
	
	var p_combo: int = player.combo_step
	var p_hp: float = player.health
	var e_hp: float = enemy.health
	
	var e_state: int = enemy.current_state
	var e_atk: int = int(enemy.is_attacking)
	var e_def: int = int(enemy.is_defending)

	var p_action_label: int = 0
	var p_ctrl = player.controller
	
	if player.is_attacking:
		p_action_label = 1 if player.combo_step in [1, 2] else 2
	elif player.is_defending:
		p_action_label = 3
	elif player.is_state_jump():
		p_action_label = 4
	elif p_ctrl:
		if p_ctrl.wants_run() and p_moving_toward > 0: p_action_label = 5 
		elif p_ctrl.wants_run() and p_moving_toward < 0: p_action_label = 6 
		elif p_moving_toward != 0: p_action_label = 7

	if p_action_label != 0 or frames_logged % 10 == 0:
		var row: String = str(dist_x) + "," + str(dist_y) + "," + str(p_vel_y) + "," + str(p_moving_toward) + "," + str(p_combo) + "," + str(p_hp) + "," + str(e_hp) + "," + str(e_state) + "," + str(e_atk) + "," + str(e_def) + "," + str(p_action_label)
		file.store_line(row)
		file.flush()
		
	frames_logged += 1

func _exit_tree() -> void:
	if file:
		file.close()
