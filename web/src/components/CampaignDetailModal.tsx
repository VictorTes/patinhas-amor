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

  const progress = Math.min(
    Math.round(((campaign.currentValue || 0) / (campaign.goalValue || 1)) * 100),
    100
  );

  const handleWhatsApp = () => {
    const phone = "5547999999999";
    const message = campaign.type === CampaignType.rifa
      ? `Olá! Gostaria de participar da campanha: ${campaign.title}. Quero comprar ${ticketQuantity} cota(s).`
      : `Olá! Tenho interesse em ajudar na campanha: ${campaign.title}`;

    window.open(`https://wa.me/${phone}?text=${encodeURIComponent(message)}`, '_blank');
  };

  return (
    <div style={styles.overlay}>
      <div style={styles.modal}>
        {/* Botão de Fechar com Fundo - Essencial para imagens escuras */}
        <button onClick={onClose} style={styles.closeBtn}>&times;</button>

        <div style={styles.content}>
          <div style={styles.imageContainer}>
            <img src={campaign.imageUrl} alt={campaign.title} style={styles.image} />
          </div>

          <div style={styles.infoSection}>
            <header style={{ marginBottom: '25px' }}>
              <span style={styles.badge}>{campaign.type.toUpperCase()}</span>
              <h2 style={styles.title}>{campaign.title}</h2>
              <div style={{ height: '4px', width: '40px', backgroundColor: '#e67e22', borderRadius: '2px' }} />
            </header>

            <p style={styles.description}>{campaign.description}</p>

            {/* Progress Bar Detail */}
            <div style={styles.progressContainer}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px' }}>
                <span style={{ fontWeight: 700, fontSize: '18px', color: '#333' }}>R$ {campaign.currentValue || 0}</span>
                <span style={{ color: '#888' }}>meta de R$ {campaign.goalValue}</span>
              </div>
              <div style={styles.progressBarBg}>
                <div style={{ ...styles.progressBarFill, width: `${progress}%` }} />
              </div>
              <p style={{ textAlign: 'right', fontSize: '13px', color: '#e67e22', fontWeight: 600, marginTop: '5px' }}>
                {progress}% concluído
              </p>
            </div>

            {!isFinalized && (
              <div style={styles.actionBox}>
                <div style={{ marginBottom: '15px' }}>
                  <p style={{ margin: 0, fontSize: '13px', color: '#666' }}>Valor por número/cota</p>
                  <p style={{ margin: 0, fontSize: '24px', fontWeight: 800, color: '#1a1a1a' }}>R$ {campaign.ticketValue}</p>
                </div>

                <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                  <input
                    type="number" min="1" value={ticketQuantity}
                    onChange={(e) => setTicketQuantity(parseInt(e.target.value))}
                    style={styles.input}
                  />
                  <button onClick={handleWhatsApp} style={styles.buyBtn}>
                    AJUDAR VIA WHATSAPP
                  </button>
                </div>
              </div>
            )}

            <div style={styles.accountability}>
              <h3 style={{ fontSize: '16px', marginBottom: '15px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span>📊</span> Prestação de Contas
              </h3>
              {campaign.hasAccountability ? (
                <div style={styles.expenseBox}>
                  {campaign.expenses?.map((exp, idx) => (
                    <div key={idx} style={styles.expenseItem}>
                      <span style={{ color: '#555' }}>{exp.description}</span>
                      <span style={{ fontWeight: 600, color: '#d32f2f' }}>- R$ {exp.value}</span>
                    </div>
                  ))}
                  <div style={{ ...styles.expenseItem, borderTop: '1px solid #ddd', marginTop: '10px', paddingTop: '10px' }}>
                    <strong style={{ color: '#333' }}>Total Arrecadado</strong>
                    <strong style={{ color: '#2e7d32', fontSize: '16px' }}>R$ {campaign.totalCollected || 0}</strong>
                  </div>
                </div>
              ) : (
                <div style={styles.emptyState}>Prestação de contas será publicada em breve.</div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  overlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(4px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, padding: '15px' },
  modal: { backgroundColor: '#fff', width: '100%', maxWidth: '1000px', maxHeight: '95vh', borderRadius: '24px', position: 'relative', overflowY: 'auto', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)' },
  closeBtn: {
    position: 'absolute',
    top: '15px',
    right: '15px',
    width: '40px',
    height: '40px',
    borderRadius: '50%',
    backgroundColor: 'white',
    color: '#000',
    border: 'none',
    cursor: 'pointer',
    zIndex: 100,
    fontSize: '24px',
    fontWeight: 'bold',
    // Flexbox para centralizar
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    // Ajuste óptico: o 'X' as vezes precisa ser "empurrado" 1px para cima
    paddingBottom: '4px',
    lineHeight: 0,
    boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
    transition: 'all 0.2s ease'
  },
  content: { display: 'flex', flexDirection: 'row', flexWrap: 'wrap' },
  imageContainer: { flex: '1 1 400px', backgroundColor: '#f8f8f8' },
  image: { width: '100%', height: '100%', minHeight: '300px', objectFit: 'cover' },
  infoSection: { flex: '1 1 500px', padding: '40px', minWidth: '300px' },
  badge: { fontSize: '10px', fontWeight: 800, color: '#e67e22', letterSpacing: '1px', marginBottom: '8px', display: 'block' },
  title: { margin: '0 0 12px 0', fontSize: '28px', color: '#1a1a1a', fontWeight: 800 },
  description: { color: '#555', lineHeight: '1.7', marginBottom: '30px', fontSize: '15px' },
  progressContainer: { marginBottom: '30px', backgroundColor: '#fcfcfc', padding: '20px', borderRadius: '16px', border: '1px solid #f0f0f0' },
  progressBarBg: { height: '12px', backgroundColor: '#eee', borderRadius: '6px', overflow: 'hidden' },
  progressBarFill: { height: '100%', backgroundColor: '#e67e22', borderRadius: '6px', transition: 'width 1.5s ease-out' },
  actionBox: { backgroundColor: '#fff', padding: '25px', borderRadius: '20px', border: '2px solid #ffe0b2', marginBottom: '30px' },
  input: { width: '80px', padding: '14px', borderRadius: '12px', border: '1px solid #ddd', fontSize: '16px', fontWeight: 'bold', textAlign: 'center' },
  buyBtn: { flex: 1, padding: '16px', backgroundColor: '#25D366', color: '#fff', border: 'none', borderRadius: '12px', fontWeight: 800, cursor: 'pointer', fontSize: '14px', boxShadow: '0 4px 14px rgba(37, 211, 102, 0.3)' },
  accountability: { borderTop: '1px solid #eee', paddingTop: '25px' },
  expenseBox: { backgroundColor: '#f9f9f9', padding: '20px', borderRadius: '12px' },
  expenseItem: { display: 'flex', justifyContent: 'space-between', padding: '10px 0', fontSize: '14px' },
  emptyState: { color: '#999', fontStyle: 'italic', fontSize: '14px', textAlign: 'center', padding: '20px' }
};