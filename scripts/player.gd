extends CharacterBody3D
class_name Player

enum State {NORMAL, KNOCKBACK}

@export var max_distance_mouse: float = 50.0
@export var speed: float = 2.0
@export var max_health: int = 100
# Скорость гасания отталкивания
@export var knockback_friction: float = 13.0

@onready var _visual_pivot: Node3D = $VisualPivot
@onready var _gun: Gun = $VisualPivot/Gun

var _camera: Camera3D = null
var _health: int = 0;
var _knockback_velocity: Vector3 = Vector3.ZERO
var _current_state: State = State.NORMAL
var _attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_health = max_health
	_camera = get_viewport().get_camera_3d()
	_camera.call_deferred("look_at", self.global_position + Vector3(0, 1, 0))

func _physics_process(delta: float) -> void:
	_attack_timer -= delta
	var horizontal_speed: float;
	_move_activity(delta)
	
	if not is_on_floor():
		_use_gravity(delta)

	_change_state()
	_action_depending_on_state(delta, horizontal_speed)
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Zombie and horizontal_speed > 3:
			collider.take_damage(100)

func _use_gravity(delta: float) -> void:
	velocity += get_gravity() * delta

func _change_state() -> void:
	if _knockback_velocity.length() > 1:
		_current_state = State.KNOCKBACK
	else:
		_current_state = State.NORMAL

func _action_depending_on_state(delta: float, horizontal_speed: float) -> void:
	var friction_mul: float
	if not is_on_floor():
		friction_mul = 0.1
	elif Input.is_action_pressed("space"):
		friction_mul = 0.7
	else:
		friction_mul = 0.3

	if _current_state == State.KNOCKBACK:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		
		horizontal_speed = Vector2(velocity.x, velocity.z).length()
		print(horizontal_speed)
		
		_knockback_velocity = _knockback_velocity.move_toward(
			Vector3.ZERO, knockback_friction * friction_mul * delta
		)
	elif _current_state == State.NORMAL:
		_knockback_velocity = Vector3.ZERO
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		# Компенсация сжатия по Z: камера наклонена, поэтому 1 м в мире по Z
		# на экране выглядит короче. Делим input_dir.y на sin(угол подъёма камеры),
		# чтобы скорость на экране была одинаковой во всех направлениях.
		var sin_phi: float = -_camera.global_transform.basis.y.z
		sin_phi = maxf(sin_phi, 0.01)  # защита от деления на 0, если камера горизонтальна
		var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y / sin_phi)
		
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * speed, speed * 4 * delta)
			velocity.z = move_toward(velocity.z, direction.z * speed, speed * 4 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, speed * friction_mul * delta)
			velocity.z = move_toward(velocity.z, 0, speed * friction_mul * delta)

func _move_activity(delta: float) -> void:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_position)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_position)
	var ray_end: Vector3 = ray_origin + ray_normal * max_distance_mouse
	var target: Vector3 = _get_ground_position(ray_origin, ray_end)
	
	if target == Vector3.INF:
		return
	
	if Input.is_action_pressed("attack") and _attack_timer <= 0.0:
		_attack(target)
		_attack_timer = _gun.shot_coldown
	
	# Расстояние от персонажа до метки на экране
	var to_target: Vector3 = target - _visual_pivot.global_position
	to_target.y = 0

	if to_target.length_squared() < 0.01:
		return
	
	# Насколько градусов нужно повернуться по вертикальной оси
	_visual_pivot.rotation.y = atan2(-to_target.x, -to_target.z)

func _get_ground_position(ray_origin: Vector3, ray_end: Vector3) -> Vector3:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		5,
		[self]
	)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result:
		return result.position
	
	return Vector3.INF

func _attack(target: Vector3) -> void:
	_gun.shoot(target)

func _die() -> void:
	queue_free()

func take_damage(damage: int) -> void:
	_health -= damage
	if _health <= 0:
		_die()

func apply_knockback(direction: Vector3, force: float, toss: float) -> void:
	direction.y = 0
	_knockback_velocity = direction.normalized() * force
	velocity.y = toss
