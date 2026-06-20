# Core.gd — Autoload singleton. Memegang instance data/codex/state untuk seluruh game.
extends Node

const GameData := preload("res://scripts/GameData.gd")
const Codex := preload("res://scripts/Codex.gd")
const GameState := preload("res://scripts/GameState.gd")
const BattleClass := preload("res://scripts/Battle.gd")

var db
var codex
var state

func _ready() -> void:
	db = GameData.new()
	codex = Codex.new(db)
	state = GameState.new(db, codex)
	state.init_game()

func new_battle(party: Array, enemy: Dictionary):
	return BattleClass.new(db, codex, party, enemy)
