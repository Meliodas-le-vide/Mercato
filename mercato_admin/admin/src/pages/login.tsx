// src/pages/Login.tsx
import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';

import { getErrorMessage } from '../api/client';
import { useAuth } from '../contexts/authContexts';

export default function Login() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);
    try {
      await login(email, password);
      navigate('/');
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-md">
        <div className="flex flex-col items-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-linear-to-br from-brand-yellow to-brand-orange flex items-center justify-center text-white font-bold text-2xl shadow-lg mb-4">
            MT
          </div>
          <h1 className="text-2xl font-bold text-text-primary">Mon Talent Admin</h1>
          <p className="text-text-secondary text-sm mt-1">Connecte-toi pour continuer</p>
        </div>

        <form
          onSubmit={handleSubmit}
          className="bg-surface border border-border rounded-2xl p-8 shadow-card"
        >
          {error && (
            <div className="bg-rose-50 border border-rose-200 text-rose-700 rounded-lg p-3 mb-6 text-sm">
              {error}
            </div>
          )}

          <div className="mb-4">
            <label className="block text-xs font-semibold text-text-secondary mb-2">
              Adresse email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@montalent.com"
              required
              className="w-full px-4 py-3 rounded-lg bg-surface-variant border border-border focus:border-brand-orange focus:outline-none text-text-primary text-sm"
            />
          </div>

          <div className="mb-6">
            <label className="block text-xs font-semibold text-text-secondary mb-2">
              Mot de passe
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              className="w-full px-4 py-3 rounded-lg bg-surface-variant border border-border focus:border-brand-orange focus:outline-none text-text-primary text-sm"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-brand-orange text-white font-semibold py-3 rounded-lg hover:shadow-lg hover:shadow-brand-orange/30 disabled:opacity-50 transition-all"
          >
            {isLoading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  );
}