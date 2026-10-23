import { Icon } from "@iconify-icon/react";

interface StatCardProps {
  icon: string;           
  iconBg: string;         
  iconColor: string;      
  label: string;          
  value: string;         
  change?: string;      
  positive?: boolean;      
}

export default function StatCard({
  icon,
  iconBg,
  iconColor,
  label,
  value,
  change,
  positive = true,
}: StatCardProps) {
  return (
    <div className="bg-surface rounded-2xl p-6 border border-border shadow-card hover:shadow-card-hover transition-all duration-300 group">
    
      <div className="flex justify-between items-start mb-4">
   
        <div
          className={`w-12 h-12 rounded-xl ${iconBg} ${iconColor} flex items-center justify-center group-hover:scale-110 transition-transform`}
        >
          <Icon icon={icon} width="24" />
        </div>

        {change && (
          <span
            className={`flex items-center text-xs font-semibold px-2 py-1 rounded-full ${
              positive
                ? 'text-emerald-600 bg-emerald-50'
                : 'text-rose-600 bg-rose-50'
            }`}
          >
            {change}
            <Icon
              icon={
                positive
                  ? 'solar:arrow-right-up-linear'
                  : 'solar:arrow-right-down-linear'
              }
              className="ml-1"
            />
          </span>
        )}
      </div>

      <h3 className="text-text-secondary text-sm font-medium mb-1">
        {label}
      </h3>

      <p className="text-text-primary text-2xl font-bold">{value}</p>
    </div>
  );
}