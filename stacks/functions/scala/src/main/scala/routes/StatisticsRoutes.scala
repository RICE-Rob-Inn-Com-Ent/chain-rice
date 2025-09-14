package routes

import cats.effect.IO
import org.http4s.{HttpRoutes}
import org.http4s.dsl.io.*
import org.http4s.circe.*
import org.http4s.circe.CirceEntityEncoder.*
import services.{StatisticsService, UserStatistics}
import models.ApiResponse
import io.circe.generic.auto.*

class StatisticsRoutes(statisticsService: StatisticsService[IO]) {

  val routes: HttpRoutes[IO] = HttpRoutes.of[IO] {
    // GET /statistics/users - statystyki użytkowników
    case GET -> Root / "statistics" / "users" =>
      statisticsService.getUserStatistics
        .map(ApiResponse.success(_))
        .flatMap(response => Ok(response))

    // GET /statistics/age-distribution - rozkład wieku
    case GET -> Root / "statistics" / "age-distribution" =>
      statisticsService.getAgeDistribution
        .map(ApiResponse.success(_))
        .flatMap(response => Ok(response))

    // GET /statistics/active-count - liczba aktywnych użytkowników
    case GET -> Root / "statistics" / "active-count" =>
      statisticsService.getActiveUsersCount
        .map(ApiResponse.success(_))
        .flatMap(response => Ok(response))
  }
}
