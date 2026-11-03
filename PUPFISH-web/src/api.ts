export type Game = {
    id: number
    name: string
    release_date: string
    rating: number | null
    aggregated_rating: number
    steam_app_id: string | null
    cover_url: string | null
  }
  
  export type LibraryEntry = {
    id: number
    game: number
    game_name: string
    game_release_date: string
    game_cover_url: string | null
    rating: number | null
    state: 'playing' | 'completed' | 'dropped'
  }
  
  export type Paged<T> = {
    count: number
    next: string | null
    previous: string | null
    results: T[]
  }
  
  export const STATE_LABELS: Record<LibraryEntry['state'], string> = {
    playing: 'Gram',
    completed: 'Ukończona',
    dropped: 'Porzucona',
  }
  
  export const thumb = (gameId: number, url: string | null) =>
    url ?? `/api/games/${gameId}/thumbnail/`
  
  // ---------- tokeny ----------
  export const isLoggedIn = () => !!localStorage.getItem('access')
  
  export function logout() {
    localStorage.removeItem('access')
    localStorage.removeItem('refresh')
  }
  
  async function readError(res: Response): Promise<string> {
    try {
      const data = await res.json()
      return Object.values(data).flat().join(' ') || `Błąd ${res.status}`
    } catch {
      return `Błąd ${res.status}`
    }
  }
  
  export async function login(username: string, password: string) {
    const res = await fetch('/api/login/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    })
    if (!res.ok) throw new Error('Nieprawidłowe dane logowania')
    const { access, refresh } = await res.json()
    localStorage.setItem('access', access)
    localStorage.setItem('refresh', refresh)
  }
  
  export async function register(username: string, email: string, password: string) {
    const res = await fetch('/api/register/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, email, password }),
    })
    if (!res.ok) throw new Error(await readError(res))
  }
  
  async function refreshToken(): Promise<boolean> {
    const refresh = localStorage.getItem('refresh')
    if (!refresh) return false
    const res = await fetch('/api/token/refresh/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh }),
    })
    if (!res.ok) return false
    localStorage.setItem('access', (await res.json()).access)
    return true
  }
  
  export async function authFetch(url: string, init: RequestInit = {}): Promise<Response> {
    const send = () =>
      fetch(url, {
        ...init,
        headers: {
          'Content-Type': 'application/json',
          ...init.headers,
          Authorization: `Bearer ${localStorage.getItem('access')}`,
        },
      })
    let res = await send()
    if (res.status === 401 && (await refreshToken())) res = await send()
    if (res.status === 401) logout()
    return res
  }
  
  // ---------- gry ----------
  export async function fetchGames(q = '', page = 1): Promise<Paged<Game>> {
    const res = await fetch(`/api/games/?search=${encodeURIComponent(q)}&page=${page}`)
    if (!res.ok) throw new Error(`Błąd ${res.status}`)
    return res.json()
  }
  
  // ---------- biblioteka ----------
  export async function fetchLibrary(): Promise<LibraryEntry[]> {
    const all: LibraryEntry[] = []
    for (let page = 1; ; page++) {
      const res = await authFetch(`/api/library/?page=${page}`)
      if (res.status === 401) throw new Error('UNAUTHORIZED')
      if (!res.ok) throw new Error(await readError(res))
      const data: Paged<LibraryEntry> = await res.json()
      all.push(...data.results)
      if (!data.next) return all
    }
  }
  
  export async function addToLibrary(gameId: number, state: LibraryEntry['state'] = 'playing') {
    const res = await authFetch('/api/library/', {
      method: 'POST',
      body: JSON.stringify({ game: gameId, state }),
    })
    if (res.status === 401) throw new Error('UNAUTHORIZED')
    if (res.status === 400) throw new Error('Ta gra jest już w Twojej bibliotece')
    if (!res.ok) throw new Error(await readError(res))
  }
  
  export async function updateLibraryState(id: number, state: LibraryEntry['state']) {
    const res = await authFetch(`/api/library/${id}/`, {
      method: 'PATCH',
      body: JSON.stringify({ state }),
    })
    if (!res.ok) throw new Error(await readError(res))
  }
  
  export async function removeFromLibrary(id: number) {
    const res = await authFetch(`/api/library/${id}/`, { method: 'DELETE' })
    if (!res.ok) throw new Error(await readError(res))
  }