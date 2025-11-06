require_relative '../config/database'
require_relative '../lib/models/contact'
require_relative '../lib/models/interaction'
require_relative '../lib/knowledge/vector_store'
require_relative '../lib/knowledge/embedding_service'

Database.setup

puts "🌱 Seeding database..."
puts "=" * 60

vector_store = VectorStore.new

puts "\n1. Creating contacts..."

contacts_data = [
  {
    name: 'Dr. João Silva',
    email: 'joao.silva@clinicaexample.com',
    company: 'Clínica Odontológica Sorriso Perfeito',
    status: 'contacted'
  },
  {
    name: 'Dra. Maria Santos',
    email: 'maria.santos@dentalsmile.com',
    company: 'Dental Smile Clínica',
    status: 'qualified'
  },
  {
    name: 'Dr. Pedro Oliveira',
    email: 'pedro.oliveira@odontocenter.com',
    company: 'OdontoCenter',
    status: 'new'
  },
  {
    name: 'Dra. Ana Costa',
    email: 'ana.costa@clinicahealthy.com',
    company: 'Clínica Healthy Teeth',
    status: 'contacted'
  },
  {
    name: 'Dr. Carlos Ferreira',
    email: 'carlos.ferreira@smiledental.com',
    company: 'Smile Dental Care',
    status: 'converted'
  }
]

contacts = []
contacts_data.each do |data|
  contact = Contact.new(data)
  contact_id = contact.save
  contacts << contact
  puts "  ✓ Created contact: #{contact.name} (ID: #{contact_id})"
end

puts "\n2. Creating interactions..."

interactions_data = [
  {
    contact: contacts[0],
    message: 'Olá, gostaria de conhecer mais sobre os serviços de gestão para clínicas odontológicas.',
    response: 'Olá Dr. João! Fico feliz em ajudar. Nossos serviços são ideais para clínicas odontológicas como a Sorriso Perfeito. Posso agendar uma apresentação?',
    summary: 'Cliente interessado em serviços de gestão para clínica, aguardando apresentação'
  },
  {
    contact: contacts[0],
    message: 'Sim, podemos agendar para próxima semana.',
    response: 'Perfeito! Vou enviar um convite para você escolher o melhor horário. Prefere segunda ou terça-feira?',
    summary: 'Agendamento confirmado para próxima semana'
  },
  {
    contact: contacts[1],
    message: 'Quais são as formas de pagamento disponíveis para o sistema de gestão?',
    response: 'Olá Dra. Maria! Oferecemos várias opções: boleto, cartão de crédito em até 12x, e PIX com desconto. Qual prefere?',
    summary: 'Cliente interessado em formas de pagamento'
  },
  {
    contact: contacts[2],
    message: 'Preciso de uma solução de gestão para minha clínica odontológica.',
    response: 'Olá Dr. Pedro! Temos planos especiais para clínicas odontológicas. Vou enviar uma proposta personalizada para a OdontoCenter.',
    summary: 'Cliente interessado em solução de gestão personalizada para clínica'
  },
  {
    contact: contacts[3],
    message: 'Gostaria de saber mais sobre o suporte técnico do sistema.',
    response: 'Olá Dra. Ana! Nosso suporte técnico funciona 24/7 com especialistas dedicados. Inclui chat, email e telefone para ajudar sua clínica.',
    summary: 'Cliente interessado em suporte técnico'
  },
  {
    contact: contacts[4],
    message: 'Quero fechar o contrato para minha clínica.',
    response: 'Excelente Dr. Carlos! Vou preparar a documentação e enviar para sua aprovação. Obrigado pela confiança na Smile Dental Care!',
    summary: 'Cliente pronto para fechar contrato'
  }
]

interactions_data.each do |data|
  interaction = Interaction.new(
    contact_id: data[:contact].id,
    message: data[:message],
    response: data[:response],
    context_summary: data[:summary]
  )
  interaction_id = interaction.save
  data[:contact].update_last_contact
  puts "  ✓ Created interaction for #{data[:contact].name} (ID: #{interaction_id})"
end

puts "\n3. Adding knowledge to vector store..."

knowledge_data = [
  {
    content: 'Nossos serviços de gestão são ideais para clínicas odontológicas que buscam soluções escaláveis e confiáveis. Oferecemos suporte 24/7 e atualizações constantes. Inclui gestão de pacientes, agendamento, prontuário eletrônico e controle financeiro.',
    metadata: { type: 'documentation', category: 'services' }
  },
  {
    content: 'Formas de pagamento: Boleto bancário, Cartão de crédito em até 12x sem juros, PIX com 5% de desconto, e Transferência bancária. Oferecemos desconto especial para clínicas que fecham contrato anual.',
    metadata: { type: 'faq', category: 'payment' }
  },
  {
    content: 'Suporte técnico disponível 24 horas por dia, 7 dias por semana. Canais: Chat online, Email suporte@example.com, Telefone (11) 3000-0000. Especialistas em sistemas para clínicas odontológicas.',
    metadata: { type: 'documentation', category: 'support' }
  },
  {
    content: 'Planos para clínicas odontológicas incluem desconto de 30% no primeiro ano, período de teste gratuito de 30 dias, e consultoria gratuita para implementação e treinamento da equipe.',
    metadata: { type: 'policy', category: 'clinics' }
  },
  {
    content: 'Processo de contratação: 1) Proposta comercial personalizada, 2) Aprovação da proposta, 3) Assinatura do contrato, 4) Ativação do sistema em até 48h, 5) Treinamento da equipe da clínica.',
    metadata: { type: 'documentation', category: 'sales' }
  },
  {
    content: 'Nossos clientes incluem grandes clínicas odontológicas como Sorriso Perfeito, Dental Smile, e Smile Dental Care. Todas relatam satisfação com o suporte, qualidade do sistema e aumento na produtividade da clínica.',
    metadata: { type: 'documentation', category: 'testimonials' }
  },
  {
    content: 'Funcionalidades do sistema: Agendamento online, Prontuário eletrônico odontológico, Controle financeiro, Gestão de pacientes, Emissão de recibos e notas fiscais, Relatórios gerenciais, Integração com aparelhos de radiografia digital.',
    metadata: { type: 'documentation', category: 'features' }
  },
  {
    content: 'Sistema desenvolvido especialmente para clínicas odontológicas, com interface intuitiva e fácil de usar. Compatível com dispositivos móveis para acesso em qualquer lugar. Conformidade com LGPD e normas do Conselho Regional de Odontologia.',
    metadata: { type: 'documentation', category: 'system' }
  }
]

knowledge_data.each_with_index do |data, index|
  begin
    doc_id = vector_store.add_document(data[:content], data[:metadata])
    if doc_id
      puts "  ✓ Added knowledge document (ID: #{doc_id})"
    else
      puts "  ⚠ Skipped knowledge document (API keys may be required)"
    end
  rescue => e
    error_msg = e.message.downcase
    if error_msg.include?('api') || error_msg.include?('401') || error_msg.include?('key')
      puts "  ⚠ Skipped knowledge document (API keys required for embeddings)"
    else
      puts "  ✗ Error adding knowledge: #{e.message}"
    end
  end
end

puts "\n" + "=" * 60
puts "✅ Database seeded successfully!"
puts ""
puts "Summary:"
puts "  - Contacts: #{contacts.length}"
puts "  - Interactions: #{interactions_data.length}"
puts "  - Knowledge documents: #{knowledge_data.length}"
puts ""

