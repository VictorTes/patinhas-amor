export function Sobre() {
  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <div className="bg-gradient-to-b from-orange-50 to-white py-16 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <span className="text-orange-600 font-bold uppercase tracking-widest text-sm">Nossa Missão</span>
          <h1 className="text-4xl md:text-5xl font-extrabold text-slate-800 mt-4 mb-6">
            Transformando vidas, <br />um latido por vez. 🐾
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
              Somos uma organização sem fins lucrativos localizada em Porto União, dedicada 
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
              alt="Cachorros felizes" 
              className="w-full h-full object-cover"
            />
          </div>
        </div>

        {/* Valores/Números */}
        <div className="bg-slate-50 rounded-3xl p-8 md:p-12 grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
          <div>
            <p className="text-3xl font-bold text-orange-600">500+</p>
            <p className="text-sm text-slate-500 font-medium">Resgatados</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-orange-600">420+</p>
            <p className="text-sm text-slate-500 font-medium">Adotados</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-orange-600">15+</p>
            <p className="text-sm text-slate-500 font-medium">Voluntários</p>
          </div>
          <div>
            <p className="text-3xl font-bold text-orange-600">100%</p>
            <p className="text-sm text-slate-500 font-medium">Amor</p>
          </div>
        </div>
      </div>

      {/* Como Ajudar */}
      <div className="max-w-4xl mx-auto px-4 py-16 text-center border-t border-slate-100">
        <h2 className="text-2xl font-bold text-slate-800 mb-4">Quer fazer parte dessa história?</h2>
        <p className="text-slate-600 mb-8">
          Você pode ajudar sendo um voluntário, doando qualquer valor ou apenas compartilhando 
          nossos animais disponíveis para adoção.
        </p>
        <button className="bg-orange-500 hover:bg-orange-600 text-white px-8 py-3 rounded-2xl font-bold transition-all shadow-lg shadow-orange-100">
          Quero ser Voluntário
        </button>
      </div>
    </div>
  );
}