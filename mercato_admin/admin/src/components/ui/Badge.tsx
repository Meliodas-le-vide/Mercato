
type BadgeStatus =
  | 'Actif'
  | 'Publiée'
  | 'Completed'
  | 'En attente'
  | 'KYC en attente'
  | 'Pending'
  | 'Refusé'
  | 'Failed'
  | 'Basse'
  | 'Moyenne'
  | 'Haute';

interface BadgeProps {
  status: BadgeStatus | string;
}


const STATUS_STYLES: Record<string, string> = {

  'Actif': 'bg-emerald-100 text-emerald-700',
  'Publiée': 'bg-emerald-100 text-emerald-700',
  'Completed': 'bg-emerald-100 text-emerald-700',


  'En attente': 'bg-amber-100 text-amber-700',
  'KYC en attente': 'bg-amber-100 text-amber-700',
  'Pending': 'bg-amber-100 text-amber-700',
  'Moyenne': 'bg-amber-100 text-amber-700',


  'Refusé': 'bg-rose-100 text-rose-700',
  'Failed': 'bg-rose-100 text-rose-700',
  'Haute': 'bg-rose-100 text-rose-700',


  'Basse': 'bg-slate-100 text-slate-700',
};

export default function Badge({ status }: BadgeProps) {
  const style = STATUS_STYLES[status] || 'bg-slate-100 text-slate-700';

  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${style}`}
    >
      {status}
    </span>
  );
}