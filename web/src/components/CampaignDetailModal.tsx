import React, { useState } from 'react';
import type { CampaignModel } from '../types';
import { CampaignType, CampaignStatus } from '../types';

interface Props {
  campaign: CampaignModel;
  onClose: () => void;
}

export const CampaignDetailModal: React.FC<Props> = ({ campaign, onClose }) => {
  const [ticketQuantity, setTicketQuantity] = useState(1);
  const isFinalized = campaign.status === CampaignStatus.finalizada;

  const handleWhatsApp = () => {
    const phone = "5547999999999"; // TODO: Colocar o número da ONG aqui
    const message = campaign.type === CampaignType.rifa
      ? `Olá! Gostaria de comprar ${ticketQuantity} número(s) para a rifa: ${campaign.title}`
      : `Olá! Tenho interesse na campanha: ${campaign.title}`;
    
    const url = `https://wa.me/${phone}?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
  };

  return (
    <div style={styles.overlay}>
      <div style={styles.modal}>
        <button onClick={onClose} style={styles.closeBtn}>&times;</button>
        
        <div style={styles.content}>
          <img src={campaign.imageUrl} alt={campaign.title} style={styles.image} />
          
          <div style={styles.infoSection}>
            <h2 style={styles.title}>{campaign.title}</h2>
            <p style={styles.description}>{campaign.description}</p>

            {/* Seção de Compra (Só aparece se for Rifa e estiver ativa) */}
            {campaign.type === CampaignType.rifa && !isFinalized && (
              <div style={styles.actionBox}>
                <p><strong>Valor do número:</strong> R$ {campaign.ticketValue}</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', margin: '15px 0' }}>
                  <span>Quantidade:</span>
                  <input 
                    type="number" 
                    min="1" 
                    value={ticketQuantity}
                    onChange={(e) => setTicketQuantity(parseInt(e.target.value))}
                    style={styles.input}
                  />
                </div>
                <button onClick={handleWhatsApp} style={styles.buyBtn}>
                  COMPRAR NÚMEROS VIA WHATSAPP
                </button>
              </div>
            )}

            {/* Prestação de Contas */}
            <div style={styles.accountability}>
              <h3>📊 Prestação de Contas</h3>
              {campaign.hasAccountability ? (
                <>
                  <p>Total Arrecadado: <strong>R$ {campaign.totalCollected || 0}</strong></p>
                  <div style={styles.expenseList}>
                    {campaign.expenses?.map((exp, idx) => (
                      <div key={idx} style={styles.expenseItem}>
                        <span>{exp.description}</span>
                        <span>R$ {exp.value}</span>
                      </div>
                    ))}
                  </div>
                </>
              ) : (
                <p style={{ color: '#999', fontStyle: 'italic' }}>Prestação de contas em andamento...</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  overlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.7)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, padding: '20px' },
  modal: { backgroundColor: '#fff', width: '100%', maxWidth: '900px', maxHeight: '90vh', borderRadius: '16px', position: 'relative', overflowY: 'auto' },
  closeBtn: { position: 'absolute', top: '15px', right: '20px', fontSize: '30px', border: 'none', background: 'none', cursor: 'pointer', zIndex: 10 },
  content: { display: 'flex', flexDirection: 'row', flexWrap: 'wrap' as any },
  image: { width: '100%', maxWidth: '400px', height: 'auto', objectFit: 'cover' },
  infoSection: { flex: 1, padding: '30px', minWidth: '300px' },
  title: { margin: '0 0 10px 0', fontSize: '24px', color: '#333' },
  description: { color: '#666', lineHeight: '1.6', marginBottom: '20px' },
  actionBox: { backgroundColor: '#fff8f0', padding: '20px', borderRadius: '12px', border: '1px solid #ffe0b2', marginBottom: '20px' },
  input: { width: '60px', padding: '8px', borderRadius: '4px', border: '1px solid #ddd' },
  buyBtn: { width: '100%', padding: '12px', backgroundColor: '#25D366', color: '#fff', border: 'none', borderRadius: '8px', fontWeight: 'bold', cursor: 'pointer' },
  accountability: { marginTop: '30px', borderTop: '1px solid #eee', paddingTop: '20px' },
  expenseList: { marginTop: '10px' },
  expenseItem: { display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #f9f9f9', fontSize: '14px' }
};