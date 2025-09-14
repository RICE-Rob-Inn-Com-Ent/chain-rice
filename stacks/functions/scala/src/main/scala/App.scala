package main

import cats.effect.{IO, IOApp, Resource}
import org.http4s.ember.server.EmberServerBuilder
import org.http4s.server.middleware.{CORS, Logger, RequestId}
import org.http4s.{HttpApp, Request, Response}
import org.http4s.dsl.io.*
import org.http4s.circe.*
import org.http4s.circe.CirceEntityEncoder.*
import org.typelevel.log4cats.slf4j.Slf4jLogger
import org.typelevel.log4cats.Logger
import com.comcast.ip4s.*

import services.{UserService, StatisticsService}
import routes.{UserRoutes, StatisticsRoutes}
import models.ApiResponse

object App extends IOApp {

  implicit val logger: Logger[IO] = Slf4jLogger.getLogger[IO]

  private def createServices: IO[(UserService[IO], StatisticsService[IO])] = {
    for {
      userService <- UserService.create
      statisticsService = StatisticsService.create(userService)
    } yield (userService, statisticsService)
  }

  private def createHttpApp(userService: UserService[IO], statisticsService: StatisticsService[IO]): HttpApp[IO] = {
    val userRoutes = new UserRoutes(userService)
    val statisticsRoutes = new StatisticsRoutes(statisticsService)

    val routes = userRoutes.routes <+> statisticsRoutes.routes

    val corsMiddleware = CORS.policy
      .withAllowOriginAll
      .withAllowMethodsAll
      .withAllowHeadersAll

    val app = corsMiddleware(routes).orNotFound

    // Dodaj middleware dla logowania i request ID
    RequestId.httpRoutes[IO](app).map { case (requestId, response) =>
      response.withHeaders(response.headers.put(requestId))
    }
  }

  private def createServer: Resource[IO, org.http4s.server.Server] = {
    for {
      (userService, statisticsService) <- Resource.eval(createServices)
      httpApp = createHttpApp(userService, statisticsService)
      
      server <- EmberServerBuilder.default[IO]
        .withHost(host"0.0.0.0")
        .withPort(port"8080")
        .withHttpApp(httpApp)
        .build
    } yield server
  }

  override def run(args: List[String]): IO[ExitCode] = {
    createServer.use { server =>
      logger.info(s"🚀 Serwer Scala uruchomiony na porcie ${server.address.getPort}") *>
      logger.info("📚 Dostępne endpointy:") *>
      logger.info("  GET    /users                    - Lista użytkowników z paginacją") *>
      logger.info("  GET    /users/:id               - Pobierz użytkownika po ID") *>
      logger.info("  POST   /users                    - Utwórz nowego użytkownika") *>
      logger.info("  PUT    /users/:id               - Zaktualizuj użytkownika") *>
      logger.info("  DELETE /users/:id               - Usuń użytkownika") *>
      logger.info("  GET    /users/search?q=query    - Wyszukaj użytkowników") *>
      logger.info("  GET    /statistics/users         - Statystyki użytkowników") *>
      logger.info("  GET    /statistics/age-distribution - Rozkład wieku") *>
      logger.info("  GET    /statistics/active-count  - Liczba aktywnych użytkowników") *>
      logger.info("") *>
      logger.info("💡 Przykłady użycia:") *>
      logger.info("  curl -X POST http://localhost:8080/users \\") *>
      logger.info("    -H 'Content-Type: application/json' \\") *>
      logger.info("    -d '{\"name\":\"Jan Kowalski\",\"email\":\"jan@example.com\",\"age\":30}'") *>
      logger.info("") *>
      logger.info("  curl http://localhost:8080/users") *>
      logger.info("") *>
      logger.info("  curl http://localhost:8080/statistics/users") *>
      IO.never
    }
  }
}


