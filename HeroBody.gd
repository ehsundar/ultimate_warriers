extends KinematicBody2D

export (int) var default_run_speed = 200
export (int) var default_jump_speed = 400
export (int) var default_gravity = 1200
export (Vector2) var default_spawn_position = Vector2(100, 100)

var run_speed = default_run_speed
var jump_speed = default_jump_speed
var gravity = default_gravity
var spawn_position = default_spawn_position


var BulletSmall = preload("BulletSmall.tscn")
var BulletMedium = preload("BulletMedium.tscn")
var BulletLarge = preload("BulletLarge.tscn")
var CurrentBullet = BulletSmall
var reload_duration = 1000

var velocity = Vector2()
var jumping = false
var health = 100
var head = "right"
var current_animation_state = "stand"
var last_shoot = 0
var last_update = 0
var hero_killed = true
var can_shoot = true
var in_cave = false
var in_front_of_cave = null #Vector2

var delegated_movement = false;

slave var slave_velocity = Vector2();
slave var slave_position = Vector2();
slave var slave_animation = "";


func _ready():
	spawn()
	update()


func _process(delta):
	if head == "left":
		$AnimatedSprite.flip_h = true
	if head == "right":
		$AnimatedSprite.flip_h = false
	
	if OS.get_ticks_msec() - last_update > 100:
		last_update = OS.get_ticks_msec()
		update()


func _physics_process(delta):
	if hero_killed:
		return
	
	if is_network_master():
		var right = Input.is_action_pressed('ui_right')
		var left = Input.is_action_pressed('ui_left')
		var up = Input.is_action_pressed('ui_up')
		var down = Input.is_action_just_pressed('ui_down')
		var cheat_up_weapon = Input.is_action_just_pressed("cheat_upgrade_weapon")
		var select = Input.is_action_just_pressed("ui_select")
			
		if not delegated_movement:
			velocity.x = 0
			
			if up:
				if is_on_floor():
					if in_front_of_cave != null:
						enter_cave(in_front_of_cave)
					else:
						velocity.y = -jump_speed
			elif is_on_floor():
				jumping = false
				
			if down:
				if in_cave:
					exit_from_cave()
				
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
			
		rset("slave_position", position)
		rset("slave_velocity", velocity)
	else:
		position = slave_position
		velocity = slave_velocity
	
	if health <= 0 and not hero_killed:
		rpc("kill")
	update_animation_state()


func set_player_name(player_name):
	get_node("label").text = player_name


func update_animation_state():
	if health <= 0:
		set_animation_state("dead")
		return
		
	if delegated_movement:
		set_animation_state("ladder")
		return
		
	if velocity.y != 0 and not delegated_movement:
		if velocity.y < 0:
			set_animation_state("jump_up")
		else:
			set_animation_state("jump_down")
		return
	
	if is_on_floor() and not delegated_movement:
		if OS.get_ticks_msec() - last_shoot > 400:
			if velocity.length() < 0.01:
				set_animation_state("stand")
			else:
				set_animation_state("walk")
				$AnimatedSprite.flip_h = velocity.x > 0
			return


sync func set_anim(state):
	current_animation_state = state
	$AnimatedSprite.play(current_animation_state)

func set_animation_state(state):
	if current_animation_state != state:
#		rpc("set_anim", new_animation_state)
		current_animation_state = state
		$AnimatedSprite.play(current_animation_state)


func shoot():
	if not can_shoot:
		return
		
	if OS.get_ticks_msec() - last_shoot < reload_duration:
		return
	last_shoot = OS.get_ticks_msec()
	
	set_animation_state("attack")
	var bullet = CurrentBullet.instance()
	bullet.start(position, head)
	get_parent().add_child(bullet)
	reload_duration = bullet.reload_duration


sync func apply_damage(damage):
	health -= damage
	if health <= 0:
		rpc("kill")
	update()

func hit(damage):
	rpc("apply_damage", damage)


func _draw():
	set_as_toplevel(true)
	if health < 0:
		health = 0
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


sync func kill():
	if hero_killed:
		return
	hero_killed = true
	health = 0
	$RespawnTimer.start()


sync func apply_spawn():
	hero_killed = false
	global_position = spawn_position
	health = 100

func spawn():
	rpc("apply_spawn")


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


sync func apply_delegated_mv(value):
	delegated_movement = value

func set_delegated_movement(value):
	rpc("apply_delegated_mv")


func hero_body_verify():
	"""
	this method created just to be checked by has_method() method
	"""
	pass


func enter_cave(cave_position):
	self.position = cave_position
	hide()
	disable_movement()
	disable_shooting()
	$CollisionShape2D.disabled = true
	in_cave = true
	
	
func exit_from_cave():
	show()
	enable_movement()
	enable_shooting()
	$CollisionShape2D.disabled = false
	in_cave = false
	
	
func disable_movement():
	run_speed = 0
	jump_speed = 0
	gravity = 0
	velocity = Vector2(0, 0)
	
	
func enable_movement():
	run_speed = default_run_speed
	jump_speed = default_jump_speed
	gravity = default_gravity
	

func disable_shooting():
	can_shoot = false
	pass
	
	
func enable_shooting():
	can_shoot = true
	pass