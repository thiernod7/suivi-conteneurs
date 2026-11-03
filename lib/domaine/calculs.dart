import 'modeles.dart';

// Les calculs du cahier des charges (CLAUDE.md, « Les calculs »).
// Tout est calculé une fois, à la création de [Suivi] ; les écrans ne font qu'afficher.

enum StatutPaiement {
  solde('Soldé'),
  partiel('Partiel'),
  impaye('Impayé');

  const StatutPaiement(this.libelle);
  final String libelle;
}

StatutPaiement statutPaiement(int du, int paye) {
  if (paye >= du) return StatutPaiement.solde;
  return paye > 0 ? StatutPaiement.partiel : StatutPaiement.impaye;
}

class CalculLigne {
  CalculLigne(this.facture, this.ligne);

  final Facture facture;
  final LigneFacture ligne;

  /// Quantité rendue (remise en stock ou au rebut).
  int rendu = 0;
  int rebut = 0;

  /// Montant total des avoirs sur cette ligne.
  int avoirs = 0;

  /// Part des paiements de la facture attribuée à cette ligne.
  int encaisse = 0;

  int get quantiteGardee => ligne.quantite - rendu;
  int get net => ligne.montant - avoirs;
}

class CalculFacture {
  CalculFacture(this.facture, this.lignes, this.age);

  final Facture facture;
  final List<CalculLigne> lignes;

  /// Jours écoulés depuis la date de la facture.
  final int age;
  final List<Paiement> paiements = [];
  final List<CalculAvoir> avoirs = [];

  int get total => lignes.fold(0, (s, l) => s + l.ligne.montant);
  int get net => lignes.fold(0, (s, l) => s + l.net);
  int get paye => paiements.fold(0, (s, p) => s + p.montant);
  int get solde => net - paye > 0 ? net - paye : 0;

  /// Payé en trop après un avoir sur une facture déjà réglée.
  int get credit => paye - net > 0 ? paye - net : 0;
  StatutPaiement get statut => statutPaiement(net, paye);
  Set<String> get conteneurs => {for (final l in lignes) l.ligne.conteneurId};
}

class CalculAvoir {
  CalculAvoir(this.avoir, this.facture, this.ligne, this.deduitDeLaFacture);

  final Avoir avoir;
  final CalculFacture facture;
  final CalculLigne ligne;

  /// Vrai si la facture restait à payer : l'avoir est déduit de la facture.
  /// Faux si elle était déjà payée : il devient un crédit pour le client.
  final bool deduitDeLaFacture;

  int get montant => avoir.quantite * ligne.ligne.prix;
}

class CalculProduit {
  CalculProduit(this.produit);

  final Produit produit;
  int vendu = 0;
  int rendu = 0;
  int rebut = 0;
  int ventes = 0;

  int get stock => produit.quantiteRecue - vendu - rebut;
}

class CalculConteneur {
  CalculConteneur(this.conteneur) : produits = [for (final p in conteneur.produits) CalculProduit(p)];

  final Conteneur conteneur;
  final List<CalculProduit> produits;
  final List<CalculLigne> lignes = [];

  int get cout => conteneur.couts.total;
  int get ventes => lignes.fold(0, (s, l) => s + l.net);
  int get encaisse => lignes.fold(0, (s, l) => s + l.encaisse);
  int get reste => ventes - encaisse;
  int get resultat => ventes - cout;

  /// Le résultat reste provisoire tant que le conteneur n'est pas entièrement vendu.
  bool get provisoire => conteneur.statut != StatutConteneur.vendu;
  int get valeurStock => produits.fold(0, (s, p) => s + p.stock * p.produit.prix);
  int get resultatPrevu => resultat + valeurStock;

  /// Part de la marchandise vendue, en valeur.
  double get partVendue {
    final recu = produits.fold(0, (s, p) => s + p.produit.quantiteRecue * p.produit.prix);
    return recu == 0 ? 0 : produits.fold(0, (s, p) => s + p.vendu * p.produit.prix) / recu;
  }

  Set<String> get clients => {for (final l in lignes) l.facture.clientId};

  /// Ce que chaque client a pris dans ce conteneur et ce qu'il en a payé, ceux qui doivent le plus d'abord.
  List<PartClient> get parClient {
    final parts = <String, PartClient>{};
    for (final l in lignes) {
      final p = parts.putIfAbsent(l.facture.clientId, () => PartClient(l.facture.clientId));
      p.achete += l.net;
      p.paye += l.encaisse;
    }
    return parts.values.toList()..sort((a, b) => b.doit.compareTo(a.doit));
  }

  /// Clients qui doivent encore quelque chose sur ce conteneur.
  int get clientsEnRetard => parClient.where((p) => p.doit > 0).length;
}

class PartClient {
  PartClient(this.clientId);

  final String clientId;
  int achete = 0;
  int paye = 0;

  int get doit => achete - paye;
  StatutPaiement get statut => statutPaiement(achete, paye);
}

class CalculClient {
  CalculClient(this.client);

  final Client client;
  final List<CalculFacture> factures = [];

  int get achete => factures.fold(0, (s, f) => s + f.net);
  int get paye => factures.fold(0, (s, f) => s + f.paye);

