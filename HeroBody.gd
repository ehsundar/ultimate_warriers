extends KinematicBody2D

export (int) var run_speed = 200
export (int) var jump_speed = 400
export (int) var gravity = 1200
export (int) var reload_duration = 1500
export (int) var ladder_speed = 200

var BulletSmall = preload("BulletSmall.tscn")
var BulletMedium = preload("BulletMedium.tscn")
var BulletLarge = preload("BulletLarge.tscn")
var CurrentBullet = BulletSmall

var velocity = Vector2()
var jumping = false
var climbing = false
var health = 100
var head = "right"
var current_state = "stand"
var last_shoot = 0
var last_update = 0


func _ready():
	position += Vector2(20, 100)


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
		
		velocity.x = 0
		
		var on_bottom = get_parent().on_bottom_ladder
		var on_top = get_parent().on_top_ladder
	
		var right = Input.is_action_pressed('ui_right')
		var left = Input.is_action_pressed('ui_left')
		var jump = Input.is_action_pressed('ui_up')
		var crouch = Input.is_action_just_pressed('ui_down')
		var cheat_up_weapon = Input.is_action_just_pressed("cheat_upgrade_weapon")
		var select = Input.is_action_just_pressed("ui_select")
		
		if climbing:
			jump = Input.is_action_pressed("ui_up")
			crouch = Input.is_action_pressed('ui_down')
			

		if not on_top and not on_bottom:
			# far from  any ladder
			climbing = false

			if jump and is_on_floor():
				jumping = true
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
		else:
			# near ladder!
			if climbing:
				# we're on ladder
				if jump:
					if on_top and not on_bottom:
						climbing = false
						jumping = true
					position += Vector2(0, -ladder_speed) * delta
				if crouch:
					position += Vector2(0, ladder_speed) * delta
			else:
				# standing on top or bottom of ladder
				if on_top:
					# we're just standing on top
					if crouch:
						climbing = true
						velocity.y = 0
						position += Vector2(0, ladder_speed) * delta
					else:
						if jump and is_on_floor():
							jumping = true
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
				else:
					# we're standing on bottom of ladder
					if jump:
						climbing = true
						jumping = false
						set_state("ladder")
						position += Vector2(0, -ladder_speed) * delta
		
		if cheat_up_weapon:
			upgrade_weapon()
		
		if select:
			shoot()
			
	update_state()


func update_state():
	if health == 0:
		set_state("dead")
		return
		
	if climbing:
		set_state("ladder")
		return
	
	if jumping:
		if velocity.y < 0:
			set_state("jump_up")
		else:
			set_state("jump_down")
		return
	
	if is_on_floor():
		if velocity.length() < 0.01:
			if OS.get_ticks_msec() - last_shoot > 400:
				set_state("stand")
		else:
			if OS.get_ticks_msec() - last_shoot > 400:
				set_state("walk")


func set_state(new_state):
	current_state = new_state
	$AnimatedSprite.play(current_state)


func shoot():
	if jumping:
		return
	if OS.get_ticks_msec() - last_shoot < reload_duration:
		return
	last_shoot = OS.get_ticks_msec()
	
	$AnimatedSprite.play("attack")
	var bullet = CurrentBullet.instance()
	bullet.start(position, head)
	get_parent().add_child(bullet)

func hit(damage):
	print("damage ", damage)
	health -= damage
	if health <= 0:
		health = 0
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
	health = 0


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
	
	