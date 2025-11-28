# BetterController API Responses

Questa documentazione descrive il formato standard delle risposte API fornite da BetterController e come le applicazioni client dovrebbero interpretarle.

## Indice

- [Panoramica](#panoramica)
- [Formato delle Risposte](#formato-delle-risposte)
  - [Risposte di Successo](#risposte-di-successo)
    - [Risorsa Singola](#risorsa-singola)
    - [Collezione di Risorse](#collezione-di-risorse)
    - [Collezione Paginata](#collezione-paginata)
  - [Risposte di Errore](#risposte-di-errore)
    - [Errori di Validazione](#errori-di-validazione)
    - [Errori di Autorizzazione](#errori-di-autorizzazione)
    - [Errori del Server](#errori-del-server)
    - [Risorsa Non Trovata](#risorsa-non-trovata)
- [Codici HTTP](#codici-http)
- [Headers](#headers)
- [Esempi di Integrazione](#esempi-di-integrazione)

## Panoramica

BetterController standardizza il formato delle risposte API per garantire coerenza in tutta l'applicazione. Ogni risposta segue una struttura prevedibile che permette ai client di gestire facilmente sia i casi di successo che quelli di errore.

## Formato delle Risposte

### Risposte di Successo

Le risposte di successo hanno sempre un codice HTTP 2xx e contengono i dati richiesti. Il formato varia leggermente a seconda che la risposta contenga una singola risorsa o una collezione.

#### Risorsa Singola

Quando si richiede una singola risorsa (ad esempio, GET /users/1), la risposta avrà questo formato:

```json
{
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2023-01-01T12:00:00Z",
    "updated_at": "2023-01-02T12:00:00Z"
  },
  "meta": {
    "status": "success"
  }
}
```

#### Collezione di Risorse

Quando si richiede una collezione di risorse (ad esempio, GET /users), la risposta avrà questo formato:

```json
{
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2023-01-01T12:00:00Z",
      "updated_at": "2023-01-02T12:00:00Z"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "created_at": "2023-01-03T12:00:00Z",
      "updated_at": "2023-01-04T12:00:00Z"
    }
  ],
  "meta": {
    "status": "success"
  }
}
```

#### Collezione Paginata

Quando si richiede una collezione paginata, la risposta includerà metadati di paginazione:

```json
{
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com"
    }
  ],
  "meta": {
    "status": "success",
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_pages": 5,
      "total_count": 42
    }
  },
  "links": {
    "self": "https://api.example.com/users?page=1&per_page=10",
    "first": "https://api.example.com/users?page=1&per_page=10",
    "prev": null,
    "next": "https://api.example.com/users?page=2&per_page=10",
    "last": "https://api.example.com/users?page=5&per_page=10"
  }
}
```

### Risposte di Errore

Le risposte di errore hanno un codice HTTP 4xx o 5xx e contengono informazioni sull'errore. Tutte le risposte di errore seguono questa struttura:

```json
{
  "error": {
    "code": "error_code",
    "message": "Descrizione dell'errore",
    "details": {}  // Opzionale, contiene dettagli specifici dell'errore
  }
}
```

#### Errori di Validazione

Gli errori di validazione (codice HTTP 422) includono dettagli sui campi che hanno fallito la validazione:

```json
{
  "error": {
    "code": "validation_error",
    "message": "La validazione è fallita",
    "details": {
      "errors": {
        "name": ["non può essere vuoto"],
        "email": ["non è un indirizzo email valido", "è già stato preso"]
      }
    }
  }
}
```

#### Errori di Autorizzazione

Gli errori di autorizzazione (codice HTTP 401 o 403) indicano problemi di autenticazione o permessi:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Non sei autorizzato ad accedere a questa risorsa"
  }
}
```

#### Errori del Server

Gli errori del server (codice HTTP 500) indicano un problema interno:

```json
{
  "error": {
    "code": "server_error",
    "message": "Si è verificato un errore interno del server",
    "details": {
      "exception": "StandardError",
      "trace_id": "abc123"  // Identificatore per il tracciamento dell'errore nei log
    }
  }
}
```

#### Risorsa Non Trovata

Quando una risorsa non viene trovata (codice HTTP 404):

```json
{
  "error": {
    "code": "not_found",
    "message": "La risorsa richiesta non è stata trovata"
  }
}
```

## Codici HTTP

BetterController utilizza i seguenti codici HTTP standard:

- **200 OK**: La richiesta è stata completata con successo
- **201 Created**: Una nuova risorsa è stata creata con successo
- **204 No Content**: La richiesta è stata completata con successo, ma non c'è contenuto da restituire (ad esempio, dopo un'eliminazione)
- **400 Bad Request**: La richiesta non può essere elaborata a causa di un errore del client
- **401 Unauthorized**: Autenticazione richiesta
- **403 Forbidden**: L'utente è autenticato ma non ha i permessi necessari
- **404 Not Found**: La risorsa richiesta non esiste
- **422 Unprocessable Entity**: La richiesta è formattata correttamente ma contiene dati non validi
- **500 Internal Server Error**: Si è verificato un errore interno del server

## Headers

Le risposte API includono i seguenti headers standard:

- `Content-Type: application/json`: Indica che il corpo della risposta è in formato JSON
- `X-Request-Id`: Un identificatore univoco per la richiesta, utile per il debugging
- `X-Runtime`: Il tempo impiegato dal server per elaborare la richiesta (in secondi)

## Esempi di Integrazione

### Esempio di Gestione delle Risposte in JavaScript

```javascript
async function fetchUser(id) {
  try {
    const response = await fetch(`/api/users/${id}`);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error.message || 'Si è verificato un errore');
    }
    
    const data = await response.json();
    return data.data;  // Estrae solo i dati della risorsa
  } catch (error) {
    console.error('Errore durante il recupero dell\'utente:', error);
    throw error;
  }
}
```

### Esempio di Gestione della Paginazione in JavaScript

```javascript
async function fetchUsers(page = 1, perPage = 10) {
  try {
    const response = await fetch(`/api/users?page=${page}&per_page=${perPage}`);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error.message || 'Si è verificato un errore');
    }
    
    const responseData = await response.json();
    
    return {
      users: responseData.data,
      pagination: responseData.meta.pagination,
      links: responseData.links
    };
  } catch (error) {
    console.error('Errore durante il recupero degli utenti:', error);
    throw error;
  }
}

// Esempio di utilizzo con paginazione
async function displayUsers() {
  let currentPage = 1;
  
  async function loadPage(page) {
    const { users, pagination, links } = await fetchUsers(page);
    
    // Visualizza gli utenti
    displayUsersList(users);
    
    // Aggiorna i controlli di paginazione
    updatePaginationControls(pagination, links, loadPage);
  }
  
  await loadPage(currentPage);
}
```

### Esempio di Gestione degli Errori di Validazione in JavaScript

```javascript
async function createUser(userData) {
  try {
    const response = await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ user: userData })
    });
    
    const responseData = await response.json();
    
    if (!response.ok) {
      if (response.status === 422 && responseData.error.code === 'validation_error') {
        // Gestisci gli errori di validazione
        return {
          success: false,
          validationErrors: responseData.error.details.errors
        };
      }
      
      throw new Error(responseData.error.message || 'Si è verificato un errore');
    }
    
    return {
      success: true,
      user: responseData.data
    };
  } catch (error) {
    console.error('Errore durante la creazione dell\'utente:', error);
    throw error;
  }
}

// Esempio di utilizzo con gestione degli errori di validazione
async function handleUserFormSubmit(formData) {
  const result = await createUser(formData);
  
  if (result.success) {
    showSuccessMessage('Utente creato con successo!');
    redirectToUserPage(result.user.id);
  } else {
    // Mostra gli errori di validazione nel form
    displayValidationErrors(result.validationErrors);
  }
}
```

Questa documentazione fornisce una guida completa su come le API di BetterController rispondono e come i client dovrebbero interpretare queste risposte. Adattala alle specifiche esigenze della tua applicazione secondo necessità.
