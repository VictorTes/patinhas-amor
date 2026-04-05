import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async'; // Importe o Provider
import { Header } from './components/Header';
import { Home } from './pages/Home';
import { Adocao } from './pages/Adocao';
import { Desaparecidos } from './pages/Desaparecidos';
import { RegistrarOcorrencia } from './pages/RegistrarOcorrencia';
import { Sobre } from './pages/Sobre';
import Acompanhamento from './pages/Acompanhamento'; // Importe a nova página
import { ScrollToTop } from './components/ScrollToTop';

function App() {
  return (
    <HelmetProvider> {/* Envolva toda a aplicação aqui */}
      <BrowserRouter>
        <ScrollToTop />
        <div className="min-h-screen bg-gray-50">
          <Header />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/adocao" element={<Adocao />} />
            <Route path="/desaparecidos" element={<Desaparecidos />} />
            <Route path="/registrar-ocorrencia" element={<RegistrarOcorrencia />} />
            <Route path="/acompanhar" element={<Acompanhamento />} />
            <Route path="/sobre" element={<Sobre />} />
          </Routes>
        </div>
      </BrowserRouter>
    </HelmetProvider>
  );
}

export default App;