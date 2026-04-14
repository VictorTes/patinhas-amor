import { Link, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';
import logoOng from '../assets/logo.png';

export function Header() {
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isDonationModalOpen, setIsDonationModalOpen] = useState(false); // Estado para o Pop-up
  const [, setIsMobile] = useState(false);

  // Detectar se é mobile
  useEffect(() => {
    const checkIsMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    checkIsMobile();
    window.addEventListener('resize', checkIsMobile);
    return () => window.removeEventListener('resize', checkIsMobile);
  }, []);

  // Fechar menu ao mudar de rota
  useEffect(() => {
    setIsMenuOpen(false);
  }, [location]);

  // Bloquear scroll quando menu estiver aberto
  useEffect(() => {
    if (isMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMenuOpen]);

  const navLinks = [
    { path: '/', label: 'Home', icon: '🏠' },
    { path: '/adocao', label: 'Adoção', icon: '🐾' },
    { path: '/desaparecidos', label: 'Desaparecidos', icon: '🔍' },
    { path: '/registrar-ocorrencia', label: 'Registrar Ocorrência', icon: '🚨' },
    { path: '/sobre', label: 'Sobre', icon: 'ℹ️' },
  ];

  return (
    <>
      <header className="bg-white border-b border-slate-100 sticky top-0 z-50 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-2 group">
              <img
                src={logoOng}
                alt="Logo Patinhas e Amor"
                className="w-20 h-20 object-contain transition-transform group-hover:scale-105"
              />
              <div className="hidden sm:block">
                <span className="text-xl font-bold bg-gradient-to-r from-orange-500 to-orange-700 bg-clip-text text-transparent">
                  Patinhas e Amor
                </span>
              </div>
            </Link>

            {/* Navegação Desktop */}
            <nav className="hidden lg:flex items-center gap-1">
              {navLinks.map((link) => {
                const isActive = location.pathname === link.path;
                return (
                  <Link
                    key={link.path}
                    to={link.path}
                    className={`
                      relative px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200
                      ${isActive
                        ? 'text-orange-600 bg-orange-50'
                        : 'text-slate-600 hover:text-orange-500 hover:bg-slate-50'
                      }
                    `}
                  >
                    {link.label}
                    {isActive && (
                      <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-1 h-1 bg-orange-500 rounded-full" />
                    )}
                  </Link>
                );
              })}
            </nav>

            {/* Ações (Desktop) */}
            <div className="hidden md:flex items-center gap-3">
              {/* Botão Doar - Abre Pop-up */}
              <button
                onClick={() => setIsDonationModalOpen(true)}
                className="flex items-center gap-2 px-4 py-2.5 text-sm font-bold text-orange-600 border-2 border-orange-500 rounded-full hover:bg-orange-50 transition-all duration-200"
              >
                <span>❤️ Doar</span>
              </button>

              <Link
                to="/adocao"
                className="flex items-center gap-2 bg-gradient-to-r from-orange-500 to-orange-600 text-white px-5 py-2.5 rounded-full font-semibold shadow-lg shadow-orange-200 hover:shadow-xl hover:shadow-orange-300 hover:-translate-y-0.5 transition-all duration-200"
              >
                <span>Adotar</span>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                </svg>
              </Link>
            </div>

            {/* Menu Burger (Mobile) */}
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="md:hidden w-12 h-12 flex items-center justify-center rounded-xl hover:bg-slate-100 transition-colors"
              aria-label={isMenuOpen ? 'Fechar menu' : 'Abrir menu'}
            >
              <div className="relative w-6 h-5">
                <span className={`absolute left-0 w-6 h-0.5 bg-slate-700 transition-all duration-300 ${isMenuOpen ? 'top-2.5 rotate-45' : 'top-0'}`} />
                <span className={`absolute left-0 top-2 w-6 h-0.5 bg-slate-700 transition-all duration-300 ${isMenuOpen ? 'opacity-0' : 'opacity-100'}`} />
                <span className={`absolute left-0 w-6 h-0.5 bg-slate-700 transition-all duration-300 ${isMenuOpen ? 'top-2.5 -rotate-45' : 'top-4'}`} />
              </div>
            </button>
          </div>
        </div>
      </header>

      {/* Overlay Mobile Menu */}
      <div className={`fixed inset-0 z-40 md:hidden transition-all duration-300 ${isMenuOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}>
        <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setIsMenuOpen(false)} />

        <div className={`absolute right-0 top-0 h-full w-80 max-w-full bg-white shadow-2xl transform transition-transform duration-300 ease-out ${isMenuOpen ? 'translate-x-0' : 'translate-x-full'}`}>
          <div className="flex flex-col h-full">
            <div className="flex items-center justify-between p-4 border-b border-slate-100">
              <span className="text-lg font-bold text-slate-800">Menu</span>
              <button onClick={() => setIsMenuOpen(false)} className="w-10 h-10 flex items-center justify-center rounded-xl hover:bg-slate-100">
                <svg className="w-6 h-6 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <nav className="flex-1 overflow-y-auto py-4">
              <div className="px-4 space-y-2">
                {navLinks.map((link) => (
                  <Link
                    key={link.path}
                    to={link.path}
                    onClick={() => setIsMenuOpen(false)}
                    className={`flex items-center gap-4 px-4 py-4 rounded-xl text-lg font-medium ${(location.pathname === link.path) ? 'bg-orange-50 text-orange-600 border-2 border-orange-200' : 'text-slate-700 hover:bg-slate-50 border-2 border-transparent'}`}
                  >
                    <span className="text-2xl">{link.icon}</span>
                    <span>{link.label}</span>
                  </Link>
                ))}
                {/* Opção Doar dentro da lista Mobile */}
                <button
                  onClick={() => { setIsMenuOpen(false); setIsDonationModalOpen(true); }}
                  className="flex items-center gap-4 px-4 py-4 rounded-xl text-lg font-medium text-slate-700 hover:bg-slate-50 w-full text-left"
                >
                  <span className="text-2xl">❤️</span>
                  <span>Fazer Doação</span>
                </button>
              </div>
            </nav>

            <div className="p-4 border-t border-slate-100 space-y-3">
              <Link
                to="/adocao"
                onClick={() => setIsMenuOpen(false)}
                className="flex items-center justify-center gap-2 w-full bg-gradient-to-r from-orange-500 to-orange-600 text-white py-4 rounded-xl font-bold text-lg shadow-lg"
              >
                <span>🐾 Quero Adotar</span>
              </Link>
              <p className="text-center text-slate-500 text-sm">ONG Patinhas e Amor © 2026</p>
            </div>
          </div>
        </div>
      </div>

      {/* Exemplo Simples de Modal de Doação (Pop-up) */}
      {isDonationModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" onClick={() => setIsDonationModalOpen(false)} />
          <div className="relative bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl text-center">
            <button onClick={() => setIsDonationModalOpen(false)} className="absolute top-4 right-4 text-slate-400 hover:text-slate-600">
               <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
            <div className="text-4xl mb-4">❤️</div>
            <h2 className="text-2xl font-bold text-slate-800 mb-2">Ajude nossa causa</h2>
            <p className="text-slate-600 mb-6">Escaneie o QR Code abaixo para realizar uma doação via Pix e ajudar nossos resgatados.</p>
            
            {/* Espaço para o QR Code */}
            <div className="bg-slate-100 aspect-square rounded-2xl flex items-center justify-center mb-6 border-2 border-dashed border-slate-300">
               <span className="text-slate-400 font-medium">[QR CODE PIX AQUI]</span>
            </div>

            <button className="w-full bg-slate-100 text-slate-700 py-3 rounded-xl font-semibold hover:bg-slate-200 transition-colors">
              Copiar Chave Pix
            </button>
          </div>
        </div>
      )}
    </>
  );
}