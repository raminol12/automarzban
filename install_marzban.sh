#!/bin/bash

show_menu() {
    clear
    echo "=== Marzban Installation Menu (Nasb Marzban) ==="
    echo "1) Update Server (Berooz Resani Server)"
    echo "2) Install Certbot & Get SSL (Nasb Certbot va Daryaft SSL)"
    echo "3) Install Marzban (Nasb Marzban)"
    echo "4) Setup SSL Certificates (Tanzim SSL)"
    echo "5) Setup Telegram Bot (Tanzim Bot Telegram)"  # Changed line
    echo "6) Install Template (mrclock) (Nasb Template (mrclock))"
    echo "7) Marzban Backup (Poshtibangiri Marzban)"
    echo "8) Restart Marzban (Restart Kardan Marzban)"
    echo "0) Exit (Khorooj)"
    echo
    read -p "Please enter your choice (Lotfan entekhab konid): " choice
}

update_server() {
    echo "Updating server... (Dar hal berooz resani server...)"
    sudo apt update && sudo apt upgrade -y
}

install_certbot() {
    read -p "Enter your domain (Domain khod ra vared konid): " domain
    echo "Installing Certbot and getting SSL... (Dar hal nasb Certbot va daryaft SSL...)"
    sudo apt-get install certbot -y # Added sudo
    sudo certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$domain" # Added sudo
}

install_marzban() {
    echo "=== Marzban Installation Options (Gozine haye nasb Marzban) ==="
    echo "1) Install with SQLite (Nasb ba SQLite)"
    echo "2) Install with MySQL (Nasb ba MySQL)"
    echo "3) Install with MariaDB (Nasb ba MariaDB)"
    echo "0) Back to main menu (Bazgasht be menu asli)"
    read -p "Choose database type (No'e database ra entekhab konid): " db_choice

    # Corrected curl command (removed backtick)
    curl -sL -o marzban.sh https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh
    chmod +x marzban.sh

    case $db_choice in
        1) sudo ./marzban.sh install ;;
        2) sudo ./marzban.sh install --database mysql ;;
        3) sudo ./marzban.sh install --database mariadb ;;
        0) rm -f marzban.sh; return ;; # Clean up marzban.sh on exit to menu
        *) echo "Invalid choice! (Entekhab eshtebah!)" ;;
    esac

    rm -f marzban.sh
}

setup_ssl() {
    read -p "Enter your domain (Domain khod ra vared konid): " domain
    echo "Setting up SSL certificates... (Dar hal tanzim SSL...)"
    sudo mkdir -p /var/lib/marzban/certs
    sudo cp "/etc/letsencrypt/live/$domain/fullchain.pem" /var/lib/marzban/certs/fullchain.pem
    sudo cp "/etc/letsencrypt/live/$domain/privkey.pem" /var/lib/marzban/certs/privkey.pem

    # Update .env file
    sudo sed -i '11s|.*|UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/fullchain.pem"|' /opt/marzban/.env
    sudo sed -i '12s|.*|UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/privkey.pem"|' /opt/marzban/.env
}

setup_telegram_bot() {
    echo "Setting up Telegram Bot... (Dar hal tanzim Bot Telegram...)"
    read -p "Enter your Telegram API Token (Token API Telegram khod ra vared konid): " telegram_api_token
    read -p "Enter your Telegram Admin ID (Admin ID Telegram khod ra vared konid): " telegram_admin_id

    if [ -z "$telegram_api_token" ] || [ -z "$telegram_admin_id" ]; then
        echo "Telegram API Token and Admin ID cannot be empty. (Token API va Admin ID Telegram nemitavanand khali bashand.)"
        return
    fi

    echo "Updating .env file for Telegram Bot... (Dar hal berooz resani file .env baraye Bot Telegram...)"

    # Delete lines 26 and 27 if they exist
    if sudo grep -q '^TELEGRAM_API_TOKEN =' /opt/marzban/.env || sudo grep -q '^TELEGRAM_ADMIN_ID =' /opt/marzban/.env || [ $(sudo wc -l < /opt/marzban/.env) -ge 26 ]; then
      sudo sed -i -e '26d' -e '26d' /opt/marzban/.env # Delete line 26 twice to effectively delete 26 and original 27
    fi

    # Insert new lines at line 26
    # Create the content to insert
    new_content="TELEGRAM_API_TOKEN = ${telegram_api_token}\nTELEGRAM_ADMIN_ID = ${telegram_admin_id}"
    # Use awk to insert. If line 26 exists, insert before it. Otherwise, append.
    sudo awk -v line_num=26 -v text="$new_content" 'NR==line_num{print text}1' /opt/marzban/.env > /tmp/env_temp && sudo mv /tmp/env_temp /opt/marzban/.env

    echo "Restarting Marzban to apply Telegram Bot settings... (Dar hal restart kardan Marzban baraye اعمال tanzimat Bot Telegram...)"
    sudo marzban restart
    echo "Telegram Bot configured and Marzban restarted. (Bot Telegram tanzim shod va Marzban restart shod.)"
}


restart_marzban() {
    echo "Restarting Marzban... (Dar hal restart kardan Marzban...)"
    sudo marzban restart # Added sudo
}

install_template_mrclock() {
    echo "Installing MrClock template... (Dar hal nasb template MrClock...)"

    # Corrected wget command (removed backtick)
    sudo wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/Mrclocks/MrClock-Subscription-Template/main/index.html
    
    # Update .env file
    # Ensure these lines are added only if they don't already exist to prevent duplicates
    if ! sudo grep -q '^CUSTOM_TEMPLATES_DIRECTORY=' /opt/marzban/.env; then
        echo 'CUSTOM_TEMPLATES_DIRECTORY="/var/lib/marzban/templates/"' | sudo tee -a /opt/marzban/.env
    fi
    if ! sudo grep -q '^SUBSCRIPTION_PAGE_TEMPLATE=' /opt/marzban/.env; then
        echo 'SUBSCRIPTION_PAGE_TEMPLATE="subscription/index.html"' | sudo tee -a /opt/marzban/.env
    fi
    
    # Restart Marzban
    sudo marzban restart # Added sudo
    echo "MrClock template installed successfully! (Template MrClock ba movafaghiat nasb shod!)"
}

backup_marzban() {
    echo "Backing up Marzban... (Dar hal poshtibangiri Marzban...)"
    sudo marzban backup
    echo "Marzban backup completed. (Poshtibangiri Marzban anjam shod.)"
}

while true; do
    show_menu
    case $choice in
        1) update_server ;;
        2) install_certbot ;;
        3) install_marzban ;;
        4) setup_ssl ;;
        5) setup_telegram_bot ;; # Changed case
        6) install_template_mrclock ;;
        7) backup_marzban ;;
        8) restart_marzban ;;
        0) echo "Exiting... (Dar hal khorooj...)" ; exit 0 ;;
        *) echo "Invalid choice! (Entekhab eshtebah!)" ;;
    esac
    read -p "Press Enter to continue... (Baraye edame kelid Enter ra bezanid...)"
done
