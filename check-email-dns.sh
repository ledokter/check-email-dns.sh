#!/bin/bash

###############################################################################
# Email DNS Authentication Checker
# Vérifie les enregistrements DNS d'authentification email (SPF, DKIM, DMARC, MX)
# Pour diagnostiquer les problèmes de délivrabilité et de sécurité
###############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Banner
cat << "EOF"
 _____                 _ _   ____  _   _ ____  
| ____|_ __ ___   __ _(_) | |  _ \| \ | / ___| 
|  _| | '_ ` _ \ / _` | | | | | | |  \| \___ \ 
| |___| | | | | | (_| | | | | |_| | |\  |___) |
|_____|_| |_| |_|\__,_|_|_| |____/|_| \_|____/ 
                                                
   Authentication Checker v1.0
EOF

print_header "EMAIL DNS AUTHENTICATION CHECKER"

# === VÉRIFICATION DES DÉPENDANCES ===

echo ""
echo -e "${YELLOW}Vérification des dépendances...${NC}"

if ! command -v dig &> /dev/null; then
    print_error "dig n'est pas installé (requis pour les requêtes DNS)"
    echo ""
    echo "Installation :"
    echo "  • Debian/Ubuntu : sudo apt install dnsutils -y"
    echo "  • CentOS/RHEL   : sudo yum install bind-utils -y"
    echo "  • macOS         : dig est préinstallé"
    exit 1
fi

print_success "dig est installé"

# === CONFIGURATION INTERACTIVE ===

echo ""
print_header "CONFIGURATION"

# Domaine à analyser
echo ""
if [ -n "$1" ]; then
    DOMAIN="$1"
    print_info "Domaine fourni en argument : $DOMAIN"
else
    read -p "Nom de domaine à analyser (ex: example.com) : " DOMAIN
fi

if [ -z "$DOMAIN" ]; then
    print_error "Le nom de domaine est obligatoire"
    exit 1
fi

# Nettoyer le domaine (supprimer http://, www., etc.)
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||' | sed 's|^www\.||' | awk -F'/' '{print $1}')

print_success "Domaine : $DOMAIN"

# Sélecteurs DKIM
echo ""
echo -e "${YELLOW}Sélecteurs DKIM à vérifier :${NC}"
echo ""
echo "Les sélecteurs DKIM varient selon le provider email."
echo "Exemples courants :"
echo "  • Google Workspace    : google"
echo "  • Office 365          : selector1, selector2"
echo "  • Mailgun             : mailo, k1"
echo "  • SendGrid            : s1, s2"
echo "  • Amazon SES          : amazonses"
echo "  • OVH                 : ovh"
echo ""
read -p "Sélecteur DKIM principal [google] : " DKIM_SELECTOR
DKIM_SELECTOR=${DKIM_SELECTOR:-google}

read -p "Sélecteur DKIM secondaire (optionnel, Entrée pour passer) : " DKIM_SELECTOR2

# Serveur DNS personnalisé
echo ""
read -p "Serveur DNS personnalisé (optionnel, ex: 8.8.8.8) [défaut système] : " DNS_SERVER

# Format de sortie
echo ""
echo -e "${YELLOW}Format de sortie :${NC}"
echo "  1) Affichage terminal (coloré)"
echo "  2) Export fichier texte"
echo "  3) Les deux"
read -p "Sélectionnez [1] : " OUTPUT_MODE
OUTPUT_MODE=${OUTPUT_MODE:-1}

OUTPUT_FILE=""
if [ "$OUTPUT_MODE" -eq 2 ] || [ "$OUTPUT_MODE" -eq 3 ]; then
    OUTPUT_FILE="dns_check_${DOMAIN}_$(date +%Y%m%d_%H%M%S).txt"
    print_info "Rapport sera sauvegardé dans : $OUTPUT_FILE"
fi

# === FONCTIONS D'ANALYSE ===

# Fonction pour exécuter dig
run_dig() {
    local query=$1
    local type=${2:-TXT}
    
    if [ -n "$DNS_SERVER" ]; then
        dig @"$DNS_SERVER" +short "$query" "$type" 2>/dev/null
    else
        dig +short "$query" "$type" 2>/dev/null
    fi
}

# Fonction pour afficher et sauvegarder
output() {
    local message="$1"
    
    if [ "$OUTPUT_MODE" -eq 1 ] || [ "$OUTPUT_MODE" -eq 3 ]; then
        echo -e "$message"
    fi
    
    if [ "$OUTPUT_MODE" -eq 2 ] || [ "$OUTPUT_MODE" -eq 3 ]; then
        echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT_FILE"
    fi
}

