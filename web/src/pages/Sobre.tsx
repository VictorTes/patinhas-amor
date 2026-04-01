export function Sobre() {
  // Função para lidar com o clique no WhatsApp
  const handleWhatsAppClick = () => {
    // Substitua pelo número real da ONG (DDI + DDD + Número)
    const phone = "5542999999999"; 
    const message = encodeURIComponent(
      "Olá! Vi o site da Patinhas e Amor e gostaria de saber mais sobre como posso ser um voluntário."
    );
    const url = `https://wa.me/${phone}?text=${message}`;
    
    // Abre o WhatsApp em uma nova aba
    window.open(url, "_blank", "noopener,noreferrer");
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <div className="bg-gradient-to-b from-orange-50 to-white py-16 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <span className="text-orange-600 font-bold uppercase tracking-widest text-sm">
            Nossa Missão
          </span>
          <h1 className="text-4xl md:text-5xl font-extrabold text-slate-800 mt-4 mb-6">
            Transformando vidas, <br /> um latido por vez. 🐾
          </h1>
          <p className="text-lg text-slate-600 leading-relaxed">
            A <strong>Patinhas e Amor</strong> nasceu do sonho de dar uma segunda chance para animais 
            que conheceram apenas o abandono e o frio das ruas.
          </p>
        </div>
      </div>

      {/* Conteúdo Principal */}
      <div className="max-w-4xl mx-auto px-4 py-12">
        <div className="grid md:grid-cols-2 gap-12 items-center mb-20">
          <div>
            <h2 className="text-2xl font-bold text-slate-800 mb-4">Quem Somos?</h2>
            <p className="text-slate-600 mb-4">
              Somos uma organização sem fins lucrativos localizada em <strong>Porto União</strong>, dedicada 
              ao resgate, reabilitação e adoção responsável de cães e gatos.
            </p>
            <p className="text-slate-600">
              Nossa equipe é formada inteiramente por voluntários apaixonados que dedicam 
              seu tempo livre para garantir que cada animal receba cuidados médicos, 
              carinho e, eventualmente, um lar definitivo.
            </p>
          </div>
          <div className="rounded-3xl overflow-hidden shadow-xl rotate-2">
            <img 
              src="https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&q=80&w=800" 
              alt="Cachorros felizes resgatados" 
              className="w-full h-full object-cover"
            />
          </div>
        </div>
      </div>

      {/* Seção Como Ajudar / CTA */}
      <div className="max-w-4xl mx-auto px-4 py-16 text-center border-t border-slate-100">
        <h2 className="text-2xl font-bold text-slate-800 mb-4">Quer fazer parte dessa história?</h2>
        <p className="text-slate-600 mb-8">
          Você pode ajudar sendo um voluntário, doando qualquer valor ou apenas compartilhando 
          nossos animais disponíveis para adoção.
        </p>
        
        {/* Botão com OnClick configurado */}
        <button 
          onClick={handleWhatsAppClick}
          className="bg-orange-500 hover:bg-orange-600 text-white px-10 py-4 rounded-2xl font-bold transition-all shadow-lg shadow-orange-200 hover:scale-105 active:scale-95"
        >
          Quero ser Voluntário
        </button>
      </div>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-400 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <span className="text-2xl">🐾</span>
            <span className="text-xl font-bold text-white">Patinhas e Amor</span>
          </div>
          <p className="text-sm">
            ONG dedicada ao resgate e adoção de animais abandonados em Porto União e região.
          </p>
          <p className="text-sm mt-4 border-t border-slate-800 pt-4">
            © 2026 Patinhas e Amor. Todos os direitos reservados.
          </p>
        </div>
      </footer>
    </div>
  );
}