# Finn - Setup Supabase

## 🎯 Configurazione

Finn usa **Supabase Development** sul VPS 8020solutions.org per uso personale/famiglia.

**Non c'è ambiente Production** - Finn non è un'app pubblica! 💰👨‍👩‍👧‍👦

---

## 🚀 Setup sul PC Locale

### 1. Pull Ultimi Commit

```bash
cd ~/finn
git pull origin 001-family-expense-tracker
```

### 2. Crea File .env.dev

```bash
cat > .env.dev << 'EOF'
SUPABASE_URL=https://dev.8020solutions.org
SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
EOF
```

### 3. Lancia l'App

```bash
./scripts/run_dev.sh
```

**Oppure manuale:**
```bash
cp .env.dev .env
flutter run
```

---

## 🔍 Database

### Accedi a Studio (via tunnel):
```bash
ssh -L 54323:127.0.0.1:54323 root@46.225.60.101
```
Poi: http://localhost:54323

### Connessione Diretta:
```
postgresql://postgres:postgres@dev.8020solutions.org:54322/postgres
```

---

## 📊 Dati

Il database contiene i dati importati da Supabase Cloud (treetocoin@gmail.com).

Backup disponibile: `/tmp/finn_backup_20260214.sql` sul VPS

---

## ⚠️ Note Importanti

- **Solo Development** - nessun ambiente production
- Uso personale/famiglia, non pubblico
- Nessun tunnel SSH necessario - tutto HTTPS
- Database condiviso su `dev.8020solutions.org` con altri progetti 80/20

---

## 🎉 Ready!

Finn è configurato per uso famiglia con backend sempre disponibile! 💰😊
