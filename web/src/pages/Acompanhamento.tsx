import { useState, useEffect } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../config/firebase';
import { useSearchParams, Link } from 'react-router-dom';
import { Helmet } from 'react-helmet'; // Para o noindex
import { FadeIn } from '../components/FadeIn';

// Tipagem básica para a ocorrência
interface OcorrenciaData {
  type: string;
  location: string;
  description: string;
  status: 'pending' | 'in_progress' | 'resolved';
  accessCode: string;
  imageUrl?: string;
  adminFeedback?: string; // Campo opcional para resposta da ONG
  createdAt?: any;
}

const Acompanhamento = () => {
  const [searchParams] = useSearchParams();
  const [protocolo, setProtocolo] = useState('');
  const [codigo, setCodigo] = useState('');
  const [loading, setLoading] = useState(false);
  const [ocorrencia, setOcorrencia] = useState<OcorrenciaData | null>(null);
  const [erro, setErro] = useState('');

  // 1. Lógica para capturar dados da URL (Link do WhatsApp)
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
      setErro('Preencha o protocolo e o código PIN.');
      return;
    }

    setLoading(true);
    setErro('');
    setOcorrencia(null);

    try {
      // 1. Tenta buscar na coleção de pendentes (onde a web grava inicialmente)
      let docRef = doc(db, "pending_occurrences", idProtocolo);
      let docSnap = await getDoc(docRef);

      // 2. Se não achar, tenta na coleção principal (após aprovação do admin)
      if (!docSnap.exists()) {
        docRef = doc(db, "occurrences", idProtocolo);
        docSnap = await getDoc(docRef);
      }

      if (docSnap.exists()) {
        const data = docSnap.data() as OcorrenciaData;
        
        // Validação do Código de Acesso (PIN)
        if (data.accessCode === pinCode) {
          setOcorrencia(data);
        } else {
          setErro('Código PIN incorreto para este protocolo.');
        }
      } else {
        setErro('Protocolo não encontrado em nosso sistema.');
      }
    } catch (err) {
      console.error(err);
      setErro('Erro ao conectar com o servidor. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  // --- VIEW: BUSCA (Quando não há ocorrência carregada) ---
  if (!ocorrencia) {
    return (
      <div className="min-h-[80vh] flex items-center justify-center px-4 py-12 bg-slate-50">
        <Helmet>
          <meta name="robots" content="noindex, nofollow" />
        </Helmet>
        
        <FadeIn>
          <div className="max-w-md w-full bg-white rounded-3xl shadow-xl shadow-slate-200/60 p-8 border border-slate-100">
            <div className="text-center mb-8">
              <div className="w-16 h-16 bg-orange-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">🔎</span>
              </div>
              <h2 className="text-2xl font-bold text-slate-800">Acompanhar Ocorrência</h2>
              <p className="text-slate-500 text-sm mt-2">Insira os dados enviados para o seu WhatsApp</p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1 ml-1">Número do Protocolo</label>
                <input 
                  type="text"
                  placeholder="ID da ocorrência" 
                  className="w-full h-14 px-4 bg-slate-50 border-2 border-slate-100 rounded-xl focus:border-orange-500 focus:bg-white transition-all outline-none"
                  value={protocolo}
                  onChange={(e) => setProtocolo(e.target.value)}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1 ml-1">Código PIN</label>
                <input 
                  type="text"
                  placeholder="6 dígitos" 
                  className="w-full h-14 px-4 bg-slate-50 border-2 border-slate-100 rounded-xl focus:border-orange-500 focus:bg-white transition-all outline-none text-center font-mono text-xl tracking-widest"
                  maxLength={6}
                  value={codigo}
                  onChange={(e) => setCodigo(e.target.value)}
                />
              </div>

              <button 
                onClick={() => buscarStatus(protocolo, codigo)}
                disabled={loading}
                className="w-full h-14 bg-slate-900 text-white rounded-xl font-bold hover:bg-orange-600 transition-all shadow-lg disabled:opacity-50"
              >
                {loading ? 'Consultando...' : 'VERIFICAR STATUS'}
              </button>

              {erro && (
                <p className="text-red-500 text-center text-sm font-medium bg-red-50 py-2 rounded-lg animate-shake">
                  ⚠️ {erro}
                </p>
              )}
            </div>

            <div className="mt-8 text-center">
               <Link to="/registrar" className="text-sm text-slate-400 hover:text-orange-500 transition-colors">
                 Não registrou ainda? <span className="underline">Criar ocorrência</span>
               </Link>
            </div>
          </div>
        </FadeIn>
      </div>
    );
  }

  // --- VIEW: RESULTADO (Quando a ocorrência foi encontrada) ---
  const statusConfig = {
    pending: { color: 'bg-amber-100 text-amber-700', label: 'Pendente', icon: '⏳' },
    in_progress: { color: 'bg-blue-100 text-blue-700', label: 'Em Atendimento', icon: '🐕' },
    resolved: { color: 'bg-emerald-100 text-emerald-700', label: 'Concluído', icon: '✅' }
  };

  return (
    <div className="min-h-screen bg-slate-50 py-12 px-4">
      <Helmet>
        <meta name="robots" content="noindex, nofollow" />
      </Helmet>

      <FadeIn>
        <div className="max-w-2xl mx-auto space-y-6">
          {/* Card Principal */}
          <div className="bg-white rounded-3xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="p-6 md:p-8">
              <div className="flex justify-between items-start mb-6">
                <div>
                  <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${statusConfig[ocorrencia.status].color}`}>
                    {statusConfig[ocorrencia.status].icon} {statusConfig[ocorrencia.status].label}
                  </span>
                  <h1 className="text-2xl font-bold text-slate-800 mt-3">{ocorrencia.type}</h1>
                  <p className="text-slate-500 flex items-center gap-1 mt-1">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /></svg>
                    {ocorrencia.location}
                  </p>
                </div>
              </div>

              {/* Timeline de Progresso */}
              <div className="py-8 border-y border-slate-50">
                <h3 className="text-sm font-bold text-slate-400 uppercase tracking-widest mb-8">Linha do Tempo</h3>
                <div className="relative pl-8 space-y-10">
                  <div className="absolute left-[11px] top-2 bottom-2 w-0.5 bg-slate-100"></div>

                  <TimelineItem 
                    label="Ocorrência Registrada" 
                    desc="Recebemos sua denúncia e ela está na fila de triagem." 
                    active={true} 
                    completed={ocorrencia.status !== 'pending'} 
                  />
                  <TimelineItem 
                    label="Equipe em Campo" 
                    desc="Nossos voluntários ou órgãos parceiros foram acionados." 
                    active={ocorrencia.status === 'in_progress' || ocorrencia.status === 'resolved'} 
                    completed={ocorrencia.status === 'resolved'} 
                  />
                  <TimelineItem 
                    label="Caso Finalizado" 
                    desc="O atendimento foi concluído e registrado no sistema." 
                    active={ocorrencia.status === 'resolved'} 
                    completed={ocorrencia.status === 'resolved'} 
                  />
                </div>
              </div>

              {/* Detalhes e Feedback */}
              <div className="mt-8 space-y-6">
                <div>
                  <h4 className="font-bold text-slate-800 mb-2">Sua Descrição:</h4>
                  <p className="text-slate-600 text-sm leading-relaxed bg-slate-50 p-4 rounded-xl italic">
                    "{ocorrencia.description}"
                  </p>
                </div>

                {ocorrencia.adminFeedback && (
                  <div className="bg-orange-50 p-5 rounded-2xl border border-orange-100">
                    <h4 className="text-orange-800 font-bold mb-1 flex items-center gap-2">
                      <span>📢</span> Resposta da Equipe Patinhas e Amor:
                    </h4>
                    <p className="text-orange-900 text-sm">
                      {ocorrencia.adminFeedback}
                    </p>
                  </div>
                )}
              </div>
            </div>

            <div className="bg-slate-50 px-8 py-4 flex justify-between items-center">
               <button 
                onClick={() => setOcorrencia(null)} 
                className="text-slate-400 text-xs font-bold hover:text-slate-600 transition-colors uppercase tracking-widest"
              >
                ← Nova Consulta
              </button>
              <p className="text-[10px] text-slate-300 font-mono">ID: {protocolo}</p>
            </div>
          </div>

          <div className="text-center">
            <Link to="/" className="text-sm font-medium text-slate-400 hover:text-orange-500 transition-colors">
              Voltar para a página inicial
            </Link>
          </div>
        </div>
      </FadeIn>
    </div>
  );
};

// Sub-componente para os itens da Timeline com estilos aprimorados
const TimelineItem = ({ label, desc, active, completed }: { label: string, desc: string, active: boolean, completed: boolean }) => (
  <div className="relative">
    <div className={`absolute -left-[27px] w-[24px] h-[24px] rounded-full border-4 border-white shadow-sm z-10 transition-colors duration-500
      ${completed ? 'bg-emerald-500' : active ? 'bg-orange-500 ring-4 ring-orange-100' : 'bg-slate-200'}`}>
      {completed && (
        <svg className="w-3 h-3 text-white mx-auto mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={4} d="M5 13l4 4L19 7" />
        </svg>
      )}
    </div>
    <div className={`transition-opacity duration-500 ${active ? 'opacity-100' : 'opacity-30'}`}>
      <p className="font-bold text-sm text-slate-800 leading-none mb-1">{label}</p>
      <p className="text-xs text-slate-500 leading-tight">{desc}</p>
    </div>
  </div>
);

export default Acompanhamento;