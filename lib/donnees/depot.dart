import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domaine/calculs.dart';
import '../domaine/modeles.dart';
import 'exemple.dart';
import 'json.dart';

/// Les données de l'application : on les lit, on en ajoute, et tous les écrans se mettent à jour.
/// Elles sont gardées sur l'appareil (navigateur, téléphone, ordinateur), sans serveur.
class Depot extends ChangeNotifier {
  // Un paramètre nommé ne peut pas être privé : on garde l'affectation explicite.
  // ignore: prefer_initializing_formals
  Depot(Donnees donnees, {required this.aujourdhui, SharedPreferences? stockage}) : _stockage = stockage {
    _remplacer(donnees, sauver: false);
  }

  static const _cle = 'suivi_conteneurs.donnees';

  /// Lit les données gardées sur l'appareil, ou prend les données d'exemple la première fois.
  static Future<Depot> charger(DateTime aujourdhui) async {
    final stockage = await SharedPreferences.getInstance();
    var donnees = donneesExemple;
    final texte = stockage.getString(_cle);
    if (texte != null) {
      try {
        donnees = donneesDepuisJson(jsonDecode(texte) as Json);
      } on Object catch (e) {
        debugPrint('Données illisibles, on reprend les exemples : $e');
      }
    }
    return Depot(donnees, aujourdhui: aujourdhui, stockage: stockage);
  }

  final DateTime aujourdhui;
  final SharedPreferences? _stockage;
  late Donnees _donnees;
  late Suivi _suivi;

  Donnees get donnees => _donnees;
  Suivi get suivi => _suivi;

  void _remplacer(Donnees d, {bool sauver = true}) {
    _donnees = d;
    _suivi = Suivi(d, aujourdhui);
    if (sauver) {
      _stockage?.setString(_cle, jsonEncode(donneesVersJson(d)));
      notifyListeners();
    }
  }

  Donnees _avec({
    List<Conteneur>? conteneurs,
    List<Client>? clients,
    List<Facture>? factures,
    List<Paiement>? paiements,
    List<Avoir>? avoirs,
  }) =>
      Donnees(
        conteneurs: conteneurs ?? _donnees.conteneurs,
        clients: clients ?? _donnees.clients,
        factures: factures ?? _donnees.factures,
        paiements: paiements ?? _donnees.paiements,
        avoirs: avoirs ?? _donnees.avoirs,
      );

  /// Prochain numéro libre de la forme « FAC-2026-017 ».
  String _prochainNumero(String prefixe, Iterable<String> existants, DateTime date) {
    final debut = '$prefixe-${date.year}-';
    var max = 0;
    for (final n in existants) {
      if (n.startsWith(debut)) max = [max, int.tryParse(n.substring(debut.length)) ?? 0].reduce((a, b) => a > b ? a : b);
    }
    return '$debut${(max + 1).toString().padLeft(3, '0')}';
  }

  String _prochainId(String prefixe, Iterable<String> existants) {
    var n = existants.length + 1;
    while (existants.contains('$prefixe$n')) {
      n++;
    }
    return '$prefixe$n';
  }

  bool numeroConteneurPris(String numero) => _donnees.conteneurs.any((c) => c.numero == numero);

  /// Ajoute un conteneur (sans produits : on les ajoute ensuite). Renvoie son identifiant.
  String ajouterConteneur({
    required String numero,
    required TypeConteneur type,
    required String origine,
    required DateTime arrivee,
    required String fournisseur,
    required int verseFournisseur,
    required Couts couts,
  }) {
    final id = _prochainId('C', _donnees.conteneurs.map((c) => c.id));
    final c = Conteneur(
      id: id,
      numero: numero,
      type: type,
      origine: origine,
      arrivee: arrivee,
      fournisseur: fournisseur,
      verseFournisseur: verseFournisseur,
      statut: StatutConteneur.enDistribution,
      couleur: _donnees.conteneurs.length,
      couts: couts,
      produits: const [],
    );
    _remplacer(_avec(conteneurs: [..._donnees.conteneurs, c]));
    return id;
  }

