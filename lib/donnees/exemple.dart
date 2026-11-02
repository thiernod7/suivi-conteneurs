import '../domaine/modeles.dart';

// Données d'exemple du prototype : 4 conteneurs, 7 commerçants, 16 factures.

DateTime _j(String iso) => DateTime.parse(iso);

const _riz = Produit(id: 'C1-riz', nom: 'Riz parfumé 25 kg', unite: 'sacs', quantiteRecue: 1000, prix: 285000, icone: IconeProduit.sac);
const _huile = Produit(id: 'C1-huile', nom: 'Huile végétale 20 L', unite: 'bidons', quantiteRecue: 300, prix: 390000, icone: IconeProduit.bidon);
const _pates = Produit(id: 'C2-pates', nom: 'Pâtes alimentaires 500 g', unite: 'cartons', quantiteRecue: 800, prix: 95000, icone: IconeProduit.carton);
const _tomate = Produit(id: 'C2-tomate', nom: 'Tomate concentrée', unite: 'cartons', quantiteRecue: 600, prix: 120000, icone: IconeProduit.tomate);
const _pneus = Produit(id: 'C3-pneus', nom: 'Pneus moto 2.75-17', unite: 'pièces', quantiteRecue: 900, prix: 160000, icone: IconeProduit.pneu);
const _batteries = Produit(id: 'C3-batteries', nom: 'Batteries 12 V', unite: 'pièces', quantiteRecue: 400, prix: 210000, icone: IconeProduit.batterie);
const _sucre = Produit(id: 'C4-sucre', nom: 'Sucre 50 kg', unite: 'sacs', quantiteRecue: 700, prix: 420000, icone: IconeProduit.sucre);
const _lait = Produit(id: 'C4-lait', nom: 'Lait en poudre', unite: 'cartons', quantiteRecue: 400, prix: 260000, icone: IconeProduit.lait);

final conteneursExemple = [
  Conteneur(
    id: 'C1', numero: 'MDNU 482113 0', type: TypeConteneur.hc40, origine: 'Guangzhou, Chine', arrivee: _j('2026-07-28'),
    fournisseur: 'Guangzhou Hengxin Trading', verseFournisseur: 290000000, statut: StatutConteneur.vendu, couleur: 0,
    couts: const Couts(achat: 290000000, fret: 48000000, douane: 22000000, manutention: 6000000),
    produits: const [_riz, _huile],
  ),
  Conteneur(
    id: 'C2', numero: 'MDNU 517390 4', type: TypeConteneur.dv20, origine: 'Mersin, Turquie', arrivee: _j('2026-08-21'),
    fournisseur: 'Mersin Gıda Ltd.', verseFournisseur: 98000000, statut: StatutConteneur.vendu, couleur: 1,
    couts: const Couts(achat: 98000000, fret: 28000000, douane: 9000000, manutention: 3000000),
    produits: const [_pates, _tomate],
  ),
  Conteneur(
    id: 'C3', numero: 'MDNU 603218 7', type: TypeConteneur.dv40, origine: 'Jebel Ali, Dubaï', arrivee: _j('2026-09-10'),
    fournisseur: 'Al Noor General Trading', verseFournisseur: 150000000, statut: StatutConteneur.vendu, couleur: 2,
    couts: const Couts(achat: 150000000, fret: 34000000, douane: 14000000, manutention: 5000000),
    produits: const [_pneus, _batteries],
  ),
  Conteneur(
    id: 'C4', numero: 'MDNU 640055 2', type: TypeConteneur.hc40, origine: 'Ningbo, Chine', arrivee: _j('2026-10-18'),
    fournisseur: 'Ningbo Sweet Food Co.', verseFournisseur: 200000000, statut: StatutConteneur.enDistribution, couleur: 3,
    couts: const Couts(achat: 290000000, fret: 46000000, douane: 20000000, manutention: 6000000),
    produits: const [_sucre, _lait],
  ),
];

