package routes

import cats.effect.IO
import cats.effect.testing.scalatest.AsyncIOSpec
import org.http4s.*
import org.http4s.circe.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.circe.CirceEntityDecoder.*
import org.http4s.dsl.io.*
import org.http4s.implicits.*
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers
import services.UserService
import models.{CreateUserRequest, UpdateUserRequest, ApiResponse, User}

class UserRoutesTest extends AsyncFreeSpec with AsyncIOSpec with Matchers {

  private def createTestApp: IO[HttpApp[IO]] = {
    UserService.create.map { userService =>
      val routes = new UserRoutes(userService)
      routes.routes.orNotFound
    }
  }

  "UserRoutes" - {
    
    "POST /users" - {
      "should create a user successfully" in {
        createTestApp.flatMap { app =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          val req = Request[IO](Method.POST, uri"/users")
            .withEntity(request)
          
          app.run(req).flatMap { response =>
            response.status shouldBe Status.Created
            response.as[ApiResponse[User]].map { apiResponse =>
              apiResponse.success shouldBe true
              apiResponse.data shouldBe defined
              apiResponse.data.get.name shouldBe "Jan Kowalski"
              apiResponse.data.get.email shouldBe "jan@example.com"
              apiResponse.data.get.age shouldBe 30
            }
          }
        }
      }

      "should return BadRequest for invalid data" in {
        createTestApp.flatMap { app =>
          val request = CreateUserRequest("", "invalid-email", -5)
          val req = Request[IO](Method.POST, uri"/users")
            .withEntity(request)
          
          app.run(req).flatMap { response =>
            response.status shouldBe Status.BadRequest
            response.as[ApiResponse[Nothing]].map { apiResponse =>
              apiResponse.success shouldBe false
              apiResponse.error shouldBe defined
            }
          }
        }
      }
    }

    "GET /users" - {
      "should return empty list initially" in {
        createTestApp.flatMap { app =>
          val req = Request[IO](Method.GET, uri"/users")
          
          app.run(req).flatMap { response =>
            response.status shouldBe Status.Ok
            response.as[ApiResponse[models.PaginatedResponse[User]]].map { apiResponse =>
              apiResponse.success shouldBe true
              apiResponse.data shouldBe defined
              apiResponse.data.get.data shouldBe empty
              apiResponse.data.get.totalCount shouldBe 0
            }
          }
        }
      }

      "should return users with pagination" in {
        createTestApp.flatMap { app =>
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 30),
            CreateUserRequest("Anna Nowak", "anna@example.com", 25)
          )
          
          // Create users first
          val createRequests = requests.map { request =>
            Request[IO](Method.POST, uri"/users").withEntity(request)
          }
          
          for {
            _ <- createRequests.traverse(app.run)
            // Now get users
            getReq = Request[IO](Method.GET, uri"/users")
            response <- app.run(getReq)
            apiResponse <- response.as[ApiResponse[models.PaginatedResponse[User]]]
          } yield {
            response.status shouldBe Status.Ok
            apiResponse.success shouldBe true
            apiResponse.data shouldBe defined
            apiResponse.data.get.data.length shouldBe 2
            apiResponse.data.get.totalCount shouldBe 2
          }
        }
      }
    }

    "GET /users/:id" - {
      "should return user if exists" in {
        createTestApp.flatMap { app =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          val createReq = Request[IO](Method.POST, uri"/users").withEntity(request)
          
          for {
            createResponse <- app.run(createReq)
            createdUser <- createResponse.as[ApiResponse[User]]
            // Get the created user
            getReq = Request[IO](Method.GET, uri"/users/1")
            getResponse <- app.run(getReq)
            apiResponse <- getResponse.as[ApiResponse[User]]
          } yield {
            getResponse.status shouldBe Status.Ok
            apiResponse.success shouldBe true
            apiResponse.data shouldBe defined
            apiResponse.data.get.name shouldBe "Jan Kowalski"
          }
        }
      }

      "should return NotFound for non-existent user" in {
        createTestApp.flatMap { app =>
          val req = Request[IO](Method.GET, uri"/users/999")
          
          app.run(req).flatMap { response =>
            response.status shouldBe Status.NotFound
            response.as[ApiResponse[Nothing]].map { apiResponse =>
              apiResponse.success shouldBe false
              apiResponse.error shouldBe defined
            }
          }
        }
      }
    }

    "PUT /users/:id" - {
      "should update user successfully" in {
        createTestApp.flatMap { app =>
          val createRequest = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          val updateRequest = UpdateUserRequest(name = Some("Jan Nowy"), age = Some(31))
          
          val createReq = Request[IO](Method.POST, uri"/users").withEntity(createRequest)
          
          for {
            _ <- app.run(createReq)
            updateReq = Request[IO](Method.PUT, uri"/users/1").withEntity(updateRequest)
            updateResponse <- app.run(updateReq)
            apiResponse <- updateResponse.as[ApiResponse[User]]
          } yield {
            updateResponse.status shouldBe Status.Ok
            apiResponse.success shouldBe true
            apiResponse.data shouldBe defined
            apiResponse.data.get.name shouldBe "Jan Nowy"
            apiResponse.data.get.age shouldBe 31
          }
        }
      }
    }

    "DELETE /users/:id" - {
      "should delete user successfully" in {
        createTestApp.flatMap { app =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          val createReq = Request[IO](Method.POST, uri"/users").withEntity(request)
          
          for {
            _ <- app.run(createReq)
            deleteReq = Request[IO](Method.DELETE, uri"/users/1")
            deleteResponse <- app.run(deleteReq)
            apiResponse <- deleteResponse.as[ApiResponse[Unit]]
          } yield {
            deleteResponse.status shouldBe Status.Ok
            apiResponse.success shouldBe true
            apiResponse.message shouldBe Some("Użytkownik został usunięty")
          }
        }
      }
    }

    "GET /users/search" - {
      "should search users by name" in {
        createTestApp.flatMap { app =>
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 30),
            CreateUserRequest("Anna Nowak", "anna@example.com", 25)
          )
          
          val createRequests = requests.map { request =>
            Request[IO](Method.POST, uri"/users").withEntity(request)
          }
          
          for {
            _ <- createRequests.traverse(app.run)
            searchReq = Request[IO](Method.GET, uri"/users/search?q=Kowalski")
            searchResponse <- app.run(searchReq)
            apiResponse <- searchResponse.as[ApiResponse[List[User]]]
          } yield {
            searchResponse.status shouldBe Status.Ok
            apiResponse.success shouldBe true
            apiResponse.data shouldBe defined
            apiResponse.data.get.length shouldBe 1
            apiResponse.data.get.head.name shouldBe "Jan Kowalski"
          }
        }
      }

      "should return BadRequest for missing query parameter" in {
        createTestApp.flatMap { app =>
          val req = Request[IO](Method.GET, uri"/users/search")
          
          app.run(req).flatMap { response =>
            response.status shouldBe Status.BadRequest
            response.as[ApiResponse[Nothing]].map { apiResponse =>
              apiResponse.success shouldBe false
              apiResponse.error shouldBe defined
            }
          }
        }
      }
    }
  }
}
