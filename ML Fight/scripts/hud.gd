extends CanvasLayer

@export var player: CharacterBody2D
@export var enemy: CharacterBody2D

@onready var player_bar: HealthBarXControl = $PlayerHealthBar
@onready var enemy_bar: HealthBarXControl = $EnemyHealthBar
@onready var player_score: Label = $PlayerScore
@onready var enemy_score: Label = $EnemyScore

var last_player_health: float = 100.0
var last_enemy_health: float = 100.0

func _ready() -> void:
	if is_instance_valid(player):
		last_player_health = player.health
		player_bar.set_value(last_player_health, false)
		
	if is_instance_valid(enemy):
		last_enemy_health = enemy.health
		enemy_bar.set_value(last_enemy_health, false)
		
	if player_score: player_score.text = "PLAYER: " + str(GameState.player_wins)
	if enemy_score: enemy_score.text = "MODEL: " + str(GameState.enemy_wins)

func _process(_delta: float) -> void:
	if is_instance_valid(player) and player.health != last_player_health:
		last_player_health = player.health
		player_bar.set_value(last_player_health, true)
		
	if is_instance_valid(enemy) and enemy.health != last_enemy_health:
		last_enemy_health = enemy.health
		enemy_bar.set_value(last_enemy_health, true)
