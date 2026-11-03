import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  fetchLibrary, removeFromLibrary, updateLibraryState, thumb,
  STATE_LABELS, type LibraryEntry,
} from '../api'

export default function Library() {
  const [items, setItems] = useState<LibraryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    fetchLibrary()
      .then(setItems)
      .catch((e) => {
        if (e.message === 'UNAUTHORIZED') navigate('/login')
        else setError(e.message)
      })
      .finally(() => setLoading(false))
  }, [navigate])

  async function changeState(id: number, state: LibraryEntry['state']) {
    await updateLibraryState(id, state)
    setItems((prev) => prev.map((i) => (i.id === id ? { ...i, state } : i)))
  }

  async function remove(id: number) {
    await removeFromLibrary(id)
    setItems((prev) => prev.filter((i) => i.id !== id))
  }

  return (
    <main className="container">
      <Link to="/" className="back">← Moja biblioteka</Link>
      {error && <p className="error">{error}</p>}
      {loading && <p className="muted">Ładowanie…</p>}
      {!loading && items.length === 0 && !error && (
        <p className="muted">
          Nie masz jeszcze żadnych gier. <Link to="/odkrywaj"><u>Przeglądaj katalog</u></Link>
        </p>
      )}

      <div className="grid">
        {items.map((i) => (
          <article key={i.id} className="card">
            <img src={thumb(i.game, i.game_cover_url)} alt={i.game_name} loading="lazy" />
            <strong>{i.game_name}</strong>
            <div className="muted">Premiera: {i.game_release_date}</div>
            <select value={i.state} onChange={(e) => changeState(i.id, e.target.value as LibraryEntry['state'])}>
              {Object.entries(STATE_LABELS).map(([v, label]) => (
                <option key={v} value={v}>{label}</option>
              ))}
            </select>
            <button className="btn-small danger" onClick={() => remove(i.id)}>Usuń</button>
          </article>
        ))}
      </div>
    </main>
  )
}