extends CharacterBody3D

# Player Nodes
@onready var head = %Head
@onready var camera = %Head/Camera3D

# Extra Variables
const SENSITIVITY = 0.003
var gravity = 10.5

# Window Size: 304/177
# Stretch Mode: Viewport

# Head Bob Variables
const BOB_FREQUENCY = 1.0
const BOB_AMPLITUDE = 0.15
var bob_time = 0.0

# Strafe Variables
const STRAFE_ANGLE = 2.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	
	# Exit Game
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Mouse Looking
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Head Bob
	bob_time += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _head_bob(bob_time)
	
	# Strafe Tilt
	if input_dir.x > 0:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(-STRAFE_ANGLE), delta * 7)
	elif input_dir.x < 0:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(STRAFE_ANGLE), delta * 7)
	else:
		head.rotation.z = lerp_angle(head.rotation.z, deg_to_rad(0), delta * 7)

	move_and_slide()


func _head_bob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	return pos
