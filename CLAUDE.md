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
- **Tableau de bord** : totaux (investi, ventes, encaissé, reste à percevoir, résultat).
- **Conteneurs** : la liste, puis le détail d'un conteneur (coûts, produits reçu / vendu / stock, clients servis et ce qu'ils doivent).
- **Clients** : la liste, puis le détail d'un client (conteneurs reçus, factures, ce qu'il doit).
- **Client dans un conteneur** : ce que ce client a pris dans ce conteneur, produit par produit.
- **Factures** : la liste et l'aperçu d'une facture (lignes, paiements, avoirs, solde).
- **Rapports** : impayés par ancienneté, meilleurs clients, meilleurs produits.
- Un **fil d'Ariane** (ex. `Conteneurs › MDNU 482113 0 › Fatoumata Camara`) pour savoir où l'on est et revenir en arrière.

## Présentation
- Interface entièrement en **français**.
- Montants en **francs guinéens (GNF)**, format français : `1 250 000 GNF`, abrégé `1,3 M` / `1,25 Md`.
- Une **couleur par conteneur**, partout où il apparaît.
- Couleurs de statut : **vert** (soldé), **orange** (partiel), **rouge** (impayé).
- Des **illustrations et icônes** pour rendre le concept facile à comprendre : bateau, conteneurs, camions, produits (sac, bidon, carton, pneu, batterie…), personnages pour les clients.
- Thème clair et sombre.

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
- `lib/ui/` : écrans, thème (`Couleurs` : une couleur par conteneur, couleurs de statut), illustrations dessinées avec `CustomPainter`.
- Tests : `flutter test`. Analyse : `flutter analyze`. Les deux doivent passer avant de pousser.
- Mise en page adaptative : barre de navigation en bas sous 760 px de large, rail sur le côté au-delà.
