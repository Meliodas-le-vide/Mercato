
import type { ReactNode } from 'react';

export interface Column<T> {
  key: string;                      
  label: string;                     
  align?: 'left' | 'right' | 'center';
  render?: (item: T) => ReactNode;    
  className?: string;                 
}

interface DataTableProps<T> {
  columns: Column<T>[];               
  data: T[];                          
  keyExtractor: (item: T) => string | number;   
}

export default function DataTable<T>({
  columns,
  data,
  keyExtractor,
}: DataTableProps<T>) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-left border-collapse">

        <thead>
          <tr className="bg-surface-variant border-b border-border">
            {columns.map((col) => (
              <th
                key={col.key}
                className={`px-6 py-4 text-xs uppercase tracking-wider text-text-tertiary font-semibold ${
                  col.align === 'right'
                    ? 'text-right'
                    : col.align === 'center'
                    ? 'text-center'
                    : 'text-left'
                }`}
              >
                {col.label}
              </th>
            ))}
          </tr>
        </thead>

        <tbody>
          {data.map((item, index) => (
            <tr
              key={keyExtractor(item)}
              className={`group hover:bg-surface-variant transition-colors ${
                index < data.length - 1 ? 'border-b border-border' : ''
              }`}
            >
              {columns.map((col) => (
                <td
                  key={col.key}
                  className={`px-6 py-4 text-sm ${
                    col.align === 'right'
                      ? 'text-right'
                      : col.align === 'center'
                      ? 'text-center'
                      : 'text-left'
                  } ${col.className || ''}`}
                >
                  {col.render
                    ? col.render(item)
                    : (item as any)[col.key] ?? '—'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}