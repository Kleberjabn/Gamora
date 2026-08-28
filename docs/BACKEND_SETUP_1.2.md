# GamoraVet 1.2 — configuração do backend

## Objetivo
Conectar o aplicativo a um backend Supabase/PostgreSQL sem armazenar segredos privilegiados no APK ou no repositório.

## Princípios
- Usuários reais são gerenciados pelo provedor de autenticação.
- O aplicativo móvel pode receber somente URL pública do projeto e chave pública/publicável apropriada ao cliente.
- Nunca colocar `service_role`, senha do banco, private key ou segredo administrativo no Android, HTML/JavaScript ou GitHub público.
- RLS deve permanecer habilitado nas tabelas com dados de usuários.
- Autorizações Tutor ↔ Clínica são verificadas no servidor, não apenas na interface.
- Revogação deve bloquear novas leituras no servidor.
- Auditoria privilegiada deve ser gravada por função/backend confiável.

## Preparação já criada
A migration `supabase/migrations/20260828_001_secure_foundation.sql` cria:
- perfis;
- pets e tutores/cuidadores;
- organizações/clínicas e membros;
- autorizações de compartilhamento;
- eventos de consentimento;
- auditoria;
- solicitações de privacidade;
- funções auxiliares e políticas RLS iniciais.

## Antes de produção
1. Revisar o modelo com profissional de privacidade/LGPD e jurídico aplicável ao negócio.
2. Definir controlador, operadores, encarregado/canal de privacidade e política de retenção.
3. Configurar ambiente separado de desenvolvimento/homologação/produção.
4. Ativar confirmação de e-mail e recuperação de conta.
5. Avaliar MFA para contas de clínica/profissionais.
6. Configurar backups, logs, alertas, rate limits e monitoramento.
7. Executar testes automatizados de RLS para tentativas de acesso entre tutores, clínicas e pets não autorizados.
8. Criar processo de resposta a incidentes e solicitações de titulares.

## Próxima conexão com Android
O Android deve receber configuração pública por build config/variáveis de ambiente e chamar apenas endpoints sujeitos a autenticação/RLS. Segredos administrativos permanecem exclusivamente no backend/Secret Manager.
