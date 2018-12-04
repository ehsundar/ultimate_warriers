extends KinematicBody2D

export (int) var run_speed = 200
export (int) var jump_speed = 400
export (int) var gravity = 1200
export (Vector2) var spawn_position = Vector2(100, 100)

var BulletSmall = preload("BulletSmall.tscn")
var BulletMedium = preload("BulletMedium.tscn")
var BulletLarge = preload("BulletLarge.tscn")
var CurrentBullet = BulletSmall
var reload_duration = 1000

var velocity = Vector2()
var jumping = false
var health = 100
var head = "right"
var current_state = "stand"
var last_shoot = 0
var last_update = 0
var hero_killed = true

var delegated_movement = false;


func _ready():
	spawn()


func _process(delta):
	if head == "left":
		$AnimatedSprite.flip_h = true
	if head == "right":
		$AnimatedSprite.flip_h = false
	
	if OS.get_ticks_msec() - last_update > 100:
		last_update = OS.get_ticks_msec()
		update()


func _physics_process(delta):	
	if health > 0:
		var right = Input.is_action_pressed('ui_right')
		var left = Input.is_action_pressed('ui_left')
		var jump = Input.is_action_pressed('ui_up')
		var crouch = Input.is_action_just_pressed('ui_down')
		var cheat_up_weapon = Input.is_action_just_pressed("cheat_upgrade_weapon")
		var select = Input.is_action_just_pressed("ui_select")
			
		if not delegated_movement:
			velocity.x = 0
			
			if jump and is_on_floor():
				velocity.y = -jump_speed
			else:
				if is_on_floor():
					jumping = false
				
			if right:
				velocity.x += run_speed
				head = "right"
			if left:
				velocity.x -= run_speed
				head = "left"
			
			velocity.y += gravity * delta
			velocity = move_and_slide(velocity, Vector2(0, -1))
	
		if cheat_up_weapon:
			upgrade_weapon()
		
		if select:
			shoot()
	else:
		# health negative
		kill()
	
	update_state()


func update_state():
	if health == 0:
		set_state("dead")
		return
		
	if velocity.y != 0 and not delegated_movement:
		if velocity.y < 0:
			set_state("jump_up")
		else:
			set_state("jump_down")
		return
	
	if is_on_floor() and not delegated_movement:
		if OS.get_ticks_msec() - last_shoot > 400:
			if velocity.length() < 0.01:
				set_state("stand")
			else:
				set_state("walk")
			return


func set_state(new_state):
	if current_state != new_state:
		current_state = new_state
		print(new_state)
		$AnimatedSprite.play(current_state)


func shoot():
	if OS.get_ticks_msec() - last_shoot < reload_duration:
		return
	last_shoot = OS.get_ticks_msec()
	
	set_state("attack")
	var bullet = CurrentBullet.instance()
	bullet.start(position, head)
	get_parent().add_child(bullet)
	reload_duration = bullet.reload_duration


func hit(damage):
	print("damage ", damage)
	health -= damage
	if health <= 0:
		kill()
	update()


func _draw():
	set_as_toplevel(true)
	var draw_bar_x = -15
	var draw_bar_y = -30
	draw_rect(Rect2(draw_bar_x, draw_bar_y, 30, 3), Color(1.0, 0.0, 0.0), false)
	draw_rect(Rect2(draw_bar_x, draw_bar_y, health * 3 / 10, 3), Color(1.0, 0.0, 0.0), true)
	
	
	var time_rem = (OS.get_ticks_msec() - last_shoot) * 30 / reload_duration
	if time_rem > 30:
		time_rem = 30
	draw_bar_y += 5
	draw_rect(Rect2(draw_bar_x, draw_bar_y, 30, 3), Color(0.0, 1.0, 0.0), false)
	draw_rect(Rect2(draw_bar_x, draw_bar_y, time_rem, 3), Color(0.0, 1.0, 0.0), true)


func kill():
	if hero_killed:
		return
	hero_killed = true
	health = 0
	$RespawnTimer.start()


func spawn():
	if not hero_killed:
		return
	hero_killed = false
	global_position = spawn_position
	health = 100


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


func set_delegated_movement(value):
	delegated_movement = value


func hero_body_verify():
	"""
	this method created just to be checked by has_method() method
	"""
	pass
