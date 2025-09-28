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
	if _old_raycast_collider != null and raycast_collider != _old_raycast_collider:
		_release_mouse()
	elif raycast_collider:
		_try_send_input_to_gui(raycast_collider)


func _try_send_input_to_gui(raycast_collider: StaticBody3D) -> void:
	var viewport: Viewport = raycast_collider.get_node("SubViewport")
	if not viewport:
		return # This isn't something we can give input to.
	
	var interaction_manager = raycast_collider.get_node("InteractionManager")
	if not interaction_manager:
		return
	
	var aspect = viewport.size.x / float(viewport.size.y)
	var effective_aspect = aspect * raycast_collider.scale.x
	
	var collision_point = get_collision_point()
	var t = raycast_collider.get_node("Quad").global_transform
	var at = t.affine_inverse() * collision_point
	at.x /= effective_aspect  # Normalize for effective aspect ratio
	at.y *= -1
	at += Vector3(0.5, 0.5, 0)
	
	# Find the viewport position by scaling the relative position by the viewport size. Discard Z.
	var viewport_point = Vector2(at.x, at.y) * Vector2(viewport.size)
	
	var source_transform = global_transform.looking_at(collision_point, Vector3.UP)
	var top_two = interaction_manager.lasso_db.calc_top_two_snapping_power(source_transform, null, 0.01, 0.01, false, 0.5)
	
	var canvas_item = null
	var slider_ratio = -1.0
	if top_two[0]:
		canvas_item = top_two[0].origin.get_meta("canvas_item")
		slider_ratio = top_two[0].origin.get_meta("slider_ratio", -1.0)
	
	if not canvas_item:
		return
	
	# If snapped to a slider snap point, adjust viewport_point
	if slider_ratio >= 0.0:
		var snapped_rect = canvas_item.get_global_rect()
		if canvas_item is HSlider:
			viewport_point.x = snapped_rect.position.x + snapped_rect.size.x * slider_ratio
			viewport_point.y = snapped_rect.position.y + snapped_rect.size.y / 2
		elif canvas_item is VSlider:
			viewport_point.x = snapped_rect.position.x + snapped_rect.size.x / 2
			viewport_point.y = snapped_rect.position.y + snapped_rect.size.y * (1 - slider_ratio)
	
	# Move cursor to snapped position
	if top_two[0]:
		get_tree().get_root().get_node("World/GUIPanel3D/Cursor").global_position = top_two[0].origin.global_position
	
	# Send mouse motion to the GUI.
	var event = InputEventMouseMotion.new()
	event.position = viewport_point
	viewport.push_input(event)

	# Figure out whether or not we should trigger a click.
	var desired_activate_gui := false
	var distance = global_transform.origin.distance_to(collision_point) / XRServer.world_scale
	if distance < 0.1:
		desired_activate_gui = true # Allow "touching" the GUI.
	else:
		desired_activate_gui = _is_trigger_pressed() # Else, use the trigger.

	# Send a left click to the GUI depending on the above.
	if desired_activate_gui != _is_activating_gui:
		event = InputEventMouseButton.new()
		event.pressed = desired_activate_gui
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = viewport_point
		viewport.push_input(event)
		_is_activating_gui = desired_activate_gui


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
