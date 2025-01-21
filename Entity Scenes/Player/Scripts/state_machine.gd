extends Node

@onready var player = $".."
@onready var standing_collision_shape = $"../StandingCollisionShape"
@onready var crouching_collision_shape = $"../CrouchingCollisionShape"
@onready var head = %Head
@onready var camera = $"../Head/Camera3D"
@onready var ray_cast = $"../RayCast3D"
@onready var sprint_timer = $"../SprintTimer"
@onready var slide_timer = $"../SlideTimer"

var direction = Vector3.ZERO
var input_dir = Vector2.ZERO
const JUMP_VELOCITY = 5.5

# Speed Variables
const SPRINT_SPEED = 12.0
const CROUCH_SPEED = 3.5
const WALK_SPEED = 6.0
var speed = 0.0

# Crouch Variables
var crouching_depth = 0.4

# Sliding Variables
var slide_speed = 10.0
var slide_vector = Vector2.ZERO
var slide_direction = Vector2.ZERO

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 15

enum states {
	WALKING,
	SPRINTING,
	CROUCHING,
	SLIDING,
}

var state = states.WALKING


func change_state(new_state):
	state = new_state


func _physics_process(delta):
	match state:
		states.WALKING:
			walking(delta)
			if Input.is_action_just_pressed("jump") and player.is_on_floor() and not ray_cast.is_colliding():
				player.velocity.y = JUMP_VELOCITY
				
		states.SPRINTING:
			sprinting(delta)
			if Input.is_action_just_pressed("jump") and player.is_on_floor() and not ray_cast.is_colliding():
				player.velocity.y = JUMP_VELOCITY
			
		states.CROUCHING:
			crouching(delta)
			
		states.SLIDING:
			sliding(delta)
			
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


func walking(delta):
	
	# Handle Walking State Changes
	
	print("walking")
	if Input.is_action_pressed("sprint"):
		change_state(states.SPRINTING)
	if Input.is_action_pressed("crouch"):
		change_state(states.CROUCHING)
		
	# Walking Code
	
	if player.is_on_floor():
		if direction:
			player.velocity.x = direction.x * speed
			player.velocity.z = direction.z * speed
		else:
			player.velocity.x = lerp(player.velocity.x, direction.x * speed, delta * 7.0)
			player.velocity.z = lerp(player.velocity.z, direction.z * speed, delta * 7.0)
	else:
		player.velocity.x = lerp(player.velocity.x, direction.x * speed, delta * 10.0)
		player.velocity.z = lerp(player.velocity.z, direction.z * speed, delta * 10.0)
	
	# Resetting From Crouch
	
	standing_collision_shape.disabled = false
	crouching_collision_shape.disabled = true
	
	speed = WALK_SPEED
	
	head.position.y = lerp(head.position.y, 1.6, delta * 7.0)
	camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)


func sprinting(delta):
	
	# Handle Sprinting State Changes
	
	print("sprinting")
	if not Input.is_action_pressed("sprint"):
		sprint_timer.start()
	if Input.is_action_just_pressed("crouch"):
		change_state(states.SLIDING)
		slide_timer.start()
		slide_vector = input_dir
		slide_direction = head.transform.basis
		
	# Sprinting Code
	
	speed = SPRINT_SPEED
	camera.fov = lerp(camera.fov, BASE_FOV + FOV_CHANGE, delta * 8.0)
	
	if player.is_on_floor():
		if direction:
			player.velocity.x = direction.x * speed
			player.velocity.z = direction.z * speed
		else:
			player.velocity.x = lerp(player.velocity.x, direction.x * speed, delta * 7.0)
			player.velocity.z = lerp(player.velocity.z, direction.z * speed, delta * 7.0)
	else:
		player.velocity.x = lerp(player.velocity.x, direction.x * speed, delta * 7.0)
		player.velocity.z = lerp(player.velocity.z, direction.z * speed, delta * 7.0)


func crouching(delta):
	
	# Handle Crouching State Changes
	
	print("crouching")
	if not Input.is_action_pressed("crouch") and not ray_cast.is_colliding():
		change_state(states.WALKING)
		
	speed = CROUCH_SPEED
	
	if player.is_on_floor():
		if direction:
			player.velocity.x = direction.x * speed
			player.velocity.z = direction.z * speed
		else:
			player.velocity.x = lerp(player.velocity.x, direction.x * speed, delta * 7.0)
			player.velocity.z = lerp(player.velocity.z, direction.z * speed, delta * 7.0)
	
	# Crouching Code
	
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = false
	
	speed = CROUCH_SPEED
	
	head.position.y = lerp(head.position.y, 1.6 - crouching_depth, delta * 7.0)
	camera.fov = lerp(camera.fov, BASE_FOV - FOV_CHANGE, delta * 8.0)


func sliding(delta):
	
	# Handle Sliding State Changes
	
	if Input.is_action_just_pressed("jump") and player.is_on_floor() and not ray_cast.is_colliding():
		player.velocity.y = JUMP_VELOCITY
		change_state(states.SPRINTING)

	# Sliding Code
	
	print("Sliding")
	direction = (slide_direction * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = false
	
	player.velocity.x = direction.x * slide_speed
	player.velocity.z = direction.z * slide_speed
	
	head.position.y = lerp(head.position.y, 1.6 - crouching_depth, delta * 7.0)
	camera.fov = lerp(camera.fov, BASE_FOV - FOV_CHANGE, delta * 8.0)


func _on_slide_timer_timeout():
	if not ray_cast.is_colliding():
		change_state(states.WALKING)
	else:
		change_state(states.CROUCHING)


func _on_sprint_timer_timeout():
	if not states.SLIDING:
		change_state(states.WALKING)
