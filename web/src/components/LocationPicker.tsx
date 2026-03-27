import { useState } from 'react';
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from 'react-leaflet';
import L from 'leaflet';

// Corrigindo o ícone padrão do Leaflet que as vezes quebra no React
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

const DefaultIcon = L.icon({
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});
L.Marker.prototype.options.icon = DefaultIcon;

interface LocationPickerProps {
  onLocationSelect: (lat: number, lng: number) => void;
}

export function LocationPicker({ onLocationSelect }: LocationPickerProps) {
  const [position, setPosition] = useState<L.LatLng | null>(null);

  // Componente interno para lidar com cliques no mapa
  function MapEvents() {
    useMapEvents({
      click(e) {
        setPosition(e.latlng);
        onLocationSelect(e.latlng.lat, e.latlng.lng);
      },
    });
    return position === null ? null : <Marker position={position} />;
  }

  // Componente para centralizar o mapa quando pegar o GPS
  function ChangeView({ center }: { center: L.LatLng }) {
    const map = useMap();
    map.setView(center, 16);
    return null;
  }

  const handleGetCurrentLocation = () => {
    if (!navigator.geolocation) {
      alert("Geolocalização não suportada pelo seu navegador.");
      return;
    }

    navigator.geolocation.getCurrentPosition((pos) => {
      const { latitude, longitude } = pos.coords;
      const latlng = L.latLng(latitude, longitude);
      setPosition(latlng);
      onLocationSelect(latitude, longitude);
    });
  };

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <span className="text-xs text-slate-500 uppercase font-bold tracking-wider">Pin no Mapa</span>
        <button
          type="button"
          onClick={handleGetCurrentLocation}
          className="text-xs bg-orange-50 text-orange-600 px-3 py-1.5 rounded-lg font-bold hover:bg-orange-100 transition-colors flex items-center gap-1"
        >
          📍 Usar minha localização atual
        </button>
      </div>
      
      <div className="h-64 w-full rounded-xl overflow-hidden border-2 border-slate-200 z-0">
        <MapContainer
          center={[-26.23, -51.08]} // Coordenadas iniciais (Porto União como exemplo)
          zoom={13}
          style={{ height: '100%', width: '100%' }}
        >
          <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
          <MapEvents />
          {position && <ChangeView center={position} />}
        </MapContainer>
      </div>
      
      {position && (
        <p className="text-[10px] text-slate-400 text-center">
          Coordenadas: {position.lat.toFixed(5)}, {position.lng.toFixed(5)}
        </p>
      )}
    </div>
  );
}