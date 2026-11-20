extends SCP

const tolerancia := 0.5

var anguy_timer := 0.0
var can_get_anguy_time := 0.0
var visivel := false
var anguy_process := false
var hold := 1.0

@onready var anguy = get_meta("anguy")
var this_material: Material
var anguy_tween: Tween

var raycasts := [RayCast3D.new(), RayCast3D.new(), RayCast3D.new(), RayCast3D.new()]

func _ready() -> void:
	super._ready()
	vel = 1.75
	$VisibleOnScreenNotifier3D.screen_entered.connect(_screen_entered)
	$VisibleOnScreenNotifier3D.screen_exited.connect(_screen_exited)
	for raycast: RayCast3D in raycasts:
		raycast.enabled = false
		raycast.exclude_parent = true
		raycast.hit_from_inside = true
		add_child(raycast)
	raycasts[0].position = Vector3(-0.25, 1.75, -0.5)
	raycasts[1].position = Vector3(0.25, 1.75, -0.5)
	raycasts[2].position = Vector3(-0.25, 1.25, -0.5)
	raycasts[3].position = Vector3(0.25, 1.25, -0.5)
	var mat: Material = $MeshInstance3D.get_active_material(0)
	if mat:
		this_material = mat.duplicate()
		$MeshInstance3D.set_surface_override_material(0, this_material)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if anguy and hold <= 0: 
		alvo = player.global_position
		virar_ao_alvo(delta, 5)
	
	if not anguy or not hold <= 0:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()

func _screen_entered():
	visivel = true

func _screen_exited():
	visivel = false

func _process(delta: float) -> void:
	var relative_face_pos := (player.global_position - (global_position + Vector3(0, 0, 0.5))).normalized()
	
	if visivel and relative_face_pos.dot(-global_basis.z.normalized()) > 0 and cara_raycast():
		can_get_anguy_time += delta
	else:
		can_get_anguy_time -= delta
	can_get_anguy_time = clamp(can_get_anguy_time, 0, tolerancia)
	
	if can_get_anguy_time == tolerancia and not anguy_process and hold <= 0:
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
	
	if anguy: tentar_atacar(999)

func cara_raycast():
	for raycast in raycasts:
		raycast.enabled = true
		raycast.target_position = raycast.to_local(player.global_position + Vector3.UP)
		raycast.force_raycast_update()
		var col: Object = raycast.get_collider()
		
		if col == player:
			return true
	return false

func anguyar():
	if anguy_tween:
		anguy_tween.kill()
	anguy_tween = create_tween()
	anguy_tween.tween_property(this_material, "albedo_color", Color(1, 0, 0, 1), 5)
	
	await anguy_tween.finished
	
	anguy = true
	set_meta("anguy", true)

func desanguyar():
	anguy = false
	set_meta("anguy", false)
	if anguy_tween:
		anguy_tween.kill()
	anguy_tween = create_tween()
	anguy_tween.tween_property(this_material, "albedo_color", Color(1, 1, 1, 1), 5)
	
	await anguy_tween.finished

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		reset()
		if anguy_tween:
			anguy_tween.kill()
		this_material.albedo_color = Color(1, 1, 1, 1)
		anguy = false
		set_meta("anguy", false)
		anguy_process = false
		anguy_timer = 0
		hold = 1
		can_get_anguy_time = 0
