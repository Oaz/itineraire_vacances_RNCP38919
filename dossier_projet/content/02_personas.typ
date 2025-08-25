= Personas <personas>

#set table.cell(breakable: false)
#let profile-header(text,img) = grid(
  columns: (2fr, 1fr),
  gutter: 20pt,
  align: horizon,
  text,
  image(img, width: 80%),
)

== Claire, l'Enthousiaste Culturelle

=== Profil

#profile-header(
  [
    - *Âge :* 26 ans
    - *Profession :* Responsable communication
    - *Profil :* Voyageuse occasionnelle mais passionnée, elle planifie elle-même ses séjours. Elle ne voyage pas pour se reposer sur une plage, mais pour se cultiver, apprendre et avoir des anecdotes à raconter.
  ],
  "../img/persona01.jpg",
)
- *Frustrations :*
  - Les guides touristiques généraux noient l'information niche qu'elle cherche.
  - Passer des heures sur Google Maps à pointer des épingles et à essayer de deviner le trajet le plus logique.
  - Craindre de manquer un joyau caché juste à côté de son parcours.
  - Les tours organisés sont trop généraux et ne correspondent jamais parfaitement à sa passion très spécifique.
- *Attentes vis-à-vis de l'application :*
  - Pouvoir choisir un thème _hyper spécifique_ ("street art", "cinéma", "art déco").
  - Avoir confiance dans la complétude des suggestions (ne rien manquer d'important sur le thème).
  - Un trajet _optimisé_ qui minimise le temps de transport à pied ou en transports en commun.
  - Pouvoir _ajuster_ facilement le parcours proposé (ex : enlever un point qui ne l'intéresse pas, en ajouter un autre).
- *Quote :* _"J'adore me plonger dans un thème pendant un voyage. Mais planifier un parcours cohérent qui regroupe tous les lieux pertinents est un vrai casse-tête."_

#page(
  flipped: true,
)[

  === Experience Map : un weekend Art Déco

  *Scénario :* Elle prévoit un weekend de 3 jours à Bordeaux. Elle ne veut pas faire que les incontournables listés dans tous les guides. Elle est fascinée par l'architecture art déco et veut absolument découvrir ce que la ville offre sur ce thème précis.

  *Objectif :* Trouver un itinéraire qui maximise sa découverte de l'architecture art déco à Bordeaux, sans perdre de temps à chercher où aller ni à faire des allers-retours inefficaces. Elle veut que l'application fasse le travail de logistique pour qu'elle se concentre sur la visite.

  #table(
    columns: (1.5fr, 2fr, 2fr, 1.5fr, 2fr),
    inset: 10pt,
    align: horizon,
    table.header([*Phase*], [*Actions*], [*Pensées*], [*Émotion*], [*Points de Contact & Opportunités pour l'App*]),
    [*1. Inspiration & Planification*],
    [Elle cherche "art déco Bordeaux" sur Google. Elle trouve des articles de blog épars et une liste Wikipédia. Elle note une quinzaine de noms dans son carnet.],
    ["C'est bien, mais est-ce que j'ai tout ? Et comment je organise tout ça ? Par où je commence ?"],
    [Enthousiaste mais submergée par la tâche d'organisation.],
    [L'app se positionne comme la solution à ce problème de curation et d'organisation.],
    [*2. Configuration*],
    [Elle ouvre l'app, sélectionne "Bordeaux", choisit "Architecture" puis le sous-thème "Art Déco". Elle définit la durée : 1 journée.],
    ["Génial, ils ont exactement la catégorie qu'il me faut ! La liste a l'air plus complète que la mienne."],
    [Confiante, impressionnée par la spécialisation de l'outil.],
    [Interface de sélection du thème. Des sous-thèmes bien organisés et précis renforcent la confiance.],
    [*3. Génération*],
    [ Elle clique sur "Créer mon itinéraire". L'app affiche une progression. En 2 secondes, une carte avec un parcours en boucle apparaît, reliant 8 points. ],
    [ "Wow, c'est instantané ! La boucle a l'air logique, ça part de la grosse concentration vers des points plus éloignés mais regroupés." ],
    [ Impressiionnée, soulagée de ne pas avoir à le faire elle-même. ],
    [ Algorithme de clustering et d'optimisation de graphe. Une animation pendant le calcul montre la "magie" technique. ],
    [ *4. Consultation & Personnalisation* ],
    [ Elle parcourt la liste des POI proposés. Elle lit la description d'un bâtiment et décide de le retirer. L'itinéraire se recalcule automatiquement. ],
    [ "Parfait, je peux ajuster. Celui-là est un peu redondant avec un autre. Super, le trajet est encore plus court maintenant." ],
    [ En contrôle, l'outil est un assistant, pas un dictateur. ],
    [ Interface de glisser-déposer ou de swipe pour modifier la liste. Recalcul fluide et instantané après modification. ],
    [ *5. Live-Experience* ],
    [ Sur place, elle suit l'itinéraire sur son téléphone. La géolocalisation la guide de point en point. Elle découvre une petite villa art déco qu'elle n'avait pas vue en ligne. ],
    [ "Incroyable ce petit bijou caché ! Heureusement que l'app l'avait inclus, je serais jamais passée par ici sinon." ],
    [ Ravie, découvreuse. Le sentiment d'avoir eu une expérience unique et optimale. ],
    [ App mobile avec GPS et fiche détaillée pour chaque POI (histoire, photos). Fonction "découverte à proximité" même en dehors du thème principal. ],
    [ *6. Partage & Retour* ],
    [ À la fin du weekend, elle partage l'itinéraire final avec ses amis passionés d'architecture. Elle note ses POI préférés dans l'app. ],
    [ "Il faut que je partage ça ! Cet itinéraire était parfait. La prochaine fois, je teste 'Bordeaux vinicole'." ],
    [ Satisfaite, fière de sa découverte. Fidélisation. ],
    [ Boutons de partage social et fonction de sauvegarde de l'historique. Création d'une communauté d'enthousiastes autour de thèmes de niche. ],
  )
]

== Julien, le Road-Tripper Curieux

=== Profil

#profile-header(
  [
    - *Âge :* 46 ans
    - *Profession :* Consultant indépendant
    - *Profil :* Julien adore prendre la route pour se rendre d'un point A à un point B. Pour lui, le trajet n'est pas une corvée mais l'opportunité de découvrir des pépites méconnues. Il déteste les autoroutes et les trajets directs.
  ],
  "../img/persona02.jpg",
)

- *Frustrations :*
  - Les applications de GPS standard (Waze, Google Maps) ne proposent que des itinéraires "rapides", "courts" ou "économiques", jamais "culturels" ou "thématiques".
  - Faire cette recherche manuellement demande de connaître à l'avance tous les sites, de les mapper un par un et de calculer soi-même le détour, ce qui est long et fastidieux.
  - La peur de manquer un site extraordinaire qui était "juste à côté" du chemin.
- *Attentes vis-à-vis de l'application :*
  - Pouvoir saisir une _origine_ et une _destination_.
  - Choisir un _thème_ pour ponctuer le trajet.
  - _Contrôler_ l'ampleur des détours (ex : "Ne pas ajouter plus de 2h au trajet total").
  - Avoir un _résumé clair_ du trajet : temps de conduite, temps de visite, distance totale.
- *Quote :* "Le voyage, c'est la destination. Je déteste arriver en n'ayant vu que des panneaux d'autoroute. Je veux que l'app me trouve les meilleurs compromis pour allier route et découverte."

#page(
  flipped: true,
)[

  === Experience Map : un road-trip romain

  *Scénario :* Il doit se rendre de _Lyon_ à _Toulouse_ pour affaire.
  Il a une journée entière de libre pour faire le trajet. Au lieu de l'autoroute (A75-A61, ~5h30), il veut découvrir le _patrimoine romain_ de la région Occitanie qu'il ne connaît pas.

  *Objectif :*
  Créer un itinéraire personnalisé entre Lyon et Toulouse qui intègre des sites romains intéressants, en optimisant le temps de route global sans pour autant faire un détour déraisonnable. Il veut que l'application trouve le meilleur équilibre entre la route directe et les écarts thématiques.

  #table(
    columns: (1.5fr, 2fr, 2fr, 1.5fr, 2fr),
    inset: 10pt,
    align: horizon,
    table.header([*Phase*], [*Actions*], [*Pensées*], [*Émotion*], [*Points de Contact & Opportunités pour l'App*]),
    [ *1. Définition du besoin* ],
    [ Il ouvre son appli de GPS classique pour voir le trajet direct Lyon-Toulouse. Il se dit que c'est trop dommage de ne rien voir. ],
    [ "5h30 de route, tout droit... Quel gâchis. Il doit bien y avoir des sites romains sympas sur la route." ],
    [ Frustration face à la monotonie du trajet proposé. ],
    [ L'app se positionne comme l'alternative au GPS classique pour les trajets "utiles mais plaisants". ],
    [ *2. Configuration* ],
    [ Il saisit : Origine: Lyon - Destination: Toulouse. Il choisit le thème "Antiquité / Patrimoine Romain" et "Détour max : +25% du temps initial". ],
    [ "Parfait, ils gèrent l'origine et la destination. Le paramètre de détour est exactement ce qu'il me faut pour garder le contrôle." ],
    [ Excitation à l'idée de voir ce que l'algo va proposer. ],
    [ Interface de saisie du trajet A->B et sélection du thème. Le curseur de "détour max" est une fonctionnalité clé pour ce persona. ],
    [ *3. Génération & Découverte* ],
    [ Il clique sur "Générer". Une carte s'affiche avec un trajet qui quitte l'autoroute, descend vers Nîmes (Maison Carrée, Arènes), remonte vers Millau et Rodez avant de filer sur Toulouse. ],
    [ "Incroyable ! Nîmes est effectivement un must et c'est pile sur la route. Il a même inclus un petit site à Millau que je ne connaissais pas. Le trajet passe à 9h, c'est parfait pour ma journée." ],
    [ Satisfaction par la pertinence du résultat. ],
    [ Algorithme de graphe qui pondère la pertinence thématique et le coût du détour. Afficher côte à côte le trajet direct et le trajet thématique (temps, distance). ],
    [ *4. Affinage* ],
    [ Il voit que l'app a inclus le Viaduc de Millau (moderne). Il le retire manuellement. L'algo recalcule et propose à la place les vestiges romains de La Graufesenque près de Millau. ],
    [ "Haha, il a essayé de glisser le viaduc ! Super, je peux corriger et il me propose autre chose de pertinent juste à côté. Parfait." ],
    [ En confiance, sentiment que l'outil comprend ses intentions. ],
    [ Interface de modification et de recalcul intelligent contextuel. ],
    [ *5. Live-Experience* ],
    [ Sur la route, il suit l'itinéraire. L'app le guide de site en site. Entre Nîmes et Millau, une notification push suggère : "À 15 min de votre trajet, oppidum de Nages." ],
    [ "Une suggestion en temps réel ? Génial ! C'est exactement le genre de spontanéité que j'adore." ],
    [ Ravi, sentiment d'exploration et de ne rien manquer. ],
    [ App mobile avec guidage et suggestions de POI "proches du tracé" en temps réel. ],
    [ *6. Bilan & Partage* ],
    [ Arrivé à Toulouse, il envoie l'itinéraire final à un collègue passionné d'histoire. ],
    [ "Cette app a transformé une corvée de route en une mini-aventure. Je la utiliserai systématiquement." ],
    [ Fidélisation totale. Il est devenu un ambassadeur de la solution. ],
    [ Fonction de partage de l'itinéraire final et sauvegarde dans l'historique. ],
  )
]

== Sophie et Marc, le Week-end en Amoureux Improvisé

=== Profil

#profile-header(  [
    - *Âge :* 33 et 35 ans
    - *Profession :* Sophie est architecte, Marc est professeur de musique.
    - *Profil :* Parisiens actifs, ils ont un weekend de libre à la dernière minute. Ils veulent en profiter pour s'échapper de la ville sans pour autant passer plus de temps dans les transports que sur place. Ils recherchent une expérience authentique et agréable.
  ],"../img/persona03.jpg")

- *Frustrations :*
  - Ne pas savoir quels sont les "vrais" bons plans sur la route, ceux qui valent le détour.
  - Avoir l'impression que prendre les petites routes sans connaitre est un pari risqué qui peut faire perdre beaucoup de temps pour une déception.
  - Les blogs de voyage proposent des listes, mais pas d'itinéraire optimisé "clé en main".

- *Attentes vis-à-vis de l'application :*
  - Gagner du temps dans la planification de leur échappée.
  - Découvrir des lieux insolites et authentiques qu'ils n'auraient pas trouvés seuls.
  - Avoir un itinéraire fluide et réalisable dans la journée.
  - Pouvoir filtrer par type de lieu (ex: "village remarquable", "production locale").

- *Quote :* "On veut que la route fasse partie du plaisir, sans qu'elle devienne une perte de temps. Juste quelques bons stops bien choisis pour casser la monotonie du trajet."

#page(
  flipped: true,
)[

  === Experience Map : une escapade normande

  *Scénario :* Ils sont à Paris et ont envie de passer la journée du samedi à Rouen pour son ambiance médiévale et ses maisons à colombages. Le trajet direct est d'environ 1h30. Ils veulent éviter l'autoroute monotone (A13) et découvrir de charmants villages et peut-être un producteur de cidre sur la route.

  *Objectif :*
  Transformer un trajet direct relativement court (1h30) en une aventure d'une journée, en trouvant des points d'intérêt (villages, artisans) qui justifient de quitter l'axe principal, sans tripler non plus la durée du trajet.

  #table(
    columns: (1.5fr, 2fr, 2fr, 1.5fr, 2fr),
    inset: 10pt,
    align: horizon,
    table.header([*Phase*], [*Actions*], [*Pensées*], [*Émotion*], [*Points de Contact & Opportunités pour l'App*]),
    [ *1. L'Impromptu* ],
    [ Samedi matin, petit-déjeuner. "Et si on allait à Rouen aujourd'hui ? Mais pas directement, si on faisait un peu de route ?" ],
    [ "C'est une super idée ! Mais par où passer ? On va perdre une heure à chercher sur internet..." ],
    [ Enthousiaste mais un peu réticent face à la charge de planification last-minute. ],
    [ L'app comme solution pour une planification rapide et inspirante d'une escapade. ],
    [ *2. Configuration Express* ],
    [ Sophie ouvre l'app. Elle saisit : Origine: Paris - Destination: Rouen. Elle sélectionne le thème "Plus Beaux Villages / Producteurs Locaux".
    Elle limite le détour à +40% du temps initial. ],
    [ "Génial, c'est exactement ce qu'on cherche. Hop, en deux clics c'est parti." ],
    [ Soulagée par la simplicité et l'immédiateté. ],
    [ Interface mobile ultra-simplifiée pour un usage rapide. Pré-remplissage de l'origine via la géolocalisation. ],
    [ *3. La Bonne Surprise* ],
    [ L'app génère un itinéraire en 15 sec. Il quitte l'A13 à Mantes-la-Jolie propose un stop à La Roche-Guyon (l'un des plus beaux villages de France) et chez un cidriculteur à Heurteauville. ],
    [ "Wow, La Roche-Guyon ! J'en avais entendu parler, c'est hyper réputé. Et le cidriculteur est pile sur le chemin. Parfait, trajet passé de 1h30 à 2h45, c'est très raisonnable !" ],
    [ Enthousiaste et impressionnée par la pertinence des choix. ],
    [ L'algorithme prouve sa valeur sur un court trajet en trouvant des perles très proches de l'axe mais qui transforment l'expérience. ],
    [ *4. L'Adjustement* ],
    [ Marc voit que l'app propose aussi un musée. Il le retire d'un swipe. "Pas envie de musée aujourd'hui." L'itinéraire se recalcule, le temps de trajet descend à 2h30. ],
    [ "Top, on peut virer ce qui ne nous correspond pas. L'itinéraire reste cohérent." ],
    [ En contrôle, l'application s'efface au profit de leur expérience. ],
    [ Interface tactile de modification ultra-rapide sur mobile. ],
    [ *5. L'Aventure* ],
    [ Sur la route, ils suivent le guidage. Ils découvrent le village de La Roche-Guyon, son château troglodytique. Ils achètent du cidre directement à la ferme. ],
    [ "C'était exactement le genre de découverte qu'on voulait. On n'aurait jamais osé quitter l'autoroute sans l'app." ],
    [ Conquis, sentiment d'avoir vécu une expérience unique et authentique. ],
    [ Guidage vocal clair entre les POI, fiches avec horaires d'ouverture et photos pour chaque stop. ],
    [ *6. Le Souvenir* ],
    [ À Rouen, ils sauvegardent l'itinéraire dans leurs "favoris". Sophie le partage sur son Instagram story avec un screenshot de la carte. ],
    [ "Il faut qu'on se souvienne de ce trajet pour le refaire avec des amis. Cette app est une pépite !" ],
    [ Fidélisation. L'application devient le compagnon indispensable de leurs escapades. ],
    [ Fonction de sauvegarde et de partage social intuitif. ],
  )
]

