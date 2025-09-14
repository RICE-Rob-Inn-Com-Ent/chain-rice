package models

import io.circe.{Decoder, Encoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}

case class ApiResponse[T](
  success: Boolean,
  data: Option[T] = None,
  message: Option[String] = None,
  error: Option[String] = None
)

object ApiResponse {
  implicit def apiResponseEncoder[T: Encoder]: Encoder[ApiResponse[T]] = deriveEncoder[ApiResponse[T]]
  implicit def apiResponseDecoder[T: Decoder]: Decoder[ApiResponse[T]] = deriveDecoder[ApiResponse[T]]
  
  def success[T](data: T, message: Option[String] = None): ApiResponse[T] = 
    ApiResponse(success = true, data = Some(data), message = message)
    
  def error[T](errorMessage: String): ApiResponse[T] = 
    ApiResponse(success = false, error = Some(errorMessage))
}

case class PaginatedResponse[T](
  data: List[T],
  totalCount: Long,
  page: Int,
  pageSize: Int,
  totalPages: Int
)

object PaginatedResponse {
  implicit def paginatedResponseEncoder[T: Encoder]: Encoder[PaginatedResponse[T]] = deriveEncoder[PaginatedResponse[T]]
  implicit def paginatedResponseDecoder[T: Decoder]: Decoder[PaginatedResponse[T]] = deriveDecoder[PaginatedResponse[T]]
}
