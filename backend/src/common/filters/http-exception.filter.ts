import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse: any =
      exception instanceof HttpException ? exception.getResponse() : null;

    const message =
      exceptionResponse?.message ||
      exception.message ||
      'Internal server error';

    // Log the error for debugging
    if (status >= 500) {
      this.logger.error(
        `${request.method} ${request.url} - Error: ${message}`,
        exception.stack,
      );
    }

    response.status(status).json({
      status: 'error',
      message: Array.isArray(message) ? message[0] : message, // Handle class-validator array messages
      errors: Array.isArray(message) ? message : undefined,
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
