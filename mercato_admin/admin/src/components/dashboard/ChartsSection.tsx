
import SectionTitle from '../ui/SectionTitle';
import ViewCharts from '../ui/ViewCharts';


export default function ChartsSection() {
  return (
    <div className="bg-surface rounded-2xl p-6 border border-border shadow-card mb-8">
      <SectionTitle
        title="Vues de vidéos"
        subtitle="Croissance mensuelle"
      />
      <ViewCharts />
    </div>
  );
}