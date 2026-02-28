# Finn - Setup Supabase

## 🎯 Configurazione

Finn usa **Supabase Cloud** (production) per uso personale/famiglia.

| Ambiente | URL | Note |
|----------|-----|------|
| **Production** | `https://ofsnyaplaowbduujuucb.supabase.co` | Supabase Cloud |
| **Dev locale** | `http://localhost:54321` | `supabase start` sul PC |

---

## 🔑 Credenziali

Le credenziali **NON** vanno nel repo. Sono gestite tramite:
- **GitHub Secrets**: `SUPABASE_URL` + `SUPABASE_ANON_KEY` → iniettate nel `.env` dal CI
- **Locale**: crea manualmente il file `.env` (vedi sotto)

### Setup locale PC

```bash
cat > .env << 'EOF'
SUPABASE_URL=https://ofsnyaplaowbduujuucb.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mc255YXBsYW93YmR1dWp1dWNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzMDQ5NTAsImV4cCI6MjA4MTg4MDk1MH0.KroyO-7pma1BsjZEWl9CLmsiPQWMIaUPDziwTSOENhE
EOF
flutter run
```

---

## 🔍 Database

- **Dashboard**: https://supabase.com/dashboard/project/ofsnyaplaowbduujuucb
- **Project ID**: `ofsnyaplaowbduujuucb`
- **Backup**: automatico (gestito da Supabase Cloud)

---

## ⚠️ Regole workflow

1. **Mai** committare il file `.env` (è in `.gitignore`)
2. **Sempre** aggiornare i GitHub Secrets se le credenziali cambiano
3. Il CI inietta automaticamente le credenziali nel `.env` prima del build APK
4. Se il progetto Supabase Cloud viene sostituito → aggiornare:
   - GitHub Secrets (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
   - Questo file (`SETUP_SUPABASE.md`)
   - Il campo `Database` in `PROJECT.md`
