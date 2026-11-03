// Ce qu'on enregistre (voir CLAUDE.md, « Ce qu'on enregistre »).
// Tous les montants sont des entiers en francs guinéens (GNF).

enum TypeConteneur {
  dv20("20' DV"),
  dv40("40' DV"),
  hc40("40' HC");

  const TypeConteneur(this.libelle);
  final String libelle;
}

enum StatutConteneur {
  enDistribution('En distribution'),
  vendu('Vendu');

  const StatutConteneur(this.libelle);
  final String libelle;
}

/// Dessin utilisé pour représenter un produit.
enum IconeProduit { sac, sucre, bidon, carton, tomate, lait, pneu, batterie }

class Couts {
  const Couts({required this.achat, required this.fret, required this.douane, required this.manutention});

  final int achat;
  final int fret;
  final int douane;
  final int manutention;

  int get total => achat + fret + douane + manutention;
}

class Produit {
  const Produit({
    required this.id,
    required this.nom,
    required this.unite,
    required this.quantiteRecue,
    required this.prix,
    required this.icone,
  });

  final String id;
  final String nom;
  final String unite;
  final int quantiteRecue;
  final int prix;
  final IconeProduit icone;
}

class Conteneur {
  const Conteneur({
    required this.id,
    required this.numero,
    required this.type,
    required this.origine,
    required this.arrivee,
    required this.fournisseur,
    required this.verseFournisseur,
    required this.statut,
    required this.couleur,
    required this.couts,
    required this.produits,
  });

  final String id;

  /// Numéro ISO 6346, ex. « MDNU 482113 0 ».
  final String numero;
  final TypeConteneur type;
  final String origine;
  final DateTime arrivee;
  final String fournisseur;

  /// Ce qui a déjà été payé au fournisseur sur l'achat.
  final int verseFournisseur;
  final StatutConteneur statut;

  /// Rang de la couleur du conteneur dans la palette.
  final int couleur;
  final Couts couts;
  final List<Produit> produits;

  /// « 482113 » : la partie du numéro qu'on lit le plus vite.
  String get numeroCourt => numero.substring(5, 11);

  /// Le même conteneur, avec quelques changements.
  Conteneur copyWith({
    String? numero,
    TypeConteneur? type,
    String? origine,
    DateTime? arrivee,
    String? fournisseur,
    int? verseFournisseur,
    StatutConteneur? statut,
    Couts? couts,
    List<Produit>? produits,
  }) =>
      Conteneur(
        id: id,
        numero: numero ?? this.numero,
        type: type ?? this.type,
        origine: origine ?? this.origine,
        arrivee: arrivee ?? this.arrivee,
        fournisseur: fournisseur ?? this.fournisseur,
        verseFournisseur: verseFournisseur ?? this.verseFournisseur,
        statut: statut ?? this.statut,
        couleur: couleur,
        couts: couts ?? this.couts,
        produits: produits ?? this.produits,
      );
}

/// Dessin du personnage qui représente un client.
enum Coiffe { turban, foulard, kufi, casquette, aucune }

class Apparence {
  const Apparence({required this.peau, required this.coiffe, required this.couleurCoiffe, required this.vetement});

  final int peau;
  final Coiffe coiffe;
  final int couleurCoiffe;
  final int vetement;
}

class Client {
  const Client({
    required this.id,
    required this.nom,
    required this.quartier,
    required this.limiteCredit,
    required this.apparence,
  });

  final String id;
  final String nom;
  final String quartier;
  final int limiteCredit;
  final Apparence apparence;

  Client copyWith({String? nom, String? quartier, int? limiteCredit}) => Client(
        id: id,
        nom: nom ?? this.nom,
        quartier: quartier ?? this.quartier,
        limiteCredit: limiteCredit ?? this.limiteCredit,
        apparence: apparence,
      );
}

class LigneFacture {
  const LigneFacture({required this.conteneurId, required this.produitId, required this.quantite, required this.prix});

  final String conteneurId;
  final String produitId;
  final int quantite;

  /// Prix unitaire au moment de la vente.
  final int prix;

  int get montant => quantite * prix;
}

class Facture {
  const Facture({required this.numero, required this.clientId, required this.date, required this.lignes});

  final String numero;
  final String clientId;
  final DateTime date;
  final List<LigneFacture> lignes;
}

enum ModePaiement {
  especes('Espèces'),
  orangeMoney('Orange Money'),
  mtnMomo('MTN MoMo'),
  virement('Virement');

  const ModePaiement(this.libelle);
  final String libelle;
}

class Paiement {
  const Paiement({required this.facture, required this.date, required this.montant, required this.mode, this.remarque});

  final String facture;
  final DateTime date;
  final int montant;
  final ModePaiement mode;
  final String? remarque;
}

enum TypeAvoir {
  /// La marchandise revient et peut être revendue.
  remisEnStock('Rendu · remis en stock'),

  /// La marchandise revient abîmée : perte pour le conteneur.
  rebut('Rendu · mis au rebut'),

  /// Le client garde la marchandise abîmée et paie moins.
  remise('Remise sans retour');

  const TypeAvoir(this.libelle);
  final String libelle;

  bool get marchandiseRendue => this != remise;
}

class Avoir {
  const Avoir({
    required this.numero,
    required this.facture,
    required this.ligne,
    required this.quantite,
    required this.type,
    required this.date,
    required this.motif,
  });

  final String numero;
  final String facture;

  /// Rang de la ligne concernée dans la facture.
  final int ligne;
  final int quantite;
  final TypeAvoir type;
  final DateTime date;
  final String motif;
}

class Donnees {
  const Donnees({
    required this.conteneurs,
    required this.clients,
    required this.factures,
    required this.paiements,
    required this.avoirs,
  });

  final List<Conteneur> conteneurs;
  final List<Client> clients;
  final List<Facture> factures;
  final List<Paiement> paiements;
  final List<Avoir> avoirs;
}
