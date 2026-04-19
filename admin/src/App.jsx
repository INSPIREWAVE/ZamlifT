import { useEffect, useMemo, useState } from 'react';

const apiBase = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api';

const sections = [
  { key: 'users', title: 'Users', endpoint: '/admin/users' },
  { key: 'drivers', title: 'Pending Driver Approvals', endpoint: '/admin/drivers/pending' },
  { key: 'trips', title: 'Trips Monitor', endpoint: '/admin/trips' },
  { key: 'payments', title: 'Payments', endpoint: '/admin/payments' },
];

function useAdminData(token) {
  const [data, setData] = useState({ users: [], drivers: [], trips: [], payments: [] });
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
              throw new Error(`Failed to load ${key}`);
            }
            return [key, await response.json()];
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
      users: data.users.length,
      drivers: data.drivers.length,
      trips: data.trips.length,
      payments: data.payments.length,
    }),
    [data],
  );

  return (
    <main className="container">
      <header>
        <h1>ZamLift Admin Dashboard</h1>
        <p>Manage users, driver approvals, trip activity, and payment lifecycle.</p>
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
        <article className="card"><h2>Users</h2><p>{counts.users}</p></article>
        <article className="card"><h2>Pending Drivers</h2><p>{counts.drivers}</p></article>
        <article className="card"><h2>Trips</h2><p>{counts.trips}</p></article>
        <article className="card"><h2>Payments</h2><p>{counts.payments}</p></article>
      </section>

      <section className="grid">
        <DataTable title="Users" rows={data.users} columns={['id', 'full_name', 'email', 'role']} />
        <DataTable title="Pending Driver Approvals" rows={data.drivers} columns={['id', 'full_name', 'email', 'verification_status']} />
        <DataTable title="Trips Monitor" rows={data.trips} columns={['id', 'driver_name', 'start_location', 'destination', 'status']} />
        <DataTable title="Payments" rows={data.payments} columns={['id', 'booking_id', 'provider', 'amount', 'status']} />
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
