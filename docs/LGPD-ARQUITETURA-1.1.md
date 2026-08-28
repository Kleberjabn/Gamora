# GamoraVet 1.1 — Arquitetura de contas, privacidade e compartilhamento

> Documento de engenharia e governança. Não substitui parecer jurídico. Textos finais, bases legais e contratos devem ser revisados por profissional jurídico antes da produção.

## 1. Princípios

- Privacidade e segurança desde a concepção e por padrão.
- Minimização: coletar apenas o necessário para finalidades declaradas.
- Transparência: explicar finalidade, compartilhamentos, retenção e direitos em linguagem clara.
- Controle de acesso composto por autenticação, autorização e auditoria.
- Segregação entre contas, organizações e pets.
- Nenhuma senha é armazenada em texto puro no app ou no banco.
- Segredos de infraestrutura nunca ficam no APK nem no repositório público.

## 2. Perfis

### Tutor / Cuidador
Pode criar conta, gerenciar seus pets, convidar cuidadores, autorizar ou revogar compartilhamentos com clínicas e consultar registros de acesso relevantes.

### Clínica / Profissional
A clínica é uma organização. Usuários da clínica possuem papéis próprios (administrador, veterinário, atendimento e estoque/dispensação). O acesso aos dados de um pet exige vínculo válido e autorização/base legal aplicável. Um funcionário não herda acesso irrestrito apenas por pertencer à clínica.

## 3. Autenticação

Produção deve usar provedor de autenticação seguro, com:
- e-mail verificado;
- senha tratada pelo provedor com hash forte;
- recuperação de senha por link/token de uso limitado;
- sessões revogáveis;
- proteção contra tentativas abusivas;
- MFA disponível para contas de clínica/administrativas;
- biometria do aparelho apenas como mecanismo local de desbloqueio, nunca como substituto da identidade no servidor.

## 4. Autorização

Modelo RBAC + regras por recurso:
- usuário só lê/escreve recursos autorizados;
- pet possui relação explícita com tutor(es)/cuidador(es);
- clínica possui membros e papéis;
- compartilhamento liga pet + clínica + categorias permitidas + finalidade + vigência;
- políticas no banco/API impedem acesso cruzado entre usuários/organizações.

Categorias inicialmente compartilháveis:
- dados básicos do pet;
- consultas;
- medicamentos/tratamentos;
- vacinas e antiparasitários;
- exames;
- documentos/receitas;
- histórico de saúde.

## 5. Compartilhamento e consentimento

O produto não usará um aceite genérico de “LGPD”. Cada operação deverá ter finalidade e hipótese legal documentadas.

Quando a operação depender de consentimento, registrar:
- titular/usuário que manifestou a decisão;
- pet e clínica destinatária;
- categorias autorizadas;
- finalidade informada;
- versão do aviso apresentado;
- data/hora;
- estado: concedido, alterado ou revogado;
- data/hora da revogação quando aplicável.

A tela deverá permitir negar categorias não necessárias e revogar autorização de forma acessível. A revogação bloqueia novos acessos dependentes daquele consentimento, sem apagar automaticamente registros cuja conservação tenha outra justificativa legal aplicável.

## 6. Direitos e privacidade

Área “Privacidade e dados” deverá oferecer:
- visualizar dados da conta;
- corrigir dados editáveis;
- consultar compartilhamentos ativos;
- revogar autorizações;
- solicitar exportação/portabilidade quando aplicável;
- solicitar exclusão da conta/dados, sujeita a retenções legalmente justificadas;
- canal de contato para direitos de titular e privacidade.

## 7. Auditoria

Eventos relevantes devem gerar trilha append-only contendo, conforme aplicável:
- identificador do ator;
- organização;
- ação;
- recurso/pet afetado;
- data/hora;
- resultado da operação;
- origem técnica necessária para segurança.

Não registrar senha, token de sessão, conteúdo secreto ou dados desnecessários nos logs.

## 8. Modelo inicial de dados

- users
- profiles
- pets
- pet_guardians
- organizations
- organization_members
- sharing_grants
- sharing_grant_categories
- consent_events
- consultations
- medications
- medication_administrations
- vaccines
- exams
- documents
- audit_events
- privacy_requests

Todos os registros de domínio devem ter identificadores não previsíveis, timestamps e regras de ownership/tenant.

## 9. Fluxo Tutor ↔ Clínica

1. Tutor ou clínica inicia convite usando identificador seguro/link temporário/QR.
2. Sistema mostra identidade da clínica e finalidade.
3. Tutor escolhe o pet e visualiza as categorias solicitadas.
4. Tutor concede apenas o que deseja/é aplicável.
5. Servidor cria grant e registra o evento/versionamento do aviso.
6. Clínica passa a ver somente os recursos permitidos.
7. Tutor pode consultar e revogar o grant.
8. Toda alteração relevante fica auditada.

## 10. Produção

Antes do lançamento:
- definir formalmente controlador(es), operador(es) e responsabilidades;
- inventário de tratamento e bases legais por finalidade;
- política de privacidade e termos revisados juridicamente;
- contratos com fornecedores e clínicas, incluindo segurança e compartilhamento;
- política de retenção e descarte;
- procedimento de incidentes de segurança;
- canal de atendimento aos titulares;
- avaliação da necessidade de RIPD conforme risco e orientação/regulamentação aplicável;
- testes de segurança e autorização antes da publicação.

## 11. Regra para o MVP 1.1

A interface de login/consentimento pode ser demonstrada localmente, mas NÃO será apresentada como autenticação real até estar ligada ao backend seguro. Dados de produção e compartilhamento real só serão habilitados após autenticação, autorização server-side e políticas de banco estarem implantadas.
