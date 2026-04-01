import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

export function ScrollToTop() {
  const { pathname } = useLocation();

  useEffect(() => {
    // Rola para a coordenada (0, 0) - topo esquerdo - toda vez que o caminho muda
    window.scrollTo({
      top: 0,
      left: 0,
      behavior: 'instant' // 'instant' garante que ele não "deslize", evitando o efeito visual de rolagem
    });
  }, [pathname]);

  return null; // Este componente não renderiza nada na tela, apenas executa a lógica
}