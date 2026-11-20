class_name SCP
extends CharacterBody3D

#relativa ao jogador ex: vel = 1; velocity = direção * (vel * Config.vel)
var vel: float = 0.0
@onready var first_state := {
	pos = self.position,
	rot = self.rotation,
	vel = self.velocity
	}
var player: CharacterBody3D
var ray := RayCast3D.new()
var alvo := Vector3(0, 0, 0)
var ataque_dist := 2.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	ray.enabled = false
	ray.exclude_parent = true
	ray.hit_from_inside = true
	add_child(ray)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= Config.gravidade * delta
	
	var vector = (transform.basis * Vector3(0, 0, -1)).normalized() * (Config.base_vel * vel)
	velocity.z = vector.z
	velocity.x = vector.x

func virar_ao_alvo(delta: float, força: float) -> void:
	if not player: return
	var map_rid: RID = $NavigationAgent3D.get_navigation_map()
	
	if NavigationServer3D.map_get_iteration_id(map_rid) == 0:
		return
	
	$NavigationAgent3D.target_position = NavigationServer3D.map_get_closest_point(map_rid, alvo)
	alvo = $NavigationAgent3D.get_next_path_position()
	
	var old_rotation := rotation
	alvo.y = global_position.y
	if not alvo.is_equal_approx(global_position):
		look_at(alvo)
	rotation.x = 0
	rotation.z = 0
	
	rotation.y = lerp_angle(old_rotation.y, rotation.y, 1.0 - exp(-(vel + força) * delta))

func tentar_atacar(dano):
	var diff := player.position - position
	diff *= diff
	
	if (diff.x + diff.y + diff.z) > ataque_dist * ataque_dist: return
	ray.enabled = true
	ray.target_position = ray.to_local(player.global_position)
	ray.force_raycast_update()
	
	if ray.get_collider() == player:
		player.atacar(dano)
	ray.enabled = true

func reset():
	position = first_state.get("pos")
	rotation = first_state.get("rot")
	velocity = first_state.get("vel")
