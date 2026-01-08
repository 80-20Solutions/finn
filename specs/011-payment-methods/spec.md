# Feature Specification: Metodi di Pagamento per Spese

**Feature Branch**: `011-payment-methods`
**Created**: 2026-01-07
**Status**: Draft
**Input**: User description: "bisogna aggiungere alla singola spesa il campo "Metodo di pagamento" , come opzioni metti: Contanti, Carta di Credito , Bonifico, Satispay" , poi , come per le categorie, da impostazioni, dai la possibilità di aggiungere metodi custom. imposta di default il metodo "Contanti" e per le spese già registrate, metti "Contanti" come metodo"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrazione Spesa con Metodo di Pagamento (Priority: P1)

Un utente registra una nuova spesa e seleziona il metodo di pagamento utilizzato. Quando visualizza la lista delle spese, può vedere immediatamente con quale metodo ha pagato ciascuna spesa.

**Why this priority**: Questa è la funzionalità core che aggiunge valore immediato permettendo agli utenti di tracciare come hanno effettuato i pagamenti. Senza questa funzionalità, la feature non ha utilità.

**Independent Test**: Può essere testata creando una nuova spesa, selezionando un metodo di pagamento predefinito (es. "Carta di Credito"), salvando la spesa e verificando che il metodo sia visibile nella lista e nei dettagli della spesa.

**Acceptance Scenarios**:

1. **Given** un utente sta creando una nuova spesa, **When** arriva alla schermata di inserimento, **Then** vede un campo "Metodo di pagamento" con valore predefinito "Contanti"
2. **Given** un utente sta creando una nuova spesa, **When** tocca il campo "Metodo di pagamento", **Then** vede le opzioni: Contanti, Carta di Credito, Bonifico, Satispay
3. **Given** un utente seleziona "Carta di Credito" come metodo, **When** salva la spesa, **Then** la spesa viene salvata con il metodo "Carta di Credito"
4. **Given** un utente visualizza la lista delle spese, **When** visualizza una spesa, **Then** può vedere il metodo di pagamento associato alla spesa
5. **Given** un utente visualizza i dettagli di una spesa, **When** apre la schermata di dettaglio, **Then** vede chiaramente il metodo di pagamento utilizzato

---

### User Story 2 - Migrazione Spese Esistenti (Priority: P2)

Le spese già registrate nel sistema vengono automaticamente associate al metodo di pagamento "Contanti" come valore predefinito, garantendo che tutte le spese abbiano un metodo di pagamento.

**Why this priority**: È fondamentale per la coerenza dei dati e per evitare errori. Deve essere implementata subito dopo la P1 per garantire che non ci siano spese senza metodo di pagamento.

**Independent Test**: Può essere testata verificando che tutte le spese esistenti nel database abbiano "Contanti" come metodo di pagamento dopo l'aggiornamento, e che non ci siano spese con metodo nullo o mancante.

**Acceptance Scenarios**:

