## code to prepare `DATASET` dataset goes here

library(readxl)
library(dplyr)
library(readr)
library(stringr)

# Fonction utilisee ci-dessous => https://www.r-bloggers.com/2018/07/the-notin-operator/
`%ni%` <- Negate(`%in%`)

# TOUS LES NOMS ------

hommes <- read_excel("data-raw/Prénoms_Population_2022.xlsx",
                     sheet = "Hommes", skip = 1) %>%
  select(2:3)
names(hommes)[1] <- "name_detected"
names(hommes)[2] <- "n_h"

femmes <- read_excel("data-raw/Prénoms_Population_2022.xlsx",
                     sheet = "Femmes", skip = 1) %>%
  select(2:3)
names(femmes)[1] <- "name_detected"
names(femmes)[2] <- "n_f"

noms <- femmes %>%
  full_join(hommes, by = "name_detected")

# On calcule les effectifs et les proportions d'H et F
noms <- noms %>%
  mutate(name_detected = str_to_title(str_trim(name_detected))) %>%
  group_by(name_detected) %>%
  summarise(n_f = sum(n_f, na.rm = TRUE),
            n_h = sum(n_h, na.rm = TRUE),
            n_tot = n_f+n_h) %>%
  ungroup() %>%
  mutate(prop_f = n_f/(n_f+n_h),
         prop_h = n_h/(n_f+n_h),
         genre_detected = case_when(
           prop_f > 0.5 ~ "F",
           prop_h > 0.5 ~ "H",
           prop_f == 0.5 ~ "half_&_half"
         )
  )

# On double les noms avec et sans tiret
noms_tiret <- noms %>%
  filter(str_detect(name_detected, "-") == TRUE) %>%
  mutate(name_detected = str_replace_all(name_detected, "-", " "))

noms <- noms %>%
  bind_rows(noms_tiret) %>%
  mutate(length = str_length(name_detected))


# --- DICTIONNAIRE DE NOMS COMMUNS ---
dico_fr <- read_excel("data-raw/liste_frequence_des_mots_132918_292375.xls") %>%
  select(word = 3) %>%
  distinct(word) %>%
  mutate(dico_fr = "fr") %>%
  filter(str_detect(word,"[[:upper:]]") != TRUE & str_length(word) != 1) %>%
  filter(word %ni% c("françois", "pierre"))

#dico_fr <- read_csv("dico/liste_francais.txt",
#                    col_names = FALSE) %>%
#  rename(word = 1) %>%
#  mutate(dico_fr = 1) %>%
#  filter(str_detect(word,"[[:upper:]]") != TRUE)

dico_nl <- read_csv("data-raw/1000_meeste_gebruikte.txt", col_names = FALSE) %>%
  select(word = 1) %>%
  distinct(word) %>%
  mutate(dico_nl = "nl") %>%
  filter(str_detect(word,"[[:upper:]]") != TRUE & str_length(word) != 1)

#dico_nl <- read_csv("dico/nl_50k.txt", col_names = FALSE) %>%
#  select(value = 1) %>%
#  separate(value, sep = " ", c("word", "freq"), convert = TRUE) %>%
#  filter(str_length(word) != 1) %>%
#  mutate(rank = rank(-freq)) %>%
#  filter(rank <= 1362) %>%
#  distinct(word) %>%
#  mutate(dico = 1)

dico <- dico_fr %>%
  full_join(dico_nl, by = "word") %>%
  rowwise() %>% # Ici on crée une colonne résumée des noms détectées contenant un vecteur
  mutate(
    dico = str_flatten(c_across(starts_with("dico_")), collapse = ";", na.rm = TRUE)
  ) %>%
  ungroup() %>%
  select(-dico_fr, -dico_nl)
# --- FIN DICO ---


noms <- noms %>%
  mutate(name_detected_lower = str_to_lower(name_detected)) %>%
  left_join(dico, by = c("name_detected_lower" = "word")) %>%
  select(-name_detected_lower)

#sum(duplicated(noms$name_detected))
#write_csv2(noms, "noms.csv")
#save(noms, file='noms.rda', compress='xz')

# LES NOMS DES +65ANS ------

hommes_65 <- read_excel("data-raw/Prénoms_Population_2009.xlsx",
                        sheet = "Hommes", skip = 1) %>%
  select(20:21)
names(hommes_65)[1] <- "name_detected"
names(hommes_65)[2] <- "n_h"

# On enlève les NA (propres au noms +65ans)
hommes_65 <- hommes_65 %>%
  filter(!is.na(name_detected))

femmes_65 <- read_excel("data-raw/Prénoms_Population_2009.xlsx",
                        sheet = "Femmes", skip = 1) %>%
  select(20:21)
names(femmes_65)[1] <- "name_detected"
names(femmes_65)[2] <- "n_f"

# On enlève les NA (propres au noms +65ans)
femmes_65 <- femmes_65 %>%
  filter(!is.na(name_detected))

noms_65 <- femmes_65 %>%
  full_join(hommes_65, by = "name_detected")

# On calcule les effectifs et les proportions d'H et F
noms_65 <- noms_65 %>%
  mutate(name_detected = str_to_title(str_trim(name_detected))) %>%
  group_by(name_detected) %>%
  summarise(n_f = sum(n_f, na.rm = TRUE),
            n_h = sum(n_h, na.rm = TRUE),
            n_tot = n_f+n_h) %>%
  ungroup() %>%
  mutate(prop_f = n_f/(n_f+n_h),
         prop_h = n_h/(n_f+n_h),
         genre_detected = case_when(
           prop_f > 0.5 ~ "F",
           prop_h > 0.5 ~ "H",
           prop_f == 0.5 ~ "half_&_half"
         )
  )

# On double les noms avec et sans tiret
noms_tiret_65 <- noms_65 %>%
  filter(str_detect(name_detected, "-") == TRUE) %>%
  mutate(name_detected = str_replace_all(name_detected, "-", " "))

noms_65 <- noms_65 %>%
  bind_rows(noms_tiret_65) %>%
  mutate(length = str_length(name_detected)) %>%
  mutate(name_detected_lower = str_to_lower(name_detected)) %>%
  left_join(dico, by = c("name_detected_lower" = "word")) %>%
  select(-name_detected_lower)


#sum(duplicated(noms_65$name_detected))
#write_csv2(noms_65, "noms_65.csv")
#save(noms_65, file='noms_65.rda', compress='xz')

rm(femmes, femmes_65, hommes, hommes_65, noms, noms_65, noms_tiret, noms_tiret_65, dico, dico_fr, dico_nl)

usethis::use_data(noms, noms_65, overwrite = TRUE)
