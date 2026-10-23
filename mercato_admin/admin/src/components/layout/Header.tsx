// src/components/layout/Header.tsx
import { Icon } from '@iconify-icon/react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/authContexts';


interface HeaderProps {
  onMenuClick: () => void;
}

export default function Header({ onMenuClick }: HeaderProps) {
  const navigate = useNavigate();
  const { user, logout } = useAuth();


  const handleLogout = async () => {
    if (!confirm('Voulez-vous vraiment vous déconnecter ?')) return;
    await logout();
    navigate('/login');
  };


  const initials = user
    ? `${user.firstname?.[0] ?? ''}${user.lastname?.[0] ?? ''}`.toUpperCase()
    : 'AD';

  return (
    <header className="sticky top-0 z-30 h-16 flex glass items-center justify-between px-6">

      <div className="flex items-center gap-4">
        <button
          onClick={onMenuClick}
          className="md:hidden text-text-secondary hover:text-brand-orange transition-colors p-1"
          aria-label="Ouvrir le menu"
        >
          <Icon icon="solar:hamburger-menu-linear" width="24" />
        </button>

        <nav className="hidden sm:flex items-center text-sm font-medium text-text-tertiary">
          <span className="hover:text-brand-orange cursor-pointer transition-colors">
            Tableau de bord
          </span>
          <Icon icon="solar:alt-arrow-right-linear" className="mx-2 text-xs" />
          <span className="text-brand-orange">Aperçu</span>
        </nav>
      </div>

   
      <div className="flex items-center gap-3 md:gap-5">
    
        <div className="hidden md:flex items-center w-64 rounded-full bg-surface-variant px-4 py-2 border border-transparent focus-within:border-brand-orange/30 focus-within:bg-surface focus-within:shadow-sm transition-all">
          <Icon
            icon="solar:magnifer-linear"
            className="text-text-tertiary mr-2"
            width="18"
          />
          <input
            type="text"
            placeholder="Rechercher..."
            className="bg-transparent border-none outline-none text-sm text-text-primary w-full placeholder-text-tertiary"
          />
        </div>

   
        <button
          className="relative text-text-secondary hover:text-brand-orange transition-colors p-2 rounded-full hover:bg-amber-50"
          aria-label="Notifications"
        >
          <Icon icon="solar:bell-linear" width="22" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full border-2 border-surface" />
        </button>

        <div className="flex items-center gap-3 pl-4 border-l border-border">
     
          <div className="text-right hidden md:block">
            <p className="text-sm font-semibold text-text-primary">
              {user ? `${user.firstname} ${user.lastname}` : 'Administrateur'}
            </p>
            <p className="text-xs text-text-tertiary">
              {user?.role === 'ADMIN' ? 'Super Admin' : user?.role || 'Admin'}
            </p>
          </div>

  
          <div className="w-10 h-10 rounded-full bg-linear-to-tr from-brand-yellow to-brand-orange p-0.5">
            {user?.Profile_image ? (
              <img
                src={user.Profile_image}
                alt={`${user.firstname} ${user.lastname}`}
                className="w-full h-full object-cover border-2 border-white rounded-full"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center bg-brand-orange text-white font-bold text-sm rounded-full border-2 border-white">
                {initials}
              </div>
            )}
          </div>
          <button
            onClick={handleLogout}
            className="text-text-tertiary hover:text-error transition-colors p-2 rounded-lg hover:bg-rose-50"
            title="Se déconnecter"
            aria-label="Se déconnecter"
          >
            <Icon icon="solar:logout-2-linear" width="20" />
          </button>
        </div>
      </div>
    </header>
  );
}