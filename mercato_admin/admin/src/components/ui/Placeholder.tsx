import Layout from '../layout/Layout';
import EmptyState from './EmptyState';

interface PagePlaceholderProps {
  title: string;
  icon: string;
  description?: string;
}

export default function PagePlaceholder({
  title,
  icon,
  description = 'Cette section est en cours de développement.',
}: PagePlaceholderProps) {
  return (
    <Layout>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-text-primary tracking-tight mb-2">
          {title}
        </h1>
        <p className="text-text-secondary">
          Gérez et consultez vos données en un coup d'œil.
        </p>
      </div>

      <div className="bg-surface rounded-2xl border border-border shadow-card">
        <EmptyState
          icon={icon}
          title={title}
          subtitle={description}
        />
      </div>
    </Layout>
  );
}