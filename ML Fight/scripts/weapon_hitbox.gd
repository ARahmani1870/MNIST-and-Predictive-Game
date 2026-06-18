extends Area2D

@export var base_damage: float = 10.0
@export var headshot_multiplier: float = 2.0

var character: CharacterBody2D
var hit_enemies: Array[Node] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_sound: AudioStreamPlayer2D = get_node_or_null("HitSound")

func _ready() -> void:
	var current = get_parent()
	while current != null and not current is CharacterBody2D:
		current = current.get_parent()
		
	character = current
	
	if character != null:
		area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if collision_shape.disabled and hit_enemies.size() > 0:
		hit_enemies.clear()

func _on_area_entered(area: Area2D) -> void:
	var target_character = area.get_parent()
	while target_character != null and not target_character is CharacterBody2D:
		target_character = target_character.get_parent()
		
	if target_character == null or target_character == character:
		return
		
	if target_character in hit_enemies:
		return
		
	var is_jump_attack: bool = character.has_method("is_state_jump") and character.is_state_jump()
	var is_run_attack: bool = character.has_method("is_state_run") and character.is_state_run()

	if area.is_in_group("head"):
		var total_damage = base_damage * headshot_multiplier
		deal_damage(target_character, total_damage, character, is_jump_attack, is_run_attack)
		hit_enemies.append(target_character)
		
	elif area.is_in_group("body"):
		deal_damage(target_character, base_damage, character, is_jump_attack, is_run_attack)
		hit_enemies.append(target_character)

func deal_damage(target: Node, amount: float, attacker: Node, is_jump_attack: bool, is_run_attack: bool) -> void:
	if target.has_method("take_damage"):
		target.take_damage(amount, attacker, is_jump_attack, is_run_attack)
		if hit_sound:
			hit_sound.play()
