import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Header } from './components/Header';
import { Home } from './pages/Home';
import { Adocao } from './pages/Adocao';
import { Desaparecidos } from './pages/Desaparecidos';
import { RegistrarOcorrencia } from './pages/RegistrarOcorrencia';

function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-50">
        <Header />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/adocao" element={<Adocao />} />
          <Route path="/desaparecidos" element={<Desaparecidos />} />
          <Route path="/registrar-ocorrencia" element={<RegistrarOcorrencia />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default App;
