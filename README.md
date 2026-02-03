# 📧 Email DNS Authentication Checker

Script Bash pour **vérifier la configuration DNS de l'authentification email** d'un domaine. Analyse SPF, DKIM, DMARC et MX records pour diagnostiquer les problèmes de délivrabilité et de sécurité.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)

## 🎯 Pourquoi Utiliser Ce Script ?

### Problèmes Détectés

- ❌ **Emails en spam** → Vérifiez SPF/DKIM/DMARC
- ❌ **Emails rejetés** → Vérifiez les enregistrements MX
- ❌ **Phishing avec votre domaine** → DMARC manquant
- ❌ **Configuration après migration** → Validation complète
- ❌ **Audit de sécurité email** → Score global

## 🔐 Enregistrements DNS Vérifiés

### 1. SPF (Sender Policy Framework)

**Rôle** : Définit quels serveurs peuvent envoyer des emails pour votre domaine

**Exemple** :
v=spf1 include:_spf.google.com include:mailgun.org ~all

text

**Ce que ça signifie** :
- `include:_spf.google.com` → Google Workspace autorisé
- `include:mailgun.org` → Mailgun autorisé
- `~all` → Autres serveurs = suspect (SoftFail)

**Sans SPF** : Vos emails vont en spam ❌

### 2. DKIM (DomainKeys Identified Mail)

**Rôle** : Signe cryptographiquement vos emails avec une clé privée

**Exemple** :
v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN...

text

**Ce que ça signifie** :
- Chaque email est signé avec une clé secrète
- Le destinataire vérifie avec la clé publique dans le DNS
- Prouve que l'email n'a pas été modifié

**Sans DKIM** : Impossible de prouver l'authenticité ❌

### 3. DMARC (Domain-based Message Authentication)

**Rôle** : Combine SPF + DKIM et définit la politique en cas d'échec

**Exemple** :
v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; pct=100

text

**Politiques** :
- `p=none` → Surveillance uniquement (pas de protection)
- `p=quarantine` → Mettre en spam ⚠️
- `p=reject` → Rejeter l'email ✅ **Recommandé**

**Sans DMARC** : Votre domaine peut être usurpé pour du phishing ❌

### 4. MX (Mail Exchange Records)

**Rôle** : Indique les serveurs qui reçoivent vos emails

**Exemple** :
10 aspmx.l.google.com.
20 alt1.aspmx.l.google.com.

text

**Sans MX** : Vous ne recevez AUCUN email ❌

## 📋 Prérequis

### Système

- **Linux, macOS ou WSL** (Windows Subsystem for Linux)
- **Bash** 4.0+

### Dépendances

#### Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install dnsutils -y
Linux (CentOS/RHEL/Fedora)
bash
sudo yum install bind-utils -y
# Ou
sudo dnf install bind-utils -y
macOS
bash
# dig est préinstallé, rien à installer
Windows (WSL)
bash
# Installer WSL puis :
sudo apt install dnsutils -y
🚀 Installation
Téléchargement Direct
bash
# Télécharger le script
wget https://raw.githubusercontent.com/ledokter/email-dns-checker/main/check-email-dns.sh

# Rendre exécutable
chmod +x check-email-dns.sh
Clone du Dépôt
bash
git clone https://github.com/ledokter/email-dns-checker.git
cd email-dns-checker
chmod +x check-email-dns.sh
💻 Utilisation
Mode Interactif (Recommandé)
bash
./check-email-dns.sh
Le script vous demandera :

Nom de domaine (ex: example.com)

Sélecteur DKIM principal (ex: google pour Google Workspace)

Sélecteur DKIM secondaire (optionnel)

Serveur DNS (optionnel, ex: 8.8.8.8)

Format de sortie (terminal, fichier, ou les deux)

Mode Rapide (Argument)
bash
./check-email-dns.sh example.com
Exemple de Session
text
 _____                 _ _   ____  _   _ ____  
| ____|_ __ ___   __ _(_) | |  _ \| \ | / ___| 
|  _| | '_ ` _ \ / _` | | | | | | |  \| \___ \ 
| |___| | | | | | (_| | | | | |_| | |\  |___) |
|_____|_| |_| |_|\__,_|_|_| |____/|_| \_|____/ 
                                                
   Authentication Checker v1.0

