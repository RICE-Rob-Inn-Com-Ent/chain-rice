package routes

import cats.effect.IO
import cats.implicits.*
import org.http4s.{HttpRoutes, ParseFailure, QueryParamDecoder}
import org.http4s.dsl.io.*
import org.http4s.circe.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.circe.CirceEntityDecoder.*
import services.UserService
import models.{User, CreateUserRequest, UpdateUserRequest, ApiResponse, PaginatedResponse, AppError}
import io.circe.syntax.*

class UserRoutes(userService: UserService[IO]) {

  private def handleError(error: Throwable): IO[ApiResponse[Nothing]] = {
    error match {
      case appError: AppError => 
        val status = appError match {
          case _: ValidationError => BadRequest
          case _: NotFoundError => NotFound
          case _: ConflictError => Conflict
          case _: DatabaseError => InternalServerError
          case _: ExternalServiceError => BadGateway
        }
        IO.pure(ApiResponse.error(appError.message))
      case _ => 
        IO.pure(ApiResponse.error("Wystąpił nieoczekiwany błąd"))
    }
  }

  val routes: HttpRoutes[IO] = HttpRoutes.of[IO] {
    // GET /users - pobierz wszystkich użytkowników z paginacją
    case GET -> Root / "users" :? pageParam(page) +& pageSizeParam(pageSize) =>
      val pageNum = page.getOrElse(1)
      val size = pageSize.getOrElse(10)
      
      userService.getAllUsers(pageNum, size)
        .flatMap { users =>
          userService.getAllUsers(1, Int.MaxValue).map { allUsers =>
            val totalPages = Math.ceil(allUsers.length.toDouble / size).toInt
            PaginatedResponse(
              data = users,
              totalCount = allUsers.length,
              page = pageNum,
              pageSize = size,
              totalPages = totalPages
            )
          }
        }
        .map(ApiResponse.success(_))
        .handleErrorWith(handleError)
        .flatMap(response => Ok(response))

    // GET /users/:id - pobierz użytkownika po ID
    case GET -> Root / "users" / LongVar(id) =>
      userService.getUserById(id)
        .map(ApiResponse.success(_))
        .handleErrorWith(handleError)
        .flatMap(response => Ok(response))

    // POST /users - utwórz nowego użytkownika
    case req @ POST -> Root / "users" =>
      req.as[CreateUserRequest]
        .flatMap(userService.createUser)
        .map(ApiResponse.success(_, Some("Użytkownik został utworzony")))
        .handleErrorWith(handleError)
        .flatMap(response => Created(response))

    // PUT /users/:id - zaktualizuj użytkownika
    case req @ PUT -> Root / "users" / LongVar(id) =>
      req.as[UpdateUserRequest]
        .flatMap(userService.updateUser(id, _))
        .map(ApiResponse.success(_, Some("Użytkownik został zaktualizowany")))
        .handleErrorWith(handleError)
        .flatMap(response => Ok(response))

    // DELETE /users/:id - usuń użytkownika
    case DELETE -> Root / "users" / LongVar(id) =>
      userService.deleteUser(id)
        .map(_ => ApiResponse.success((), Some("Użytkownik został usunięty")))
        .handleErrorWith(handleError)
        .flatMap(response => Ok(response))

    // GET /users/search?q=query - wyszukaj użytkowników
    case GET -> Root / "users" / "search" :? queryParam(query) =>
      query match {
        case Some(q) if q.nonEmpty =>
          userService.searchUsers(q)
            .map(ApiResponse.success(_))
            .handleErrorWith(handleError)
            .flatMap(response => Ok(response))
        case _ =>
          BadRequest(ApiResponse.error("Parametr wyszukiwania 'q' jest wymagany"))
      }
  }

  // Query parameter decoders
  implicit val pageQueryParamDecoder: QueryParamDecoder[Int] = 
    QueryParamDecoder.intQueryParamDecoder.emap { page =>
      if (page > 0) Right(page) else Left(ParseFailure("Invalid page", "Page must be positive"))
    }

  implicit val pageSizeQueryParamDecoder: QueryParamDecoder[Int] = 
    QueryParamDecoder.intQueryParamDecoder.emap { pageSize =>
      if (pageSize > 0 && pageSize <= 100) Right(pageSize) 
      else Left(ParseFailure("Invalid page size", "Page size must be between 1 and 100"))
    }

  object pageParam extends OptionalQueryParamDecoderMatcher[Int]("page")
  object pageSizeParam extends OptionalQueryParamDecoderMatcher[Int]("pageSize")
  object queryParam extends OptionalQueryParamDecoderMatcher[String]("q")
}