const clientsExemple = [
  Client(id: 'k1', nom: 'El Hadj Mamadou Bah', quartier: 'Madina Marché', limiteCredit: 200000000,
      apparence: Apparence(peau: 0xFF6B4423, coiffe: Coiffe.turban, couleurCoiffe: 0xFFF2EFE6, vetement: 0xFFE6E0D0)),
  Client(id: 'k2', nom: 'Fatoumata Camara', quartier: 'Madina Rail', limiteCredit: 75000000,
      apparence: Apparence(peau: 0xFF8A5A3B, coiffe: Coiffe.foulard, couleurCoiffe: 0xFFD9532B, vetement: 0xFFF0B429)),
  Client(id: 'k3', nom: 'Ibrahima Sow', quartier: 'Koloma', limiteCredit: 150000000,
      apparence: Apparence(peau: 0xFF5A3A22, coiffe: Coiffe.kufi, couleurCoiffe: 0xFF3B5A9C, vetement: 0xFF4A6BB0)),
  Client(id: 'k4', nom: 'Mariama Diallo', quartier: 'Matoto', limiteCredit: 100000000,
      apparence: Apparence(peau: 0xFF7A4E2F, coiffe: Coiffe.foulard, couleurCoiffe: 0xFF7B3FA0, vetement: 0xFF2E8B7A)),
  Client(id: 'k5', nom: 'Oumar Kouyaté', quartier: 'Kaloum', limiteCredit: 100000000,
      apparence: Apparence(peau: 0xFF4E321D, coiffe: Coiffe.aucune, couleurCoiffe: 0xFF1A1A1A, vetement: 0xFFC98F1E)),
  Client(id: 'k6', nom: 'Aïssatou Barry', quartier: 'Madina Dispensaire', limiteCredit: 100000000,
      apparence: Apparence(peau: 0xFF93613F, coiffe: Coiffe.foulard, couleurCoiffe: 0xFF2C7D69, vetement: 0xFFC4532D)),
  Client(id: 'k7', nom: 'Moussa Keïta', quartier: 'Bonfi', limiteCredit: 80000000,
      apparence: Apparence(peau: 0xFF62402A, coiffe: Coiffe.casquette, couleurCoiffe: 0xFF24323D, vetement: 0xFF6F7F8A)),
];

LigneFacture _l(Conteneur c, Produit p, int quantite) =>
    LigneFacture(conteneurId: c.id, produitId: p.id, quantite: quantite, prix: p.prix);

Conteneur _c(String id) => conteneursExemple.firstWhere((c) => c.id == id);

final facturesExemple = [
  Facture(numero: 'FAC-2026-001', clientId: 'k1', date: _j('2026-07-29'), lignes: [_l(_c('C1'), _riz, 300)]),
  Facture(numero: 'FAC-2026-002', clientId: 'k2', date: _j('2026-07-30'), lignes: [_l(_c('C1'), _riz, 250)]),
  Facture(numero: 'FAC-2026-003', clientId: 'k3', date: _j('2026-07-30'), lignes: [_l(_c('C1'), _riz, 250)]),
  Facture(numero: 'FAC-2026-004', clientId: 'k6', date: _j('2026-07-31'), lignes: [_l(_c('C1'), _riz, 200)]),
  Facture(numero: 'FAC-2026-005', clientId: 'k4', date: _j('2026-08-02'), lignes: [_l(_c('C1'), _huile, 200)]),
  Facture(numero: 'FAC-2026-006', clientId: 'k5', date: _j('2026-08-22'), lignes: [_l(_c('C2'), _pates, 300), _l(_c('C2'), _tomate, 200)]),
  Facture(numero: 'FAC-2026-007', clientId: 'k1', date: _j('2026-08-23'), lignes: [_l(_c('C2'), _pates, 250)]),
  // Une facture qui mélange deux conteneurs : huile du C1 et tomate du C2.
  Facture(numero: 'FAC-2026-008', clientId: 'k2', date: _j('2026-08-25'), lignes: [_l(_c('C1'), _huile, 90), _l(_c('C2'), _tomate, 100)]),
  Facture(numero: 'FAC-2026-009', clientId: 'k7', date: _j('2026-08-26'), lignes: [_l(_c('C2'), _pates, 150), _l(_c('C2'), _tomate, 250)]),
  Facture(numero: 'FAC-2026-010', clientId: 'k7', date: _j('2026-09-12'), lignes: [_l(_c('C3'), _pneus, 400), _l(_c('C3'), _batteries, 200)]),
  Facture(numero: 'FAC-2026-011', clientId: 'k3', date: _j('2026-09-12'), lignes: [_l(_c('C3'), _pneus, 300), _l(_c('C3'), _batteries, 150)]),
  Facture(numero: 'FAC-2026-012', clientId: 'k4', date: _j('2026-09-15'), lignes: [_l(_c('C3'), _pneus, 150)]),
  Facture(numero: 'FAC-2026-013', clientId: 'k1', date: _j('2026-10-20'), lignes: [_l(_c('C4'), _sucre, 200)]),
  Facture(numero: 'FAC-2026-014', clientId: 'k6', date: _j('2026-10-21'), lignes: [_l(_c('C4'), _sucre, 150), _l(_c('C4'), _lait, 100)]),
  Facture(numero: 'FAC-2026-015', clientId: 'k2', date: _j('2026-10-22'), lignes: [_l(_c('C4'), _sucre, 120)]),
  Facture(numero: 'FAC-2026-016', clientId: 'k4', date: _j('2026-10-24'), lignes: [_l(_c('C4'), _lait, 80)]),
];

