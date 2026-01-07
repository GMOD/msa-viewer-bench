import fs from 'fs'

const base = process.argv[2] || 'json'
console.log(
  [
    ['program', 'x_size', 'y_size', 'time', 'mean', 'sd'].join('\t'),
    ...fs
      .readdirSync(base)
      .filter(f => f !== 'README.md')
      .flatMap(file => {
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
        return e.times
          .map(time =>
            time < 120
              ? [program, x, y, time, e.mean, e.stddev].join('\t')
              : undefined,
          )
          .filter(f => !!f)
      }),
  ].join('\n'),
)
