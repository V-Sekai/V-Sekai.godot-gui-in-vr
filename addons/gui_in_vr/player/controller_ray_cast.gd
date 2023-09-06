extends RayCast3D

var _is_activating_gui := false
var _old_raycast_collider: PhysicsBody3D = null
var _old_viewport_point: Vector2
var _ws := 1.0

@onready var _controller: XRController3D = get_parent()


func _process(_delta) -> void:
	_scale_ray()
	var raycast_collider: StaticBody3D = get_collider()
	# First of all, check if we need to release a previous mouse click.
	if not raycast_collider:
		return
	if _old_raycast_collider != null and raycast_collider != _old_raycast_collider:
		_release_mouse()
	elif raycast_collider:
		_try_send_input_to_gui(raycast_collider)


func _try_send_input_to_gui(raycast_collider: StaticBody3D) -> void:
	var nodes: Array[Node] = raycast_collider.find_children("*", "SubViewport")
	if not nodes.size():
		return
	var viewport: Viewport = nodes[0]
	if not viewport:
		return # This isn't something we can give input to.
	var controls: Array[Node] = viewport.find_children("*", "Control")
	if not controls.size():
		return # This isn't something we can give input to.
	var control: Control = controls[0]
	var collider_transform = raycast_collider.global_transform
	if (global_transform.origin * collider_transform.origin).z < 0:
		return # Don't allow pressing if we're behind the GUI.

	# Convert the collision to a relative position. Expects the 2nd child to be a CollisionShape.
	var shape_size = raycast_collider.get_child(1).shape.size * 2
	var collision_point = get_collision_point()

	var t = raycast_collider.global_transform
	var at = t.affine_inverse() * collision_point
	var screen_size: Vector2 = control.size
	at.x = ((at.x / screen_size.x) + 0.5) * viewport.size.x
	at.y = (0.5 - (at.y / screen_size.y)) * viewport.size.y

	# Find the viewport position by scaling the relative position by the viewport size. Discard Z.
	var viewport_point = Vector2(at.x, at.y)

	# Send mouse motion to the GUI.
	var event = InputEventMouseMotion.new()
	event.global_position = viewport_point
	viewport.push_input(event)

	# Figure out whether or not we should trigger a click.
	var desired_activate_gui := false
	var distance = global_transform.origin.distance_to(collision_point) / XRServer.world_scale
	if distance < 0.1:
		desired_activate_gui = true # Allow "touching" the GUI.
	else:
		desired_activate_gui = _is_trigger_pressed() # Else, use the trigger.

	# Send a left click to the GUI depending on the above.
	if desired_activate_gui:
		event = InputEventMouseButton.new()
		event.pressed = desired_activate_gui
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = viewport_point
		viewport.push_input(event)
		_is_activating_gui = desired_activate_gui
		_old_raycast_collider = raycast_collider
		_old_viewport_point = viewport_point


func _release_mouse() -> void:
	var event = InputEventMouseButton.new()
	event.button_index = 1
	event.position = _old_viewport_point
	_old_raycast_collider.get_child(0).push_input(event)
	_old_raycast_collider = null
	_is_activating_gui = false


func _is_trigger_pressed() -> bool:
	var trigger_press: bool = _controller.get_float("trigger") > 0.6
	return trigger_press


func _scale_ray() -> Vector3:
	var new_ws = XRServer.world_scale
	if _ws != new_ws:
		_ws = new_ws
		scale = Vector3.ONE * _ws
	return Vector3.ONE
