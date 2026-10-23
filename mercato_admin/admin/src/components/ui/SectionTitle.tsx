
import type { ReactNode } from 'react';

interface SectionTitleProps {
  title: string;
  subtitle?: string;
  action?: ReactNode;  
}

export default function SectionTitle({
  title,
  subtitle,
  action,
}: SectionTitleProps) {
  return (
    <div className="flex items-start justify-between mb-4">
   
      <div>
        <h3 className="text-text-primary text-lg font-semibold tracking-tight">
          {title}
        </h3>
        {subtitle && (
          <p className="text-text-secondary text-xs mt-1">{subtitle}</p>
        )}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
}