# === ANALYSE DNS ===

print_header "ANALYSE DES ENREGISTREMENTS DNS"

# Initialiser le fichier de sortie
if [ -n "$OUTPUT_FILE" ]; then
    cat > "$OUTPUT_FILE" << EOF
═══════════════════════════════════════════════════════════════
 RAPPORT D'ANALYSE DNS - AUTHENTIFICATION EMAIL
═══════════════════════════════════════════════════════════════

Domaine analysé  : $DOMAIN
Date du rapport  : $(date '+%d/%m/%Y %H:%M:%S')
Serveur DNS      : $([ -n "$DNS_SERVER" ] && echo "$DNS_SERVER" || echo "Système")

═══════════════════════════════════════════════════════════════

EOF
fi

# === 1. SPF (Sender Policy Framework) ===

echo ""
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output "${CYAN}📧 SPF (Sender Policy Framework)${NC}"
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output ""
output "${BLUE}Rôle :${NC} Définit quels serveurs peuvent envoyer des emails pour votre domaine"
output ""

SPF_RECORD=$(run_dig "$DOMAIN" TXT | grep "v=spf1")

if [ -n "$SPF_RECORD" ]; then
    output "${GREEN}✅ Enregistrement SPF trouvé :${NC}"
    output "   $SPF_RECORD"
    output ""
    
    # Analyse du SPF
    if echo "$SPF_RECORD" | grep -q "~all"; then
        output "${YELLOW}   Politique : SoftFail (~all) - Emails suspects marqués${NC}"
    elif echo "$SPF_RECORD" | grep -q "-all"; then
        output "${GREEN}   Politique : Fail (-all) - Emails non autorisés rejetés (recommandé)${NC}"
    elif echo "$SPF_RECORD" | grep -q "\\+all"; then
        output "${RED}   ⚠️  Politique : Pass (+all) - DANGEREUX ! Tous les serveurs autorisés${NC}"
    elif echo "$SPF_RECORD" | grep -q "?all"; then
        output "${YELLOW}   Politique : Neutral (?all) - Aucune politique appliquée${NC}"
    fi
    
    # Compter les includes
    INCLUDE_COUNT=$(echo "$SPF_RECORD" | grep -o "include:" | wc -l)
    if [ "$INCLUDE_COUNT" -gt 10 ]; then
        output "${RED}   ⚠️  Attention : $INCLUDE_COUNT includes détectés (limite recommandée : 10)${NC}"
    fi
else
    output "${RED}❌ Aucun enregistrement SPF trouvé${NC}"
    output "${YELLOW}   Impact : Vos emails risquent d'être marqués comme spam ou rejetés${NC}"
    output "${CYAN}   Solution : Ajoutez un enregistrement TXT SPF à votre DNS${NC}"
fi

# === 2. DKIM (DomainKeys Identified Mail) ===

echo ""
output ""
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output "${CYAN}🔐 DKIM (DomainKeys Identified Mail)${NC}"
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output ""
output "${BLUE}Rôle :${NC} Signe cryptographiquement vos emails pour prouver leur authenticité"
output ""

DKIM_FOUND=0

# Vérifier le sélecteur principal
output "${YELLOW}Vérification du sélecteur : ${DKIM_SELECTOR}${NC}"
DKIM_RECORD=$(run_dig "${DKIM_SELECTOR}._domainkey.${DOMAIN}" TXT)

if [ -n "$DKIM_RECORD" ]; then
    output "${GREEN}✅ Enregistrement DKIM trouvé (${DKIM_SELECTOR}) :${NC}"
    output "   ${DKIM_RECORD:0:80}..."
    output ""
    
    # Analyser la clé
    if echo "$DKIM_RECORD" | grep -q "k=rsa"; then
        output "${GREEN}   Type de clé : RSA${NC}"
    fi
    
    if echo "$DKIM_RECORD" | grep -q "p="; then
        KEY_LENGTH=$(echo "$DKIM_RECORD" | grep -o "p=[^;]*" | wc -c)
        if [ "$KEY_LENGTH" -lt 200 ]; then
            output "${YELLOW}   ⚠️  Clé courte détectée (considérez 2048 bits minimum)${NC}"
        else
            output "${GREEN}   Longueur de clé : OK${NC}"
        fi
    fi
    
    DKIM_FOUND=1
else
    output "${RED}❌ Aucun enregistrement DKIM trouvé pour le sélecteur '${DKIM_SELECTOR}'${NC}"
