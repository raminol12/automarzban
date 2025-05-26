#!/bin/bash

show_menu() {
    clear
    echo "=== Marzban Installation Menu (Nasb Marzban) ==="
    echo "1) Update Server (Berooz Resani Server)"
    echo "2) Install Certbot & Get SSL (Nasb Certbot va Daryaft SSL)"
    echo "3) Install Marzban (Nasb Marzban)"
    echo "4) Setup SSL Certificates (Tanzim SSL)"
    echo "5) Restart Marzban (Restart Kardan Marzban)"
    echo "6) Install Template (Nasb Template)"
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
    apt-get install certbot -y
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$domain"
}

install_marzban() {
    echo "=== Marzban Installation Options (Gozine haye nasb Marzban) ==="
    echo "1) Install with SQLite (Nasb ba SQLite)"
    echo "2) Install with MySQL (Nasb ba MySQL)"
    echo "3) Install with MariaDB (Nasb ba MariaDB)"
    echo "0) Back to main menu (Bazgasht be menu asli)"
    read -p "Choose database type (No'e database ra entekhab konid): " db_choice

    case $db_choice in
        1) sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install ;;
        2) sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install --database mysql ;;
        3) sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install --database mariadb ;;
        0) return ;;
        *) echo "Invalid choice! (Entekhab eshtebah!)" ;;
    esac
}

setup_ssl() {
    read -p "Enter your domain (Domain khod ra vared konid): " domain
    echo "Setting up SSL certificates... (Dar hal tanzim SSL...)"
    mkdir -p /var/lib/marzban/certs
    cp "/etc/letsencrypt/live/$domain/fullchain.pem" /var/lib/marzban/certs/fullchain.pem
    cp "/etc/letsencrypt/live/$domain/privkey.pem" /var/lib/marzban/certs/privkey.pem

    # Update .env file
    sed -i '11,12d' /opt/marzban/.env
    echo 'UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/fullchain.pem"' >> /opt/marzban/.env
    echo 'UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/privkey.pem"' >> /opt/marzban/.env
}

restart_marzban() {
    echo "Restarting Marzban... (Dar hal restart kardan Marzban...)"
    marzban restart
}

install_template() {
    echo "Installing template... (Dar hal nasb template...)"
    sudo wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/Mrclocks/MrClock-Subscription-Template/main/index.html
    
    # Update .env file
    echo 'CUSTOM_TEMPLATES_DIRECTORY="/var/lib/marzban/templates/"' | sudo tee -a /opt/marzban/.env
    echo 'SUBSCRIPTION_PAGE_TEMPLATE="subscription/index.html"' | sudo tee -a /opt/marzban/.env
    
    # Restart Marzban
    marzban restart
    echo "Template installed successfully! (Template ba movafaghiat nasb shod!)"
}

while true; do
    show_menu
    case $choice in
        1) update_server ;;
        2) install_certbot ;;
        3) install_marzban ;;
        4) setup_ssl ;;
        5) restart_marzban ;;
        6) install_template ;;
        0) echo "Exiting... (Dar hal khorooj...)" ; exit 0 ;;
        *) echo "Invalid choice! (Entekhab eshtebah!)" ;;
    esac
    read -p "Press Enter to continue... (Baraye edame kelid Enter ra bezanid...)" 
done
