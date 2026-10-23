
export const navItems = [
  {
    section: 'Administration',
    items: [
      { label: 'Tableau de bord', icon: 'solar:widget-5-linear', path: '/', active: true },
      { label: 'Utilisateurs', icon: 'solar:users-group-rounded-linear', path: '/users' },
      { label: 'Joueurs', icon: 'solar:football-linear', path: '/players' },
      { label: 'Recruteurs', icon: 'solar:user-check-rounded-linear', path: '/recruiters', badge: 3 },
    ],
  },
  {
    section: 'Contenu',
    items: [
      { label: 'Vidéos', icon: 'solar:videocamera-record-linear', path: '/videos' },
      { label: 'Événements', icon: 'solar:calendar-linear', path: '/events' },
      { label: 'Signalements', icon: 'solar:danger-triangle-linear', path: '/reports', badge: 12 },
    ],
  },
];

export const stats = [
  {
    id: 'players',
    icon: 'solar:football-linear',
    iconBg: 'bg-amber-50',
    iconColor: 'text-brand-yellow',
    label: 'Joueurs inscrits',
    value: '1,254',
    change: '+12.5%',
    positive: true,
  },
  {
    id: 'videos',
    icon: 'solar:videocamera-record-linear',
    iconBg: 'bg-orange-50',
    iconColor: 'text-brand-orange',
    label: 'Vidéos publiées',
    value: '3,842',
    change: '+8.4%',
    positive: true,
  },
  {
    id: 'reports',
    icon: 'solar:danger-triangle-linear',
    iconBg: 'bg-rose-50',
    iconColor: 'text-error',
    label: 'Signalements',
    value: '12',
    change: '-2.1%',
    positive: false,
  },
  {
    id: 'recruiters',
    icon: 'solar:user-check-rounded-linear',
    iconBg: 'bg-sky-50',
    iconColor: 'text-info',
    label: 'Recruteurs',
    value: '87',
    change: '+5.2%',
    positive: true,
  },
];


export const recentPlayers = [
  { id: 1, name: 'Jean Dupont', initials: 'JD', avatarColor: 'bg-amber-100 text-amber-700', position: 'Attaquant', club: 'Paris SG', date: '24 Oct 2025', status: 'Actif' },
  { id: 2, name: 'Marie Martin', initials: 'MM', avatarColor: 'bg-orange-100 text-orange-700', position: 'Milieu', club: 'Lyon OL', date: '23 Oct 2025', status: 'KYC en attente' },
  { id: 3, name: 'Paul Durand', initials: 'PD', avatarColor: 'bg-sky-100 text-sky-700', position: 'Défenseur', club: 'Marseille OM', date: '22 Oct 2025', status: 'Actif' },
  { id: 4, name: 'Sophie Bernard', initials: 'SB', avatarColor: 'bg-purple-100 text-purple-700', position: 'Gardien', club: 'Lille LOSC', date: '21 Oct 2025', status: 'Actif' },
];


export const recentVideos = [
  { id: 1, title: 'Compilation buts — Saison 2025', author: 'Jean Dupont', authorInitials: 'JD', authorColor: 'bg-amber-100 text-amber-700', views: 12450, likes: 842, comments: 42, date: '24 Oct 2025', status: 'Publiée' },
  { id: 2, title: 'Match U19 — Résumé complet', author: 'Marie Martin', authorInitials: 'MM', authorColor: 'bg-orange-100 text-orange-700', views: 8720, likes: 512, comments: 28, date: '23 Oct 2025', status: 'Publiée' },
  { id: 3, title: 'Analyse tactique — Défense en ligne', author: 'Paul Durand', authorInitials: 'PD', authorColor: 'bg-sky-100 text-sky-700', views: 5210, likes: 287, comments: 15, date: '22 Oct 2025', status: 'En attente' },
];

export const reports = [
  { id: 1, reporter: 'Jean Dupont', reporterInitials: 'JD', reporterColor: 'bg-amber-100 text-amber-700', target: 'Compte @fake_user', reason: 'Faux profil', date: '24 Oct 2025', priority: 'Haute' },
  { id: 2, reporter: 'Marie Martin', reporterInitials: 'MM', reporterColor: 'bg-orange-100 text-orange-700', target: 'Vidéo #3842', reason: 'Contenu inapproprié', date: '23 Oct 2025', priority: 'Moyenne' },
  { id: 3, reporter: 'Paul Durand', reporterInitials: 'PD', reporterColor: 'bg-sky-100 text-sky-700', target: 'Commentaire #921', reason: 'Spam', date: '23 Oct 2025', priority: 'Basse' },
];


export const recruiterKyc = [
  { id: 1, name: 'Sophie Martin', initials: 'SM', avatarColor: 'bg-amber-100 text-amber-700', organization: 'FC Abidjan Scouting', organizationType: 'Cabinet de scouting', license: '12345-FIFA-2025', date: '24 Oct 2025', status: 'En attente' },
  { id: 2, name: 'Marc Petit', initials: 'MP', avatarColor: 'bg-orange-100 text-orange-700', organization: 'ASEC Mimosas', organizationType: 'Club professionnel', license: '67890-SIRET-2025', date: '23 Oct 2025', status: 'En attente' },
  { id: 3, name: 'Claire Dubois', initials: 'CD', avatarColor: 'bg-sky-100 text-sky-700', organization: 'Africa Talent Agency', organizationType: 'Agence de joueurs', license: '11223-RCS-2025', date: '22 Oct 2025', status: 'En attente' },
];


export const upcomingEvents = [
  { id: 1, title: 'Essai détection U19', organizer: 'FC Abidjan Scouting', location: 'Stade Félix Houphouët-Boigny', city: 'Abidjan', date: '15 Nov 2025', time: '14:30', day: '15', month: 'NOV' },
  { id: 2, title: 'Tournoi régional U17', organizer: 'ASEC Mimosas', location: 'Stade Robert Champroux', city: 'Abidjan', date: '22 Nov 2025', time: '09:00', day: '22', month: 'NOV' },
  { id: 3, title: 'Match amical professionnel', organizer: 'Stella Club', location: 'Stade de la Paix', city: 'Bouaké', date: '03 Dec 2025', time: '16:00', day: '03', month: 'DÉC' },
];


export const viewsChartData = {
  labels: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct'],
  values: [12500, 15200, 14800, 22000, 24500, 30000, 28500, 35000, 38500, 42000],
};


export const currentUser = {
  name: 'Admin Mon Talent',
  firstName: 'Admin',
  initials: 'AM',
  role: 'Super Admin',
  email: 'admin@montalent.com',
  avatar: 'https://avatars.githubusercontent.com/u/152723454?w=800&q=80',
};