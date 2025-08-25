#import "lib.typ": *

#show: thesis.with(
  draft: false,
  colored: true,
  logo: "img/datascientest.png",
  logo-width: 6cm,
  title: "Itinéraire de vacances",
  author: "Olivier Azeau",
  email: "datascientest@azeau.com",
  details1: "RNCP 38919",
  details2: "Dossier de projet",
  date: datetime.today(),
  language: "fr",

  chapters: (
    include "content/01_vision_produit.typ",
    include "content/02_personas.typ",
    include "content/03_exploration.typ",
    include "content/04_mvp.typ",
    include "content/05_deploiement.typ",
    include "content/06_qualite.typ",
    include "content/07_futur.typ",
  ),

)
