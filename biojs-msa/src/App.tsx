// @ts-expect-error
import msa, { io, utils } from 'msa'
import { useEffect, useRef, useState } from 'react'
import 'msa/css/msa.css'

const params = new URLSearchParams(window.location.search)
const file =
  params.get('file') || 'https://jbrowse.org/demos/msabench/128_128.fa'

function parseSmallFasta(text: string) {
  return text
    .split('>')
    .filter(t => /\S/.test(t))
    .map((entryText, idx) => {
      const [defLine, ...seqLines] = entryText.split('\n')
      const [id] = defLine!.split(' ')
      const seq = seqLines.join('').replace(/\s/g, '')
      return { id: 'r' + idx, meta: {}, name: id, seq } as const
    })
}

export default function MSA() {
  const ref = useRef<HTMLDivElement>(null)
  const renderRef = useRef(false)
  const [error, setError] = useState<unknown>()
  useEffect(() => {
    if (!ref.current) {
      return
    }

    ;(async () => {
      try {
        if (!renderRef.current) {
          renderRef.current = true
          const res = await fetch(file)

          if (!res.ok) {
            throw new Error(`HTTP ${res.status} fetching ${file}`)
          }
          const seqs = parseSmallFasta(await res.text())
          var m = new msa({
            el: ref.current,
            seqs,
            vis: {
              conserv: true,
            },
          })
          m.render()
        }
      } catch (e) {
        setError(e)
        console.error(e)
      }
    })()
  }, [])

  return (
    <>
      {error ? <div style={{ color: 'red' }}>{`${error}`}</div> : null}
      <div ref={ref} />
    </>
  )
}
