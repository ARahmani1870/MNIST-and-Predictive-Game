extends Node

func get_movement_direction() -> float:
	return Input.get_axis("move_left", "move_right")

func wants_jump() -> bool:
	return Input.is_action_just_pressed("jump")

func wants_run() -> bool:
	return Input.is_action_pressed("run")

func wants_light_attack() -> bool:
	return Input.is_action_just_pressed("lightAttack")

func wants_heavy_attack() -> bool:
	return Input.is_action_just_pressed("heavyAttack")

func wants_defend() -> bool:
	return Input.is_action_pressed("defend")
