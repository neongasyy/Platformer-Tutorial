extends Node2D

const SPEED = 40
const ATTACK_DAMAGE = 1
const ATTACK_COOLDOWN = 1.0 # seconds between hits while in contact with player

var direction = 1
var attack_ready: bool = true

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true

	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * SPEED * delta
	
func _on_attack_area_body_entered(body: Node2D) -> void:
	_try_attack(body)
	
func _try_attack(body: Node2D) -> void:
	if not attack_ready:
		return
	if not (body.is_in_group("player") and body.has_method("take_damage")):
		return
	body.take_damage(ATTACK_DAMAGE)
	attack_ready = false
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	attack_ready = true
	# re-check overlap in case player is still standing in the area
	if attack_area.get_overlapping_bodies().has(body):
		_try_attack(body)
		
