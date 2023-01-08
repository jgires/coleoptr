
#' name_be_genderize
#'
#' @param data_to_detect le data.frame d'interet
#' @param col_name le nom de la colonne qui contient les prenoms dont il faut trouver le genre
#' @param reference le dictionnaire des prenoms de reference
#' @param inexact indiquer si le matching doit etre inexact (probabiliste)
#' @param method_stringdist la methode de matching inexact
#' @param error_max l'erreur maximale du matching inexact
#'
#' @import dplyr
#' @import readr
#' @import stringr
#' @import fuzzyjoin
#' @import stringdist
#' @import parallel
#'
#' @export
#'
#' @examples
#' x <- data.frame(prenom = c(paste0("C","\u00e9","line"), "Najib", "Dominique"))
#'
#' result <- name_be_genderize(data_to_detect = x,
#' col_name = "prenom")
name_be_genderize <- function(data_to_detect,
                              col_name = NULL,
                              reference = "all",
                              inexact = FALSE,
                              method_stringdist = "lcs",
                              error_max = 1) {

  # Un stop si la colonne avec le nom n'est pas renseignee
  if (is.null(col_name)) {
    stop(paste0("\u2716", " Le champ de nom n'a pas ", "\u00e9", "t", "\u00e9", " correctement rempli"))
  }

  cat(paste0("\n", "--- name_be_genderize ---"))

  # On cree un ID unique et la colonne de nom (transformee pour le matching)
  data_to_detect$name_join_data <- data_to_detect[[col_name]]
  data_to_detect <- data_to_detect %>%
    mutate(
      ID_name_unique = row_number(),
      name_join_data = str_to_lower(str_trim(name_join_data))
    ) %>%
    relocate(ID_name_unique)

  # On charge les noms
  if (reference == "all") {
    noms <- noms %>%
      mutate(name_join_noms = str_to_lower(str_trim(name_detected))) %>%
      select(-length)
  }

  if (reference == "old") {
    noms <- noms_65 %>%
      mutate(name_join_noms = str_to_lower(str_trim(name_detected))) %>%
      select(-length)
  }

  # Si exact => jointure exacte
  if (inexact == FALSE) {

    cat(paste0("\n", "\u29D7", " D", "\u00e9", "tection des noms (matching exact)"))

    data_to_detect <- data_to_detect %>%
      left_join(noms, by = c("name_join_data" = "name_join_noms")) %>%
      select(-name_join_data, -dico)

    cat(paste0("\r", "\u2714", " D", "\u00e9", "tection des noms (matching exact)", "\033[K"))

  }

  # Si inexact => jointure probabiliste

  # On parallelise : n-1 core ssi 3 cores ou plus, sinon 1 core
  if (inexact == TRUE) {
    if (parallel::detectCores() > 3) {
      n.cores <- parallel::detectCores() - 1
    } else {
      n.cores <- 1
    }

    cat(paste0("\r", "\u2139", " Utilisation de ", n.cores, " coeurs de l'ordinateur"))

    cat(paste0("\n", "\u29D7", " D", "\u00e9", "tection des noms (matching inexact avec fuzzyjoin)"))

    data_to_detect <- stringdist_left_join(
      data_to_detect,
      noms,
      by = c("name_join_data" = "name_join_noms"),
      method = method_stringdist,
      max_dist = error_max,
      distance_col = "dist_fuzzy"
    )

    # On ne garde que la distance minimale
    data_to_detect <- data_to_detect %>%
      group_by(ID_name_unique) %>%
      mutate(min = min(dist_fuzzy)) %>%
      filter(dist_fuzzy == min | is.na(dist_fuzzy)) %>%
      select(-min)

    # Au cas ou plus de doublons
    if (sum(duplicated(data_to_detect$ID_name_unique)) == 0) {
      data_to_detect <- data_to_detect %>%
        select(-name_join_data, -name_join_noms)
    }

    # Au cas ou il reste des doublons : nouveau calcul de distance avec Jaro-Winkler

    cat(paste0("\r", "\u2714", " D", "\u00e9", "tection des noms (matching inexact avec fuzzyjoin)", "\033[K"))

    if (sum(duplicated(data_to_detect$ID_name_unique)) > 0) {
      cat(paste0("\n", "\u29D7", " Ex-aequos : calcul de la distance Jaro-Winkler pour d", "\u00e9", "partager"))

      data_to_detect <- data_to_detect %>%
        mutate(distance_jw = stringdist(name_join_data, name_join_noms, method = "jw", p = 0.1)) %>%
        group_by(ID_name_unique) %>%
        mutate(min_jw = min(distance_jw)) %>%
        filter(distance_jw == min_jw | is.na(distance_jw)) %>%
        sample_n(1) %>% # Au cas ou il reste ENCORE des doublons : tirage aleatoire (arrive uniquement lorsque la tolerance est elevee)
        select(-min_jw, -distance_jw, -name_join_data, -name_join_noms, -dico)

      cat(paste0("\r", "\u2714", " Ex-aequos : calcul de la distance Jaro-Winkler pour d", "\u00e9", "partager"))
    }
  }

  return(data_to_detect)
}
