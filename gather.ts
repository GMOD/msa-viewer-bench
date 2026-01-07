import fs from 'fs'

const base = process.argv[2] || 'json'

interface Result {
  program: string
  x: string
  y: string
  time: number
  mean: number
  sd: number
}

const results: Result[] = []

for (const file of fs.readdirSync(base)) {
  if (file === 'README.md') {
    continue
  }
  const text = fs.readFileSync(`${base}/${file}`, 'utf8')
  const res = JSON.parse(text)
  const e = res.results[0] as {
    times: number[]
    mean: number
    stddev: number
  }
  const r = file.replace('.fa.json', '')
  const [program, sample] = r.split('-')
  const [x, y] = sample.split('_')

  for (const time of e.times) {
    if (time < 120) {
      results.push({ program, x, y, time, mean: e.mean, sd: e.stddev })
    }
  }
}

function formatTsv(rows: Result[]): string {
  const header = ['program', 'x_size', 'y_size', 'size', 'time', 'mean', 'sd'].join('\t')
  const lines = rows.map(r =>
    [r.program, r.x, r.y, Number(r.x) * Number(r.y), r.time, r.mean, r.sd].join('\t'),
  )
  return [header, ...lines].join('\n')
}

// Categorize by test type
// Filename format: x_y.fa where x is first number, y is second
const varyXY = results.filter(r => r.x === r.y)
const varyX = results.filter(r => r.y === '100' && r.x !== '100') // files like 128_100.fa
const varyY = results.filter(r => r.x === '100' && r.y !== '100') // files like 100_128.fa

fs.writeFileSync('varyXY.tsv', formatTsv(varyXY))
fs.writeFileSync('varyX.tsv', formatTsv(varyX))
fs.writeFileSync('varyY.tsv', formatTsv(varyY))

console.log(`Wrote ${varyXY.length} rows to varyXY.tsv`)
console.log(`Wrote ${varyX.length} rows to varyX.tsv`)
console.log(`Wrote ${varyY.length} rows to varyY.tsv`)
