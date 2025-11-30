# Feature: Supporto GraphQL per BetterController

## Obiettivo

Aggiungere supporto GraphQL completo a BetterController con:
- Schema auto-generato dai model/ResourcesController
- Paginazione cursor-based (Relay) e offset-based
- Integrazione con sistemi auth esistenti (Pundit, CanCan)
- Sicurezza e performance best practices

## Decisioni di Design

| Aspetto | Scelta | Rationale |
|---------|--------|-----------|
| Rate Limiting | `Rails.cache` | Nessuna dipendenza extra, backend pluggabile |
| Type Generation | File fisici via generator | Più controllo, customizzazione, visibilità |
| Paginazione | Entrambe (Relay + Offset) | Flessibilità per diversi casi d'uso |
| Auth | Riutilizzo Pundit/CanCan | Coerenza con pattern esistenti |

---

## Struttura File

```
lib/better_controller/
├── graphql.rb                          # Loader principale
├── graphql/
│   ├── configuration.rb                # Config GraphQL-specific
│   ├── exposable.rb                    # Concern principale (graphql_expose)
│   │
│   ├── dsl/
│   │   ├── expose_builder.rb           # DSL per graphql_expose block
│   │   ├── field_builder.rb            # Builder per field definition
│   │   └── pagination_builder.rb       # Builder per pagination config
│   │
│   ├── types/
│   │   ├── base_object.rb              # Base type con auth hooks
│   │   ├── base_field.rb               # Field con authorize option
│   │   ├── base_input_type.rb          # Input type base
│   │   ├── model_type_generator.rb     # Genera type da AR model
│   │   └── pagination_types.rb         # PageInfo, Connection types
│   │
│   ├── resolvers/
│   │   ├── base_resolver.rb            # Resolver base
│   │   ├── collection_resolver.rb      # Query collection (index)
│   │   └── record_resolver.rb          # Query singolo record (show)
│   │
│   ├── mutations/
│   │   ├── base_mutation.rb            # Mutation base con validation
│   │   ├── create_mutation.rb          # Create template
│   │   ├── update_mutation.rb          # Update template
│   │   └── destroy_mutation.rb         # Destroy template
│   │
│   ├── authorization/
│   │   ├── field_authorizer.rb         # Interface auth field-level
│   │   ├── pundit_authorizer.rb        # Integrazione Pundit
│   │   └── cancan_authorizer.rb        # Integrazione CanCan
│   │
│   ├── pagination/
│   │   ├── relay_connection.rb         # Cursor-based (Relay spec)
│   │   ├── offset_connection.rb        # Offset-based (page/perPage)
│   │   └── hybrid_connection.rb        # Supporta entrambi
│   │
│   ├── security/
│   │   ├── query_analyzer.rb           # Depth/complexity limiting
│   │   ├── rate_limiter.rb             # Rate limiting via Rails.cache
│   │   └── introspection_control.rb    # Disable in production
│   │
│   ├── loading/
│   │   ├── association_loader.rb       # Batch load associations
│   │   └── record_loader.rb            # Batch load by ID
│   │
│   └── schema/
│       └── schema_builder.rb           # Costruisce schema da controllers
│
lib/generators/better_controller/graphql/
├── install_generator.rb                # Setup iniziale
├── type_generator.rb                   # Genera type da model
├── controller_generator.rb             # Genera controller GraphQL
└── templates/
    ├── initializer.rb.tt
    ├── base_type.rb.tt
    ├── schema.rb.tt
    └── graphql_controller.rb.tt
```

---

## API Pubblica

### Setup Minimo (1 linea)

```ruby
class UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController
  include BetterController::GraphQL::Exposable

  graphql_expose :users  # Auto-genera tutto da User model
end
```

### Setup Customizzato

```ruby
class UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController
  include BetterController::GraphQL::Exposable

  graphql_expose :users do
    # Campi
    fields :id, :name, :email, :created_at
    exclude_fields :password_digest, :reset_token

    # Associazioni
    has_many :posts
    belongs_to :organization

    # Paginazione
    pagination :relay  # o :offset, o :both

    # Filtri e ordinamento
    filterable_by :email, :status, :created_at
    sortable_by :name, :created_at

    # Autorizzazione (riusa Pundit policy esistente)
    authorize_with :pundit
    scope -> { policy_scope(User) }
  end
end
```

### GraphQL Queries Risultanti

**Relay-style (cursor):**
```graphql
query {
  users(first: 10, after: "cursor123") {
    edges {
      cursor
      node { id name email }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

**Offset-style:**
```graphql
query {
  users(page: 2, perPage: 25) {
    nodes { id name email }
    pageInfo {
      currentPage
      totalPages
      totalCount
    }
  }
}
```

**Mutations:**
```graphql
mutation {
  createUser(input: { name: "John", email: "john@example.com" }) {
    user { id name }
    errors
  }
}
```

---

## Configurazione

```ruby
# config/initializers/better_controller.rb
BetterController.configure do |config|
  # === GraphQL Core ===
  config.graphql_enabled = true
  config.graphql_schema_path = 'app/graphql'

  # === Paginazione ===
  config.graphql_default_pagination = :relay  # :relay, :offset, :both
  config.graphql_default_page_size = 25
  config.graphql_max_page_size = 100

  # === Sicurezza ===
  config.graphql_max_depth = 10
  config.graphql_max_complexity = 200
  config.graphql_timeout_ms = 30_000
  config.graphql_introspection = :auto  # :auto, :enabled, :disabled

  # === Rate Limiting (usa Rails.cache) ===
  config.graphql_rate_limiting_enabled = true
  config.graphql_rate_limit_authenticated = { requests: 100, window: 60 }
  config.graphql_rate_limit_anonymous = { requests: 50, window: 60 }

  # === Autorizzazione ===
  config.graphql_authorization_adapter = :pundit  # :pundit, :cancan, :none

  # === Auto-generation ===
  config.graphql_auto_expose_fields = true
  config.graphql_exclude_fields = [:password_digest, :encrypted_password, :reset_token]