  /// Ajoute un produit dans un conteneur. Renvoie son identifiant.
  String ajouterProduit(
    String conteneurId, {
    required String nom,
    required String unite,
    required int quantite,
    required int prix,
    required IconeProduit icone,
  }) {
    final c = _donnees.conteneurs.firstWhere((c) => c.id == conteneurId);
    final id = _prochainId('$conteneurId-p', c.produits.map((p) => p.id));
    final p = Produit(id: id, nom: nom, unite: unite, quantiteRecue: quantite, prix: prix, icone: icone);
    _changerConteneur(conteneurId, (x) => x.copyWith(produits: [...x.produits, p]));
    return id;
  }

  static const _teintes = [0xFF2E8B7A, 0xFFF0B429, 0xFF4A6BB0, 0xFFC4532D, 0xFF7B3FA0, 0xFF6F7F8A, 0xFFC98F1E];

  /// Ajoute un client. Renvoie son identifiant.
  String ajouterClient({required String nom, required String quartier, required int limiteCredit}) {
    final id = _prochainId('k', _donnees.clients.map((k) => k.id));
    final k = Client(
      id: id,
      nom: nom,
      quartier: quartier,
      limiteCredit: limiteCredit,
      apparence: Apparence(
        peau: 0xFF6B4423,
        coiffe: Coiffe.aucune,
        couleurCoiffe: 0xFF1A1A1A,
        vetement: _teintes[_donnees.clients.length % _teintes.length],
      ),
    );
    _remplacer(_avec(clients: [..._donnees.clients, k]));
    return id;
  }

  /// Ajoute une facture, et un premier paiement si le client paie tout de suite. Renvoie son numéro.
  String ajouterFacture({
    required String clientId,
    required DateTime date,
    required List<LigneFacture> lignes,
    int payeMaintenant = 0,
    ModePaiement mode = ModePaiement.especes,
  }) {
    final numero = _prochainNumero('FAC', _donnees.factures.map((f) => f.numero), date);
    _remplacer(_avec(
      factures: [..._donnees.factures, Facture(numero: numero, clientId: clientId, date: date, lignes: lignes)],
      paiements: [
        ..._donnees.paiements,
        if (payeMaintenant > 0) Paiement(facture: numero, date: date, montant: payeMaintenant, mode: mode),
      ],
    ));
    return numero;
  }

  void ajouterPaiement(Paiement p) => _remplacer(_avec(paiements: [..._donnees.paiements, p]));

  /// Ajoute un retour ou une remise. Renvoie son numéro.
  String ajouterAvoir({
    required String facture,
    required int ligne,
    required int quantite,
    required TypeAvoir type,
    required DateTime date,
    required String motif,
  }) {
    final numero = _prochainNumero('AV', _donnees.avoirs.map((a) => a.numero), date);
    _remplacer(_avec(avoirs: [
      ..._donnees.avoirs,
      Avoir(numero: numero, facture: facture, ligne: ligne, quantite: quantite, type: type, date: date, motif: motif),
    ]));
    return numero;
  }

  // ---- modifier et supprimer

  void _changerConteneur(String id, Conteneur Function(Conteneur) changer) => _remplacer(_avec(conteneurs: [
        for (final x in _donnees.conteneurs) x.id == id ? changer(x) : x,
      ]));

  bool numeroConteneurPrisAilleurs(String numero, String sauf) =>
      _donnees.conteneurs.any((c) => c.numero == numero && c.id != sauf);

  bool _conteneurUtilise(String id) => _donnees.factures.any((f) => f.lignes.any((l) => l.conteneurId == id));

  /// Pourquoi on ne peut pas supprimer ce conteneur, ou null si on peut.
  String? raisonGarderConteneur(String id) =>
      _conteneurUtilise(id) ? 'Des factures utilisent ce conteneur. Supprimez d\'abord ces factures.' : null;

  void modifierConteneur(
    String id, {
    required String numero,
    required TypeConteneur type,
    required String origine,
    required DateTime arrivee,
    required String fournisseur,
    required int verseFournisseur,
    required Couts couts,
    required StatutConteneur statut,
  }) =>
      _changerConteneur(
        id,
        (c) => c.copyWith(
          numero: numero,
          type: type,
          origine: origine,
          arrivee: arrivee,
          fournisseur: fournisseur,
          verseFournisseur: verseFournisseur,
          couts: couts,
          statut: statut,
        ),
      );

  void supprimerConteneur(String id) {
    if (_conteneurUtilise(id)) throw StateError(raisonGarderConteneur(id)!);
    _remplacer(_avec(conteneurs: [for (final c in _donnees.conteneurs) if (c.id != id) c]));
  }

