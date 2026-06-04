import { useState, useRef, type ChangeEvent, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import {
  uploadOccurrenceImage,
  createPendingOccurrence,
  formatPhoneNumber,
  unmaskPhone,
  validateFileSize,
  formatFileSize,
  type OccurrenceFormData,
} from '../services/firebaseService';

import { LocationPicker } from '../components/LocationPicker';
import { FadeIn } from '../components/FadeIn';

export function RegistrarOcorrencia() {
  const [formData, setFormData] = useState({
    fullName: '',
    phone: '',
    type: 'Desaparecido', // Fixo como Desaparecido
    location: '',
    description: '',
    lat: undefined as number | undefined,
    lng: undefined as number | undefined,
  });

  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [uploadProgress, setUploadProgress] = useState<string>('');

  const handlePhoneChange = (e: ChangeEvent<HTMLInputElement>) => {
    const masked = formatPhoneNumber(e.target.value);
    setFormData((prev) => ({ ...prev, phone: masked }));
    if (errors.phone) {
      setErrors((prev) => ({ ...prev, phone: '' }));
    }
  };

  const handleImageChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!validateFileSize(file)) {
      setErrors((prev) => ({
        ...prev,
        image: `Arquivo muito grande (${formatFileSize(file.size)}). Máximo permitido: 2MB`,
      }));
      return;
    }

    if (!file.type.startsWith('image/')) {
      setErrors((prev) => ({ ...prev, image: 'Por favor, selecione uma imagem válida' }));
      return;
    }

    setSelectedFile(file);
    setErrors((prev) => ({ ...prev, image: '' }));

    const reader = new FileReader();
    reader.onloadend = () => {
      setImagePreview(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleRemoveImage = () => {
    setSelectedFile(null);
    setImagePreview(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.fullName.trim()) {
      newErrors.fullName = 'Nome completo é obrigatório';
    }

    if (!formData.phone.trim()) {
      newErrors.phone = 'Telefone é obrigatório';
    } else if (unmaskPhone(formData.phone).length < 10) {
      newErrors.phone = 'Telefone incompleto';
    }

    if (!formData.location.trim()) {
      newErrors.location = 'Localização é obrigatória';
    }

    if (!formData.description.trim()) {
      newErrors.description = 'Descrição é obrigatória';
    } else if (formData.description.length < 10) {
      newErrors.description = 'Descrição muito curta (mínimo 10 caracteres)';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      setTimeout(() => {
        const firstError = document.querySelector('[data-error="true"]');
        firstError?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }, 100);
      return;
    }

    setIsSubmitting(true);
    setUploadProgress('');

    try {
      let imageUrl = '';

      if (selectedFile) {
        setUploadProgress('Enviando foto...');
        imageUrl = await uploadOccurrenceImage(selectedFile);
        setUploadProgress('Foto enviada!');
      }

      const accessCode = Math.floor(100000 + Math.random() * 900000).toString();

      const occurrenceData: OccurrenceFormData = {
        reporterName: formData.fullName.trim(),
        reporterPhone: unmaskPhone(formData.phone),
        type: formData.type, // Sempre será 'Desaparecido'
        location: formData.location.trim(),
        description: formData.description.trim(),
        imageUrl: imageUrl,
        latitude: formData.lat,
        longitude: formData.lng,
        accessCode: accessCode, 
        status: 'pending',
      };

      await createPendingOccurrence(occurrenceData);
      
      setIsSuccess(true);

      setFormData({ 
        fullName: '', 
        phone: '', 
        type: 'Desaparecido', 
        location: '', 
        description: '',
        lat: undefined,
        lng: undefined
      });
      setSelectedFile(null);
      setImagePreview(null);
    } catch (error) {
      console.error('Erro ao enviar:', error);
      setErrors((prev) => ({
        ...prev,
        submit: error instanceof Error ? error.message : 'Erro ao enviar. Tente novamente.',
      }));
    } finally {
      setIsSubmitting(false);
      setUploadProgress('');
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 ">
      {/* Header Fixo */}
      <div className="bg-white border-b border-slate-100 sticky top-16 z-30">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <FadeIn>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                <span className="text-2xl">🔍</span>
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-800">Animal Desaparecido</h1>
                <p className="text-sm text-slate-500">Solicite a divulgação na rede</p>
              </div>
            </div>
          </FadeIn>
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-4 py-6">
        {errors.submit && (
          <FadeIn>
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 flex items-center gap-2">
              <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {errors.submit}
            </div>
          </FadeIn>
        )}

        {!isSuccess && (
          <FadeIn>
            <form onSubmit={handleSubmit} className="space-y-5">
              
              {/* Mensagem Explicativa */}
              <div className="p-4 bg-blue-50 border border-blue-100 rounded-xl flex items-start gap-3 animate-in fade-in slide-in-from-top-2 duration-300">
                <span className="text-xl">ℹ️</span>
                <p className="text-sm text-blue-800 leading-relaxed">
                  Caso queira que divulguemos o animal desaparecido, preencha os dados abaixo. É importante informar na descrição: <strong>cor do pelo, se usava coleira, o nome do animal e o horário/local aproximado do último avistamento</strong>.
                </p>
              </div>

              {/* Nome Completo */}
              <div data-error={!!errors.fullName}>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Seu Nome Completo <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formData.fullName}
                  onChange={(e) => {
                    setFormData((prev) => ({ ...prev, fullName: e.target.value }));
                    if (errors.fullName) setErrors((prev) => ({ ...prev, fullName: '' }));
                  }}
                  placeholder="Ex: João da Silva"
                  className={`w-full h-14 px-4 text-base rounded-xl border-2 transition-all duration-200
                    ${errors.fullName ? 'border-red-300 bg-red-50' : 'border-slate-200 focus:border-orange-500 focus:ring-4 focus:ring-orange-100'}
                  `}
                />
                {errors.fullName && <p className="mt-1 text-sm text-red-500">{errors.fullName}</p>}
              </div>

              {/* Telefone */}
              <div data-error={!!errors.phone}>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Seu Telefone / WhatsApp <span className="text-red-500">*</span>
                </label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={handlePhoneChange}
                  placeholder="(00) 00000-0000"
                  maxLength={16}
                  className={`w-full h-14 px-4 text-base rounded-xl border-2 transition-all duration-200
                    ${errors.phone ? 'border-red-300 bg-red-50' : 'border-slate-200 focus:border-orange-500 focus:ring-4 focus:ring-orange-100'}
                  `}
                />
                {errors.phone && <p className="mt-1 text-sm text-red-500">{errors.phone}</p>}
              </div>

              {/* Localização */}
              <div data-error={!!errors.location} className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-2">
                    Localização do desaparecimento (Endereço ou Referência) <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <input
                      type="text"
                      value={formData.location}
                      onChange={(e) => {
                        setFormData((prev) => ({ ...prev, location: e.target.value }));
                        if (errors.location) setErrors((prev) => ({ ...prev, location: '' }));
                      }}
                      placeholder="Rua, bairro ou ponto de referência onde sumiu"
                      className={`w-full h-14 px-4 pl-12 text-base rounded-xl border-2 transition-all duration-200
                        ${errors.location ? 'border-red-300 bg-red-50' : 'border-slate-200 focus:border-orange-500 focus:ring-4 focus:ring-orange-100'}
                      `}
                    />
                    <div className="absolute left-4 top-1/2 -translate-y-1/2">
                      <svg className="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      </svg>
                    </div>
                  </div>
                  {errors.location && <p className="mt-1 text-sm text-red-500">{errors.location}</p>}
                </div>

                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
                    <label className="block text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                      <span className="text-orange-500">📍</span> Selecionar ponto exato no mapa <span className="text-slate-400 font-normal text-xs">(Opcional)</span>
                    </label>
                    <LocationPicker 
                      onLocationSelect={(lat, lng) => setFormData(prev => ({ ...prev, lat, lng }))} 
                    />
                    <p className="mt-2 text-[11px] text-slate-400 italic">
                      Dica: Se quiser, toque no mapa para marcar o local exato do último avistamento.
                    </p>
                </div>
              </div>

              {/* Descrição */}
              <div data-error={!!errors.description}>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Descrição Detalhada do Animal <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => {
                    setFormData((prev) => ({ ...prev, description: e.target.value }));
                    if (errors.description) setErrors((prev) => ({ ...prev, description: '' }));
                  }}
                  placeholder="Nome do animal, raça aparente, porte, cor da pelagem, usava coleira? Alguma marca característica?"
                  rows={5}
                  className={`w-full px-4 py-3 text-base rounded-xl border-2 transition-all duration-200 resize-none
                    ${errors.description ? 'border-red-300 bg-red-50' : 'border-slate-200 focus:border-orange-500 focus:ring-4 focus:ring-orange-100'}
                  `}
                />
                {errors.description && <p className="mt-1 text-sm text-red-500">{errors.description}</p>}
              </div>

              {/* Foto */}
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Foto do Animal <span className="text-slate-400 font-normal">(Altamente recomendado)</span>
                </label>

                {!imagePreview ? (
                  <div
                    onClick={() => fileInputRef.current?.click()}
                    className={`w-full h-32 border-2 border-dashed rounded-xl flex flex-col items-center justify-center cursor-pointer transition-all duration-200
                      ${errors.image ? 'border-red-300 bg-red-50' : 'border-slate-300 bg-slate-50 hover:border-orange-400 hover:bg-orange-50'}
                    `}
                  >
                    <svg className="w-10 h-10 text-slate-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span className="text-sm text-slate-600 font-medium">Toque para adicionar foto</span>
                  </div>
                ) : (
                  <div className="relative rounded-xl overflow-hidden shadow-md">
                    <img src={imagePreview} alt="Preview" className="w-full h-48 object-cover" />
                    <button
                      type="button"
                      onClick={handleRemoveImage}
                      className="absolute top-2 right-2 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center text-slate-600 hover:text-red-500 transition-colors"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                )}

                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleImageChange}
                  className="hidden"
                />
              </div>

              {/* Botão de Envio */}
              <div className="pt-4">
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full h-14 bg-gradient-to-r from-orange-500 to-orange-600 text-white rounded-xl font-bold text-lg shadow-lg shadow-orange-200 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-3 active:scale-[0.98] transition-all duration-200"
                >
                  {isSubmitting ? (
                    <>
                      <svg className="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                      </svg>
                      {uploadProgress || 'Enviando...'}
                    </>
                  ) : (
                    <>
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                      </svg>
                      Solicitar Divulgação
                    </>
                  )}
                </button>
              </div>
            </form>
          </FadeIn>
        )}

        {/* Modal de Sucesso */}
        {isSuccess && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <FadeIn>
              <div className="bg-white rounded-3xl shadow-2xl p-8 max-w-md w-full text-center border border-slate-100">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
                  <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                
                <h2 className="text-2xl font-bold text-slate-800 mb-4">Enviado com Sucesso!</h2>
                
                <p className="text-slate-600 mb-8 leading-relaxed">
                  Sua solicitação de divulgação foi registrada e será analisada pela nossa equipe em breve.
                </p>

                <div className="space-y-3">
                  <Link
                    to="/"
                    className="block w-full bg-gradient-to-r from-orange-500 to-orange-600 text-white py-4 rounded-xl font-bold shadow-lg shadow-orange-200 hover:scale-[1.02] active:scale-[0.98] transition-all"
                  >
                    Voltar ao Início
                  </Link>
                </div>
              </div>
            </FadeIn>
          </div>
        )}
      </div>

      <footer className="bg-slate-900 text-slate-400 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <FadeIn direction="up">
            <div className="flex items-center justify-center gap-2 mb-4">
              <span className="text-2xl">🐾</span>
              <span className="text-xl font-bold text-white">Patinhas & Amor</span>
            </div>
            <a
              href="https://www.instagram.com/patinhaseamorgemeasdoiguacu"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-sm text-white hover:text-pink-500 transition-colors mb-6"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect>
                <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path>
                <line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line>
              </svg>
              Siga-nos no Instagram
            </a>

            <p className="text-sm">ONG dedicada ao resgate e adoção de animais abandonados.</p>
            <p className="text-sm mt-2">© 2026 Patinhas & Amor. Porto União - SC.</p>
          </FadeIn>
        </div>
      </footer>
    </div>
  );
}