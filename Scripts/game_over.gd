extends Control

var enemies_killed
var quotas_met
var total_points
var total_trees

func _ready():
	$Stats/quotas.text = str(quotas_met)
	$Stats/points.text = str(total_points)
	$Stats/trees.text = str(total_trees)
	$Stats/kills.text = str(enemies_killed)
