extends StaticBody3D

@onready var viewport = $SubViewport
@onready var interaction_manager = $InteractionManager

func _ready():
	var aspect = viewport.size.x * 1.0/viewport.size.y
	
	$CollisionShape3D.shape.size.x = aspect
	$Quad.scale.x = aspect
	
	# Register controls with invisible 9-patch zone system
	var gui = $SubViewport/GUI
	var root_control = gui
	var form_element: Control = root_control.find_next_valid_focus()
	var already_added_items := {}
	while form_element != null:
		if not already_added_items.has(form_element):
			already_added_items[form_element] = true
			# Create a 3D anchor for the control
			var rect = form_element.get_global_rect()
			var center = rect.get_center()
			var panel_size = Vector2(viewport.size)
			var normalized_pos = center / panel_size
			# Assuming the quad is 1x1, scale to aspect
			var x = (normalized_pos.x - 0.5) * aspect
			var y = (0.5 - normalized_pos.y)  # Y flipped
			var anchor = Node3D.new()
			add_child(anchor)
			anchor.position = Vector3(x, y, 0.01)
			anchor.set_meta("canvas_item", form_element)
			# Set lasso properties for invisible 9-patch zones
			var lasso_point = interaction_manager.lasso_db.PointOfInterest.new()
			lasso_point.width = rect.size.x / panel_size.x
			lasso_point.height = rect.size.y / panel_size.y
			# The zones provide an invisible 9-patch coordinate system for interaction
			lasso_point.register_point(interaction_manager.lasso_db, anchor)
			if form_element is HSlider:
				# Create multiple anchors for 10% snaps
				for i in range(11):  # 0, 10, 20, ..., 100%
					var ratio = i / 10.0
					var anchor_pos = rect.position + Vector2(rect.size.x * ratio, rect.size.y / 2)
					var normalized_pos_fine = anchor_pos / panel_size
					var x_fine = (normalized_pos_fine.x - 0.5) * aspect
					var y_fine = (0.5 - normalized_pos_fine.y)
					var fine_anchor = Node3D.new()
					add_child(fine_anchor)
					fine_anchor.position = Vector3(x_fine, y_fine, 0.01)
					fine_anchor.set_meta("canvas_item", form_element)
					fine_anchor.set_meta("slider_ratio", ratio)
					var fine_point = interaction_manager.lasso_db.PointOfInterest.new()
					fine_point.width = rect.size.x / 11.0  # Smaller zones
					fine_point.height = rect.size.y
					fine_point.snapping_power = 3.0  # Higher priority
					fine_point.register_point(interaction_manager.lasso_db, fine_anchor)
			elif form_element is VSlider:
				# Similar for VSlider
				for i in range(11):
					var ratio = i / 10.0
					var anchor_pos = rect.position + Vector2(rect.size.x / 2, rect.size.y * (1 - ratio))
					var normalized_pos_fine = anchor_pos / panel_size
					var x_fine = (normalized_pos_fine.x - 0.5) * aspect
					var y_fine = (0.5 - normalized_pos_fine.y)
					var fine_anchor = Node3D.new()
					add_child(fine_anchor)
					fine_anchor.position = Vector3(x_fine, y_fine, 0.01)
					fine_anchor.set_meta("canvas_item", form_element)
					fine_anchor.set_meta("slider_ratio", ratio)
					var fine_point = interaction_manager.lasso_db.PointOfInterest.new()
					fine_point.width = rect.size.x
					fine_point.height = rect.size.y / 11.0
					fine_point.snapping_power = 3.0
					fine_point.register_point(interaction_manager.lasso_db, fine_anchor)
		form_element = form_element.find_next_valid_focus()
		if already_added_items.has(form_element):
			break