  /// Ce que le client doit. Négatif : le client a un crédit.
  int get doit => achete - paye;
  StatutPaiement get statut => statutPaiement(achete, paye);
  bool get depasseLimite => doit > client.limiteCredit;
  Set<String> get conteneurs => {for (final f in factures) ...f.conteneurs};

  /// Ce que le client a pris dans chaque conteneur, du plus récent au plus ancien achat.
  List<PartConteneur> get parConteneur {
    final parts = <String, PartConteneur>{};
    for (final f in [...factures]..sort((a, b) => b.facture.date.compareTo(a.facture.date))) {
      for (final l in f.lignes) {
        final p = parts.putIfAbsent(l.ligne.conteneurId, () => PartConteneur(l.ligne.conteneurId));
        p.quantites[l.ligne.produitId] = (p.quantites[l.ligne.produitId] ?? 0) + l.quantiteGardee;
        p.achete += l.net;
        p.paye += l.encaisse;
      }
    }
    return parts.values.toList();
  }
}

class PartConteneur {
  PartConteneur(this.conteneurId);

  final String conteneurId;

  /// Quantité gardée par produit (après retours).
  final quantites = <String, int>{};
  int achete = 0;
  int paye = 0;

  int get doit => achete - paye;
  StatutPaiement get statut => statutPaiement(achete, paye);
}

class Totaux {
  const Totaux({required this.investi, required this.ventes, required this.encaisse, required this.reste, required this.resultat});

  final int investi;
  final int ventes;
  final int encaisse;
  final int reste;
  final int resultat;
}

class Suivi {
  Suivi(this.donnees, this.aujourdhui) {
    for (final c in donnees.conteneurs) {
      _conteneurs[c.id] = CalculConteneur(c);
    }
    for (final k in donnees.clients) {
      _clients[k.id] = CalculClient(k);
    }
    for (final f in donnees.factures) {
      final cf = CalculFacture(f, [for (final l in f.lignes) CalculLigne(f, l)], aujourdhui.difference(f.date).inDays);
      _factures[f.numero] = cf;
      _clients[f.clientId]!.factures.add(cf);
      for (final l in cf.lignes) {
        _conteneurs[l.ligne.conteneurId]!.lignes.add(l);
      }
    }
    for (final p in donnees.paiements) {
      _factures[p.facture]!.paiements.add(p);
    }
    for (final a in [...donnees.avoirs]..sort((a, b) => a.date.compareTo(b.date))) {
      final f = _factures[a.facture]!;
      final l = f.lignes[a.ligne];
      final payeAvant = f.paiements.where((p) => !p.date.isAfter(a.date)).fold(0, (s, p) => s + p.montant);
      final ca = CalculAvoir(a, f, l, payeAvant < f.net);
      l.avoirs += ca.montant;
      if (a.type.marchandiseRendue) l.rendu += a.quantite;
      if (a.type == TypeAvoir.rebut) l.rebut += a.quantite;
      f.avoirs.add(ca);
      avoirs.add(ca);
    }
    for (final f in _factures.values) {
      _repartirPaiements(f);
    }
    for (final c in _conteneurs.values) {
      for (final l in c.lignes) {
        final p = c.produits.firstWhere((p) => p.produit.id == l.ligne.produitId);
        p.vendu += l.quantiteGardee;
        p.rendu += l.rendu;
        p.rebut += l.rebut;
        p.ventes += l.net;
      }
    }
  }

  final Donnees donnees;
  final DateTime aujourdhui;
  final _conteneurs = <String, CalculConteneur>{};
  final _clients = <String, CalculClient>{};
  final _factures = <String, CalculFacture>{};
  final List<CalculAvoir> avoirs = [];

  List<CalculConteneur> get conteneurs => _conteneurs.values.toList();
  List<CalculClient> get clients => _clients.values.toList();
  List<CalculFacture> get factures => _factures.values.toList();

  CalculConteneur conteneur(String id) => _conteneurs[id]!;
  CalculClient client(String id) => _clients[id]!;
  CalculFacture facture(String numero) => _factures[numero]!;

  Totaux get totaux => Totaux(
        investi: conteneurs.fold(0, (s, c) => s + c.cout),
        ventes: conteneurs.fold(0, (s, c) => s + c.ventes),
        encaisse: conteneurs.fold(0, (s, c) => s + c.encaisse),
        reste: conteneurs.fold(0, (s, c) => s + c.reste),
        resultat: conteneurs.fold(0, (s, c) => s + c.resultat),
      );

  /// Un paiement couvre les lignes de la facture au prorata de leur montant.
  /// Ce qui dépasse le montant de la facture est un crédit client, pas une recette du conteneur.
  static void _repartirPaiements(CalculFacture f) {
    final net = f.net;
    final aRepartir = f.paye < net ? f.paye : net;
    if (net == 0) return;
    var reste = aRepartir;
    for (var i = 0; i < f.lignes.length; i++) {
      final l = f.lignes[i];
      final part = i == f.lignes.length - 1 ? reste : aRepartir * l.net ~/ net;
      l.encaisse = part;
      reste -= part;
    }
  }
}
