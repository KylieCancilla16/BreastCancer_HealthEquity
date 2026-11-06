
#!/bin/bash
set -e

docker build -t final_project .

docker run --rm -it \
  -p 8787:8787 \
  -e PASSWORD=rstudio \
  -v "$PWD:/home/rstudio/work" \
  final_project
