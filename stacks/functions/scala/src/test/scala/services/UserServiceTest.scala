package services

import cats.effect.IO
import cats.effect.testing.scalatest.AsyncIOSpec
import models.{User, CreateUserRequest, UpdateUserRequest, AppError}
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers

class UserServiceTest extends AsyncFreeSpec with AsyncIOSpec with Matchers {

  "UserService" - {
    
    "createUser" - {
      "should create a user with valid data" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          service.createUser(request).map { user =>
            user.name shouldBe "Jan Kowalski"
            user.email shouldBe "jan@example.com"
            user.age shouldBe 30
            user.isActive shouldBe true
            user.id shouldBe 1L
          }
        }
      }

      "should reject empty name" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("", "jan@example.com", 30)
          service.createUser(request).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Nazwa użytkownika nie może być pusta")
          }
        }
      }

      "should reject invalid email" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "invalid-email", 30)
          service.createUser(request).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Nieprawidłowy format email")
          }
        }
      }

      "should reject negative age" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", -5)
          service.createUser(request).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Wiek musi być między 0 a 150 lat")
          }
        }
      }

      "should reject age over 150" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 200)
          service.createUser(request).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Wiek musi być między 0 a 150 lat")
          }
        }
      }

      "should reject duplicate email" in {
        UserService.create.flatMap { service =>
          val request1 = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          val request2 = CreateUserRequest("Anna Nowak", "jan@example.com", 25)
          
          for {
            _ <- service.createUser(request1)
            result <- service.createUser(request2).attempt
          } yield {
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Użytkownik z tym emailem już istnieje")
          }
        }
      }
    }

    "getUserById" - {
      "should return user if exists" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          for {
            createdUser <- service.createUser(request)
            retrievedUser <- service.getUserById(createdUser.id)
          } yield {
            retrievedUser shouldBe createdUser
          }
        }
      }

      "should return NotFoundError if user doesn't exist" in {
        UserService.create.flatMap { service =>
          service.getUserById(999L).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Użytkownik o ID 999 nie został znaleziony")
          }
        }
      }
    }

    "getAllUsers" - {
      "should return empty list initially" in {
        UserService.create.flatMap { service =>
          service.getAllUsers(1, 10).map { users =>
            users shouldBe empty
          }
        }
      }

      "should return all users with pagination" in {
        UserService.create.flatMap { service =>
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 30),
            CreateUserRequest("Anna Nowak", "anna@example.com", 25),
            CreateUserRequest("Piotr Wiśniewski", "piotr@example.com", 35)
          )
          
          for {
            _ <- requests.traverse(service.createUser)
            users <- service.getAllUsers(1, 2)
            allUsers <- service.getAllUsers(1, 10)
          } yield {
            users.length shouldBe 2
            allUsers.length shouldBe 3
            allUsers.map(_.name) should contain allOf("Jan Kowalski", "Anna Nowak", "Piotr Wiśniewski")
          }
        }
      }
    }

    "updateUser" - {
      "should update user with valid data" in {
        UserService.create.flatMap { service =>
          val createRequest = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          val updateRequest = UpdateUserRequest(name = Some("Jan Nowy"), age = Some(31))
          
          for {
            createdUser <- service.createUser(createRequest)
            updatedUser <- service.updateUser(createdUser.id, updateRequest)
          } yield {
            updatedUser.name shouldBe "Jan Nowy"
            updatedUser.email shouldBe "jan@example.com"
            updatedUser.age shouldBe 31
            updatedUser.id shouldBe createdUser.id
          }
        }
      }

      "should return NotFoundError if user doesn't exist" in {
        UserService.create.flatMap { service =>
          val updateRequest = UpdateUserRequest(name = Some("Jan Nowy"))
          service.updateUser(999L, updateRequest).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Użytkownik o ID 999 nie został znaleziony")
          }
        }
      }
    }

    "deleteUser" - {
      "should delete existing user" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          for {
            createdUser <- service.createUser(request)
            _ <- service.deleteUser(createdUser.id)
            result <- service.getUserById(createdUser.id).attempt
          } yield {
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
          }
        }
      }

      "should return NotFoundError if user doesn't exist" in {
        UserService.create.flatMap { service =>
          service.deleteUser(999L).attempt.map { result =>
            result.isLeft shouldBe true
            result.left.get shouldBe a[AppError]
            result.left.get.asInstanceOf[AppError].message should include("Użytkownik o ID 999 nie został znaleziony")
          }
        }
      }
    }

    "searchUsers" - {
      "should find users by name" in {
        UserService.create.flatMap { service =>
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 30),
            CreateUserRequest("Anna Nowak", "anna@example.com", 25),
            CreateUserRequest("Piotr Kowalski", "piotr@example.com", 35)
          )
          
          for {
            _ <- requests.traverse(service.createUser)
            results <- service.searchUsers("Kowalski")
          } yield {
            results.length shouldBe 2
            results.map(_.name) should contain allOf("Jan Kowalski", "Piotr Kowalski")
          }
        }
      }

      "should find users by email" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan.kowalski@example.com", 30)
          for {
            _ <- service.createUser(request)
            results <- service.searchUsers("kowalski")
          } yield {
            results.length shouldBe 1
            results.head.email shouldBe "jan.kowalski@example.com"
          }
        }
      }

      "should return empty list for non-matching query" in {
        UserService.create.flatMap { service =>
          val request = CreateUserRequest("Jan Kowalski", "jan@example.com", 30)
          for {
            _ <- service.createUser(request)
            results <- service.searchUsers("NonExistent")
          } yield {
            results shouldBe empty
          }
        }
      }
    }
  }
}
