extends RigidBody2D

@export var speed = 800
@export var damage = 10



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = Vector2(speed, 0).rotated(rotation)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body):
	print("Touche : ", body.name)
	queue_free()
