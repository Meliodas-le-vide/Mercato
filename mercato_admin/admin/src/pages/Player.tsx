// src/pages/Players.tsx
import Layout from '../components/layout/Layout';
import Badge from '../components/ui/Badge';
import { useApi } from '../hooks/useApi';
import { usersService } from '../api/services';

export default function Players() {
  const { data: response, isLoading } = useApi(
    () => usersService.getAll(1, 50, 'PLAYER'),
    { initialData: { data: [], pagination: { total: 0, page: 1, limit: 50, totalPages: 0 } } }
  );

  const players = response?.data || [];

  return (
    <Layout>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-text-primary mb-2">Joueurs</h1>
        <p className="text-text-secondary">{response?.pagination.total || 0} joueurs</p>
      </div>

      <div className="bg-surface rounded-2xl border border-border shadow-card overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center">Chargement...</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="bg-surface-variant border-b border-border text-xs uppercase text-text-tertiary">
                <th className="px-6 py-4 text-left">Nom</th>
                <th className="px-6 py-4 text-left">Email</th>
                <th className="px-6 py-4 text-left">Statut</th>
              </tr>
            </thead>
            <tbody>
              {players.map((p) => (
                <tr key={p.id} className="border-b border-border hover:bg-surface-variant">
                  <td className="px-6 py-4 font-medium">{p.firstname} {p.lastname}</td>
                  <td className="px-6 py-4 text-sm">{p.email}</td>
                  <td className="px-6 py-4">
                    <Badge status={p.isBanned ? 'Refusé' : 'Actif'} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  );
}