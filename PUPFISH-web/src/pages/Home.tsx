import { Link } from 'react-router-dom'
import { isLoggedIn, logout } from '../api'

const items = [
  { to: '/odkrywaj', title: 'Katalog gier', desc: 'Wyszukaj kolejny ulubiony tytuł' },
  { to: '/biblioteka', title: 'Moja biblioteka', desc: 'Wszystkie dodane przez Ciebie gry' },
]

export default function Home() {
  const logged = isLoggedIn()

  return (
    <main className="container">
      <h1 className="logo">🐟 pupfish</h1>
      <h2>Twoja kolekcja, twoje zasady.</h2>
      <p className="muted">Odkrywaj gry i miej wszystkie ulubione tytuły w jednym miejscu.</p>

      <section className="banner">
        <h3>Czas na nową przygodę?</h3>
        <p>Znajdź coś dla siebie w katalogu gier.</p>
        <Link to="/odkrywaj" className="btn">Odkrywaj gry</Link>
      </section>

      <h3>Twoje miejsce</h3>
      <div className="list">
        {items.map((i) => (
          <Link key={i.to} to={i.to} className="row">
            <div>
              <strong>{i.title}</strong>
              <div className="muted">{i.desc}</div>
            </div>
            <span>›</span>
          </Link>
        ))}
      </div>

      <p className="muted" style={{ marginTop: 24 }}>
        {logged ? (
          <a href="/" onClick={() => logout()}><u>Wyloguj</u></a>
        ) : (
          <>
            <Link to="/login"><u>Zaloguj się</u></Link> lub{' '}
            <Link to="/register"><u>załóż konto</u></Link>
          </>
        )}
      </p>
    </main>
  )
}