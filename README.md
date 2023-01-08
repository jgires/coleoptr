
<!-- README.md is generated from README.Rmd. Please edit that file -->

# coleoptr

<!-- badges: start -->
<!-- badges: end -->

`coleoptr` est un package R qui permet :

-   de détecter les prénoms dans des chaînes de caractères ;
-   d’estimer l’appartenance des prénoms à chaque sexe.

Le package repose sur un dictionnaire de prénoms de l’ensemble de la
population belge en 2022 compilé par
[Statbel](https://statbel.fgov.be/fr/themes/population/noms-et-prenoms/prenoms-femmes-et-hommes#figures).
Celui-ci contient 48.505 prénoms et permet de détecter les prénoms
utilisés pour nommer les personnes en Belgique (et de ce fait les
institutions, rues, écoles, commerces, etc.).

## Installation

Vous pouvez installer la version de développement de `coleoptr` depuis
[GitHub](https://github.com/) avec cette commande :

``` r
# install.packages("devtools")
devtools::install_github("jgires/coleoptr")
```

## Exemple

Voici un exemple à partir de noms de rue qui illustre les deux fonctions
de `coleoptr`.

La fonction `name_be_extract` permet de détecter et d’extraire les
prénoms dans une chaîne de caractères (ici le nom de rue) :

``` r
library(coleoptr)
x <- data.frame(rue = c("Rue Albert Dekkers",
                        "Avenue du Pont de Luttre",
                        "rue du Champ Ste-Anne",
                        "Toekomststraat",
                        "Avenue du Pont de Luttre",
                        "Sint-Jozefstraat",
                        "Rue Coron Paulette",
                        "Rue Marchand Père et Fils",
                        "Rue Saints-Pierre et Paul",
                        "Katarinalaan"
                        ))
result <- name_be_extract(data_to_detect = x,
                          col_to_detect = "rue",
                          nl_detect = TRUE)
```

``` r
result[,c("rue", "name_extracted_1", "name_extracted_2")]
#> # A tibble: 10 × 3
#>    rue                       name_extracted_1 name_extracted_2
#>    <chr>                     <chr>            <chr>           
#>  1 Rue Albert Dekkers        Albert           <NA>            
#>  2 Avenue du Pont de Luttre  <NA>             <NA>            
#>  3 rue du Champ Ste-Anne     Anne             <NA>            
#>  4 Toekomststraat            <NA>             <NA>            
#>  5 Avenue du Pont de Luttre  <NA>             <NA>            
#>  6 Sint-Jozefstraat          Jozef            <NA>            
#>  7 Rue Coron Paulette        Paulette         <NA>            
#>  8 Rue Marchand Père et Fils <NA>             <NA>            
#>  9 Rue Saints-Pierre et Paul Pierre           Paul            
#> 10 Katarinalaan              Katarina         <NA>
```

La fonction `name_be_genderize` permet quand à elle d’estimer le genre
des prénoms. Elle peut s’appliquer sur les résultats de
`name_be_extract`. Dans tous les cas, elle s’applique sur un champ
contenant le nom seul :

``` r
result_genderized <- name_be_genderize(result,
                                       col_name = "name_extracted_1")
```

``` r
result_genderized[,c("rue", "name_extracted_1", "prop_f", "prop_h", "genre_detected")]
#> # A tibble: 10 × 5
#>    rue                       name_extracted_1    prop_f    prop_h genre_detected
#>    <chr>                     <chr>                <dbl>     <dbl> <chr>         
#>  1 Rue Albert Dekkers        Albert            0         1        H             
#>  2 Avenue du Pont de Luttre  <NA>             NA        NA        <NA>          
#>  3 rue du Champ Ste-Anne     Anne              0.999     0.000753 F             
#>  4 Toekomststraat            <NA>             NA        NA        <NA>          
#>  5 Avenue du Pont de Luttre  <NA>             NA        NA        <NA>          
#>  6 Sint-Jozefstraat          Jozef             0         1        H             
#>  7 Rue Coron Paulette        Paulette          1         0        F             
#>  8 Rue Marchand Père et Fils <NA>             NA        NA        <NA>          
#>  9 Rue Saints-Pierre et Paul Pierre            0.000218  1.00     H             
#> 10 Katarinalaan              Katarina          1         0        F
```

## Options

Plusieurs options existent et seront documentées plus tard…

## Développements futurs ?

Des difficultés spécifiques se posent dans la détection de prénoms en
**néérlandais** (et sans doute en **allemand**), puisque le prénom est
parfois accolé à l’objet/institution nommée par ce prénom. Par exemple,
pour la voierie *Katarinalaan*, le prénom et l’avenue (*laan*) forment
un seul mot. La fonction `name_be_extract` peut tout à fait détecter et
extraire les prénoms à l’intérieur de mots plus longs (en indiquant
l’option `respect_boundaries = FALSE`), mais alors la fonction détecte
un grand nombre de faux positifs : elle détecte pour *Place de Ninove*
les prénoms *Lac* et *Nino*, par exemple (le problème est le même en
néérlandais).

La solution qui a été trouvée est de maintenir le respect des frontières
de mots (`respect_boundaries = TRUE` est l’option par défaut), et
d’indiquer avec l’option `nl_detect = TRUE` (utilisée dans l’exemple
précédent) que l’on fait une recherche dans des champs écrits en
néérlandais. La fonction opère alors une série de corrections en REGEX
au préalable pour rendre possible la détection des prénoms accolés à un
certain nombre d’objets/institutions (*pour l’instant : uniquement
voieries et institutions scolaires jusqu’au secondaire*). Le soucis de
cette procédure est qu’elle demande des corrections particulières à la
nature des données. A terme, la solution est probablement de créer un
dictionnaire de correction en néérlandais, reprenant de nombreux
objets/institutions, pour englober le plus de cas possibles. Cette
solution demande cependant un gros travail dont je ne sais pas s’il est
réellement faisable. Si quelqu’un a une solution technique plus
parcimonieuse et systématique, je suis preneur.
