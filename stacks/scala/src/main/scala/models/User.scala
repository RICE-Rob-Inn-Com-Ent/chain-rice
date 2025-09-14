package models

import io.circe.{Decoder, Encoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}

case class User(
  id: Long,
  name: String,
  email: String,
  age: Int,
  isActive: Boolean = true
)

object User {
  implicit val userEncoder: Encoder[User] = deriveEncoder[User]
  implicit val userDecoder: Decoder[User] = deriveDecoder[User]
}

case class CreateUserRequest(
  name: String,
  email: String,
  age: Int
)

object CreateUserRequest {
  implicit val createUserRequestEncoder: Encoder[CreateUserRequest] = deriveEncoder[CreateUserRequest]
  implicit val createUserRequestDecoder: Decoder[CreateUserRequest] = deriveDecoder[CreateUserRequest]
}

case class UpdateUserRequest(
  name: Option[String] = None,
  email: Option[String] = None,
  age: Option[Int] = None,
  isActive: Option[Boolean] = None
)

object UpdateUserRequest {
  implicit val updateUserRequestEncoder: Encoder[UpdateUserRequest] = deriveEncoder[UpdateUserRequest]
  implicit val updateUserRequestDecoder: Decoder[UpdateUserRequest] = deriveDecoder[UpdateUserRequest]
}
