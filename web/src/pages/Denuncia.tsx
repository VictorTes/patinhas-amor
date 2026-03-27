import { useState } from 'react';
import { Timestamp } from 'firebase/firestore';
import { createOccurrence } from '../services/firestore';
import type { OccurrenceType, OccurrenceStatus } from '../types';

const occurrenceTypes: OccurrenceType[] = ['Bravos', 'Perdidos', 'Maus Tratos', 'Outros'];

export function Denuncia() {
  const [formData, setFormData] = useState({
    type: '' as OccurrenceType | '',
    location: '',
    description: '',
    reporterPhone: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!formData.type) {
      setError('Selecione o tipo de ocorrência');
      return;
    }

    setSubmitting(true);

    try {
      await createOccurrence({
        type: formData.type,
        location: formData.location,
        description: formData.description,
        reporterPhone: formData.reporterPhone,
        status: 'pending' as OccurrenceStatus,
        createdAt: Timestamp.now(),
      });

      setSubmitted(true);
      setFormData({
        type: '',
        location: '',
        description: '',
        reporterPhone: '',
      });
    } catch (err) {
      setError('Erro ao enviar denúncia. Tente novamente.');
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  };

  if (submitted) {
    return (
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-8 rounded-lg text-center">
            <div className="text-5xl mb-4">✅</div>
            <h2 className="text-2xl font-bold mb-2">Denúncia Enviada!</h2>
            <p className="mb-6">
              Obrigado por nos informar. Analisaremos sua denúncia em breve.
            </p>
            <button
              onClick={() => setSubmitted(false)}
              className="bg-primary-600 text-white px-6 py-2 rounded-md hover:bg-primary-700 transition-colors"
            >
              Enviar outra denúncia
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl md:text-4xl font-bold text-gray-800 mb-4">
          🚨 Registrar Ocorrência
        </h1>
        <p className="text-gray-600 mb-8">
          Use este formulário para reportar animais agressivos, perdidos, casos
          de maus tratos ou outras situações que precisam de atenção.
        </p>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow-md">
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tipo de Ocorrência *
            </label>
            <select
              value={formData.type}
              onChange={(e) =>
                setFormData({ ...formData, type: e.target.value as OccurrenceType })
              }
              required
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <option value="">Selecione...</option>
              {occurrenceTypes.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Localização *
            </label>
            <input
              type="text"
              value={formData.location}
              onChange={(e) =>
                setFormData({ ...formData, location: e.target.value })
              }
              placeholder="Endereço ou ponto de referência"
              required
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Descrição *
            </label>
            <textarea
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              placeholder="Descreva detalhadamente o ocorrido..."
              rows={4}
              required
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Seu Telefone *
            </label>
            <input
              type="tel"
              value={formData.reporterPhone}
              onChange={(e) =>
                setFormData({ ...formData, reporterPhone: e.target.value })
              }
              placeholder="(XX) XXXXX-XXXX"
              required
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full bg-red-600 text-white py-3 rounded-md font-semibold hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {submitting ? 'Enviando...' : 'Enviar Denúncia'}
          </button>
        </form>
      </div>
    </div>
  );
}
