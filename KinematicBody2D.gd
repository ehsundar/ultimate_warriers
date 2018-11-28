extends KinematicBody2D

export (int) var run_speed = 200
export (int) var jump_speed = 400
export (int) var gravity = 1200
export (int) var reload_duration = 1500

var BulletSmall = preload("BulletSmall.tscn")
var BulletMedium = preload("BulletMedium.tscn")
var BulletLarge = preload("BulletLarge.tscn")
var CurrentBullet = BulletSmall

var velocity = Vector2()
var jumping = false
var health = 100
var head = "right"
var last_shoot = 0
var last_update = 0


func get_input():
	velocity.x = 0
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_up')

	if jump and is_on_floor():
		jumping = true
		velocity.y = -jump_speed
	if right:
		velocity.x += run_speed
		head = "right"
	if left:
		velocity.x -= run_speed
		head = "left"
	
	if Input.is_action_just_pressed("cheat_upgrade_weapon"):
		upgrade_weapon()
	
	if Input.is_action_just_pressed("ui_select"):
		shoot()


func _process(delta):
	if head == "left":
		$AnimatedSprite.flip_h = true
	if head == "right":
		$AnimatedSprite.flip_h = false
	
	if OS.get_ticks_msec() - last_update > 100:
		last_update = OS.get_ticks_msec()
		update()


func _physics_process(delta):	
	if is_on_floor():
		if jumping:
			jumping = false
		
		if velocity.length() < 0.01:
			$AnimatedSprite.play("stand")
		else:
			$AnimatedSprite.play("walk")
	else:
		if jumping:
			if velocity.y < 0:
				$AnimatedSprite.play("jump_up")
			else:
				$AnimatedSprite.play("jump_down")
				
	get_input()
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0, -1))


func shoot():
	if OS.get_ticks_msec() - last_shoot < reload_duration:
		return

	last_shoot = OS.get_ticks_msec()
	
	print("SHOOT")
	var bullet = CurrentBullet.instance()
	bullet.start(global_position, head)
	get_parent().add_child(bullet)

func hit(damage):
	print("HIT")
	health -= damage
	if health < 0:
		queue_free()
	update()


func _draw():
	set_as_toplevel(true)
	var draw_bar_x = -25
	var draw_bar_y = -40
	draw_rect(Rect2(draw_bar_x, draw_bar_y, 50, 5), Color(1.0, 0.0, 0.0), false)
	draw_rect(Rect2(draw_bar_x, draw_bar_y, health / 2, 5), Color(1.0, 0.0, 0.0), true)
	
	var time_rem = (OS.get_ticks_msec() - last_shoot) * 50 / reload_duration
	if time_rem > 50:
		time_rem = 50
	draw_bar_y += 10
	draw_rect(Rect2(draw_bar_x, draw_bar_y, 50, 5), Color(0.0, 1.0, 0.0), false)
	draw_rect(Rect2(draw_bar_x, draw_bar_y, time_rem, 5), Color(0.0, 1.0, 0.0), true)


func upgrade_weapon(level=1, absolute=false):
	if absolute:
		if level == 1:
			CurrentBullet = BulletSmall
			return
		if level == 2:
			CurrentBullet = BulletMedium
			return
		if level == 3:
			CurrentBullet = BulletLarge
			return
	else:
		if CurrentBullet == BulletSmall:
			CurrentBullet = BulletMedium
			return
		if CurrentBullet == BulletMedium:
			CurrentBullet = BulletLarge
			return
		if CurrentBullet == BulletLarge:
			return
		CurrentBullet = BulletSmall
	