# Suivi des conteneurs — cahier des charges

## Le besoin, en une phrase
Un importateur du marché de Madina (Conakry, Guinée) fait venir des conteneurs par bateau. Pour **chaque conteneur**, il veut savoir : à quels clients la marchandise est partie, qui n'a pas encore payé, et combien il a gagné ou perdu.

## Comment ça marche, simplement
1. **Le bateau arrive** au port de Conakry avec des conteneurs. Chaque conteneur a un coût.
2. **On vide le conteneur** : on note les produits et leurs quantités (riz, huile, sucre, pneus…).
3. **Les clients sont servis** : le contenu d'un conteneur part chez plusieurs commerçants. Un même commerçant peut recevoir des produits de plusieurs conteneurs.
4. **On suit l'argent** : chaque client paie tout, une partie ou rien. L'importateur voit ce qu'on lui doit et le résultat de chaque conteneur.

## Ce qu'on enregistre
- **Conteneur** : numéro (ex. `MDNU 482113 0`), type (20', 40', 40' HC), pays d'origine, date d'arrivée, fournisseur, statut (`En distribution` / `Vendu`).
  - Ses coûts : achat de la marchandise, fret maritime, dédouanement, manutention et transport.
  - Ce qui a déjà été versé au fournisseur.
- **Produit du conteneur** : nom, unité (sacs, bidons, cartons, pièces), quantité reçue, prix de vente.
- **Client** : nom, quartier ou marché, limite de crédit.
- **Facture** : numéro (ex. `FAC-2026-008`), date, client, lignes. Chaque ligne indique le produit, la quantité, le prix et **le conteneur d'où il vient**. Une facture peut contenir des produits de plusieurs conteneurs.
- **Paiement** : facture, date, montant, mode (espèces, Orange Money, MTN MoMo, virement). Une facture peut être payée en plusieurs fois.
- **Avoir** (retour ou remise) : numéro (ex. `AV-2026-001`), facture et ligne concernées, quantité, motif, date.

## Les calculs
- **Coût d'un conteneur** = achat + fret + dédouanement + manutention.
- **Ventes d'un conteneur** = total de ses lignes de facture, moins les avoirs.
- **Encaissé** = paiements reçus. **Reste à percevoir** = ventes − encaissé.
- **Résultat** = ventes − coût. Il est **provisoire** tant que le conteneur n'est pas entièrement vendu.
- **Stock restant** = quantité reçue − quantité vendue. **Résultat prévu** = résultat + valeur du stock restant.
- **Statut de paiement** (client ou facture) : `Soldé` (tout payé), `Partiel`, `Impayé`.
- **Ancienneté d'une facture impayée** : 0–30 jours, 31–60, 61–90, plus de 90.
- **Limite de crédit** : alerte quand ce que doit un client dépasse sa limite.
- **Paiement d'une facture à plusieurs conteneurs** : il est réparti entre les lignes **au prorata** de leur montant. Ce qui est payé en trop (après un avoir sur une facture déjà réglée) est un crédit pour le client, pas une recette du conteneur.

### Retours et avoirs
Trois cas :
- **Marchandise rendue et remise en stock** : elle peut être revendue.
- **Marchandise rendue mais abîmée** (mise au rebut) : c'est une perte pour le conteneur.
- **Remise sans retour** : le client garde la marchandise abîmée et paie moins.

Si la facture n'est pas encore payée, l'avoir est **déduit de la facture**. Si elle est déjà payée, il devient un **crédit pour le client**, à déduire d'une prochaine facture.

## Inspiration : Invoice Manager
Le client utilisait **Invoice Manager**, une application de facturation. Elle sert **seulement d'inspiration** pour comprendre ses habitudes : facture avec son solde, paiement en plusieurs fois, liste des clients et fournisseurs, aperçu de facture, rapports des impayés.

On ne la copie pas. On conçoit **nos propres interfaces et notre propre expérience utilisateur**, pensées pour ce besoin, avec le **conteneur au centre** de tout.

## Écrans attendus
- **Accueil** : gagné ou perdu, ce qu'on me doit, qui me doit le plus, mes conteneurs.
- **Conteneurs** : la liste, puis un conteneur (dépensé, vendu, on me doit, gagné ; ce qu'il y a dedans ; ses clients).
- **Clients** : la liste, puis un client (ce qu'il a pris, dans quels conteneurs, ce qu'il doit).
- **Factures** : la liste, puis une facture (ce qui a été pris, les paiements, ce qui reste à payer).
- **Plus** (5e bouton) : il n'ouvre pas d'écran, il fait **monter un menu du bas** (bottom sheet) par-dessus l'écran : Produits, Paiements, Retours, Fournisseurs (avec un petit détail sous chacun), **Mode clair / Mode sombre** (gardé sur l'appareil), et « Remettre les exemples » en rouge. Le bouton Plus reste choisi quand on est sur un de ces écrans.
- Les rapports (impayés anciens, meilleurs clients, meilleurs produits) viennent sur l'Accueil, pas dans un écran à part.
- **Formulaires d'ajout** (`lib/ui/formulaires/`), en plein écran : une croix pour annuler, un grand bouton **Enregistrer** en bas.
  - On les ouvre avec le gros bouton **+** en bas des listes (Nouveau conteneur, client, facture, produit, paiement, retour) ou depuis une page : Ajouter un produit (conteneur), Nouvelle facture (client), Ajouter un paiement et Retour (facture).
  - Montants écrits par paquets de trois chiffres pendant la saisie. Choix en boutons visibles (taille, unité, image du produit, « Comment ? » pour le mode de paiement). Client, facture, produit : on les choisit dans un panneau qui monte du bas, avec une recherche.
  - Contrôles : champs obligatoires, numéro de conteneur (4 lettres et 7 chiffres, pas deux fois le même), quantité vendue ≤ ce qui reste, paiement ≤ ce qui reste à payer, retour ≤ ce qui a été pris. Messages courts : « Obligatoire », « Il reste 230 ».
  - Facture : lignes produit par produit (le prix se remplit tout seul), montant calculé, « Payé maintenant » avec Rien / Tout. Numéros donnés tout seuls : `FAC-2026-017`, `AV-2026-004`.
- **Modifier et supprimer** : les mêmes formulaires, déjà remplis (titre « Modifier le… »).
  - On les ouvre avec le **crayon ✎** en haut d'un conteneur, d'un client, d'une facture ; en touchant un produit (dans son conteneur), un paiement ou un retour (dans sa facture), ou une ligne des listes Produits, Paiements, Retours.
  - **Supprimer** : un seul endroit, le bouton rouge en bas du formulaire de modification, toujours avec une confirmation (« Oui, supprimer » / « Non »).
  - Protections : un conteneur ou un produit utilisé par des factures, un client qui a des factures, ne se suppriment pas (message « Impossible » qui dit quoi faire d'abord). Supprimer une facture supprime aussi ses paiements et ses retours. La quantité reçue d'un produit ne descend pas sous ce qui est vendu ; un paiement ne dépasse pas ce qui reste à payer ; le montant d'une facture ne descend pas sous ce qui est déjà reçu ; les produits d'une facture ne changent plus quand elle a des retours.
  - Changer le prix d'un produit ne change pas les factures déjà faites. Un conteneur passe à « Tout vendu » depuis sa modification.
- **Recherche et filtres**, les mêmes sur les trois listes (`lib/ui/recherche.dart`) :
  - une case pour chercher (sans tenir compte des majuscules ni des accents), avec une croix pour l'effacer ;
  - à côté, un bouton **Filtres** (icône réglages) avec un petit nombre quand des filtres sont actifs ;
  - il ouvre un **panneau qui monte du bas** (bottom sheet) : titre « Filtres », les choix en boutons visibles avec leur nombre (pas de listes déroulantes), les conteneurs (leur carré de couleur ; toucher à nouveau enlève), puis **Réinitialiser** et **Voir les résultats · N**. Les choix ne s'appliquent qu'en touchant « Voir les résultats » ;
  - les filtres actifs s'affichent sous la recherche, avec une croix pour les enlever ;
  - si rien ne correspond : « Tout voir » remet tout à zéro.
  - Conteneurs : numéro, pays, fournisseur ou produit ; Tous / En vente / Tout vendu.
  - Clients : nom ou quartier ; Tous / Me doivent / Payé / Limite dépassée ; par conteneur.
  - Factures : nom, numéro ou produit ; Toutes / À payer / En retard (plus de 30 jours) / Payé ; par conteneur.

## Simplicité : la règle principale
L'application sera utilisée par des personnes qui lisent peu. Elle doit se comprendre **au premier coup d'œil**.
- **Peu de mots**, des mots de tous les jours. Pas de phrases d'explication. Un titre court par écran.
- **Toujours le même mot pour la même chose** :

| On écrit | Pour dire |
|---|---|
| Dépensé | coût du conteneur |
| Vendu | ventes |
| Reçu | argent encaissé |
| On me doit | reste à percevoir |
| Gagné / Perdu | résultat (jamais un montant négatif : on écrit « Perdu » et le montant) |
| Payé / En partie / Pas payé | statut de paiement |
| En vente / Tout vendu | statut du conteneur |
| Dedans | produits du conteneur |
| Reste | stock |
| Rendus · abîmés | retours, mise au rebut |
| Acheté | ce qu'un client a pris (après retours) |
| Me doit / Je lui dois | ce qu'un client doit / son crédit |
| Limite · Limite dépassée | limite de crédit |
| À payer | ce qui reste à payer sur une facture |
| Montant · Retours · Reçu | le compte d'une facture : montant − retours − reçu = à payer |
| 92 jours | âge d'une facture pas encore payée (en rouge au-delà de 30 jours) |

- **Une icône à côté de chaque mot** et **une couleur pour chaque statut** : vert ✓ Payé, orange En partie, rouge ✗ Pas payé. Jamais la couleur seule.
- **Les montants en grand**, abrégés : `381,9 M GNF`, `1,07 Md GNF`.
- **Gros boutons**, faciles à toucher. 5 boutons de navigation : Accueil, Conteneurs, Clients, Factures, Plus.
- Un **bouton retour** en haut de chaque écran de détail.
- Un conteneur = un **carré de couleur** et les 6 chiffres qu'on retient (`482113`). Un client = un **rond avec ses initiales**. Un produit = une **petite image** (sac, bidon, carton, pneu…).
- Police **Lexend**, conçue pour faciliter la lecture. Texte un peu plus grand que d'habitude. L'écran doit rester correct quand le téléphone est réglé en **grand texte**.
- Interface en **français**. Thème clair et sombre.

### Style
- Moderne et léger : fond clair, **cartes blanches bordées d'un trait fin** (0,8 px), coins arrondis, beaucoup d'espace.
- **Icônes fines** : Material Symbols (`material_symbols_icons`), épaisseur 300 ; l'icône du bouton choisi est pleine.
- Couleur réservée au sens : vert reçu / payé, orange en partie, rouge on me doit / pas payé. Le reste en gris.
- Montants en demi-gras (Lexend 600), le reste en normal ; « GNF » en petit et en gris.

## Le projet
- **Étape 1 — Prototype** : application **Flutter web adaptative** (téléphone et ordinateur), avec des **données d'exemple**, sans serveur. Publiée sur GitHub Pages pour la montrer au client.
- **Étape 2** : validation avec le client.
- **Étape 3** : application **Android**, à partir du même code.
- **Étape 4** : application **Windows (.exe)**, à partir du même code, fabriquée par GitHub Actions sur une machine Windows.
- Plus tard : un **serveur** (Django ou FastAPI) pour enregistrer les données et les partager entre appareils. iPhone possible (demande un Mac et un compte Apple).

## Stack du développeur
Python, Django, FastAPI, React.js, React Native, Tailwind CSS. Pour ce projet : **Flutter (Dart)**.

## Organisation du code
- `lib/domaine/` : modèles et calculs, en Dart pur, sans interface. Les écrans ne font qu'afficher ce que `Suivi` a calculé.
- `lib/donnees/exemple.dart` : données d'exemple du prototype.
- `lib/donnees/depot.dart` : `Depot`, les données qu'on modifie (ajouts, numéros automatiques). Elles sont **gardées sur l'appareil** (`shared_preferences`, en JSON via `json.dart`) ; la première fois, ce sont les exemples. Après chaque ajout, `Suivi` est recalculé et tous les écrans se mettent à jour.
- Date du jour : la vraie date dans l'application ; une date fixe (`aujourdhuiExemple`) dans les tests.
- `lib/ui/` : écrans, thème (`Couleurs` : une couleur par conteneur, couleurs de statut), composants communs (`composants.dart`), images des produits.
- Tests : `flutter test` (calculs, écrans sur ordinateur, téléphone et grand texte). Analyse : `flutter analyze`. Les deux doivent passer avant de pousser.
- Mise en page adaptative : barre de navigation en bas sous 760 px de large, rail sur le côté au-delà.
