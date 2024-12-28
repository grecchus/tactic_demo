extends RichTextLabel

func _on_log_updated():
	self.text += "\n" + gv.console_log[0]
