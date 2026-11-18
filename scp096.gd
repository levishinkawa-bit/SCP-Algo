extends CharacterBody3D

@onready var vel := Config.base_vel * 1.75

@onready var first_state = {
	pos = self.position,
	rot = self.rotation,
	vel = self.velocity
	}

var anguy_timer := 0.0
var player: CharacterBody3D
var can_get_anguy := false
var anguy_process := false
var hold := 1.0

@onready var anguy = get_meta("anguy")
var this_material: Material

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	$VisibleOnScreenNotifier3D.screen_entered.connect(_screen_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_screen_exited)
	var mat: Material = $MeshInstance3D.get_active_material(0)
	if mat:
		this_material = mat.duplicate()
		$MeshInstance3D.set_surface_override_material(0, this_material)

func _physics_process(delta: float) -> void:
	if player and anguy and hold <= 0:
		var alvo := player.global_position
		var old_rotation := rotation
		
		look_at(alvo)
		rotation.x = 0
		rotation.z = 0
		
		rotation.y = lerp_angle(old_rotation.y, rotation.y, 1.0 - exp(-(vel + 2) * delta))
	
	if not is_on_floor():
		velocity.y -= Config.gravidade * delta
	
	if anguy and hold <= 0:
		var vector := (transform.basis * Vector3(0, 0, -1)).normalized() * vel
		velocity.z = vector.z
		velocity.x = vector.x
	else:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()

func _screen_entered():
	can_get_anguy = true

func _screen_exited():
	can_get_anguy = false

func _process(delta: float) -> void:
	if can_get_anguy and not anguy_process and hold <= 0:
		anguy_process = true
		anguyar()
		anguy_timer = 60
	
	if anguy_timer > delta:
		anguy_timer -= delta
	elif anguy_process:
		desanguyar()
		anguy_process = false
	if not hold <= 0:
		hold -= delta
	
	var diff := player.position - position
	diff *= diff
	if anguy and (diff.x + diff.y + diff.z) < 9 and hold <= 0: # 3 * 3
		player.atacar(999)

func anguyar():
	create_tween().tween_property(this_material, "albedo_color", Color(1, 0, 0, 1), 5)
	await get_tree().create_timer(5).timeout
	anguy = true
	set_meta("anguy", true)

func desanguyar():
	anguy = false
	set_meta("anguy", false)
	create_tween().tween_property(this_material, "albedo_color", Color(1, 1, 1, 1), 5)
	await get_tree().create_timer(5).timeout

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		position = first_state.get("pos")
		rotation = first_state.get("rot")
		velocity = first_state.get("vel")
		this_material.albedo_color = Color(1, 1, 1, 1)
		anguy = false
		set_meta("anguy", false)
		anguy_process = false
		anguy_timer = 0
		hold = 1
