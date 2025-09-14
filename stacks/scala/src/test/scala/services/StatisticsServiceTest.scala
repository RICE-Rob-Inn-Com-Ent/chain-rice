package services

import cats.effect.IO
import cats.effect.testing.scalatest.AsyncIOSpec
import models.CreateUserRequest
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers

class StatisticsServiceTest extends AsyncFreeSpec with AsyncIOSpec with Matchers {

  "StatisticsService" - {
    
    "getUserStatistics" - {
      "should return correct statistics for empty user list" in {
        UserService.create.flatMap { userService =>
          val statisticsService = StatisticsService.create(userService)
          statisticsService.getUserStatistics.map { stats =>
            stats.totalUsers shouldBe 0
            stats.activeUsers shouldBe 0
            stats.inactiveUsers shouldBe 0
            stats.averageAge shouldBe 0.0
            stats.youngestUser shouldBe None
            stats.oldestUser shouldBe None
          }
        }
      }

      "should return correct statistics for multiple users" in {
        UserService.create.flatMap { userService =>
          val statisticsService = StatisticsService.create(userService)
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 30),
            CreateUserRequest("Anna Nowak", "anna@example.com", 25),
            CreateUserRequest("Piotr Wiśniewski", "piotr@example.com", 35)
          )
          
          for {
            users <- requests.traverse(userService.createUser)
            stats <- statisticsService.getUserStatistics
          } yield {
            stats.totalUsers shouldBe 3
            stats.activeUsers shouldBe 3
            stats.inactiveUsers shouldBe 0
            stats.averageAge shouldBe 30.0
            stats.youngestUser shouldBe defined
            stats.youngestUser.get.age shouldBe 25
            stats.oldestUser shouldBe defined
            stats.oldestUser.get.age shouldBe 35
          }
        }
      }
    }

    "getAgeDistribution" - {
      "should return correct age distribution" in {
        UserService.create.flatMap { userService =>
          val statisticsService = StatisticsService.create(userService)
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 20), // 18-24
            CreateUserRequest("Anna Nowak", "anna@example.com", 30),  // 25-34
            CreateUserRequest("Piotr Wiśniewski", "piotr@example.com", 40), // 35-49
            CreateUserRequest("Maria Kowalczyk", "maria@example.com", 20), // 18-24
            CreateUserRequest("Tomasz Nowak", "tomasz@example.com", 60)   // 50-64
          )
          
          for {
            _ <- requests.traverse(userService.createUser)
            distribution <- statisticsService.getAgeDistribution
          } yield {
            distribution("18-24") shouldBe 2
            distribution("25-34") shouldBe 1
            distribution("35-49") shouldBe 1
            distribution("50-64") shouldBe 1
            distribution.get("0-17") shouldBe None
            distribution.get("65+") shouldBe None
          }
        }
      }

      "should handle edge cases in age ranges" in {
        UserService.create.flatMap { userService =>
          val statisticsService = StatisticsService.create(userService)
          val requests = List(
            CreateUserRequest("Child", "child@example.com", 10),    // 0-17
            CreateUserRequest("Senior", "senior@example.com", 70)    // 65+
          )
          
          for {
            _ <- requests.traverse(userService.createUser)
            distribution <- statisticsService.getAgeDistribution
          } yield {
            distribution("0-17") shouldBe 1
            distribution("65+") shouldBe 1
          }
        }
      }
    }

    "getActiveUsersCount" - {
      "should return correct count of active users" in {
        UserService.create.flatMap { userService =>
          val statisticsService = StatisticsService.create(userService)
          val requests = List(
            CreateUserRequest("Jan Kowalski", "jan@example.com", 30),
            CreateUserRequest("Anna Nowak", "anna@example.com", 25),
            CreateUserRequest("Piotr Wiśniewski", "piotr@example.com", 35)
          )
          
          for {
            users <- requests.traverse(userService.createUser)
            // Deactivate one user
            _ <- userService.updateUser(users(1).id, models.UpdateUserRequest(isActive = Some(false)))
            activeCount <- statisticsService.getActiveUsersCount
          } yield {
            activeCount shouldBe 2
          }
        }
      }
    }
  }
}
