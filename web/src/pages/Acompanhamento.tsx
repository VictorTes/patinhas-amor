import { useState, useEffect } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../config/firebase';
import { useSearchParams } from 'react-router-dom';

const Acompanhamento = () => {
  const [searchParams] = useSearchParams();
  const [protocolo, setProtocolo] = useState('');
  const [codigo, setCodigo] = useState('');
  const [loading, setLoading] = useState(false);
  const [ocorrencia, setOcorrencia] = useState<any>(null);
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

  const buscarStatus = async (p: string, c: string) => {
    setLoading(true);
    setErro('');
    try {
      // Busca na coleção de pendentes ou na principal
      let docRef = doc(db, "pending_occurrences", p);
      let docSnap = await getDoc(docRef);

      if (!docSnap.exists()) {
        docRef = doc(db, "occurrences", p);
        docSnap = await getDoc(docRef);
      }

      if (docSnap.exists()) {
        const data = docSnap.data();
        // Validação do Código de Acesso
        if (data.accessCode === c) {
          setOcorrencia(data);
        } else {
          setErro('Código de acesso incorreto.');
        }
      } else {
        setErro('Protocolo não encontrado.');
      }
    } catch (err) {
      setErro('Erro ao buscar informações.');
    } finally {
      setLoading(false);
    }
  };

  // --- COMPONENTE DE BUSCA ---
  if (!ocorrencia) {
    return (
      <div className="max-w-md mx-auto p-6 bg-white rounded-xl shadow-lg mt-10">
        <h2 className="text-2xl font-bold text-orange-500 mb-6 text-center">Acompanhar Ocorrência</h2>
        <div className="space-y-4">
          <input 
            placeholder="Número do Protocolo" 
            className="w-full p-3 border rounded-lg"
            value={protocolo}
            onChange={(e) => setProtocolo(e.target.value)}
          />
          <input 
            placeholder="Código de Acesso (6 dígitos)" 
            className="w-full p-3 border rounded-lg"
            maxLength={6}
            value={codigo}
            onChange={(e) => setCodigo(e.target.value)}
          />
          <button 
            onClick={() => buscarStatus(protocolo, codigo)}
            disabled={loading}
            className="w-full bg-orange-500 text-white p-3 rounded-lg font-bold hover:bg-orange-600 transition"
          >
            {loading ? 'Buscando...' : 'VERIFICAR STATUS'}
          </button>
          {erro && <p className="text-red-500 text-center text-sm">{erro}</p>}
        </div>
      </div>
    );
  }

  // --- COMPONENTE DE RESULTADO (VISÃO DO CIDADÃO) ---
  const statusColors: any = {
    pending: 'bg-red-100 text-red-600',
    in_progress: 'bg-blue-100 text-blue-600',
    resolved: 'bg-green-100 text-green-600'
  };

  const statusLabels: any = {
    pending: 'Pendente',
    in_progress: 'Em Curso',
    resolved: 'Concluído'
  };

  return (
    <div className="max-w-2xl mx-auto p-4 md:p-8 space-y-6">
      {/* Cabeçalho */}
      <header className="flex justify-between items-start">
        <div>
          <h1 className="text-xl font-bold text-gray-800">{ocorrencia.type}</h1>
          <p className="text-gray-500">{ocorrencia.location}</p>
        </div>
        <span className={`px-4 py-2 rounded-full font-bold text-xs uppercase ${statusColors[ocorrencia.status]}`}>
          {statusLabels[ocorrencia.status]}
        </span>
      </header>

      {/* Timeline Virtual baseada no Status */}
      <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
        <h3 className="font-bold mb-6">Progresso da Ocorrência</h3>
        <div className="relative pl-8 space-y-8">
          {/* Linha Vertical Cinza de Fundo */}
          <div className="absolute left-[15px] top-2 bottom-2 w-0.5 bg-gray-200"></div>

          <TimelineItem 
            label="Recebido" 
            desc="Sua denúncia foi registrada com sucesso." 
            active={true} 
            completed={ocorrencia.status !== 'pending'} 
          />
          <TimelineItem 
            label="Em Atendimento" 
            desc="Nossa equipe está trabalhando neste caso." 
            active={ocorrencia.status === 'in_progress' || ocorrencia.status === 'resolved'} 
            completed={ocorrencia.status === 'resolved'} 
          />
          <TimelineItem 
            label="Finalizado" 
            desc="O caso foi encerrado pela ONG." 
            active={ocorrencia.status === 'resolved'} 
            completed={ocorrencia.status === 'resolved'} 
          />
        </div>
      </div>

      {/* Descrição/Feedback do Admin */}
      <div className="bg-orange-50 p-6 rounded-2xl border border-orange-100">
        <h3 className="text-orange-700 font-bold mb-2">Mensagem da Equipe:</h3>
        <p className="text-orange-900 italic text-sm">
          "{ocorrencia.description || 'Aguardando atualização dos moderadores.'}"
        </p>
      </div>

      <button onClick={() => setOcorrencia(null)} className="text-gray-400 text-sm hover:underline">
        Fazer nova busca
      </button>
    </div>
  );
};

// Sub-componente para os itens da Timeline
const TimelineItem = ({ label, desc, active, completed }: any) => (
  <div className="relative">
    <div className={`absolute -left-[25px] w-[18px] h-[18px] rounded-full border-4 border-white shadow-sm z-10
      ${completed ? 'bg-green-500' : active ? 'bg-blue-500 animate-pulse' : 'bg-gray-300'}`}>
    </div>
    <div className={active ? 'opacity-100' : 'opacity-40'}>
      <p className="font-bold text-sm text-gray-800">{label}</p>
      <p className="text-xs text-gray-500">{desc}</p>
    </div>
  </div>
);

export default Acompanhamento;