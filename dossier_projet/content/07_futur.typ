= Évolutions futures <futur>

== Bilan du MVP : Un potentiel confirmé, une qualité de données à consolider

La première version du MVP démontre la viabilité technique et la pertinence du concept. L'architecture mise en place – pipeline ETL, bases PostgreSQL et Neo4j, algorithmes de clustering et de routage – fonctionne et est capable de générer automatiquement des itinéraires thématiques cohérents sur le plan logique et spatial. Les premiers tests produisent des parcours qui, d'un point de vue algorithmique, sont tout à fait sympathiques et prometteurs.

Cependant, comme l'a révélé l'analyse de qualité des données, le MVP bute sur une limitation fondamentale : la qualité et l'exhaustivité des données sources. La dépendance initiale quasi-exclusive aux données DATAtourisme, qui présentent d'importantes lacunes (catégorisation inconsistante, absence de POIs pourtant bien réels, couverture géographique inégale), se traduit inévitablement dans les résultats. Le fameux exemple de l'absence de châteaux en Aquitaine n'est pas qu'une anecdote ; il est le symptôme d'un problème systémique qui empêche toute utilisation fiable et généralisable du service en l'état. Un itinéraire "Châteaux" qui ignorerait des joyaux du patrimoine est, par définition, inutilisable.

== Feuille de route prioritaire : L'amélioration radicale de la qualité des données

La conclusion est sans appel : la prochaine phase de développement doit être intégralement consacrée à l'enrichissement et à l'amélioration de la base de données des points d'intérêt. Toute autre évolution fonctionnelle ou technique serait prématurée sans cette fondation solide.

=== Phase 1 : Enrichissement par OpenStreetMap

L'objectif est de combler les lacunes de catégorisation et d'exhaustivité de DATAtourisme en utilisant la richesse et la granularité des données collaboratives d'OpenStreetMap.

*Actions*

1. *Développement d'un pipeline d'ingestion OSM* : création d'un module ETL dédié pour télécharger et parser les fichiers .pbf de la France, en extrayant les POIs pertinents via leurs tags (`historic=*`, `tourism=*`, `heritage=*`, `attraction=*`).
2. *Processus de fusion et de dédoublonnage* : mise en place d'un algorithme de matching géospatial et textuel pour croiser les entrées OSM avec la base DATAtourisme existante. Pour chaque match :
  - Mise à jour des catégories du POI existant avec les tags OSM manquants (ex: ajout du tag `historic=castle` à un château DATAtourisme only catégorisé "Parc").
  - Insertion des POIs présents dans OSM mais absents de DATAtourisme.
3. *Mise à jour des algorithmes métier* : adaptation des processus de clustering et de génération de routes dans Neo4j pour qu'ils s'appuient sur la base de données enrichie et ses catégories fusionnées.

*Résultat attendu*

Une correction massive des anomalies de catégorisation et une augmentation significative du nombre de POIs référencés, en particulier pour les thématiques les plus touchées (châteaux, monuments historiques, sites naturels). Les itinéraires générés gagneront immédiatement en crédibilité et en exhaustivité.

=== Phase 2 : Ajout d'une couche de Popularité et de Réputation

Une fois la base "physique" des POIs consolidée, l'étape suivante consiste à ajouter une dimension qualitative pour guider la sélection des points les plus intéressants au sein d'un cluster.

*Actions*

1. *Intégration ciblée d'APIs tierces* : utilisation des API Google Places et/ou techniques de scraping prudent de TripAdvisor pour récupérer, pour chaque POI, des métriques de réputation (note moyenne, nombre d'avis).
2. *Pondération des algorithmes de sélection* : modification de la logique de construction de l'itinéraire pour prioriser les POIs avec les notes et le volume d'avis les plus élevés, garantissant ainsi que les suggestions faites à l'utilisateur correspondent aux lieux les plus plébiscités.

*Résultat attendu*

Non seulement l'itinéraire sera complet et thématiquement cohérent, mais il sera également optimisé pour la qualité de l'expérience visiteur, évitant les déceptions et renforçant la confiance dans les recommandations du service.

== Conclusion

La stratégie d'évolution est donc claire et focalisée : passer d'un MVP de validation technique à un produit utilisable en production en résolvant le problème de la qualité des données. L'enrichissement via OpenStreetMap constitue la priorité absolue, car il est le plus impactant et le moins risqué. L'ajout de la couche de popularité viendra dans un second temps parachever cette foundation data pour offrir une expérience réellement valuable à l'utilisateur final.