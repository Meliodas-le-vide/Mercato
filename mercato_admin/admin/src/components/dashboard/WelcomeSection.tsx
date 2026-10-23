import { useAuth } from '../../contexts/authContexts';
export default function WelcomeSection() {
  const { user } = useAuth();


  const greeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  };

  const firstName = user?.firstname || 'Admin';

  return (
    <div className="flex flex-col md:flex-row md:items-end gap-4 justify-between mb-8">
      <div>
        <h1 className="text-3xl md:text-4xl text-text-primary font-bold tracking-tight mb-2">
          {greeting()}, {firstName}
        </h1>
        <p className="text-text-secondary">
          Voici ce qui se passe sur Mon Talent aujourd'hui.
        </p>
      </div>

    </div>
  );
}