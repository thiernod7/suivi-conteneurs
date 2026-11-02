# Suivi des conteneurs

Application de suivi des conteneurs pour un importateur du marché de Madina (Conakry) : à quels clients la marchandise est partie, qui doit encore payer, et le résultat de chaque conteneur.

Le besoin et le plan du projet sont décrits dans [`CLAUDE.md`](CLAUDE.md).

**Prototype en ligne :** https://thiernod7.github.io/suivi-conteneurs/ (données d'exemple)

## Lancer en local

Il faut [Flutter](https://docs.flutter.dev/get-started/install) 3.47.

```bash
flutter pub get
flutter run -d chrome     # dans le navigateur
flutter test              # les tests
```

## Organisation du code

```
lib/
  domaine/modeles.dart     ce qu'on enregistre : conteneurs, clients, factures, paiements, avoirs
  domaine/calculs.dart     les calculs du cahier des charges (ventes, encaissé, résultat, stock…)
  donnees/exemple.dart     les données d'exemple du prototype
  ui/                      les écrans, le thème, les illustrations
test/                      tests des calculs et des écrans
```

## Publication

À chaque push sur `main`, GitHub Actions lance les tests puis publie la version web sur GitHub Pages (`.github/workflows/web.yml`).
