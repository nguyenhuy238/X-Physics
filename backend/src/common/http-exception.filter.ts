import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const payload =
      exception instanceof HttpException ? exception.getResponse() : null;

    response.status(status).json({
      success: false,
      message:
        typeof payload === 'object' && payload && 'message' in payload
          ? payload.message
          : 'Internal server error',
      errors: Array.isArray((payload as { message?: unknown })?.message)
        ? (payload as { message: string[] }).message.map((message) => ({
            message,
          }))
        : undefined,
    });
  }
}
