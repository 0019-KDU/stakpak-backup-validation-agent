#!/bin/bash
# One-time setup for Stakpak backup validation agent on the droplet
set -e

echo "━━━ Stakpak Backup Validation Agent Setup ━━━"

# 1. Install Stakpak
echo "▶ Installing Stakpak..."
curl -sSL https://stakpak.dev/install.sh | sh

# 2. Create directories
echo "▶ Creating directories..."
mkdir -p /root/.stakpak/backups
mkdir -p /root/.stakpak/logs
mkdir -p /root/.stakpak/scripts
mkdir -p /root/.stakpak/staging
mkdir -p ~/.stakpak

# 3. Copy configs
echo "▶ Copying configs..."
cp .stakpak/config.toml ~/.stakpak/config.toml
cp .stakpak/autopilot.toml ~/.stakpak/autopilot.toml

# 4. Copy scripts
echo "▶ Copying scripts..."
cp scripts/*.sh /root/.stakpak/scripts/
chmod +x /root/.stakpak/scripts/*.sh

# 5. Copy staging docker-compose
echo "▶ Copying staging config..."
cp staging/docker-compose.yml /root/.stakpak/staging/docker-compose.yml

# 6. Setup .env
echo "▶ Setting up environment..."
if [ ! -f /root/.stakpak/.env ]; then
  cp .stakpak/.env.example /root/.stakpak/.env
  echo ""
  echo "  ⚠ Edit /root/.stakpak/.env with your real credentials:"
  echo "    nano /root/.stakpak/.env"
fi

# 7. Apply rulebook
echo "▶ Applying Stakpak rulebook..."
stakpak rb apply rulebooks/backup-validation.md

# 8. Create MySQL staging user permissions
echo "▶ Granting MySQL permissions for staging DB..."
source /root/.stakpak/.env
mysql -u root -p -e "
  GRANT ALL PRIVILEGES ON \`${STAGING_DB_NAME}\`.* TO '${DB_USER}'@'%';
  FLUSH PRIVILEGES;
"

echo ""
echo "━━━ Setup Complete ━━━"
echo ""
echo "Next steps:"
echo "  1. Edit /root/.stakpak/.env with real values"
echo "  2. Login to Stakpak:  stakpak auth login --api-key \$STAKPAK_API_KEY"
echo "  3. Start autopilot:   stakpak up"
echo "  4. Test manually:     bash /root/.stakpak/scripts/run_validation.sh"
echo ""
echo "Autopilot schedules:"
echo "  - Daily full validation at 02:00 AM"
echo "  - Quick integrity check every 6 hours"
