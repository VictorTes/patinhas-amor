import { useState, useEffect } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../config/firebase';
import { useSearchParams, Link } from 'react-router-dom';
import { Helmet } from 'react-helmet-async'; // Recomendado usar react-helmet-async
import { FadeIn } from '../components/FadeIn';

// Tipagem aprimorada
interface OcorrenciaData {
  type: string;
  location: string;
  description: string;
  status: 'pending' | 'in_progress' | 'resolved';
  accessCode: string;
  imageUrl?: string;
  adminFeedback?: string;
  isWaitingApproval?: boolean; // Flag para controle interno da UI
}

const Acompanhamento = () => {
  const [searchParams] = useSearchParams();
  const [protocolo, setProtocolo] = useState('');
  const [codigo, setCodigo] = useState('');
  const [loading, setLoading] = useState(false);
  const [ocorrencia, setOcorrencia] = useState<OcorrenciaData | null>(null);
  const [erro, setErro] = useState('');

  // 1. Captura automática via URL (Link do WhatsApp)
  useEffect(() => {
    const p = searchParams.get('p');
    const c = searchParams.get('c');
    if (p && c) {
      setProtocolo(p);
      setCodigo(c);
      buscarStatus(p, c);
    }
  }, [searchParams]);

  const buscarStatus = async (idProtocolo: string, pinCode: string) => {
    if (!idProtocolo || !pinCode) {
      setErro('Preencha o protocolo e o PIN.');
      return;
    }

    setLoading(true);
    setErro('');
    setOcorrencia(null);

    try {
      // Lógica de busca em duas etapas:
      // 1. Tenta buscar na coleção oficial (onde estão as aprovadas)
      let docRef = doc(db, "occurrences", idProtocolo);
      let docSnap = await getDoc(docRef);
      let pending = false;

      // 2. Se não existir na oficial, busca na pendente
      if (!docSnap.exists()) {
        docRef = doc(db, "pending_occurrences", idProtocolo);
        docSnap = await getDoc(docRef);
        pending = true;
      }

      if (docSnap.exists()) {
        const data = docSnap.data() as OcorrenciaData;
        
        // Validação de Segurança via Código PIN
        if (data.accessCode === pinCode) {
          setOcorrencia({ ...data, isWaitingApproval: pending });
        } else {
          setErro('Código PIN incorreto.');
        }
      } else {
        setErro('Protocolo não encontrado.');
      }
    } catch (err) {
      console.error(err);
      setErro('Erro de permissão ou conexão.');
    } finally {
      setLoading(false);
    }
  };

  // --- VIEW: BUSCA ---
  if (!ocorrencia) {
    return (
      <div className="min-h-[80vh] flex items-center justify-center px-4 py-12 bg-slate-50">
        <Helmet>
          <meta name="robots" content="noindex, nofollow" />
        </Helmet>
        
        <FadeIn>
          <div className="max-w-md w-full bg-white rounded-3xl shadow-xl p-8 border border-slate-100">
            <div className="text-center mb-8">
              <div className="w-16 h-16 bg-orange-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">🔎</span>
              </div>
              <h2 className="text-2xl font-bold text-slate-800">Acompanhar Ocorrência</h2>
              <p className="text-slate-500 text-sm mt-2">Consulte o status da sua denúncia</p>
            </div>

            <div className="space-y-4">
              <input 
                type="text"
                placeholder="Número do Protocolo" 
                className="w-full h-14 px-4 bg-slate-50 border-2 border-slate-100 rounded-xl focus:border-orange-500 transition-all outline-none"
                value={protocolo}
                onChange={(e) => setProtocolo(e.target.value)}
              />
              <input 
                type="text"
                placeholder="Código PIN" 
                className="w-full h-14 px-4 bg-slate-50 border-2 border-slate-100 rounded-xl focus:border-orange-500 transition-all outline-none text-center font-mono text-xl tracking-widest"
                maxLength={6}
                value={codigo}
                onChange={(e) => setCodigo(e.target.value)}
              />
              <button 
                onClick={() => buscarStatus(protocolo, codigo)}
                disabled={loading}
                className="w-full h-14 bg-slate-900 text-white rounded-xl font-bold hover:bg-orange-600 transition-all shadow-lg disabled:opacity-50"
              >
                {loading ? 'Consultando...' : 'VERIFICAR STATUS'}
              </button>
              {erro && <p className="text-red-500 text-center text-sm font-medium">{erro}</p>}
            </div>
            <div className="mt-8 text-center text-sm text-slate-400">
               <Link to="/registrar-ocorrencia" className="hover:underline">Fazer uma nova denúncia</Link>
            </div>
          </div>
        </FadeIn>
      </div>
    );
  }

  // --- VIEW: RESULTADO ---
  const statusConfig = {
    pending: { color: 'bg-amber-100 text-amber-700', label: 'Pendente', icon: '⏳' },
    in_progress: { color: 'bg-blue-100 text-blue-700', label: 'Em Curso', icon: '🐕' },
    resolved: { color: 'bg-emerald-100 text-emerald-700', label: 'Concluído', icon: '✅' }
  };

  return (
    <div className="min-h-screen bg-slate-50 py-12 px-4">
      <Helmet><meta name="robots" content="noindex, nofollow" /></Helmet>

      <FadeIn>
        <div className="max-w-2xl mx-auto space-y-6">
          <div className="bg-white rounded-3xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="p-6 md:p-8">
              
              {/* Alerta de Aguardando Aprovação */}
              {ocorrencia.isWaitingApproval && (
                <div className="mb-6 p-4 bg-blue-50 border border-blue-100 rounded-2xl text-blue-800 text-sm flex items-start gap-3">
                  <span className="text-lg">📩</span>
                  <p>Sua denúncia foi enviada com sucesso e está <strong>aguardando visualização</strong> da nossa equipe técnica para entrar no sistema oficial.</p>
                </div>
              )}

              <div className="flex justify-between items-start mb-6">
                <div>
                  <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase ${statusConfig[ocorrencia.status].color}`}>
                    {statusConfig[ocorrencia.status].icon} {statusConfig[ocorrencia.status].label}
                  </span>
                  <h1 className="text-2xl font-bold text-slate-800 mt-3">{ocorrencia.type}</h1>
                  <p className="text-slate-500 text-sm mt-1">{ocorrencia.location}</p>
                </div>
              </div>

              {/* Timeline */}
              <div className="py-8 border-y border-slate-50">
                <h3 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-8">Status do Atendimento</h3>
                <div className="relative pl-8 space-y-10">
                  <div className="absolute left-[11px] top-2 bottom-2 w-0.5 bg-slate-100"></div>

                  <TimelineItem 
                    label="Denúncia Recebida" 
                    desc="O protocolo foi gerado e está em nossa fila." 
                    active={true} 
                    completed={!ocorrencia.isWaitingApproval} 
                  />
                  <TimelineItem 
                    label="Em Análise / Atendimento" 
                    desc="Estamos verificando as informações ou já estamos no local." 
                    active={!ocorrencia.isWaitingApproval && (ocorrencia.status === 'in_progress' || ocorrencia.status === 'resolved')} 
                    completed={ocorrencia.status === 'resolved'} 
                  />
                  <TimelineItem 
                    label="Finalizado" 
                    desc="O caso foi encerrado e a solução foi aplicada." 
                    active={ocorrencia.status === 'resolved'} 
                    completed={ocorrencia.status === 'resolved'} 
                  />
                </div>
              </div>

              {/* Detalhes Adicionais */}
              <div className="mt-8 space-y-4">
                <div className="bg-slate-50 p-4 rounded-xl">
                  <h4 className="text-xs font-bold text-slate-400 uppercase mb-2">Descrição enviada:</h4>
                  <p className="text-slate-700 text-sm italic">"{ocorrencia.description}"</p>
                </div>

                {ocorrencia.adminFeedback && (
                  <div className="bg-orange-50 p-4 rounded-xl border border-orange-100">
                    <h4 className="text-orange-800 font-bold text-sm mb-1">Resposta da ONG:</h4>
                    <p className="text-orange-900 text-sm">{ocorrencia.adminFeedback}</p>
                  </div>
                )}
              </div>
            </div>

            <div className="bg-slate-50 px-8 py-4 flex justify-between items-center border-t">
              <button onClick={() => setOcorrencia(null)} className="text-slate-400 text-xs font-bold hover:text-orange-500 uppercase">
                ← Nova Consulta
              </button>
              <p className="text-[10px] text-slate-300 font-mono">PROTOCOLO: {protocolo}</p>
            </div>
          </div>
        </div>
      </FadeIn>
    </div>
  );
};

const TimelineItem = ({ label, desc, active, completed }: any) => (
  <div className="relative">
    <div className={`absolute -left-[27px] w-[24px] h-[24px] rounded-full border-4 border-white shadow-sm z-10 
      ${completed ? 'bg-emerald-500' : active ? 'bg-orange-500 ring-4 ring-orange-50' : 'bg-slate-200'}`}>
      {completed && <svg className="w-3 h-3 text-white mx-auto mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={4} d="M5 13l4 4L19 7" /></svg>}
    </div>
    <div className={active ? 'opacity-100' : 'opacity-30'}>
      <p className="font-bold text-sm text-slate-800 leading-none mb-1">{label}</p>
      <p className="text-xs text-slate-500 leading-tight">{desc}</p>
    </div>
  </div>
);

export default Acompanhamento;