import React from 'react';
import type { CampaignModel } from '../types';

interface Props {
  campaign: CampaignModel;
  onClick: (campaign: CampaignModel) => void;
}

export const CampaignCard: React.FC<Props> = ({ campaign, onClick }) => {
  return (
    <div 
      onClick={() => onClick(campaign)}
      style={{
        border: '1px solid #eee',
        borderRadius: '12px',
        overflow: 'hidden',
        cursor: 'pointer',
        backgroundColor: '#fff',
        transition: 'transform 0.2s',
        boxShadow: '0 2px 8px rgba(0,0,0,0.05)'
      }}
      onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-4px)'}
      onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
    >
      <img 
        src={campaign.imageUrl} 
        alt={campaign.title} 
        style={{ width: '100%', height: '200px', objectFit: 'cover' }} 
      />
      <div style={{ padding: '16px' }}>
        <h3 style={{ margin: '0 0 8px 0', color: '#333' }}>{campaign.title}</h3>
        <p style={{ 
          fontSize: '14px', 
          color: '#666', 
          display: '-webkit-box', 
          WebkitLineClamp: 2, 
          WebkitBoxOrient: 'vertical', 
          overflow: 'hidden',
          marginBottom: '12px'
        }}>
          {campaign.description}
        </p>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ 
            fontSize: '12px', 
            fontWeight: 'bold', 
            padding: '4px 8px', 
            borderRadius: '4px',
            backgroundColor: campaign.status === 'ativa' ? '#e6f4ea' : '#feeced',
            color: campaign.status === 'ativa' ? '#1e8e3e' : '#d93025'
          }}>
            {campaign.status.toUpperCase()}
          </span>
          {campaign.ticketValue && (
            <span style={{ fontWeight: 'bold', color: '#e67e22' }}>
              R$ {campaign.ticketValue}
            </span>
          )}
        </div>
      </div>
    </div>
  );
};