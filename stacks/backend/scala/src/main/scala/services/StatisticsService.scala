package services

import cats.effect.IO
import cats.implicits.*
import models.{User, AppError}

trait StatisticsService[F[_]] {
  def getUserStatistics: F[UserStatistics]
  def getAgeDistribution: F[Map[String, Int]]
  def getActiveUsersCount: F[Int]
}

case class UserStatistics(
  totalUsers: Int,
  activeUsers: Int,
  inactiveUsers: Int,
  averageAge: Double,
  youngestUser: Option[User],
  oldestUser: Option[User]
)

class StatisticsServiceImpl(userService: UserService[IO]) extends StatisticsService[IO] {

  override def getUserStatistics: IO[UserStatistics] = {
    for {
      allUsers <- userService.getAllUsers(1, Int.MaxValue)
      activeUsers = allUsers.filter(_.isActive)
      inactiveUsers = allUsers.filter(!_.isActive)
      averageAge = if (allUsers.nonEmpty) allUsers.map(_.age).sum.toDouble / allUsers.length else 0.0
      youngestUser = allUsers.minByOption(_.age)
      oldestUser = allUsers.maxByOption(_.age)
    } yield UserStatistics(
      totalUsers = allUsers.length,
      activeUsers = activeUsers.length,
      inactiveUsers = inactiveUsers.length,
      averageAge = averageAge,
      youngestUser = youngestUser,
      oldestUser = oldestUser
    )
  }

  override def getAgeDistribution: IO[Map[String, Int]] = {
    userService.getAllUsers(1, Int.MaxValue).map { users =>
      users.groupBy { user =>
        user.age match {
          case age if age < 18 => "0-17"
          case age if age < 25 => "18-24"
          case age if age < 35 => "25-34"
          case age if age < 50 => "35-49"
          case age if age < 65 => "50-64"
          case _ => "65+"
        }
      }.view.mapValues(_.length).toMap
    }
  }

  override def getActiveUsersCount: IO[Int] = {
    userService.getAllUsers(1, Int.MaxValue).map(_.count(_.isActive))
  }
}

object StatisticsService {
  def create(userService: UserService[IO]): StatisticsService[IO] = 
    new StatisticsServiceImpl(userService)
}
