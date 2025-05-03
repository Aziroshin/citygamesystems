# GdUnit generated TestSuite
class_name Curve2dDebugVisualizerTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://dev/curve_debug_visualizer/curve2d_debug_visualizer.gd'

const TestScene := preload("./fixtures/curve2d_test_scene.tscn")


class TestScreenshotter2D extends Node2D:
	var sub_viewport
	@onready var viewport_image_or_null: Image = null
	@onready var viewport_texture: ViewportTexture
	var delete_file_before_saving := false
	var wait_for_draw := true
	
	
	func _init(
		p_delete_file_before_saving := false,
		p_name := "TestScreenshotter2D",
		p_sub_viewport: SubViewport = null
	) -> void:
		p_delete_file_before_saving = p_delete_file_before_saving
		name = p_name
		
		if not p_sub_viewport == null:
			sub_viewport = p_sub_viewport
		
		
	func _ready() -> void:
		if sub_viewport == null:
			sub_viewport = get_tree().root.get_viewport()
		viewport_texture = sub_viewport.get_texture()
		
		
	static func get_or_create_if_not_exist(
		p_parent: Node,
		#p_scene: Node,
		p_delete_file_before_saving := false,
		p_name := "TestScreenshotter2D",
		p_sub_viewport: SubViewport = null
	) -> TestScreenshotter2D:
		var maybe_existing := p_parent.find_child("TestScreenshotter2D")
		
		if maybe_existing:
			return maybe_existing as TestScreenshotter2D
		
		var new_screenshotter := TestScreenshotter2D.new(
			p_delete_file_before_saving,
			p_name,
			p_sub_viewport
		)
		p_parent.add_child(new_screenshotter)
		return new_screenshotter


	## Takes a screenshot and saves the `Image` in `viewport_image_or_null`.
	## If `p_file_path` isn't empty, the screenshot is saved to that path.
	## `wait_for` has to be a signal.
	func take_screenshot(p_file_path := ""):
		if wait_for_draw:
			await RenderingServer.frame_post_draw
		print("Curve2dDebugVisualizerTest.gd: ")
		viewport_image_or_null = viewport_texture.get_image()
		if viewport_image_or_null == null:
			return
		viewport_image_or_null.convert(Image.FORMAT_RGBA8)
		
		if not p_file_path == "":
			if delete_file_before_saving:
				DirAccess.remove_absolute(p_file_path)
			viewport_image_or_null.save_png(p_file_path)
		
		return


func test__update_from_curve() -> void:
	var scene := TestScene.instantiate()
	var screenshotter := TestScreenshotter2D.get_or_create_if_not_exist(
		self,
		true
	)
	var runner := scene_runner(scene)
	var path2d: Path2D = runner.get_property("path")
	var visualizer: Curve2dDebugVisualizer = runner.get_property("visualizer")

	screenshotter.take_screenshot("user://curve2d_debug_mess.png")
		
	return
