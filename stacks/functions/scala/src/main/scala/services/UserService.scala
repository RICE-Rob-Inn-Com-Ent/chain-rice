package services

import cats.effect.{IO, Ref}
import cats.implicits.*
import models.{User, CreateUserRequest, UpdateUserRequest, AppError}
import java.util.concurrent.atomic.AtomicLong

trait UserService[F[_]] {
  def createUser(request: CreateUserRequest): F[User]
  def getUserById(id: Long): F[User]
  def getAllUsers(page: Int, pageSize: Int): F[List[User]]
  def updateUser(id: Long, request: UpdateUserRequest): F[User]
  def deleteUser(id: Long): F[Unit]
  def searchUsers(query: String): F[List[User]]
}

class InMemoryUserService private (usersRef: Ref[IO, Map[Long, User]], idCounter: AtomicLong) 
  extends UserService[IO] {

  override def createUser(request: CreateUserRequest): IO[User] = {
    val emailRegex = """^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$""".r
    
    for {
      _ <- IO.raiseWhen(request.name.trim.isEmpty)(
        AppError.validation("Nazwa użytkownika nie może być pusta")
      )
      _ <- IO.raiseWhen(request.age < 0 || request.age > 150)(
        AppError.validation("Wiek musi być między 0 a 150 lat")
      )
      _ <- IO.raiseWhen(!emailRegex.matches(request.email))(
        AppError.validation("Nieprawidłowy format email")
      )
      
      users <- usersRef.get
      _ <- IO.raiseWhen(users.values.exists(_.email == request.email))(
        AppError.conflict("Użytkownik z tym emailem już istnieje")
      )
      
      newId = idCounter.incrementAndGet()
      newUser = User(
        id = newId,
        name = request.name.trim,
        email = request.email.toLowerCase,
        age = request.age
      )
      
      _ <- usersRef.update(_ + (newId -> newUser))
    } yield newUser
  }

  override def getUserById(id: Long): IO[User] = {
    usersRef.get.flatMap { users =>
      users.get(id) match {
        case Some(user) => IO.pure(user)
        case None => IO.raiseError(AppError.notFound(s"Użytkownik o ID $id nie został znaleziony"))
      }
    }
  }

  override def getAllUsers(page: Int, pageSize: Int): IO[List[User]] = {
    usersRef.get.map { users =>
      val allUsers = users.values.toList.sortBy(_.id)
      val startIndex = (page - 1) * pageSize
      val endIndex = startIndex + pageSize
      allUsers.slice(startIndex, endIndex)
    }
  }

  override def updateUser(id: Long, request: UpdateUserRequest): IO[User] = {
    val emailRegex = """^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$""".r
    
    for {
      users <- usersRef.get
      existingUser <- users.get(id) match {
        case Some(user) => IO.pure(user)
        case None => IO.raiseError(AppError.notFound(s"Użytkownik o ID $id nie został znaleziony"))
      }
      
      _ <- request.email match {
        case Some(email) if !emailRegex.matches(email) => 
          IO.raiseError(AppError.validation("Nieprawidłowy format email"))
        case Some(email) if users.values.exists(u => u.email == email.toLowerCase && u.id != id) =>
          IO.raiseError(AppError.conflict("Użytkownik z tym emailem już istnieje"))
        case _ => IO.unit
      }
      
      _ <- request.age match {
        case Some(age) if age < 0 || age > 150 =>
          IO.raiseError(AppError.validation("Wiek musi być między 0 a 150 lat"))
        case _ => IO.unit
      }
      
      updatedUser = existingUser.copy(
        name = request.name.getOrElse(existingUser.name),
        email = request.email.map(_.toLowerCase).getOrElse(existingUser.email),
        age = request.age.getOrElse(existingUser.age),
        isActive = request.isActive.getOrElse(existingUser.isActive)
      )
      
      _ <- usersRef.update(_ + (id -> updatedUser))
    } yield updatedUser
  }

  override def deleteUser(id: Long): IO[Unit] = {
    usersRef.get.flatMap { users =>
      if (users.contains(id)) {
        usersRef.update(_ - id)
      } else {
        IO.raiseError(AppError.notFound(s"Użytkownik o ID $id nie został znaleziony"))
      }
    }
  }

  override def searchUsers(query: String): IO[List[User]] = {
    usersRef.get.map { users =>
      val lowercaseQuery = query.toLowerCase
      users.values.filter { user =>
        user.name.toLowerCase.contains(lowercaseQuery) ||
        user.email.toLowerCase.contains(lowercaseQuery)
      }.toList.sortBy(_.id)
    }
  }
}

object UserService {
  def create: IO[UserService[IO]] = {
    for {
      usersRef <- Ref.of[IO, Map[Long, User]](Map.empty)
      idCounter = new AtomicLong(0)
    } yield new InMemoryUserService(usersRef, idCounter)
  }
}
