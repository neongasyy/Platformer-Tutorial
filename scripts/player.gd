extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -225.0
const ROLL_SPEED = 250.0
const ROLL_DURATION = 0.3 # seconds
const MAX_JUMPS = 2
const INVINCIBILITY_DURATION = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

@export var max_health: int = 3
var health: int = max_health
var invincible: bool = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead: bool = false
var is_rolling: bool = false
var roll_timer: float = 0.0
var facing_direction: float = 1.0
var jump_count: int = 0

signal health_changed(current: int, max: int)

func _ready() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0 # reset jumps upon landing

	# Rolling check.
	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
		move_and_slide()
		return
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# Get the input direction. (left: -1, 0, right:1)
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		facing_direction = direction
	
	# Handle rolling.
	if Input.is_action_just_pressed("roll") and is_on_floor():
		start_roll()
		return
	
	# Flip player model.
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations.
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func start_roll() -> void:
	is_rolling = true
	roll_timer = ROLL_DURATION
	velocity.x = facing_direction * ROLL_SPEED
	animated_sprite.play("roll")
	
func take_damage(amount: int = 1) -> void:
	if invincible or is_dead:
		return
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()
	else:
		invincible = true
		modulate = Color(1, 0.4, 0.4) # quick red flash
		await get_tree().create_timer(INVINCIBILITY_DURATION).timeout
		modulate = Color(1, 1, 1)
		invincible = false
		
func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		show_death_text()
		Engine.time_scale = 0.5
		await get_tree().create_timer(1.0).timeout
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()

func show_death_text() -> void:
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	var label = Label.new()
	label.text = "You Died"
	label.modulate = Color.RED
	label.add_theme_font_size_override("font_size", 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(label)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	animated_sprite.play("death")
