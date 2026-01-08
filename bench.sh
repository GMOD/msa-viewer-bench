#!/bin/bash

ITERS=10

echo "=== Step 1: Clear old results ==="
rm -rf screenshots json timings
mkdir -p screenshots json timings

echo ""
echo "=== Step 2: Run benchmarks ==="

function bench() {
  echo "--- Testing $1 ---"

  # Remote Jalview with annotation tracks disabled
  hyperfine -i --warmup 1 --export-json json/jalview-$1.json --runs $ITERS "node bench/jalview.ts 'https://www.jalview.org/jalview-js/JalviewJS.shtml/?-setprop%20SHOW_CONSERVATION=false%20-setprop%20SHOW_QUALITY=false%20-setprop%20SHOW_IDENTITY=false%20-setprop%20SHOW_OCCUPANCY=false%20-setprop%20SHOW_CONSENSUS_HISTOGRAM=false%20-setprop%20SHOW_CONSENSUS_LOGO=false%20open%20https://jbrowse.org/demos/msabench/$1'" || true

  hyperfine -i --warmup 1 --export-json json/jbrowsemsa-$1.json --runs $ITERS "node bench/jbrowsemsa.ts 'https://gmod.org/JBrowseMSA/?data={\"msaview\":{\"msaFilehandle\":{\"uri\":\"https://jbrowse.org/demos/msabench/$1\"}}}'" || true

  hyperfine -i --warmup 1 --export-json json/wasabi-$1.json --runs $ITERS "node bench/wasabi.ts 'http://was.bi/userID?url=https://jbrowse.org/demos/msabench/$1'" || true

  hyperfine -i --warmup 1 --export-json json/biojsmsa-$1.json --runs $ITERS "node bench/biojsmsa.ts 'https://jbrowse.org/demos/msabench-biojs/?file=https://jbrowse.org/demos/msabench/$1'" || true

  echo ""
}

for file in out/*.fa; do
  F=$(basename $file)
  bench $F
done

echo ""
echo "=== Step 3: Gather results and make plots ==="
node gather.ts
node gather-timings.ts >timings.tsv
Rscript plot.R

echo ""
echo "=== Done! ==="
echo "Results written to: varyXY.tsv, varyX.tsv, varyY.tsv, timings.tsv"
echo "Plots written to: img/"
