import { Icon } from '@iconify-icon/react';
import type { ReactNode, MouseEvent } from 'react';

type ButtonVariant = 'primary' | 'outline' | 'ghost' | 'danger';

interface ButtonProps {
  children: ReactNode;           
  icon?: string;                  
  variant?: ButtonVariant;         
  onClick?: () => void;            
  disabled?: boolean;             
  type?: 'button' | 'submit';      
  className?: string;             
}

export default function Button({
  children,
  icon,
  variant = 'primary',
  onClick,
  disabled = false,
  type = 'button',
  className = '',
}: ButtonProps) {

  const base =
    'inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed';

  const variants: Record<ButtonVariant, string> = {
    primary:
      'bg-brand-orange text-white shadow-md shadow-brand-orange/30 hover:shadow-lg hover:shadow-brand-orange/40 hover:-translate-y-0.5',
    outline:
      'border border-border text-text-secondary hover:bg-white hover:shadow-sm hover:border-brand-orange/30 hover:text-brand-orange',
    ghost:
      'text-text-secondary hover:bg-surface-variant hover:text-text-primary',
    danger:
      'bg-error text-white shadow-md shadow-error/30 hover:shadow-lg hover:shadow-error/40',
  };

  const handleClick = (e: MouseEvent<HTMLButtonElement>) => {
    if (disabled) {
      e.preventDefault();
      return;
    }
    onClick?.();
  };

  return (
    <button
      type={type}
      onClick={handleClick}
      disabled={disabled}
      className={`${base} ${variants[variant]} ${className}`}
    >
      {icon && <Icon icon={icon} width="18" />}
      <span>{children}</span>
    </button>
  );
}