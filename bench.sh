#!/bin/bash

ITERS=1

rm -rf screenshots
mkdir screenshots

function bench() {

  # Remote Jalview with annotation tracks disabled
  hyperfine -i --export-json json/jalview-$1.json --runs $ITERS "node bench/jalview.ts 'https://www.jalview.org/jalview-js/JalviewJS.shtml/?-setprop%20SHOW_CONSERVATION=false%20-setprop%20SHOW_QUALITY=false%20-setprop%20SHOW_CONSENSUS=false%20-setprop%20SHOW_OCCUPANCY=false%20-setprop%20SHOW_CONSENSUS_HISTOGRAM=false%20open%20https://jbrowse.org/demos/msabench/$1'"

  hyperfine -i --export-json json/jbrowsemsa-$1.json --runs $ITERS "node bench/jbrowsemsa.ts 'https://gmod.org/JBrowseMSA/?data={\"msaview\":{\"msaFilehandle\":{\"uri\":\"https://jbrowse.org/demos/msabench/$1\"}}}'"

  hyperfine -i --export-json json/wasabi-$1.json --runs $ITERS "node bench/wasabi.ts 'http://was.bi/userID?url=https://jbrowse.org/demos/msabench/$1'"

  hyperfine -i --export-json json/biojsmsa-$1.json --runs $ITERS "node bench/biojsmsa.ts 'https://jbrowse.org/demos/msabench-biojs/?file=https://jbrowse.org/demos/msabench/$1'"
}

for file in out/*.fa; do
  F=$(basename $file)
  echo "TESTING $F"
  bench $F
  echo -e "\n\n\n\n\n"
done
