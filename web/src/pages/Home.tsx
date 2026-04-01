import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { AnimalGrid } from '../components/AnimalGrid';
import { FadeIn } from '../components/FadeIn';
import { getAnimalsByStatus } from '../services/firebaseService';
import type { Animal } from '../types';

export function Home() {
  const [availableAnimals, setAvailableAnimals] = useState<Animal[]>([]);
  const [missingAnimals, setMissingAnimals] = useState<Animal[]>([]);
  const [loadingAvailable, setLoadingAvailable] = useState(true);
  const [loadingMissing, setLoadingMissing] = useState(true);

  useEffect(() => {
    async function fetchAnimals() {
      try {
        const available = await getAnimalsByStatus('available_for_adoption');
        // Limita a 4 animais na Home
        setAvailableAnimals(available.slice(0, 4));
      } catch (error) {
        console.error('[Home] Erro ao buscar disponíveis:', error);
      } finally {
        setLoadingAvailable(false);
      }

      try {
        const missing = await getAnimalsByStatus('missing');
        // Limita a no máximo 4 cards de desaparecidos
        setMissingAnimals(missing.slice(0, 4));
      } catch (error) {
        console.error('[Home] Erro ao buscar desaparecidos:', error);
      } finally {
        setLoadingMissing(false);
      }
    }
    fetchAnimals();
  }, []);

  const hasMissingAnimals = missingAnimals.length > 0;

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-orange-400 via-orange-500 to-orange-600" />

        <div className="absolute inset-0 opacity-10">
          <motion.div 
            animate={{ y: [0, 20, 0], x: [0, 10, 0] }}
            transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
            className="absolute top-0 left-0 w-96 h-96 bg-white rounded-full -translate-x-1/2 -translate-y-1/2" 
          />
          <motion.div 
            animate={{ y: [0, -30, 0], x: [0, -15, 0] }}
            transition={{ duration: 10, repeat: Infinity, ease: "easeInOut" }}
            className="absolute bottom-0 right-0 w-64 h-64 bg-white rounded-full translate-x-1/3 translate-y-1/3" 
          />
        </div>

        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-28">
          <div className="text-center max-w-3xl mx-auto">
            <FadeIn direction="down">
              <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm text-white px-4 py-2 rounded-full text-sm font-medium mb-6">
                <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                ONG ativa desde 2020
              </div>
            </FadeIn>

            <FadeIn direction="up" delay={0.2}>
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 leading-tight">
                Encontre seu novo
                <span className="block">
                  <span className="text-yellow-200">melhor amigo</span> 🐾
                </span>
              </h1>
            </FadeIn>

            <FadeIn direction="up" delay={0.4}>
              <p className="text-lg md:text-xl text-white/90 mb-10 max-w-2xl mx-auto">
                Resgatamos, cuidamos e encontramos lares amorosos para animais
                abandonados. Cada adoção é uma nova história de amor.
              </p>
            </FadeIn>

            <FadeIn direction="up" delay={0.6}>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link
                  to="/adocao"
                  className="inline-flex items-center justify-center gap-2 bg-white text-orange-600 px-8 py-4 rounded-full font-bold text-lg shadow-xl hover:shadow-2xl hover:scale-105 transition-all duration-200"
                >
                  Quero Adotar
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </Link>

                <Link
                  to="/registrar-ocorrencia"
                  className="inline-flex items-center justify-center gap-2 bg-orange-700/50 backdrop-blur-sm text-white border border-white/30 px-8 py-4 rounded-full font-semibold text-lg hover:bg-orange-700/70 hover:scale-105 transition-all duration-200"
                >
                  🚨 Registrar ocorrência
                </Link>
              </div>
            </FadeIn>
          </div>
        </div>
      </section>

      {/* Seção de Adoção */}
      <section className="py-16 lg:py-24 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-12">
            <FadeIn direction="right">
              <div>
                <div className="inline-flex items-center gap-2 text-orange-600 font-medium text-sm mb-3">
                  <span className="w-8 h-px bg-orange-500" />
                  Adoção
                </div>
                <h2 className="text-3xl md:text-4xl font-bold text-slate-800 mb-3">
                  Eles precisam de um lar 💕
                </h2>
                <p className="text-slate-600 text-lg max-w-xl">
                  Conheça nossos amiguinhos que estão esperando por uma família amorosa
                </p>
              </div>
            </FadeIn>

            <FadeIn direction="left" delay={0.2}>
              <Link
                to="/adocao"
                className="hidden sm:inline-flex items-center gap-2 text-orange-600 font-semibold hover:text-orange-700 group"
              >
                Ver todos os animais
                <svg className="w-5 h-5 transition-transform group-hover:translate-x-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </Link>
            </FadeIn>
          </div>

          {loadingAvailable ? (
            <div className="flex items-center justify-center py-16">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
            </div>
          ) : (
            <>
              <FadeIn delay={0.4}>
                <AnimalGrid
                  animals={availableAnimals}
                  emptyMessage="Nenhum animal disponível para adoção no momento."
                  columns={4}
                />
              </FadeIn>
              {/* Botão Mobile para Adoção */}
              <div className="mt-8 block md:hidden">
                <Link
                  to="/adocao"
                  className="flex items-center justify-center w-full bg-white border-2 border-orange-100 text-orange-600 py-4 rounded-2xl font-bold shadow-sm"
                >
                  Ver todos os animais →
                </Link>
              </div>
            </>
          )}
        </div>
      </section>

      {/* Seção de Desaparecidos */}
      {(hasMissingAnimals || loadingMissing) && (
        <section className="py-16 lg:py-24 bg-gradient-to-b from-red-50 to-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <FadeIn direction="up">
              <div className="bg-red-500 text-white rounded-2xl p-6 md:p-8 mb-10 shadow-lg shadow-red-200">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                  <div className="flex items-start md:items-center gap-4">
                    <motion.div 
                      animate={{ rotate: [0, -10, 10, 0] }}
                      transition={{ duration: 2, repeat: Infinity }}
                      className="w-14 h-14 bg-white/20 rounded-xl flex items-center justify-center flex-shrink-0"
                    >
                      <span className="text-3xl">⚠️</span>
                    </motion.div>
                    <div>
                      <h2 className="text-2xl md:text-3xl font-bold mb-1">Nos ajude a encontrá-los</h2>
                      <p className="text-red-100">Esses animais estão desaparecidos e precisam voltar para casa</p>
                    </div>
                  </div>
                  <Link
                    to="/desaparecidos"
                    className="hidden md:inline-flex items-center justify-center gap-2 bg-white text-red-600 px-6 py-3 rounded-xl font-semibold hover:bg-red-50 transition-colors"
                  >
                    Ver todos
                  </Link>
                </div>
              </div>
            </FadeIn>

            {loadingMissing ? (
              <div className="flex items-center justify-center py-16">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-500" />
              </div>
            ) : (
              <>
                <FadeIn delay={0.3}>
                  <AnimalGrid
                    animals={missingAnimals}
                    variant="urgent"
                    emptyMessage="Nenhum animal desaparecido no momento."
                    columns={4}
                  />
                </FadeIn>

                {/* Botão Mobile para Desaparecidos */}
                <div className="mt-8 block md:hidden">
                  <Link
                    to="/desaparecidos"
                    className="flex items-center justify-center w-full bg-red-600 text-white py-4 rounded-2xl font-bold shadow-lg shadow-red-100"
                  >
                    Ver todos os desaparecidos →
                  </Link>
                </div>
              </>
            )}
          </div>
        </section>
      )}

      {/* Seção Como Ajudar */}
      <section className="py-16 lg:py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <FadeIn direction="up">
            <div className="text-center mb-12">
              <div className="inline-flex items-center gap-2 text-orange-600 font-medium text-sm mb-3">
                <span className="w-8 h-px bg-orange-500" />
                Como Ajudar
                <span className="w-8 h-px bg-orange-500" />
              </div>
              <h2 className="text-3xl md:text-4xl font-bold text-slate-800 mb-4">Faça parte dessa missão 🤝</h2>
            </div>
          </FadeIn>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8">
            {[
              { icon: '🏠', title: 'Adote', desc: 'Dê um lar amoroso para um animal.', link: '/adocao', color: 'orange' },
              { icon: '🚨', title: 'Ocorrências', desc: 'Avise-nos sobre animais em risco.', link: '/registrar-ocorrencia', color: 'red' },
              { icon: '📢', title: 'Divulgue', desc: 'Compartilhe animais desaparecidos.', link: '/desaparecidos', color: 'blue' },
            ].map((item, index) => (
              <FadeIn key={item.title} delay={index * 0.2} direction="up">
                <div className="group bg-slate-50 rounded-2xl p-8 text-center hover:bg-white hover:shadow-xl transition-all duration-300 border border-transparent hover:border-slate-100">
                  <div className="w-16 h-16 bg-white rounded-2xl flex items-center justify-center mx-auto mb-6 text-3xl shadow-sm group-hover:scale-110 group-hover:rotate-6 transition-transform">
                    {item.icon}
                  </div>
                  <h3 className="text-xl font-bold text-slate-800 mb-3">{item.title}</h3>
                  <p className="text-slate-600 mb-6">{item.desc}</p>
                  <Link to={item.link} className={`font-semibold ${item.color === 'red' ? 'text-red-600' : item.color === 'blue' ? 'text-blue-600' : 'text-orange-600'}`}>
                    Saber mais →
                  </Link>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>

      <footer className="bg-slate-900 text-slate-400 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <FadeIn direction="up">
            <div className="flex items-center justify-center gap-2 mb-4">
              <span className="text-2xl">🐾</span>
              <span className="text-xl font-bold text-white">Patinhas e Amor</span>
            </div>
            <p className="text-sm">ONG dedicada ao resgate e adoção de animais abandonados.</p>
            <p className="text-sm mt-2">© 2026 Patinhas e Amor. Porto União - SC.</p>
          </FadeIn>
        </div>
      </footer>
    </div>
  );
}