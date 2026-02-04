extends Area2D

@export var speed: float = 1000.0
@export var damage: float = 10.0

# reference to the node that fired this projectile
var shooter: Node = null

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

	# ignore collisions with the shooter
	if shooter and body == shooter:
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("IcePlayer touché par la FireBall !")
	
	queue_free()



func apply_counter(multiplier: float, size_mult: float) -> void:
	# amplify damage and visual size when player used counter-attack
	damage *= multiplier
	scale *= size_mult

	# trigger a camera shake if there's a camera_shaker in the scene
	var tree = get_tree()
	if tree == null:
		tree = Engine.get_main_loop() # fallback if node isn't in the scene tree yet
	var shaker = null
	if tree and tree.has_method("get_first_node_in_group"):
		shaker = tree.get_first_node_in_group("camera_shakers")
	if shaker and shaker.has_method("shake"):
		# stronger shake for counter (scale with size_mult)
		shaker.shake(12.0 * size_mult, 0.24 * size_mult)