fi

# Vérifier le sélecteur secondaire si fourni
if [ -n "$DKIM_SELECTOR2" ]; then
    output ""
    output "${YELLOW}Vérification du sélecteur : ${DKIM_SELECTOR2}${NC}"
    DKIM_RECORD2=$(run_dig "${DKIM_SELECTOR2}._domainkey.${DOMAIN}" TXT)
    
    if [ -n "$DKIM_RECORD2" ]; then
        output "${GREEN}✅ Enregistrement DKIM trouvé (${DKIM_SELECTOR2}) :${NC}"
        output "   ${DKIM_RECORD2:0:80}..."
        DKIM_FOUND=1
    else
        output "${RED}❌ Aucun enregistrement DKIM trouvé pour le sélecteur '${DKIM_SELECTOR2}'${NC}"
    fi
fi

if [ $DKIM_FOUND -eq 0 ]; then
    output ""
    output "${YELLOW}   Impact : Impossible de vérifier l'authenticité de vos emails${NC}"
    output "${CYAN}   Solution : Configurez DKIM chez votre provider email${NC}"
fi

# === 3. DMARC (Domain-based Message Authentication) ===

echo ""
output ""
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output "${CYAN}🛡️  DMARC (Domain-based Message Authentication)${NC}"
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output ""
output "${BLUE}Rôle :${NC} Définit la politique si SPF ou DKIM échouent + rapports d'abus"
output ""

DMARC_RECORD=$(run_dig "_dmarc.${DOMAIN}" TXT)

if [ -n "$DMARC_RECORD" ]; then
    output "${GREEN}✅ Enregistrement DMARC trouvé :${NC}"
    output "   $DMARC_RECORD"
    output ""
    
    # Analyser la politique
    if echo "$DMARC_RECORD" | grep -q "p=none"; then
        output "${YELLOW}   Politique : none (surveillance uniquement, aucune action)${NC}"
        output "${CYAN}   Recommandation : Passez à 'quarantine' ou 'reject' pour plus de sécurité${NC}"
    elif echo "$DMARC_RECORD" | grep -q "p=quarantine"; then
        output "${GREEN}   Politique : quarantine (emails suspects mis en spam)${NC}"
    elif echo "$DMARC_RECORD" | grep -q "p=reject"; then
        output "${GREEN}   Politique : reject (emails suspects rejetés) ✨ Recommandé${NC}"
    fi
    
    # Vérifier les rapports
    if echo "$DMARC_RECORD" | grep -q "rua="; then
        RUA=$(echo "$DMARC_RECORD" | grep -o "rua=[^;]*" | sed 's/rua=//')
        output "${GREEN}   Rapports agrégés : $RUA${NC}"
    else
        output "${YELLOW}   ⚠️  Aucun email de rapport configuré (rua)${NC}"
    fi
    
    if echo "$DMARC_RECORD" | grep -q "ruf="; then
        RUF=$(echo "$DMARC_RECORD" | grep -o "ruf=[^;]*" | sed 's/ruf=//')
        output "${GREEN}   Rapports forensiques : $RUF${NC}"
    fi
    
    # Vérifier le pourcentage
    if echo "$DMARC_RECORD" | grep -q "pct="; then
        PCT=$(echo "$DMARC_RECORD" | grep -o "pct=[0-9]*" | sed 's/pct=//')
        output "${CYAN}   Pourcentage appliqué : ${PCT}%${NC}"
    fi
else
    output "${RED}❌ Aucun enregistrement DMARC trouvé${NC}"
    output "${YELLOW}   Impact : Votre domaine peut être usurpé pour du phishing${NC}"
    output "${CYAN}   Solution : Ajoutez un enregistrement TXT _dmarc à votre DNS${NC}"
fi

# === 4. MX Records (Mail Exchange) ===

echo ""
output ""
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output "${CYAN}📬 MX (Mail Exchange Records)${NC}"
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output ""
output "${BLUE}Rôle :${NC} Définit les serveurs qui reçoivent vos emails"
output ""

MX_RECORDS=$(run_dig "$DOMAIN" MX)

