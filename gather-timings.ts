import fs from 'fs'

const base = process.argv[2] || 'timings'

interface TimingEntry {
  pageLoadTime: number
  fastaDownloadTime: number
  renderTime: number
  totalTime: number
  url: string
}

function extractSizeFromUrl(url: string): { x: string; y: string } | undefined {
  const match = url.match(/(\d+)_(\d+)\.fa/)
  if (match) {
    return { x: match[1], y: match[2] }
  }
  return undefined
}

console.log(
  ['program', 'x_size', 'y_size', 'pageLoadTime', 'fastaDownloadTime', 'renderTime', 'totalTime'].join('\t'),
)

if (!fs.existsSync(base)) {
  process.exit(0)
}

for (const file of fs.readdirSync(base)) {
  if (!file.endsWith('.jsonl')) {
    continue
  }
  const program = file.replace('.jsonl', '')
  const lines = fs.readFileSync(`${base}/${file}`, 'utf8').trim().split('\n')
  for (const line of lines) {
    if (!line) {
      continue
    }
    const entry = JSON.parse(line) as TimingEntry
    const size = extractSizeFromUrl(entry.url)
    if (size && entry.totalTime < 120000) {
      console.log(
        [
          program,
          size.x,
          size.y,
          entry.pageLoadTime,
          entry.fastaDownloadTime ?? 0,
          entry.renderTime,
          entry.totalTime,
        ].join('\t'),
      )
    }
  }
}
