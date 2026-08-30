@tool
class_name LoadingView extends Control

@onready var logo: TextureRect = $Logo
@onready var label: RichTextLabel = $Label
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer



func playAnimation():
	animationPlayer.play("Loading")
