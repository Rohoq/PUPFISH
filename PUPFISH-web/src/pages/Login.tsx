import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { login } from '../api'

export default function Login() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const navigate = useNavigate()

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    try {
      await login(username, password)
      navigate('/biblioteka')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  return (
    <main className="container">
      <h2>Zaloguj się</h2>
      <form onSubmit={onSubmit} style={{ display: 'grid', gap: 12, maxWidth: 360 }}>
        <input className="search" placeholder="Login" value={username} onChange={(e) => setUsername(e.target.value)} />
        <input className="search" type="password" placeholder="Hasło" value={password} onChange={(e) => setPassword(e.target.value)} />
        <button className="btn-small" type="submit">Zaloguj</button>
        {error && <p className="error">{error}</p>}
      </form>
      <p className="muted">Nie masz konta? <Link to="/register"><u>Zarejestruj się</u></Link></p>
    </main>
  )
}