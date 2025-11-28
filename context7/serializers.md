# BetterController Serializers

Questa documentazione descrive come utilizzare i serializzatori in BetterController per formattare le risposte API in modo coerente.

## Indice

- [Panoramica](#panoramica)
- [Definizione di un Serializer](#definizione-di-un-serializer)
- [Utilizzo di Base](#utilizzo-di-base)
- [Serializzazione di Risorse Singole](#serializzazione-di-risorse-singole)
- [Serializzazione di Collezioni](#serializzazione-di-collezioni)
- [Opzioni di Serializzazione](#opzioni-di-serializzazione)
- [Serializer Nidificati](#serializer-nidificati)
- [Best Practices](#best-practices)

## Panoramica

I serializzatori in BetterController sono responsabili della conversione degli oggetti del modello in rappresentazioni JSON adatte per le risposte API. Forniscono un modo coerente per:

1. Definire quali attributi includere nella risposta
2. Formattare i dati in modo appropriato
3. Includere metodi personalizzati nel risultato serializzato
4. Gestire relazioni nidificate

## Definizione di un Serializer

Per creare un serializer, è necessario includere il modulo `BetterController::Serializers::Serializer` e definire gli attributi e i metodi da serializzare:

```ruby
class UserSerializer
  include BetterController::Serializers::Serializer
  
  # Definisce gli attributi da includere nella risposta
  attributes :id, :name, :email, :created_at
  
  # Definisce i metodi da includere nella risposta
  methods :full_name, :role_name
  
  # Metodo personalizzato che sarà incluso nella risposta
  def full_name
    "#{object.first_name} #{object.last_name}"
  end
  
  # Un altro metodo personalizzato
  def role_name
    object.role.name if object.role
  end
end
```

## Utilizzo di Base

Ecco come utilizzare un serializer in un controller:

```ruby
class UsersController < ApplicationController
  include BetterController
  
  def show
    user = User.find(params[:id])
    serializer = UserSerializer.new(user)
    
    # Serializza l'utente e restituisce una risposta di successo
    respond_with_success(serializer.serialize(user))
  end
end
```

## Serializzazione di Risorse Singole

Per serializzare una singola risorsa:

```ruby
user = User.find(1)
serializer = UserSerializer.new(user)
result = serializer.serialize(user)

# Oppure più semplicemente:
result = serializer.serialize_resource(user)
```

Il risultato sarà un hash con gli attributi e i metodi definiti:

```ruby
{
  id: 1,
  name: "John Doe",
  email: "john@example.com",
  created_at: "2023-01-01T12:00:00Z",
  full_name: "John Doe",
  role_name: "Admin"
}
```

## Serializzazione di Collezioni

Per serializzare una collezione di risorse:

```ruby
users = User.all
serializer = UserSerializer.new
result = serializer.serialize(users)

# Oppure più esplicitamente:
result = serializer.serialize_collection(users)
```

Il risultato sarà un array di hash, ciascuno rappresentante un utente serializzato:

```ruby
[
  {
    id: 1,
    name: "John Doe",
    email: "john@example.com",
    created_at: "2023-01-01T12:00:00Z",
    full_name: "John Doe",
    role_name: "Admin"
  },
  {
    id: 2,
    name: "Jane Smith",
    email: "jane@example.com",
    created_at: "2023-01-02T12:00:00Z",
    full_name: "Jane Smith",
    role_name: "Editor"
  }
]
```

## Opzioni di Serializzazione

È possibile passare opzioni aggiuntive al metodo `serialize` per personalizzare il comportamento:

```ruby
# Includi solo attributi specifici
serializer.serialize(user, only: [:id, :name])

# Escludi attributi specifici
serializer.serialize(user, except: [:created_at])

# Includi attributi aggiuntivi
serializer.serialize(user, include: [:additional_field])
```

## Serializer Nidificati

Per gestire relazioni nidificate, è possibile utilizzare altri serializer all'interno di un serializer:

```ruby
class UserSerializer
  include BetterController::Serializers::Serializer
  
  attributes :id, :name, :email
  methods :posts
  
  def posts
    PostSerializer.new.serialize(object.posts)
  end
end

class PostSerializer
  include BetterController::Serializers::Serializer
  
  attributes :id, :title, :content, :created_at
end
```

Questo produrrà una risposta nidificata:

```ruby
{
  id: 1,
  name: "John Doe",
  email: "john@example.com",
  posts: [
    {
      id: 101,
      title: "Primo Post",
      content: "Contenuto del primo post",
      created_at: "2023-01-05T12:00:00Z"
    },
    {
      id: 102,
      title: "Secondo Post",
      content: "Contenuto del secondo post",
      created_at: "2023-01-06T12:00:00Z"
    }
  ]
}
```

## Best Practices

1. **Mantieni i serializer semplici**: Ogni serializer dovrebbe avere una singola responsabilità.

2. **Riutilizza i serializer**: Crea serializer di base che possono essere estesi per casi d'uso specifici.

3. **Gestisci i nil**: Assicurati che i metodi personalizzati gestiscano correttamente i casi in cui l'oggetto o le sue proprietà sono nil.

   ```ruby
   def full_name
     return "" unless object && object.respond_to?(:first_name) && object.respond_to?(:last_name)
     "#{object.first_name} #{object.last_name}"
   end
   ```

4. **Evita logica complessa**: I serializer dovrebbero concentrarsi sulla formattazione dei dati, non sulla logica di business.

5. **Usa serializer dedicati per le API**: Crea serializer specifici per le API pubbliche e mantienili stabili per evitare breaking changes.

6. **Documenta i tuoi serializer**: Documenta chiaramente quali attributi e metodi sono inclusi nella risposta serializzata.

7. **Testa i tuoi serializer**: Scrivi test per assicurarti che i serializer producano il formato di output atteso.

   ```ruby
   RSpec.describe UserSerializer do
     let(:user) { create(:user, first_name: "John", last_name: "Doe") }
     let(:serializer) { UserSerializer.new(user) }
     
     it "serializes a user correctly" do
       result = serializer.serialize(user)
       
       expect(result).to include(
         id: user.id,
         name: user.name,
         email: user.email
       )
       expect(result[:full_name]).to eq("John Doe")
     end
   end
   ```

Seguendo queste linee guida, puoi creare serializer robusti e manutenibili che producono risposte API coerenti in tutta la tua applicazione.
