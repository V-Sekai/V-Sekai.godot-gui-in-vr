extends MeshInstance3D

signal controller_activated(controller)

var _ws := 1.0

@onready var _controller: XRController3D = get_parent()
@onready var vive_material = preload("res://addons/gui_in_vr/vive/vive.tres")
@onready var touchpad_cylinder = $Touchpad/Cylinder
@onready var touchpad_selection_dot = $Touchpad/SelectionDot

func _ready():
	_controller.visible = false


func _process(_delta):
	_base_controller_mesh_stuff()

	# Show a hint where the user's finger is on the touchpad.
	var touchpad_input = _controller.get_vector2("trigger_touch")
	if touchpad_input == Vector2.ZERO:
		touchpad_selection_dot.position = Vector3.ZERO
	else:
		touchpad_selection_dot.position = Vector3(touchpad_input.x, 0.5, -touchpad_input.y) * 0.018


func _base_controller_mesh_stuff():
	if !_controller.get_is_active():
		_controller.visible = false
		return

	_scale_controller_mesh()

	# Was active before, we don't need to do anything.
	if _controller.visible:
		return

	# Became active, handle it.
	var controller_name: String = _controller.get_pose().name
	print("Controller " + controller_name + " became active")

	# Attempt to load a mesh for this controller.
	mesh = load_controller_mesh(controller_name)
	touchpad_cylinder.visible = controller_name.find("vive") < 0
	if !touchpad_cylinder.visible:
		material_override = vive_material

	# Make it visible.
	_controller.visible = true
	emit_signal("controller_activated", _controller)


func load_controller_mesh(controller_name):
	printerr("Unable to load a controller mesh.")
	var sphere_mesh: SphereMesh = SphereMesh.new()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color.a = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	sphere_mesh.height = 0.5
	sphere_mesh.radius = 0.25
	return sphere_mesh


func _scale_controller_mesh():
	var new_ws = XRServer.world_scale
	if _ws != new_ws:
		_ws = new_ws
		scale = Vector3.ONE * _ws
