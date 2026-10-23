

import { Link, useLocation } from 'react-router-dom';
import { navItems } from '../../data/mockData';
import { Icon } from '@iconify-icon/react';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function Sidebar({ isOpen, onClose }: SidebarProps) {
  const location = useLocation(); 

  return (
    <aside
      className={`sidebar-transition fixed inset-y-0 left-0 z-50 w-64 bg-surface border-r border-border flex flex-col justify-between md:relative md:translate-x-0 ${
        isOpen ? 'translate-x-0' : '-translate-x-full'
      }`}
    >
   
      <div className="h-16 flex items-center px-6 border-b border-border">
        <Link to="/" className="flex items-center gap-3">
       
          <div className="w-9 h-9 rounded-lg bg-linear-to-br from-brand-yellow to-brand-orange flex items-center justify-center text-white font-bold text-sm shadow-md">
            MT
          </div>
          <div className="flex flex-col leading-tight">
            <span className="text-text-primary text-base font-bold tracking-tight">
              MON TALENT
            </span>
            <span className="text-text-tertiary text-[10px] font-medium uppercase tracking-wider">
              Administration
            </span>
          </div>
        </Link>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {navItems.map((section) => (
          <div key={section.section}>
        
            <p className="px-3 text-[11px] font-semibold text-text-tertiary uppercase tracking-wider mb-2 mt-4 first:mt-0">
              {section.section}
            </p>

          
            {section.items.map((item) => {
             
              const isActive = location.pathname === item.path;

              return (
                <Link
                  key={item.label}
                  to={item.path}
                  onClick={onClose} 
                  className={`group flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors duration-150 ${
                    isActive
                      ? 'bg-amber-50 text-brand-orange font-semibold'
                      : 'text-text-secondary hover:bg-surface-variant hover:text-text-primary'
                  }`}
                >
              
                  <Icon
                    icon={item.icon}
                    width="20"
                    style={{
                      color: isActive ? '#FF6F00' : 'currentColor',
                    }}
                  />

            
                  <span className="flex-1 text-sm">{item.label}</span>

               
                  {item.badge && (
                    <span className="bg-brand-orange text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
                      {item.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

     
      <div className="p-3 border-t border-border">
        <Link
          to="/settings"
          onClick={onClose}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-text-secondary hover:bg-surface-variant hover:text-text-primary transition-colors"
        >
          <Icon icon="solar:settings-linear" width="20" />
          <span className="text-sm">Paramètres</span>
        </Link>

        <button
          onClick={() => {
         
            if (confirm('Voulez-vous vraiment vous déconnecter ?')) {
              alert('Déconnexion (à implémenter)');
            }
          }}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-text-secondary hover:bg-rose-50 hover:text-error transition-colors"
        >
          <Icon icon="solar:logout-2-linear" width="20" />
          <span className="text-sm">Déconnexion</span>
        </button>
      </div>
    </aside>
  );
}