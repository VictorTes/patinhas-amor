import React from 'react';
import type { CampaignModel } from '../types';

interface Props {
  campaign: CampaignModel;
  onClick: (campaign: CampaignModel) => void; 
}

export const CampaignCard: React.FC<Props> = ({ campaign, onClick }) => {
  // Cálculo do progresso
  const progress = Math.round(((campaign.currentValue || 0) / (campaign.goalValue || 1)) * 100);

  /**
   * Helper para formatação de moeda no padrão R$ 0.000,00
   */
  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  };

  return (
    <div 
      onClick={() => onClick(campaign)}
      style={{
        borderRadius: '16px',
        overflow: 'hidden',
        cursor: 'pointer',
        backgroundColor: '#fff',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
        display: 'flex',
        flexDirection: 'column',
        height: '100%', 
        minHeight: '550px', 
        border: '1px solid #f0f0f0'
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-6px)';
        e.currentTarget.style.boxShadow = '0 12px 24px rgba(0,0,0,0.12)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0)';
        e.currentTarget.style.boxShadow = '0 4px 20px rgba(0,0,0,0.08)';
      }}
    >
      {/* Container da Imagem mais alto (Padrão Retrato) */}
      <div style={{ position: 'relative', height: '380px', overflow: 'hidden' }}>
        <img 
          src={campaign.imageUrl} 
          alt={campaign.title} 
          style={{ 
            width: '100%', 
            height: '100%', 
            objectFit: 'cover' 
          }} 
        />
        <span style={{ 
          position: 'absolute', top: '12px', right: '12px',
          fontSize: '11px', fontWeight: 800, padding: '6px 12px', borderRadius: '20px',
          backgroundColor: campaign.status === 'ativa' ? '#27ae60' : '#e74c3c',
          color: '#fff', textTransform: 'uppercase', letterSpacing: '0.5px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
        }}>
          {campaign.status}
        </span>
      </div>

      <div style={{ padding: '20px', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <h3 style={{ 
          margin: '0 0 10px 0', 
          color: '#1a1a1a', 
          fontSize: '1.2rem', 
          lineHeight: '1.3',
          fontWeight: 700 
        }}>
          {campaign.title}
        </h3>
        
        <p style={{ 
          fontSize: '14px', color: '#666', marginBottom: '20px',
          display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden',
          lineHeight: '1.5'
        }}>
          {campaign.description}
        </p>

        {/* Informações fixadas no rodapé do card */}
        <div style={{ marginTop: 'auto' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '13px' }}>
            <span style={{ color: '#888', fontWeight: 500 }}>Progresso</span>
            <span style={{ fontWeight: 'bold', color: '#e67e22' }}>{progress}%</span>
          </div>
          
          <div style={{ width: '100%', height: '8px', backgroundColor: '#f0f0f0', borderRadius: '10px', overflow: 'hidden', marginBottom: '15px' }}>
            <div style={{ 
              width: `${progress}%`, 
              height: '100%', 
              backgroundColor: '#e67e22', 
              borderRadius: '10px', 
              transition: 'width 1s ease-in-out' 
            }} />
          </div>

          <div style={{ 
            display: 'flex', 
            justifyContent: 'space-between', 
            alignItems: 'center',
            paddingTop: '10px',
            borderTop: '1px solid #f9f9f9'
          }}>
            <div>
              <p style={{ margin: 0, fontSize: '11px', color: '#aaa', textTransform: 'uppercase' }}>Arrecadado</p>
              <p style={{ margin: 0, fontWeight: 700, color: '#333', fontSize: '15px' }}>
                {formatCurrency(campaign.currentValue || 0)}
              </p>
            </div>
            {campaign.ticketValue && (
              <div style={{ textAlign: 'right' }}>
                <p style={{ margin: 0, fontSize: '11px', color: '#aaa', textTransform: 'uppercase' }}>Cota</p>
                <p style={{ margin: 0, fontWeight: 700, color: '#e67e22', fontSize: '15px' }}>
                  {formatCurrency(campaign.ticketValue)}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};