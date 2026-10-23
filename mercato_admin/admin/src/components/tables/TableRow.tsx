import type { ReactNode } from 'react';

interface TableRowProps {
  children: ReactNode;   
  isLast?: boolean;     
}

export default function TableRow({ children, isLast = false }: TableRowProps) {
  return (
    <tr
      className={`group hover:bg-surface-variant transition-colors ${
        !isLast ? 'border-b border-border' : ''
      }`}
    >
      {children}
    </tr>
  );
}

interface TableCellProps {
  children: ReactNode;
  align?: 'left' | 'right' | 'center';  
  className?: string;
}

export function TableCell({
  children,
  align = 'left',
  className = '',
}: TableCellProps) {
  const alignment = {
    left: 'text-left',
    right: 'text-right',
    center: 'text-center',
  }[align];

  return (
    <td className={`px-6 py-4 text-sm text-text-primary ${alignment} ${className}`}>
      {children}
    </td>
  );
}