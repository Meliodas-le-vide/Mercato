// src/pages/Dashboard.tsx
import Layout from '../components/layout/Layout';
import WelcomeSection from '../components/dashboard/WelcomeSection';
import StatsGrid from '../components/dashboard/StatsGrid';
import ChartsSection from '../components/dashboard/ChartsSection';

export default function Dashboard() {
  return (
    <Layout>
      <WelcomeSection />
      <StatsGrid />
      <ChartsSection />
    </Layout>
  );
}