import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { addToLibrary, fetchGames, thumb, type Game } from '../api'

export default function Discover() {
  const [q, setQ] = useState('')
  const [games, setGames] = useState<Game[]>([])
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(false)
  const [error, setError] = useState('')
  const [info, setInfo] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    const t = setTimeout(() => {
      fetchGames(q, 1)
        .then((d) => {
          setGames(d.results)
          setPage(1)
          setHasMore(!!d.next)
          setError('')
        })
        .catch((e) => setError(e.message))
    }, 300)
    return () => clearTimeout(t)
  }, [q])

  async function loadMore() {
    const next = page + 1
    try {
      const d = await fetchGames(q, next)
      setGames((prev) => [...prev, ...d.results])
      setPage(next)
      setHasMore(!!d.next)
    } catch (e) {
      setError((e as Error).message)
    }
  }

  async function add(g: Game) {
    setInfo('')
    try {
      await addToLibrary(g.id)
      setInfo(`Dodano „${g.name}” do biblioteki`)
    } catch (e) {
      const msg = (e as Error).message
      if (msg === 'UNAUTHORIZED') navigate('/login')
      else setInfo(msg)
    }
  }

  return (
    <main className="container">
      <Link to="/" className="back">← Odkrywaj gry</Link>
      <p className="muted">Znajdź swoją następną grę</p>
      <input
        className="search"
        placeholder="Szukaj po nazwie"
        value={q}
        onChange={(e) => setQ(e.target.value)}
      />
      {error && <p className="error">{error}</p>}
      {info && <p className="muted">{info}</p>}

      <div className="grid">
        {games.map((g) => (
          <article key={g.id} className="card">
            <img src={thumb(g.id, g.cover_url)} alt={g.name} loading="lazy" />
            <strong>{g.name}</strong>
            <div className="muted">Premiera: {g.release_date}</div>
            {g.rating != null && <div>⭐ Ocena {g.rating.toFixed(1)}</div>}
            <button className="btn-small" onClick={() => add(g)}>+ Do biblioteki</button>
          </article>
        ))}
      </div>

      {hasMore && (
        <button className="btn-small" style={{ marginTop: 24 }} onClick={loadMore}>
          Pokaż więcej
        </button>
      )}
    </main>
  )
}