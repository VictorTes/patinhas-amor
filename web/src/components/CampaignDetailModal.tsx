import React, { useState, useEffect } from 'react';
import type { CampaignModel } from '../types';
import { CampaignType, CampaignStatus } from '../types';

interface Props {
  campaign: CampaignModel;
  onClose: () => void;
}

export const CampaignDetailModal: React.FC<Props> = ({ campaign, onClose }) => {
  const [ticketQuantity, setTicketQuantity] = useState(1);
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);
  const [selectedReceiptIndex, setSelectedReceiptIndex] = useState<number | null>(null);

  const isFinalized = campaign.status === CampaignStatus.finalizada;
  const receipts = campaign.receipts || [];

  useEffect(() => {
    const handleResize = () => setIsMobile(window.innerWidth < 768);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Navegação do Lightbox
  const nextReceipt = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (selectedReceiptIndex !== null) {
      setSelectedReceiptIndex((selectedReceiptIndex + 1) % receipts.length);
    }
  };

  const prevReceipt = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (selectedReceiptIndex !== null) {
      setSelectedReceiptIndex((selectedReceiptIndex - 1 + receipts.length) % receipts.length);
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(value);
  };

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
        <button onClick={onClose} style={styles.closeBtn}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

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

            {campaign.prize && (
              <div style={styles.prizeBox}>
                <h4 style={{ margin: '0 0 5px 0', fontSize: '12px', color: '#e67e22', textTransform: 'uppercase' }}>🎁 Premiação</h4>
                <p style={{ margin: 0, fontWeight: 700, color: '#333' }}>{campaign.prize}</p>
              </div>
            )}

            <div style={styles.progressContainer}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px', alignItems: 'flex-end' }}>
                <div>
                  <span style={{ fontSize: '12px', color: '#888', display: 'block' }}>Arrecadado</span>
                  <span style={{ fontWeight: 700, fontSize: '20px', color: '#333' }}>{formatCurrency(campaign.currentValue || 0)}</span>
                </div>
                <span style={{ color: '#888', fontSize: '13px' }}>meta: {formatCurrency(campaign.goalValue || 0)}</span>
              </div>
              <div style={styles.progressBarBg}>
                <div style={{ ...styles.progressBarFill, width: `${progress}%` }} />
              </div>
              <p style={{ textAlign: 'right', fontSize: '13px', color: '#2ecc71', fontWeight: 600, marginTop: '5px' }}>
                {progress}% concluído
              </p>
            </div>

            {!isFinalized && (
              <div style={styles.actionBox}>
                <div style={{ marginBottom: '15px' }}>
                  <p style={{ margin: 0, fontSize: '13px', color: '#666' }}>Valor por cota</p>
                  <p style={{ margin: 0, fontSize: '24px', fontWeight: 800, color: '#1a1a1a' }}>{formatCurrency(campaign.ticketValue || 0)}</p>
                </div>

                <div style={{ 
                  display: 'flex', 
                  gap: '12px', 
                  flexDirection: isMobile ? 'column' : 'row',
                  alignItems: 'stretch' 
                }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                    {isMobile && <label style={{ fontSize: '11px', fontWeight: 'bold', color: '#999' }}>QTD:</label>}
                    <input
                      type="number" min="1" value={ticketQuantity}
                      onChange={(e) => setTicketQuantity(parseInt(e.target.value))}
                      style={{ ...styles.input, width: isMobile ? '100%' : '80px' }}
                    />
                  </div>
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
                <>
                  <div style={styles.expenseBox}>
                    {campaign.expenses?.map((exp, idx) => (
                      <div key={idx} style={styles.expenseItem}>
                        <span style={{ color: '#555' }}>{exp.description}</span>
                        <span style={{ fontWeight: 600, color: '#d32f2f' }}>- {formatCurrency(exp.value)}</span>
                      </div>
                    ))}
                    <div style={{ ...styles.expenseItem, borderTop: '1px solid #ddd', marginTop: '10px', paddingTop: '10px' }}>
                      <strong style={{ color: '#333' }}>Total Liquidado</strong>
                      <strong style={{ color: '#2e7d32', fontSize: '16px' }}>{formatCurrency(campaign.totalCollected || 0)}</strong>
                    </div>
                  </div>

                  {receipts.length > 0 && (
                    <div style={{ marginTop: '20px' }}>
                      <p style={{ fontSize: '13px', fontWeight: 700, color: '#666', marginBottom: '10px' }}>Comprovantes Anexados:</p>
                      <div style={styles.receiptGrid}>
                        {receipts.map((url, i) => (
                          <div key={i} onClick={() => setSelectedReceiptIndex(i)} style={styles.receiptThumb}>
                            <img src={url} alt="Comprovante" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </>
              ) : (
                <div style={styles.emptyState}>Prestação de contas será publicada em breve.</div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* LIGHTBOX / TELA CHEIA */}
      {selectedReceiptIndex !== null && (
        <div style={styles.lightboxOverlay} onClick={() => setSelectedReceiptIndex(null)}>
          <button style={styles.lightboxClose} onClick={() => setSelectedReceiptIndex(null)}>✕</button>
          
          {receipts.length > 1 && (
            <>
              <button style={styles.navBtnLeft} onClick={prevReceipt}>‹</button>
              <button style={styles.navBtnRight} onClick={nextReceipt}>›</button>
            </>
          )}

          <div style={styles.lightboxContent} onClick={(e) => e.stopPropagation()}>
            <img 
              src={receipts[selectedReceiptIndex]} 
              alt="Comprovante em tela cheia" 
              style={styles.lightboxImage} 
            />
            <div style={styles.lightboxCounter}>
              {selectedReceiptIndex + 1} / {receipts.length}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  overlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(4px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, padding: '15px' },
  modal: { backgroundColor: '#fff', width: '100%', maxWidth: '1000px', maxHeight: '95vh', borderRadius: '24px', position: 'relative', overflowY: 'auto', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)' },
  closeBtn: { position: 'absolute', top: '15px', right: '15px', width: '40px', height: '40px', borderRadius: '50%', backgroundColor: 'white', color: '#000', border: 'none', cursor: 'pointer', zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(0,0,0,0.2)', transition: 'all 0.2s ease' },
  content: { display: 'flex', flexDirection: 'row', flexWrap: 'wrap' },
  imageContainer: { flex: '1 1 400px', backgroundColor: '#f8f8f8' },
  image: { width: '100%', height: '100%', minHeight: '300px', objectFit: 'cover' },
  infoSection: { flex: '1 1 500px', padding: '40px', minWidth: '300px' },
  badge: { fontSize: '10px', fontWeight: 800, color: '#e67e22', letterSpacing: '1px', marginBottom: '8px', display: 'block' },
  title: { margin: '0 0 12px 0', fontSize: '28px', color: '#1a1a1a', fontWeight: 800 },
  description: { color: '#555', lineHeight: '1.7', marginBottom: '20px', fontSize: '15px' },
  prizeBox: { backgroundColor: '#fffbe6', padding: '15px', borderRadius: '12px', border: '1px solid #ffe58f', marginBottom: '25px' },
  progressContainer: { marginBottom: '30px', backgroundColor: '#fcfcfc', padding: '20px', borderRadius: '16px', border: '1px solid #f0f0f0' },
  progressBarBg: { height: '12px', backgroundColor: '#eee', borderRadius: '6px', overflow: 'hidden' },
  progressBarFill: { height: '100%', backgroundColor: '#2ecc71', borderRadius: '6px', transition: 'width 1.5s ease-out' },
  actionBox: { backgroundColor: '#fff', padding: '25px', borderRadius: '20px', border: '2px solid #ffe0b2', marginBottom: '30px' },
  input: { padding: '14px', borderRadius: '12px', border: '1px solid #ddd', fontSize: '16px', fontWeight: 'bold', textAlign: 'center', backgroundColor: '#f9f9f9' },
  buyBtn: { flex: 1, padding: '16px', backgroundColor: '#25D366', color: '#fff', border: 'none', borderRadius: '12px', fontWeight: 800, cursor: 'pointer', fontSize: '14px', boxShadow: '0 4px 14px rgba(37, 211, 102, 0.3)' },
  accountability: { borderTop: '1px solid #eee', paddingTop: '25px' },
  expenseBox: { backgroundColor: '#f9f9f9', padding: '20px', borderRadius: '12px' },
  expenseItem: { display: 'flex', justifyContent: 'space-between', padding: '10px 0', fontSize: '14px' },
  receiptGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(80px, 1fr))', gap: '10px' },
  receiptThumb: { height: '80px', borderRadius: '8px', overflow: 'hidden', border: '1px solid #ddd', cursor: 'pointer', transition: 'transform 0.2s' },
  emptyState: { color: '#999', fontStyle: 'italic', fontSize: '14px', textAlign: 'center', padding: '20px' },
  
  // Lightbox Styles
  lightboxOverlay: { position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.95)', zIndex: 2000, display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '20px' },
  lightboxContent: { position: 'relative', maxWidth: '90%', maxHeight: '90%', display: 'flex', flexDirection: 'column', alignItems: 'center' },
  lightboxImage: { maxWidth: '100%', maxHeight: '80vh', objectFit: 'contain', borderRadius: '8px', boxShadow: '0 0 30px rgba(0,0,0,0.5)' },
  lightboxClose: { position: 'absolute', top: '20px', right: '20px', backgroundColor: 'transparent', color: 'white', border: 'none', fontSize: '30px', cursor: 'pointer', zIndex: 2100 },
  navBtnLeft: { position: 'absolute', left: '20px', backgroundColor: 'rgba(255,255,255,0.1)', color: 'white', border: 'none', fontSize: '50px', width: '60px', height: '60px', borderRadius: '50%', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'background 0.3s' },
  navBtnRight: { position: 'absolute', right: '20px', backgroundColor: 'rgba(255,255,255,0.1)', color: 'white', border: 'none', fontSize: '50px', width: '60px', height: '60px', borderRadius: '50%', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'background 0.3s' },
  lightboxCounter: { color: 'white', marginTop: '15px', fontSize: '14px', fontWeight: 'bold', backgroundColor: 'rgba(0,0,0,0.5)', padding: '5px 15px', borderRadius: '20px' }
};