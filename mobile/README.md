# Patinhas e Amor – Animal Rescue Platform

## 🐾 Sobre o projeto

O **Patinhas e Amor – Animal Rescue Platform** é um sistema digital desenvolvido para auxiliar a ONG **Patinhas e Amor** na gestão de denúncias de abandono ou maus-tratos de animais, bem como na organização de animais resgatados e no incentivo à adoção responsável.

A plataforma conecta a comunidade e a ONG através de duas interfaces principais:

* **Plataforma Web Pública** – onde cidadãos podem registrar ocorrências e visualizar animais disponíveis para adoção.
* **Aplicativo Mobile (Flutter)** – utilizado pela ONG para gerenciar denúncias, acompanhar ocorrências e cadastrar animais resgatados.

O objetivo é organizar as informações de forma estruturada, evitando a perda de denúncias recebidas por redes sociais ou mensagens informais, além de facilitar o processo de adoção.

---

## 🎯 Problema

Muitas organizações de resgate animal recebem denúncias de abandono ou maus-tratos por diversos canais, como redes sociais, mensagens privadas ou aplicativos de conversa. Isso dificulta a organização das ocorrências, o acompanhamento dos casos e o registro histórico das ações realizadas.

Além disso, a divulgação de animais disponíveis para adoção nem sempre é centralizada, reduzindo a visibilidade dos animais resgatados.

---

## 💡 Solução

A plataforma propõe uma solução digital simples e organizada que permite:

* registro estruturado de denúncias pela comunidade
* armazenamento das ocorrências em banco de dados
* visualização e gerenciamento das denúncias pela ONG
* cadastro de animais resgatados
* divulgação pública de animais disponíveis para adoção

As solicitações de adoção são realizadas diretamente via **WhatsApp**, utilizando mensagens automáticas geradas pelo sistema para facilitar o contato com a ONG.

---

## 🏗️ Arquitetura do sistema

```text
Usuário (Plataforma Web)
        ↓
       API
        ↓
  Banco de Dados
        ↑
App Flutter (ONG)
```

---

## 🌐 Funcionalidades da plataforma web

* Registro de ocorrências (abandono, maus-tratos ou animais feridos)
* Formulário com descrição, localização e contato
* Visualização de animais disponíveis para adoção

---

## 📱 Funcionalidades do aplicativo mobile

* Visualização de denúncias registradas pela comunidade
* Atualização do status das ocorrências (pendente, em atendimento, resolvido)
* Cadastro de animais resgatados
* Gerenciamento das informações de resgate

---

## 🧰 Tecnologias utilizadas

**Frontend Web**

* React

**Mobile**

* Flutter
* Dart

**Backend**

* Node.js
* API REST

**Banco de dados**

* PostgreSQL

---

## 🎓 Contexto acadêmico

Este projeto foi desenvolvido como parte de um **projeto de extensão universitária**, com o objetivo de aplicar conhecimentos em desenvolvimento de software para resolver um problema real enfrentado por uma organização de proteção animal.

---

## ❤️ Impacto social

A plataforma busca facilitar a comunicação entre a comunidade e a ONG **Patinhas e Amor**, permitindo respostas mais rápidas a denúncias de maus-tratos ou abandono e aumentando a visibilidade dos animais disponíveis para adoção.

---

