export const formatPhoneNumber = (phone: string) => {
  // Remove tudo que não for número
  const cleaned = phone.replace(/\D/g, '');
  
  // Se for o formato padrão Brasil (11 dígitos com DDD)
  // Ex: 41999887766 -> (41) 99988-7766
  const match = cleaned.match(/^(\d{2})(\d{5})(\d{4})$/);
  
  if (match) {
    return `(${match[1]}) ${match[2]}-${match[3]}`;
  }

  // Caso o número venha com o 55 (DDI) no início 
  const matchWithDDI = cleaned.match(/^55(\d{2})(\d{5})(\d{4})$/);
  if (matchWithDDI) {
    return `(${matchWithDDI[1]}) ${matchWithDDI[2]}-${matchWithDDI[3]}`;
  }

  return phone; // Retorna o original se não encaixar no padrão
};