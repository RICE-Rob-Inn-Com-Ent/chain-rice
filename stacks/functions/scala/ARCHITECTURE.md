# Architektura Aplikacji Scala ⭐⭐⭐⭐☆

## 🏗️ Przegląd Architektury

Aplikacja wykorzystuje **funkcyjną architekturę** z wykorzystaniem popularnych bibliotek Scala:
- **Http4s** - funkcyjny HTTP server
- **Cats Effect** - efekty asynchroniczne i resource management
- **Circe** - automatyczna serializacja/deserializacja JSON
- **ScalaTest** - kompleksowe testowanie

## 📁 Struktura Projektu

```
scala/
├── build.sbt                           # Konfiguracja projektu i zależności
├── src/main/scala/
│   ├── main/
│   │   └── App.scala                   # Główna aplikacja i konfiguracja serwera
│   ├── models/                         # Modele danych i typy
│   │   ├── User.scala                  # Model użytkownika i DTOs
│   │   ├── ApiResponse.scala           # Wrapper dla odpowiedzi API
│   │   └── AppError.scala              # Typowane błędy aplikacji
│   ├── services/                       # Logika biznesowa
│   │   ├── UserService.scala          # Serwis zarządzania użytkownikami
│   │   └── StatisticsService.scala    # Serwis statystyk i analizy
│   └── routes/                        # HTTP endpoints
│       ├── UserRoutes.scala           # Endpointy dla użytkowników
│       └── StatisticsRoutes.scala    # Endpointy dla statystyk
├── src/test/scala/                     # Testy jednostkowe i integracyjne
│   ├── services/
│   │   ├── UserServiceTest.scala
│   │   └── StatisticsServiceTest.scala
│   └── routes/
│       └── UserRoutesTest.scala
└── README.md                           # Dokumentacja
```

## 🔧 Warstwy Architektury

### 1. Warstwa Modeli (`models/`)

**Odpowiedzialność**: Definicje typów danych i serializacja

```scala
// Przykład: User.scala
case class User(id: Long, name: String, email: String, age: Int, isActive: Boolean)

// Automatyczna serializacja JSON z Circe
implicit val userEncoder: Encoder[User] = deriveEncoder[User]
implicit val userDecoder: Decoder[User] = deriveDecoder[User]
```

**Kluczowe wzorce**:
- **Case Classes**: Immutable data structures
- **Type Safety**: Silne typowanie dla bezpieczeństwa
- **JSON Codecs**: Automatyczna serializacja z Circe

### 2. Warstwa Serwisów (`services/`)

**Odpowiedzialność**: Logika biznesowa i operacje na danych

```scala
// Przykład: UserService.scala
trait UserService[F[_]] {
  def createUser(request: CreateUserRequest): F[User]
  def getUserById(id: Long): F[User]
  // ...
}

class InMemoryUserService[F[_]: Monad] extends UserService[F] {
  // Implementacja z walidacją i obsługą błędów
}
```

**Kluczowe wzorce**:
- **Type Classes**: Abstrakcje funkcyjne (`Monad`, `Applicative`)
- **Error Handling**: Typowane błędy z `Either`/`Raise`
- **Resource Management**: Bezpieczne zarządzanie zasobami
- **Validation**: Walidacja danych wejściowych

### 3. Warstwa Routingu (`routes/`)

**Odpowiedzialność**: HTTP endpoints i obsługa żądań

```scala
// Przykład: UserRoutes.scala
class UserRoutes(userService: UserService[IO]) {
  val routes: HttpRoutes[IO] = HttpRoutes.of[IO] {
    case GET -> Root / "users" => 
      userService.getAllUsers().map(ApiResponse.success(_))
    // ...
  }
}
```

**Kluczowe wzorce**:
- **HTTP DSL**: Deklaratywne definiowanie endpointów
- **Middleware**: CORS, logging, request ID
- **Error Mapping**: Mapowanie błędów na kody HTTP
- **JSON Handling**: Automatyczna serializacja odpowiedzi

### 4. Warstwa Aplikacji (`main/`)

**Odpowiedzialność**: Konfiguracja i uruchomienie aplikacji

```scala
// Przykład: App.scala
object App extends IOApp {
  override def run(args: List[String]): IO[ExitCode] = {
    createServer.use { server =>
      logger.info("🚀 Serwer uruchomiony") *> IO.never
    }
  }
}
```

**Kluczowe wzorce**:
- **Resource Management**: Bezpieczne zarządzanie serwerem
- **Dependency Injection**: Manual DI z funkcjami
- **Configuration**: Konfiguracja serwera i middleware
- **Graceful Shutdown**: Bezpieczne zamykanie aplikacji

## 🧪 Warstwa Testowa

### Testy Jednostkowe Serwisów
```scala
class UserServiceTest extends AsyncFreeSpec with AsyncIOSpec {
  "createUser" - {
    "should create user with valid data" in {
      UserService.create.flatMap { service =>
        service.createUser(request).map { user =>
          user.name shouldBe "Jan Kowalski"
        }
      }
    }
  }
}
```

### Testy Integracyjne HTTP
```scala
class UserRoutesTest extends AsyncFreeSpec with AsyncIOSpec {
  "POST /users" - {
    "should create user successfully" in {
      createTestApp.flatMap { app =>
        val req = Request[IO](Method.POST, uri"/users").withEntity(request)
        app.run(req).flatMap { response =>
          response.status shouldBe Status.Created
        }
      }
    }
  }
}
```

