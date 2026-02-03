extends Area2D

@export var speed: float = 1000.0
@export var damage: float = 10.0

@export var deleteTimer: float = 2.0

@onready var animated_sprite = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	animated_sprite.play("rotate")
	
	await get_tree().create_timer(deleteTimer).timeout
	if is_instance_valid(self):
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta


func _on_body_entered(body):
	print("Touche : ", body.name)

	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("FirePlayer touché par la IceBall !")

	queue_free()