if [ -n "$MX_RECORDS" ]; then
    output "${GREEN}✅ Enregistrements MX trouvés :${NC}"
    output ""
    
    MX_COUNT=0
    while IFS= read -r mx; do
        MX_COUNT=$((MX_COUNT + 1))
        PRIORITY=$(echo "$mx" | awk '{print $1}')
        SERVER=$(echo "$mx" | awk '{print $2}')
        output "   [$MX_COUNT] Priorité $PRIORITY : $SERVER"
        
        # Détecter le provider
        if echo "$SERVER" | grep -q "google"; then
            output "       ${CYAN}→ Provider : Google Workspace${NC}"
        elif echo "$SERVER" | grep -q "outlook\\|office365"; then
            output "       ${CYAN}→ Provider : Microsoft 365${NC}"
        elif echo "$SERVER" | grep -q "ovh"; then
            output "       ${CYAN}→ Provider : OVH${NC}"
        elif echo "$SERVER" | grep -q "mail\\.protection\\.outlook"; then
            output "       ${CYAN}→ Provider : Microsoft Exchange Online${NC}"
        fi
    done <<< "$MX_RECORDS"
    
    output ""
    output "${GREEN}   Total : $MX_COUNT serveur(s) de messagerie${NC}"
    
    if [ "$MX_COUNT" -eq 1 ]; then
        output "${YELLOW}   ⚠️  Un seul serveur MX (considérez un backup pour la redondance)${NC}"
    fi
else
    output "${RED}❌ Aucun enregistrement MX trouvé${NC}"
    output "${YELLOW}   Impact : Vous ne pouvez PAS recevoir d'emails à ce domaine${NC}"
    output "${CYAN}   Solution : Configurez des enregistrements MX chez votre provider${NC}"
fi

# === SCORE GLOBAL ===

echo ""
output ""
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output "${CYAN}📊 SCORE DE SÉCURITÉ EMAIL${NC}"
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output ""

SCORE=0
MAX_SCORE=4

[ -n "$SPF_RECORD" ] && SCORE=$((SCORE + 1))
[ $DKIM_FOUND -eq 1 ] && SCORE=$((SCORE + 1))
[ -n "$DMARC_RECORD" ] && SCORE=$((SCORE + 1))
[ -n "$MX_RECORDS" ] && SCORE=$((SCORE + 1))

output "Configuration : $SCORE/$MAX_SCORE"
output ""

if [ $SCORE -eq 4 ]; then
    output "${GREEN}✅ EXCELLENT : Toutes les protections sont en place !${NC}"
elif [ $SCORE -eq 3 ]; then
    output "${YELLOW}⚠️  BON : Il manque une protection, vérifiez ci-dessus${NC}"
elif [ $SCORE -eq 2 ]; then
    output "${YELLOW}⚠️  MOYEN : Plusieurs protections manquantes${NC}"
elif [ $SCORE -eq 1 ]; then
    output "${RED}❌ FAIBLE : Configuration email très incomplète${NC}"
else
    output "${RED}❌ CRITIQUE : Aucune protection configurée !${NC}"
fi

# === RÉSUMÉ ET RECOMMANDATIONS ===

echo ""
output ""
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output "${CYAN}💡 RECOMMANDATIONS${NC}"
output "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
output ""

if [ -z "$SPF_RECORD" ]; then
    output "${RED}1. Configurer SPF${NC}"
    output "   Exemple : v=spf1 include:_spf.google.com ~all"
    output ""
fi

if [ $DKIM_FOUND -eq 0 ]; then
    output "${RED}2. Configurer DKIM${NC}"
    output "   Contactez votre provider email pour obtenir les enregistrements DKIM"
    output ""
fi

if [ -z "$DMARC_RECORD" ]; then
    output "${RED}3. Configurer DMARC${NC}"
    output "   Exemple : v=DMARC1; p=quarantine; rua=mailto:dmarc@$DOMAIN"
    output ""
fi

if [ -z "$MX_RECORDS" ]; then
    output "${RED}4. Configurer MX${NC}"
    output "   Configurez vos serveurs de messagerie dans les DNS"
    output ""
fi

output "${CYAN}📚 Ressources utiles :${NC}"
output "   • Test en ligne : https://mxtoolbox.com/dmarc.aspx"
output "   • Générateur SPF : https://www.spfwizard.net/"
output "   • Documentation : https://dmarc.org/"
output ""

# === FIN ===

print_header "✨ ANALYSE TERMINÉE"

echo ""
print_success "Analyse DNS terminée pour : $DOMAIN"

if [ -n "$OUTPUT_FILE" ]; then
    echo ""
    print_success "Rapport sauvegardé : $OUTPUT_FILE"
    echo ""
    echo "Pour consulter le rapport :"
    echo "  cat $OUTPUT_FILE"
    echo "  less $OUTPUT_FILE"
fi

echo ""
print_info "Pour tester l'envoi d'emails : https://www.mail-tester.com/"
echo ""
