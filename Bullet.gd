extends KinematicBody2D

export var damage = 20
export var speed = 750
export var max_range = 400
var velocity = Vector2()
var direction = ""
var total_movement = 0

func start(pos, dir):
	if dir == "left":
		velocity = Vector2(-1 * speed, 0)
		pos += Vector2(-20, 0)
	if dir == "right":
		velocity = Vector2(1 * speed, 0)
		pos += Vector2(20, 0)
		
	position = pos
	direction = dir

func _physics_process(delta):
	if total_movement > max_range:
		queue_free()
	else:
		total_movement += (velocity * delta).length()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
			
		if collision.collider.has_method("hit"):
			collision.collider.hit(damage)
			queue_free()


func reduce_damage(value):
	damage -= value
	print(damage)
	if damage <= 0:
		queue_free()
