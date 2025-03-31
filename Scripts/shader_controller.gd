extends Control

func set_shader_param(shader: String, param: String, value):
	get_node(shader + "/Shader").set_shader_parameter(param, value)