═══════════════════════════════════════════════════════════════
 EMAIL DNS AUTHENTICATION CHECKER
═══════════════════════════════════════════════════════════════

Vérification des dépendances...
✅ dig est installé

═══════════════════════════════════════════════════════════════
 CONFIGURATION
═══════════════════════════════════════════════════════════════

Nom de domaine à analyser (ex: example.com) : monsite.com
✅ Domaine : monsite.com

Sélecteurs DKIM à vérifier :

Les sélecteurs DKIM varient selon le provider email.
Exemples courants :
  -  Google Workspace    : google
  -  Office 365          : selector1, selector2
  -  Mailgun             : mailo, k1
  -  SendGrid            : s1, s2
  -  Amazon SES          : amazonses
  -  OVH                 : ovh

Sélecteur DKIM principal [google] : 
Sélecteur DKIM secondaire (optionnel, Entrée pour passer) : 

Serveur DNS personnalisé (optionnel, ex: 8.8.8.8) [défaut système] : 

Format de sortie :
  1) Affichage terminal (coloré)
  2) Export fichier texte
  3) Les deux
Sélectionnez [1] : 3
ℹ️  Rapport sera sauvegardé dans : dns_check_monsite.com_20260203_041500.txt

═══════════════════════════════════════════════════════════════
 ANALYSE DES ENREGISTREMENTS DNS
═══════════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 SPF (Sender Policy Framework)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rôle : Définit quels serveurs peuvent envoyer des emails pour votre domaine

✅ Enregistrement SPF trouvé :
   v=spf1 include:_spf.google.com ~all

   Politique : SoftFail (~all) - Emails suspects marqués

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 DKIM (DomainKeys Identified Mail)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rôle : Signe cryptographiquement vos emails pour prouver leur authenticité

Vérification du sélecteur : google
✅ Enregistrement DKIM trouvé (google) :
   v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC3QEKyU1fSma...

   Type de clé : RSA
   Longueur de clé : OK

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  DMARC (Domain-based Message Authentication)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rôle : Définit la politique si SPF ou DKIM échouent + rapports d'abus

✅ Enregistrement DMARC trouvé :
   v=DMARC1; p=quarantine; rua=mailto:dmarc@monsite.com

   Politique : quarantine (emails suspects mis en spam)
   Rapports agrégés : mailto:dmarc@monsite.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📬 MX (Mail Exchange Records)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rôle : Définit les serveurs qui reçoivent vos emails

✅ Enregistrements MX trouvés :

   [1] Priorité 1 : aspmx.l.google.com.
       → Provider : Google Workspace
   [2] Priorité 5 : alt1.aspmx.l.google.com.
       → Provider : Google Workspace
   [3] Priorité 10 : alt2.aspmx.l.google.com.
       → Provider : Google Workspace

   Total : 3 serveur(s) de messagerie

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SCORE DE SÉCURITÉ EMAIL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration : 4/4

✅ EXCELLENT : Toutes les protections sont en place !

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 RECOMMANDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Ressources utiles :
   -  Test en ligne : https://mxtoolbox.com/dmarc.aspx
   -  Générateur SPF : https://www.spfwizard.net/
   -  Documentation : https://dmarc.org/

═══════════════════════════════════════════════════════════════
 ✨ ANALYSE TERMINÉE
═══════════════════════════════════════════════════════════════

✅ Analyse DNS terminée pour : monsite.com

✅ Rapport sauvegardé : dns_check_monsite.com_20260203_041500.txt

Pour consulter le rapport :
  cat dns_check_monsite.com_20260203_041500.txt
  less dns_check_monsite.com_20260203_041500.txt

ℹ️  Pour tester l'envoi d'emails : https://www.mail-tester.com/
🔍 Sélecteurs DKIM par Provider
Provider Email	Sélecteurs Courants
Google Workspace	google
Microsoft 365	selector1, selector2
Mailgun	mailo, k1
SendGrid	s1, s2
Amazon SES	amazonses
OVH	ovh
Postmark	pm1, pm2
Mailchimp	k1, k2
Brevo (Sendinblue)	mail
Comment Trouver Votre Sélecteur ?
Consultez la documentation de votre provider email

