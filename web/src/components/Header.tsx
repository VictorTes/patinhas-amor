import { Link, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';
import logoOng from '../assets/logo.png';

export function Header() {
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
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
            <nav className="hidden md:flex items-center gap-1">
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

            {/* Botão de ação CTA (Desktop) */}
            <Link
              to="/adocao"
              className="hidden md:flex items-center gap-2 bg-gradient-to-r from-orange-500 to-orange-600 text-white px-5 py-2.5 rounded-full font-semibold shadow-lg shadow-orange-200 hover:shadow-xl hover:shadow-orange-300 hover:-translate-y-0.5 transition-all duration-200"
            >
              <span>Adotar</span>
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
            </Link>

            {/* Menu Burger (Mobile) */}
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="md:hidden w-12 h-12 flex items-center justify-center rounded-xl hover:bg-slate-100 transition-colors"
              aria-label={isMenuOpen ? 'Fechar menu' : 'Abrir menu'}
            >
              <div className="relative w-6 h-5">
                <span
                  className={`absolute left-0 w-6 h-0.5 bg-slate-700 transition-all duration-300 ${isMenuOpen ? 'top-2.5 rotate-45' : 'top-0'
                    }`}
                />
                <span
                  className={`absolute left-0 top-2 w-6 h-0.5 bg-slate-700 transition-all duration-300 ${isMenuOpen ? 'opacity-0' : 'opacity-100'
                    }`}
                />
                <span
                  className={`absolute left-0 w-6 h-0.5 bg-slate-700 transition-all duration-300 ${isMenuOpen ? 'top-2.5 -rotate-45' : 'top-4'
                    }`}
                />
              </div>
            </button>
          </div>
        </div>
      </header>

      {/* Overlay Mobile Menu */}
      <div
        className={`fixed inset-0 z-40 md:hidden transition-all duration-300 ${isMenuOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
          }`}
      >
        {/* Backdrop escuro */}
        <div
          className="absolute inset-0 bg-black/50 backdrop-blur-sm"
          onClick={() => setIsMenuOpen(false)}
        />

        {/* Menu lateral */}
        <div
          className={`absolute right-0 top-0 h-full w-80 max-w-full bg-white shadow-2xl transform transition-transform duration-300 ease-out ${isMenuOpen ? 'translate-x-0' : 'translate-x-full'
            }`}
        >
          <div className="flex flex-col h-full">
            {/* Header do menu */}
            <div className="flex items-center justify-between p-4 border-b border-slate-100">
              <span className="text-lg font-bold text-slate-800">Menu</span>
              <button
                onClick={() => setIsMenuOpen(false)}
                className="w-10 h-10 flex items-center justify-center rounded-xl hover:bg-slate-100 transition-colors"
                aria-label="Fechar menu"
              >
                <svg className="w-6 h-6 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Links de navegação */}
            <nav className="flex-1 overflow-y-auto py-4">
              <div className="px-4 space-y-2">
                {navLinks.map((link) => {
                  const isActive = location.pathname === link.path;
                  return (
                    <Link
                      key={link.path}
                      to={link.path}
                      onClick={() => setIsMenuOpen(false)}
                      className={`
                        flex items-center gap-4 px-4 py-4 rounded-xl text-lg font-medium transition-all duration-200
                        ${isActive
                          ? 'bg-orange-50 text-orange-600 border-2 border-orange-200'
                          : 'text-slate-700 hover:bg-slate-50 border-2 border-transparent'
                        }
                      `}
                    >
                      <span className="text-2xl">{link.icon}</span>
                      <span>{link.label}</span>
                      {isActive && (
                        <span className="ml-auto w-2 h-2 bg-orange-500 rounded-full" />
                      )}
                    </Link>
                  );
                })}
              </div>
            </nav>

            {/* Footer do menu com CTA */}
            <div className="p-4 border-t border-slate-100">
              <Link
                to="/adocao"
                onClick={() => setIsMenuOpen(false)}
                className="flex items-center justify-center gap-2 w-full bg-gradient-to-r from-orange-500 to-orange-600 text-white py-4 rounded-xl font-bold text-lg shadow-lg shadow-orange-200"
              >
                <span>🐾 Quero Adotar</span>
              </Link>
              <p className="text-center text-slate-500 text-sm mt-4">
                ONG Patinhas e Amor © 2025
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
