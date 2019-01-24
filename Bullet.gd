extends KinematicBody2D

export (int) var damage = 20
export (int) var speed = 750
export (int) var max_range = 400
export (int) var reload_duration = 1000
export (int) var upgrade_cost = 0

var velocity = Vector2()
var total_movement = 0


func start(pos, dir):
	if dir == data_types.LEFT:
		velocity = Vector2(-1 * speed, 0)
		pos += Vector2(-26, 0)
	if dir == data_types.RIGHT:
		velocity = Vector2(1 * speed, 0)
		pos += Vector2(26, 0)
		
	position = pos


func _physics_process(delta):
	if total_movement > max_range:
		queue_free()
	else:
		total_movement += (velocity * delta).length()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
		print(collision.collider)
			
		if collision.collider.has_method("hit"):
			collision.collider.hit(damage)
			queue_free()


func reduce_damage(value):
	damage -= value
	print(damage)
	if damage <= 0:
		queue_free()
