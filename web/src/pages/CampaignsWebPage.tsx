import React, { useEffect, useState } from 'react';
import { getCampaignsStream } from '../services/firebaseService';
import { CampaignStatus } from '../types';
import type { CampaignModel } from '../types'; 

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
      <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '80vh', gap: '20px' }}>
        <div className="animate-spin" style={{ width: '40px', height: '40px', border: '4px solid #f3f3f3', borderTop: '4px solid #e67e22', borderRadius: '50%' }} />
        <p style={{ color: '#666', fontWeight: 500 }}>Buscando campanhas solidárias...</p>
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: '#fafafa', minHeight: '100vh' }}>
      <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '60px 20px' }}>
        <header style={{ 
          marginBottom: '50px', 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'flex-end', 
          flexWrap: 'wrap',
          gap: '20px'
        }}>
          <div>
            <h1 style={{ margin: 0, color: '#1a1a1a', fontSize: '2.5rem', fontWeight: 800, letterSpacing: '-1px' }}>
              Campanhas <span style={{ color: '#e67e22' }}>Solidárias</span>
            </h1>
            <p style={{ color: '#666', fontSize: '1.1rem', marginTop: '8px' }}>
              Transparência e amor em cada doação.
            </p>
          </div>

          <div style={{ 
            display: 'flex', 
            backgroundColor: '#eee', 
            padding: '4px', 
            borderRadius: '12px',
            gap: '4px' 
          }}>
            {(['todas', 'ativa', 'finalizada'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                style={{
                  padding: '10px 24px',
                  borderRadius: '10px',
                  border: 'none',
                  backgroundColor: filter === f ? '#fff' : 'transparent',
                  color: filter === f ? '#e67e22' : '#666',
                  cursor: 'pointer',
                  fontWeight: 700,
                  fontSize: '14px',
                  transition: 'all 0.2s',
                  boxShadow: filter === f ? '0 2px 8px rgba(0,0,0,0.05)' : 'none'
                }}
              >
                {f === 'todas' ? 'Todas' : f === 'ativa' ? 'Ativas' : 'Concluídas'}
              </button>
            ))}
          </div>
        </header>

        {filteredCampaigns.length > 0 ? (
          <div style={{ 
            display: 'grid', 
            gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', 
            gap: '30px' 
          }}>
            {filteredCampaigns.map((campaign) => (
              <CampaignCard 
                key={campaign.id} 
                campaign={campaign} 
                onClick={(c) => setSelectedCampaign(c)} 
              />
            ))}
          </div>
        ) : (
          <div style={{ textAlign: 'center', padding: '100px 20px', color: '#999' }}>
            <p style={{ fontSize: '1.2rem' }}>Nenhuma campanha encontrada neste filtro.</p>
          </div>
        )}

        {selectedCampaign && (
          <CampaignDetailModal 
            campaign={selectedCampaign} 
            onClose={() => setSelectedCampaign(null)} 
          />
        )}
      </div>
    </div>
  );
};

export default CampaignsWebPage;