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

const occurrenceTypes = [
  { value: '', label: 'Selecione o tipo' },
  { value: 'Desaparecido', label: '🔍 Animal Desaparecido' },
  { value: 'Abandono', label: '🚷 Abandono' },
  { value: 'Maus Tratos', label: '🚨 Maus Tratos' },
  { value: 'Animal Ferido', label: '🩹 Animal Ferido' },
  { value: 'Outro', label: '📝 Outros' },
];

export function RegistrarOcorrencia() {
  const [formData, setFormData] = useState({
    fullName: '',
    phone: '',
    type: '',
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
  const [successData, setSuccessData] = useState({ protocol: '', code: '' }); // Para o modal
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

    if (!formData.type) {
      newErrors.type = 'Selecione o tipo de ocorrência';
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

  const handleShareWhatsapp = () => {
    const baseUrl = window.location.origin;
    const trackingLink = `${baseUrl}/acompanhar?p=${successData.protocol}&c=${successData.code}`;
    
    const message = `🐾 *Patinhas e Amor - Ocorrência Registrada*\n\nOlá! Salve estes dados para acompanhar sua denúncia:\n\n📍 *Protocolo:* ${successData.protocol}\n🔑 *Código:* ${successData.code}\n\n🔗 *Acompanhe aqui:* ${trackingLink}`;

    window.open(`https://wa.me/?text=${encodeURIComponent(message)}`, '_blank');
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

      // Gera o código de acesso de 6 dígitos
      const accessCode = Math.floor(100000 + Math.random() * 900000).toString();

      const occurrenceData: OccurrenceFormData = {
        reporterName: formData.fullName.trim(),
        reporterPhone: unmaskPhone(formData.phone),
        type: formData.type,
        location: formData.location.trim(),
        description: formData.description.trim(),
        imageUrl: imageUrl,
        latitude: formData.lat,
        longitude: formData.lng,
        accessCode: accessCode, // Adicionado ao envio
        status: 'pending',
      };

      const docId = await createPendingOccurrence(occurrenceData);
      
      setSuccessData({ protocol: docId, code: accessCode });
      setIsSuccess(true);

      // Limpa os campos
      setFormData({ 
        fullName: '', 
        phone: '', 
        type: '', 
        location: '', 
        description: '',
        lat: undefined,
        lng: undefined
      });
      setSelectedFile(null);
      setImagePreview(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
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
      <div className="bg-white border-b border-slate-100 sticky top-16 z-30">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <FadeIn>
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
                <span className="text-2xl">🚨</span>
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-800">Registrar Ocorrência</h1>
                <p className="text-sm text-slate-500">Ajude um animal em risco</p>
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

              <div data-error={!!errors.type}>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  O que aconteceu? <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <select
                    value={formData.type}
                    onChange={(e) => {
                      setFormData((prev) => ({ ...prev, type: e.target.value }));
                      if (errors.type) setErrors((prev) => ({ ...prev, type: '' }));
                    }}
                    className={`w-full h-14 px-4 text-base rounded-xl border-2 appearance-none transition-all duration-200 bg-white
                      ${errors.type ? 'border-red-300 bg-red-50' : 'border-slate-200 focus:border-orange-500 focus:ring-4 focus:ring-orange-100'}
                    `}
                  >
                    {occurrenceTypes.map((type) => (
                      <option key={type.value} value={type.value}>{type.label}</option>
                    ))}
                  </select>
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </div>

                {formData.type === 'Desaparecido' && (
                  <div className="mt-3 p-4 bg-blue-50 border border-blue-100 rounded-xl flex items-start gap-3 animate-in fade-in slide-in-from-top-2 duration-300">
                    <span className="text-xl">ℹ️</span>
                    <p className="text-sm text-blue-800 leading-relaxed">
                      Para <strong>Animais Desaparecidos</strong>, por favor, informe na descrição: 
                      cor do pelo, se usava coleira, nome do animal e o horário aproximado em que foi visto pela última vez.
                    </p>
                  </div>
                )}
              </div>

              <div data-error={!!errors.location} className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-2">
                    Localização (Endereço ou Referência) <span className="text-red-500">*</span>
                  </label>
                  <div className="relative">
                    <input
                      type="text"
                      value={formData.location}
                      onChange={(e) => {
                        setFormData((prev) => ({ ...prev, location: e.target.value }));
                        if (errors.location) setErrors((prev) => ({ ...prev, location: '' }));
                      }}
                      placeholder="Rua, bairro ou ponto de referência"
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
                      <span className="text-orange-500">📍</span> Selecionar ponto exato no mapa
                    </label>
                    <LocationPicker 
                      onLocationSelect={(lat, lng) => setFormData(prev => ({ ...prev, lat, lng }))} 
                    />
                    <p className="mt-2 text-[11px] text-slate-400 italic">
                      Dica: Toque no mapa para marcar o local exato ou use o botão de GPS acima do mapa.
                    </p>
                </div>
              </div>

              <div data-error={!!errors.description}>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Descrição Detalhada <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => {
                    setFormData((prev) => ({ ...prev, description: e.target.value }));
                    if (errors.description) setErrors((prev) => ({ ...prev, description: '' }));
                  }}
                  placeholder="Descreva a situação, estado do animal e detalhes relevantes..."
                  rows={5}
                  className={`w-full px-4 py-3 text-base rounded-xl border-2 transition-all duration-200 resize-none
                    ${errors.description ? 'border-red-300 bg-red-50' : 'border-slate-200 focus:border-orange-500 focus:ring-4 focus:ring-orange-100'}
                  `}
                />
                {errors.description && <p className="mt-1 text-sm text-red-500">{errors.description}</p>}
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Foto do Local / Animal <span className="text-slate-400 font-normal">(opcional)</span>
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
                      Enviar Ocorrência
                    </>
                  )}
                </button>
              </div>
            </form>
          </FadeIn>
        )}

        {/* Modal de Sucesso Atualizado */}
        {isSuccess && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <FadeIn>
              <div className="bg-white rounded-3xl shadow-2xl p-8 max-w-md w-full text-center border border-slate-100">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                
                <h2 className="text-2xl font-bold text-slate-800 mb-2">Denúncia Enviada!</h2>
                
                <div className="bg-slate-50 rounded-2xl p-4 mb-6 border border-slate-100">
                   <p className="text-[10px] text-slate-400 uppercase font-bold tracking-wider mb-1">Seus dados de acesso</p>
                   <div className="flex justify-around items-center">
                      <div>
                        <p className="text-xs text-slate-500">Protocolo</p>
                        <p className="font-mono font-bold text-slate-800">{successData.protocol.slice(0, 8)}...</p>
                      </div>
                      <div className="w-px h-8 bg-slate-200"></div>
                      <div>
                        <p className="text-xs text-slate-500">Código PIN</p>
                        <p className="font-mono font-bold text-orange-600 text-lg">{successData.code}</p>
                      </div>
                   </div>
                </div>

                <p className="text-sm text-slate-500 mb-6 leading-relaxed">
                  Para sua segurança, salve o link de acompanhamento no seu WhatsApp. Assim você não perde o código!
                </p>

                <div className="space-y-3">
                  <button
                    onClick={handleShareWhatsapp}
                    className="w-full bg-[#25D366] text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 shadow-lg shadow-green-100 active:scale-95 transition-transform"
                  >
                    <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                       <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L0 24l6.335-1.662c1.72 1.025 3.69 1.566 5.71 1.567h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                    </svg>
                    Salvar no WhatsApp
                  </button>

                  <Link
                    to="/"
                    className="block w-full bg-slate-100 text-slate-600 py-4 rounded-xl font-bold hover:bg-slate-200 transition-colors"
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
              <span className="text-xl font-bold text-white">Patinhas e Amor</span>
            </div>
            <p className="text-sm">ONG dedicada ao resgate e adoção de animais abandonados.</p>
            <p className="text-sm mt-2">© 2026 Patinhas e Amor. Porto União - SC.</p>
          </FadeIn>
        </div>
      </footer>
    </div>
  );
}