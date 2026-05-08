/**
 * Converte um Timestamp (Firebase), Date ou string em formato brasileiro DD/MM/AAAA
 */
export const formatDate = (dateValue: any): string => {
  if (!dateValue) return "A definir";

  try {
    // Se for um Timestamp do Firebase, ele tem o método .toDate()
    const date = typeof dateValue.toDate === 'function' 
      ? dateValue.toDate() 
      : new Date(dateValue);

    // Verifica se a data é válida antes de formatar
    if (isNaN(date.getTime())) return "Data inválida";

    return new Intl.DateTimeFormat('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(date);
  } catch (error) {
    console.error("Erro ao formatar data:", error);
    return "Erro na data";
  }
};