============================================
  STELVIS ERPNext POS
  One-Click Windows Installer
============================================

REQUIREMENTS:
- Windows 10/11 (64-bit)
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space
- Internet connection (first time only)


============================================
INSTALLATION (Two simple steps)
============================================

STEP 1:
  1. Right-click "INSTALL.bat"
  2. Select "Run as administrator"
  3. Follow the prompts
  4. Computer will restart

STEP 2 (after restart):
  1. Wait for Docker Desktop to start
     (whale icon appears in system tray)
  2. Right-click "SETUP-ERPNEXT.bat"
  3. Select "Run as administrator"
  4. Wait 10-15 minutes for setup to finish
  5. Browser opens automatically - done!


============================================
LOGIN
============================================

  URL:      http://stelvis.local
  Username: Administrator
  Password: admin2024

  >>> CHANGE PASSWORD AFTER FIRST LOGIN! <<<


============================================
DAILY USE (Desktop Shortcuts)
============================================

After install, you'll have these on your Desktop:

  "Stelvis ERPNext - Start"  = Start the system
  "Stelvis POS"              = Open POS in browser
  "Stelvis Backup"           = Backup your data

Note: If Docker Desktop is set to auto-start
(it is by default), ERPNext starts automatically
when you turn on your computer.


============================================
POS SETUP (First time after login)
============================================

1. Complete the Setup Wizard
   - Company name, country, currency

2. Create a POS Profile
   - Search "POS Profile" in search bar
   - Set company, warehouse, payment methods

3. Open POS
   - http://stelvis.local/app/point-of-sale


============================================
TROUBLESHOOTING
============================================

"stelvis.local" doesn't load:
  > Make sure Docker Desktop is running
  > Double-click "Stelvis ERPNext - Start" on desktop
  > Wait 1-2 minutes

Forgot admin password:
  > Open Command Prompt, run:
  > docker exec stelvis-erpnext bench --site stelvis.local set-admin-password NEW_PASSWORD

Reset everything:
  > Open Command Prompt in this folder, run:
  > docker compose down -v
  > Then run SETUP-ERPNEXT.bat again

============================================
  Files in this folder:
============================================
  INSTALL.bat          - Step 1 installer
  SETUP-ERPNEXT.bat    - Step 2 setup
  start.bat            - Start ERPNext
  stop.bat             - Stop ERPNext
  backup.bat           - Backup data
  docker-compose.yml   - Docker configuration
  .env                 - Passwords (edit before install)
============================================
