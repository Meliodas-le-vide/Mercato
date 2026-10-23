// src/pages/Reports.tsx
import Layout from '../components/layout/Layout';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import { useApi } from '../hooks/useApi';
import { reportsService } from '../api/services';

export default function Reports() {
  const { data: reports, isLoading, error, refetch } = useApi(
    () => reportsService.getAll(),
    { initialData: [] }
  );

  const handleReview = async (id: number, status: 'REVIEWED' | 'DISMISSED') => {
    try { await reportsService.review(id, status); await refetch(); } catch { alert('Erreur'); }
  };

  return (
    <Layout>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-text-primary mb-2">Signalements</h1>
        <p className="text-text-secondary">{reports?.length || 0} signalements</p>
      </div>

      <div className="bg-surface rounded-2xl border border-border shadow-card overflow-hidden">
        {isLoading && <div className="p-12 text-center">Chargement...</div>}
        {error && <div className="p-6 bg-rose-50 text-rose-700">{error}</div>}

        {!isLoading && !error && (
          <table className="w-full">
            <thead>
              <tr className="bg-surface-variant border-b border-border text-xs uppercase text-text-tertiary">
                <th className="px-6 py-4 text-left">Signalé par</th>
                <th className="px-6 py-4 text-left">Cible</th>
                <th className="px-6 py-4 text-left">Raison</th>
                <th className="px-6 py-4 text-left">Statut</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {reports?.map((r) => (
                <tr key={r.id} className="border-b border-border hover:bg-surface-variant">
                  <td className="px-6 py-4 text-sm">{r.reporter?.firstname} {r.reporter?.lastname}</td>
                  <td className="px-6 py-4 text-sm">{r.target?.firstname} {r.target?.lastname}</td>
                  <td className="px-6 py-4 text-sm">{r.reason}</td>
                  <td className="px-6 py-4"><Badge status={r.status} /></td>
                  <td className="px-6 py-4 text-right">
                    {r.status === 'OPEN' && (
                      <div className="flex gap-2 justify-end">
                        <Button variant="primary" onClick={() => handleReview(r.id, 'REVIEWED')}>Traiter</Button>
                        <Button variant="ghost" onClick={() => handleReview(r.id, 'DISMISSED')}>Rejeter</Button>
                      </div>
                    )}
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