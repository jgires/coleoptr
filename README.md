
<!-- README.md is generated from README.Rmd. Please edit that file -->

# coleoptr

<!-- badges: start -->
<!-- badges: end -->

`coleoptr` permet :

-   de détecter les prénoms dans des chaines de caractères ;
-   de dire la probabilité d’appartenance des prénoms à chaque sexe.

## Installation

Vous pouvez installer la version de développement de coleoptr depuis
[GitHub](https://github.com/) avec cette commande :

``` r
# install.packages("devtools")
devtools::install_github("jgires/coleoptr")
```

## Example

Voici un example qui exemplifie les deux fonctions de `coleoptr` : nous
allons 1) détecter des prénoms contenus dans des noms de rue et 2)
prédire le genre de ces prénoms.

La fonction `name_be_extract` permet de détecter et d’extraire les
prénoms dans une chaîne de caractère (ici le nom de rue) :

``` r
library(coleoptr)
x <- data.frame(rue = c("Avenue Paul Héger",
                        "Jardin des Justes",
                        "Chemin Marie Popelin",
                        "Place Sainte-Catherine",
                        "Avenue Paul Dejaer",
                        "Rue de Molenbeek",
                        "Boulevard Léopold III",
                        "Avenue Sainte-Anne",
                        "Rue Saints-Pierre et Paul"
                        ))
result <- name_be_extract(data_to_detect = x,
                          col_to_detect = "rue")
```

``` r
result[,c("rue", "name_extracted_1", "name_extracted_2")]
#> # A tibble: 9 × 3
#>   rue                       name_extracted_1 name_extracted_2
#>   <chr>                     <chr>            <chr>           
#> 1 Avenue Paul Héger         Paul             <NA>            
#> 2 Jardin des Justes         <NA>             <NA>            
#> 3 Chemin Marie Popelin      Marie            <NA>            
#> 4 Place Sainte-Catherine    Catherine        <NA>            
#> 5 Avenue Paul Dejaer        Paul             <NA>            
#> 6 Rue de Molenbeek          <NA>             <NA>            
#> 7 Boulevard Léopold III     Léopold          <NA>            
#> 8 Avenue Sainte-Anne        Anne             <NA>            
#> 9 Rue Saints-Pierre et Paul Pierre           Paul
```

La fonction `name_be_genderize` permet quand à elle de prédire le genre
des prénoms. Elle peut s’appliquer sur les résultats de
`name_be_extract` :

``` r
result_genderized <- name_be_genderize(result,
                                       col_name = "name_extracted_1")
```

``` r
result_genderized[,c("rue", "name_extracted_1", "prop_f", "prop_h", "genre_detected")]
#> # A tibble: 9 × 5
#>   rue                       name_extracted_1    prop_f    prop_h genre_detected
#>   <chr>                     <chr>                <dbl>     <dbl> <chr>         
#> 1 Avenue Paul Héger         Paul              0         1        H             
#> 2 Jardin des Justes         <NA>             NA        NA        <NA>          
#> 3 Chemin Marie Popelin      Marie             0.999     0.00108  F             
#> 4 Place Sainte-Catherine    Catherine         1         0        F             
#> 5 Avenue Paul Dejaer        Paul              0         1        H             
#> 6 Rue de Molenbeek          <NA>             NA        NA        <NA>          
#> 7 Boulevard Léopold III     Léopold           0         1        H             
#> 8 Avenue Sainte-Anne        Anne              0.999     0.000753 F             
#> 9 Rue Saints-Pierre et Paul Pierre            0.000218  1.00     H
```

## Options

De nombreuses options existent et seront documentées plus tard…
