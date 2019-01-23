extends CanvasLayer

func _ready():
	pass


func set_name(text):
	$YourName.text = text


func set_health(value):
	$HealthBar.value = value


func set_posion_count(count):
	assert(count < 4)
	assert(count >= 0)
	
	if count >= 1:
		$TexturePosion1.show()
	else:
		$TexturePosion1.hide()
	
	if count >= 2:
		$TexturePosion2.show()
	else:
		$TexturePosion2.hide()
	
	if count >= 3:
		$TexturePosion3.show()
	else:
		$TexturePosion3.hide()


func set_bullet(level):
	if level == 1:
		$TextureBullet1.show()
		$TextureBullet2.hide()
		$TextureBullet3.hide()
	if level == 2:
		$TextureBullet1.hide()
		$TextureBullet2.show()
		$TextureBullet3.hide()
	if level == 3:
		$TextureBullet1.hide()
		$TextureBullet2.hide()
		$TextureBullet3.show()

