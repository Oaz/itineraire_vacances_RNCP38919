docker build -t typst-mermaid ./docgen
docker run -v $(pwd):/workdir -v $(pwd)/fonts:/fonts \
  -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) typst-mermaid main.typ dossier_projet.pdf
