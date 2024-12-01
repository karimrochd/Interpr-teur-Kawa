# Interpréteur Kawa

Le projet d'interpréteur Kawa, réalisé par Karim ROCHD et Jewin CHENG est une implémentation d'un langage de programmation orienté objet simplifié, inspiré par le langage Java. Il est réalisé en OCaml et utilise `ocamllex` et `menhir` pour l'analyse lexicale et syntaxique.

## Description de Kawa

Kawa est un langage de programmation qui intègre des concepts de programmation orientée objet, y compris la déclaration de classes, la création d'objets, et la définition de méthodes. Il offre un système de typage statique et prend en charge des opérations arithmétiques de base, des structures conditionnelles, et des boucles itératives.

## Structure du Projet

Le projet est divisé en plusieurs composants principaux :

- **Lexer (`kawalexer.mll`)** : Analyse lexicale du langage, reconnaissant les tokens et gérant les commentaires.
- **Parser (`kawaparser.mly`)** : Construit l'arbre syntaxique abstrait en analysant la structure grammaticale des programmes.
- **Typechecker (`typechecker.ml`)** : Vérifie la cohérence des types dans le code, s'assurant que les opérations et affectations sont valides.
- **Interpréteur (`interpreter.ml`)** : Exécute le code Kawa à partir de l'arbre syntaxique, gérant les expressions, instructions, et appels de méthodes.

## Fonctionnalités Clés

- **Types de Données** : Support des types de base tels que `int` et `bool`, ainsi que des types définis par l'utilisateur via des classes.
- **Classes et Objets** : Possibilité de définir des classes avec des attributs et des méthodes. Création et manipulation d'instances de ces classes.
- **Méthodes** : Définition de méthodes au sein des classes, y compris un constructeur pour l'initialisation des objets.
- **Opérations Arithmétiques et Logiques** : Prise en charge des opérations de base pour la manipulation de données numériques et booléennes.
- **Structures de Contrôle** : Implémentation des instructions conditionnelles (`if/else`) et des boucles (`while`).

## Développement et Tests

Au cours du développement, une série de tests supplémentaires a été intégrée pour évaluer de manière plus approfondie les fonctionnalités du langage Kawa, notamment les opérations arithmétiques, la manipulation des variables, et le contrôle de flux. Ces tests ont permis de confirmer le bon fonctionnement de la majorité des aspects de l'interpréteur. Cependant, nous avons identifié un problème spécifique concernant la gestion du caractère '-' par le lexer. Actuellement, le lexer ne parvient pas à interpréter correctement ce caractère dans certains contextes, notamment lorsqu'il est utilisé comme opérateur de soustraction ou pour dénoter des nombres négatifs. 
Opérations consécutifs possibles qu'en mettant chaque opérations entre parenthèses. 
Tentative d'implémentation de l'héritage à plusieurs niveaux, classe qui hérite d'une autre classe qui elle en hérite aussi. L'héritage à un niveau fonctionne, les appels de méthodes, constructeurs et typage dynamique fonctionne.
Ce qui est fonctionnelle est : les boucles conditionnelles, la boucle while, une partie du paradigme objet, l'utilisation/modification/affectation de variables/objets, les opérations binaires, unaire que sur le booléen.

### Exemples de Tests

- **Tests Lexicaux** : Validation de la reconnaissance des tokens et de la gestion des commentaires.
- **Tests Syntaxiques** : Vérification de la construction correcte des arbres syntaxiques pour divers exemples de code.
- **Tests de Type** : Contrôle de la cohérence des types dans différents contextes de programmation.
- **Tests d'Exécution** : Exécution de programmes de test pour évaluer la fiabilité de l'interpréteur.

## Conclusion

L'interpréteur Kawa est un projet éducatif visant à illustrer les concepts fondamentaux de la programmation de langages et de l'implémentation d'interpréteurs. Bien que simplifié par rapport à des langages de programmation complets, Kawa offre une base solide pour comprendre la structure et le fonctionnement d'un interpréteur de langage de programmation.