1. **Given** esistono spese registrate prima dell'introduzione dei metodi di pagamento, **When** il sistema viene aggiornato, **Then** tutte le spese esistenti hanno "Contanti" come metodo di pagamento
2. **Given** un utente visualizza una spesa registrata prima dell'aggiornamento, **When** apre i dettagli, **Then** vede "Contanti" come metodo di pagamento
3. **Given** un utente modifica una spesa esistente (registrata prima dell'aggiornamento), **When** salva le modifiche, **Then** può mantenere "Contanti" o cambiare il metodo di pagamento

---

### User Story 3 - Gestione Metodi di Pagamento Custom (Priority: P3)

Un utente può aggiungere metodi di pagamento personalizzati dalle impostazioni, che diventano disponibili come opzioni quando registra nuove spese.

**Why this priority**: Aggiunge flessibilità per casi d'uso specifici ma non è essenziale per il funzionamento base. Gli utenti possono iniziare ad usare la feature con i metodi predefiniti.

**Independent Test**: Può essere testata accedendo alle impostazioni, aggiungendo un nuovo metodo personalizzato (es. "PayPal"), e verificando che appaia nella lista dei metodi disponibili quando si crea una nuova spesa.

**Acceptance Scenarios**:

1. **Given** un utente è nelle impostazioni dell'app, **When** accede alla sezione "Metodi di Pagamento", **Then** vede la lista dei metodi predefiniti e l'opzione per aggiungere nuovi metodi
2. **Given** un utente vuole aggiungere un metodo custom, **When** tocca "Aggiungi metodo" e inserisce un nome (es. "PayPal"), **Then** il nuovo metodo viene salvato e appare nella lista
3. **Given** un utente ha creato metodi custom, **When** crea una nuova spesa, **Then** vede sia i metodi predefiniti che quelli custom nella lista di selezione
4. **Given** un utente ha creato un metodo custom, **When** vuole eliminarlo dalle impostazioni, **Then** può eliminarlo se non è utilizzato da nessuna spesa
5. **Given** un utente tenta di eliminare un metodo custom utilizzato da spese esistenti, **When** conferma l'eliminazione, **Then** il sistema impedisce l'eliminazione e mostra un messaggio informativo

---

### User Story 4 - Modifica Metodo di Pagamento (Priority: P3)

Un utente può modificare il metodo di pagamento di una spesa esistente, permettendo la correzione di errori o aggiornamenti.

**Why this priority**: Utile per correggere errori ma non bloccante. Gli utenti possono prima registrare correttamente le nuove spese.

**Independent Test**: Può essere testata aprendo una spesa esistente in modalità modifica, cambiando il metodo di pagamento, salvando e verificando che la modifica sia persistita.

**Acceptance Scenarios**:

1. **Given** un utente visualizza i dettagli di una spesa, **When** tocca "Modifica" o l'icona di modifica, **Then** può modificare il metodo di pagamento selezionando un'opzione diversa
2. **Given** un utente modifica il metodo di pagamento di una spesa, **When** salva le modifiche, **Then** il nuovo metodo viene salvato e visualizzato nei dettagli della spesa
3. **Given** un utente modifica una spesa, **When** cambia altri campi ma non il metodo di pagamento, **Then** il metodo di pagamento originale rimane invariato

---

### Edge Cases

- Cosa succede quando un utente elimina un metodo di pagamento custom che è utilizzato da spese esistenti?
  - Il sistema deve impedire l'eliminazione e mostrare un messaggio che indica quante spese utilizzano quel metodo

- Cosa succede se un utente tenta di creare un metodo custom con un nome vuoto o composto solo da spazi?
  - Il sistema deve validare l'input e mostrare un messaggio di errore

- Cosa succede se un utente tenta di creare un metodo custom con un nome già esistente (case-insensitive)?
  - Il sistema deve impedire la creazione e mostrare un messaggio che indica che il metodo esiste già

- Come vengono gestiti i metodi di pagamento in un contesto multi-utente/gruppo?
  - I metodi predefiniti sono disponibili per tutti
  - I metodi custom sono personali per ogni utente (ogni utente vede e può utilizzare solo i propri metodi custom)

- Cosa succede quando si filtra o si cerca una spesa per metodo di pagamento?
  - [Assunzione: questa funzionalità non è richiesta nella versione iniziale, ma il design deve permettere futura estensibilità]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Il sistema DEVE aggiungere un campo "Metodo di pagamento" a ogni spesa
- **FR-002**: Il sistema DEVE fornire quattro metodi di pagamento predefiniti: "Contanti", "Carta di Credito", "Bonifico", "Satispay"
- **FR-003**: Il sistema DEVE impostare "Contanti" come metodo di pagamento predefinito per le nuove spese
- **FR-004**: Il sistema DEVE assegnare "Contanti" come metodo di pagamento a tutte le spese esistenti (migrazione dati)
- **FR-005**: Gli utenti DEVONO poter selezionare il metodo di pagamento durante la creazione di una spesa
- **FR-006**: Gli utenti DEVONO poter visualizzare il metodo di pagamento nella lista delle spese
- **FR-007**: Gli utenti DEVONO poter visualizzare il metodo di pagamento nei dettagli di una spesa
- **FR-008**: Gli utenti DEVONO poter modificare il metodo di pagamento di una spesa esistente
- **FR-009**: Il sistema DEVE fornire una sezione "Metodi di Pagamento" nelle impostazioni dell'app
- **FR-010**: Gli utenti DEVONO poter aggiungere metodi di pagamento personalizzati dalle impostazioni
- **FR-011**: Gli utenti DEVONO poter visualizzare tutti i metodi di pagamento (predefiniti e custom) nelle impostazioni
- **FR-012**: Gli utenti DEVONO poter eliminare metodi di pagamento custom dalle impostazioni
- **FR-013**: Il sistema DEVE impedire l'eliminazione di un metodo di pagamento custom se è utilizzato da almeno una spesa
- **FR-014**: Il sistema DEVE validare che il nome di un metodo custom non sia vuoto
- **FR-015**: Il sistema DEVE impedire la creazione di metodi custom con nomi duplicati (case-insensitive)
- **FR-016**: I metodi custom DEVONO apparire nella lista di selezione insieme ai metodi predefiniti
- **FR-017**: Il sistema DEVE persistere i metodi di pagamento nel database
- **FR-018**: Il sistema DEVE mantenere l'associazione tra spesa e metodo di pagamento anche se il metodo viene rinominato

### Key Entities

- **Metodo di Pagamento (PaymentMethod)**: Rappresenta un metodo di pagamento disponibile nell'app
  - Attributi chiave: nome, tipo (predefinito/custom), data creazione, utente proprietario (per metodi custom - identifica l'utente che ha creato il metodo)

- **Spesa (Expense)**: Entità esistente che viene estesa con il riferimento al metodo di pagamento
  - Nuovi attributi: riferimento al metodo di pagamento (obbligatorio)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Gli utenti possono aggiungere il metodo di pagamento a una nuova spesa in meno di 3 secondi (2 tap: campo + selezione)
- **SC-002**: Il 100% delle spese nel sistema ha un metodo di pagamento associato (nessuna spesa senza metodo)
- **SC-003**: Gli utenti possono creare e utilizzare un metodo di pagamento custom entro 30 secondi dall'apertura delle impostazioni
- **SC-004**: Il metodo di pagamento è visibile nella lista spese senza dover aprire i dettagli
- **SC-005**: La migrazione delle spese esistenti viene completata senza errori per tutti i record
- **SC-006**: Gli utenti possono distinguere visivamente tra diversi metodi di pagamento nella lista spese

## Assumptions

- I metodi predefiniti (Contanti, Carta di Credito, Bonifico, Satispay) non possono essere eliminati o rinominati
- I nomi dei metodi di pagamento hanno una lunghezza massima ragionevole (es. 50 caratteri)
- La validazione case-insensitive per i nomi duplicati usa le convenzioni della lingua italiana e si applica solo ai metodi dell'utente corrente
- I metodi custom sono personali: ogni utente può creare, vedere e utilizzare solo i propri metodi custom
- Non è richiesta nella versione iniziale la possibilità di ordinare o riordinare i metodi di pagamento
- Non è richiesta nella versione iniziale la possibilità di filtrare le spese per metodo di pagamento
- La UI mostrerà i metodi in ordine: prima i predefiniti nell'ordine specificato, poi i custom dell'utente in ordine alfabetico

## Dependencies

- La feature dipende dalla struttura dati esistente delle spese (Expense entity)
- La feature dipende dalla sezione Impostazioni esistente nell'app
- Se l'app supporta la sincronizzazione multi-dispositivo, i metodi custom devono essere sincronizzati

## Out of Scope

- Filtri e ricerche per metodo di pagamento (feature futura)
- Statistiche e report per metodo di pagamento (feature futura)
- Icone personalizzate per i metodi di pagamento
- Riordino manuale dei metodi di pagamento
- Import/export di metodi di pagamento custom
- Archiviazione di metodi di pagamento non più utilizzati (invece dell'eliminazione)