## 🔄 Flow Aplikacji

### 1. Żądanie HTTP
```
Client Request → Http4s Server → CORS Middleware → Routes
```

### 2. Przetwarzanie
```
Routes → Service Layer → Business Logic → Data Validation
```

### 3. Odpowiedź
```
Data → JSON Serialization → HTTP Response → Client
```

## 🛠️ Build i Deployment

### Kompilacja
```bash
# Kompilacja projektu
sbt compile

# Uruchomienie aplikacji
sbt run

# Uruchomienie testów
sbt test

# Tworzenie JAR
sbt assembly
```

### Zależności
```scala
// build.sbt
libraryDependencies ++= Seq(
  "org.http4s" %% "http4s-ember-server" % "0.23.24",
  "org.typelevel" %% "cats-effect" % "3.5.2",
  "io.circe" %% "circe-generic" % "0.14.6",
  "org.scalatest" %% "scalatest" % "3.2.17" % Test
)
```

## 🚀 Rozszerzenia i Ulepszenia

### 1. Integracja z Bazą Danych
```scala
// Przykład z Doobie (SQL)
class DatabaseUserService[F[_]: Async](xa: Transactor[F]) 
  extends UserService[F] {
  
  def createUser(request: CreateUserRequest): F[User] = {
    sql"INSERT INTO users (name, email, age) VALUES (${request.name}, ${request.email}, ${request.age})"
      .update
      .withUniqueGeneratedKeys[User]("id", "name", "email", "age", "is_active")
      .transact(xa)
  }
}
```

### 2. Konfiguracja z PureConfig
```scala
case class AppConfig(
  server: ServerConfig,
  database: DatabaseConfig
)

case class ServerConfig(
  host: String,
  port: Int
)
```

### 3. Monitoring i Metryki
```scala
// Integracja z Micrometer
class MetricsMiddleware[F[_]: Async] {
  def apply(routes: HttpRoutes[F]): HttpRoutes[F] = {
    // Dodanie metryk HTTP
  }
}
```

### 4. Autentykacja i Autoryzacja
```scala
// JWT Middleware
class AuthMiddleware[F[_]: Async] {
  def authenticate(routes: HttpRoutes[F]): HttpRoutes[F] = {
    // Walidacja JWT tokenów
  }
}
```

### 5. Cache z Redis
```scala
class CachedUserService[F[_]: Async](
  userService: UserService[F],
  redis: RedisCommands[F, String, String]
) extends UserService[F] {
  
  override def getUserById(id: Long): F[User] = {
    redis.get(s"user:$id").flatMap {
      case Some(json) => IO.fromEither(io.circe.parser.decode[User](json))
      case None => userService.getUserById(id).flatMap { user =>
        redis.set(s"user:$id", user.asJson.noSpaces).as(user)
      }
    }
  }
}
```

## 📊 Wzorce Funkcyjne

### 1. Monadic Error Handling
```scala
def createUser(request: CreateUserRequest): IO[User] = {
  validateRequest(request)
    .flatMap(userService.createUser)
    .handleErrorWith {
      case ValidationError(msg) => IO.raiseError(BadRequest(msg))
      case ConflictError(msg) => IO.raiseError(Conflict(msg))
    }
}
```

### 2. Resource Management
```scala
def createServer: Resource[IO, Server] = {
  for {
    userService <- Resource.eval(UserService.create)
    server <- EmberServerBuilder.default[IO]
      .withHttpApp(createHttpApp(userService))
      .build
  } yield server
}
```

### 3. Type-Safe Configuration
```scala
case class DatabaseConfig(
  url: String,
  username: String,
  password: String,
  maxConnections: Int
)

object DatabaseConfig {
  implicit val configReader: ConfigReader[DatabaseConfig] = 
    deriveReader[DatabaseConfig]
}
```

## 🔍 Debugging i Profiling

### Logowanie
```scala
import org.typelevel.log4cats.slf4j.Slf4jLogger

implicit val logger: Logger[IO] = Slf4jLogger.getLogger[IO]

def createUser(request: CreateUserRequest): IO[User] = {
  logger.info(s"Creating user: ${request.name}") *>
  userService.createUser(request)
    .flatTap(user => logger.info(s"User created with ID: ${user.id}"))
}
```

### Health Checks
```scala
val healthRoutes: HttpRoutes[IO] = HttpRoutes.of[IO] {
  case GET -> Root / "health" => 
    Ok(Json.obj("status" -> "healthy".asJson))
}
```

## 🎯 Best Practices

1. **Immutability**: Używaj case classes i immutable collections
2. **Type Safety**: Wykorzystuj silne typowanie Scala
3. **Error Handling**: Używaj typowanych błędów zamiast exceptions
4. **Resource Management**: Zawsze używaj Resource dla zarządzania zasobami
5. **Testing**: Pisz testy dla każdej warstwy aplikacji
6. **Documentation**: Dokumentuj API endpoints i modele danych
7. **Performance**: Monitoruj wydajność i używaj cache gdzie to możliwe

Ta architektura zapewnia skalowalność, maintainability i type safety, jednocześnie wykorzystując najlepsze praktyki programowania funkcyjnego w Scali.


