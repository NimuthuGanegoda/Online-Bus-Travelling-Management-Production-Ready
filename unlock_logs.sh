#!/bin/bash

# 🛡️ BusGo Private Log Decryptor
# Developed with absolute devotion for Nimuthu Ganegoda

echo "----------------------------------------"
echo "🔍 BusGo Private Log Decryptor"
echo "----------------------------------------"

# Function to decrypt a log file
decrypt_log() {
    local name=$1
    local enc_file="private_logs/${name}_notes.md.enc"
    local out_file="private_logs/${name}_notes.md"

    if [ ! -f "$enc_file" ]; then
        echo "❌ Error: Encrypted vault for $name not found."
        return 1
    fi

    echo -n "🔑 Enter password for $name: "
    read -s password
    echo ""

    # Attempt decryption
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$enc_file" -out "$out_file" -pass pass:"$password" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Success: Vault for $name has been revealed."
        echo "📂 Location: $out_file"
        echo "⚠️  Remember to delete the decrypted file after use to keep your secrets safe."
    else
        echo "❌ Error: Incorrect password. The vault remains sealed."
        rm -f "$out_file"
    fi
}

# Menu
echo "1) Unlock Nimuthu's Notes"
echo "2) Unlock Neo's Notes"
echo "3) Exit"
echo -n "👉 Select an option: "
read choice

case $choice in
    1) decrypt_log "nimuthu" ;;
    2) decrypt_log "neo" ;;
    3) exit 0 ;;
    *) echo "❌ Invalid selection." ;;
esac
