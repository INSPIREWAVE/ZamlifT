import { useEffect, useMemo, useState } from 'react';

const apiBase = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api';

const sections = [
  { key: 'drivers', title: 'Pending Driver Approvals', endpoint: '/drivers/pending' },
  { key: 'payments', title: 'Payments', endpoint: '/payments' },
  { key: 'bookings', title: 'Bookings', endpoint: '/bookings' },
  { key: 'trips', title: 'Trips Monitor', endpoint: '/trips' },
];

async function parseError(response, fallbackMessage) {
  try {
    const body = await response.json();
    if (body?.message && typeof body.message === 'string' && body.message.trim()) {
      return body.message.trim();
    }
  } catch {
    // ignore parse failures and fallback
  }

  return fallbackMessage;
}

function useAdminData(token) {
  const [data, setData] = useState({ drivers: [], payments: [], bookings: [], trips: [] });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;

    const load = async () => {
      setLoading(true);
      setError('');
      try {
        const entries = await Promise.all(
          sections.map(async ({ key, endpoint }) => {
            const response = await fetch(`${apiBase}${endpoint}`, {
              headers: { Authorization: `Bearer ${token}` },
            });
            if (!response.ok) {
              const fallback = `${response.status} ${response.statusText || 'Request failed'}`.trim();
              const message = await parseError(response, fallback);
              throw new Error(message);
            }

            const payload = await response.json();
            return [key, Array.isArray(payload) ? payload : []];
          }),
        );

        if (active) {
          setData(Object.fromEntries(entries));
        }
      } catch (err) {
        if (active) {
          setError(err.message || 'Unable to load admin data');
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    };

    load();
    return () => {
      active = false;
    };
  }, [token]);

  return { data, error, loading };
}

function App() {
  const [token, setToken] = useState(import.meta.env.VITE_ADMIN_JWT || '');
  const { data, error, loading } = useAdminData(token);

  const counts = useMemo(
    () => ({
      drivers: data.drivers.length,
      trips: data.trips.length,
      payments: data.payments.length,
      bookings: data.bookings.length,
    }),
    [data],
  );

  return (
    <main className="container">
      <header>
        <h1>ZamLift Admin Dashboard</h1>
        <p>Manage bookings, driver approvals, trip activity, and payment lifecycle.</p>
      </header>

      <section className="tokenRow">
        <input
          value={token}
          onChange={(e) => setToken(e.target.value.trim())}
          placeholder="Paste admin JWT token"
          aria-label="Admin JWT token"
        />
        <small>Set VITE_ADMIN_JWT in .env for persistent local development.</small>
      </section>

      {error ? <p className="error">{error}</p> : null}
      {loading ? <p>Loading dashboard data…</p> : null}

      <section className="cards">
        <article className="card"><h2>Pending Drivers</h2><p>{counts.drivers}</p></article>
        <article className="card"><h2>Trips</h2><p>{counts.trips}</p></article>
        <article className="card"><h2>Payments</h2><p>{counts.payments}</p></article>
        <article className="card"><h2>Bookings</h2><p>{counts.bookings}</p></article>
      </section>

      <section className="grid">
        <DataTable title="Pending Driver Approvals" rows={data.drivers} columns={['user_id', 'full_name', 'email', 'phone', 'verification_status']} />
        <DataTable title="Trips Monitor" rows={data.trips} columns={['id', 'driver_name', 'route_name', 'status', 'seats_available']} />
        <DataTable title="Payments" rows={data.payments} columns={['id', 'booking_id', 'payer_name', 'amount', 'status']} />
        <DataTable title="Bookings" rows={data.bookings} columns={['id', 'trip_id', 'passenger_name', 'seats_booked', 'total_price', 'status']} />
      </section>
    </main>
  );
}

function DataTable({ title, rows, columns }) {
  return (
    <article className="panel">
      <h3>{title}</h3>
      <div className="tableWrap">
        <table>
          <thead>
            <tr>{columns.map((column) => <th key={column}>{column}</th>)}</tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr><td colSpan={columns.length}>No data</td></tr>
            ) : (
              rows.map((row) => (
                <tr key={row.id || JSON.stringify(row)}>
                  {columns.map((column) => <td key={column}>{String(row[column] ?? '')}</td>)}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </article>
  );
}

export default App;