Cherchez dans votre DNS : dig _domainkey.example.com TXT

Testez les sélecteurs courants avec ce script

📊 Interprétation des Résultats
Score 4/4 : ✅ EXCELLENT
SPF, DKIM, DMARC et MX configurés

Délivrabilité optimale

Protection maximale contre le phishing

Score 3/4 : ⚠️ BON
Une protection manque (généralement DMARC)

Bonne délivrabilité mais sécurité incomplète

Action : Configurez l'enregistrement manquant

Score 2/4 : ⚠️ MOYEN
Plusieurs protections manquantes

Risque élevé de spam et phishing

Action urgente : Configurez SPF, DKIM et DMARC

Score 1/4 : ❌ FAIBLE
Configuration très incomplète

Emails probablement rejetés

Action critique : Configuration complète nécessaire

Score 0/4 : ❌ CRITIQUE
Aucune protection

Le domaine ne peut ni envoyer ni recevoir d'emails correctement

Action immédiate : Configuration urgente

🛠️ Résoudre les Problèmes
SPF Manquant
Ajoutez un enregistrement TXT à votre DNS :

text
Nom    : @  (ou votre domaine)
Type   : TXT
Valeur : v=spf1 include:_spf.google.com ~all
TTL    : 3600
Générateur SPF : https://www.spfwizard.net/

DKIM Manquant
Générez les clés DKIM chez votre provider email

Ajoutez l'enregistrement dans votre DNS

Exemple Google Workspace :

text
Nom    : google._domainkey
Type   : TXT
Valeur : v=DKIM1; k=rsa; p=VOTRE_CLE_PUBLIQUE
TTL    : 3600
DMARC Manquant
Ajoutez un enregistrement TXT :

text
Nom    : _dmarc
Type   : TXT
Valeur : v=DMARC1; p=quarantine; rua=mailto:dmarc@votre-domaine.com
TTL    : 3600
Évolution recommandée :

Commencez par p=none (surveillance)

Passez à p=quarantine (spam)

Finalement p=reject (rejet) après validation

MX Manquants
Configurez vos serveurs de messagerie :

text
Nom    : @  (ou votre domaine)
Type   : MX
Priorité : 10
Valeur : mail.votre-domaine.com
TTL    : 3600
🧪 Tests Complémentaires
Mail-Tester
Testez la qualité de vos emails :

Allez sur : https://www.mail-tester.com/

Envoyez un email à l'adresse fournie

Obtenez un score sur 10

MXToolbox
Tests DNS complets :

https://mxtoolbox.com/SuperTool.aspx

Google Postmaster Tools
Pour surveiller la réputation chez Gmail :

https://postmaster.google.com/

📚 Ressources
Documentation Officielle
RFC 7208 - SPF

RFC 6376 - DKIM

RFC 7489 - DMARC

Outils en Ligne
MXToolbox - Tests DNS complets

DMARC Analyzer - Analyse DMARC

Mail-Tester - Test de qualité email

SPF Wizard - Générateur SPF

Guides
Cloudflare - Email Security

Google - Email Authentication

Microsoft - Email Authentication

🤝 Contribution
Les contributions sont bienvenues !

Fork ce dépôt

Créez une branche : git checkout -b feature/amelioration

Committez : git commit -m "Ajout détection provider X"

Push : git push origin feature/amelioration

Ouvrez une Pull Request

📝 Changelog
v1.0.0 (2026-02-03)
🎉 Version initiale

✨ Vérification SPF, DKIM, DMARC, MX

✨ Configuration interactive

✨ Support multi-sélecteurs DKIM

✨ Export fichier texte

✨ Score de sécurité global

✨ Détection automatique des providers

✨ Recommandations personnalisées

⚖️ Licence
MIT License

📬 Contact
Auteur : ledokter

⭐ Si cet outil vous aide, donnez une étoile au projet !