  /// Pourquoi on ne peut pas supprimer ce produit, ou null si on peut.
  String? raisonGarderProduit(String produitId) =>
      _donnees.factures.any((f) => f.lignes.any((l) => l.produitId == produitId))
          ? 'Ce produit a déjà été vendu. Supprimez d\'abord les factures qui le contiennent.'
          : null;

  void modifierProduit(
    String conteneurId,
    String produitId, {
    required String nom,
    required String unite,
    required int quantite,
    required int prix,
    required IconeProduit icone,
  }) =>
      _changerConteneur(conteneurId, (c) => c.copyWith(produits: [
            for (final p in c.produits)
              p.id == produitId
                  ? Produit(id: p.id, nom: nom, unite: unite, quantiteRecue: quantite, prix: prix, icone: icone)
                  : p,
          ]));

  void supprimerProduit(String conteneurId, String produitId) {
    if (raisonGarderProduit(produitId) != null) throw StateError(raisonGarderProduit(produitId)!);
    _changerConteneur(conteneurId, (c) => c.copyWith(produits: [for (final p in c.produits) if (p.id != produitId) p]));
  }

  /// Pourquoi on ne peut pas supprimer ce client, ou null si on peut.
  String? raisonGarderClient(String id) => _donnees.factures.any((f) => f.clientId == id)
      ? 'Ce client a des factures. Supprimez d\'abord ses factures.'
      : null;

  void modifierClient(String id, {required String nom, required String quartier, required int limiteCredit}) =>
      _remplacer(_avec(clients: [
        for (final k in _donnees.clients)
          k.id == id ? k.copyWith(nom: nom, quartier: quartier, limiteCredit: limiteCredit) : k,
      ]));

  void supprimerClient(String id) {
    if (raisonGarderClient(id) != null) throw StateError(raisonGarderClient(id)!);
    _remplacer(_avec(clients: [for (final k in _donnees.clients) if (k.id != id) k]));
  }

  /// Les lignes d'une facture ne changent plus quand elle a des retours (les retours pointent vers ses lignes).
  bool lignesBloquees(String numero) => _donnees.avoirs.any((a) => a.facture == numero);

  void modifierFacture(String numero, {required String clientId, required DateTime date, required List<LigneFacture> lignes}) {
    final ancienne = _donnees.factures.firstWhere((f) => f.numero == numero);
    if (lignesBloquees(numero) && lignes.length != ancienne.lignes.length) {
      throw StateError('Les lignes ne changent plus : il y a des retours.');
    }
    _remplacer(_avec(factures: [
      for (final f in _donnees.factures)
        f.numero == numero ? Facture(numero: numero, clientId: clientId, date: date, lignes: lignes) : f,
    ]));
  }

  /// Supprime la facture, ses paiements et ses retours.
  void supprimerFacture(String numero) => _remplacer(_avec(
        factures: [for (final f in _donnees.factures) if (f.numero != numero) f],
        paiements: [for (final p in _donnees.paiements) if (p.facture != numero) p],
        avoirs: [for (final a in _donnees.avoirs) if (a.facture != numero) a],
      ));

  /// Les paiements n'ont pas de numéro : on les repère par leur rang dans la liste.
  int rangPaiement(Paiement p) => _donnees.paiements.indexWhere((x) => identical(x, p));

  void modifierPaiement(int rang, Paiement nouveau) => _remplacer(_avec(paiements: [
        for (final (i, p) in _donnees.paiements.indexed) i == rang ? nouveau : p,
      ]));

  void supprimerPaiement(int rang) => _remplacer(_avec(paiements: [
        for (final (i, p) in _donnees.paiements.indexed)
          if (i != rang) p,
      ]));

  void modifierAvoir(String numero, {required int quantite, required TypeAvoir type, required DateTime date, required String motif}) =>
      _remplacer(_avec(avoirs: [
        for (final a in _donnees.avoirs)
          a.numero == numero
              ? Avoir(numero: numero, facture: a.facture, ligne: a.ligne, quantite: quantite, type: type, date: date, motif: motif)
              : a,
      ]));

  void supprimerAvoir(String numero) =>
      _remplacer(_avec(avoirs: [for (final a in _donnees.avoirs) if (a.numero != numero) a]));

  /// Revient aux données d'exemple (ce qui a été ajouté est perdu).
  void remettreExemples() => _remplacer(donneesExemple);
}
