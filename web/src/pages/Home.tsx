import { useEffect, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { AnimalGrid } from '../components/AnimalGrid';
import { FadeIn } from '../components/FadeIn';
import { CampaignCard } from '../components/CampaignCard'; // Importando seu novo card
import { getAnimalsByStatus, getCampaigns } from '../services/firebaseService'; // Verifique se getCampaigns existe
import type { Animal, CampaignModel } from '../types';

function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

export function Home() {
  const navigate = useNavigate();
  const [availableAnimals, setAvailableAnimals] = useState<Animal[]>([]);
  const [missingAnimals, setMissingAnimals] = useState<Animal[]>([]);
  const [campaigns, setCampaigns] = useState<CampaignModel[]>([]);
  
  const [loadingAvailable, setLoadingAvailable] = useState(true);
  const [loadingMissing, setLoadingMissing] = useState(true);
  const [loadingCampaigns, setLoadingCampaigns] = useState(true);

  useEffect(() => {
    async function fetchData() {
      // Busca Animais Disponíveis
      try {
        const available = await getAnimalsByStatus('available_for_adoption');
        setAvailableAnimals(available.slice(0, 4));
      } catch (error) {
        console.error('[Home] Erro ao buscar disponíveis:', error);
      } finally {
        setLoadingAvailable(false);
      }

      // Busca Animais Desaparecidos
      try {
        const missing = await getAnimalsByStatus('missing');
        setMissingAnimals(missing.slice(0, 4));
      } catch (error) {
        console.error('[Home] Erro ao buscar desaparecidos:', error);
      } finally {
        setLoadingMissing(false);
      }

      // Busca Campanhas
      try {
        const activeCampaigns = await getCampaigns(); // Ajuste conforme seu service
        setCampaigns(activeCampaigns.slice(0, 3)); // Pega as 3 primeiras
      } catch (error) {
        console.error('[Home] Erro ao buscar campanhas:', error);
      } finally {
        setLoadingCampaigns(false);
      }
    }
    fetchData();
  }, []);

  const hasMissingAnimals = missingAnimals.length > 0;

  return (
    <div className="min-h-screen bg-white">
      <ScrollToTop />

      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-orange-400 via-orange-500 to-orange-600" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-28 text-center">
            <FadeIn direction="down">
              <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm text-white px-4 py-2 rounded-full text-sm font-medium mb-6">
                <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                ONG ativa desde 2020
              </div>
            </FadeIn>

            <FadeIn direction="up" delay={0.2}>
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-6 leading-tight">
                Encontre seu novo <span className="text-yellow-200">melhor amigo</span> 🐾
              </h1>
            </FadeIn>

            <FadeIn direction="up" delay={0.4}>
              <p className="text-lg md:text-xl text-white/90 mb-10 max-w-2xl mx-auto">
                Resgatamos, cuidamos e encontramos lares amorosos para animais abandonados.
              </p>
            </FadeIn>

            <FadeIn direction="up" delay={0.6}>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link to="/adocao" className="inline-flex items-center justify-center gap-2 bg-white text-orange-600 px-8 py-4 rounded-full font-bold text-lg shadow-xl hover:scale-105 transition-all">
                  Quero Adotar
                </Link>
                <Link to="/registrar-ocorrencia" className="inline-flex items-center justify-center gap-2 bg-orange-700/50 backdrop-blur-sm text-white border border-white/30 px-8 py-4 rounded-full font-semibold text-lg hover:scale-105 transition-all">
                  🚨 Registrar ocorrência
                </Link>
              </div>
            </FadeIn>
        </div>
      </section>

      {/* Seção de Adoção */}
      <section className="py-16 lg:py-24 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-12">
            <FadeIn direction="right">
              <div>
                <div className="inline-flex items-center gap-2 text-orange-600 font-medium text-sm mb-3">
                  <span className="w-8 h-px bg-orange-500" /> Adoção
                </div>
                <h2 className="text-3xl md:text-4xl font-bold text-slate-800 mb-3">Eles precisam de um lar 💕</h2>
              </div>
            </FadeIn>
            <FadeIn direction="left">
              <Link to="/adocao" className="hidden sm:inline-flex items-center gap-2 text-orange-600 font-semibold hover:text-orange-700 group">
                Ver todos os animais →
              </Link>
            </FadeIn>
          </div>

          {loadingAvailable ? (
            <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" /></div>
          ) : (
            <FadeIn delay={0.4}>
              <AnimalGrid animals={availableAnimals} emptyMessage="Nenhum animal disponível no momento." columns={4} />
            </FadeIn>
          )}
        </div>
      </section>

      {/* Seção de Desaparecidos */}
      {(hasMissingAnimals || loadingMissing) && (
        <section className="py-16 lg:py-24 bg-gradient-to-b from-red-50 to-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <FadeIn direction="up">
              <div className="bg-red-500 text-white rounded-2xl p-6 md:p-8 mb-10 shadow-lg">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                  <div className="flex items-center gap-4">
                    <span className="text-4xl">⚠️</span>
                    <div>
                      <h2 className="text-2xl font-bold">Nos ajude a encontrá-los</h2>
                      <p className="text-red-100">Esses animais precisam voltar para casa</p>
                    </div>
                  </div>
                  <Link to="/desaparecidos" className="bg-white text-red-600 px-6 py-3 rounded-xl font-semibold hover:bg-red-50 transition-colors">Ver todos</Link>
                </div>
              </div>
            </FadeIn>
            {loadingMissing ? (
              <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-red-500" /></div>
            ) : (
              <FadeIn delay={0.3}>
                <AnimalGrid animals={missingAnimals} variant="urgent" columns={4} />
              </FadeIn>
            )}
          </div>
        </section>
      )}

      {/* Seção de Campanhas (MODIFICADA COM SEU COMPONENTE) */}
      <section className="py-16 lg:py-24 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-12">
            <FadeIn direction="right">
              <div>
                <div className="inline-flex items-center gap-2 text-blue-600 font-medium text-sm mb-3">
                  <span className="w-8 h-px bg-blue-500" /> Campanhas
                </div>
                <h2 className="text-3xl md:text-4xl font-bold text-slate-800 mb-3">Nossas Campanhas Ativas 📢</h2>
                <p className="text-slate-600 text-lg max-w-xl">Participe das nossas ações de arrecadação.</p>
              </div>
            </FadeIn>
            <FadeIn direction="left">
              <Link to="/campanhas" className="text-blue-600 font-semibold hover:underline">Ver todas →</Link>
            </FadeIn>
          </div>

          {loadingCampaigns ? (
            <div className="flex justify-center py-12"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" /></div>
          ) : (
            <FadeIn delay={0.4}>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                {campaigns.length > 0 ? (
                  campaigns.map((camp) => (
                    <CampaignCard 
                      key={camp.id} 
                      campaign={camp} 
                      onClick={(c) => navigate(`/campanhas/${c.id}`)} 
                    />
                  ))
                ) : (
                  <p className="text-slate-500 col-span-full text-center">Nenhuma campanha ativa no momento.</p>
                )}
              </div>
            </FadeIn>
          )}
        </div>
      </section>

      {/* Seção Como Ajudar */}
      <section className="py-16 lg:py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <FadeIn direction="up">
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-4xl font-bold text-slate-800 mb-4">Faça parte dessa missão 🤝</h2>
            </div>
          </FadeIn>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              { icon: '🏠', title: 'Adote', desc: 'Dê um lar amoroso.', link: '/adocao', color: 'text-orange-600' },
              { icon: '🚨', title: 'Ocorrências', desc: 'Avise-nos sobre riscos.', link: '/registrar-ocorrencia', color: 'text-red-600' },
              { icon: '📢', title: 'Divulgue', desc: 'Compartilhe desaparecidos.', link: '/desaparecidos', color: 'text-blue-600' },
            ].map((item, index) => (
              <FadeIn key={item.title} delay={index * 0.2} direction="up">
                <div className="bg-slate-50 p-8 rounded-2xl text-center hover:shadow-xl transition-all border border-transparent hover:border-slate-100">
                  <div className="text-4xl mb-4">{item.icon}</div>
                  <h3 className="text-xl font-bold mb-2">{item.title}</h3>
                  <p className="text-slate-600 mb-6">{item.desc}</p>
                  <Link to={item.link} className={`${item.color} font-bold`}>Saber mais →</Link>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>

      <footer className="bg-slate-900 text-slate-400 py-12 text-center">
        <div className="flex items-center justify-center gap-2 mb-4">
          <span className="text-2xl">🐾</span>
          <span className="text-xl font-bold text-white">Patinhas e Amor</span>
        </div>
        <p className="text-sm">© 2026 Patinhas e Amor. Porto União - SC.</p>
      </footer>
    </div>
  );
}