// src/components/ui/EmptyState.tsx
// État vide : "Aucune donnée" avec icône et message

import { Icon } from '@iconify-icon/react';
import type { ReactNode } from 'react';

interface EmptyStateProps {
  icon: string;              
  title: string;             
  subtitle?: string;          
  action?: ReactNode;          
}

export default function EmptyState({
  icon,
  title,
  subtitle,
  action,
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
  
      <div className="w-16 h-16 rounded-full bg-amber-50 flex items-center justify-center mb-4">
        <Icon
          icon={icon}
          width="32"
          style={{ color: '#FF6F00' }}
        />
      </div>

      <h3 className="text-text-primary text-base font-semibold mb-2">
        {title}
      </h3>

      {subtitle && (
        <p className="text-text-secondary text-sm max-w-sm mb-6">
          {subtitle}
        </p>
      )}

      {action && <div>{action}</div>}
    </div>
  );
}