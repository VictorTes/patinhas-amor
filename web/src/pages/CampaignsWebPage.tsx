import React, { useEffect, useState } from 'react';
import { getCampaignsStream } from '../services/firebaseService';
import { CampaignStatus } from '../types';
// Note o "type" adicionado abaixo:
import type { CampaignModel } from '../types'; 
import { CampaignCard } from '../components/CampaignCard';

const CampaignsWebPage: React.FC = () => {
  const [campaigns, setCampaigns] = useState<CampaignModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<CampaignStatus | 'todas'>('ativa');

  useEffect(() => {
    // Iniciamos o Stream em tempo real
    const unsubscribe = getCampaignsStream((data) => {
      setCampaigns(data);
      setLoading(false);
    });

    // Cleanup ao desmontar o componente
    return () => unsubscribe();
  }, []);

  // Lógica de filtragem
  const filteredCampaigns = campaigns.filter((c) => {
    if (filter === 'todas') return true;
    return c.status === filter;
  });

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: '50px' }}>
        <p>Carregando campanhas...</p>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '24px' }}>
      <header style={{ marginBottom: '32px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ margin: 0, color: '#333' }}>Campanhas Solidárias</h1>
          <p style={{ color: '#666' }}>Ajude as causas da nossa ONG</p>
        </div>

        {/* Filtros Visuais */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {(['todas', 'ativa', 'finalizada'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                padding: '8px 16px',
                borderRadius: '20px',
                border: '1px solid #e67e22',
                backgroundColor: filter === f ? '#e67e22' : 'transparent',
                color: filter === f ? '#fff' : '#e67e22',
                cursor: 'pointer',
                fontWeight: 'bold',
                textTransform: 'capitalize'
              }}
            >
              {f === 'todas' ? 'Todas' : f === 'ativa' ? 'Ativas' : 'Concluídas'}
            </button>
          ))}
        </div>
      </header>

      {filteredCampaigns.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
          Nenhuma campanha encontrada neste status.
        </div>
      ) : (
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', 
          gap: '24px' 
        }}>
          {filteredCampaigns.map((campaign) => (
            <CampaignCard 
              key={campaign.id} 
              campaign={campaign} 
              onClick={(c) => console.log('Abrir modal da campanha:', c.id)} 
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default CampaignsWebPage;