extends Node

@export var target: Node2D
@export var attack_range: float = 25.0

var weights: Array = []
var biases: Array = []
var is_model_loaded: bool = false

var direction: float = 0.0
var jump_pressed: bool = false
var run_pressed: bool = false
var light_pressed: bool = false
var heavy_pressed: bool = false
var defend_pressed: bool = false

var attack_cooldown: float = 0.0
var react_timer: float = 0.0
var predicted_action: int = 0

const ATK_BUFFER: int = 10

func _ready() -> void:
	# Wait for safety
	await get_tree().process_frame
	load_model_weights()

func load_model_weights() -> void:
	var data = ModelLoader.weights_data
	
	if data and data.has("weights") and data.has("biases"):
		weights = data["weights"]
		biases = data["biases"]
		is_model_loaded = true

func _physics_process(delta: float) -> void:
	jump_pressed = false
	light_pressed = false
	heavy_pressed = false
	defend_pressed = false
	run_pressed = false
	direction = 0.0
	
	if not is_model_loaded or not target or not is_instance_valid(target):
		return
		
	var x_difference = target.global_position.x - owner.global_position.x
	var dir_to_target = sign(x_difference) if abs(x_difference) > 10 else 0.0
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	react_timer -= delta
	if react_timer <= 0:
		react_timer = 0.1 
		predicted_action = predict_player_action(dir_to_target)

	var horizontal_distance = abs(x_difference)
	execute_counter_strategy(predicted_action, dir_to_target, horizontal_distance)

func predict_player_action(dir_to_target: float) -> int:
	var dist_x: float = abs(x_difference_calc())
	var dist_y: float = target.global_position.y - owner.global_position.y
	var p_vel_y: float = target.velocity.y
	
	var p_input_dir: float = target.controller.get_movement_direction() if target.get("controller") else 0.0
	var p_moving_toward: float = p_input_dir * -dir_to_target 
	
	var p_combo: float = float(target.combo_step) if target.get("combo_step") != null else 0.0
	var p_hp: float = target.health
	var e_hp: float = owner.health
	var e_state: float = float(owner.current_state)
	var e_atk: float = float(int(owner.is_attacking))
	var e_def: float = float(int(owner.is_defending))

	var input_vector = [
		dist_x / 100.0, dist_y / 100.0, p_vel_y / 100.0, p_moving_toward / 100.0, 
		p_combo / 100.0, p_hp / 100.0, e_hp / 100.0, e_state / 100.0, e_atk / 100.0, e_def / 100.0
	]

	var A0 = input_vector
	var A1 = relu_layer(mat_mul_add(weights[1], A0, biases[1]))
	var A2 = relu_layer(mat_mul_add(weights[2], A1, biases[2]))
	var Z3 = mat_mul_add(weights[3], A2, biases[3])
	
	var highest_val = Z3[0]
	var best_index = 0
	for i in range(1, Z3.size()):
		if Z3[i] > highest_val:
			highest_val = Z3[i]
			best_index = i
			
	return best_index

func execute_counter_strategy(prediction: int, dir_to_target: float, distance: float) -> void:
	if owner.is_on_wall() and owner.is_on_floor():
		jump_pressed = true

	match prediction:
		1: # prediction - incoming light attack
			if distance < attack_range + 20:
				defend_pressed = true
				direction = 0.0
			else:
				direction = -dir_to_target
				
		2: # prediction - incoming heavy attack
			direction = dir_to_target
			if distance <= attack_range:
				direction = 0.0
				try_attack(true)
				
		3: # prediction - player will block
			direction = dir_to_target
			if owner.is_on_floor() and distance < 100:
				jump_pressed = true
			if distance <= attack_range + 10:
				direction = 0.0
				try_attack(false)
				
		4: # prediction - player will jump
			if distance < 80:
				direction = -dir_to_target
				run_pressed = true
			else:
				direction = dir_to_target
				
		5, 7: # prediction - player is active
			direction = dir_to_target
			if distance <= attack_range + 34:
				direction = 0.0
				try_attack(false, true)
				
		6, 0: # prediction - player is passive
			direction = dir_to_target
			run_pressed = (distance > 100)
			if distance <= attack_range:
				direction = 0.0
				try_attack()

func try_attack(force_light: bool = false, force_heavy: bool = false) -> void:
	if jump_pressed:
		return
		
	if owner.has_method("is_state_jump") and owner.is_state_jump():
		if owner.velocity.y < -50.0: # Still moving up too fast
			return
		
	if attack_cooldown <= 0:
		attack_cooldown = randf_range(0.2, 0.5) # randomness to make game fairer for player
		if force_light:
			light_pressed = true
		elif force_heavy:
			heavy_pressed = true
		else:
			if randf() > 0.6:
				heavy_pressed = true
			else:
				light_pressed = true

func x_difference_calc() -> float:
	return target.global_position.x - owner.global_position.x

func mat_mul_add(W: Array, X: Array, B: Array) -> Array:
	var output = []
	for i in range(W.size()):
		var sum = 0.0
		for j in range(X.size()):
			sum += float(W[i][j]) * float(X[j])
		sum += float(B[i][0])
		output.append(sum)
	return output

func relu_layer(arr: Array) -> Array:
	var output = []
	for val in arr:
		output.append(max(0.0, val))
	return output

func get_movement_direction() -> float:
	return direction

func wants_jump() -> bool:
	return jump_pressed

func wants_run() -> bool:
	return run_pressed

func wants_light_attack() -> bool:
	return light_pressed

func wants_heavy_attack() -> bool:
	return heavy_pressed

func wants_defend() -> bool:
	return defend_pressed
