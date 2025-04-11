extends Control

var message = preload("res://Scenes/message.tscn")
var fade_messages = []
var fade_time_left = {}
var message_timers = {}

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Enter") and $Chatbox.visible and $Chatbox.text != "":
		var new_message = message.instantiate()
		if $Chatbox.text.begins_with("/"):
			new_message.text = process_command($Chatbox.text)
		else:
			new_message.text = LocalData.player.name + ": " + $Chatbox.text
			
		$Messages/Vbox.add_child(new_message)
		$Chatbox.text = ""
		$Chatbox.visible = false
		LocalData.player.movement_inputs_enabled = true
		fade_messages.append(new_message)
		fade_time_left[new_message] = 1
		message_timers[new_message] = 0

	for msg in $Messages/Vbox.get_children():
		if $Chatbox.visible:
			msg.visible = true
			msg.modulate.a = 1
		else:
			if message_timers.has(msg):
				message_timers[msg] += _delta
				if message_timers[msg] >= 4:
					fade_time_left[msg] -= _delta
					msg.visible = fade_time_left[msg] > 0
					msg.modulate.a = fade_time_left[msg]

	if not $Chatbox.visible:
		for msg in fade_messages:
			if fade_time_left.has(msg):
				if fade_time_left[msg] <= 0:
					fade_time_left[msg] = 0
					msg.visible = false

	if $Messages.get_v_scroll_bar().changed:
		$Messages.scroll_vertical = $Messages.get_v_scroll_bar().max_value
		
func process_command(Command: String) -> String:
	Command = Command.remove_char(0)
	var args = Command.split(" ")
	
	match args[0]:
		"give":
			pass
	
	
	return ""
