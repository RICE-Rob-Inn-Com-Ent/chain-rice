package models

sealed trait AppError extends Throwable {
  def message: String
  def cause: Option[Throwable] = None
}

case class ValidationError(message: String) extends AppError
case class NotFoundError(message: String) extends AppError
case class ConflictError(message: String) extends AppError
case class DatabaseError(message: String, override val cause: Option[Throwable] = None) extends AppError
case class ExternalServiceError(message: String, override val cause: Option[Throwable] = None) extends AppError

object AppError {
  def validation(message: String): AppError = ValidationError(message)
  def notFound(message: String): AppError = NotFoundError(message)
  def conflict(message: String): AppError = ConflictError(message)
  def database(message: String, cause: Option[Throwable] = None): AppError = DatabaseError(message, cause)
  def externalService(message: String, cause: Option[Throwable] = None): AppError = ExternalServiceError(message, cause)
}
