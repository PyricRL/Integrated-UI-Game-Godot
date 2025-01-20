extends CharacterBody3D

# Player Nodes
@onready var head = %Head
@onready var camera = %Head/Camera3D
@onready var standing_collision_shape = $StandingCollisionShape
@onready var crouching_collision_shape = $CrouchingCollisionShape
@onready var ray_cast_3d = $RayCast3D
@onready var coyote_timer = $CoyoteTimer

const SENSITIVITY = 0.003

# Jump Variables
const JUMP_VELOCITY = 5
var gravity = 10.5

# Window Size: 304/177
# Stretch Mode: Viewport

# Head Bob Variables
const BOB_FREQUENCY = 1.0
const BOB_AMPLITUDE = 0.15
var bob_time = 0.0

# States
var walking = false
var sprinting = false
var crouching = false
var sliding = false

# Speed Variables
const SPRINT_SPEED = 12.0
const CROUCH_SPEED = 3.5
const WALK_SPEED = 6.0
var speed

# Crouch Variables
var crouching_depth = -1.0

# Slide Variables
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

# Strafe Variables
const STRAFE_ANGLE = 2.5

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 15

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
	
	# Get Movement Input
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Handle Movement States
	
	# Gravity
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Crouching and Sliding
	
	if Input.is_action_pressed("crouch") or sliding:
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		speed = CROUCH_SPEED
		
		head.position.y = lerp(head.position.y, 2.0 + crouching_depth, delta * 7.0)
		camera.fov = lerp(camera.fov, BASE_FOV - FOV_CHANGE, delta * 8.0)
		
		print("Crouching depth is: " + str(head.position.y))
		
		# Slide Begin
		
		if sprinting and input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			
		# Handle States
		
		walking = false
		sprinting = false
		crouching = true
	
	# Handle Slide Cancel
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and sliding:
		velocity.y = JUMP_VELOCITY
		
		# Handle States
		
		walking = false
		sprinting = false
		crouching = true
		sliding = false
		
	elif not ray_cast_3d.is_colliding():
		
		# Jumping
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		# Standing
		
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		print("standing")
		
		head.position.y = lerp(head.position.y, 1.8, delta * 7.0)
		
		# Sprinting and Walking
		
		if Input.is_action_pressed("sprint"):
			speed = SPRINT_SPEED
			camera.fov = lerp(camera.fov, BASE_FOV + FOV_CHANGE, delta * 8.0)
			
			# Handle States
		
			walking = false
			sprinting = true
			crouching = false
			
		elif Input.is_action_just_released("sprint"):
			coyote_timer.start()
			
			# Handle States
		
			walking = false
			sprinting = true
			crouching = false
			
		elif coyote_timer.is_stopped():
			speed = WALK_SPEED
			camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)
			
			# Handle States
		
			walking = true
			sprinting = false
			crouching = false
	
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Sliding
	
	if sliding:
		slide_timer -= delta
		direction = (head.transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		if slide_timer <= 0:
			sliding = false
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			if sliding:
				velocity.x = direction.x * (slide_timer + 0.4) * slide_speed
				velocity.z = direction.z * (slide_timer + 0.4) * slide_speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 10.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 10.0)
		
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


func _on_coyote_timer_timeout():
	# Handle States
		
	walking = true
	sprinting = false
	crouching = false
