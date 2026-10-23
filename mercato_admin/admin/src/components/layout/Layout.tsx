
import Header from './Header';
import MobileOverlay from './MobileOverlay';
import { useSidebar } from '../../hooks/useSidebar';
import Sidebar from './sidebar';
import type { ReactNode } from 'react';


interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {

  const { isOpen, toggle, close } = useSidebar();

  return (
    <div className="flex h-screen overflow-hidden bg-background">

      <Sidebar isOpen={isOpen} onClose={close} />

      <MobileOverlay isOpen={isOpen} onClick={close} />

      <main className="flex-1 flex flex-col overflow-y-auto overflow-x-hidden">
    
        <Header onMenuClick={toggle} />
        <div className="flex-1 w-full max-w-7xl mx-auto px-6 py-6 space-y-6">
          {children}
        </div>
      </main>
    </div>
  );
}