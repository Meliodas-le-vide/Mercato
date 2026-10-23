

import { useState, useCallback, useEffect } from 'react';


interface UseSidebarReturn {
  isOpen: boolean;
  toggle: () => void;
  close: () => void;
}

export function useSidebar(): UseSidebarReturn {
  const [isOpen, setIsOpen] = useState<boolean>(false);

  const toggle = useCallback(() => setIsOpen((prev) => !prev), []);
  const close = useCallback(() => setIsOpen(false), []);

  useEffect(() => {
    document.body.style.overflow = isOpen ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  return { isOpen, toggle, close };
}