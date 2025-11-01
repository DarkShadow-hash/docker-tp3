<?php
$mysqli = new mysqli('data', 'root', 'root', 'mabase'); // adapter le mot de passe si vide

if ($mysqli->connect_errno) {
    printf("Échec de connexion : %s\n", $mysqli->connect_error);
    exit();
}

// Insertion d'une nouvelle ligne (incrémentation du compteur)
if ($mysqli->query("INSERT INTO matable (compteur) SELECT COUNT(*)+1 FROM matable;") === TRUE) {
    echo "Count updated<br />";
} else {
    echo "Erreur SQL : " . $mysqli->error . "<br />";
}

// Lecture du compteur
if ($result = $mysqli->query("SELECT * FROM matable")) {
    printf("Count : %d<br />", $result->num_rows);
    $result->close();
}

$mysqli->close();
?>