Paiement _p(String facture, String date, int montant, ModePaiement mode, [String? remarque]) =>
    Paiement(facture: facture, date: _j(date), montant: montant, mode: mode, remarque: remarque);

final paiementsExemple = [
  _p('FAC-2026-001', '2026-07-29', 50000000, ModePaiement.especes),
  _p('FAC-2026-001', '2026-08-10', 35500000, ModePaiement.orangeMoney),
  _p('FAC-2026-002', '2026-07-30', 42750000, ModePaiement.especes, 'Acompte'),
  _p('FAC-2026-003', '2026-08-05', 71250000, ModePaiement.virement, 'Ecobank'),
  _p('FAC-2026-004', '2026-07-31', 57000000, ModePaiement.especes),
  _p('FAC-2026-006', '2026-08-22', 30000000, ModePaiement.especes),
  _p('FAC-2026-006', '2026-09-01', 22500000, ModePaiement.orangeMoney),
  _p('FAC-2026-007', '2026-08-23', 23750000, ModePaiement.especes),
  _p('FAC-2026-008', '2026-09-15', 21060000, ModePaiement.orangeMoney),
  _p('FAC-2026-009', '2026-08-26', 15000000, ModePaiement.especes),
  _p('FAC-2026-009', '2026-09-20', 7125000, ModePaiement.mtnMomo),
  _p('FAC-2026-010', '2026-09-12', 40000000, ModePaiement.especes),
  _p('FAC-2026-010', '2026-10-05', 39500000, ModePaiement.virement, 'Orabank'),
  _p('FAC-2026-011', '2026-09-14', 79500000, ModePaiement.virement, 'Ecobank'),
  _p('FAC-2026-013', '2026-10-20', 42000000, ModePaiement.especes, 'Acompte 50 %'),
  _p('FAC-2026-015', '2026-10-22', 15120000, ModePaiement.orangeMoney),
];

final avoirsExemple = [
  Avoir(numero: 'AV-2026-001', facture: 'FAC-2026-005', ligne: 0, quantite: 20, type: TypeAvoir.remisEnStock,
      date: _j('2026-08-04'), motif: 'Erreur de commande : bidons rendus intacts'),
  Avoir(numero: 'AV-2026-002', facture: 'FAC-2026-011', ligne: 1, quantite: 10, type: TypeAvoir.rebut,
      date: _j('2026-09-30'), motif: 'Batteries défectueuses'),
  Avoir(numero: 'AV-2026-003', facture: 'FAC-2026-013', ligne: 0, quantite: 6, type: TypeAvoir.remise,
      date: _j('2026-10-22'), motif: 'Sacs mouillés pendant le transport'),
];

final donneesExemple = Donnees(
  conteneurs: conteneursExemple,
  clients: clientsExemple,
  factures: facturesExemple,
  paiements: paiementsExemple,
  avoirs: avoirsExemple,
);

/// Date du jour figée pour que le prototype raconte toujours la même histoire.
final aujourdhuiExemple = _j('2026-11-02');
