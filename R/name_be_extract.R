
#' name_be_extract
#'
#' @param data_to_detect le data.frame d'interet
#' @param col_to_detect le nom de la colonne dans laquelle detecter les presnoms
#' @param reference le dictionnaire des prenoms de reference
#' @param numb_threshold le seuil de frequence minimale de prenoms pour le dictionnaire
#' @param length_threshold le seuil de longueur minimale de prenoms pour le dictionnaire
#' @param exclude_dico exclure les noms communs de la detection
#' @param spec_char_insens insensible aux caracteres speciaux dans la detection
#' @param respect_boundaries respecter les frontieres des mots
#' @param nl_street detection dans des noms de rue en neerlandais
#'
#' @import dplyr
#' @import readr
#' @importFrom tidyr unnest_wider
#' @import stringr
#'
#' @export
#'
#' @examples
#' x <- data.frame(rue = c(paste0("Avenue Paul H","\u00e9","ger"),
#' "Jardin des Justes", "Place Sainte-Catherine"))
#'
#' result <- name_be_extract(data_to_detect = x,
#' col_to_detect = "rue")
name_be_extract <- function(data_to_detect,
                            col_to_detect = NULL,
                            reference = "all",
                            numb_threshold = 500,
                            length_threshold = 3,
                            exclude_dico = NULL,
                            spec_char_insens = FALSE,
                            respect_boundaries = TRUE,
                            nl_street = FALSE) {

  # Un stop si la colonne avec le nom n'est pas renseignee
  if (is.null(col_to_detect)) {
    stop(paste0("\u2716", " Le champ dans lequel d", "\u00e9", "tecter le nom n'a pas ", "\u00e9", "t", "\u00e9", " correctement rempli"))
  }

  cat(paste0("\n", "--- name_be_extract ---"))


  # 1. Preparation des donnees --------------------------------------------------------------------------------------------------------------

  # Fonction utilisee ci-dessous => https://www.r-bloggers.com/2018/07/the-notin-operator/
  `%ni%` <- Negate(`%in%`)

  cat(paste0("\n", "\u29D7", " Pr", "\u00e9", "paration des donn", "\u00e9", "es"))

  # On cree la colonne dans laquelle on doit detecter le prenom (transformee pour le matching)
  data_to_detect$col_to_detect <- data_to_detect[[col_to_detect]]
  data_to_detect <- data_to_detect %>%
    mutate(col_to_detect = str_to_lower(str_trim(col_to_detect)),
           ID_detect_unique = row_number()) %>%
    relocate(ID_detect_unique)

  # On charge les noms
  if (reference == "all") {
    #noms <- read_delim("noms.csv", delim = ";", progress= F,  col_types = cols(.default = col_character())) %>%
    noms <- noms %>%
      filter(str_detect(name_detected, "-") == FALSE) %>%
      filter(n_tot >= numb_threshold) %>% # On ne prend que les noms dont la frequence est superieure a numb_threshold
      mutate(name_detect_noms = str_to_lower(str_trim(name_detected))) %>%
      filter(length >= length_threshold)
  }

  if (reference == "old") {
    #noms <- read_delim("noms_65.csv", delim = ";", progress= F,  col_types = cols(.default = col_character())) %>%
    noms <- noms_65 %>%
      filter(str_detect(name_detected, "-") == FALSE) %>%
      filter(n_tot >= numb_threshold) %>% # On ne prend que les noms dont la frequence est superieure a numb_threshold
      mutate(name_detect_noms = str_to_lower(str_trim(name_detected))) %>%
      filter(length >= length_threshold)
  }

  # On enleve qques prenoms qui sont aussi des noms communs, pour ne pas detecter toutes les rues / institutions avec "Reine Astrid", "Prince bidule", etc.
  noms <- noms %>%
    filter(name_detect_noms %ni% c("prince",
                                   "reine",
                                   "prins",
                                   "princesse",
                                   "roi",
                                   "de",
                                   "la",
                                   "le",
                                   "des",
                                   "les",
                                   "van",
                                   "v\u00e2n",
                                   "ten",
                                   "duc",
                                   "roc",
                                   "saint"
    ))

  # On exlut les noms communs si exclude_dico == TRUE
  # NOTE : ici il faut faire un travail de selection du meilleur dictionnaire
  if (!is.null(exclude_dico)) {

    exclude_dico_computed <- NULL

    if (any(exclude_dico %in% "fr")) {
      exclude_dico_computed <- append(exclude_dico_computed, c("fr", "fr;nl"))
    }
    if (any(exclude_dico %in% "nl")) {
      exclude_dico_computed <- append(exclude_dico_computed, c("nl", "fr;nl"))
    }
    exclude_dico_computed <- unique(exclude_dico_computed)

      filter_noms_com <- unique(noms$name_detect_noms[noms$dico %in% exclude_dico_computed & !is.na(noms$dico)])

      noms <- noms %>%
        filter(name_detect_noms %ni% filter_noms_com)
  }

  # Le tri ici est important pour eviter de selectionner le plus court au sein de noms potentiellement plus longs (eviter de prendre "Deni" dans "Denise" car "Deni" est avant "Denise" dans la liste des noms)
  # Voir ici pour une solution alternative ? => https://stackoverflow.com/questions/50453844/how-to-extract-the-longest-match
  noms$length <- as.numeric(noms$length)
  noms <- noms[order(noms$length, decreasing = TRUE),]

  # Si insensible aux caract. speciaux : on transforme la detection avec des REGEX
  if (spec_char_insens == TRUE) {
  noms <- noms %>%
    mutate(name_detect_noms = str_replace_all(name_detect_noms, "[']", "[' ]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[a\u00e0\u00e2\u00e2\u00e3\u00e4\u00e5]", "[a\u00e0\u00e2\u00e2\u00e3\u00e4\u00e5]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[e\u00e8\u00e9\u00ea\u00eb]", "[e\u00e8\u00e9\u00ea\u00eb]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[i\u00ec\u00ed\u00ee\u00ef]", "[i\u00ec\u00ed\u00ee\u00ef]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[o\u00f2\u00f3\u00f4\u00f5\u00f6\u00f8]", "[o\u00f2\u00f3\u00f4\u00f5\u00f6\u00f8]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[u\u00f9\u00fa\u00fb\u00fc]", "[u\u00f9\u00fa\u00fb\u00fc]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[y\u00fd\u00ff]", "[y\u00fd\u00ff]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[n\u00f1]", "[n\u00f1]"),
           name_detect_noms = str_replace_all(name_detect_noms, "[c\u00e7]", "[c\u00e7]")) %>%
    distinct(name_detect_noms)
  }

  # Dans le cas de rues en NL
  # Voir: https://www.dbnl.org/tekst/stev002leid01_01/stev002leid01_01_0001.php
  # PROBLEME RESTANT : il reste les rues avec possessif : sstraat - slaan - splein...
  if (nl_street == TRUE) {
    data_to_detect <- data_to_detect %>%
      mutate(col_to_detect = str_replace(col_to_detect, "nieuwstraat\\b", ""),
             col_to_detect = str_replace(col_to_detect, "straat\\b", ""),
             col_to_detect = str_replace(col_to_detect, "laan\\b", ""),
             col_to_detect = str_replace(col_to_detect, "plaats\\b", ""),
             col_to_detect = str_replace(col_to_detect, "pleintje\\b", ""),
             col_to_detect = str_replace(col_to_detect, "voorplein\\b", ""),
             col_to_detect = str_replace(col_to_detect, "plein\\b", ""),
             col_to_detect = str_replace(col_to_detect, "nieuwweg\\b", ""),
             col_to_detect = str_replace(col_to_detect, "weg\\b", ""),
             col_to_detect = str_replace(col_to_detect, "steenweg\\b", ""),
             col_to_detect = str_replace(col_to_detect, "square\\b", ""),
             col_to_detect = str_replace(col_to_detect, "dreef\\b", ""),
             col_to_detect = str_replace(col_to_detect, "lei\\b", ""),
             col_to_detect = str_replace(col_to_detect, "pad\\b", ""),
             col_to_detect = str_replace(col_to_detect, "straatje\\b", ""),
             col_to_detect = str_replace(col_to_detect, "steeg\\b", ""),
             col_to_detect = str_replace(col_to_detect, "wegel\\b", ""),
             col_to_detect = str_replace(col_to_detect, "dam\\b", ""),
             col_to_detect = str_replace(col_to_detect, "kaai\\b", ""),
             col_to_detect = str_replace(col_to_detect, "park\\b", ""),
             col_to_detect = str_replace(col_to_detect, "dijk\\b", ""),
             col_to_detect = str_replace(col_to_detect, "polder\\b", ""),
             col_to_detect = str_replace(col_to_detect, "veld\\b", ""),
             col_to_detect = str_replace(col_to_detect, "heide\\b", ""),
             col_to_detect = str_replace(col_to_detect, "kerkhof\\b", ""),
             col_to_detect = str_replace(col_to_detect, "hof\\b", ""),
             col_to_detect = str_replace(col_to_detect, "steenstraat\\b", ""),
             col_to_detect = str_replace(col_to_detect, "berg\\b", ""),
             col_to_detect = str_replace(col_to_detect, "vest\\b", ""),
             col_to_detect = str_replace(col_to_detect, "markt\\b", ""),
             col_to_detect = str_replace(col_to_detect, "poort\\b", ""),
             col_to_detect = str_replace(col_to_detect, "vliet\\b", ""),
             col_to_detect = str_replace(col_to_detect, "dal\\b", ""),
             col_to_detect = str_replace(col_to_detect, "bos\\b", ""),
             col_to_detect = str_replace(col_to_detect, "tuin\\b", ""),
             col_to_detect = str_replace(col_to_detect, "kerk\\b", ""),
             col_to_detect = str_replace(col_to_detect, "hospitaal\\b", ""),
             col_to_detect = str_replace(col_to_detect, "fontein\\b", ""),
             col_to_detect = str_replace(col_to_detect, "hoef\\b", ""),
             col_to_detect = str_replace(col_to_detect, "wijk\\b", ""),
             col_to_detect = str_replace(col_to_detect, "baan\\b", ""),
             col_to_detect = str_replace(col_to_detect, "abdij\\b", ""),
             col_to_detect = str_replace(col_to_detect, "kruispunt\\b", ""),
             col_to_detect = str_replace(col_to_detect, "gang\\b", "")
      )
  }

  cat(paste0("\r", "\u2714", " Pr", "\u00e9", "paration des donn", "\u00e9", "es"))


  # 2. Detection des noms -------------------------------------------------------------------------------------------------------------------

  # --- FONCTIONS ---
  # Detection de TOUS les noms avec respect des frontieres de mots (\\b)
  if (respect_boundaries == TRUE) {
    extract_name_all <- function(v) {
      str_extract_all(
        v,
        str_c(
          "\\b(?<!\\-)(",
          str_c(noms$name_detect_noms,
                collapse = "|"
          ),
          ")\\b(?!\\-)"
        )
      )
    }
    # Detection du PREMIER nom avec respect des frontieres de mots (\\b)
    extract_name <- function(v) {
      str_extract(
        v,
        str_c(
          "\\b(?<!\\-)(",
          str_c(noms$name_detect_noms,
                collapse = "|"
          ),
          ")\\b(?!\\-)"
        )
      )
    }
  }

  # Detection de TOUS les noms SANS respect des frontieres de mots (le nom peut etre au milieu d'une chaine de caracteres plus longue)
  if (respect_boundaries == FALSE) {
    extract_name_all <- function(v) {
      str_extract_all(
        v,
        str_c(
          str_c(noms$name_detect_noms,
                collapse = "|"
          )
        )
      )
    }

    # Detection du PREMIER nom SANS respect des frontieres de mots (le nom peut etre au milieu d'une chaine de caracteres plus longue)
    extract_name <- function(v) {
      str_extract(
        v,
        str_c(
          str_c(noms$name_detect_noms,
                collapse = "|"
          )
        )
      )
    }
  }

  cat(paste0("\n", "\u29D7", " D", "\u00e9", "tection des noms (extraction avec stringr sur base des noms belges)", "\033[K"))

  data_to_detect <- data_to_detect %>%
    mutate(
      col_to_detect = str_replace_all(col_to_detect, "[-]", " "), # Pour supprimer les tirets, pour isoler les noms

      name_extracted = extract_name_all(col_to_detect)
    )

  cat(paste0("\r", "\u2714", " D", "\u00e9", "tection des noms (extraction avec stringr sur base des noms belges)", "\033[K"))


  # 3. Mise en forme des donnees ------------------------------------------------------------------------------------------------------------

  cat(paste0("\n", "\u29D7", " Mise en forme du tableau"))

  data_to_detect <- data_to_detect %>%
    unnest_wider(name_extracted, names_sep="_") %>%
    mutate(
      across(
        starts_with("name_extracted_"),
        str_to_title
      )
    ) %>%
    select(-col_to_detect) #%>%
#    rowwise() %>% # Ici on cree une colonne resumee des noms detectes contenant un vecteur
#    mutate(
#      name_extracted_all = str_flatten(c_across(starts_with("name_extracted_")), collapse = ";", na.rm = TRUE)
#      ) %>%
#    ungroup()

  cat(paste0("\r", "\u2714", " Mise en forme du tableau", "\033[K"))

  return(data_to_detect)
}
