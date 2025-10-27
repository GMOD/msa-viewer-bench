import puppeteer from 'puppeteer'
import fs from 'fs'

const browser = await puppeteer.launch({
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
})
const page = await browser.newPage()
const url = process.argv[2]

await page.goto(url)

// Set screen size
await page.setViewport({
  width: 1080,
  height: 1024,
})

await page.waitForSelector('canvas', { timeout: 120000 })
const ret = await page.$eval('canvas', (val: HTMLCanvasElement) =>
  val.toDataURL().replace(/^data:image\/\w+;base64,/, ''),
)
fs.mkdirSync('screenshots', { recursive: true })
const p = encodeURIComponent(url)
await page.screenshot({
  path: `screenshots/jbrowsemsa-fullpage-${p}.png`,
})
fs.writeFileSync(
  `screenshots/jbrowsemsa-fragment-${p}.png`,
  Buffer.from(ret, 'base64'),
)

await browser.close()
