import { useState } from 'react';
import Layout from '../components/layout/Layout';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import { useApi } from '../hooks/useApi';

import { usersService, type User } from '../api/services';
import { Icon } from '@iconify-icon/react';
import { useAuth } from '../contexts/authContexts';


const INITIAL_DATA = {
  data: [],
  pagination: { total: 0, page: 1, limit: 50, totalPages: 0 },
};

export default function Users() {
  const { user: currentAdmin } = useAuth();
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('');

  const { data: response, isLoading, error, refetch } = useApi(
    () => usersService.getAll(1, 50, roleFilter || undefined, search || undefined),
    { initialData: INITIAL_DATA }
  );

  const users = response?.data || [];

  const isSelf = (user: User) => user.id === currentAdmin?.id;

  const handleBan = async (user: User) => {
    if (isSelf(user)) {
      alert('Vous ne pouvez pas vous bannir vous-même.');
      return;
    }
    const reason = prompt(`Motif du bannissement pour ${user.firstname} :`);
    if (!reason) return;
    try {
      await usersService.ban(user.id, reason);
      await refetch();
    } catch (err: any) {
      alert(err?.response?.data?.error || 'Erreur');
    }
  };

  const handleUnban = async (user: User) => {
    if (!confirm(`Débannir ${user.firstname} ?`)) return;
    try {
      await usersService.unban(user.id);
      await refetch();
    } catch (err: any) {
      alert(err?.response?.data?.error || 'Erreur');
    }
  };

  const handleDelete = async (user: User) => {
    if (isSelf(user)) {
      alert('Vous ne pouvez pas supprimer votre propre compte.');
      return;
    }
    if (!confirm(`Supprimer définitivement ${user.firstname} ${user.lastname} ?`)) return;
    try {
      await usersService.delete(user.id);
      await refetch();
    } catch (err: any) {
      alert(err?.response?.data?.error || 'Erreur');
    }
  };

  return (
    <Layout>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-text-primary mb-2">Utilisateurs</h1>
        <p className="text-text-secondary">
          {response?.pagination.total || 0} comptes
        </p>
      </div>

      <div className="bg-surface rounded-2xl border border-border shadow-card overflow-hidden">
    
        <div className="p-6 border-b border-border flex flex-wrap gap-4">
          <input
            type="text"
            placeholder="Rechercher..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-4 py-2 rounded-lg border border-border bg-surface-variant text-sm flex-1 min-w-[200px]"
          />
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-4 py-2 rounded-lg border border-border bg-surface-variant text-sm"
          >
            <option value="">Tous les rôles</option>
            <option value="PLAYER">Joueurs</option>
            <option value="RECRUITER">Recruteurs</option>
            <option value="USER">Fans</option>
            <option value="CLUB_AGENT">Agents</option>
            <option value="ADMIN">Admins</option>
          </select>
        </div>


        {isLoading && (
          <div className="p-12 text-center text-text-secondary">
            Chargement...
          </div>
        )}
        {error && (
          <div className="p-6 bg-rose-50 text-rose-700 text-sm">{error}</div>
        )}

      
        {!isLoading && !error && (
          <table className="w-full">
            <thead>
              <tr className="bg-surface-variant border-b border-border text-xs uppercase text-text-tertiary">
                <th className="px-6 py-4 text-left">Utilisateur</th>
                <th className="px-6 py-4 text-left">Email</th>
                <th className="px-6 py-4 text-left">Rôle</th>
                <th className="px-6 py-4 text-left">Statut</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => {
                const isCurrentAdmin = isSelf(user);

                return (
                  <tr
                    key={user.id}
                    className={`border-b border-border transition-colors ${
                      isCurrentAdmin
                        ? 'bg-amber-50/50' 
                        : 'hover:bg-surface-variant'
                    }`}
                  >
               
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center text-xs font-bold text-amber-700">
                          {user.firstname?.[0]}
                          {user.lastname?.[0]}
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-text-primary">
                            {user.firstname} {user.lastname}
                          </span>
                      
                          {isCurrentAdmin && (
                            <span className="px-2 py-0.5 bg-brand-orange text-white text-[10px] font-bold rounded-full">
                              VOUS
                            </span>
                          )}
                        </div>
                      </div>
                    </td>

                    <td className="px-6 py-4 text-sm text-text-secondary">
                      {user.email}
                    </td>

                    <td className="px-6 py-4 text-sm">{user.role}</td>

                    <td className="px-6 py-4">
                      <Badge status={user.isBanned ? 'Refusé' : 'Actif'} />
                    </td>

                 
                    <td className="px-6 py-4 text-right">
                      {isCurrentAdmin ? (
                   
                        <span className="text-xs text-text-tertiary italic">
                          — Aucune action
                        </span>
                      ) : (
                        <div className="flex gap-2 justify-end">
                          {user.isBanned ? (
                            <Button
                              variant="ghost"
                              onClick={() => handleUnban(user)}
                            >
                              Débannir
                            </Button>
                          ) : (
                            <Button
                              variant="ghost"
                              onClick={() => handleBan(user)}
                            >
                              Bannir
                            </Button>
                          )}
                          <button
                            onClick={() => handleDelete(user)}
                            className="text-error hover:bg-rose-50 p-2 rounded-lg transition-colors"
                            title="Supprimer"
                          >
                            <Icon
                              icon="solar:trash-bin-trash-linear"
                              width={18}
                            />
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </Layout>
  );
}