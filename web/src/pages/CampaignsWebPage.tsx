import React, { useEffect, useState } from 'react';
import { getCampaignsStream } from '../services/firebaseService';
import { CampaignStatus } from '../types';
import type { CampaignModel } from '../types'; 

// Importações corrigidas (sem o .tsx no final e apontando para os nomes certos)
import { CampaignCard } from '../components/CampaignCard';
import { CampaignDetailModal } from '../components/CampaignDetailModal';

const CampaignsWebPage: React.FC = () => {
  const [campaigns, setCampaigns] = useState<CampaignModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<CampaignStatus | 'todas'>('ativa');
  const [selectedCampaign, setSelectedCampaign] = useState<CampaignModel | null>(null);

  useEffect(() => {
    const unsubscribe = getCampaignsStream((data) => {
      setCampaigns(data);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    document.body.style.overflow = selectedCampaign ? 'hidden' : 'unset';
  }, [selectedCampaign]);

  const filteredCampaigns = campaigns.filter((c) => {
    if (filter === 'todas') return true;
    return c.status === filter;
  });

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
        <p>Carregando campanhas...</p>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '40px 20px' }}>
      <header style={{ marginBottom: '40px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap' }}>
        <div>
          <h1 style={{ margin: 0, color: '#333' }}>Campanhas Solidárias</h1>
          <p style={{ color: '#e67e22' }}>Ajude os animais da nossa ONG</p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          {(['todas', 'ativa', 'finalizada'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                padding: '10px 20px',
                borderRadius: '25px',
                border: '1px solid #e67e22',
                backgroundColor: filter === f ? '#e67e22' : 'transparent',
                color: filter === f ? '#fff' : '#e67e22',
                cursor: 'pointer',
                fontWeight: 'bold'
              }}
            >
              {f === 'todas' ? 'Todas' : f === 'ativa' ? 'Ativas' : 'Concluídas'}
            </button>
          ))}
        </div>
      </header>

      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', 
        gap: '24px' 
      }}>
        {filteredCampaigns.map((campaign) => (
          <CampaignCard 
            key={campaign.id} 
            campaign={campaign} 
            onClick={(c) => setSelectedCampaign(c)} 
          />
        ))}
      </div>

      {selectedCampaign && (
        <CampaignDetailModal 
          campaign={selectedCampaign} 
          onClose={() => setSelectedCampaign(null)} 
        />
      )}
    </div>
  );
};

export default CampaignsWebPage;