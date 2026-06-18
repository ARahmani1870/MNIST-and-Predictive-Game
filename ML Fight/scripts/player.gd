extends CharacterBody2D

const HIT_STUN_DURATION: float = 0.2
const BLOCK_STUN_DURATION: float = 0.5
const BLOCK_BREAK_STUN_DURATION: float = 0.8
const JUMP_ATTACK_MULTIPLIER: float = 1.6
const RUN_ATTACK_MULTIPLIER: float = 1.25

enum State { IDLE, WALK, RUN, JUMP }

const walkSpeed = 130
const runSpeedBoost = 120
const airSpeedMultiplier = 0.67
const JUMP_VELOCITY = -300.0

var SPEED = walkSpeed
var current_state = State.IDLE

var is_attacking: bool = false
var combo_step: int = 0
var advance_combo: bool = false

var is_defending: bool = false
var stun_timer: float = 0.0
var health: float = 100.0

var is_dead: bool = false
var is_hurt: bool = false

@export var controller: Node
@export var ai_target: Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var combat_pivot: Node2D = $Combat

@onready var jump_sound: AudioStreamPlayer2D = get_node_or_null("JumpSound")
@onready var hurt_sound: AudioStreamPlayer2D = get_node_or_null("HurtSound")
@onready var death_sound: AudioStreamPlayer2D = $DeathSound

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	
	if controller and "target" in controller:
		controller.target = ai_target

func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if stun_timer > 0:
		stun_timer -= delta
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0, walkSpeed)
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction: float = controller.get_movement_direction()

	if direction > 0:
		animated_sprite_2d.flip_h = false
		combat_pivot.scale.x = 1
	elif direction < 0:
		animated_sprite_2d.flip_h = true
		combat_pivot.scale.x = -1

	handle_actions()

	if not is_hurt:
		match current_state:
			State.IDLE:
				idle_state(direction)
			State.WALK:
				walk_state(direction)
			State.RUN:
				run_state(direction)
			State.JUMP:
				jump_state(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, walkSpeed)

	move_and_slide()

func handle_actions() -> void:
	if is_hurt:
		return

	is_defending = controller.wants_defend()

	if is_defending:
		if is_attacking:
			end_attack()
		animation_player.play("defend")
		velocity.x = move_toward(velocity.x, 0, walkSpeed)
		return

	if controller.wants_light_attack():
		if not is_attacking:
			start_attack("attack1", 1)
		elif is_attacking and combo_step == 1:
			advance_combo = true
	elif controller.wants_heavy_attack():
		if not is_attacking:
			start_attack("attack3", 3)

func take_damage(amount: float, attacker: Node, is_jump_attack: bool, is_run_attack: bool) -> void:
	if is_dead:
		return

	if is_defending:
		var dir_to_attacker = sign(attacker.global_position.x - global_position.x)
		var my_facing_dir = sign(combat_pivot.scale.x)
		var valid_block = (dir_to_attacker == 0 or dir_to_attacker == my_facing_dir)

		if valid_block:
			if is_jump_attack:
				apply_stun(BLOCK_BREAK_STUN_DURATION)
			else:
				if attacker.has_method("apply_stun"):
					attacker.apply_stun(BLOCK_STUN_DURATION)
			return

	var final_amount = amount
	if is_jump_attack:
		final_amount *= JUMP_ATTACK_MULTIPLIER
	elif is_run_attack:
		final_amount *= RUN_ATTACK_MULTIPLIER
		
	health -= final_amount

	if health <= 0:
		die()
	else:
		apply_stun(HIT_STUN_DURATION)

func apply_stun(duration: float) -> void:
	stun_timer = duration
	is_attacking = false
	is_defending = false
	combo_step = 0
	advance_combo = false
	is_hurt = false
	animation_player.play("hurt")
	if hurt_sound and name == "Player":
		hurt_sound.play()

func die() -> void:
	is_dead = true
	is_attacking = false
	is_defending = false
	is_hurt = false
	stun_timer = 0.0
	animation_player.play("death")
	death_sound.play()
	velocity.x = 0
	
	if name == "Player":
		GameState.enemy_wins += 1
	else:
		GameState.player_wins += 1
	
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func start_attack(anim_name: String, step: int) -> void:
	is_attacking = true
	combo_step = step
	advance_combo = false
	animation_player.play(anim_name)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "attack1":
		if advance_combo:
			start_attack("attack2", 2)
		else:
			end_attack()
	elif anim_name == "attack2" or anim_name == "attack3":
		end_attack()
	elif anim_name == "hurt":
		is_hurt = false
		end_attack()

func end_attack() -> void:
	is_attacking = false
	combo_step = 0
	advance_combo = false

func idle_state(direction: float) -> void:
	if not is_attacking and not is_defending and not is_hurt:
		animation_player.play("idle")
	
	velocity.x = move_toward(velocity.x, 0, walkSpeed)
	
	if not is_on_floor():
		current_state = State.JUMP
	elif controller.wants_jump() and not is_attacking and not is_defending and not is_hurt:
		velocity.y = JUMP_VELOCITY
		if name == "Player":
			jump_sound.play()
		current_state = State.JUMP
	elif direction != 0:
		if controller.wants_run():
			current_state = State.RUN
		else:
			current_state = State.WALK

func walk_state(direction: float) -> void:
	if not is_attacking and not is_defending and not is_hurt:
		animation_player.play("walk")
	
	SPEED = walkSpeed
	velocity.x = direction * SPEED

	if not is_on_floor():
		current_state = State.JUMP
	elif controller.wants_jump() and not is_attacking and not is_defending and not is_hurt:
		velocity.y = JUMP_VELOCITY
		if name == "Player":
			jump_sound.play()
		current_state = State.JUMP
	elif direction == 0:
		current_state = State.IDLE
	elif controller.wants_run():
		current_state = State.RUN

func run_state(direction: float) -> void:
	if not is_attacking and not is_defending and not is_hurt:
		animation_player.play("run")
	
	SPEED = walkSpeed + runSpeedBoost
	velocity.x = direction * SPEED

	if not is_on_floor():
		current_state = State.JUMP
	elif controller.wants_jump() and not is_attacking and not is_defending and not is_hurt:
		velocity.y = JUMP_VELOCITY
		if name == "Player":
			jump_sound.play()
		current_state = State.JUMP
	elif direction == 0:
		current_state = State.IDLE
	elif not controller.wants_run():
		current_state = State.WALK

func jump_state(direction: float) -> void:
	if not is_attacking and not is_defending and not is_hurt:
		animation_player.play("jump")
	
	SPEED = (walkSpeed + int(controller.wants_run()) * runSpeedBoost) * airSpeedMultiplier
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_on_floor():
		if direction == 0:
			current_state = State.IDLE
		elif controller.wants_run():
			current_state = State.RUN
		else:
			current_state = State.WALK

func is_state_jump() -> bool:
	return current_state == State.JUMP

func is_state_run() -> bool:
	return current_state == State.RUN
