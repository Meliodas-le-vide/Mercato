

import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Filler,
  Tooltip,
  type ChartOptions,
} from 'chart.js';
import { viewsChartData } from '../../data/mockData';


ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Filler,
  Tooltip
);

export default function ViewCharts() {

  const data = {
    labels: viewsChartData.labels,
    datasets: [
      {
        label: 'Vues',
        data: viewsChartData.values,
        borderColor: '#FF6F00',          
        backgroundColor: (context: any) => {
          const chart = context.chart;
          const { ctx, chartArea } = chart;

          if (!chartArea) return 'rgba(255, 111, 0, 0.1)';

          const gradient = ctx.createLinearGradient(
            0, chartArea.top, 0, chartArea.bottom
          );
          gradient.addColorStop(0, 'rgba(255, 111, 0, 0.25)');
          gradient.addColorStop(1, 'rgba(255, 111, 0, 0)');
          return gradient;
        },
        borderWidth: 2,
        pointBackgroundColor: '#FFFFFF',
        pointBorderColor: '#FF6F00',
        pointBorderWidth: 2,
        pointRadius: 4,
        pointHoverRadius: 6,
        fill: true,
        tension: 0.4,   
      },
    ],
  };

  const options: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },   
      tooltip: {
        backgroundColor: '#FFFFFF',
        titleColor: '#111827',
        bodyColor: '#6B7280',
        borderColor: '#E5E7EB',
        borderWidth: 1,
        padding: 12,
        displayColors: false,
        callbacks: {
          label: (context) => {
            const value = context.parsed.y;
            return `${value.toLocaleString('fr-FR')} vues`;
          },
        },
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        grid: {
          color: '#F3F4F6',
          borderDash: [4, 4],
        },
        ticks: {
          color: '#9CA3AF',
          callback: (value) => `${Number(value) / 1000}k`,
        },
      },
      x: {
        grid: { display: false },
        ticks: { color: '#9CA3AF' },
      },
    },
  };

  return (
    <div className="h-64 w-full">
      <Line data={data} options={options} />
    </div>
  );
}