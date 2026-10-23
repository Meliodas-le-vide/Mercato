// src/pages/Recruiters.tsx
import { useState } from 'react';
import Layout from '../components/layout/Layout';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import { useApi } from '../hooks/useApi';
import { recruitersService } from '../api/services';

export default function Recruiters() {
  const [statusFilter, setStatusFilter] = useState<string>('PENDING');

  const { data: recruiters, isLoading, error, refetch } = useApi(
    () => recruitersService.getAll(statusFilter || undefined),
    { initialData: [] }
  );

  const handleVerify = async (id: number, status: 'VERIFIED' | 'REJECTED') => {
    try {
      await recruitersService.verify(id, status);
      await refetch();
    } catch { alert('Erreur'); }
  };

  return (
    <Layout>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-text-primary mb-2">Recruteurs</h1>
        <p className="text-text-secondary">{recruiters?.length || 0} demandes KYC</p>
      </div>

      <div className="bg-surface rounded-2xl border border-border shadow-card overflow-hidden">
        <div className="p-6 border-b border-border">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-4 py-2 rounded-lg border border-border bg-surface-variant text-sm"
          >
            <option value="PENDING">En attente</option>
            <option value="VERIFIED">Vérifiés</option>
            <option value="REJECTED">Refusés</option>
            <option value="">Tous</option>
          </select>
        </div>

        {isLoading && <div className="p-12 text-center">Chargement...</div>}
        {error && <div className="p-6 bg-rose-50 text-rose-700">{error}</div>}

        {!isLoading && !error && (
          <table className="w-full">
            <thead>
              <tr className="bg-surface-variant border-b border-border text-xs uppercase text-text-tertiary">
                <th className="px-6 py-4 text-left">Recruteur</th>
                <th className="px-6 py-4 text-left">Organisation</th>
                <th className="px-6 py-4 text-left">Licence</th>
                <th className="px-6 py-4 text-left">Statut</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {recruiters?.map((r) => (
                <tr key={r.id} className="border-b border-border hover:bg-surface-variant">
                  <td className="px-6 py-4">
                    <div className="font-medium">{r.user?.firstname} {r.user?.lastname}</div>
                    <div className="text-xs text-text-tertiary">{r.user?.email}</div>
                  </td>
                  <td className="px-6 py-4 text-sm">{r.organizationName || '—'}</td>
                  <td className="px-6 py-4 text-xs font-mono">{r.licenseNumber || '—'}</td>
                  <td className="px-6 py-4">
                    <Badge
                      status={
                        r.verificationStatus === 'PENDING' ? 'En attente'
                        : r.verificationStatus === 'VERIFIED' ? 'Actif'
                        : 'Refusé'
                      }
                    />
                  </td>
                  <td className="px-6 py-4 text-right">
                    {r.verificationStatus === 'PENDING' && (
                      <div className="flex gap-2 justify-end">
                        <Button variant="primary" onClick={() => handleVerify(r.id, 'VERIFIED')}>Valider</Button>
                        <Button variant="danger" onClick={() => handleVerify(r.id, 'REJECTED')}>Refuser</Button>
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