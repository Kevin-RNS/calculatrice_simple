extends Control
# Affichage
@onready var label_operation: Label = %Operation
@onready var label_resultat: Label = %Resultat

# État de la calculatrice
var nombre1: float = 0.0
var nombre2: float = 0.0
var operateur: String = ""

# Vrai quand l'utilisateur est en train de taper un nombre.
var saisie_en_cours: bool = false

# Vrai si le nombre en cours contient déjà une virgule.
var partie_decimale: bool = false

# Précision utilisée pour arrondir les résultats.
const PRECISION := 0.0000001


func _ready() -> void:
	# Les boutons des chiffres s'appellent "0", "1", ... "9".
	for groupe in %Boutons.get_children():
		for bouton in groupe.get_children():
			if str(bouton.name).is_valid_int():
				bouton.pressed.connect(_on_chiffre_pressed.bind(str(bouton.name)))


# ---------------------------------------------------------------
# Chiffres et virgule
# ---------------------------------------------------------------
func _on_chiffre_pressed(chiffre: String) -> void:
	# Nouveau nombre : on remplace l'affichage.
	if not saisie_en_cours:
		# Si le calcul précédent est fini, on efface l'ancienne opération.
		if operateur == "":
			label_operation.text = ""
		label_resultat.text = chiffre
		saisie_en_cours = true
		partie_decimale = false
		return

	# Évite d'afficher "05" ou "-05".
	if label_resultat.text == "0":
		label_resultat.text = chiffre
		return
	if label_resultat.text == "-0":
		label_resultat.text = "-" + chiffre
		return

	label_resultat.text += chiffre


func _on_virgule_pressed() -> void:
	# Si on n'a pas encore commencé à taper, on part de "0."
	if not saisie_en_cours:
		# Si le calcul précédent est fini, on efface l'ancienne opération.
		if operateur == "":
			label_operation.text = ""
		label_resultat.text = "0."
		saisie_en_cours = true
		partie_decimale = true
		return

	# Une seule virgule par nombre.
	if not partie_decimale:
		label_resultat.text += "."
		partie_decimale = true


# ---------------------------------------------------------------
# Opérations
# ---------------------------------------------------------------
func _on_diviser_pressed() -> void:
	_choisir_operateur("/")


func _on_multiplier_pressed() -> void:
	_choisir_operateur("x")


func _on_soustraire_pressed() -> void:
	_choisir_operateur("-")


func _on_additionner_pressed() -> void:
	_choisir_operateur("+")


func _choisir_operateur(symbole: String) -> void:
	nombre1 = label_resultat.text.to_float()
	operateur = symbole
	label_operation.text = _format_nombre(nombre1) + " " + operateur

	# Le prochain chiffre tapé sera le deuxième nombre.
	saisie_en_cours = false
	partie_decimale = false


func _on_egal_pressed() -> void:
	if operateur == "":
		return

	nombre2 = label_resultat.text.to_float()
	var resultat: float

	match operateur:
		"+":
			resultat = nombre1 + nombre2
		"-":
			resultat = nombre1 - nombre2
		"x":
			resultat = nombre1 * nombre2
		"/":
			if nombre2 == 0.0:
				label_operation.text = "Division par zéro impossible"
				label_resultat.text = "0"
				operateur = ""
				saisie_en_cours = false
				partie_decimale = false
				return
			resultat = nombre1 / nombre2
		_:
			return

	label_operation.text = (
		_format_nombre(nombre1) + " " + operateur + " " + _format_nombre(nombre2)
	)
	label_resultat.text = _format_nombre(resultat)

	operateur = ""
	saisie_en_cours = false
	partie_decimale = false


# ---------------------------------------------------------------
# Boutons spéciaux
# ---------------------------------------------------------------
func _on_clear_pressed() -> void:
	label_operation.text = ""
	label_resultat.text = "0"
	nombre1 = 0.0
	nombre2 = 0.0
	operateur = ""
	saisie_en_cours = false
	partie_decimale = false


func _on_signe_pressed() -> void:
	# Cas particulier : permet de commencer un nombre négatif ("-0" puis les chiffres).
	if label_resultat.text == "0":
		label_resultat.text = "-0"
		saisie_en_cours = true
		return
	if label_resultat.text == "-0":
		label_resultat.text = "0"
		saisie_en_cours = true
		return

	var valeur := label_resultat.text.to_float()
	label_resultat.text = _format_nombre(-valeur)


func _on_effacer_pressed() -> void:
	# On efface seulement pendant la saisie d'un nombre.
	if not saisie_en_cours:
		return

	var texte := label_resultat.text

	# S'il ne reste qu'un chiffre (ou "-5"), on revient à "0".
	if texte.length() <= 1 or (texte.length() == 2 and texte.begins_with("-")):
		label_resultat.text = "0"
		saisie_en_cours = false
		partie_decimale = false
		return

	label_resultat.text = texte.left(-1)
	partie_decimale = label_resultat.text.contains(".")


# Outils
func _format_nombre(valeur: float) -> String:
	# Arrondit pour éviter les résultats du type 0.30000000000000004.
	var arrondi := snappedf(valeur, PRECISION)
	var texte := str(arrondi)

	# Enlève le ".0" des nombres entiers (5.0 -> 5).
	if texte.ends_with(".0"):
		texte = texte.left(-2)

	return texte
