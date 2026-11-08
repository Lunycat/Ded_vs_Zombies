extends Node3D
class_name Gun

@export var shot_coldown: float = 0.6

@onready var _marker: Marker3D = $Marker3D

const BULLET_SCENE: Resource = preload("res://scenes/bullets/bullet.tscn")

func shoot(target: Vector3) -> void:
	var muzzle: Vector3 = _marker.global_position
	var direction: Vector3 = (target - muzzle).normalized()
	var bullet: Bullet = BULLET_SCENE.instantiate()
	bullet.configure(muzzle, direction)
	get_tree().current_scene.add_child(bullet)
