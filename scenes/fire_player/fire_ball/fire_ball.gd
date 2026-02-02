extends RigidBody2D

@export var speed = 1000
@export var damage = 10

@export var deleteTimer: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = Vector2(speed, 0).rotated(rotation)
	await get_tree().create_timer(deleteTimer).timeout
	if is_instance_valid(self):
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body):
	print("Touche : ", body.name)
	queue_free()
