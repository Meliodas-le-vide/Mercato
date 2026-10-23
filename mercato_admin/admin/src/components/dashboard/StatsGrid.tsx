import StatCard from '../ui/StatCard';
import { useApi } from '../../hooks/useApi';
import { statsService } from '../../api/services';

export default function StatsGrid() {
  const { data: stats, isLoading, error } = useApi(
    () => statsService.getDashboardStats(),
    { initialData: undefined }
  );

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="bg-surface rounded-2xl p-6 border border-border shadow-card animate-pulse h-32" />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-rose-50 border border-rose-200 text-rose-700 rounded-xl p-4 mb-8 text-sm">
         Impossible de charger les statistiques : {error}
      </div>
    );
  }

  const cards = [
    { id: 'players', icon: 'solar:football-linear', iconBg: 'bg-amber-50', iconColor: 'text-brand-yellow', label: 'Joueurs inscrits', value: stats?.totalPlayers?.toLocaleString('fr-FR') || '0' },
    { id: 'videos', icon: 'solar:videocamera-record-linear', iconBg: 'bg-orange-50', iconColor: 'text-brand-orange', label: 'Vidéos publiées', value: stats?.totalVideos?.toLocaleString('fr-FR') || '0' },
    { id: 'reports', icon: 'solar:danger-triangle-linear', iconBg: 'bg-rose-50', iconColor: 'text-error', label: 'Signalements', value: stats?.totalReports?.toLocaleString('fr-FR') || '0' },
    { id: 'recruiters', icon: 'solar:user-check-rounded-linear', iconBg: 'bg-sky-50', iconColor: 'text-info', label: 'Recruteurs', value: stats?.totalRecruiters?.toLocaleString('fr-FR') || '0' },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      {cards.map((card) => (
        <StatCard key={card.id} {...card} />
      ))}
    </div>
  );
}