import '../domaine/modeles.dart';

// Conversion des données en JSON (et retour), pour les garder sur l'appareil.

typedef Json = Map<String, Object?>;

String _date(DateTime d) => d.toIso8601String().substring(0, 10);
DateTime _lireDate(Object? s) => DateTime.parse(s as String);
T _enum<T extends Enum>(List<T> valeurs, Object? nom) => valeurs.byName(nom as String);

Json donneesVersJson(Donnees d) => {
      'version': 1,
      'conteneurs': [for (final c in d.conteneurs) _conteneur(c)],
      'clients': [for (final k in d.clients) _client(k)],
      'factures': [for (final f in d.factures) _facture(f)],
      'paiements': [for (final p in d.paiements) _paiement(p)],
      'avoirs': [for (final a in d.avoirs) _avoir(a)],
    };

Donnees donneesDepuisJson(Json j) {
  List<Json> liste(String cle) => (j[cle] as List).cast<Json>();
  return Donnees(
    conteneurs: [for (final c in liste('conteneurs')) _lireConteneur(c)],
    clients: [for (final k in liste('clients')) _lireClient(k)],
    factures: [for (final f in liste('factures')) _lireFacture(f)],
    paiements: [for (final p in liste('paiements')) _lirePaiement(p)],
    avoirs: [for (final a in liste('avoirs')) _lireAvoir(a)],
  );
}

Json _conteneur(Conteneur c) => {
      'id': c.id,
      'numero': c.numero,
      'type': c.type.name,
      'origine': c.origine,
      'arrivee': _date(c.arrivee),
      'fournisseur': c.fournisseur,
      'verseFournisseur': c.verseFournisseur,
      'statut': c.statut.name,
      'couleur': c.couleur,
      'couts': {'achat': c.couts.achat, 'fret': c.couts.fret, 'douane': c.couts.douane, 'manutention': c.couts.manutention},
      'produits': [
        for (final p in c.produits)
          {'id': p.id, 'nom': p.nom, 'unite': p.unite, 'quantiteRecue': p.quantiteRecue, 'prix': p.prix, 'icone': p.icone.name},
      ],
    };

Conteneur _lireConteneur(Json j) {
  final couts = j['couts'] as Json;
  return Conteneur(
    id: j['id'] as String,
    numero: j['numero'] as String,
    type: _enum(TypeConteneur.values, j['type']),
    origine: j['origine'] as String,
    arrivee: _lireDate(j['arrivee']),
    fournisseur: j['fournisseur'] as String,
    verseFournisseur: j['verseFournisseur'] as int,
    statut: _enum(StatutConteneur.values, j['statut']),
    couleur: j['couleur'] as int,
    couts: Couts(
      achat: couts['achat'] as int,
      fret: couts['fret'] as int,
      douane: couts['douane'] as int,
      manutention: couts['manutention'] as int,
    ),
    produits: [
      for (final p in (j['produits'] as List).cast<Json>())
        Produit(
          id: p['id'] as String,
          nom: p['nom'] as String,
          unite: p['unite'] as String,
          quantiteRecue: p['quantiteRecue'] as int,
          prix: p['prix'] as int,
          icone: _enum(IconeProduit.values, p['icone']),
        ),
    ],
  );
}

Json _client(Client k) => {
      'id': k.id,
      'nom': k.nom,
      'quartier': k.quartier,
      'limiteCredit': k.limiteCredit,
      'apparence': {
        'peau': k.apparence.peau,
        'coiffe': k.apparence.coiffe.name,
        'couleurCoiffe': k.apparence.couleurCoiffe,
        'vetement': k.apparence.vetement,
      },
    };

Client _lireClient(Json j) {
  final a = j['apparence'] as Json;
  return Client(
    id: j['id'] as String,
    nom: j['nom'] as String,
    quartier: j['quartier'] as String,
    limiteCredit: j['limiteCredit'] as int,
    apparence: Apparence(
      peau: a['peau'] as int,
      coiffe: _enum(Coiffe.values, a['coiffe']),
      couleurCoiffe: a['couleurCoiffe'] as int,
      vetement: a['vetement'] as int,
    ),
  );
}

Json _facture(Facture f) => {
      'numero': f.numero,
      'clientId': f.clientId,
      'date': _date(f.date),
      'lignes': [
        for (final l in f.lignes)
          {'conteneurId': l.conteneurId, 'produitId': l.produitId, 'quantite': l.quantite, 'prix': l.prix},
      ],
    };

Facture _lireFacture(Json j) => Facture(
      numero: j['numero'] as String,
      clientId: j['clientId'] as String,
      date: _lireDate(j['date']),
      lignes: [
        for (final l in (j['lignes'] as List).cast<Json>())
          LigneFacture(
            conteneurId: l['conteneurId'] as String,
            produitId: l['produitId'] as String,
            quantite: l['quantite'] as int,
            prix: l['prix'] as int,
          ),
      ],
    );

Json _paiement(Paiement p) =>
    {'facture': p.facture, 'date': _date(p.date), 'montant': p.montant, 'mode': p.mode.name, 'remarque': p.remarque};

Paiement _lirePaiement(Json j) => Paiement(
      facture: j['facture'] as String,
      date: _lireDate(j['date']),
      montant: j['montant'] as int,
      mode: _enum(ModePaiement.values, j['mode']),
      remarque: j['remarque'] as String?,
    );

Json _avoir(Avoir a) => {
      'numero': a.numero,
      'facture': a.facture,
      'ligne': a.ligne,
      'quantite': a.quantite,
      'type': a.type.name,
      'date': _date(a.date),
      'motif': a.motif,
    };

Avoir _lireAvoir(Json j) => Avoir(
      numero: j['numero'] as String,
      facture: j['facture'] as String,
      ligne: j['ligne'] as int,
      quantite: j['quantite'] as int,
      type: _enum(TypeAvoir.values, j['type']),
      date: _lireDate(j['date']),
      motif: j['motif'] as String,
    );
