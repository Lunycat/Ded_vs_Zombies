extends Node3D
class_name Bullet

@export var damage: int
@export var speed: int = 40
@export var max_distance: int = 100

var _start_position: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO
var _damage: int = 0

func _ready() -> void:
	global_position = _start_position

func _physics_process(delta: float) -> void:
	if global_position.distance_to(_start_position) >= max_distance:
		queue_free()
		return
	
	var prev_position: Vector3 = global_position
	var next_position: Vector3 = global_position + _direction * delta * speed
	
	var collision: Dictionary = _get_next_collision(prev_position, next_position)
	
	if collision.is_empty():
		global_position = next_position
		return
	
	var collider = collision.collider
	var hit_point = collision.position
	
	if collider is Zombie:
		collider.take_damage(_damage)
		global_position = hit_point
	elif collider is StaticBody3D:
		global_position = hit_point
	
	queue_free()

func _get_next_collision(start: Vector3, end: Vector3) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		start,
		end,
		13,
		[self]
	)
	var result: Dictionary = space_state.intersect_ray(query)
	
	return result

func configure(start: Vector3, direction: Vector3) -> void:
	_start_position = start
	_direction = direction