end
```

---

## Generators

### Install

```bash
rails generate better_controller:graphql:install
```

Crea:
- `config/initializers/better_controller_graphql.rb`
- `app/graphql/types/base_object.rb`
- `app/graphql/types/base_field.rb`
- `app/graphql/better_controller_schema.rb`

### Type da Model

```bash
rails generate better_controller:graphql:type User
```

Crea `app/graphql/types/user_type.rb` con tutti i campi del model.

### Controller GraphQL

```bash
rails generate better_controller:graphql:controller Users
```

Crea controller con `graphql_expose` configurato.

---

## Sicurezza

### Query Depth/Complexity

```ruby
# Automatico - analizza query prima dell'esecuzione
# Rifiuta query troppo profonde o complesse
```

### Rate Limiting

```ruby
# Usa Rails.cache come backend
# Supporta qualsiasi cache store (memory, Redis, Memcached)
# Headers X-RateLimit-* nella response
```

### Introspection Control

- **Development**: abilitato
- **Production**: disabilitato (configurabile)
- **Opzione**: solo per admin autenticati

### Field-Level Authorization

```ruby
# Riusa le Pundit policy esistenti
class UserPolicy < ApplicationPolicy
  def email?  # GraphQL field :email
    user == record || user.admin?
  end

  def salary?  # GraphQL field :salary
    user.admin? || user.hr?
  end
end
```

---

## N+1 Prevention

```ruby
# Automatic batch loading con GraphQL::Dataloader
class UserType < Types::BaseObject
  field :posts, [PostType], null: false

  def posts
    dataloader.with(AssociationLoader, User, :posts).load(object)
  end
end
```

---

## File Critici da Modificare

| File | Modifiche |
|------|-----------|
| `lib/better_controller.rb` | Aggiungere require condizionale per graphql |
| `lib/better_controller/configuration.rb` | Aggiungere tutti i config graphql_* |
| `lib/better_controller/controllers/resources_controller.rb` | Pattern di riferimento (non modificare) |
| `lib/better_controller/dsl/action_builder.rb` | Pattern DSL di riferimento (non modificare) |
| `lib/better_controller/utils/pagination.rb` | Estendere per cursor-based |
| `better_controller.gemspec` | Aggiungere graphql come optional dependency |

---

## Fasi di Implementazione

### Fase 1: Core Infrastructure
1. `lib/better_controller/graphql.rb` - loader
2. `lib/better_controller/graphql/configuration.rb` - config options
3. `lib/better_controller/graphql/exposable.rb` - concern principale
4. `lib/better_controller/graphql/dsl/expose_builder.rb` - DSL

### Fase 2: Types e Generation
5. `types/base_object.rb`, `base_field.rb`, `base_input_type.rb`
6. `types/model_type_generator.rb` - genera da AR model
7. `types/pagination_types.rb` - PageInfo, Connection

### Fase 3: Resolvers e Mutations
8. `resolvers/base_resolver.rb`, `collection_resolver.rb`, `record_resolver.rb`
9. `mutations/base_mutation.rb`, `create_mutation.rb`, `update_mutation.rb`, `destroy_mutation.rb`

### Fase 4: Paginazione
10. `pagination/relay_connection.rb` - cursor-based
11. `pagination/offset_connection.rb` - offset-based
12. `pagination/hybrid_connection.rb` - supporta entrambi

### Fase 5: Authorization
13. `authorization/field_authorizer.rb` - interface
14. `authorization/pundit_authorizer.rb`
15. `authorization/cancan_authorizer.rb`

### Fase 6: Security
16. `security/query_analyzer.rb` - depth/complexity
17. `security/rate_limiter.rb` - Rails.cache based
18. `security/introspection_control.rb`

### Fase 7: Performance
19. `loading/association_loader.rb`
20. `loading/record_loader.rb`

### Fase 8: Schema Builder
21. `schema/schema_builder.rb` - assembla schema da controllers

### Fase 9: Generators
22. `install_generator.rb` + templates
23. `type_generator.rb` + templates
24. `controller_generator.rb` + templates

### Fase 10: Testing e Docs
25. Specs per ogni modulo
26. Integration tests
27. README e examples

---

## Dipendenze

```ruby
# better_controller.gemspec
spec.add_dependency 'graphql', '>= 2.0'  # Optional, required only if graphql_enabled
```

Conditional loading:

```ruby
# lib/better_controller/graphql.rb
raise LoadError, "graphql gem required" unless defined?(GraphQL)
```

---

## Status

- [ ] Fase 1: Core Infrastructure
- [ ] Fase 2: Types e Generation
- [ ] Fase 3: Resolvers e Mutations
- [ ] Fase 4: Paginazione
- [ ] Fase 5: Authorization
- [ ] Fase 6: Security
- [ ] Fase 7: Performance
- [ ] Fase 8: Schema Builder
- [ ] Fase 9: Generators
- [ ] Fase 10: Testing e Docs
