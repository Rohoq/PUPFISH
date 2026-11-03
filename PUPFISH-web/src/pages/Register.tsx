import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { register, login } from '../api'

export default function Register() {
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const navigate = useNavigate()

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    try {
      await register(username, email, password)
      await login(username, password) // od razu zaloguj
      navigate('/odkrywaj')
    } catch (err) {
      setError((err as Error).message)
    }
  }

  return (
    <main className="container">
      <h2>Załóż konto</h2>
      <form onSubmit={onSubmit} style={{ display: 'grid', gap: 12, maxWidth: 360 }}>
        <input className="search" placeholder="Login" value={username} onChange={(e) => setUsername(e.target.value)} />
        <input className="search" type="email" placeholder="E-mail" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input className="search" type="password" placeholder="Hasło" value={password} onChange={(e) => setPassword(e.target.value)} />
        <button className="btn-small" type="submit">Zarejestruj</button>
        {error && <p className="error">{error}</p>}
      </form>
      <p className="muted">Masz już konto? <Link to="/login"><u>Zaloguj się</u></Link></p>
    </main>
  )
}